#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <clientprefs>
#include <colorvariables>

#undef REQUIRE_PLUGIN
#tryinclude <zombieplague>
#tryinclude <zombiereloaded>
#tryinclude <zombieswarm>
#define REQUIRE_PLUGIN

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

ArrayList weaponEntities;
ArrayList weaponUnlocks;
ArrayList weaponAmmo;
ArrayList weaponNames;
ArrayList rankNames;

bool weaponSelected[MAXPLAYERS + 1];

#if defined _zombieplaguemod_included
bool zpLoaded;
#endif

#if defined _zr_included
bool zrLoaded;
#endif

#if defined _zombieswarm_included
bool zmLoaded;
#endif

Handle cvarMenuTime, cvarDamageReward, cvarDamageRewardVIP, cvarDamageDeal, cvarWeaponMenu,
cvarMenuDelay, cvarMenuReOpen, cvarSaveType, cvarEnableTop10,
cvarWeaponRestriction, cvarMenuAutoReOpenTime, cvarMaxSecondary, ClientPrimaryCookie = INVALID_HANDLE,
ClientSecondaryCookie = INVALID_HANDLE;

Database conDatabase = null;
Handle menuTimer[MAXPLAYERS + 1] = null;
Handle g_hForwardOnLevelUp;

int playerLevel[MAXPLAYERS + 1], pUnlocks[MAXPLAYERS + 1], pDamageDone[MAXPLAYERS + 1];
int rememberPrimary[MAXPLAYERS + 1], rememberSecondary[MAXPLAYERS + 1];

char modConfig[PLATFORM_MAX_PATH];

#define GUM_ChatPrefix "[ GUM ]"

public void OnPluginStart()
{
    LoadTranslations("gum.phrases");
    CreateConVar("gum_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

    cvarSaveType = CreateConVar("gum_savetype", "0", "Save Data Type : 0 = SteamID, 1 = IP, 2 = Name.");

    cvarWeaponRestriction = CreateConVar("gum_restrict_guns", "1", "Restrict weapon picking, based on levels? 1 - Yes, 0 - No.");

    cvarDamageDeal = CreateConVar("gum_damage_deal", "150", "Damage deal to get reward");
    cvarDamageReward = CreateConVar("gum_damage_reward", "3", "Unlocks for damaging enemy");
    cvarDamageRewardVIP = CreateConVar("gum_damage_reward_vip", "3", "Unlocks for damaging enemy (VIP)");
    
    cvarWeaponMenu = CreateConVar("gum_menu", "1", "Show weapons by menu? 1 - Yes, 0 - Give instantly");
    cvarMenuTime = CreateConVar("gum_menu_time", "30", "Cvar for how many seconds menu is shown");
    cvarMenuDelay = CreateConVar("gum_menu_delay", "1.0", "Delay to display menu when player spawned");
    cvarMenuReOpen = CreateConVar("gum_menu_reopen", "1", "Enable menu re-open ? 1 - Yes, 0 - No.");
    cvarMenuAutoReOpenTime = CreateConVar("gum_menu_reopen_auto", "120.0", ">0 - Amount of time that menu shall open, 0 - Don't reopen.");
    
    cvarEnableTop10 = CreateConVar("gum_enable_top10", "1", "Enable !top10 ? 1 - Yes, 0 - No.");
    
    cvarMaxSecondary = CreateConVar("gum_max_secondary", "9", "Max pistols level we have.");
    
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
    
    // Configs
    BuildPath(Path_SM, modConfig, sizeof(modConfig), "configs/gum_weapons.cfg");
    AutoExecConfig( true, "gum");

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

public void OnConfigsExecuted()
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
        
        SendConVarValue(client, FindConVar("mp_playercashawards"), "0");
        SendConVarValue(client, FindConVar("mp_teamcashawards"), "0");
    }
    
    SDKHook(client, SDKHook_WeaponCanUse, onWeaponCanUse);
}
public void OnClientPostAdminCheck(int client)
{
    
}

public void OnClientDisconnect(int client)
{
    if ( IsClientInGame(client) )
    {
        if (!IsFakeClient(client)) {
            SaveClientData(client);
        }
        
        if (menuTimer[client] != null) {
            delete menuTimer[client];
        }
    }
}

public void SaveClientData(int client) {
    if ( IsClientInGame(client) )
    {
        if (!IsFakeClient(client)) {
            char sQuery[256];
            char sKey[32], oName[32], pName[80];
            getSaveIdentifier( client, sKey, sizeof( sKey ) );
            
            GetClientName(client, oName, sizeof(oName));
            conDatabase.Escape(oName, pName, sizeof(pName));
        
            Format( sQuery, sizeof( sQuery ), "SELECT `purchased` FROM `gum` WHERE ( `player_id` = '%s' )", sKey);
            
            DataPack dp = new DataPack();
            
            dp.WriteCell(playerLevel[client]);
            dp.WriteCell(pUnlocks[client]);
            dp.WriteString(sKey);
            dp.WriteString(pName);
            
            conDatabase.Query( querySelectSavedDataCallback, sQuery, dp);
        }
    }
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
        
    #if defined _zombieplaguemod_included
    if (zpLoaded && ZP_IsPlayerZombie(client)) return Plugin_Continue;
    #endif
    
    #if defined _zr_included
    if (zrLoaded && ZR_IsClientZombie(client)) return Plugin_Continue;
    #endif
    
    #if defined _zombieswarm_included
    if (zmLoaded && ZS_IsClientZombie(client)) return Plugin_Continue;
    #endif

    char sWeapon[32], arrWeaponString[32];
    GetWeaponClassname(weapon, sWeapon, sizeof(sWeapon));
    
    if (StrContains(sWeapon, "knife")>=0)
        return Plugin_Continue;
        
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
        char sQuery[ 256 ]; 
    
        Format( sQuery, sizeof( sQuery ), "SELECT `player_name`, `player_level`, `player_unlocks` FROM `gum` ORDER BY `player_unlocks` DESC LIMIT 10;" );
    
        conDatabase.Query( queryShowTopTableCallback, sQuery, client);
        
        return Plugin_Handled;
    }
    else if (( StrEqual(sArg1, "!guns") || StrEqual(sArg1, "guns") || StrEqual(sArg1, "/guns")) && GetConVarInt(cvarMenuReOpen) )
    {
        #if defined _zombieplaguemod_included
        if (zpLoaded && ZP_IsPlayerZombie(client)) return Plugin_Handled;
        #endif
        
        #if defined _zr_included
        if (zrLoaded && ZR_IsClientZombie(client)) return Plugin_Handled;
        #endif
        
        #if defined _zombieswarm_included
        if (zmLoaded && ZS_IsClientZombie(client)) return Plugin_Handled;
        #endif
        
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

public void eventPlayerChangename(Event event, const char[] name, bool dontBroadcast)
{
    char sNewName[32], sOldName[32];
    int client = GetClientOfUserId( GetEventInt(event,"userid") );
    GetEventString( event, "newname", sNewName, sizeof( sNewName ) );
    GetEventString( event, "oldname", sOldName, sizeof( sOldName ) );
    
    if ( !UTIL_IsValidClient(client) )
        return;

    if ( GetConVarInt(cvarSaveType) == 2 && !StrEqual( sOldName, sNewName )  )
    {
        setPlayerUnlocks(client, 0);
        
        rememberSecondary[client] = 0;
        rememberPrimary[client] = GetConVarInt(cvarMaxSecondary);
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
        
    if (pDamageDone[attacker] >= GetConVarInt(cvarDamageDeal)) {
        if(IsClientVip(attacker))
            setPlayerUnlocks(attacker, pUnlocks[attacker] + GetConVarInt(cvarDamageRewardVIP) );
        else
            setPlayerUnlocks(attacker, pUnlocks[attacker] + GetConVarInt(cvarDamageReward) );
        //SaveClientData(attacker);    
        pDamageDone[attacker] = 0;
    }
    
    pDamageDone[attacker] += damage;
}

stock bool IsClientVip(int client)
{
    if (GetUserFlagBits(client) & ADMFLAG_RESERVATION || GetUserFlagBits(client) & ADMFLAG_ROOT) 
        return true;
    return false;
}

public void eventPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    /* Reserved */
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    if (UTIL_IsValidClient(client))
        SaveClientData(client);
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
    
    stripPlayerWeapons(client);
    
    if ( IsFakeClient(client) )
    {
        giveWeaponSelection( client, GetRandomInt( 0, GetConVarInt(cvarMaxSecondary) - 1 ), 0);
        giveWeaponSelection( client, GetRandomInt( GetConVarInt(cvarMaxSecondary), weaponEntities.Length - 1 ), 0);
    } else {
        menuTimer[client] = CreateTimer( GetConVarFloat(cvarMenuDelay), mainMenu, client, TIMER_FLAG_NO_MAPCHANGE);
    }
}

// Menus
public Action mainMenu(Handle timer, any client)
{
    menuTimer[client] = null;

    if ( !UTIL_IsValidAlive(client) ) {
        return Plugin_Stop;
    }
    
    #if defined _zombieplaguemod_included
    if (zpLoaded && ZP_IsPlayerZombie(client)) return Plugin_Stop;
    #endif
    
    #if defined _zr_included
    if (zrLoaded && ZR_IsClientZombie(client)) return Plugin_Stop;
    #endif
    
    #if defined _zombieswarm_included
    if (zmLoaded && ZS_IsClientZombie(client)) return Plugin_Stop;
    #endif
    
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
        #if defined _zombieplaguemod_included
        if (zpLoaded && ZP_IsPlayerZombie(client)) return;
        #endif
        
        #if defined _zr_included
        if (zrLoaded && ZR_IsClientZombie(client)) return;
        #endif
        
        #if defined _zombieswarm_included
        if (zmLoaded && ZS_IsClientZombie(client)) return;
        #endif
    
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
            Format(szItems, sizeof( szItems ), "%s (Lvl %d)", arrWeaponString, itemId);

            menu.AddItem("selectionId", szItems);
        }
        else
        {
            Format(szItems, sizeof( szItems ), "%s (Lvl %d)", arrWeaponString, itemId);
            
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
        #if defined _zombieplaguemod_included
        if (zpLoaded && ZP_IsPlayerZombie(client)) return;
        #endif
        
        #if defined _zr_included
        if (zrLoaded && ZR_IsClientZombie(client)) return;
        #endif
        
        #if defined _zombieswarm_included
        if (zmLoaded && ZS_IsClientZombie(client)) return;
        #endif
    
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
            Format(szItems, sizeof( szItems ), "%s (Lv %d)", arrWeaponString, itemId);

            menu.AddItem("selectionId", szItems);
        }
        else
        {
            Format(szItems, sizeof( szItems ), "%s (Lv %d)", arrWeaponString, itemId);
            
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
        #if defined _zombieplaguemod_included
        if (zpLoaded && ZP_IsPlayerZombie(client)) return;
        #endif
        
        #if defined _zr_included
        if (zrLoaded && ZR_IsClientZombie(client)) return;
        #endif
        
        #if defined _zombieswarm_included
        if (zmLoaded && ZS_IsClientZombie(client)) return;
        #endif
    
        rememberPrimary[client] = item + GetConVarInt(cvarMaxSecondary);
        
        char value[5];
        IntToString(rememberPrimary[client],value,sizeof(value));
        SetClientCookie(client,ClientPrimaryCookie,value);
    
        giveWeaponSelection(client, item + GetConVarInt(cvarMaxSecondary), 0);
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

public void getSaveIdentifier( int client, char[] szKey, int maxlen )
{
    switch( GetConVarInt( cvarSaveType ) )
    {
        case 2:
        {
            GetClientName( client, szKey, maxlen );

            ReplaceString( szKey, maxlen, "'", "\'" );
        }

        case 1:    GetClientIP( client, szKey, maxlen );
        case 0:    GetClientAuthId( client, AuthId_SteamID64, szKey, maxlen );
    }
}

public void databaseInit()
{
    Database.Connect(databaseConnectionCallback);
}

public void saveData(int rowCount, const char[] sKey, const char[] playerName, int level, int unlocks)
{
    char sQuery[256];
    
    int bufferLength = strlen(playerName) * 2 + 1;
    char[] newPlayerName = new char[bufferLength];
    conDatabase.Escape(playerName, newPlayerName, bufferLength);
    
    if (rowCount > 0)
        Format( sQuery, sizeof( sQuery ), "UPDATE `gum` SET `player_name` = '%s', `player_level` = '%d', `player_unlocks` = '%d', `purchased` = '0' WHERE (`player_id` = '%s');", newPlayerName, level, unlocks, sKey );
    else
        Format( sQuery, sizeof( sQuery ), "INSERT INTO `gum` (`player_id`, `player_name`, `player_level`, `player_unlocks`) VALUES ('%s', '%s', '%d', '%d');", sKey, newPlayerName, level, unlocks );
    
    conDatabase.Query( querySetDataCallback, sQuery);
}
public void loadData(int client)
{
    char sQuery[ 256 ]; 
    
    char szKey[64];
    getSaveIdentifier( client, szKey, sizeof( szKey ) );

    Format( sQuery, sizeof( sQuery ), "SELECT `player_unlocks` FROM `gum` WHERE ( `player_id` = '%s' );", szKey );
    
    conDatabase.Query( querySelectDataCallback, sQuery, client);
}
public void databaseConnectionCallback(Database db, const char[] error, any data)
{
    if ( db == null )
    {
        PrintToServer("Failed to connect: %s", error);
        LogError( "%s", error ); 
        
        return;
    }
    
    conDatabase = db;
    conDatabase.SetCharset("utf8mb4");
    
    char sQuery[512], driverName[16];
    conDatabase.Driver.GetIdentifier(driverName, sizeof(driverName));
    
    if ( StrEqual(driverName, "mysql") )
    {
        Format( sQuery, sizeof( sQuery ), "CREATE TABLE IF NOT EXISTS `gum` ( `id` int NOT NULL AUTO_INCREMENT, \
        `player_id` varchar(32) NOT NULL, \
        `player_name` varchar(32) default NULL, \
        `player_level` int default NULL, \
        `player_unlocks` int default NULL, \
        `purchased` int NOT NULL default 0, \
        PRIMARY KEY (`id`), UNIQUE KEY `player_id` (`player_id`) ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;" );
    }
    else
    {
        Format( sQuery, sizeof( sQuery ), "CREATE TABLE IF NOT EXISTS `gum` ( `id` INTEGER PRIMARY KEY AUTOINCREMENT, \
        `player_id` TEXT NOT NULL UNIQUE, \
        `player_name` TEXT DEFAULT NULL, \
        `player_level` INTEGER DEFAULT NULL, \
        `player_unlocks` INTEGER DEFAULT NULL, \
        `purchased` INTEGER NOT NULL DEFAULT 0 \
         );" );
    }
    
    conDatabase.Query( QueryCreateTable, sQuery);
}
public void QueryCreateTable(Database db, DBResultSet results, const char[] error, any data)
{ 
    if ( db == null )
    {
        LogError( "%s", error ); 
        
        return;
    } 
}
public void querySetDataCallback(Database db, DBResultSet results, const char[] error, any data)
{ 
    if ( db == null )
    {
        LogError( "%s", error ); 
        
        return;
    } 
} 
public void querySelectSavedDataCallback(Database db, DBResultSet results, const char[] error, DataPack pack)
{ 
    if ( db != null )
    {
        int resultRows = results.RowCount;
        
        char sKey[32], pName[32];
        
        pack.Reset();
        int level = pack.ReadCell();
        int unlocks = pack.ReadCell();
        pack.ReadString(sKey, sizeof(sKey));
        pack.ReadString(pName, sizeof(pName));

        if (resultRows > 0) {
            int dbPurchased = 0;
            while ( results.FetchRow() ) 
            {
                int fieldPurchased;
                results.FieldNameToNum("purchased", fieldPurchased);
                
                dbPurchased = results.FetchInt(fieldPurchased);
            }
            saveData(resultRows, sKey, pName, level, unlocks + dbPurchased);
        } else {
            saveData(resultRows, sKey, pName, level, unlocks);
        }
    } 
    else
    {
        LogError( "%s", error ); 
        
        return;
    }
}
public void querySelectDataCallback(Database db, DBResultSet results, const char[] error, any client)
{ 
    if (error[0] != EOS) {
        LogError( "Server misfunctioning come back later: %s", error );
        KickClientEx(client, "Server misfunctioning come back later!");
        return;
    }
    if ( db != null)
    {
        int unlocks = 0;
        if (results.HasResults) {
            while ( results.FetchRow() ) 
            {
                int fieldUnlocks;
                results.FieldNameToNum("player_unlocks", fieldUnlocks);

                unlocks = results.FetchInt(fieldUnlocks);
                LogMessage("[ GUM ] Player %N loaded with unlocks: %d", client, unlocks);
            }
        } else {
            // TODO something
        }
        setPlayerUnlocks(client, unlocks);
    } 
    else
    {
        LogError( "%s", error ); 
        
        return;
    }
}
public void queryShowTopTableCallback(Database db, DBResultSet results, const char[] error, any client)
{ 
    if ( db != null )
    {
        if ( !UTIL_IsValidClient(client) )
            return;
        
        char name[64], szInfo[128];
        int level, unlocks;

        Menu panel = new Menu(top10PanelHandler);
        panel.SetTitle( "Top 10 Players" );

        while ( results.FetchRow() )
        {
            int fieldName, fieldLevel, fieldUnlocks;
            results.FieldNameToNum("player_name", fieldName);
            results.FieldNameToNum("player_level", fieldLevel);
            results.FieldNameToNum("player_unlocks", fieldUnlocks);
            
            results.FetchString( fieldName, name, sizeof(name) );
            level = results.FetchInt(fieldLevel);
            unlocks = results.FetchInt(fieldUnlocks);
            
            ReplaceString(name, sizeof(name), "&lt;", "<");
            ReplaceString(name, sizeof(name), "&gt;", ">");
            ReplaceString(name, sizeof(name), "&#37;", "%");
            ReplaceString(name, sizeof(name), "&#61;", "=");
            ReplaceString(name, sizeof(name), "&#42;", "*");
            
            Format( szInfo, sizeof( szInfo ), "%t", "Menu option: Player format", name, level, unlocks, getMaxPlayerUnlocksByLevel(level) );

            panel.AddItem("panel_info", szInfo);
        }

        panel.ExitButton = true;
        panel.Display( client, GetConVarInt(cvarMenuTime) );
    } 
    else
    {
        LogError( "%s", error ); 
        
        return;
    }
}
public int top10PanelHandler(Menu menu, MenuAction action, int client, int item)
{
    if (action == MenuAction_End)
    {
        delete menu;
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