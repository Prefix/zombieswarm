#pragma semicolon 1

#include <sourcemod>
#include <cstrike>
#include <gum>
#include <colorvariables>

#define PLUGIN_NAME "GUM - Nick bonus"
#define PLUGIN_AUTHOR "Prefix"
#define PLUGIN_DESCRIPTION "Bonus for people who wears our community name."
#define PLUGIN_VERSION "1.0"
#define PLUGIN_URL "https://github.com/Prefix/zombieswarm"

#define CREDITS 10
#define VIPCREDITS 5

#define MAX_WORDS 200
new String:g_swearwords[MAX_WORDS][32];
new String:badwordfile[PLATFORM_MAX_PATH];
new g_swearNum;

new Handle:timeris;

public Plugin:myinfo = 
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

public OnPluginStart()
{
	timeris = CreateTimer(150.0, Timer_GiveCredits, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(0.1, Read_Files);
}

public Action:Read_Files(Handle:timer){
	BuildPath(Path_SM,badwordfile,sizeof(badwordfile),"configs/gum-badnames.txt");
	if(!FileExists(badwordfile)) {
		LogMessage("gum-badnames.txt not parsed...file doesnt exist!");
	} else {
		new Handle:badwordshandle = OpenFile(badwordfile, "r");
		new i = 0;
		while( i < MAX_WORDS && !IsEndOfFile(badwordshandle)){
			ReadFileLine(badwordshandle, g_swearwords[i], sizeof(g_swearwords[]));
			TrimString(g_swearwords[i]);
			i++;
			g_swearNum++;
		}
		CloseHandle(badwordshandle);
	}
}

public OnClientPutInServer(client){
	if(!(IsClientInGame(client) && !IsFakeClient(client)))
		return;
	if(CheckClientName(client)) 
		KickClient(client, "It's bad nickname, change it! Otherwise we won't let you play here!");
}

public OnClientSettingsChanged(client){
	if(!(IsClientInGame(client) && !IsFakeClient(client)))
		return;
	if(CheckClientName(client)) 
		KickClient(client, "It's bad nickname, change it! Otherwise we won't let you play here!");
}

string_cleaner(String:str[], maxlength){
	new i, len = strlen(str);

	ReplaceString(str, maxlength, "|<", "k");
	ReplaceString(str, maxlength, "|>", "p");
	ReplaceString(str, maxlength, "()", "o");
	ReplaceString(str, maxlength, "[]", "o");
	ReplaceString(str, maxlength, "{}", "o");

	for(i = 0; i < len; i++)
	{
		if(str[i] == '@')
			str[i] = 'a';

		if(str[i] == '$')
			str[i] = 's';

		if(str[i] == '0')
			str[i] = 'o';

		if(str[i] == '7')
			str[i] = 't';

		if(str[i] == '3')
			str[i] = 'e';

		if(str[i] == '5')
			str[i] = 's';

		if(str[i] == '<')
			str[i] = 'c';
		
	}
}

CheckClientName(client) {
	if(IsClientInGame(client) && !IsFakeClient(client)){
		decl String:clientName[64];
		GetClientName(client,clientName,64);
		string_cleaner(clientName, sizeof(clientName));
		
		new i = 0;
		new found = false;
		while (i < g_swearNum){
			if (StrContains(clientName, g_swearwords[i], false) != -1 ){
				found = true;
			}
			i++;
		}
		return found;
	}	
	return false;
}

public OnMapStart() {
	if(timeris != INVALID_HANDLE) {
		if(CloseHandle(timeris)) 
		timeris = INVALID_HANDLE; 
		timeris = CreateTimer(150.0, Timer_GiveCredits, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	} else {
		timeris = CreateTimer(150.0, Timer_GiveCredits, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
	
}

public OnMapEnd() {
	if(timeris != INVALID_HANDLE) {
		if(CloseHandle(timeris)) 
		timeris = INVALID_HANDLE; 
	}
}

public Action:Timer_GiveCredits(Handle:timerz)
{
	new newGained = 0;
	new String:name[MAX_NAME_LENGTH];
	for(new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			GetClientName(i,name, sizeof(name));
			if(CheckAdminFlags(i, ADMFLAG_RESERVATION)) {
				if(GetClientTeam(i) != CS_TEAM_SPECTATOR) {
					setPlayerUnlocks(i, getPlayerUnlocks(i)+VIPCREDITS);
					CPrintToChat(i, "[{GREEN}ZS{default}] You have gained %i xp for being a VIP. Thank you for contributing in this community!", VIPCREDITS);
				} else {
					CPrintToChat(i, "[{GREEN}ZS{default}] If you were in T or CT team you could have gained %i xp. Consider playing!", VIPCREDITS);
				}
			} else {
				CPrintToChat(i, "[{GREEN}ZS{default}] If you were a vip you could have gained %i xp. Consider donating!", VIPCREDITS);
			}
			if(StrContains(name, "ZS", false) != -1) {
				if((StrContains(name, "shit", false) != -1)) {
					CPrintToChat(i, "[{GREEN}ZS{default}] You will not get %i xp for having a bad name!", CREDITS);
					continue;
				} else if(GetClientTeam(i) == CS_TEAM_SPECTATOR) {
					CPrintToChat(i, "[{GREEN}ZS{default}] You will not get %i xp for being inactive!", CREDITS);
					continue;
				} else {
					setPlayerUnlocks(i, getPlayerUnlocks(i)+CREDITS);
					CPrintToChat(i, "[{GREEN}ZS{default}] You gained %i xp for wearing our community name!", CREDITS);
					newGained++;
				}
			}
		}
	}  
	if (newGained > 0) {
		CPrintToChatAll("[{GREEN}ZS{default}] {GREEN} %i guys gained %i additional xp.You want additional credits too?", newGained, CREDITS);
	} else { 
		CPrintToChatAll("[{GREEN}ZS{default}] {GREEN}Nodody gained %i additional xp but you want to get additional xp?", CREDITS);
		CPrintToChatAll("[{GREEN}ZS{default}] {GREEN}Put \"ZS\" in your nickname and you will get additional xp.");
	}
	

	return Plugin_Continue;
}

stock bool:CheckAdminFlags(client, flags)
{
	new AdminId:admin = GetUserAdmin(client);
	if (admin != INVALID_ADMIN_ID)
	{
		new count, found;
		for (new i = 0; i <= 20; i++)
		{
			if (flags & (1<<i))
			{
				count++;

				if (GetAdminFlag(admin, AdminFlag:i))
				{
					found++;
				}
			}
		}

		if (count == found)
		{
			return true;
		}
	}

	return false;
}

