#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <gum>
#include <prestige>
#include <zombieswarm>
#include <colorvariables>
#include <swarm/utils>

#define PLUGIN_VERSION "1.0"
#define PLUGIN_NAME "Prestige for GunXP system"

Database conDatabase = null;

enum g_eResetSystem {
    resetThisTier,
    resetPrevTier
}

ArrayList g_aReborn;
ArrayList g_aEvolution;
ArrayList g_aNirvana;

Handle g_hForwardOnReborn;
Handle g_hForwardOnEvolution;
Handle g_hForwardOnNirvana;

int g_iReborns[MAXPLAYERS+1];
int g_iEvolutions[MAXPLAYERS+1];
int g_iNirvana[MAXPLAYERS+1];
int g_iRebornPoints[MAXPLAYERS+1];
int g_iEvolutionPoints[MAXPLAYERS+1];
int g_iNirvanaPoints[MAXPLAYERS+1];
int g_iTotalReborns[MAXPLAYERS+1];

public Plugin myinfo =
{
    name = PLUGIN_NAME,
    author = "Zombie Swarm Contributors",
    description = "Reborns and Evolutions for Gun XP system",
    version = PLUGIN_VERSION,
    url = "https://github.com/Prefix/zombieswarm"
};

public void OnPluginStart()
{
    CreateConVar("prestige_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
    // Database
    databaseInit();

    g_aReborn = new ArrayList(view_as<int>(g_eResetSystem));
    g_aEvolution = new ArrayList(view_as<int>(g_eResetSystem));
    g_aNirvana = new ArrayList(view_as<int>(g_eResetSystem));

    LoadResetConfig();

}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    // Use MethodMapName.FunctionName format
    CreateNative("PrestigePlayer.PrestigePlayer", Native_PrestigePlayer_Constructor);
    // Properties
    CreateNative("PrestigePlayer.Client.get", Native_PrestigePlayer_ClientGet);
    // LEVEL/RB/EVO/Nirvana
    CreateNative("PrestigePlayer.MaxLevel.get", Native_PrestigePlayer_MaxLevelGet);
    CreateNative("PrestigePlayer.MaxReborns.get", Native_PrestigePlayer_MaxRebornsGet);
    CreateNative("PrestigePlayer.MaxEvolutions.get", Native_PrestigePlayer_MaxEvolutionsGet);
    CreateNative("PrestigePlayer.Level.get", Native_PrestigePlayer_LevelGet);
    CreateNative("PrestigePlayer.Level.set", Native_PrestigePlayer_LevelSet);
    CreateNative("PrestigePlayer.Reborn.get", Native_PrestigePlayer_RebornGet);
    CreateNative("PrestigePlayer.Reborn.set", Native_PrestigePlayer_RebornSet);
    CreateNative("PrestigePlayer.Evolution.get", Native_PrestigePlayer_EvolutionGet);
    CreateNative("PrestigePlayer.Evolution.set", Native_PrestigePlayer_EvolutionSet);
    CreateNative("PrestigePlayer.Nirvana.get", Native_PrestigePlayer_NirvanaGet);
    CreateNative("PrestigePlayer.Nirvana.set", Native_PrestigePlayer_NirvanaSet);
    // Points
    CreateNative("PrestigePlayer.RebornPoints.get", Native_PrestigePlayer_RBPointsGet);
    CreateNative("PrestigePlayer.RebornPoints.set", Native_PrestigePlayer_RBPointsSet);
    CreateNative("PrestigePlayer.EvolutionPoints.get", Native_PrestigePlayer_EvoPointsGet);
    CreateNative("PrestigePlayer.EvolutionPoints.set", Native_PrestigePlayer_EvoPointsSet);
    CreateNative("PrestigePlayer.NirvanaPoints.get", Native_PrestigePlayer_NirvanaPointsGet);
    CreateNative("PrestigePlayer.NirvanaPoints.set", Native_PrestigePlayer_NirvanaPointsSet);
    // Total
    CreateNative("PrestigePlayer.TotalReborns.get", Native_PrestigePlayer_TotalReborns);
    // Other
    CreateNative("PrestigePlayer.DoesMeetRequirements", Native_PrestigePlayer_Requirements);
    
    // Register mod library
    RegPluginLibrary("prestige");

    g_hForwardOnReborn = CreateGlobalForward("Prestige_OnReborn", ET_Ignore, Param_Cell);
    g_hForwardOnEvolution = CreateGlobalForward("Prestige_OnEvolution", ET_Ignore, Param_Cell);
    g_hForwardOnNirvana = CreateGlobalForward("Prestige_OnNirvana", ET_Ignore, Param_Cell);

    return APLRes_Success;
}

public void GUM_OnLevelUp(int client) {
    if (!UTIL_IsValidClient(client))
        return;

    bool made = false;
    if (CanReborn(client)) {
        MakeReborn(client);
        made = true;
    }
    if (CanEvolution(client)) {
        MakeEvolution(client);
        made = true;
    }
    if (CanNirvana(client)) {
        MakeNirvana(client);
        made = true;
    }
    if (made) {
        SaveClientData(client); 
    }
}

public void MakeReborn(int client) {
    if (!UTIL_IsValidClient(client))
        return;
    if (CanReborn(client)) {
        GUM_SetPlayerUnlocks(client, 0);
        g_iReborns[client] += 1;
        g_iRebornPoints[client] += 1;
        g_iTotalReborns[client] += 1;
        Call_StartForward(g_hForwardOnReborn);
        Call_PushCell(client);
        Call_Finish();
        CPrintToChat(client, "[ Reborn ] You have reborn! Your current reborns {green}%d{default}!", g_iReborns[client]);
    }
}

public void MakeEvolution(int client) {
    if (!UTIL_IsValidClient(client))
        return;
    if (CanEvolution(client)) {
        g_iReborns[client] = 0;
        g_iEvolutions[client] += 1;
        g_iEvolutionPoints[client] += 1;
        Call_StartForward(g_hForwardOnEvolution);
        Call_PushCell(client);
        Call_Finish();
        CPrintToChat(client, "[ Evolution ] You have reached evolution! Your current evolutions {green}%d{default}!", g_iEvolutions[client]);
    }
}

public void MakeNirvana(int client) {
    if (!UTIL_IsValidClient(client))
        return;
    if (CanEvolution(client)) {
        g_iEvolutions[client] = 0;
        g_iNirvana[client] += 1;
        g_iNirvanaPoints[client] += 1;
        Call_StartForward(g_hForwardOnNirvana);
        Call_PushCell(client);
        Call_Finish();
        CPrintToChat(client, "[ Nirvana ] You have reached Nirvana! Your current nirvanas {green}%d{default}!", g_iNirvana[client]);
    }
}

public void databaseInit()
{
    Database.Connect(databaseConnectionCallback);
}


public void OnClientPutInServer(int client)
{
    if ( UTIL_IsValidClient(client) && !IsFakeClient(client) )
    {
        loadData(client);
    }
}

public void OnClientDisconnect(int client)
{
    if ( IsClientInGame(client) )
    {
        if (!IsFakeClient(client)) {
            SaveClientData(client);
        }
    }
}

stock bool CanReborn(int client) {
    int level = GUM_GetPlayerLevel(client);
    int index = 0;
    for (int i = 0; i < g_aReborn.Length; i++)
    {
        int lookup_tier = g_aReborn.Get(i, resetThisTier);
        if (g_iReborns[client] < lookup_tier)
            break;
        index = i;
    }
    int lookup_prev_tier = g_aReborn.Get(index, resetPrevTier);
    return level >= lookup_prev_tier ? true : false;
}

stock bool CanEvolution(int client) {
    int level = g_iReborns[client];
    int index = 0;
    for (int i = 0; i < g_aEvolution.Length; i++)
    {
        int lookup_tier = g_aEvolution.Get(i, resetThisTier);
        if (g_iEvolutions[client] < lookup_tier)
            break;
        index = i;
    }
    int lookup_prev_tier = g_aEvolution.Get(index, resetPrevTier);
    return level >= lookup_prev_tier ? true : false;
}

stock bool CanNirvana(int client) {
    int level = g_iEvolutions[client];
    int index = 0;
    for (int i = 0; i < g_aNirvana.Length; i++)
    {
        int lookup_tier = g_aNirvana.Get(i, resetThisTier);
        if (g_iNirvana[client] < lookup_tier)
            break;
        index = i;
    }
    int lookup_prev_tier = g_aNirvana.Get(index, resetPrevTier);
    return level >= lookup_prev_tier ? true : false;
}

stock void LoadResetConfig() {
    char ResetPath[PLATFORM_MAX_PATH];
    KeyValues ResetKV = new KeyValues("ResetSystem");
    BuildPath(Path_SM, ResetPath, sizeof(ResetPath), "configs/prestige/reset_system.cfg");
    
    if (!ResetKV.ImportFromFile(ResetPath)) {
        LogError("Couldn't import: \"%s\"", ResetPath);
        return;
    }

    if (!ResetKV.GotoFirstSubKey()) {
        LogError("No configs in: \"%s\"", ResetPath);
        return;
    }
    char sectionname[PLATFORM_MAX_PATH];
    do
    {
        ResetKV.GetSectionName(sectionname, sizeof(sectionname));
        char newkey[32];
        Format(newkey, sizeof(newkey), "%s-%i", sectionname, 0);
        ResetKV.JumpToKey(newkey, false);
        do
        {
            if (StrEqual(sectionname, "reborn")) {
                int minrb = ResetKV.GetNum("minimum_reborn", -1);
                int reqlvl = ResetKV.GetNum("required_level", -1);
                if (minrb == -1 || reqlvl == -1) {
                    LogMessage("Misconfigurated field found in [reborn] prestige/reset_system.cfg");
                } else {
                    int temp_push[g_eResetSystem];
                    temp_push[resetThisTier] = minrb;
                    temp_push[resetPrevTier] = reqlvl;
                    g_aReborn.PushArray(temp_push[0]);
                }
                
            } else if (StrEqual(sectionname, "evolution")) {
                int minevo = ResetKV.GetNum("minimum_evolution", -1);
                int reqrb = ResetKV.GetNum("required_reborn", -1);
                if (reqrb == -1 || minevo == -1) {
                    LogMessage("Misconfigurated field found in [evolution] prestige/reset_system.cfg");
                } else {
                    int temp_push[g_eResetSystem];
                    temp_push[resetThisTier] = minevo;
                    temp_push[resetPrevTier] = reqrb;
                    g_aEvolution.PushArray(temp_push[0]);
                }
            } else if (StrEqual(sectionname, "nirvana")) {
                int minnirvana = ResetKV.GetNum("minimum_nirvana", -1);
                int reqevo = ResetKV.GetNum("required_evolution", -1);
                if (minnirvana == -1 || reqevo == -1) {
                    LogMessage("Misconfigurated field found in [nirvana] prestige/reset_system.cfg");
                } else {
                    int temp_push[g_eResetSystem];
                    temp_push[resetThisTier] = minnirvana;
                    temp_push[resetPrevTier] = reqevo;
                    g_aNirvana.PushArray(temp_push[0]);
                }
            }
        } while (ResetKV.GotoNextKey());
        ResetKV.GoBack();
    } while (ResetKV.GotoNextKey());

    delete ResetKV;
}

public void SaveClientData(int client) {
    if ( IsClientInGame(client) )
    {
        if (!IsFakeClient(client)) {
            char sQuery[512];
            char szKey[64], oName[32], pName[80];
            GetClientAuthId( client, AuthId_SteamID64, szKey, sizeof(szKey) );
            
            GetClientName(client, oName, sizeof(oName));
            conDatabase.Escape(oName, pName, sizeof(pName));
        
            Format( sQuery, sizeof( sQuery ), "SELECT `player_reborns` FROM `prestige_players` WHERE ( `player_id` = '%s' )", szKey);
            
            DataPack dp = new DataPack();
            
            dp.WriteString(szKey);
            dp.WriteString(pName);
            dp.WriteCell(g_iReborns[client]);
            dp.WriteCell(g_iEvolutions[client]);
            dp.WriteCell(g_iNirvana[client]);
            dp.WriteCell(g_iRebornPoints[client]);
            dp.WriteCell(g_iEvolutionPoints[client]);
            dp.WriteCell(g_iNirvanaPoints[client]);
            dp.WriteCell(g_iTotalReborns[client]);
            
            conDatabase.Query( querySelectSavedDataCallback, sQuery, dp);
            /*g_iReborns[client] = 0; 
            g_iEvolutions[client] = 0; 
            g_iNirvana[client] = 0; 
            g_iRebornPoints[client] = 0; 
            g_iEvolutionPoints[client] = 0; 
            g_iNirvanaPoints[client] = 0; 
            g_iTotalReborns[client] = 0; */
        }
    }
}

public void querySelectSavedDataCallback(Database db, DBResultSet results, const char[] error, DataPack pack)
{ 
    if ( db != null )
    {
        int resultRows = results.RowCount;
        
        char sKey[64], pName[32];
        
        pack.Reset();
        pack.ReadString(sKey, sizeof(sKey));
        pack.ReadString(pName, sizeof(pName));
        int reborns = pack.ReadCell();
        int evolutions = pack.ReadCell();
        int nirvana = pack.ReadCell();
        int rbpoints = pack.ReadCell();
        int evopoints = pack.ReadCell();
        int nirvanapoints = pack.ReadCell();
        int totalreborns = pack.ReadCell();

        char sQuery[512];
        
        int bufferLength = strlen(pName) * 2 + 1;
        char[] newPlayerName = new char[bufferLength];
        conDatabase.Escape(pName, newPlayerName, bufferLength);
        
        if (resultRows > 0)
            Format( sQuery, sizeof( sQuery ), "UPDATE `prestige_players` SET `player_name`='%s',`player_reborns`=%i,`player_evolutions`=%i,`player_nirvana`=%i,`player_reborn_points`=%i,`player_evolution_points`=%i,`player_nirvana_points`=%i,`player_total_reborns`=%i WHERE `player_id`= '%s'", newPlayerName, reborns, evolutions, nirvana, rbpoints, evopoints, nirvanapoints, totalreborns, sKey );
        else
            Format( sQuery, sizeof( sQuery ), "INSERT INTO `prestige_players`(`player_id`, `player_name`, `player_reborns`, `player_evolutions`, `player_nirvana`, `player_reborn_points`, `player_evolution_points`, `player_nirvana_points`, `player_total_reborns`) VALUES ('%s', '%s', %i, %i, %i, %i, %i, %i, %i);", sKey, newPlayerName, reborns, evolutions, nirvana, rbpoints, evopoints, nirvanapoints, totalreborns );
        conDatabase.Query( querySetDataCallback, sQuery);
    } 
    else
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

public void loadData(int client)
{
    char sQuery[ 256 ]; 
    
    char szKey[64];
    GetClientAuthId( client, AuthId_SteamID64, szKey, sizeof(szKey) );

    Format( sQuery, sizeof( sQuery ), "SELECT * FROM `prestige_players` WHERE ( `player_id` = '%s' );", szKey );
    
    conDatabase.Query( querySelectDataCallback, sQuery, client);
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
        int reborns = 0;
        int evolutions = 0;
        int nirvana = 0;
        int reborn_points = 0;
        int evolution_points = 0;
        int nirvana_points = 0;
        int total_reborns = 0;
        if (results.HasResults) {
            while ( results.FetchRow() ) 
            {
                int fieldReborns;
                results.FieldNameToNum("player_reborns", fieldReborns);
                reborns = results.FetchInt(fieldReborns);
                int fieldEvolutions;
                results.FieldNameToNum("player_evolutions", fieldEvolutions);
                evolutions = results.FetchInt(fieldEvolutions);
                int fieldNirvana;
                results.FieldNameToNum("player_nirvana", fieldNirvana);
                nirvana = results.FetchInt(fieldNirvana);
                int fieldRebornPoints;
                results.FieldNameToNum("player_reborn_points", fieldRebornPoints);
                reborn_points = results.FetchInt(fieldRebornPoints);
                int fieldEvolutionPoints;
                results.FieldNameToNum("player_evolution_points", fieldEvolutionPoints);
                evolution_points = results.FetchInt(fieldEvolutionPoints);
                int fieldNirvanaPoints;
                results.FieldNameToNum("player_nirvana_points", fieldNirvanaPoints);
                nirvana_points = results.FetchInt(fieldNirvanaPoints);
                int fieldTotalReborns;
                results.FieldNameToNum("player_total_reborns", fieldTotalReborns);
                total_reborns = results.FetchInt(fieldTotalReborns);
            }
        }
        LoadPrestigeProfile(client, reborns, evolutions, nirvana, reborn_points, evolution_points, nirvana_points, total_reborns);
    } 
    else
    {
        LogError( "%s", error ); 
        
        return;
    }
}

public void LoadPrestigeProfile(int client, int reborns, int evolutions, int nirvana, int reborn_points, int evolution_points, int nirvana_points, int total_reborns) {
    g_iReborns[client] = reborns;
    g_iEvolutions[client] = evolutions;
    g_iNirvana[client] = nirvana;
    g_iRebornPoints[client] = reborn_points;
    g_iEvolutionPoints[client] = evolution_points;
    g_iNirvanaPoints[client] = nirvana_points;
    g_iTotalReborns[client] = total_reborns;
    LogMessage("[ Prestige ] Player %N loaded with Reborns: %i Evolutions: %i Nirvanas: %i", client, reborns, evolutions, nirvana);
    // TODO forward on loaded profile
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
        Format( sQuery, sizeof( sQuery ), "CREATE TABLE IF NOT EXISTS `prestige_players` ( `id` int NOT NULL AUTO_INCREMENT, \
        `player_id` varchar(64) NOT NULL, \
        `player_name` varchar(64) default NULL, \
        `player_reborns` int default 0, \
        `player_evolutions` int default 0, \
        `player_nirvana` int default 0, \
        `player_reborn_points` int default 0, \
        `player_evolution_points` int default 0, \
        `player_nirvana_points` int default 0, \
        `player_total_reborns` int default 0, \
        PRIMARY KEY (`id`), UNIQUE KEY `player_id` (`player_id`) ) ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4;" );
    }
    else
    {
        Format( sQuery, sizeof( sQuery ), "CREATE TABLE IF NOT EXISTS `prestige_players` ( `id` INTEGER PRIMARY KEY AUTOINCREMENT, \
        `player_id` TEXT NOT NULL UNIQUE, \
        `player_name` TEXT DEFAULT NULL, \
        `player_reborns` INTEGER DEFAULT 0, \
        `player_evolutions` INTEGER DEFAULT 0, \
        `player_nirvana` INTEGER DEFAULT 0, \
        `player_reborn_points` INTEGER DEFAULT 0, \
        `player_evolutions_points` INTEGER DEFAULT 0, \
        `player_nirvana_points` INTEGER DEFAULT 0, \
        `player_total_reborns` INTEGER DEFAULT 0 \
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

public int Native_PrestigePlayer_Constructor(Handle plugin, int numParams)
{
    int client = view_as<int>(GetNativeCell(1));
    if ( UTIL_IsValidClient( client ) ) {
        return view_as< int >( GetClientUserId( client ) );
    }
    return view_as< int >(-1);
}

public int Native_PrestigePlayer_ClientGet(Handle plugin, int numParams) 
{
    PrestigePlayer player = GetNativeCell(1);
    return GetClientOfUserId( view_as<int>(player) );
}

public int Native_PrestigePlayer_MaxLevelGet(Handle plugin, int numParams)
{
    PrestigePlayer player = GetNativeCell(1);
    int client = player.Client;
    int index = 0;
    for (int i = 0; i < g_aReborn.Length; i++)
    {
        int lookup_tier = g_aReborn.Get(i, resetThisTier);
        if (g_iReborns[client] < lookup_tier) 
            break;
        index = i;
    }
    int lookup_prev_tier = g_aReborn.Get(index, resetPrevTier);
    return lookup_prev_tier;
}

public int Native_PrestigePlayer_MaxRebornsGet(Handle plugin, int numParams)
{
    PrestigePlayer player = GetNativeCell(1);
    int client = player.Client;
    int index = 0;
    for (int i = 0; i < g_aEvolution.Length; i++)
    {
        int lookup_tier = g_aEvolution.Get(i, resetThisTier);
        if (g_iEvolutions[client] < lookup_tier) 
            break;
        index = i;
    }
    int lookup_prev_tier = g_aEvolution.Get(index, resetPrevTier);
    return lookup_prev_tier;
}

public int Native_PrestigePlayer_MaxEvolutionsGet(Handle plugin, int numParams)
{
    PrestigePlayer player = GetNativeCell(1);
    int client = player.Client;
    int index = 0;
    for (int i = 0; i < g_aNirvana.Length; i++)
    {
        int lookup_tier = g_aNirvana.Get(i, resetThisTier);
        if (g_iNirvana[client] < lookup_tier)
            break;
        index = i;
    }
    int lookup_prev_tier = g_aNirvana.Get(index, resetPrevTier);
    return lookup_prev_tier;
}


public int Native_PrestigePlayer_LevelGet(Handle plugin, int numParams)
{
    PrestigePlayer player = GetNativeCell(1);
    return GUM_GetPlayerLevel(player.Client);
}

public int Native_PrestigePlayer_LevelSet(Handle plugin, int numParams)
{
    PrestigePlayer player = GetNativeCell(1);
    GUM_SetPlayerLevel( player.Client, GetNativeCell(2));
}

public int Native_PrestigePlayer_RebornGet(Handle plugin, int numParams)
{
    PrestigePlayer player = GetNativeCell(1);
    return g_iReborns[player.Client];
}

public int Native_PrestigePlayer_RebornSet(Handle plugin, int numParams)
{
    PrestigePlayer player = GetNativeCell(1);
    int client = player.Client;
    g_iReborns[client] = GetNativeCell(2);
    bool made = false;
    if (CanEvolution(client)) {
        MakeEvolution(client);
        made = true;
    }
    if (CanNirvana(client)) {
        MakeNirvana(client);
        made = true;
    }
    if (made) {
        SaveClientData(client); 
    }
}

public int Native_PrestigePlayer_EvolutionGet(Handle plugin, int numParams)
{
    PrestigePlayer player = GetNativeCell(1);
    return g_iEvolutions[player.Client];
}

public int Native_PrestigePlayer_EvolutionSet(Handle plugin, int numParams)
{
    PrestigePlayer player = GetNativeCell(1);
    int client = player.Client;
    g_iEvolutions[client] = GetNativeCell(2);
    bool made = false;
    if (CanNirvana(client)) {
        MakeNirvana(client);
        made = true;
    }
    if (made) {
        SaveClientData(client); 
    }
}

public int Native_PrestigePlayer_NirvanaGet(Handle plugin, int numParams)
{
    PrestigePlayer player = GetNativeCell(1);
    return g_iNirvana[player.Client];
}

public int Native_PrestigePlayer_NirvanaSet(Handle plugin, int numParams)
{
    PrestigePlayer player = GetNativeCell(1);
    g_iNirvana[player.Client] = GetNativeCell(2);
    SaveClientData(player.Client); 
    CPrintToChat(player.Client, "[ Nirvana ] You have reached Nirvana! Your current nirvanas {green}%d{default}!", g_iNirvana[player.Client]);
}

public int Native_PrestigePlayer_RBPointsGet(Handle plugin, int numParams)
{
    PrestigePlayer player = GetNativeCell(1);
    return g_iRebornPoints[player.Client];
}

public int Native_PrestigePlayer_RBPointsSet(Handle plugin, int numParams)
{
    PrestigePlayer player = GetNativeCell(1);
    g_iRebornPoints[player.Client] = GetNativeCell(2);
    SaveClientData(player.Client); 
}

public int Native_PrestigePlayer_EvoPointsGet(Handle plugin, int numParams)
{
    PrestigePlayer player = GetNativeCell(1);
    return g_iEvolutionPoints[player.Client];
}

public int Native_PrestigePlayer_EvoPointsSet(Handle plugin, int numParams)
{
    PrestigePlayer player = GetNativeCell(1);
    g_iEvolutionPoints[player.Client] = GetNativeCell(2);
    SaveClientData(player.Client); 
}

public int Native_PrestigePlayer_NirvanaPointsGet(Handle plugin, int numParams)
{
    PrestigePlayer player = GetNativeCell(1);
    return g_iNirvanaPoints[player.Client];
}

public int Native_PrestigePlayer_NirvanaPointsSet(Handle plugin, int numParams)
{
    PrestigePlayer player = GetNativeCell(1);
    g_iNirvanaPoints[player.Client] = GetNativeCell(2);
    SaveClientData(player.Client); 
}

public int Native_PrestigePlayer_TotalReborns(Handle plugin, int numParams)
{
    PrestigePlayer player = GetNativeCell(1);
    return g_iNirvanaPoints[player.Client];
}

public int Native_PrestigePlayer_Requirements(Handle plugin, int numParams)
{
    PrestigePlayer player = GetNativeCell(1);
    int client = player.Client;
    int level = GetNativeCell(2);
    int rb = GetNativeCell(3);
    int evo = GetNativeCell(4);
    int nirvana = GetNativeCell(5);
    return (level <= GUM_GetPlayerLevel(client) && rb <= g_iReborns[client] && evo <= g_iEvolutions[client] && nirvana <= g_iNirvana[client]);
}