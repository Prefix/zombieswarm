
#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <zombieswarm>

#include <swarm/utils>

// Checks if user connected, without any errors.
#define IsValidClient(%1)  ( 1 <= %1 <= MaxClients && IsClientInGame(%1) )
// Checks if user alive, without any errors.
#define IsValidAlive(%1) ( 1 <= %1 <= MaxClients && IsClientInGame(%1) && IsPlayerAlive(%1) )

ConVar cvarTBrounds;
int rounds = 1;

#define PLUGIN_NAME ZS_PLUGIN_NAME ... " - Team Balance"

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
    // ConVars
    ZS_StartConfig("zombieswarm.teambalancer");
    // How many rounds players need to play in order to switch teams > 4 players
    cvarTBrounds = CreateConVar("zm_tb_rounds", "1", "How much rounds you have to play for one side?");
    ZS_EndConfig();
    // Commands
    
    // Hooks

    // Hook On Round end to switch teams.
    HookEvent("round_end", eventRoundEnd);

    CreateConVar("zombie_mod_tb", ZS_PLUGIN_VERSION, PLUGIN_NAME, FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
}


// Private helper function to get opposite team
int GetOppositeTeam(int client, int team = 0) {
    // If team is CT or T let's get opposite team, otherwise zombie.
    if (team > 0 && team != CS_TEAM_SPECTATOR) 
        return (team == CS_TEAM_CT) ? CS_TEAM_T:CS_TEAM_CT;
    else if (team > 0 && team == CS_TEAM_SPECTATOR)
        return CS_TEAM_T;
    // In case if none of these happens
    return (GetClientTeam(client) == CS_TEAM_T) ? CS_TEAM_CT:CS_TEAM_T;
}

public void eventRoundEnd(Event event, const char[] name, bool dontBroadcast)
{
    CreateTimer(3.0, afterRoundEnded, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action afterRoundEnded(Handle timer, any data) {
    // Get amount of players (CT and T)
    int AmountOfPlayers = GetCountOfCustom(_, true);
    // Debug message
    //PrintToChatAll("Amount of players: %i ", AmountOfPlayers);
    // If less than 3 people
    if (AmountOfPlayers < 3) {
        //PrintToChatAll("Amount of players: %i < 3 : SwapTeams ", AmountOfPlayers);
        // Swap team if there are 1 or 2 players
        SwapTeam();
    } else if (AmountOfPlayers == 3 ) {
        // if there is 3 players, lets make custom requested balance, one player is random
        //PrintToChatAll("Amount of players: %i = 3 : ThreePlayersBalance ", AmountOfPlayers);
        ThreePlayersBalance();
    } else {
        // Players > 3, lets make real balance.

        // Check if teams are balanced as they are now
        if(!IsBalanced()) {
            // Let's make team balance and switch teams.
            MakeTeamBalance();
            return Plugin_Continue;
        }
        // Check if our convar reached our wanted value
        if (rounds == cvarTBrounds.IntValue) {
            // If it does let's swap teams, since they are balanced
            SwapTeam();
            rounds = 1;
        } else {
            // Let's return everyone to their teams (maybe it's infection mode in some other plugin part)
            ReturnEveryone();
            // Add +1 to rounds
            rounds++;
        }
    }
    return Plugin_Continue;
}

// Custom team balancer function to get players to the teams.
void ThreePlayersBalance() {
    // This balancer works like this, we get random player from any team and give it random team
    int player = GetRandomPlayer(_, true);
    // Lets check if random player is valid (just in case)
    if (IsValidClient(player)) {
        ZMPlayer ZPlayer = ZMPlayer(player);
        // Lets switch player to humans team
        ZPlayer.Team = CS_TEAM_CT;
        // Debug message
        //PrintToChatAll("ThreePlayersBalance: Selected Human %N", player);
    }
    // Foreach loop to bring everyone else to zombies team
    for (int client = 1; client <= MaxClients; client++) 
    {
        // Lets make some checks in order to know if player needs to be switched.
        if(!IsValidClient(client) || GetClientTeam(client) == CS_TEAM_SPECTATOR || player == client)
            continue;
        if (IsFakeClient(client) || IsClientSourceTV(client)) 
            continue;
        // Debug message
        //PrintToChatAll("ThreePlayersBalance: Selected Zombie %N", client);
        // Switch player to zombies team
        ZMPlayer ZClient = ZMPlayer(client);
        ZClient.Team = CS_TEAM_T;
    }
}

int GetCountOfCustom(bool findt = false, bool both = false) {
    int c_ct = 0;
    int c_t = 0;
    for (int client = 1; client <= MaxClients; client++) 
    {
        if(!IsValidClient(client) || GetClientTeam(client) == CS_TEAM_SPECTATOR)
            continue;
        if (IsFakeClient(client) || IsClientSourceTV(client)) 
            continue;
        ZMPlayer ZClient = ZMPlayer(client);
        int team = ZClient.Team;
        if (team == CS_TEAM_CT) 
            c_ct++;
        else if (team == CS_TEAM_T) 
            c_t++;
    }
    if (both) return c_t+c_ct;
    return (findt) ? c_t:c_ct;
}

int GetRandomPlayer(bool getCT = false, bool anyTeam = false) {
    int[] iClients = new int[MaxClients];
    int iClientsNum, i;
    
    for (i = 1; i <= MaxClients; i++) 
    { 
        if (IsValidClient(i))
        {
            int team = GetClientTeam(i);
            if (!anyTeam && getCT && team != CS_TEAM_CT)
                continue;
            if (!anyTeam && !getCT && team != CS_TEAM_T)
                continue;
            if (anyTeam && ( team == CS_TEAM_SPECTATOR || team == CS_TEAM_NONE ) )
                continue;
            iClients[iClientsNum++] = i;
        }
    }
    if (iClientsNum > 0)
    {
        return iClients[GetRandomInt(0, iClientsNum-1)]; 
    }
    
    return 0;
}

bool IsBalanced() {
    int c_ct = GetCountOfCustom();
    int c_t = GetCountOfCustom(true);
    int both = GetCountOfCustom(_, true);

    int difference = c_ct-c_t;
    if (both <= 3 ) return true;
    // If difference by 1 but there is like 3 ct and 4 t and there is nothing to be done about it.
    if (difference > -2 && difference < 2) {
        
        return false;
    }
    return false;
}

int GetPlayerDiff(bool &morect) {
    int c_ct = GetCountOfCustom();
    int c_t = GetCountOfCustom(true);

    int difference = c_ct-c_t;

    if (difference > 0 ) {
        morect = true;
        return Math_Abs(difference);
    }
    if (difference < 0) {
        morect = true;
        return Math_Abs(difference);
    }
    morect = false;
    return 0;
}

int Math_Abs(int value)
{
    return (value ^ (value >> 31)) - (value >> 31);
}

void MakeTeamBalance() 
{
    //PrintToChatAll("MakeTeamBalance");
    // Swap teams
    SwapTeam();
    // Lets get difference 
    bool morect = false;
    int diff = GetPlayerDiff(morect);
    if (diff <= 1) 
        return;
    diff--;
    // Lets make list of people 
    for (int players = 1; players <= diff; players++) 
    {
        int player = GetRandomPlayer(morect);
        if(!IsValidClient(player))
            continue;
        if (IsFakeClient(player) || IsClientSourceTV(player)) 
            continue;

        int team;
        ZMPlayer ZClient = ZMPlayer(player);
        if (morect) 
            team = CS_TEAM_T;
        else 
            team = CS_TEAM_CT;

        
        ZClient.Team = team;
    }
}

void SwapTeam()
{
    for (int client = 1; client <= MaxClients; client++) 
    {
        if(!IsValidClient(client) || GetClientTeam(client) == CS_TEAM_SPECTATOR)
            continue;
        // Getting player team.
        ZMPlayer ZClient = ZMPlayer(client);
        int team = ZClient.Team;
        if (team == CS_TEAM_CT || team == CS_TEAM_T) {
            int rteam = GetOppositeTeam(client, team);
            ZClient.Team = rteam;
        } else {
            if(GetCountOfCustom() > GetCountOfCustom(true)) {
                ZClient.Team = CS_TEAM_T;
            } else {
                ZClient.Team =  CS_TEAM_CT;
            }
        }
    }
}

void ReturnEveryone()
{
    for (int client = 1; client <= MaxClients; client++) 
    {
        if(!IsValidClient(client) || GetClientTeam(client) == CS_TEAM_SPECTATOR)
            continue;

        ZMPlayer ZClient = ZMPlayer(client);
        int team = ZClient.Team;
        ZClient.Team = team;
    }
}