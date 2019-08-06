#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <clientprefs>
#include <colorvariables>
#include <autoexecconfig>
#include <emitsoundany>

#undef REQUIRE_PLUGIN
#tryinclude <zombieplague>
#tryinclude <zombiereloaded>
#tryinclude <zombieswarm>
#define REQUIRE_PLUGIN

// Globals
#include "swarm/gum/globals.sp"
#include "swarm/gum/sql.sp"
#include "swarm/gum/xpconfig.sp"

#define PLUGIN_VERSION "1.0"
#define PLUGIN_NAME "Gun Unlocks Mod"

#define MAX_RANK_NAME 32

public Plugin myinfo =
{
    name = PLUGIN_NAME,
    author = "Zombie Swarm Contributors",
    description = "Kill enemies to get stronger",
    version = PLUGIN_VERSION,
    url = "https://github.com/Prefix/zombieswarm"
};

#define GUM_ChatPrefix "[ GUM ]"

public void OnPluginStart()
{
    LoadTranslations("gum.phrases");
    CreateConVar("gum_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_REPLICATED);

    AutoExecConfig_SetCreateDirectory(true);
    AutoExecConfig_SetCreateFile(true);
    AutoExecConfig_SetFile("gunxpmod", "gunxpmod");
    cvarSaveType = AutoExecConfig_CreateConVar("gum_savetype", "0", "Save Data Type : 0 = SteamID, 1 = IP, 2 = Name.",_,true,0.0,true,2.0);
    cvarWeaponRestriction = AutoExecConfig_CreateConVar("gum_restrict_guns", "1", "Restrict weapon picking, based on levels? 1 - Yes, 0 - No.",_,true,0.0,true,1.0);
    InitExperience();
    // CVARS: reopen when lvl, dont count bots when calculating dmg
    // Weapons
    cvarWeaponMenu = AutoExecConfig_CreateConVar("gum_menu", "1", "Show weapons by menu? 1 - Yes, 0 - Give instantly",_,true,0.0,true,1.0);
    cvarMenuTime = AutoExecConfig_CreateConVar("gum_menu_time", "30", "Cvar for how many seconds menu is shown");
    cvarMenuDelay = AutoExecConfig_CreateConVar("gum_menu_delay", "1.0", "Delay to display menu when player spawned");
    cvarMenuReOpen = AutoExecConfig_CreateConVar("gum_menu_reopen", "1", "Enable menu re-open ? 1 - Yes, 0 - No.",_,true,0.0,true,1.0);
    cvarMenuAutoReOpenTime = AutoExecConfig_CreateConVar("gum_menu_reopen_auto", "0", ">0 - Amount of time that menu shall open, 0 - Don't reopen.",_,true,0.0,true,1.0);
    cvarEnableTop10 = AutoExecConfig_CreateConVar("gum_enable_top10", "1", "Enable !top10 ? 1 - Yes, 0 - No.",_,true,0.0,true,1.0);
    cvarMaxSecondary = AutoExecConfig_CreateConVar("gum_max_secondary", "9", "Max pistols level we have. Make sure you know what you edit here!");
    AutoExecConfig_ExecuteFile();
    AutoExecConfig_CleanFile();

    ClientPrimaryCookie = RegClientCookie("GunXPClientPrimary", "Cookie to store client selections from GunXP Primary menu", CookieAccess_Private);
    ClientSecondaryCookie = RegClientCookie("GunXPSecondaryPrimary", "Cookie to store client selections from GunXP Secondary menu", CookieAccess_Private);
    
    for (int i = MaxClients; i > 0; --i) {
        if (!AreClientCookiesCached(i)) {
            continue;
        }
        OnClientCookiesCached(i);
    }

    // Events
    HookEvent("player_spawn", eventPlayerSpawn);
    HookEvent("player_death", eventPlayerDeath);
    HookEvent("round_start",  eventRoundStart);
    HookEvent("player_hurt",  eventPlayerHurt);
    HookEvent("player_team",  eventPlayerTeam);
    HookEvent("round_end", eventRoundEnd, EventHookMode_Post);
    // Configs
    BuildPath(Path_SM, modConfig, sizeof(modConfig), "configs/gunxpmod/gum_weapons.cfg");

    // Console commands
    RegConsoleCmd("say", sayCommand);
    
    RegAdminCmd("sm_gum_setxp", setAdminUnlocks, ADMFLAG_ROOT);
    
    // Translations
    LoadTranslations("common.phrases");
    
    // Database
    databaseInit();
}
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    CreateNative("GUM_SetPlayerUnlocks", nativeSetPlayerUnlocks);
    CreateNative("GUM_GetPlayerUnlocks", nativeGetPlayerUnlocks);
    CreateNative("GUM_GetUnlocksToLevel", nativeGetUnlocksToLevel);
    CreateNative("GUM_GetRankName", nativeGetPlayerRankName);
    CreateNative("GUM_GetPlayerLevel", nativeGetPlayerLevel);
    CreateNative("GUM_GetMaxLevel", nativeGetMaxLevel);
    CreateNative("GUM_SetPlayerLevel", nativeSetPlayerLevel);
    
    
    // Optional native for ZombiePlague
    MarkNativeAsOptional("ZP_OnExtraBuyCommand");
    MarkNativeAsOptional("ZP_IsPlayerZombie");
    
    // Optional native for ZombieReloaded
    MarkNativeAsOptional("ZR_IsClientZombie");
    
    // Optional native for ZombieSwarm
    MarkNativeAsOptional("ZS_IsClientZombie");
    
    // Register mod library
    RegPluginLibrary("gum");

    g_hForwardOnLevelUp = CreateGlobalForward("GUM_OnLevelUp", ET_Ignore, Param_Cell);

    return APLRes_Success;
}
public void OnAllPluginsLoaded()
{
    #if defined _zombieplaguemod_included
    zpLoaded = LibraryExists("zombieplague");
    #endif
    
    #if defined _zr_included
    zrLoaded = LibraryExists("zombiereloaded");
    #endif
    
    #if defined _zombieswarm_included
    zmLoaded = LibraryExists("zombieswarm");
    #endif
}
public void OnLibraryRemoved(const char[] name)
{
    #if defined _zombieplaguemod_included
    if (StrEqual(name, "zombieplague"))
        zpLoaded = false;
    #endif
        
    #if defined _zr_included
    if (StrEqual(name, "zombiereloaded"))
        zrLoaded = false;
    #endif
    
    #if defined _zombieswarm_included
    if (StrEqual(name, "zombieswarm"))
        zmLoaded = false;
    #endif
}
 
public void OnLibraryAdded(const char[] name)
{
    #if defined _zombieplaguemod_included
    if (StrEqual(name, "zombieplague"))
        zpLoaded = true;
    #endif
    
    #if defined _zr_included
    if (StrEqual(name, "zombiereloaded"))
        zrLoaded = true;
    #endif
    
    #if defined _zombieswarm_included
    if (StrEqual(name, "zombieswarm"))
        zmLoaded = true;
    #endif
}
public void OnClientCookiesCached(int client) {
    char primaryValue[5], secondaryValue[5];
    
    GetClientCookie(client, ClientPrimaryCookie, primaryValue, sizeof(primaryValue));
    GetClientCookie(client, ClientSecondaryCookie, secondaryValue, sizeof(secondaryValue));
    
    rememberPrimary[client] = StringToInt(primaryValue);
    rememberSecondary[client] = StringToInt(secondaryValue);
}  

#if defined _zombieplaguemod_included
public Action ZP_OnExtraBuyCommand(int client, char[] extraitem_command)
{
    return Plugin_Handled;
}
#endif

public void LoadWeaponConfig()
{
    weaponEntities = new ArrayList(ByteCountToCells(32));
    weaponUnlocks = new ArrayList(ByteCountToCells(10));
    weaponAmmo = new ArrayList(ByteCountToCells(10));
    weaponNames = new ArrayList(ByteCountToCells(32));
    rankNames = new ArrayList(ByteCountToCells(32));

    KeyValues kvModCfg = CreateKeyValues("weapon_config");

    if (!kvModCfg.ImportFromFile(modConfig)) return;
    if (!kvModCfg.GotoFirstSubKey()) return;
    
    char weaponEntity[32];
    char unlock[10];
    char ammo[10];
    char weaponName[32];
    char rankName[32];
    
    do
    {
        kvModCfg.GetSectionName(weaponEntity, sizeof(weaponEntity));
        kvModCfg.GetString("unlocks", unlock, sizeof(unlock));
        kvModCfg.GetString("ammo", ammo, sizeof(ammo));
        kvModCfg.GetString("name", weaponName, sizeof(weaponName));
        kvModCfg.GetString("rank", rankName, sizeof(rankName));
        
        int iUnlocks = StringToInt(unlock);
        int iAmmo = StringToInt(ammo);

        weaponEntities.PushString(weaponEntity);
        weaponUnlocks.Push(iUnlocks);
        weaponAmmo.Push(iAmmo);
        weaponNames.PushString(weaponName);
        rankNames.PushString(rankName);
    } while (kvModCfg.GotoNextKey());
    
    delete kvModCfg;
}


public void OnMapStart()
{
    restrictBuyzone();
    
    // Disable cash awards
    SetConVarInt(FindConVar("mp_playercashawards"), 0);
    
    LoadWeaponConfig();
    ImportEXPConfig();
}

public void OnMapEnd()
{
    ClearSurviveTimers();
}

public void OnClientPutInServer(int client)
{
    if ( UTIL_IsValidClient(client) && !IsFakeClient(client) )
    {
        loadData(client);
        
        if (!AreClientCookiesCached(client)) {
            rememberPrimary[client] = GetConVarInt(cvarMaxSecondary);
            rememberSecondary[client] = 0;
        }
        pDamageDone[client] = 0;
        pKillDone[client] = 0;
        SendConVarValue(client, FindConVar("mp_playercashawards"), "0");
        SendConVarValue(client, FindConVar("mp_teamcashawards"), "0");
    }
    
    SDKHook(client, SDKHook_WeaponCanUse, onWeaponCanUse);
    CalculatePlayerAmount();
}
public void OnClientPostAdminCheck(int client)
{
    CalculatePlayerAmount();
}

public void OnClientDisconnect(int client)
{
    if ( IsClientInGame(client) )
    {
        pDamageDone[client] = 0;
        pKillDone[client] = 0;
        if (!IsFakeClient(client)) {
            SaveClientData(client);
        }
        
        if (menuTimer[client] != null) {
            delete menuTimer[client];
        }
        //RemoveMultiKill(client);
        RemoveSurviveTimer(client);
    }
    CalculatePlayerAmount();
}

public Action CS_OnBuyCommand(int client, const char[] weapon)   
{   
    // Block buying
    return Plugin_Handled;  
}

public Action onWeaponCanUse(int client, int weapon)
{
    if ( !UTIL_IsValidAlive(client) )
        return Plugin_Handled;
    
    if (IsFakeClient(client) || !GetConVarInt(cvarWeaponRestriction))
        return Plugin_Continue;
        
    /*#if defined _zombieplaguemod_included
    if (zpLoaded && ZP_IsPlayerZombie(client)) return Plugin_Continue;
    #endif
    
    #if defined _zr_included
    if (zrLoaded && ZR_IsClientZombie(client)) return Plugin_Continue;
    #endif
    
    #if defined _zombieswarm_included
    if (zmLoaded && ZS_IsClientZombie(client)) return Plugin_Continue;
    #endif*/

    char sWeapon[32], arrWeaponString[32];
    GetWeaponClassname(weapon, sWeapon, sizeof(sWeapon));
    
    if (StrContains(sWeapon, "knife")>=0)
        return Plugin_Continue;

    if (PlayerIsZombie(client))
        return Plugin_Handled;
        
    if (playerLevel[client] + 1 >= weaponEntities.Length)
        return Plugin_Continue;
        
    for (int lvlEquipId = playerLevel[client] + 1; lvlEquipId < weaponEntities.Length; lvlEquipId++) 
    {
        weaponEntities.GetString(lvlEquipId, arrWeaponString, sizeof(arrWeaponString));

        if( StrEqual(sWeapon, arrWeaponString) )
        {
            return Plugin_Handled;
        }
    }
    
    return Plugin_Continue;
}

public Action setAdminUnlocks(int client, int args)
{
    if(!UTIL_IsValidClient(client))
    {
        PrintToServer("%t","Command is in-game only!");
        return Plugin_Handled;
    }

    if(args < 2) 
    {
        ReplyToCommand(client, "%t", "Command: sm_gum_setxp Description");
        return Plugin_Handled;
    }

    char amountArg[10], targetArg[32];

    GetCmdArg(1, targetArg, sizeof(targetArg)); 
    GetCmdArg(2, amountArg, sizeof(amountArg));

    int amount = StringToInt(amountArg);

    char targetName[MAX_TARGET_LENGTH]; 
    int targetList[MAXPLAYERS + 1], targetCount; 
    bool targetTranslate; 

    if ((targetCount = ProcessTargetString(targetArg, client, targetList, MAXPLAYERS, COMMAND_FILTER_CONNECTED, 
    targetName, sizeof(targetName), targetTranslate)) <= 0) 
    { 
        ReplyToTargetError(client, targetCount); 
        return Plugin_Handled; 
    } 

    for (int i = 0; i < targetCount; i++) 
    {
        int tClient = targetList[i]; 
        if (UTIL_IsValidClient(tClient)) 
        {
            CPrintToChat(tClient, "%t", "Command: sm_gum_setxp Message", client, amount);
            setPlayerUnlocks(tClient, amount);
        } 
    } 

    return Plugin_Handled;
}

public Action sayCommand(int client, int args)
{
    if ( !UTIL_IsValidClient(client) )
        return Plugin_Continue;
    
    char text[192];
    char sArg1[16];
    GetCmdArgString(text, sizeof(text));

    StripQuotes(text);

    BreakString(text, sArg1, sizeof(sArg1));
    
    if( StrEqual(sArg1, "/level") ||  StrEqual(sArg1, "!level") || StrEqual(sArg1, "level") || StrEqual(sArg1, "/xp") || StrEqual(sArg1, "!xp") || StrEqual(sArg1, "xp") )
    {
        CPrintToChat(client, "{blue}LEVEL {default}[{green}%d{default}]", playerLevel[client]);
        CPrintToChat(client, "{blue}UNLOCKS {default}[{green}%d {default}/ {green}%d{default}]", pUnlocks[client], getMaxPlayerUnlocksByLevel(playerLevel[client]));
        
        return Plugin_Handled;
    }
    else if (( StrEqual(sArg1, "!top10") || StrEqual(sArg1, "/top10") || StrEqual(sArg1, "top10")) && GetConVarInt(cvarEnableTop10) )
    {
        ExecuteTopTen(client);
        
        return Plugin_Handled;
    }
    else if (( StrEqual(sArg1, "!guns") || StrEqual(sArg1, "guns") || StrEqual(sArg1, "/guns")) && GetConVarInt(cvarMenuReOpen) )
    {
        if (PlayerIsZombie(client))
            return Plugin_Handled;
        
        if (!GetConVarInt(cvarWeaponMenu))
            return Plugin_Continue;
    
        if ( !weaponSelected[client] )
        {
            CPrintToChat(client, "%t", "Chat: Gun Menu Reopen" );
            menuTimer[client] = CreateTimer( GetConVarFloat(cvarMenuDelay), mainMenu, client, TIMER_FLAG_NO_MAPCHANGE );
        }
        
        return Plugin_Handled;
    }
    
    return Plugin_Continue;
}

bool PlayerIsZombie(int client)
{
    #if defined _zombieplaguemod_included
    if (zpLoaded && ZP_IsPlayerZombie(client)) return true;
    #endif
    
    #if defined _zr_included
    if (zrLoaded && ZR_IsClientZombie(client)) return true;
    #endif
    
    #if defined _zombieswarm_included
    if (zmLoaded && ZS_IsClientZombie(client)) return true;
    #endif

    return false;
}

public void eventPlayerChangename(Event event, const char[] name, bool dontBroadcast)
{
    if (GetConVarInt(cvarSaveType) != 2)
        return; 

    char sNewName[32], sOldName[32];
    int client = GetClientOfUserId( GetEventInt(event,"userid") );
    GetEventString( event, "newname", sNewName, sizeof( sNewName ) );
    GetEventString( event, "oldname", sOldName, sizeof( sOldName ) );
    
    if ( !UTIL_IsValidClient(client) )
        return;

    if ( !StrEqual( sOldName, sNewName )  )
    {
        setPlayerUnlocks(client, 0);
        
        rememberSecondary[client] = 0;
        rememberPrimary[client] = GetConVarInt(cvarMaxSecondary);
    }
}
public void eventRoundEnd(Event event, const char[] name, bool dontBroadcast)
{
    int winner = GetEventInt(event, "winner");
    RemoveSurviveTimer();
    //RemoveMultiKill();
    RoundWinnerBonus(winner);
    MostDamageBonus(winner);
    ClearSurviveTimers();
    ResetDamageNKills();
    HappyHourEndRound(winner);
}

public void eventPlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "attacker"));
    int newteam = GetEventInt(event, "team");
    int oldteam = GetEventInt(event, "oldteam");
    //bool disconnect = GetEventBool(event, "disconnect");
    
    if (!UTIL_IsValidClient(client))
        return;

    if (newteam != oldteam)
    {
        pDamageDone[client] = 0;
        pKillDone[client] = 0;
    }
}

public void eventPlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
    int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
    int victim   = GetClientOfUserId(GetEventInt(event, "userid"));
    int damage   = GetEventInt(event, "dmg_health");

    if ( !UTIL_IsValidClient(attacker) )
        return;

    if ( attacker == victim )
        return;

    pDamageDone[attacker] += damage;

    if (!g_cEXP_Damage.BoolValue) XPonHurt(attacker, victim, damage);
    if (g_aActiveHappyHours.Length > 0) GiveHappyHourBonus(attacker, configDamage, damage);
}

public void eventPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    /* Reserved */
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
    RemoveSurviveTimer(client, -1);
    //RemoveMultiKill(client, -1);
    if (!UTIL_IsValidClient(attacker))
        return;
    if (!UTIL_IsValidClient(client))
        return;
    if (client == attacker)
        return;
    if (GetClientTeam(client) == GetClientTeam(attacker))
        return;
    pKillDone[attacker] += 1;
    XPonKills(attacker);
    //DeathMultiKillLogic(attacker);

    if (g_aActiveHappyHours.Length > 0)
        GiveHappyHourBonus(attacker, configKills);
    if (UTIL_IsValidClient(client))
        SaveClientData(client);
    if (UTIL_IsValidClient(attacker))
        SaveClientData(attacker);
}

public void eventRoundStart(Event event, const char[] name, bool dontBroadcast)
{
    restrictBuyzone();
}

public void eventPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));

    if ( !UTIL_IsValidAlive(client) )
        return;
    if ( IsClientSourceTV(client) )
        return;
    
    if (menuTimer[client] != null) {
        delete menuTimer[client];
    }

    pDamageDone[client] = 0;
    pKillDone[client] = 0;
    
    stripPlayerWeapons(client);
    
    if ( IsFakeClient(client) )
    {
        giveWeaponSelection( client, GetRandomInt( 0, GetConVarInt(cvarMaxSecondary) - 1 ), 0);
        giveWeaponSelection( client, GetRandomInt( GetConVarInt(cvarMaxSecondary), weaponEntities.Length - 1 ), 0);
    } else {
        menuTimer[client] = CreateTimer( GetConVarFloat(cvarMenuDelay), mainMenu, client, TIMER_FLAG_NO_MAPCHANGE);
    }
    StartSurviveTimers(client);
}


// Menus
public Action mainMenu(Handle timer, any client)
{
    menuTimer[client] = null;

    if ( !UTIL_IsValidAlive(client) ) {
        return Plugin_Stop;
    }
    
    if (PlayerIsZombie(client))
        return Plugin_Stop;
    
    weaponSelected[client] = false;
    
    if (GetConVarInt(cvarWeaponMenu)) {
        mainWeaponMenu(client);
    } else {
        giveWeaponSelection(client, playerLevel[client], 1);
    }
    
    if (GetConVarFloat(cvarMenuAutoReOpenTime) > 0.0)
        menuTimer[client] = CreateTimer( GetConVarFloat(cvarMenuAutoReOpenTime), mainMenu, client, TIMER_FLAG_NO_MAPCHANGE);

    return Plugin_Stop;
}

public void mainWeaponMenu(int client)
{
    Menu menu = new Menu(WeaponMenuHandler);
    char buffer[64];
    menu.SetTitle("%t","Menu Title: Gun XP Mod Weapons");

    Format(buffer,sizeof(buffer),"%t","Menu option: Choose Weapon");
    menu.AddItem("selectionId", buffer);
    Format(buffer,sizeof(buffer),"%t","Menu option: Last Selected Weapons");
    menu.AddItem("selectionId", buffer);

    menu.ExitButton = true;
    
    menu.Display(client, GetConVarInt(cvarMenuTime) );
}
public int WeaponMenuHandler(Menu menu, MenuAction action, int client, int item)
{
    if( action == MenuAction_Select )
    {    
        if (!PlayerIsZombie(client)) 
        {
            switch (item)
            {
                case 0: // show pistols
                {
                    secondaryWeaponMenu(client);
                }
                case 1: // last weapons
                {
                    weaponSelected[client] = true;
                    
                    if ( playerLevel[client] > GetConVarInt(cvarMaxSecondary) - 1 )
                    {
                        giveWeaponSelection(client, rememberPrimary[client], 1);
                        giveWeaponSelection(client, rememberSecondary[client], 0);
                    }
                    else if ( playerLevel[client] < GetConVarInt(cvarMaxSecondary) )
                    {
                        giveWeaponSelection(client, rememberSecondary[client], 1);
                    }
                }
            }
        }
    } 
    else if (action == MenuAction_End)    
    {
        delete menu;
    }
}
public void secondaryWeaponMenu(int client)
{
    Menu menu = new Menu(secondaryWeaponMenuHandler);

    char szMsg[60], szItems[60], arrWeaponString[32];
    Format(szMsg, sizeof( szMsg ), "%t", "Menu Title: Level", playerLevel[client], pUnlocks[client], getMaxPlayerUnlocksByLevel(playerLevel[client]));
    
    menu.SetTitle(szMsg);

    for (int itemId = 0; itemId < GetConVarInt(cvarMaxSecondary); itemId++)
    {
        weaponNames.GetString(itemId, arrWeaponString, sizeof(arrWeaponString));
        if ( playerLevel[client] >= itemId )
        {
            Format(szItems, sizeof( szItems ), "%s %t", arrWeaponString, "Gun Menu: Level format", itemId);

            menu.AddItem("selectionId", szItems);
        }
        else
        {
            Format(szItems, sizeof( szItems ), "%s %t", arrWeaponString, "Gun Menu: Level format", itemId);
            
            menu.AddItem("selectionId", szItems, ITEMDRAW_DISABLED);
        }
    }

    menu.ExitButton = true;
    
    menu.Display(client, GetConVarInt(cvarMenuTime) );
}
public int secondaryWeaponMenuHandler(Menu menu, MenuAction action, int client, int item)
{
    if( action == MenuAction_Select )
    {
        if (PlayerIsZombie(client))
        {
            weaponSelected[client] = true;
            
            rememberSecondary[client] = item;
            
            char value[5];
            IntToString(rememberSecondary[client],value,sizeof(value));
            SetClientCookie(client,ClientSecondaryCookie,value);

            giveWeaponSelection(client, item, 1);
        
            if ( playerLevel[client] > GetConVarInt(cvarMaxSecondary) - 1 )
            {
                primaryWeaponMenu(client);
            }
        }
    } 
    else if (action == MenuAction_End)    
    {
        delete menu;
    }
}
public void primaryWeaponMenu(int client)
{
    Menu menu = new Menu(primaryWeaponMenuHandler);

    char szMsg[60], szItems[60], arrWeaponString[32];
    Format(szMsg, sizeof( szMsg ), "%t", "Menu Title: Level", playerLevel[client], pUnlocks[client], getMaxPlayerUnlocksByLevel(playerLevel[client]));
    
    menu.SetTitle(szMsg);

    for (int itemId = GetConVarInt(cvarMaxSecondary); itemId < weaponEntities.Length; itemId++)
    {
        weaponNames.GetString(itemId, arrWeaponString, sizeof(arrWeaponString));
        if ( playerLevel[client] >= itemId )
        {
            Format(szItems, sizeof( szItems ), "%s %t", arrWeaponString, "Gun Menu: Level format", itemId);

            menu.AddItem("selectionId", szItems);
        }
        else
        {
            Format(szItems, sizeof( szItems ), "%s %t", arrWeaponString, "Gun Menu: Level format", itemId);
            
            menu.AddItem("selectionId", szItems, ITEMDRAW_DISABLED);
        }
    }

    menu.ExitButton = true;
    
    menu.Display(client, GetConVarInt(cvarMenuTime) );
}
public int primaryWeaponMenuHandler(Menu menu, MenuAction action, int client, int item)
{
    if( action == MenuAction_Select )
    {
        if (!PlayerIsZombie(client))
        {
            rememberPrimary[client] = item + GetConVarInt(cvarMaxSecondary);
            
            char value[5];
            IntToString(rememberPrimary[client],value,sizeof(value));
            SetClientCookie(client,ClientPrimaryCookie,value);
        
            giveWeaponSelection(client, item + GetConVarInt(cvarMaxSecondary), 0);
        }
    } 
    else if (action == MenuAction_End)    
    {
        delete menu;
    }
}
public void giveWeaponSelection(int client, int selection, int strip)
{
    if( UTIL_IsValidAlive(client) && !IsClientSourceTV(client) ) 
    {
        if ( strip )
        {
            stripPlayerWeapons(client);
        }
        
        char arrWeaponString[32];
        weaponEntities.GetString(selection, arrWeaponString, sizeof(arrWeaponString));
        int AmmoAmount = weaponAmmo.Get(selection);
        
        int weapon = GivePlayerItem(client, arrWeaponString);

        // Sets weapon ammo

        DataPack data = new DataPack(); 

        data.WriteCell(GetClientSerial(client)); 
        data.WriteCell(weapon); 
        data.WriteCell(AmmoAmount); 
        data.Reset(); 

        RequestFrame(SetWeaponAmmo, data); 
    }
}
public void SetWeaponAmmo(DataPack data) {  
    int client = GetClientFromSerial(data.ReadCell()); 
    int weapon = data.ReadCell(); 
    int ammo = data.ReadCell(); 
    data.Close(); 
    if (!UTIL_IsValidAlive(client)) return;
    if (weapon < 1) return;

    int ammotype = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType"); 
    if(ammotype == -1) return; 
    SetEntProp(client, Prop_Send, "m_iAmmo", ammo, _, ammotype); 
    SetEntProp(weapon, Prop_Send, "m_iPrimaryReserveAmmoCount", ammo);
}  
// Usefull Stocks
public void stripPlayerWeapons(int client)
{
    int wepIdx;
    for (int i = 0; i < 2; i++)
    {
        if ((wepIdx = GetPlayerWeaponSlot(client, i)) != -1)
        {
            RemovePlayerItem(client, wepIdx);
            AcceptEntityInput(wepIdx, "Kill");
        }
    }
    FakeClientCommand(client, "use weapon_knife");
}
public void setPlayerUnlocks(int client, int value)
{
    if ( !UTIL_IsValidClient(client) )
        return;

    setPlayerUnlocksLogics(client, value);
    SaveClientData(client);
}
public void setPlayerUnlocksLogics(int client, int value)
{
    pUnlocks[client] = value;

    if ( pUnlocks[client] < 0 )
    {
        pUnlocks[client] = 0;
    }
    
    int levelByUnlocks = getPlayerLevelByUnlocks(client);

    if(levelByUnlocks > playerLevel[client])
    {
        CPrintToChat(client, "%t", "Chat: Level up", levelByUnlocks);
        
        if (GetConVarInt(cvarWeaponMenu)) {
            menuTimer[client] = CreateTimer( GetConVarFloat(cvarMenuDelay), mainMenu, client, TIMER_FLAG_NO_MAPCHANGE);
        } else {
            giveWeaponSelection(client, levelByUnlocks, 1);
        }
    }
    
    playerLevel[client] = levelByUnlocks;
    if (playerLevel[client] > 0) {
        Call_StartForward(g_hForwardOnLevelUp);
        Call_PushCell(client);
        Call_Finish();
    }
    SaveClientData(client);
}
public int getPlayerLevelByUnlocks(int client)
{
    int pLevel = 0;

    for (int i = 0; i < weaponUnlocks.Length; i++) 
    {
        if (i+1 < weaponUnlocks.Length && weaponUnlocks.Get(i+1) >= pUnlocks[client]+1) {
            pLevel = i;
            break;
        } 
        else if (i+1 >= (weaponUnlocks.Length)) {
            pLevel = weaponUnlocks.Length-1;
            break;
        }
    }

    return pLevel;
}
public int getMaxPlayerUnlocksByLevel(int level)
{
    if (level+1 >= weaponUnlocks.Length)
        return weaponUnlocks.Get(weaponUnlocks.Length-1);

    return weaponUnlocks.Get(level+1);
}
public int nativeSetPlayerUnlocks(Handle plugin, int numParams)
{
    int client = GetNativeCell( 1 );
    int value = GetNativeCell( 2 );

    if ( !UTIL_IsValidClient(client) )
        return;

    setPlayerUnlocksLogics(client, value);
}

public int nativeSetPlayerLevel(Handle plugin, int numParams)
{
    int client = GetNativeCell( 1 );
    int value = GetNativeCell( 2 );

    if ( !UTIL_IsValidClient(client) )
        return;

    if (value+1 >= weaponUnlocks.Length)
        return;

    setPlayerUnlocksLogics(client, weaponUnlocks.Get(value));
}

public int nativeGetMaxLevel(Handle plugin, int numParams)
{
    return weaponEntities.Length;
}

public int nativeGetPlayerUnlocks(Handle plugin, int numParams)
{
    int client = GetNativeCell( 1 );

    if (!UTIL_IsValidClient(client)) {
        return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index (%d)", client);
    }

    return pUnlocks[client];
}
public int nativeGetUnlocksToLevel(Handle plugin, int numParams)
{
    int client = GetNativeCell( 1 );

    if (!UTIL_IsValidClient(client)) {
        return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index (%d)", client);
    }

    return getMaxPlayerUnlocksByLevel(playerLevel[client]);
}


public int nativeGetPlayerRankName(Handle plugin, int numParams)
{
    int client = GetNativeCell( 1 );

    if (!UTIL_IsValidClient(client)) {
        return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index (%d)", client);
    }

    int level = playerLevel[client];
    char rank_name[MAX_RANK_NAME];
    rankNames.GetString(level, rank_name, MAX_RANK_NAME);
    int bytes;
    SetNativeString(2, rank_name, MAX_RANK_NAME, true, bytes);
    return bytes;
}

public int nativeGetPlayerLevel(Handle plugin, int numParams)
{
    int client = GetNativeCell( 1 );

    if (!UTIL_IsValidClient(client)) {
        return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index (%d)", client);
    }

    return playerLevel[client];
}

public void restrictBuyzone() {
    char sClass[65];
    for (int i = MaxClients; i <= GetMaxEntities(); i++)
    {
        if(IsValidEdict(i) && IsValidEntity(i))
        {
            GetEdictClassname(i, sClass, sizeof(sClass));
            if(StrEqual("func_buyzone", sClass))
            {
                RemoveEdict(i);
            }
        }
    } 
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
stock bool UTIL_IsValidClient(int client)
{
    return ( 1 <= client <= MaxClients && IsClientInGame(client) );
}
stock bool UTIL_IsValidAlive(int client)
{
    return ( 1 <= client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client) );
}

/**
 * Checks to see if a client has all of the specified admin flags
 *
 * @param client        Player's index.
 * @param flagString    String of flags to check for.
 * @return                True on admin having all flags, false otherwise.
 * Original taken from https://forums.alliedmods.net/showpost.php?p=886345&postcount=4
 */
stock bool CheckAdminFlagsByString(int client, const char[] flagString)
{
    if (strlen(flagString) < 1)
        return true;
    AdminId admin = view_as<AdminId>(GetUserAdmin(client));
    if (admin != INVALID_ADMIN_ID){
        if(GetAdminFlag(admin, Admin_Root)) {
            return true;
        }
        int count, found, flags = ReadFlagString(flagString);
        for (int i = 0; i <= 20; i++){
            if (flags & (1<<i))
            {
                count++;

                if(GetAdminFlag(admin, view_as<AdminFlag>(i))){
                    found++;
                }
            }
        }

        if (count == found){
            return true;
        }
    }

    return false;
}

stock bool IsClientVip(int client)
{
    if (GetUserFlagBits(client) & ADMFLAG_RESERVATION || GetUserFlagBits(client) & ADMFLAG_ROOT) 
        return true;
    return false;
}