#include <sourcemod>
#include <gum>
#include <zombiemod>

#pragma semicolon 1
#pragma newdecls required

static const int SPECMODE_FIRSTPERSON	= 4,
				SPECMODE_3RDPERSON		= 5;

static const float UPDATE_INTERVAL	= 1.5;
static const char PLUGIN_VERSION[]	= "1.2.0";
static const char colors[][]		= {"R", "G", "B", "A"};


Handle HudHintTimers[MAXPLAYERS+1];
bool g_bEnabled;
int g_iColor[4];
float g_fPosX,
	g_fPosY;

public Plugin myinfo =
{
	name		= "Zombie Swarm CS:GO Hud",
	author		= "Prefix (Based from Grey83)",
	description	= "View statistics about you in zombie swarm",
	version		= PLUGIN_VERSION,
	url			= ""
};

public void OnPluginStart()
{
	CreateConVar("sm_zombieswarm_csgohud_version", PLUGIN_VERSION, "Zombie Swarm HUD Version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	ConVar CVar;
	HookConVarChange((CVar = CreateConVar("sm_zombieswarm_csgohud_enabled","1","Enables the HUD for all players by default.", FCVAR_NONE, true, 0.0, true, 1.0)), CVarChange_Enabled);
	g_bEnabled		= CVar.BoolValue;
	HookConVarChange((CVar = CreateConVar("sm_zombieswarm_csgohud_color", "0 127 255 255","HUD color. Set by RGBA (0 - 255).")), CVarChange_Color);
	char sBuffer[16];
	CVar.GetString(sBuffer, sizeof(sBuffer));
	String2Color(sBuffer);
	HookConVarChange((CVar = CreateConVar("sm_zombieswarm_csgohud_x", "0.05","List position X (0.0 - 1.0 or -1 for center)", FCVAR_NONE, true, -1.0, true, 1.0)), CVarChange_PosX);
	g_fPosX			= CVar.FloatValue;
	if(g_fPosX < 0) g_fPosX = -1.0;
	HookConVarChange((CVar = CreateConVar("sm_zombieswarm_csgohud_y", "0.05","List position Y (0.0 - 1.0 or -1 for center)", FCVAR_NONE, true, -1.0, true, 1.0)), CVarChange_PosY);
	g_fPosY			= CVar.FloatValue;
	if(g_fPosY < 0) g_fPosX = -1.0;

	AutoExecConfig(true, "plugin.zombieswarm_csgo_hud");
}

public void CVarChange_Enabled(ConVar CVar, const char[] oldValue, const char[] newValue)
{
	g_bEnabled = CVar.BoolValue;

	if(g_bEnabled) CreateAllHudTimers();
	else KillAllHudTimers();
}

public void CVarChange_Color(ConVar CVar, const char[] oldValue, const char[] newValue)
{
	char sBuffer[16];
	CVar.GetString(sBuffer, sizeof(sBuffer));
	String2Color(sBuffer);
}

public void CVarChange_PosX(ConVar CVar, const char[] oldValue, const char[] newValue)
{
	g_fPosX = CVar.FloatValue;
	if(g_fPosX < 0) g_fPosX = -1.0;
}

public void CVarChange_PosY(ConVar CVar, const char[] oldValue, const char[] newValue)
{
	g_fPosY = CVar.FloatValue;
	if(g_fPosY < 0) g_fPosX = -1.0;
}

void String2Color(const char[] str)
{
	static char Splitter[4][16];
	if(ExplodeString(str, " ", Splitter, sizeof(Splitter), sizeof(Splitter[])) > 3)
	{
		for(int i; i < 4; i++)
		{
			if(String_IsNumeric(Splitter[i]))
			{
				g_iColor[i] = StringToInt(Splitter[i]);
				if(g_iColor[i] < 0 || g_iColor[i] > 255)
				{
					PrintToServer("Zombie Swarm HUD warning: incorrect '%s' color parameter (%i)! Correct: 0 - 255.", colors[i], g_iColor[i]);
					g_iColor[i] = 255;
				}
			}
			else
			{
				g_iColor[i] = 255;
				PrintToServer("Zombie Swarm HUD warning: incorrect '%s' color parameter ('%s' is not numeric)!", colors[i], Splitter[i]);
			}
		}
	}
	else PrintToServer("Zombie Swarm HUD warning: not all parameters of color are specified ('%s' < 'R G B A')!", str);
}

bool String_IsNumeric(const char[] str)
{
	int x, numbersFound;

	while (str[x] != '\0')
	{
		if(IsCharNumeric(str[x])) numbersFound++;
		else return false;
		x++;
	}

	return view_as<bool>(numbersFound);
}

void KillAllHudTimers()		// Kill all of the active timers.
{
	for(int i = 1; i <= MaxClients; i++)
		KillHudHintTimer(i);
}

void CreateAllHudTimers()	// Enable timers on all players in game.
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(!IsClientInGame(i)) continue;
		CreateHudHintTimer(i);
	}
}

public void OnClientPostAdminCheck(int client)
{
	if(g_bEnabled) CreateHudHintTimer(client);
}

public void OnClientDisconnect(int client)
{
	if(IsClientInGame(client)) KillHudHintTimer(client);
}

public Action Timer_UpdateHudHint(Handle timer, any client)
{
	static char szText[254];
	szText[0] = '\0';

	// Dealing with a client who is in the game and playing.
	if(IsPlayerAlive(client))
	{
		GetInformationAboutPlayer(client, szText, sizeof(szText), true);
	} else {

		int iSpecModeUser = GetEntProp(client, Prop_Send, "m_iObserverMode");
		if(iSpecModeUser == SPECMODE_FIRSTPERSON || iSpecModeUser == SPECMODE_3RDPERSON)
		{
			// Find out who the User is spectating.
			int iTargetUser = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
			GetInformationAboutPlayer(iTargetUser, szText, sizeof(szText));
		}
	}

	SetHudTextParams(g_fPosX, g_fPosY, UPDATE_INTERVAL + 0.1, g_iColor[0], g_iColor[1], g_iColor[2], g_iColor[3], 0, 0.0, 0.0, 0.0);
	ShowHudText(client, -1, szText);

	return Plugin_Continue;
}

void GetInformationAboutPlayer(int client, char[] str, int maxlength, bool aboutyourself = false) {
	if(!IsValidClient(client)) return;
	char temp_string[256];
	ZMPlayer player = ZMPlayer(client);
	FormatEx(temp_string, sizeof(temp_string), "About %N:\n", player.Client);
	FormatEx(temp_string, sizeof(temp_string), "%s  Level: %d\n", temp_string, player.Level);
	FormatEx(temp_string, sizeof(temp_string), "%s  XP: %d\n", temp_string, player.XP);
	strcopy(str, maxlength, temp_string);
}

void CreateHudHintTimer(int client)
{
	HudHintTimers[client] = CreateTimer(UPDATE_INTERVAL, Timer_UpdateHudHint, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

void KillHudHintTimer(int client)
{
	if(HudHintTimers[client] != null)
	{
		KillTimer(HudHintTimers[client]);
		HudHintTimers[client] = null;
	}
}