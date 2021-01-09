#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <zombieswarm>
#include <gum>
#include <cstrike>
#include <colorvariables>
#include <overlays>
#include <autoexecconfig>
#include <emitsoundany>

#pragma semicolon 1
#pragma newdecls required

//#define DEBUG 1

// Globals
#include "swarm/core/defines.sp"
#include "swarm/core/enums.sp"
#include "swarm/core/globals.sp"
#include "swarm/core/natives.sp"
#include "swarm/core/cvars.sp"

#include <swarm/utils>

public Plugin myinfo =
{
    name = ZS_PLUGIN_NAME,
    author = ZS_PLUGIN_AUTHOR,
    description = ZS_PLUGIN_DESCRIPTION,
    version = ZS_PLUGIN_VERSION,
    url = ZS_PLUGIN_URL
};

public void OnPluginStart()
{   
    LoadTranslations("zombieswarm.phrases");

    ZS_StartConfig("zombieswarm");
    InitCvars();
    ZS_EndConfig();

    HookConVarChange(g_cFog, OnConVarChange);
    
    HookEvent("player_spawn", eventPlayerSpawn);
    HookEvent("round_start", eventRoundStart);
    HookEvent("round_freeze_end", eventRoundFreezeEnd, EventHookMode_Post);
    HookEvent("cs_win_panel_round", eventWinPanelRound, EventHookMode_Pre);
    HookEvent("player_team", eventTeamChange, EventHookMode_Pre);
    HookEvent("player_death", eventPlayerDeath);
    HookEvent("round_end", eventRoundEnd);
    HookEvent("weapon_fire", eventWeaponFire);
    HookEvent("player_footstep", eventFootstep);

    AddNormalSoundHook(view_as<NormalSHook>(Event_SoundPlayed));
    
    AddCommandListener( blockKill, "kill");
    AddCommandListener( blockKill, "spectate");
    AddCommandListener( blockKill, "explode");
    AddCommandListener( blockKill, "jointeam");
    AddCommandListener( blockKill, "explodevector");
    AddCommandListener( blockKill, "killvector");
    AddCommandListener( joinTeam, "jointeam");

    g_aZombieClass = new ArrayList(sizeof(g_esZombieClass));
    g_aZombieAbility = new ArrayList(sizeof(g_esZombieAbility));
    g_aPlayerAbility = new ArrayList(sizeof(g_esPlayerAbility));
    g_aZombieSounds = new ArrayList(sizeof(g_esZombieSounds));
    
    g_iCollisionOffset = FindSendPropInfo("CBaseEntity", "m_CollisionGroup");
    
    g_cAlpha = FindConVar("sv_disable_immunity_alpha");
    
    if(g_cAlpha != null) SetConVarInt(g_cAlpha, 1);   
    RegAdminCmd("sm_swarmtest", Command_SwarmTest, ADMFLAG_ROOT, "Some useful debug info");
    RegAdminCmd("sm_swarmdebug_player", Command_SwarmDebugPlayer, ADMFLAG_ROOT, "Some useful debug info");

}
public Action Command_SwarmDebugPlayer(int client, int args)
{
    PrintToServer("PlayerClass");
    PrintToServer("==============================================");
    for (client = 1; client <= MaxClients; client++) 
    {
        if (UTIL_IsValidClient(client)) {
            PrintToServer("client: %d", client);
            PrintToServer("g_iTeam: %d", g_iTeam[client]);
            PrintToServer("g_iZombieClass: %d", g_iZombieClass[client]);
            PrintToServer("g_bGhost: %s", g_bGhost[client] ? "true" : "false");
            PrintToServer("g_bCooldown: %s", g_bCooldown[client] ? "true" : "false");
            PrintToServer("g_bShouldCollide: %s", g_bShouldCollide[client] ? "true" : "false");
            PrintToServer("g_bCanJoin: %s", g_bCanJoin[client] ? "true" : "false");
            PrintToServer("g_bCanIgnore: %s", g_bCanIgnore[client] ? "true" : "false");
            PrintToServer("g_bOverrideHint: %s", g_bOverrideHint[client] ? "true" : "false");
            PrintToServer("g_fLastButtons: %d", g_fLastButtons[client]);
            PrintToServer("g_fHintSpeed: %f", g_fHintSpeed[client]);
            PrintToServer("g_sOverrideHintText: %s", g_sOverrideHintText[client]);
            PrintToServer("g_iZombieRespawnLeft: %d", g_iZombieRespawnLeft[client]);
            for (int i = 0; i < g_aPlayerAbility.Length; i++)
            {
                g_esPlayerAbility temp_ability;
                g_aPlayerAbility.GetArray(i, temp_ability, sizeof(temp_ability)); 
                if (temp_ability.paClient != client)
                    continue;
                PrintToServer("abilityID[%d]: %d",i, temp_ability.paID);
            }
        }
        PrintToServer("==============================================");
    }
}
public Action Command_SwarmTest(int client, int args)
{
    PrintToServer("PlayerClass");
    PrintToServer("==============================================");
    for (client = 1; client <= MaxClients; client++) 
    {
        if (UTIL_IsValidClient(client)) {
            PrintToServer("client: %d", client);
            PrintToServer("g_iZombieClass: %d", g_iZombieClass[client]);
            PrintToServer("g_fLastButtons: %d", g_fLastButtons[client]);
            PrintToServer("g_bOverrideHint: %d", g_bOverrideHint[client]);
            for (int i = 0; i < g_aPlayerAbility.Length; i++)
            {
                g_esPlayerAbility temp_ability;
                g_aPlayerAbility.GetArray(i, temp_ability, sizeof(temp_ability)); 
                if (temp_ability.paClient != client)
                    continue;
                PrintToServer("abilityID[%d]: %d",i, temp_ability.paID);
            }
        }
        PrintToServer("==============================================");
    }
    PrintToServer("ZombieClasses");
    PrintToServer("==============================================");
    for (int i = 0; i < g_aZombieClass.Length; i++)
    {
        g_esZombieClass zombie;
        g_aZombieClass.GetArray(i, zombie);
        PrintToServer("ID: %d", zombie.dataID);
        PrintToServer("dataID: %d", zombie.dataID);
        PrintToServer("dataHP: %d", zombie.dataHP);
        PrintToServer("dataAbilityButton: %d", zombie.dataAbilityButton);
        PrintToServer("dataCooldown: %f", zombie.dataCooldown);
        PrintToServer("dataSpeed: %f", zombie.dataSpeed);
        PrintToServer("dataGravity: %f", zombie.dataGravity);
        PrintToServer("dataDamage: %f", zombie.dataDamage);
        PrintToServer("dataAttackSpeed: %df", zombie.dataAttackSpeed);
        PrintToServer("dataName: %s", zombie.dataName);
        PrintToServer("dataDescription: %s", zombie.dataDescription);
        PrintToServer("dataModel: %s", zombie.dataModel);
        PrintToServer("dataArms: %s", zombie.dataArms);
        PrintToServer("dataExcluded: %d", zombie.dataExcluded ? "true" : "false");
        PrintToServer("dataUniqueName: %s", zombie.dataUniqueName);
        PrintToServer("==============================================");
    }
    PrintToServer("g_esZombieAbility");
    PrintToServer("==============================================");
    for (int i = 0; i < g_aZombieAbility.Length; i++)
    {
        g_esZombieAbility zombiey;
        g_aZombieAbility.GetArray(i, zombiey);
        PrintToServer("ID: %d", i);
        PrintToServer("abilityID: %d", zombiey.abilityID);
        PrintToServer("abilityZombieClass: %d", zombiey.abilityZombieClass);
        PrintToServer("abilityDuration: %f", zombiey.abilityDuration);
        PrintToServer("abilityButtons: %d", zombiey.abilityButtons);
        PrintToServer("abilityCooldown: %f", zombiey.abilityCooldown);
        PrintToServer("abilityName: %s", zombiey.abilityName);
        PrintToServer("abilityDescription: %s", zombiey.abilityDescription);
        PrintToServer("abilityExcluded: %d", zombiey.abilityExcluded ? "true" : "false");
        PrintToServer("abilityUniqueName: %s", zombiey.abilityUniqueName);
        PrintToServer("==============================================");
    }
    PrintToServer("g_esPlayerAbility");
    PrintToServer("==============================================");
    for (int i = 0; i < g_aPlayerAbility.Length; i++)
    {
        g_esPlayerAbility zombiex;
        g_aPlayerAbility.GetArray(i, zombiex);
        PrintToServer("paID: %d", i);
        PrintToServer("paID: %d", zombiex.paID);
        PrintToServer("paClient: %d", zombiex.paClient);
        PrintToServer("paZombieClass: %d", zombiex.paZombieClass);
        PrintToServer("paDuration: %f", zombiex.paDuration);
        PrintToServer("paCooldown: %f", zombiex.paCooldown);
        PrintToServer("paCurrentDuration: %f", zombiex.paCurrentDuration);
        PrintToServer("paCurrentCooldown: %f", zombiex.paCurrentCooldown);
        PrintToServer("paState: %d", zombiex.paState);
        PrintToServer("paButtons: %d", zombiex.paButtons);
        PrintToServer("paExcluded: %s", zombiex.paExcluded ? "true" : "false");
        PrintToServer("paName: %s", zombiex.paName);
        PrintToServer("paDescription: %s", zombiex.paDescription);
        PrintToServer("paUniqueName: %s", zombiex.paUniqueName);
        PrintToServer("==============================================");
    }
}

public void OnConfigsExecuted() {
    g_aZombieClass.Clear();
    g_aZombieAbility.Clear();
    g_aPlayerAbility.Clear();
    g_iNumClasses = 0;
    g_iNumAbilities = 0;
    g_iNumPlayerAbilities = 0;
    Call_StartForward(g_hForwardZSOnLoaded);
    Call_Finish();
}

public void eventWeaponFire(Event event, char[] name, bool dbc)
{
    RequestFrame(FirePostFrame, event.GetInt("userid"));
}

public Action eventFootstep(Event event, char[] name, bool dbc)
{
    if (!g_cSoundsFootsteps.BoolValue) return Plugin_Continue;
    
    int client = event.GetInt("userid");
    if (UTIL_IsValidAlive(client) && GetClientTeam(client) == CS_TEAM_T) {
        if (g_fNextFootstep[client] < GetGameTime()) {
            PlayFootstepSound(client);
            return Plugin_Stop;
        }
    }
    return Plugin_Continue;
}

public void OnConVarChange(ConVar convar, const char[] oldValue, const char[] newValue) {
    if (convar == g_cFog) {
        g_cFog.SetInt(StringToInt(newValue));
        FogEnable(g_cFog.BoolValue);
    }
    else if (convar == g_cFogDensity) {
        float val = StringToFloat(newValue);
        g_cFogDensity.SetFloat(val);
        if (g_iFogIndex != -1) {
            DispatchKeyValueFloat(g_iFogIndex, "fogmaxdensity", val);
        }
    }
    else if (convar == g_cFogStartDist) {
        int val = StringToInt(newValue);
        g_cFogStartDist.SetInt(val);
        if (g_iFogIndex != -1) {
            SetVariantInt(val);
            AcceptEntityInput(g_iFogIndex, "SetStartDist");
        }
    }
    else if (convar == g_cFogEndDist) {
        int val = StringToInt(newValue);
        g_cFogEndDist.SetInt(val);
        if (g_iFogIndex != -1) {
            SetVariantInt(val);
            AcceptEntityInput(g_iFogIndex, "SetEndDist");
        }
    }
    else if (convar == g_cFogColor) {
        g_cFogColor.SetString(newValue);
        if (g_iFogIndex != -1) {
            SetVariantString(newValue);
            AcceptEntityInput(g_iFogIndex, "SetColor");
            SetVariantString(newValue);
            AcceptEntityInput(g_iFogIndex, "SetColorSecondary");
        }
    }
    else if (convar == g_cFogZPlane) {
        int val = StringToInt(newValue);
        g_cFogZPlane.SetInt(val);
        if (g_iFogIndex != -1) {
            SetVariantInt(val);
            AcceptEntityInput(g_iFogIndex, "SetFarZ");
        }
    }
    else if (convar == g_cCountDown) {
        int value = StringToInt(newValue) > 10?10:StringToInt(newValue);
        g_cCountDown.SetInt(value);
        g_iCountdownNumber = value;
    }
}
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    InitMethodMaps();
    InitNatives();
    InitForwards();
    // Register mod library
    RegPluginLibrary("zombieswarm");

    return APLRes_Success;
}
public void OnEntityCreated(int entity, const char[] classname) {
    if(!entity)
        return;
    
    if (StrEqual("info_player_terrorist",classname)) {
        SDKHook(entity, SDKHook_SpawnPost, OnTsEntitySpawnPost);
    } else if (StrEqual("info_player_counterterrorist",classname)) {
        SDKHook(entity, SDKHook_SpawnPost, OnCTsEntitySpawnPost);
    } else if (StrEqual("sky_camera",classname)) {
        SDKHook(entity, SDKHook_SpawnPost, OnSkyCameraSpawnPost);
    } else if (StrEqual("func_bomb_target",classname)) {
        SDKHook(entity, SDKHook_SpawnPost, RemoveMapEntity);
    } else if (StrEqual("func_hostage_rescue",classname)) {
        SDKHook(entity, SDKHook_SpawnPost, RemoveMapEntity);
    } else if (StrEqual("hostage_entity",classname)) {
        SDKHook(entity, SDKHook_SpawnPost, RemoveMapEntity);
    } else if (StrEqual("func_buyzone",classname)) {
        SDKHook(entity, SDKHook_SpawnPost, RemoveMapEntity);
    }
}

public void OnTsEntitySpawnPost(int EntRef) {
    int entity = EntRefToEntIndex(EntRef);
    float Vec[3];
    
    GetEntPropVector(entity, Prop_Data, "m_vecOrigin", Vec);
    Vec[2] = (Vec[2] + 73);
    g_fSpawns[CS_TEAM_T][g_iTSpawns] = Vec;
    g_iTSpawns++;
    
    SDKUnhook(entity, SDKHook_SpawnPost, OnTsEntitySpawnPost);
}
public void OnCTsEntitySpawnPost(int EntRef) {
    int entity = EntRefToEntIndex(EntRef);
    float Vec[3];

    GetEntPropVector(entity, Prop_Data, "m_vecOrigin", Vec);
    Vec[2] = (Vec[2] + 73);
    g_fSpawns[CS_TEAM_CT][g_iCTSpawns] = Vec;
    g_iCTSpawns++;
    
    SDKUnhook(entity, SDKHook_SpawnPost, OnCTsEntitySpawnPost);
}
public void OnSkyCameraSpawnPost(int EntRef) {
    g_iSkyCameraIndex = EntRefToEntIndex(EntRef);
    AcceptEntityInput(g_iSkyCameraIndex, "Kill");
}
public void RemoveMapEntity(int EntRef) {
    int index = EntRefToEntIndex(EntRef);
    AcceptEntityInput(index, "Kill");
}
public void OnCascadeLightSpawnPost(int EntRef) {
    g_iCascadeLightIndex = EntRefToEntIndex(EntRef);
}
public void OnMapEnd() {
    float Vec[3];
    Vec[0] = 0.0;
    Vec[1] = 0.0;
    Vec[2] = 0.0;
    for (int i = 0; i <= g_iTSpawns; i++) {
        g_fSpawns[CS_TEAM_T][i] = Vec;
    }
    for (int i = 0; i <= g_iCTSpawns; i++) {
        g_fSpawns[CS_TEAM_T][i] = Vec;
    }
    
    g_iTSpawns = 0;
    g_iCTSpawns = 0;
}
public void OnMapStart()
{
    BuildPath(Path_SM, g_sDownloadFilesPath, sizeof(g_sDownloadFilesPath), "configs/swarm/zm_downloads.txt");
    gI_Players = 0;
    g_aZombieSounds.Clear();
    g_bRoundEnded = false;
    
    g_iCountdownNumber = g_cCountDown.IntValue > 10?10:g_cCountDown.IntValue;
    
    PrecacheModel(DEFAULT_ARMS);
    
    PrecacheSoundAny("radio/terwin.wav", true);
    PrecacheSoundAny("radio/ctwin.wav", true);
    
    char overlay_ct[125], overlay_t[125];
    g_cOverlayTWin.GetString(overlay_t,sizeof(overlay_t));
    g_cOverlayCTWin.GetString(overlay_ct,sizeof(overlay_ct));
    
    PrecacheDecal(overlay_t);
    PrecacheDecal(overlay_ct);
    AddFileToDownloadsTable(overlay_t);
    AddFileToDownloadsTable(overlay_ct);
    
    // Set team names
    SetConVarString(FindConVar("mp_teamname_1"), "HUMANS");
    SetConVarString(FindConVar("mp_teamname_2"), "ZOMBIES");
    
    // Get round time
    float roundTime = GetConVarFloat(FindConVar("mp_roundtime"));
    
    // Bug fix for standart maps
    SetConVarFloat(FindConVar("mp_roundtime_hostage"), roundTime);
    SetConVarFloat(FindConVar("mp_roundtime_defuse"),  roundTime);
    
    // Remove free armor
    SetConVarInt(FindConVar("mp_free_armor"), 0);
    
    SetConVarInt(FindConVar("mp_timelimit"), 20);
    SetConVarInt(FindConVar("mp_maxrounds"), 0);
    SetConVarInt(FindConVar("mp_friendlyfire"), 0);

    int ent; 
    ent = FindEntityByClassname(-1, "env_fog_controller");
    if (ent != -1)  {
        g_iFogIndex = ent;
    }
    else {
        g_iFogIndex = CreateEntityByName("env_fog_controller");
        DispatchSpawn(g_iFogIndex);
    }

    g_iSunIndex = FindEntityByClassname(-1, "env_sun");

    CreateFog();
    FogEnable(g_cFog.BoolValue);
    
    UTIL_LoadSounds();
    UTIL_LoadZombieSounds();
    defaultsoundindex = FindZombieSoundsIndex(DEFAULT_SOUND_PACK);
    
    // Initialize some chars
    char zBuffer[PLATFORM_MAX_PATH];

    //**********************************************
    //* Zombie class precache                          *
    //**********************************************
    for (int i = 0; i < g_aZombieClass.Length; i++)
    {
        g_esZombieClass temp_checker;
        g_aZombieClass.GetArray(i, temp_checker, sizeof(temp_checker));

        //****************  Player ****************//
        // Path should be models/player/custom_player/cso2_zombi/zombie
        
        Format(zBuffer, sizeof(zBuffer), "%s.mdl", temp_checker.dataModel);
        PrecacheModel(zBuffer);
        AddFileToDownloadsTable(zBuffer);

        Format(zBuffer, sizeof(zBuffer), "%s.dx90.vtx", temp_checker.dataModel);
        AddFileToDownloadsTable(zBuffer);
        
        Format(zBuffer, sizeof(zBuffer), "%s.phy", temp_checker.dataModel);
        AddFileToDownloadsTable(zBuffer);
        
        Format(zBuffer, sizeof(zBuffer), "%s.vvd", temp_checker.dataModel);
        AddFileToDownloadsTable(zBuffer);
        
        if (strlen(temp_checker.dataArms)) {
            Format(zBuffer,sizeof(zBuffer),"%s",temp_checker.dataArms);
            AddFileToDownloadsTable(zBuffer);
        }
    }

    // Open file
    File iDocument = OpenFile(g_sDownloadFilesPath, "r");
    
    // Initialize chars
    char szBuffer[PLATFORM_MAX_PATH];
    int szBufferText = sizeof(szBuffer);
    
    // If doesn't exist turn off server
    if(iDocument == null)
    {
        SetFailState("[ZM] File zm_downloads.txt doesn't exist!\n\n");
        return;
    }
    
    // Read through file
    while (ReadFileLine(iDocument, szBuffer, szBufferText))
    {    
        // If end of file, stop
        if (IsEndOfFile(iDocument))
            break;

        // If char long, make sure that it will be split
        int iLength = strlen(szBuffer);
        
        if (szBuffer[iLength-1] == '\n')
        {
            szBuffer[--iLength] = '\0';
        }
        
        // Removes whitespace at the begin and end of char
        TrimString(szBuffer);
        
        // If char have commentaries, skip
        if(StrContains(szBuffer, "//", false) != -1 || StrContains(szBuffer, "/*", false) != -1 || StrContains(szBuffer, ";", false) != -1)
            continue;
        
        // Read not empty char
        if(!StrEqual(szBuffer, "", false))
        {
            AddFileToDownloadsTable(szBuffer);
        }
    }
    
    if(iDocument != null)
    {
        // We're done with this file now, so we can close it
        delete iDocument;
    }

    int tempEnt = -1;
    while((tempEnt = FindEntityByClassname(tempEnt, "func_bomb_target")) != -1)
    {
        AcceptEntityInput(tempEnt,"kill");
    }
    
    while((tempEnt = FindEntityByClassname(tempEnt, "func_hostage_rescue")) != -1) 
    {
        AcceptEntityInput(tempEnt,"kill");
    }
}
public Action Event_SoundPlayed(int clients[MAXPLAYERS-1], int &numClients, char[] sample, int &entity, int &iChannel, float &flVolume, int &iLevel, int &iPitch, int &iFlags) {
    if (IsValidWeapon(entity)) {
        int owner = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
        if (!UTIL_IsValidAlive(owner))
            return Plugin_Continue;
        if (GetClientTeam(owner) != CS_TEAM_T)
            return Plugin_Continue;
        if (g_cGhostMode.BoolValue && g_bGhost[owner])
            return Plugin_Stop;
        char sWeapon[64];
        GetWeaponClassname(entity, sWeapon, sizeof(sWeapon));
        if (StrContains(sWeapon, "knife") == -1)
            return Plugin_Continue;

        if (g_cSoundsHit.BoolValue && StrContains(sample, "knife/knife_hit", false) >= 0) {
            if (g_bDidHit[owner])
                PlayHitSound(owner);
            else 
                PlayMissSound(owner);
            return Plugin_Stop;
        }
        if (g_cSoundsMiss.BoolValue && StrContains(sample, "knife/knife_slash", false) >= 0) {
            PlayMissSound(owner);
            return Plugin_Stop;
        }
    }
    if (UTIL_IsValidAlive(entity) && GetClientTeam(entity) == CS_TEAM_T) {
        if (g_cGhostMode.BoolValue && g_bGhost[entity]) return Plugin_Stop;
        if (defaultsoundindex == -1) return Plugin_Continue;
        if (
            StrContains(sample, "player/death", false) >= 0 ||
            StrContains(sample, "physics/flesh", false) >= 0 ||
            StrContains(sample, "player/footstep", false) >= 0 ||
            StrContains(sample, "player/headshot", false) >= 0 ||
            StrContains(sample, "player/kevlar", false) >= 0
        ) return Plugin_Stop;
    }
    
    return Plugin_Continue;
}

// https://github.com/kgns/weapons/blob/2e4a949335b683b680d97fd8a4c7f0a0bc8c4f76/addons/sourcemod/scripting/weapons/helpers.sp#L146-L161
stock bool IsValidWeapon(int weaponEntity)
{
	if (weaponEntity > 4096 && weaponEntity != INVALID_ENT_REFERENCE) {
		weaponEntity = EntRefToEntIndex(weaponEntity);
	}
	
	if (!IsValidEdict(weaponEntity) || !IsValidEntity(weaponEntity) || weaponEntity == -1) {
		return false;
	}
	
	char weaponClass[64];
	GetEdictClassname(weaponEntity, weaponClass, sizeof(weaponClass));
	
	return StrContains(weaponClass, "weapon_") == 0;
}

void CreateFog() {
    if(g_iFogIndex != -1)  {
        float FogDensity = GetConVarFloat(g_cFogDensity);
        int FogStartDist = GetConVarInt(g_cFogStartDist);
        int FogEndDist = GetConVarInt(g_cFogEndDist);
        int FogZPlane = GetConVarInt(g_cFogZPlane);
        DispatchKeyValueFloat(g_iFogIndex, "fogmaxdensity", FogDensity);
        SetVariantInt(FogStartDist);
        AcceptEntityInput(g_iFogIndex, "SetStartDist");
        SetVariantInt(FogEndDist);
        AcceptEntityInput(g_iFogIndex, "SetEndDist");
        SetVariantInt(FogZPlane);
        AcceptEntityInput(g_iFogIndex, "SetFarZ");
    
        char FogColor[32];
        GetConVarString(g_cFogColor, FogColor, sizeof(FogColor));    

        SetVariantString(FogColor);
        AcceptEntityInput(g_iFogIndex, "SetColor");
        
        SetVariantString(FogColor);
        AcceptEntityInput(g_iFogIndex, "SetColorSecondary");
        
    }
}

void FogEnable(bool status) {
    if (g_iFogIndex != -1) {
        if (status) {
            AcceptEntityInput(g_iFogIndex, "TurnOn");
        }
        else
            AcceptEntityInput(g_iFogIndex, "TurnOff");
    }
    
    if (g_iSunIndex != -1) {
        if (status)
            AcceptEntityInput(g_iSunIndex, "TurnOff");
        else
            AcceptEntityInput(g_iSunIndex, "TurnOn");
    }
    
    if (status) {
        if (g_iCascadeLightIndex != -1) {
            AcceptEntityInput(g_iCascadeLightIndex, "Disable");
            SetLightStyle(0,"a");
        }
    }
    else {
        if (g_iCascadeLightIndex != -1) {
            AcceptEntityInput(g_iCascadeLightIndex, "Enable");
            SetLightStyle(0,"");
        }
        
    }
    
    DispatchKeyValue(0, "skyname", "embassy");
}

public void OnGameFrame()
{
    if (!g_cGhostMode.BoolValue)
        return;
    int client;
    for (client = 1; client <= MaxClients; client++) 
    {
        if (UTIL_IsValidClient(client)) {
            int target = UTIL_IsPlayerStuck(client); 
            
            if (target < 0) {
                g_bShouldCollide[client] = false;
            } else {
                if (UTIL_IsValidClient(target) && (g_bGhost[client] || g_bGhost[target])) {
                    //if (UTIL_IsValidClient(target)) {
                    g_bShouldCollide[target] = true;
                    g_bShouldCollide[client] = true;
                }
            }
        }
    }
}

public void OnClientPutInServer(int client)
{
	if(++gI_Players == 1)
	{
		CS_TerminateRound(0.1, CSRoundEnd_Draw);
	}
}

public void OnClientPostAdminCheck(int client)
{
    g_bCanJoin[client] = true;
    g_bCanIgnore[client] = false;
    
    SDKHook(client, SDKHook_OnTakeDamage, onTakeDamage);
    SDKHook(client, SDKHook_TraceAttack, onTraceAttack);
    SDKHook(client, SDKHook_WeaponCanUse, onWeaponCanUse);
    ClearPlayerAbilities(client);

     // Ghost mod related
    if (!g_cGhostMode.BoolValue)
        return;
    SDKHook(client, SDKHook_ShouldCollide, onShouldCollide);
    SDKHook(client, SDKHook_SetTransmit, onSetTransmit);
    //SDKHook(client, SDKHook_StartTouch, onTouch);
    //SDKHook(client, SDKHook_Touch, onTouch);
    SDKHook(client, SDKHook_PostThinkPost, onPostThinkPost);
}

public void OnClientDisconnect(int client)
{
    if ( !IsClientInGame(client) )
        return;
    
    g_bCanJoin[client] = false;
    g_bCanIgnore[client] = false;
    
    g_iTeam[client] = CS_TEAM_NONE;

    g_bOverrideHint[client] = false;
    
    if (g_hTimerGhostHint[client] != null) {
        delete g_hTimerGhostHint[client];
    }
    
    if (g_hTimerZombieRespawn[client] != null) {
        delete g_hTimerZombieRespawn[client];
    }
    
    if (g_hTimerCooldown[client] != null) {
        delete g_hTimerCooldown[client];
        g_hTimerCooldown[client] = null;
    }
    ClearPlayerAbilities(client);
    g_iZombieRespawnLeft[client] = 0;
    g_fLastButtons[client] = 0;
    g_bCooldown[client] = false;
}

public void ClearPlayerAbilities(int client) {
    if (!UTIL_IsValidClient(client))
        return;
    for (int i = 0; i < g_aPlayerAbility.Length; i++)
    {
        if (i == g_aPlayerAbility.Length)
            break;

        g_esPlayerAbility temp_checker;
        g_aPlayerAbility.GetArray(i, temp_checker, sizeof(temp_checker));

        if(temp_checker.paClient == client) {
            if (temp_checker.paTimerDuration != null) {
                delete temp_checker.paTimerDuration;
                temp_checker.paTimerDuration = null;
            }
            if (temp_checker.paTimerCooldown != null) {
                delete temp_checker.paTimerCooldown;
                temp_checker.paTimerCooldown = null;
            }
            g_aPlayerAbility.Erase(i--);
        }
    }
}

public void onPostThinkPost(int client)
{
    if(g_bGhost[client] && GetClientTeam(client) == CS_TEAM_T) {
        SetEntData(client, g_iCollisionOffset, 2, 1, true);
    } else {
        SetEntData(client, g_iCollisionOffset, 5, 4, true);
    }
}

public Action onWeaponCanUse(int client, int weapon)
{
    if ( !UTIL_IsValidAlive(client) )
        return Plugin_Handled;
    
    char sWeapon[32];
    GetEdictClassname(weapon, sWeapon, sizeof(sWeapon));
    
    if (GetClientTeam(client) == CS_TEAM_T && !(StrContains(sWeapon, "knife")>=0)) {
        return Plugin_Handled;
    }
    
    return Plugin_Continue;
}

public Action onTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
    if ( !UTIL_IsValidClient(victim) )
        return Plugin_Continue;
    
    if (GetClientTeam(victim) == CS_TEAM_T) {
        if (damagetype & DMG_FALL)
        return Plugin_Handled;
    }
    
    if ( !UTIL_IsValidClient(attacker) )
        return Plugin_Continue;
    
    if (victim == attacker)
        return Plugin_Continue;
    
    if (g_bRoundEnded)
        return Plugin_Handled;
    
    if (g_cGhostMode.BoolValue && (g_bGhost[victim] || g_bGhost[attacker]))
        return Plugin_Handled;

    bool changed = false;
    // Apply custom zombie damage
    if (GetClientTeam(attacker) == CS_TEAM_T && GetClientTeam(victim) == CS_TEAM_CT) {
        g_bDidHit[attacker] = true;
        int zm_id = FindZombieIndex(g_iZombieClass[attacker]);
        g_esZombieClass class;
        g_aZombieClass.GetArray(zm_id, class, sizeof(class));
        float zmdamage = class.dataDamage;
        damage = zmdamage;
        changed = true;
    }

    // If both players in tunnel (ducking), lets give zombie some advantage by making human dmg lower.
    if (GetClientTeam(victim) == CS_TEAM_T && GetClientTeam(attacker) == CS_TEAM_CT && GetEntityFlags(victim) & FL_DUCKING && GetEntityFlags(attacker) & FL_DUCKING) {
        damage *= 0.33;
        changed = true;
    }
    if (GetGameTime() >= g_fNextPain[victim] && GetClientTeam(victim) == CS_TEAM_T && g_cSoundsPain.BoolValue) PlayPainSound(victim);
    return changed ? Plugin_Changed : Plugin_Continue;

}

public Action onTraceAttack(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &ammotype, int hitbox, int hitgroup)
{
    if ( !UTIL_IsValidClient(victim) )
        return Plugin_Continue;
    
    if ( !UTIL_IsValidClient(attacker) )
        return Plugin_Continue;
    
    if (victim == attacker)
        return Plugin_Continue;
    
    if (g_bRoundEnded)
        return Plugin_Handled;
    
    if (g_cGhostMode.BoolValue && (g_bGhost[victim] || g_bGhost[attacker]))
        return Plugin_Handled;
    
    return Plugin_Continue;
}

public Action onSetTransmit(int entity, int client) 
{
    if ( !UTIL_IsValidAlive(entity) || !UTIL_IsValidAlive(client) ) return Plugin_Continue;
    
    if (entity == client) return Plugin_Continue;
    
    if ( g_iTeam[entity] != g_iTeam[client] && !g_bGhost[client]
            && g_iTeam[entity] == CS_TEAM_T && g_bGhost[entity] )
    return Plugin_Handled; 
    
    // Hide near human for ghost zombie    
    if ( g_iTeam[entity] != g_iTeam[client] && !g_bGhost[entity]
            && GetClientTeam(client) == CS_TEAM_T && g_bGhost[client] && g_bShouldCollide[client] && g_bShouldCollide[entity] )
    return Plugin_Handled; 
    
    if (g_iTeam[entity] == g_iTeam[client] && !g_bGhost[client] && g_iTeam[entity] == CS_TEAM_T 
            && g_bGhost[entity])
    return Plugin_Handled;
    
    if (g_iTeam[entity] == g_iTeam[client] && g_bGhost[client] && g_iTeam[entity] == CS_TEAM_T 
            && g_bGhost[entity] && g_bShouldCollide[client] && g_bShouldCollide[entity])
    return Plugin_Handled;
    
    return Plugin_Continue;
}

public bool onShouldCollide(int entity, int collisiongroup, int contentsmask, bool result ) 
{
    if (g_bShouldCollide[entity]) {
        collisiongroup = 2;
        contentsmask = (CONTENTS_SOLID | CONTENTS_MOVEABLE | CONTENTS_PLAYERCLIP | CONTENTS_WINDOW | CONTENTS_MONSTER | CONTENTS_GRATE | CONTENTS_TEAM1 | CONTENTS_TEAM2);
        result = false;
        return false;
    }

    result = true;
    return true;
}

public void onTouch(int ent1, int ent2)
{
    if(ent1 == ent2)
        return;
    
    if(!UTIL_IsValidClient(ent1))
        return;
    
    if(!UTIL_IsValidClient(ent2))
        return;
    
    //if(g_iTeam[ent1] != g_iTeam[ent2] && g_bGhost[ent1])
    if(g_iTeam[ent1] != g_iTeam[ent2])
    {
        g_bShouldCollide[ent1] = true;
        g_bShouldCollide[ent2] = true;
        return;
    }
    
    g_bShouldCollide[ent1] = false;
    g_bShouldCollide[ent2] = false;
}

public Action blockKill(int client, const char[] command, int argc)
{
    return Plugin_Handled;
}

public Action joinTeam(int client, const char[] command, int argc)
{
    if (IsFakeClient(client))
        return Plugin_Continue;
    
    if (!UTIL_IsValidClient(client)) 
        return Plugin_Handled;
    
    if (IsPlayerAlive(client)) 
        return Plugin_Handled;
    
    if (IsClientSourceTV(client)) 
        return Plugin_Handled;
    
    if (!g_bCanJoin[client])
        return Plugin_Handled;
    
    char sTeam[4];
    GetCmdArg( 1, sTeam, sizeof(sTeam));
    int iTeam = StringToInt(sTeam);

    if ( iTeam == CS_TEAM_CT || iTeam == CS_TEAM_T || iTeam == CS_TEAM_NONE
            || iTeam == CS_TEAM_SPECTATOR ) {
        g_bCanJoin[client] = false;
        
        if (getHumans() >= GetConVarInt(g_cRoundStartZombies)) {
            CS_SwitchTeam( client, CS_TEAM_T );
            CreateTimer( 0.5, respawnClientOnConnect, client, TIMER_FLAG_NO_MAPCHANGE);
        } else {
            if ( getHumans() > getZombies() ) {
                CS_SwitchTeam( client, CS_TEAM_T );    
                CreateTimer( 0.5, respawnClientOnConnect, client, TIMER_FLAG_NO_MAPCHANGE);
            } else {
                CS_SwitchTeam( client, CS_TEAM_CT );
                if ( g_iRoundKillCounter < GetConVarInt(g_cRoundKillsTeamJoinHumans) )    
                CreateTimer( 0.5, respawnClientOnConnect, client, TIMER_FLAG_NO_MAPCHANGE);
            }
        }

        if(getTrueCT() == getTrueT()) {
            g_iTeam[client] = CS_TEAM_CT;
        } else if (getTrueCT() > getTrueT()) {
            g_iTeam[client] = CS_TEAM_T;
        } else {
            g_iTeam[client] = CS_TEAM_CT;
        }


    }
    
    return Plugin_Handled;
}

public void eventPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    g_iRoundKillCounter++;
    
    int victim = GetClientOfUserId(GetEventInt(event, "userid"));

    if ( !UTIL_IsValidClient(victim) )
        return;
    if (IsClientSourceTV(victim)) 
        return;

    if (g_hTimerGhostHint[victim] != null) {
        delete g_hTimerGhostHint[victim];
    }
    ClearPlayerAbilities(victim);
    if (GetClientTeam(victim) == CS_TEAM_CT && getHumans() > 1) {
        g_bCanIgnore[victim] = true;
        //CS_SwitchTeam( victim, CS_TEAM_T );
        g_iZombieRespawnLeft[victim] = (IsClientVip(victim)) ? GetConVarInt(g_cRespawnTimeSVip) : GetConVarInt(g_cRespawnTimeS);
        g_hTimerZombieRespawn[victim] = CreateTimer( 1.0, timerZombieRespawnCallback, victim, TIMER_FLAG_NO_MAPCHANGE);
    } else if (GetClientTeam(victim) == CS_TEAM_T) {
        if (g_cSoundsDeathEnable.BoolValue) PlayDeathZombieSound(victim);
        g_iZombieRespawnLeft[victim] = (IsClientVip(victim)) ? GetConVarInt(g_cRespawnTimeZVip) : GetConVarInt(g_cRespawnTimeZ);
        g_hTimerZombieRespawn[victim] = CreateTimer( 1.0, timerZombieRespawnCallback, victim, TIMER_FLAG_NO_MAPCHANGE);
        
        if (g_hTimerCooldown[victim] != null) {
            delete g_hTimerCooldown[victim];
        }
    }
}

stock bool IsClientVip(int client)
{
    if (GetUserFlagBits(client) & ADMFLAG_RESERVATION || GetUserFlagBits(client) & ADMFLAG_ROOT) 
        return true;
    return false;
}

public void eventPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));

    if ( !UTIL_IsValidAlive(client) )
        return;
    
    if (g_hTimerZombieRespawn[client] != null) {
        delete g_hTimerZombieRespawn[client];
    }
    
    g_fHintSpeed[client] = TIMER_SPEED;
    g_bOverrideHint[client] = false;

    g_iZombieRespawnLeft[client] = 0;

    if (GetClientTeam(client) == CS_TEAM_T) {
        
        if (g_cGhostMode.BoolValue) {
            // Set zombie ghost mode
            setZombieGhostMode(client, true);
            
            g_hTimerGhostHint[client] = CreateTimer( 1.0, ghostHint, client, TIMER_FLAG_NO_MAPCHANGE);
            
            Menu menu = new Menu(ZombieClassMenuHandler);
            menu.SetTitle("%t","Select zombie class");
            
            char className[MAX_CLASS_NAME_SIZE], key[MAX_CLASS_ID];
            for (int i = 0; i < g_aZombieClass.Length; i++)
            {
                g_esZombieClass temp_checker;
                g_aZombieClass.GetArray(i, temp_checker, sizeof(temp_checker));
                if(!temp_checker.dataExcluded) {
                    Format(className,sizeof(className),"%s",temp_checker.dataName);
                    IntToString(i,key,sizeof(key));
                    menu.AddItem(key, className);
                }
            }
            menu.ExitButton = true;
            menu.Display(client, 0);
        } else {
            int random = getRandZombieClass();
            g_esZombieClass temp_checker;
            g_aZombieClass.GetArray(random, temp_checker, sizeof(temp_checker));
            g_iZombieClass[client] = temp_checker.dataID;

            g_bGhost[client] = false;
            setZombieClassParameters(client);
            AssignPlayerAbilities(client);
            callZombieSelected(client, temp_checker.dataID);
            
            CPrintToChat(client,"%t","Random Zombie class",temp_checker.dataName);
            
            g_hTimerGhostHint[client] = CreateTimer( 1.0, ghostHint, client, TIMER_FLAG_NO_MAPCHANGE);
        }
        
    } else if (GetClientTeam(client) == CS_TEAM_CT) {
        SetEntityGravity(client, g_cHumanGravity.FloatValue); 
        g_bGhost[client] = false;
    }
    // Hide RADAR
    CreateTimer(0.0, RemoveRadar, client);
}
public int ZombieClassMenuHandler(Menu menu, MenuAction action, int client, int param2) {
    if (UTIL_IsValidClient(client)) {
        g_esZombieClass temp_checker;
        if (action == MenuAction_Select && GetClientTeam(client) == CS_TEAM_T && g_bGhost[client]) {
            char key[MAX_CLASS_ID];
            menu.GetItem(param2, key, sizeof(key));
            int classInt = StringToInt(key);
            g_aZombieClass.GetArray(classInt, temp_checker, sizeof(temp_checker));

            g_iZombieClass[client] = temp_checker.dataID;
            setZombieClassParameters(client);
            callZombieSelected(client, temp_checker.dataID);
            
            CPrintToChat(client,"%t","You selected",temp_checker.dataName);
            if (strlen(temp_checker.dataDescription)) {
                CPrintToChat(client,"%t","Zombie Selected Description", temp_checker.dataDescription);
            }
        }
        else if (action == MenuAction_Cancel) {
            int random = getRandZombieClass();
            g_aZombieClass.GetArray(random, temp_checker, sizeof(temp_checker));
            g_iZombieClass[client] = temp_checker.dataID;

            setZombieClassParameters(client);
            callZombieSelected(client, temp_checker.dataID);
            
            CPrintToChat(client,"%t","Random Zombie class",temp_checker.dataName);
            if (strlen(temp_checker.dataDescription)) {
                CPrintToChat(client,"%t","Zombie Selected Description", temp_checker.dataDescription);
            }
        }
    }
}
public Action eventRoundFreezeEnd(Event event, const char[] name, bool dontBroadcast)
{
    if(g_cGhostMode.BoolValue) {
        g_bGhostCanSpawn = false;
        if (g_hTimerCountDown != INVALID_HANDLE) {
            KillTimer(g_hTimerCountDown);
        }
        
        g_hTimerCountDown = CreateTimer(1.0, CountDown, _, TIMER_REPEAT);
    } else {
        g_bGhostCanSpawn = true;
    }
}

public Action eventRoundStart(Event event, const char[] name, bool dontBroadcast)
{
    
    g_iRoundKillCounter = 0;
    g_bRoundEnded = false;
    g_bGhostCanSpawn = false;
    
    int ent = -1;
    while((ent = FindEntityByClassname(ent, "light"))!=-1){
        AcceptEntityInput(ent, "TurnOff");
        break;
    }
    
    // Names of entities, which will be remove every round
    //#define ROUNDSTART_OBJECTIVE_ENTITIES "func_bomb_target_hostage_entity_func_hostage_rescue_func_buyzoneprop_physics_overrideprop_physics_multiplayer"
    
    // Removes all entities with a targetname that match in ROUNDSTART_OBJECTIVE_ENTITIES,
    // and removes them, so standart map will avalible for playing
    //removeMapEventEntity(ROUNDSTART_OBJECTIVE_ENTITIES); 
    int removEnt = -1;
    while((removEnt = FindEntityByClassname(removEnt, "hostage_entity")) != -1)
    {
        AcceptEntityInput(removEnt, "kill");
    }
    while((removEnt = FindEntityByClassname(removEnt, "func_buyzone")) != -1)
    {
        AcceptEntityInput(removEnt, "kill");
    }
    
}

public Action eventWinPanelRound(Event event, const char[] name, bool dontBroadcast)
{
    // Set dont broadcast for panel
    if(dontBroadcast == false) 
    {
        SetEventBroadcast(event, true); 
    }
    
    return Plugin_Continue; 
}

public void eventRoundEnd(Event event, const char[] name, bool dontBroadcast)
{
    g_iRoundKillCounter = 0;
    
    g_bRoundEnded = true;
    
    int winner = GetEventInt(event, "winner");
    
    for (int client = 1; client <= MaxClients; client++) 
    { 
        if (UTIL_IsValidClient(client) )
        {    
            if (g_hTimerZombieRespawn[client] != null) {
                delete g_hTimerZombieRespawn[client];
            }

            g_iZombieRespawnLeft[client] = 0;
            
            /*StopSound(client, SNDCHAN_STATIC, "radio/ctwin.wav");
            StopSound(client, SNDCHAN_STATIC, "radio/rounddraw.wav");
            StopSound(client, SNDCHAN_STATIC, "radio/terwin.wav");*/
            
            char overlay[125];
            
            if(winner == CS_TEAM_T) {
                int randomSound = GetRandomInt(0, g_iTotalZombieWinSounds);
                g_cOverlayTWin.GetString(overlay,sizeof(overlay));
                
                UTIL_PlayClientCommandSound(client, g_ZombieWinSounds[randomSound]);
            } else if(winner == CS_TEAM_CT) {
                int randomSound = GetRandomInt(0, g_iTotalHumanWinSounds);
                g_cOverlayCTWin.GetString(overlay,sizeof(overlay));
                
                UTIL_PlayClientCommandSound(client, g_HumanWinSounds[randomSound]);
            }
            
            if (g_cOverlayEnable.BoolValue) {
                if (strlen(overlay) > 0) {
                    ShowOverlayAll(overlay,5.0);
                }
            }
            
            g_bCooldown[client] = false;
            if (g_hTimerCooldown[client] != null) {
                delete g_hTimerCooldown[client];
            }
            ClearPlayerAbilities(client);
        }
    }

    // Use custom plugin for handling it.
    //setTeamBalance();
}



public Action eventTeamChange(Event event, const char[] name, bool dontBroadcast)
{
    //int client = GetClientOfUserId(GetEventInt(event, "userid"));
    //int team = GetEventInt(event, "team");
    
    // Block change team message
    if(!dontBroadcast) 
    { 
        // Execute event and block it
        Event sEvent = CreateEvent("player_team", true);  

        SetEventInt(sEvent, "userid", GetEventInt(event, "userid")); 
        SetEventInt(sEvent, "team", GetEventInt(event, "team")); 
        SetEventInt(sEvent, "oldteam", GetEventInt(event, "oldteam")); 
        SetEventBool(sEvent, "disconnect", GetEventBool(event, "disconnect")); 
        
        FireEvent(sEvent, true); 
    }
    
    return Plugin_Handled;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float velocity[3], float angles[3], int &weapon, int &subtype, int &cmdNum, int &tickCount, int &seed, int mouse[2])
{
    if ( !UTIL_IsValidAlive(client) )
        return Plugin_Continue;
    
    if (GetClientTeam(client) != CS_TEAM_T) 
        return Plugin_Continue;
    
    if (!g_bGhost[client] || !g_cGhostMode.BoolValue) {
        for (int i = 0; i < g_aPlayerAbility.Length; i++)
        {
            g_esPlayerAbility temp_checker;
            g_aPlayerAbility.GetArray(i, temp_checker, sizeof(temp_checker));
            // Skip those undefined ones
            if (temp_checker.paButtons & IN_BULLRUSH) {
                continue;
            }
            if(temp_checker.paClient != client) {
                continue;
            }
            int pressed = GetEntProp(client, Prop_Data, "m_afButtonPressed");
            int released = GetEntProp(client, Prop_Data, "m_afButtonReleased");
            if (pressed & temp_checker.paButtons) {
                if (temp_checker.paState != stateIdle)
                    continue;
                Call_StartForward(g_hForwardAbilityButtonPressed);
                Call_PushCell(client);
                Call_PushCell(temp_checker.paID);
                Call_Finish();
            } else if (released & temp_checker.paButtons) {
                if (temp_checker.paState != stateRunning)
                    continue;
                Call_StartForward(g_hForwardAbilityButtonReleased);
                Call_PushCell(client);
                Call_PushCell(temp_checker.paID);
                Call_Finish();
            }
        }

    } else {
        if (!g_cGhostMode.BoolValue) {
            return Plugin_Continue;
        }
        if ((buttons & IN_ATTACK)) {
            char hintText[512];
            if (!UTIL_IsClientInTargetsView(client)) {
                if (g_bGhostCanSpawn) {
                    setZombieGhostMode(client, false);
                    AssignPlayerAbilities(client);
                    int zm_id = FindZombieIndex(client);
                    g_esZombieClass class;
                    g_aZombieClass.GetArray(zm_id, class, sizeof(class));
                    float tSpeed = class.dataSpeed;
                    // Set zombie speed
                    SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", tSpeed);
                    
                    Format(hintText, sizeof(hintText), "%t","Hint: You have been revived");
                    UTIL_ShowHintMessage(client, hintText);
                } else {
                    Format(hintText, sizeof(hintText), "%t","Hint: Wait a little bit");
                    UTIL_ShowHintMessage(client, hintText);
                }
            } else {
                Format(hintText, sizeof(hintText), "%t","Hint: Hide from humans to respawn");
                UTIL_ShowHintMessage(client, hintText);
            }
        }
        /*if ((buttons & IN_RELOAD)) {
            if (g_iTSpawns > 0) {
                int random = GetRandomInt(0,g_iTSpawns);
                float spawn[3];
                spawn = g_fSpawns[CS_TEAM_T][random];
                if (UTIL_IsValidClient(client) && g_bGhost[client] && (spawn[0] != 0.0 && spawn[1] != 0.0 && spawn[2] != 0.0))
                    TeleportEntity(client, spawn, NULL_VECTOR, NULL_VECTOR);
            }
            else {
                CPrintToChat(client,"%t","Chat: No valid spawns found");
            }
        }*/
    }
    return Plugin_Continue;
}

public Action teleportZombieToHuman(Handle timer, any client)
{
    if ( !UTIL_IsValidAlive(client) || g_iTeam[client] != CS_TEAM_T || !g_bGhost[client] ) {
        return Plugin_Continue;
    }
    
    float targetOrigin[3], changedTargetOrigin[3];
    
    int rClient = UTIL_GetRandomHuman();
    if (UTIL_IsValidClient(rClient))
    {
        GetClientAbsOrigin(rClient, targetOrigin);
        changedTargetOrigin[0] = targetOrigin[0];
        changedTargetOrigin[1] = targetOrigin[1];
        changedTargetOrigin[2] = targetOrigin[2];
        
        int isStuck = UTIL_GetPlayerStuckVector(client, changedTargetOrigin);
        if (isStuck < 0) {
            targetOrigin[0] = changedTargetOrigin[0];
            targetOrigin[1] = changedTargetOrigin[1];
            targetOrigin[2] = changedTargetOrigin[2];
        }
        
        TeleportEntity(client, targetOrigin, NULL_VECTOR, NULL_VECTOR);
    }

    return Plugin_Continue;
}

public Action RemoveRadar(Handle timer, any client) 
{
    if ( !UTIL_IsValidAlive(client) )
    return Plugin_Continue;

    SetEntProp(client, Prop_Send, "m_iHideHUD", GetEntProp(client, Prop_Send, "m_iHideHUD") | HIDEHUD_RADAR);
    
    return Plugin_Continue;
} 

public Action ghostHint(Handle timer, any client)
{
    g_hTimerGhostHint[client] = null;
    char hintText[1024];

    if ( !UTIL_IsValidAlive(client) || GetClientTeam(client) != CS_TEAM_T )
    return Plugin_Continue;
    
    if (g_bOverrideHint[client]) {
        UTIL_ShowHintMessage(client, g_sOverrideHintText[client]);
    }
    else if (g_bGhost[client]) {
        Format(hintText,sizeof(hintText),"%t","Hint: Currently you are a ghost");
        UTIL_ShowHintMessage(client, hintText);
    } else {
        char sHintText[196];
        int zm_id = FindZombieIndex(client);
        g_esZombieClass temp_checker;
        g_aZombieClass.GetArray(zm_id, temp_checker, sizeof(temp_checker));
        Format(sHintText, sizeof(sHintText), "%t","Hint: Zombie Info Name and Description", temp_checker.dataName, temp_checker.dataDescription);
        
        UTIL_ShowHintMessage(client, sHintText);
        if (g_cSoundsIdle.BoolValue && GetTime() > g_fNextIdle[client]) {
            PlayIdleSound(client);
        }
    }
    
    g_hTimerGhostHint[client] = CreateTimer( g_fHintSpeed[client], ghostHint, client, TIMER_FLAG_NO_MAPCHANGE);
    
    return Plugin_Continue;
}

public Action respawnClientOnConnect( Handle timer, any client )
{
    if ( !UTIL_IsValidClient(client) || IsPlayerAlive(client) )
    {
        return Plugin_Continue;
    }
    
    CS_RespawnPlayer( client );
    
    return Plugin_Continue;
}

public Action timerZombieRespawnCallback( Handle timer, any client )
{    
    g_hTimerZombieRespawn[client] = null;
    if ( !UTIL_IsValidClient(client) )
    return Plugin_Continue;
    
    if (IsPlayerAlive(client))
    return Plugin_Continue;

    if (GetClientTeam(client) == CS_TEAM_SPECTATOR) {
        return Plugin_Continue;
    }
    char sHintText[196];
    if (g_iZombieRespawnLeft[client] == 0) {
        CS_RespawnPlayer( client );
        Format(sHintText,sizeof(sHintText),"%t","Hint: Go Go Go");
        UTIL_ShowHintMessage(client, sHintText);
    } else {
        Format(sHintText, sizeof(sHintText), "%t","Hint: Respawn cooldown", g_iZombieRespawnLeft[client]);
        UTIL_ShowHintMessage(client, sHintText);
        g_iZombieRespawnLeft[client]--;
        g_hTimerZombieRespawn[client] = CreateTimer( 1.0, timerZombieRespawnCallback, client, TIMER_FLAG_NO_MAPCHANGE);
    }
    
    return Plugin_Continue;
}

stock int getZombieHealthRate(int client)
{
    int zm_id = FindZombieIndex(client);
    g_esZombieClass temp_checker;
    g_aZombieClass.GetArray(zm_id, temp_checker, sizeof(temp_checker));
    int health = temp_checker.dataHP;
    int value = (RoundToCeil(SquareRoot(float(health)/(getZombies()+1)/2.0))+2)*health;

    if (getHumans() < getZombies()) {
        value = (RoundToCeil(SquareRoot(float(health)/(getZombies()+1)/2.0)))*health;
    }
    
    return value;
}

stock int getHumans(bool alive = false)
{
    int humans, i;
    
    for (i = 1; i <= MaxClients; i++)
    {
        if (UTIL_IsValidClient(i) && !IsClientSourceTV(i) && GetClientTeam(i) == CS_TEAM_CT)
        {
            if (!alive || (alive && IsPlayerAlive(i)))
            humans++;
        }
    }
    
    return humans;
}

stock int getZombies(bool alive = false)
{
    int zombies, i;
    
    for (i = 1; i <= MaxClients; i++)
    {
        if (UTIL_IsValidClient(i) && !IsClientSourceTV(i) && GetClientTeam(i) == CS_TEAM_T)
        {
            if (!alive || (alive && IsPlayerAlive(i)))
            zombies++;
        }
    }
    
    return zombies;
}

stock int getTrueCT(bool alive = false)
{
    int humans, i;
    
    for (i = 1; i <= MaxClients; i++)
    {
        if (UTIL_IsValidClient(i) && !IsClientSourceTV(i) && g_iTeam[i] == CS_TEAM_CT)
        {
            if (!alive || (alive && IsPlayerAlive(i)))
            humans++;
        }
    }
    
    return humans;
}

stock int getTrueT(bool alive = false)
{
    int zombies, i;
    
    for (i = 1; i <= MaxClients; i++)
    {
        if (UTIL_IsValidClient(i) && !IsClientSourceTV(i) && g_iTeam[i] == CS_TEAM_T)
        {
            if (!alive || (alive && IsPlayerAlive(i)))
            zombies++;
        }
    }
    
    return zombies;
}

public void setZombieGhostMode(int client, bool mode) 
{
    g_bGhost[client] = mode;
    if (GetClientTeam(client) == CS_TEAM_T)
        setZombieClassParameters(client);
}

public void removeMapEventEntity(const char[] objects)
{
    // Initialize char
    char sClass[64];
    
    // Save max amount of entities
    int maxEntities = GetMaxEntities();
    
    // Check all entities and remove it
    for (int i = 0; i <= maxEntities; i++)
    {
        if(IsValidEdict(i) && IsValidEntity(i))
        {
            // Get classname
            GetEdictClassname(i, sClass, sizeof(sClass));
            
            // Compare classname
            if(StrContains(objects, sClass) != -1) 
            {
                RemoveEdict(i);
            }
        }
    }
}

public int getRandZombieClass() 
{
    int[] tclasses = new int[g_iNumClasses];
    int classCount;
    for (int i = 0; i < g_aZombieClass.Length; i++)
    {
        g_esZombieClass temp_checker;
        g_aZombieClass.GetArray(i, temp_checker, sizeof(temp_checker));
        bool excluded = temp_checker.dataExcluded;
        if(!excluded) {
            tclasses[classCount++] = i;
        }
    }
    
    return tclasses[GetRandomInt(0, classCount - 1)];
}

public void setZombieClassParameters(int client) 
{
    if (!UTIL_IsValidAlive(client)) return;
    if (GetClientTeam(client) != CS_TEAM_T) return;
    // Set zombie class model
    int zm_id = FindZombieIndex(client);
    g_esZombieClass temp_checker;
    g_aZombieClass.GetArray(zm_id, temp_checker, sizeof(temp_checker));

    char zBuffer[PLATFORM_MAX_PATH];
    Format(zBuffer, sizeof(zBuffer), "%s.mdl", temp_checker.dataModel);
    SetEntityModel(client, zBuffer);
    
    // Set zombie arms
    if (strlen(temp_checker.dataArms) > 0) {
        int ent = GetEntPropEnt(client, Prop_Send, "m_hMyWearables");
        if(ent != -1) {
            AcceptEntityInput(ent, "KillHierarchy");
        }
        SetEntPropString(client, Prop_Send, "m_szArmsModel", temp_checker.dataArms);
    }
    else {
        int ent = GetEntPropEnt(client, Prop_Send, "m_hMyWearables");
        if(ent != -1) {
            AcceptEntityInput(ent, "KillHierarchy");
        }
        SetEntPropString(client, Prop_Send, "m_szArmsModel", DEFAULT_ARMS);
    }
    
    // Set zombie health
    SetEntProp(client, Prop_Send, "m_iHealth", getZombieHealthRate(client), 4);
    
    // Set zombie speed
    if(g_bGhost[client] || g_cGhostMode.BoolValue)
        SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.4);
    else
        SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", temp_checker.dataSpeed);
    
    // Set zombie gravity
    SetEntityGravity(client, temp_checker.dataGravity);
}

public void AssignPlayerAbilities(int client) {
    if (!UTIL_IsValidAlive(client))
        return;
    ClearPlayerAbilities(client);
    // Give player abilities
    for (int i = 0; i < g_aZombieAbility.Length; i++)
    {
        g_esZombieAbility temp_checkability;
        g_aZombieAbility.GetArray(i, temp_checkability, sizeof(temp_checkability)); 
        if(g_iZombieClass[client] != temp_checkability.abilityZombieClass || temp_checkability.abilityExcluded)
            continue;
        g_esPlayerAbility temp_ability;
        strcopy(temp_ability.paName, sizeof(g_esPlayerAbility::paName), temp_checkability.abilityName);
        strcopy(temp_ability.paDescription, sizeof(g_esPlayerAbility::paDescription), temp_checkability.abilityDescription);
        strcopy(temp_ability.paUniqueName, sizeof(g_esPlayerAbility::paUniqueName), temp_checkability.abilityUniqueName);

        temp_ability.paButtons = temp_checkability.abilityButtons;
        temp_ability.paCooldown = temp_checkability.abilityCooldown;
        temp_ability.paDuration = temp_checkability.abilityDuration;
        temp_ability.paCurrentDuration = 0.0;
        temp_ability.paCurrentCooldown = 0.0;
        // todo forward ZS_PlayerAbilityStateChange
        temp_ability.paState = stateIdle; // from <zombieswarm.inc>
        temp_ability.paExcluded = false;
        temp_ability.paZombieClass = temp_checkability.abilityZombieClass;
        temp_ability.paID = g_iNumPlayerAbilities;
        temp_ability.paClient = client;
        temp_ability.paTimerDuration = null;
        temp_ability.paTimerCooldown = null;
        g_aPlayerAbility.PushArray(temp_ability, sizeof(temp_ability));
        // TODO on player ability register
        g_iNumPlayerAbilities++;
    }
}

public Action CountDown(Handle timer) {
    if (g_iCountdownNumber <= 0) {
        g_iCountdownNumber = g_cCountDown.IntValue > 10?10:g_cCountDown.IntValue;
        g_bGhostCanSpawn = true;
        g_hTimerCountDown = INVALID_HANDLE;
        
        return Plugin_Stop;
    }
    
    for (int client = 1; client <= MaxClients; client++) {
        if (!UTIL_IsValidClient(client))
            continue;
        /*if(GetClientTeam(client) != CS_TEAM_T)
            continue;*/
        UTIL_PlaySoundToClient(client,g_CountdownSounds[(g_iCountdownNumber - 1)], 0.2);
    }
    
    g_iCountdownNumber--;
    g_bGhostCanSpawn = false;
    
    return Plugin_Continue;
}

public int FindZombieIndex(int id) {
    int foundx = -1;
    for (int i = 0; i < g_aZombieClass.Length; i++)
    {
        g_esZombieClass tempItemx;
        g_aZombieClass.GetArray(i, tempItemx, sizeof(tempItemx)); 
        if (id == tempItemx.dataID)
        {
            foundx = i;
            break;
        }
    }
    return view_as<int>(foundx);
}

public int FindZombieAbilityIndex(int id) {
    int founde = -1;
    for (int i = 0; i < g_aZombieAbility.Length; i++)
    {
        g_esZombieAbility tempItem;
        g_aZombieAbility.GetArray(i, tempItem, sizeof(tempItem)); 
        if (id == tempItem.abilityID)
        {
            founde = i;
            break;
        }
    }

    return view_as<int>(founde);
}

public int FindPlayerAbilityIndex(int id) {
    int foundq = -1;
    for (int i = 0; i < g_aPlayerAbility.Length; i++)
    {
        g_esPlayerAbility tempItem;
        g_aPlayerAbility.GetArray(i, tempItem, sizeof(tempItem)); 
        if (id == tempItem.paID)
        {
            foundq = i;
            break;
        }
    }

    return view_as<int>(foundq);
}
stock void UTIL_LoadSounds() {
    char SoundPath[PLATFORM_MAX_PATH];
    KeyValues Sounds = new KeyValues("Sounds");
    BuildPath(Path_SM, SoundPath, sizeof(SoundPath), "configs/swarm/sounds.cfg");
    
    if (!Sounds.ImportFromFile(SoundPath)) {
        LogError("Couldn't import: \"%s\"", SoundPath);
        return;
    }

    if (!Sounds.GotoFirstSubKey()) {
        LogError("No sounds in: \"%s\"", SoundPath);
        return;
    }
    char sectionname[PLATFORM_MAX_PATH];
    char buffer[PLATFORM_MAX_PATH];
    g_iTotalHumanWinSounds = 0;
    g_iTotalZombieWinSounds = 0;
    g_iTotalCountdownSounds = 0;
    do
    {
        Sounds.GetSectionName(sectionname, sizeof(sectionname));
        bool scatter = false;
        int i = 0;
        while (!scatter) {
            char key[10];
            IntToString(i, key, sizeof(key));
            Sounds.GetString(key, buffer, sizeof(buffer), "notexists");
            if (StrEqual(buffer, "notexists")) {
                break;
            }
            UTIL_RegisterSound(sectionname, buffer);
            i++;
        }
    } while (Sounds.GotoNextKey());

    delete Sounds;
}

void UTIL_RegisterSound(const char[] sectionname, const char[] key) {
    if (StrEqual(sectionname, "human_win")) {
        strcopy(g_HumanWinSounds[g_iTotalHumanWinSounds], PLATFORM_MAX_PATH, key);
        UTIL_LoadSound(g_HumanWinSounds[g_iTotalHumanWinSounds]);
        g_iTotalHumanWinSounds++;
    } else if (StrEqual(sectionname, "zombie_win")) {
        strcopy(g_ZombieWinSounds[g_iTotalZombieWinSounds], PLATFORM_MAX_PATH, key);
        UTIL_LoadSound(g_ZombieWinSounds[g_iTotalZombieWinSounds]);
        g_iTotalZombieWinSounds++;
    } else if (StrEqual(sectionname, "countdown")) {
        strcopy(g_CountdownSounds[g_iTotalCountdownSounds], PLATFORM_MAX_PATH, key);
        UTIL_LoadSound(g_CountdownSounds[g_iTotalCountdownSounds]);
        g_iTotalCountdownSounds++;
    } else {
        LogMessage("Unknown sound category: %s", sectionname);
    }
}

stock void UTIL_LoadZombieSounds() {
	char DirectoryPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, DirectoryPath, sizeof(DirectoryPath), "configs/swarm/zombiesounds");
	DirectoryListing list = OpenDirectory(DirectoryPath, false);
	if (list != null) {
		char buffer[128];
		FileType filetype;
		while (list.GetNext(buffer, sizeof(buffer), filetype)) {
            if (filetype != FileType_File) 
                continue;
            // get unique
            char unique[128];
            strcopy(unique, sizeof(unique), buffer);
            ReplaceString(unique, sizeof(unique), ".cfg", "", false);
            // Load file
            char SoundPath[PLATFORM_MAX_PATH];
            Format(SoundPath, sizeof(SoundPath), "%s/%s", DirectoryPath, buffer);
            KeyValues Sounds = new KeyValues("ZombieSounds");
            if (!Sounds.ImportFromFile(SoundPath)) {
                LogError("Couldn't import: \"%s\"", SoundPath);
                return;
            }

            if (!Sounds.GotoFirstSubKey()) {
                LogError("No sounds in: \"%s\"", SoundPath);
                return;
            }
            // Make new enum Struct

            g_esZombieSounds newSound;
            strcopy(newSound.Unique, sizeof(g_esZombieSounds::Unique), unique);
            newSound.DeathSounds = new ArrayList(ByteCountToCells(PLATFORM_MAX_PATH));
            newSound.Footsteps = new ArrayList(ByteCountToCells(PLATFORM_MAX_PATH));
            newSound.Hit = new ArrayList(ByteCountToCells(PLATFORM_MAX_PATH));
            newSound.Miss = new ArrayList(ByteCountToCells(PLATFORM_MAX_PATH));
            newSound.Pain = new ArrayList(ByteCountToCells(PLATFORM_MAX_PATH));
            newSound.Idle = new ArrayList(ByteCountToCells(PLATFORM_MAX_PATH));

            char sectionname[PLATFORM_MAX_PATH];
            char soundbuffer[PLATFORM_MAX_PATH];
            do
            {
                Sounds.GetSectionName(sectionname, sizeof(sectionname));
                bool scatter = false;
                int i = 0;
                while (!scatter) {
                    char key[10];
                    IntToString(i, key, sizeof(key));
                    Sounds.GetString(key, soundbuffer, sizeof(soundbuffer), "notexists");
                    if (StrEqual(soundbuffer, "notexists")) {
                        break;
                    }
                    bool found_section = true;
                    if (StrEqual(sectionname, "DeathSounds", false)) {
                        newSound.DeathSounds.PushString(soundbuffer);
                    } else if (StrEqual(sectionname, "Footsteps", false)) {
                        newSound.Footsteps.PushString(soundbuffer);
                    } else if (StrEqual(sectionname, "Hit", false)) {
                        newSound.Hit.PushString(soundbuffer);
                    } else if (StrEqual(sectionname, "Miss", false)) {
                        newSound.Miss.PushString(soundbuffer);
                    } else if (StrEqual(sectionname, "Pain", false)) {
                        newSound.Pain.PushString(soundbuffer);
                    } else if (StrEqual(sectionname, "Idle", false)) {
                        newSound.Idle.PushString(soundbuffer);
                    } else {
                        found_section = false;
                        LogMessage("Unknown sound category: %s", sectionname);
                    }
                    if (found_section) {
                        UTIL_LoadSound(soundbuffer);
                    }

                    i++;
                }
                
            } while (Sounds.GotoNextKey());
            g_aZombieSounds.PushArray(newSound, sizeof(newSound)); 
            delete Sounds;
		}
	}
	delete list;
}

stock void UTIL_LoadSound(char[] sound) {
    char soundsPath[PLATFORM_MAX_PATH];
    Format(soundsPath, PLATFORM_MAX_PATH, "sound/%s", sound);
    if (FileExists(soundsPath)) {
        PrecacheSoundAny(sound, true);
        AddFileToDownloadsTable(soundsPath);
    }
    else {
        LogError("Cannot locate sounds file: '%s'", soundsPath);
    }

}

public void FirePostFrame(int userid)
{
    int client = GetClientOfUserId(userid);
    if(!client)
        return;
    if (!UTIL_IsValidAlive(client))
        return;
    if (GetClientTeam(client) != CS_TEAM_T)
        return;
    int weapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
    if (!IsValidEntity(weapon))
        return;

    char sWeapon[32];
    GetWeaponClassname(weapon, sWeapon, sizeof(sWeapon));
    if (StrContains(sWeapon, "knife") == -1)
        return;

    float curtime = GetGameTime();
    float nexttime = GetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack");
    nexttime -= curtime;
    int zm_id = FindZombieIndex(client);
    g_esZombieClass temp_checker;
    g_aZombieClass.GetArray(zm_id, temp_checker, sizeof(temp_checker));
    float speed = temp_checker.dataAttackSpeed;
    nexttime *= 1.0/speed; // 4.0 - multiplier
    nexttime += curtime;
    SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", nexttime);
    SetEntPropFloat(client, Prop_Send, "m_flNextAttack", 0.0);
}  

/* Since cs:go likes to use items_game prefabs instead of weapon files on newly added weapons */
public void GetWeaponClassname(int weapon, char[] buffer, int size) {
    switch(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex")) {
        case 23: Format(buffer, size, "weapon_mp5sd"); 
        case 60: Format(buffer, size, "weapon_m4a1_silencer");
        case 61: Format(buffer, size, "weapon_usp_silencer");
        case 63: Format(buffer, size, "weapon_cz75a");
        case 64: Format(buffer, size, "weapon_revolver");
        default: GetEdictClassname(weapon, buffer, size);
    }
}

public int FindZombieSoundsIndex(char[] unique) {
    int found = -1;
    for (int i = 0; i < g_aZombieSounds.Length; i++)
    {
        g_esZombieSounds tempItem;
        g_aZombieSounds.GetArray(i, tempItem, sizeof(tempItem)); 
        if (StrEqual(tempItem.Unique, unique, false))
        {
            found = i;
            break;
        }
    }
    return found;
}

void PlayDeathZombieSound(int client) 
{
    if (GetClientTeam(client) != CS_TEAM_T)
        return;
    if (g_cGhostMode.BoolValue && g_bGhost[client])
        return;
    if (!g_cSoundsDeathEnable.BoolValue)
        return;
    g_esZombieSounds DefaultSoundPack;
    g_aZombieSounds.GetArray(defaultsoundindex, DefaultSoundPack, sizeof(DefaultSoundPack));

    g_esZombieSounds ZMSoundPack;
    int zombie_index = FindZombieIndex(g_iZombieClass[client]);
    if (zombie_index == -1) return;
    g_esZombieClass class;
    g_aZombieClass.GetArray(zombie_index, class, sizeof(class));
    int zombieid = FindZombieSoundsIndex(class.dataUniqueName);
    
    if (zombieid != -1) {
        g_aZombieSounds.GetArray(zombieid, ZMSoundPack, sizeof(ZMSoundPack));
    }
    
    char playsound[PLATFORM_MAX_PATH];
    bool gotsound = false;
    if (DefaultSoundPack.DeathSounds.Length == 0 && (zombieid == -1 || ZMSoundPack.DeathSounds.Length == 0))
        return;
    if (zombieid != -1 && ZMSoundPack.DeathSounds.Length > 1) {
        int randomSound = GetRandomInt(0, ZMSoundPack.DeathSounds.Length-1);
        
        ZMSoundPack.DeathSounds.GetString(randomSound, playsound, sizeof(playsound));
        gotsound = true;
    } else if (zombieid != -1 && ZMSoundPack.DeathSounds.Length == 1) {
        ZMSoundPack.DeathSounds.GetString(0, playsound, sizeof(playsound));
        gotsound = true;
    } else if (DefaultSoundPack.DeathSounds.Length > 1) {
        int randomSound = GetRandomInt(0, DefaultSoundPack.DeathSounds.Length-1);
        DefaultSoundPack.DeathSounds.GetString(randomSound, playsound, sizeof(playsound));
        gotsound = true;
    } else if (DefaultSoundPack.DeathSounds.Length == 1) {
        DefaultSoundPack.DeathSounds.GetString(0, playsound, sizeof(playsound));
        gotsound = true;
    }
    if (gotsound) {
        EmitSoundToAllAny(playsound, client, SNDCHAN_VOICE);
    }
}


public void PlayPainSound(int client) {
    if (GetClientTeam(client) != CS_TEAM_T)
        return;
    if (g_cGhostMode.BoolValue && g_bGhost[client])
        return;
    if (!g_cSoundsPain.BoolValue)
        return;
    g_esZombieSounds DefaultSoundPack;
    g_aZombieSounds.GetArray(defaultsoundindex, DefaultSoundPack, sizeof(DefaultSoundPack));

    g_esZombieSounds ZMSoundPack;
    int zombie_index = FindZombieIndex(g_iZombieClass[client]);
    if (zombie_index == -1) return;
    g_esZombieClass class;
    g_aZombieClass.GetArray(zombie_index, class, sizeof(class));
    int zombieid = FindZombieSoundsIndex(class.dataUniqueName);
    
    if (zombieid != -1) {
        g_aZombieSounds.GetArray(zombieid, ZMSoundPack, sizeof(ZMSoundPack));
    }

    float currentgtime = GetGameTime();
    
    char playsound[PLATFORM_MAX_PATH];

    if (currentgtime < g_fNextPain[client]) return;
    bool gotsound = false;
    if (DefaultSoundPack.Pain.Length == 0 && (zombieid == -1 || ZMSoundPack.Pain.Length == 0))
        return;
    if (zombieid != -1 && ZMSoundPack.Pain.Length > 1) {
        int randomSound = GetRandomInt(0, ZMSoundPack.Pain.Length-1);
        ZMSoundPack.Pain.GetString(randomSound, playsound, sizeof(playsound));
        gotsound = true;
    } else if (zombieid != -1 && ZMSoundPack.Pain.Length == 1) {
        ZMSoundPack.Pain.GetString(0, playsound, sizeof(playsound));
        gotsound = true;
    } else if (DefaultSoundPack.Pain.Length > 1) {
        int randomSound = GetRandomInt(0, DefaultSoundPack.Pain.Length-1);
        DefaultSoundPack.Pain.GetString(randomSound, playsound, sizeof(playsound));
        gotsound = true;
    } else if (DefaultSoundPack.Pain.Length == 1) {
        DefaultSoundPack.Pain.GetString(0, playsound, sizeof(playsound));
        gotsound = true;
    }
    if (gotsound) {
        EmitSoundToAllAny(playsound, client, SNDCHAN_ITEM);
        g_fNextPain[client] = GetGameTime() + g_cPainFrequency.FloatValue;
    }
}

public void PlayFootstepSound(int client) {
    if (GetClientTeam(client) != CS_TEAM_T)
        return;
    if (g_cGhostMode.BoolValue && g_bGhost[client])
        return;
    if (!g_cSoundsFootsteps.BoolValue)
        return;
    g_esZombieSounds DefaultSoundPack;
    g_aZombieSounds.GetArray(defaultsoundindex, DefaultSoundPack, sizeof(DefaultSoundPack));

    g_esZombieSounds ZMSoundPack;
    int zombie_index = FindZombieIndex(g_iZombieClass[client]);
    if (zombie_index == -1) return;
    g_esZombieClass class;
    g_aZombieClass.GetArray(zombie_index, class, sizeof(class));
    int zombieid = FindZombieSoundsIndex(class.dataUniqueName);
    
    if (zombieid != -1) {
        g_aZombieSounds.GetArray(zombieid, ZMSoundPack, sizeof(ZMSoundPack));
    }

    float currentgtime = GetGameTime();
    
    char playsound[PLATFORM_MAX_PATH];

    if (currentgtime < g_fNextFootstep[client]) return;
    bool gotsound = false;
    if (DefaultSoundPack.Footsteps.Length == 0 && (zombieid == -1 || ZMSoundPack.Footsteps.Length == 0))
        return;
    if (zombieid != -1 && ZMSoundPack.Footsteps.Length > 1) {
        int randomSound = GetRandomInt(0, ZMSoundPack.Footsteps.Length-1);
        ZMSoundPack.Footsteps.GetString(randomSound, playsound, sizeof(playsound));
        gotsound = true;
    } else if (zombieid != -1 && ZMSoundPack.Footsteps.Length == 1) {
        ZMSoundPack.Footsteps.GetString(0, playsound, sizeof(playsound));
        gotsound = true;
    } else if (DefaultSoundPack.Footsteps.Length > 1) {
        int randomSound = GetRandomInt(0, DefaultSoundPack.Footsteps.Length-1);
        DefaultSoundPack.Footsteps.GetString(randomSound, playsound, sizeof(playsound));
        gotsound = true;
    } else if (DefaultSoundPack.Footsteps.Length == 1) {
        DefaultSoundPack.Footsteps.GetString(0, playsound, sizeof(playsound));
        gotsound = true;
    }
    if (gotsound) {
        EmitSoundToAllAny(playsound, client);
        g_fNextFootstep[client] = GetGameTime() + g_cFootstepFrequency.FloatValue;
    }
}

public void PlayHitSound(int client) {
    if (GetClientTeam(client) != CS_TEAM_T)
        return;
    if (g_cGhostMode.BoolValue && g_bGhost[client])
        return;
    if (!g_cSoundsHit.BoolValue)
        return;
    g_bDidHit[client] = false;
    g_esZombieSounds DefaultSoundPack;
    g_aZombieSounds.GetArray(defaultsoundindex, DefaultSoundPack, sizeof(DefaultSoundPack));

    g_esZombieSounds ZMSoundPack;
    int zombie_index = FindZombieIndex(g_iZombieClass[client]);
    if (zombie_index == -1) return;
    g_esZombieClass class;
    g_aZombieClass.GetArray(zombie_index, class, sizeof(class));
    int zombieid = FindZombieSoundsIndex(class.dataUniqueName);
    
    if (zombieid != -1) {
        g_aZombieSounds.GetArray(zombieid, ZMSoundPack, sizeof(ZMSoundPack));
    }

    //float currentgtime = GetGameTime();
    
    char playsound[PLATFORM_MAX_PATH];

    bool gotsound = false;
    if (DefaultSoundPack.Hit.Length == 0 && (zombieid == -1 || ZMSoundPack.Hit.Length == 0))
        return;
    if (zombieid != -1 && ZMSoundPack.Hit.Length > 1) {
        int randomSound = GetRandomInt(0, ZMSoundPack.Hit.Length-1);
        ZMSoundPack.Hit.GetString(randomSound, playsound, sizeof(playsound));
        gotsound = true;
    } else if (zombieid != -1 && ZMSoundPack.Hit.Length == 1) {
        ZMSoundPack.Hit.GetString(0, playsound, sizeof(playsound));
        gotsound = true;
    } else if (DefaultSoundPack.Hit.Length > 1) {
        int randomSound = GetRandomInt(0, DefaultSoundPack.Hit.Length-1);
        DefaultSoundPack.Hit.GetString(randomSound, playsound, sizeof(playsound));
        gotsound = true;
    } else if (DefaultSoundPack.Hit.Length == 1) {
        DefaultSoundPack.Hit.GetString(0, playsound, sizeof(playsound));
        gotsound = true;
    }
    if (gotsound) {
        EmitSoundToAllAny(playsound, client);
    }
}

public void PlayMissSound(int client) {
    if (GetClientTeam(client) != CS_TEAM_T)
        return;
    if (g_cGhostMode.BoolValue && g_bGhost[client])
        return;
    if (!g_cSoundsMiss.BoolValue)
        return;
    g_esZombieSounds DefaultSoundPack;
    g_aZombieSounds.GetArray(defaultsoundindex, DefaultSoundPack, sizeof(DefaultSoundPack));

    g_esZombieSounds ZMSoundPack;
    int zombie_index = FindZombieIndex(g_iZombieClass[client]);
    if (zombie_index == -1) return;
    g_esZombieClass class;
    g_aZombieClass.GetArray(zombie_index, class, sizeof(class));
    int zombieid = FindZombieSoundsIndex(class.dataUniqueName);
    
    if (zombieid != -1) {
        g_aZombieSounds.GetArray(zombieid, ZMSoundPack, sizeof(ZMSoundPack));
    }

    //float currentgtime = GetGameTime();
    
    char playsound[PLATFORM_MAX_PATH];

    bool gotsound = false;
    if (DefaultSoundPack.Miss.Length == 0 && (zombieid == -1 || ZMSoundPack.Miss.Length == 0))
        return;
    if (zombieid != -1 && ZMSoundPack.Miss.Length > 1) {
        int randomSound = GetRandomInt(0, ZMSoundPack.Miss.Length-1);
        ZMSoundPack.Miss.GetString(randomSound, playsound, sizeof(playsound));
        gotsound = true;
    } else if (zombieid != -1 && ZMSoundPack.Miss.Length == 1) {
        ZMSoundPack.Miss.GetString(0, playsound, sizeof(playsound));
        gotsound = true;
    } else if (DefaultSoundPack.Miss.Length > 1) {
        int randomSound = GetRandomInt(0, DefaultSoundPack.Miss.Length-1);
        DefaultSoundPack.Miss.GetString(randomSound, playsound, sizeof(playsound));
        gotsound = true;
    } else if (DefaultSoundPack.Miss.Length == 1) {
        DefaultSoundPack.Miss.GetString(0, playsound, sizeof(playsound));
        gotsound = true;
    }
    if (gotsound) {
        EmitSoundToAllAny(playsound, client);
    }
}

public void PlayIdleSound(int client) {
    if (GetClientTeam(client) != CS_TEAM_T)
        return;
    if (g_cGhostMode.BoolValue && g_bGhost[client])
        return;
    if (!g_cSoundsIdle.BoolValue)
        return;
    g_esZombieSounds DefaultSoundPack;
    g_aZombieSounds.GetArray(defaultsoundindex, DefaultSoundPack, sizeof(DefaultSoundPack));

    g_esZombieSounds ZMSoundPack;
    int zombie_index = FindZombieIndex(g_iZombieClass[client]);
    if (zombie_index == -1) return;
    g_esZombieClass class;
    g_aZombieClass.GetArray(zombie_index, class, sizeof(class));
    int zombieid = FindZombieSoundsIndex(class.dataUniqueName);
    
    if (zombieid != -1) {
        g_aZombieSounds.GetArray(zombieid, ZMSoundPack, sizeof(ZMSoundPack));
    }

    float currentgtime = GetGameTime();
    
    char playsound[PLATFORM_MAX_PATH];

    if (currentgtime < g_fNextIdle[client]) return;
    bool gotsound = false;
    if (DefaultSoundPack.Idle.Length == 0 && (zombieid == -1 || ZMSoundPack.Idle.Length == 0))
        return;
    if (zombieid != -1 && ZMSoundPack.Idle.Length > 1) {
        int randomSound = GetRandomInt(0, ZMSoundPack.Idle.Length-1);
        ZMSoundPack.Idle.GetString(randomSound, playsound, sizeof(playsound));
        gotsound = true;
    } else if (zombieid != -1 && ZMSoundPack.Idle.Length == 1) {
        ZMSoundPack.Idle.GetString(0, playsound, sizeof(playsound));
        gotsound = true;
    } else if (DefaultSoundPack.Idle.Length > 1) {
        int randomSound = GetRandomInt(0, DefaultSoundPack.Idle.Length-1);
        DefaultSoundPack.Idle.GetString(randomSound, playsound, sizeof(playsound));
        gotsound = true;
    } else if (DefaultSoundPack.Idle.Length == 1) {
        DefaultSoundPack.Idle.GetString(0, playsound, sizeof(playsound));
        gotsound = true;
    }
    if (gotsound) {
        EmitSoundToAllAny(playsound, client);
        float nextidle = GetRandomFloat(g_cIdleMinFrequency.FloatValue, g_cIdleMaxFrequency.FloatValue);
        g_fNextIdle[client] = GetGameTime() + nextidle;
    }
}