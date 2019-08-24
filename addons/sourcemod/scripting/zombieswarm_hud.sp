#include <sourcemod>
#include <gum>
#include <sdktools>
#include <zombieswarm>
#include <swarm/utils>
#include <prestige>

#pragma semicolon 1
#pragma newdecls required

static const int SPECMODE_FIRSTPERSON    = 4,
                SPECMODE_3RDPERSON        = 5;

static const float UPDATE_INTERVAL    = 0.1;
static const char PLUGIN_VERSION[]    = "1.2.0";
static const char colors[][]        = {"R", "G", "B", "A"};



Handle HudHintTimers[MAXPLAYERS+1];
bool g_bEnabled;
int g_iColor[4];
float g_fPosX,
    g_fPosY;

bool g_bEnabledAbility;
int g_iColorAbility[4];
float g_fPosXAbility,
    g_fPosYAbility;

Handle g_hHudSync[MAXPLAYERS+1] = null;
Handle g_hHudSyncAbility[MAXPLAYERS+1] = null;

#define PLUGIN_NAME ZS_PLUGIN_NAME ... " - HUD"

public Plugin myinfo =
{
    name = PLUGIN_NAME,
    author = ZS_PLUGIN_AUTHOR,
    description = ZS_PLUGIN_DESCRIPTION,
    version = ZS_PLUGIN_VERSION,
    url = ZS_PLUGIN_URL
};

public void OnPluginStart()
{
    ZS_StartConfig("zombieswarm.hud");
    ConVar CVar;
    HookConVarChange((CVar = AutoExecConfig_CreateConVar("sm_zombieswarm_csgohud_enabled","1","Enables the HUD for all players by default.", FCVAR_NONE, true, 0.0, true, 1.0)), CVarChange_Enabled);
    g_bEnabled        = CVar.BoolValue;
    HookConVarChange((CVar = AutoExecConfig_CreateConVar("sm_zombieswarm_csgohud_color", "0 127 255 255","HUD color. Set by RGBA (0 - 255).")), CVarChange_Color);
    char sBuffer[16];
    CVar.GetString(sBuffer, sizeof(sBuffer));
    String2Color(sBuffer);
    HookConVarChange((CVar = AutoExecConfig_CreateConVar("sm_zombieswarm_csgohud_x", "0.05","List position X (0.0 - 1.0 or -1 for center)", FCVAR_NONE, true, -1.0, true, 1.0)), CVarChange_PosX);
    g_fPosX            = CVar.FloatValue;
    if(g_fPosX < 0) g_fPosX = -1.0;
    HookConVarChange((CVar = AutoExecConfig_CreateConVar("sm_zombieswarm_csgohud_y", "0.05","List position Y (0.0 - 1.0 or -1 for center)", FCVAR_NONE, true, -1.0, true, 1.0)), CVarChange_PosY);
    g_fPosY            = CVar.FloatValue;
    if(g_fPosY < 0) g_fPosX = -1.0;
    // Hud2
    HookConVarChange((CVar = AutoExecConfig_CreateConVar("sm_zombieswarm_csgohud_ability_enabled","1","Enables the Ability HUD for all players by default.", FCVAR_NONE, true, 0.0, true, 1.0)), CVarChange_Ability_Enabled);
    g_bEnabledAbility        = CVar.BoolValue;
    HookConVarChange((CVar = AutoExecConfig_CreateConVar("sm_zombieswarm_csgohud_ability_color", "100 127 255 255","HUD color. Set by RGBA (0 - 255).")), CVarChange_Ability_Color);
    CVar.GetString(sBuffer, sizeof(sBuffer));
    String2Color(sBuffer, true);
    HookConVarChange((CVar = AutoExecConfig_CreateConVar("sm_zombieswarm_csgohud_ability_x", "0.05" ,"List position X (0.0 - 1.0 or -1 for center)", FCVAR_NONE, true, -1.0, true, 1.0)), CVarChange_Ability_PosX);
    g_fPosXAbility            = CVar.FloatValue;
    if(g_fPosXAbility < 0) g_fPosXAbility = -1.0;
    HookConVarChange((CVar = AutoExecConfig_CreateConVar("sm_zombieswarm_csgohud_ability_y", "-1.0","List position Y (0.0 - 1.0 or -1 for center)", FCVAR_NONE, true, -1.0, true, 1.0)), CVarChange_Ability_PosY);
    g_fPosYAbility            = CVar.FloatValue;
    if(g_fPosYAbility < 0) g_fPosYAbility = -1.0;
    ZS_EndConfig();

    CreateConVar("sm_zombieswarm_csgohud_version", PLUGIN_VERSION, "Zombie Swarm HUD Version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
    LoadTranslations("zombieswarm_hud.phrases");
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

public void CVarChange_Ability_Enabled(ConVar CVar, const char[] oldValue, const char[] newValue)
{
    g_bEnabledAbility = CVar.BoolValue;

    if(g_bEnabledAbility) CreateAllHudTimers();
    else KillAllHudTimers();
}

public void CVarChange_Ability_Color(ConVar CVar, const char[] oldValue, const char[] newValue)
{
    char sBuffer[16];
    CVar.GetString(sBuffer, sizeof(sBuffer));
    String2Color(sBuffer, true);
}

public void CVarChange_Ability_PosX(ConVar CVar, const char[] oldValue, const char[] newValue)
{
    g_fPosXAbility = CVar.FloatValue;
    if(g_fPosX < 0) g_fPosXAbility = -1.0;
}

public void CVarChange_Ability_PosY(ConVar CVar, const char[] oldValue, const char[] newValue)
{
    g_fPosYAbility = CVar.FloatValue;
    if(g_fPosY < 0) g_fPosXAbility = -1.0;
}

void String2Color(const char[] str, bool ability = false)
{
    static char Splitter[4][16];
    if(ExplodeString(str, " ", Splitter, sizeof(Splitter), sizeof(Splitter[])) > 3)
    {
        for(int i; i < 4; i++)
        {
            if(String_IsNumeric(Splitter[i]))
            {
                if (ability) {
                    g_iColorAbility[i] = StringToInt(Splitter[i]);
                    if(g_iColorAbility[i] < 0 || g_iColorAbility[i] > 255)
                    {
                        PrintToServer("Zombie Swarm HUD warning: incorrect '%s' color parameter (%i)! Correct: 0 - 255.", colors[i], g_iColorAbility[i]);
                        g_iColorAbility[i] = 255;
                    }
                } else {
                    g_iColor[i] = StringToInt(Splitter[i]);
                    if(g_iColor[i] < 0 || g_iColor[i] > 255)
                    {
                        PrintToServer("Zombie Swarm HUD warning: incorrect '%s' color parameter (%i)! Correct: 0 - 255.", colors[i], g_iColor[i]);
                        g_iColor[i] = 255;
                    }
                }
            }
            else
            {
                if (ability) g_iColorAbility[i] = 255;
                else g_iColor[i] = 255;
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

void KillAllHudTimers()        // Kill all of the active timers.
{
    for(int i = 1; i <= MaxClients; i++)
        KillHudHintTimer(i);
}

void CreateAllHudTimers()    // Enable timers on all players in game.
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
    char szText[512];
    szText[0] = '\0';
    char szTextAbility[512];
    szTextAbility[0] = '\0';
    int abilities[API_MAX_PLAYER_ABILITIES];
    int found = 0;
    bool havefound = false;
    // Dealing with a client who is in the game and playing.
    if(IsPlayerAlive(client))
    {
        GetInformationAboutPlayer(client, szText, sizeof(szText));
        ZMPlayer player = ZMPlayer(client);
        havefound = player.GetPlayerAbilities(abilities, found);
        if (havefound) {
            GetPlayerAbilityInfo(client, szTextAbility, sizeof(szTextAbility));
        }
    } else {

        int iSpecModeUser = GetEntProp(client, Prop_Send, "m_iObserverMode");
        if(iSpecModeUser == SPECMODE_FIRSTPERSON || iSpecModeUser == SPECMODE_3RDPERSON)
        {
            // Find out who the User is spectating.
            int iTargetUser = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
            GetInformationAboutPlayer(iTargetUser, szText, sizeof(szText));
            ZMPlayer player = ZMPlayer(iTargetUser);
            havefound = player.GetPlayerAbilities(abilities, found);
            if (havefound) {
                GetPlayerAbilityInfo(iTargetUser, szTextAbility, sizeof(szTextAbility));
            }
        }
    }
    if (g_hHudSync[client] == null)
    {
        g_hHudSync[client] = CreateHudSynchronizer();
    }
    if (g_hHudSyncAbility[client] == null)
    {
        g_hHudSyncAbility[client] = CreateHudSynchronizer();
    }
    SetHudTextParams(g_fPosX, g_fPosY, UPDATE_INTERVAL+0.1, g_iColor[0], g_iColor[1], g_iColor[2], g_iColor[3], 0, 0.0, 0.0, 0.0);
    ShowSyncHudText(client, g_hHudSync[client], szText);
    if (havefound) {
        SetHudTextParams(g_fPosXAbility, g_fPosYAbility, UPDATE_INTERVAL+0.1, g_iColorAbility[0], g_iColorAbility[1], g_iColorAbility[2], g_iColorAbility[3], 0, 0.0, 0.0, 0.0);
        ShowSyncHudText(client, g_hHudSyncAbility[client], szTextAbility);
    }

    return Plugin_Continue;
}

void GetInformationAboutPlayer(int client, char[] str, int maxlength) {
    if(!UTIL_IsValidClient(client)) return;
    char temp_string[512];
    temp_string[0] = '\0';
    ZMPlayer player = ZMPlayer(client);
    PrestigePlayer prestige = PrestigePlayer(client);
    char rank_name[32];
    int bytes = GUM_GetRankName(client, rank_name);
    Format(temp_string, sizeof(temp_string), "%t:\n", "Main: About Player", player.Client);
    Format(temp_string, sizeof(temp_string), "%s  %t\n", temp_string, "Main: Reborns", prestige.Reborn, prestige.MaxReborns);
    if (prestige.Evolution > 0 || prestige.Nirvana > 0)
        Format(temp_string, sizeof(temp_string), "%s  %t\n", temp_string, "Main: Evolutions", prestige.Evolution, prestige.MaxEvolutions);
    if (prestige.Nirvana > 0)
        Format(temp_string, sizeof(temp_string), "%s  %t\n", temp_string, "Nirvanas: [ %i ]", prestige.Nirvana);

    Format(temp_string, sizeof(temp_string), "%s  %t\n", temp_string, "Main: Level", GUM_GetPlayerLevel(client), prestige.MaxLevel);
    Format(temp_string, sizeof(temp_string), "%s  %t\n", temp_string, "Main: XP", GUM_GetPlayerUnlocks(client), GUM_GetUnlocksToLevel(client));
    if (bytes > 0) {
        Format(temp_string, sizeof(temp_string), "%s  %t\n \n", temp_string, "Main: Rank", rank_name);
    }
    strcopy(str, maxlength, temp_string);
}

void GetPlayerAbilityInfo(int client, char[] str, int maxlength) {
    if(!UTIL_IsValidClient(client)) return;
    char temp_string[512];
    int abilities[API_MAX_PLAYER_ABILITIES];
    int found = 0;
    ZMPlayer player = ZMPlayer(client);
    bool havefound = player.GetPlayerAbilities(abilities, found);
    if(!havefound) return;
    Format(temp_string, sizeof(temp_string), "%t\n\n","Abilities: Title");
    for (int i = 0; i < found; i++) {
        if (abilities[i] < 0) {
            continue;
        }
        int ability_index = player.GetAbilityByID(abilities[i]);
        if (ability_index < 0)
            continue;

        PlayerAbility ability = view_as<PlayerAbility>(abilities[i]);
        char sState[128];
        if (ability.State == stateIdle) {
            Format(sState, sizeof(sState), "%t", "Ability state: Ready to use");
            char buttons[64];
            UTIL_DEBUG_PrintButtons(ability.Buttons, buttons);
            char name[MAX_ABILITY_NAME_SIZE];
            ability.GetName(name, sizeof(name));
            Format(temp_string, sizeof(temp_string), "%s%t\n",temp_string, "Ability format: Ready to use", name, sState, buttons);
        } else if (ability.State == stateRunning) {
            Format(sState, sizeof(sState), "%t", "Ability state: Activated");
            char name[MAX_ABILITY_NAME_SIZE];
            ability.GetName(name, sizeof(name));
            Format(temp_string, sizeof(temp_string), "%s%t\n",temp_string, "Ability format: Activated", name, sState, ability.CurrentDuration);
        } else if (ability.State == stateCooldown) {
            Format(sState, sizeof(sState), "%t", "Ability state: On cooldown");
            char name[MAX_ABILITY_NAME_SIZE];
            ability.GetName(name, sizeof(name));
            Format(temp_string, sizeof(temp_string), "%s%t\n",temp_string, "Ability format: On cooldown", name, sState, ability.CurrentCooldown);
        } else if (ability.State == stateDisabled) {
            Format(sState, sizeof(sState), "%t", "Ability state: Disabled");
            char name[MAX_ABILITY_NAME_SIZE];
            ability.GetName(name, sizeof(name));
            Format(temp_string, sizeof(temp_string), "%s%t\n",temp_string, "Ability format: Disabled", name);
        }
    }
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
        delete HudHintTimers[client];
        HudHintTimers[client] = null;
    }
    if(g_hHudSync[client] != null)
    {
        delete g_hHudSync[client];
        g_hHudSync[client] = null;
    }
    if(g_hHudSyncAbility[client] != null)
    {
        delete g_hHudSyncAbility[client];
        g_hHudSyncAbility[client] = null;
    }
}

stock void UTIL_DEBUG_PrintButtons(int buttons, char[] message) {
    int found = 0;
    char button_text[128];
    if (buttons & IN_ATTACK) {
        if (found > 0) {
            Format(button_text, sizeof(button_text), "%s + ", button_text);
            found++;
        }
        Format(button_text, sizeof(button_text), "%s%t", button_text, "Button: Mouse1");
    } if (buttons & IN_JUMP) {
        if (found > 0) {
            Format(button_text, sizeof(button_text), "%s + ", button_text);
            found++;
        }
        Format(button_text, sizeof(button_text), "%s%t", button_text, "Button: Jump");
    } if (buttons & IN_DUCK) {
        if (found > 0) {
            Format(button_text, sizeof(button_text), "%s + ", button_text);
            found++;
        }
        Format(button_text, sizeof(button_text), "%s%t", button_text, "Button: Duck");
    } if (buttons & IN_FORWARD) {
        if (found > 0) {
            Format(button_text, sizeof(button_text), "%s + ", button_text);
            found++;
        }
        Format(button_text, sizeof(button_text), "%s%t", button_text, "Button: W (Forward)");
    } if (buttons & IN_BACK) {
        if (found > 0) {
            Format(button_text, sizeof(button_text), "%s + ", button_text);
            found++;
        }
        Format(button_text, sizeof(button_text), "%s%t", button_text, "Button: S (Back)");
    } if (buttons & IN_USE) {
        if (found > 0) {
            Format(button_text, sizeof(button_text), "%s + ", button_text);
            found++;
        }
        Format(button_text, sizeof(button_text), "%s%t", button_text, "Button: E (USE)");
    } if (buttons & IN_MOVELEFT) {
        if (found > 0) {
            Format(button_text, sizeof(button_text), "%s + ", button_text);
            found++;
        }
        Format(button_text, sizeof(button_text), "%s%t", button_text, "Button: A (MOVE LEFT)");
    } if (buttons & IN_MOVERIGHT) {
        if (found > 0) {
            Format(button_text, sizeof(button_text), "%s + ", button_text);
            found++;
        }
        Format(button_text, sizeof(button_text), "%s%t", button_text, "Button: D (MOVE RIGHT)");
    } if (buttons & IN_ATTACK2) {
        if (found > 0) {
            Format(button_text, sizeof(button_text), "%s + ", button_text);
            found++;
        }
        Format(button_text, sizeof(button_text), "%s%t", button_text, "Button: Right mouse click");
    } if (buttons & IN_RELOAD) {
        if (found > 0) {
            Format(button_text, sizeof(button_text), "%s + ", button_text);
            found++;
        }
        Format(button_text, sizeof(button_text), "%s%t", button_text, "Button: R (Reload)");
    }
    Format(message, 128, "%s", button_text);
}