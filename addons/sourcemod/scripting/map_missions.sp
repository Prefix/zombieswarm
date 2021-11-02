#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <zombieswarm>
#include <multicolors>
#include <gum>
#include <swarm/utils>

#define PLUGIN_VERSION "1.0"

#define SOUND_RED_TAKE "swarm/mission/redflag.mp3"
#define SOUND_BLUE_TAKE "swarm/mission/blueflag.mp3"

#define FLAG_NAME 0 // constant
#define FLAG_POSITION 1 // constant
#define FLAG_ENTITY 2
#define FLAG_TRIGGER 3
#define FLAG_BEAMTIMER 4
#define FLAG_TEAM 5
#define FLAG_TAKETIMER 6
#define FLAG_ACTIVATOR 7

#define REWARD_TAKING_FLAG 8

#define SCORE_TO_WIN 200

public Plugin myinfo =
{
    name = "Map missions",
    author = "Zombie Swarm contributors",
    description = "none",
    version = PLUGIN_VERSION,
    url = "https://github.com/Prefix/zombieswarm"
};

int fireSprite, haloSprite;

int takingFlag[MAXPLAYERS + 1] = {-1, ...};

bool roundTerminated;

float roundTime;

Handle timerRoundTime = null;

ArrayList flagsList;

char sMap[PLATFORM_MAX_PATH];

Handle g_hSetProgressBarTime = null;

public void OnPluginStart()
{
	CreateConVar("map_missions", PLUGIN_VERSION, "Map missions", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	HookEvent("round_start", eventRoundStart);
	HookEvent("round_end", eventRoundEnd);
	HookEvent("player_death", eventPlayerDeath);
	
	RegAdminCmd("mm_flag", flagCreateMenuCommand, ADMFLAG_CUSTOM3);
	RegAdminCmd("mm_menu", MainMenuCommand, ADMFLAG_CUSTOM3);

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetSignature(SDKLibrary_Server, "\x55\x89\xE5\x83\xEC\x48\x89\x5D\xF4\x8B\x5D\x08\x89\x75\xF8\x8B\x75\x0C\x89\x7D\xFC\x39\xB3\xE8\x27\x00\x00", 27); //Linux
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	g_hSetProgressBarTime = EndPrepSDKCall();
	
	flagsList = new ArrayList();
}

public void OnMapStart()
{

	char g_sWorkShopID[PLATFORM_MAX_PATH];
	GetCurrentMap(sMap, sizeof(sMap) - 1);
	
	if (StrContains(sMap, "workshop", false) != -1)
		GetCurrentWorkshopMap(sMap, sizeof(sMap) -1 , g_sWorkShopID, sizeof(g_sWorkShopID) - 1);

	// Flag model
	PrecacheModel( "models/conquest/flagv2/flag.mdl" );
	
	AddFileToDownloadsTable("models/conquest/flagv2/flag.mdl");
	AddFileToDownloadsTable("models/conquest/flagv2/flag.dx80.vtx");
	AddFileToDownloadsTable("models/conquest/flagv2/flag.dx90.vtx");
	AddFileToDownloadsTable("models/conquest/flagv2/flag.phy");
	AddFileToDownloadsTable("models/conquest/flagv2/flag.sw.vtx");
	AddFileToDownloadsTable("models/conquest/flagv2/flag.vvd");
	AddFileToDownloadsTable("models/conquest/flagv2/flag.xbox.vtx");
		
	AddFileToDownloadsTable("materials/models/conquest/flagv2/ct_flag.vmt");
	AddFileToDownloadsTable("materials/models/conquest/flagv2/ct_flag.vtf");
	AddFileToDownloadsTable("materials/models/conquest/flagv2/neutralflag.vmt");
	AddFileToDownloadsTable("materials/models/conquest/flagv2/neutralflag.vtf");
	AddFileToDownloadsTable("materials/models/conquest/flagv2/t_flag.vmt");
	AddFileToDownloadsTable("materials/models/conquest/flagv2/t_flag.vtf");
	
	fireSprite = PrecacheModel( "sprites/fire2.vmt" );
	AddFileToDownloadsTable( "materials/sprites/fire2.vtf" );
	AddFileToDownloadsTable( "materials/sprites/fire2.vmt");
	haloSprite = PrecacheModel( "sprites/halo01.vmt" );
	AddFileToDownloadsTable( "materials/sprites/halo01.vtf" );
	AddFileToDownloadsTable( "materials/sprites/halo01.vmt" );
	
	char soundsPath[PLATFORM_MAX_PATH];
	
	Format(soundsPath, PLATFORM_MAX_PATH, "sound/%s", SOUND_RED_TAKE);
		
	if( FileExists(soundsPath) )
	{
		FakePrecacheSoundEx(SOUND_RED_TAKE);
		AddFileToDownloadsTable( soundsPath );
	}
	else
	{
		LogError("Cannot locate sounds file '%s'", soundsPath);
	}
	
	Format(soundsPath, PLATFORM_MAX_PATH, "sound/%s", SOUND_BLUE_TAKE);
		
	if( FileExists(soundsPath) )
	{
		FakePrecacheSoundEx(SOUND_BLUE_TAKE);
		AddFileToDownloadsTable( soundsPath );
	}
	else
	{
		LogError("Cannot locate sounds file '%s'", soundsPath);
	}
	
	roundTerminated = false;
	
	roundTime = GetConVarFloat(FindConVar("mp_roundtime"));
	roundTime *= 60.0;
	roundTime -= 2.0;
	
	if (timerRoundTime != null)
		delete timerRoundTime;
	
	flagsList.Clear();
	
	char sFile[PLATFORM_MAX_PATH];
	
	BuildPath(Path_SM, sFile, sizeof(sFile), "configs/objects/%s.cfg", sMap);
	
	if(!FileExists(sFile))
		return;
		
	KeyValues kv = CreateKeyValues("Objects");

	if (!kv.ImportFromFile(sFile)) {
		delete kv;
		return;
	}
		
	if (!kv.GotoFirstSubKey()) {
		delete kv;
		return;
	}

	char sBuffer[256];
	float fVec[3];
	
	ArrayList flagList;
	
	do
	{
		flagList = new ArrayList(ByteCountToCells(256));
		
		// A description shown in chat when conquered
		kv.GetString("name", sBuffer, sizeof(sBuffer));
		flagList.PushString(sBuffer);
		
		// The position of the flag
		kv.GetVector("position", fVec);
		flagList.PushArray(fVec, 3);
		
		flagList.Push(-1);
		flagList.Push(-1);
		flagList.Push(INVALID_HANDLE);
		
		flagList.Push(0);
		flagList.Push(INVALID_HANDLE);
		flagList.Push(0);
			
		// Add it to the global flags array
		flagsList.Push(flagList);
	} while(kv.GotoNextKey());
	
	delete kv;
}

public void OnClientPutInServer(int client)
{
	if ( UTIL_IsValidClient(client) )
	{
		takingFlag[client] = -1;
	}
}

public void OnClientDisconnect(int client)
{
	if ( IsClientInGame(client) )
	{
		if (takingFlag[client] != -1) {
			ArrayList flagArray = flagsList.Get(takingFlag[client]);
			
			flagArray.Set(FLAG_ACTIVATOR, 0);
		
			Handle flagConquerTimer = flagArray.Get(FLAG_TAKETIMER);
		
			if(flagConquerTimer != INVALID_HANDLE)
			{
				KillTimer(flagConquerTimer);
				flagArray.Set(FLAG_TAKETIMER, INVALID_HANDLE);
			}
			
			SDKCall(g_hSetProgressBarTime, client, 0);
			
			takingFlag[client] = -1;
		}
	}
}

public Action flagCreateMenuCommand(int client, int args)
{
	if(!UTIL_IsValidClient(client))
	{
		PrintToServer("%t","Command is in-game only!");
		return Plugin_Handled;
	}
	
	if(args < 1) 
	{
		ReplyToCommand(client, "[SM] Use: mm_flag <name>");
		return Plugin_Handled;
	}
	
	char nameArg[32];

	GetCmdArg(1, nameArg, sizeof(nameArg)); 
	
	float position[3];
			
	getLookPosition(client, position);
			
	position[2] += 20.0;
			
	ArrayList flag = new ArrayList(ByteCountToCells(256));
		
	// A description shown in chat when conquered
	flag.PushString(nameArg);
			
	// The position of the flag
	flag.PushArray(position, 3);
	
	flag.Push(-1);
	flag.Push(-1);
	flag.Push(INVALID_HANDLE);
		
	flag.Push(0);
	flag.Push(INVALID_HANDLE);
	flag.Push(0);
			
	// Add it to the global flags array
	int index = flagsList.Push(flag);
	
	createFlag(position, index);
			
	saveObjectsToFile();

	return Plugin_Handled;
}

public Action MainMenuCommand(int client, int args)
{
	if(!UTIL_IsValidClient(client))
	{
		PrintToServer("%t","Command is in-game only!");
		return Plugin_Handled;
	}
	
	objectsMenu(client);

	return Plugin_Handled;
}

public void eventRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	int size = flagsList.Length;
	
	roundTerminated = false;
	
	if (timerRoundTime != null)
		delete timerRoundTime;
	
	timerRoundTime = CreateTimer(roundTime, timerRoundTimeCallback);
	
	// Don't do anything, if no flags for that map -> "disabled"
	if(size == 0)
		return;

	// Create flags
	float position[3];
	
	for(int cell = 0; cell < size; cell++)
	{
		// Get all info out of the global array
		ArrayList flag = flagsList.Get(cell);
		
		flag.GetArray(FLAG_POSITION, position, 3);

		createFlag(position, cell);
	}
	
	SetTeamScore(CS_TEAM_CT, 0);
	CS_SetTeamScore(CS_TEAM_CT, 0);
	
	SetTeamScore(CS_TEAM_T, 0);
	CS_SetTeamScore(CS_TEAM_T, 0);
}

public void eventRoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	int size = flagsList.Length;
	
	// Don't do anything, if no flags for that map -> "disabled"
	if(size == 0)
		return;
		
	int i;
	for (i = 1; i <= MaxClients; i++)
	{
		if (UTIL_IsValidClient(i)) {
			SDKCall(g_hSetProgressBarTime, i, 0);
			
			takingFlag[i] = -1;
		}
	}
		
	removeFlags(size);
}

public void eventPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(GetEventInt(event, "userid"));

	if ( !UTIL_IsValidClient(victim) )
		return;
	
	if (takingFlag[victim] != -1) {
		SDKCall(g_hSetProgressBarTime, victim, 0);
		
		ArrayList flagArray = flagsList.Get(takingFlag[victim]);
		
		flagArray.Set(FLAG_ACTIVATOR, 0);
	
		Handle flagConquerTimer = flagArray.Get(FLAG_TAKETIMER);
	
		if(flagConquerTimer != INVALID_HANDLE)
		{
			KillTimer(flagConquerTimer);
			flagArray.Set(FLAG_TAKETIMER, INVALID_HANDLE);
		}
		
		takingFlag[victim] = -1;
	}
}

public void objectsMenu(int client)
{
	Menu menu = new Menu(objectsMenuCallback);

	menu.SetTitle("Objects menu");
	
	menu.AddItem("item", "Delete flags");

	menu.ExitButton = true;
	
	menu.Display(client, 30);
}
public int objectsMenuCallback(Handle menu, MenuAction action, int client, int item)
{
	if( action == MenuAction_Select )
	{	
		if (item == 0) {
			deleteFlagsMenu(client);
		}
	} 
	else if (action == MenuAction_End)	
	{
		delete menu;
	}
	return 0;
}

public void deleteFlagsMenu(int client)
{
	Menu menu = new Menu(deleteFlagsMenuCallback);

	menu.SetTitle("Delete flags");
	
	int size = flagsList.Length;
	
	char sBuffer[256];
	
	for(int cell = 0; cell < size; cell++)
	{
		// Get all info out of the global array
		ArrayList flag = flagsList.Get(cell);
		
		flag.GetString(FLAG_NAME, sBuffer, sizeof(sBuffer));
		
		menu.AddItem("flag_item", sBuffer);
	}

	menu.ExitButton = true;
	
	menu.Display(client, 30);
}
public int deleteFlagsMenuCallback(Handle menu, MenuAction action, int client, int item)
{
	if( action == MenuAction_Select )
	{	
		flagsList.Erase(item);
		
		saveObjectsToFile();
		
		int size = flagsList.Length;
		
		int i;
		for (i = 1; i <= MaxClients; i++)
		{
			if (UTIL_IsValidClient(i)) {
				takingFlag[i] = -1;
			}
		}
	
		removeFlags(size);

		// Create flags
		float position[3];
		
		for(int cell = 0; cell < size; cell++)
		{
			// Get all info out of the global array
			ArrayList flag = flagsList.Get(cell);
			
			flag.GetArray(FLAG_POSITION, position, 3);
	
			createFlag(position, cell);
		}
		
		PrintToChatAll("Successfully deleted flag!");
		
		objectsMenu(client);
	} 
	else if (action == MenuAction_End)	
	{
		delete menu;
	}
	return 0;
}

public void createFlag(float position[3], int index)
{
	// Get all info out of the global array
	ArrayList flagArray = flagsList.Get(index);
	
	int flag = CreateEntityByName("prop_dynamic");
	
	if(!IsValidEntity(flag))
	{
		PrintToServer("Can't create a flag.");
		return;
	}

	TeleportEntity(flag, position, NULL_VECTOR, NULL_VECTOR);
	
	SetEntityModel(flag, "models/conquest/flagv2/flag.mdl");
	
	DispatchKeyValue(flag, "skin", "0"); // red = 1 blue = 2
	
	char targetName[64];
	Format(targetName, sizeof(targetName), "mm_flag%d", index);
	DispatchKeyValue(flag, "targetname", targetName);
	
	// Spawn
	DispatchSpawn(flag);
	ActivateEntity(flag);
	
	SetVariantString("flag_idle1");
	AcceptEntityInput(flag, "SetAnimation");
	
	flagArray.Set(FLAG_ENTITY, flag);
	
	// Create Trigger to detect touches
	int trigger = CreateEntityByName("trigger_multiple");
	
	if(!IsValidEntity(trigger))
	{
		PrintToServer("Can't create a trigger.");
		return;
	}
	
	DispatchKeyValue(trigger, "spawnflags", "1"); // triggers on clients (players) only
	Format(targetName, sizeof(targetName), "mm_flag_trigger%d", index);
	DispatchKeyValue(trigger, "targetname", targetName);
	DispatchKeyValue(trigger, "wait", "0");
	
	DispatchSpawn(trigger);
	ActivateEntity(trigger);
	
	TeleportEntity(trigger, position, NULL_VECTOR, NULL_VECTOR);
	SetEntityModel(trigger, "models/conquest/flagv2/flag.mdl");
	
	float bindBoxes[3];
	
	bindBoxes[0] = -100.0;
	bindBoxes[1] = -100.0;
	bindBoxes[2] = -20.0;
	SetEntPropVector(trigger, Prop_Send, "m_vecMins", bindBoxes);
	
	bindBoxes[0] = 100.0;
	bindBoxes[1] = 100.0;
	bindBoxes[2] = 150.0;
	SetEntPropVector(trigger, Prop_Send, "m_vecMaxs", bindBoxes);
	
	SetEntProp(trigger, Prop_Send, "m_nSolidType", 2);
	
	int effects = GetEntProp(trigger, Prop_Send, "m_fEffects");
	effects |= 32;
	SetEntProp(trigger, Prop_Send, "m_fEffects", effects);
	
	HookSingleEntityOutput(trigger, "OnStartTouch", triggerFlagOnStartTouch);
	HookSingleEntityOutput(trigger, "OnEndTouch", triggerFlagOnEndTouch);
	
	flagArray.Set(FLAG_TRIGGER, trigger);
	
	int color[4] = {102,102,102,220};
	
	TE_SetupBeamRingPoint(position, 280.0, 300.0, fireSprite, haloSprite, 0, 10, 2.0, 15.0, 0.5, color, 25, 0);
  	TE_SendToAll();
  	
  	flagArray.Set(FLAG_TRIGGER, trigger);
  	
  	// Start conquer timer
	Handle beamTimer = CreateTimer(2.0, timerBeamCallback, index, TIMER_FLAG_NO_MAPCHANGE);
	flagArray.Set(FLAG_BEAMTIMER, beamTimer);
}

public Action timerBeamCallback(Handle timer, any index)
{
	ArrayList flagArray = flagsList.Get(index);
	flagArray.Set(FLAG_BEAMTIMER, INVALID_HANDLE);
	
	int flag = flagArray.Get(FLAG_ENTITY);

	if(!IsValidEntity(flag))
		return Plugin_Stop;
		
	float position[3];
	flagArray.GetArray(FLAG_POSITION, position, 3);
	
	int team = 0;
	team = flagArray.Get(FLAG_TEAM);
		
	int color[4] = {102,102,102,220};
	
	if (CS_GetTeamScore(CS_TEAM_T) >= SCORE_TO_WIN) {
		if (!roundTerminated) {
			CS_TerminateRound(10.0, CSRoundEnd_TerroristWin, true);
			roundTerminated = true;
		}
		
		return Plugin_Stop;
		
	} else if (CS_GetTeamScore(CS_TEAM_CT) >= SCORE_TO_WIN) {
		if (!roundTerminated) {
			CS_TerminateRound(10.0, CSRoundEnd_CTWin, true);
			roundTerminated = true;
		}
		
		return Plugin_Stop;
	}
	
	if (team == CS_TEAM_T) {
		if (!roundTerminated) {
			SetTeamScore(CS_TEAM_T, CS_GetTeamScore(CS_TEAM_T)+1);
			CS_SetTeamScore(CS_TEAM_T, CS_GetTeamScore(CS_TEAM_T)+1);
		}
		
		color[0] = 255;
		color[1] = 0;
		color[2] = 0;
	} else if (team == CS_TEAM_CT) {
		if (!roundTerminated) {
			SetTeamScore(CS_TEAM_CT, CS_GetTeamScore(CS_TEAM_CT)+1);
			CS_SetTeamScore(CS_TEAM_CT, CS_GetTeamScore(CS_TEAM_CT)+1);
		}
		
		color[0] = 0;
		color[1] = 0;
		color[2] = 255;
	}
		
	TE_SetupBeamRingPoint(position, 280.0, 300.0, fireSprite, haloSprite, 0, 10, 2.0, 15.0, 0.5, color, 20, 0);
  	TE_SendToAll();
  	
  	Handle beamTimer = CreateTimer(2.0, timerBeamCallback, index, TIMER_FLAG_NO_MAPCHANGE);
	flagArray.Set(FLAG_BEAMTIMER, beamTimer);
  	
  	return Plugin_Stop;
}

public Action timerTakingCallback(Handle timer, any index)
{
	ArrayList flagArray = flagsList.Get(index);
	flagArray.Set(FLAG_TAKETIMER, INVALID_HANDLE);
	
	int flag = flagArray.Get(FLAG_ENTITY);
	int client = flagArray.Get(FLAG_ACTIVATOR);

	if(!UTIL_IsValidAlive(client) || !IsValidEntity(flag))
		return Plugin_Stop;
		
	takingFlag[client] = -1;
	
	SDKCall(g_hSetProgressBarTime, client, 0);
	
	float entityOrigin[3], clientOrigin[3], distanceBetween;
	GetEntPropVector(flag, Prop_Send, "m_vecOrigin", entityOrigin);
	
	char fName[128];
	flagArray.GetString(FLAG_NAME, fName, sizeof(fName));
		
	if (GetClientTeam(client) == CS_TEAM_CT) {
		playClientCommandSoundAll(SOUND_BLUE_TAKE);
		
		CPrintToChatAll("{green}Humans has taken {blue}[%s] {green}flag!", fName );
		
		DispatchKeyValue(flag, "skin", "2");
		
		int i;
		for (i = 1; i <= MaxClients; i++)
		{
			if (UTIL_IsValidAlive(i) && GetClientTeam(i) == CS_TEAM_CT) {
				GetClientAbsOrigin ( i, clientOrigin );
				distanceBetween = GetVectorDistance ( entityOrigin, clientOrigin );
				
				if ( distanceBetween <= 350.0 )
				{
					CPrintToChat(i, "{default}Reward: {green} %d UL {default} for taking the flag!", REWARD_TAKING_FLAG);
					
					GUM_SetPlayerUnlocks( i, GUM_GetPlayerUnlocks( i ) + REWARD_TAKING_FLAG );
				}
			}
		}
	} else if (GetClientTeam(client) == CS_TEAM_T) {
		playClientCommandSoundAll(SOUND_RED_TAKE);
		
		CPrintToChatAll("{green}Zombies has taken {red}[%s] {green}flag!", fName);
		
		DispatchKeyValue(flag, "skin", "1");
		
		int i;
		for (i = 1; i <= MaxClients; i++)
		{
			if (UTIL_IsValidAlive(i) && GetClientTeam(i) == CS_TEAM_T) {
				GetClientAbsOrigin ( i, clientOrigin );
				distanceBetween = GetVectorDistance ( entityOrigin, clientOrigin );
				
				if ( distanceBetween <= 350.0 )
				{
					CPrintToChat(i, "{default}Reward: {green} %d UL {default} for taking the flag!", REWARD_TAKING_FLAG);
					
					GUM_SetPlayerUnlocks( i, GUM_GetPlayerUnlocks( i ) + REWARD_TAKING_FLAG );
				}
			}
		}
	}
		
	flagArray.Set(FLAG_TEAM, GetClientTeam(client));
	flagArray.Set(FLAG_ACTIVATOR, 0);
	
	return Plugin_Stop;
}

public Action timerRoundTimeCallback(Handle timer, any index)
{
	timerRoundTime = null;
	
	CS_TerminateRound(10.0, CSRoundEnd_TerroristWin, true);
	
	return Plugin_Stop;
}

public void removeFlags(int size)
{
	for(int cell = 0; cell < size; cell++)
	{
		// Get all info out of the global array
		ArrayList flagArray = flagsList.Get(cell);
		
		flagArray.Set(FLAG_TEAM, 0);
		flagArray.Set(FLAG_ACTIVATOR, 0);
		
		Handle beamTimer = flagArray.Get(FLAG_BEAMTIMER);
		
		if(beamTimer != INVALID_HANDLE)
		{
			KillTimer(beamTimer);
			flagArray.Set(FLAG_BEAMTIMER, INVALID_HANDLE);
		}
		
		Handle conquerTimer = flagArray.Get(FLAG_TAKETIMER);
		
		if(conquerTimer != INVALID_HANDLE)
		{
			KillTimer(conquerTimer);
			flagArray.Set(FLAG_TAKETIMER, INVALID_HANDLE);
		}
	}
	
	// Remove the entity
	int maxEntities = GetMaxEntities(), i;
	char sBuffer[64];
	
	for(i = MaxClients; i < maxEntities; i++)
	{
		if(IsValidEntity(i) && IsValidEdict(i) ) {
			GetEdictClassname(i, sBuffer, sizeof(sBuffer));
		
			if (StrEqual(sBuffer, "prop_dynamic", false) || StrEqual(sBuffer, "trigger_multiple", false)) {
				GetEntPropString(i, Prop_Data, "m_iName", sBuffer, sizeof(sBuffer));
				
				if ( StrContains(sBuffer, "mm_flag") != -1 || StrContains(sBuffer, "mm_flag_trigger") != -1) {
					AcceptEntityInput(i, "Kill");
				}
			}
		}
	}
}

public void triggerFlagOnStartTouch(char[] output, int caller, int activator, float delay)
{
	// Ignore dead players
	//if(!UTIL_IsValidAlive(activator) || isGhost(activator))
	if(!UTIL_IsValidAlive(activator) || GetClientTeam(activator) == CS_TEAM_SPECTATOR)
	{
		return;
	}
	
	// Get array index of this trigger
	char targetName[64];
	GetEntPropString(caller, Prop_Data, "m_iName", targetName, sizeof(targetName));
	ReplaceString(targetName, sizeof(targetName), "mm_flag_trigger", "");
	int index = StringToInt(targetName);

	ArrayList flagArray = flagsList.Get(index);
	
	int flagTeam = flagArray.Get(FLAG_TEAM);
	Handle flagConquerTimer = flagArray.Get(FLAG_TAKETIMER);
	
	if (GetClientTeam(activator) == flagTeam)
		return;
		
	if (takingFlag[activator] != -1)
		return;
		
	if (GetClientTeammateTakingFlag(activator, index))
		return;
		
	SDKCall(g_hSetProgressBarTime, activator, 0);
		
	takingFlag[activator] = index;
				
	int enemy = getEnemyTakingFlag(activator, index);
	if (enemy > 0) {
		SDKCall(g_hSetProgressBarTime, enemy, 0);
		
		flagArray.Set(FLAG_ACTIVATOR, 0);
		
		if(flagConquerTimer != INVALID_HANDLE)
		{
			KillTimer(flagConquerTimer);
			flagArray.Set(FLAG_TAKETIMER, INVALID_HANDLE);
		}
		
		takingFlag[enemy] = -1;
		takingFlag[activator] = -1;
	} else {
		SDKCall(g_hSetProgressBarTime, activator, 5);
		
		flagArray.Set(FLAG_ACTIVATOR, activator);
		flagConquerTimer = CreateTimer(5.0, timerTakingCallback, index, TIMER_FLAG_NO_MAPCHANGE);
		flagArray.Set(FLAG_TAKETIMER, flagConquerTimer);
	}
}

public void triggerFlagOnEndTouch(char[] output, int caller, int activator, float delay)
{
	// Ignore anything other than players
	if(!UTIL_IsValidClient(activator))
	{
		return;
	}
	
	// Get array index of this trigger
	char targetName[64];
	GetEntPropString(caller, Prop_Data, "m_iName", targetName, sizeof(targetName));
	ReplaceString(targetName, sizeof(targetName), "mm_flag_trigger", "");
	int index = StringToInt(targetName);

	ArrayList flagArray = flagsList.Get(index);
	
	Handle flagConquerTimer = flagArray.Get(FLAG_TAKETIMER);

	if (takingFlag[activator] != -1) {
		SDKCall(g_hSetProgressBarTime, activator, 0);
		
		flagArray.Set(FLAG_ACTIVATOR, 0);
		
		if(flagConquerTimer != INVALID_HANDLE)
		{
			KillTimer(flagConquerTimer);
			flagArray.Set(FLAG_TAKETIMER, INVALID_HANDLE);
		}
		
		takingFlag[activator] = -1;
	}
}

public void saveObjectsToFile()
{
	char sFile[PLATFORM_MAX_PATH];
	
	BuildPath(Path_SM, sFile, sizeof(sFile), "configs/objects/%s.cfg", sMap);
	
	KeyValues kv = CreateKeyValues("Objects");
	
	int listSize = flagsList.Length;
	
	ArrayList flag;
	float fVec[3];
	char sBuffer[256];
	
	for(int i = 0; i < listSize; i++)
	{
		flag = flagsList.Get(i);
		IntToString(i, sBuffer, sizeof(sBuffer));
		
		// Create a new section for that flag
		kv.JumpToKey(sBuffer, true);
		
		flag.GetString(FLAG_NAME, sBuffer, sizeof(sBuffer));
		kv.SetString("name", sBuffer);
		
		flag.GetArray(FLAG_POSITION, fVec, 3);
		kv.SetVector("position", fVec);
		
		kv.GoBack();
	}
	
	kv.Rewind();
	
	kv.ExportToFile(sFile);
	
	delete kv;
}


stock void getLookPosition(int client, float eyePositionReference[3])
{
	float eyePosition[3], eyeAngles[3];
	Handle trace; 
	
	GetClientEyePosition(client, eyePosition); 
	GetClientEyeAngles(client, eyeAngles); 
	
	trace = TR_TraceRayFilterEx(eyePosition, eyeAngles, MASK_SOLID, RayType_Infinite, getLookPositionFilter, client); 
	
	TR_GetEndPosition(eyePositionReference, trace); 
	
	delete trace;
}

public bool getLookPositionFilter(int entity, int contentsMask, any client)
{ 
	return client != entity; 
}

public int GetClientTeammateTakingFlag(int client, int index)
{
	int i;
	
	for (i = 1; i <= MaxClients; i++)
	{
		if (UTIL_IsValidClient(i) && client != i && takingFlag[i] == index && GetClientTeam(client) == GetClientTeam(i))
		{
			return true;
		}
	}
	
	return false;
}

public int getEnemyTakingFlag(int client, int index)
{
	int i;
	
	for (i = 1; i <= MaxClients; i++)
	{
		if (UTIL_IsValidClient(i) && client != i && takingFlag[i] == index && GetClientTeam(client) != GetClientTeam(i))
		{
			return i;
		}
	}
	
	return 0;
}

stock void playClientCommandSoundAll(const char[] sound)
{
	for (int client = 1; client <= MaxClients; client++) 
	{ 
		if (UTIL_IsValidClient(client) )
		{
			ClientCommand(client, "playgamesound Music.StopAllMusic");
			ClientCommand(client, "play *%s", sound);
		}
	}
}

stock bool FakePrecacheSoundEx( const char[] szPath )
{
	char sPathStar[PLATFORM_MAX_PATH];
	Format(sPathStar, sizeof(sPathStar), "*%s", szPath);
	
	AddToStringTable( FindStringTable( "soundprecache" ), sPathStar );
	return true;
}

void GetCurrentWorkshopMap(char[] szMap, int iMapBuf, char[] szWorkShopID, int iWorkShopBuf)
{
	char szCurMap[128];
	char szCurMapSplit[2][64];

	GetCurrentMap(szCurMap, 127);
	ReplaceString(szCurMap, sizeof(szCurMap), "workshop/", "", false);
	ExplodeString(szCurMap, "/", szCurMapSplit, 2, 63);

	strcopy(szMap, iMapBuf, szCurMapSplit[1]);
	strcopy(szWorkShopID, iWorkShopBuf, szCurMapSplit[0]);
}