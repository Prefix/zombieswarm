#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <gum>
#include <swarm/utils>

public Plugin myinfo =
{
    name = "Grenades pack",
    author = "Zombie Swarm Contributors",
    description = "none",
    version = "1.0",
    url = "https://github.com/Prefix/zombieswarm"
};

#define ITEM_COST 5

bool itemEnabled[MAXPLAYERS + 1];

public void OnPluginStart()
{
    // We are registering item here
    // itemRebuy - 0 = Item can be bought one time per connect, 1 = Buy item many times, 2 = Item can be bought one time per round
    // itemRebuyTimes - 0 = Infinite buy, >0 = Item rebuy times
    registerGumItem("Grenades Pack", "Gives grenades pack", ITEM_COST, 0, 0);
    
    HookEvent("player_spawn", eventPlayerSpawn);
}

// Called when item/unlock was selected by menu
public void gumItemSetCallback(client)
{
    itemEnabled[client] = true;
    
    if (!UTIL_IsValidAlive(client))
        return;
    if (GetClientTeam(client) == CS_TEAM_T)
        return;
    
    GivePlayerItem(client, "weapon_hegrenade");
    GivePlayerItem(client, "weapon_flashbang");
    GivePlayerItem(client, "weapon_smokegrenade");
    //GivePlayerItem(client, "weapon_molotov");
}

// Called when item/unlock was selected by menu
public void gumItemUnSetCallback(client)
{
    itemEnabled[client] = false;
}

// Take the item/unlock from the player
public void OnClientDisconnect(client)
{
    if ( UTIL_IsValidClient(client) )
        itemEnabled[client] = false;
}

public eventPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));

    if ( !UTIL_IsValidAlive(client) )
        return;
        
    if ( !itemEnabled[client] )
        return;

    if (GetClientTeam(client) == CS_TEAM_T)
        return;
        
    CreateTimer(3.0, TGiveGrenades, client);

    //GivePlayerItem(client, "weapon_molotov");
}

public Action TGiveGrenades(Handle timer, any client)
{
    if ( !UTIL_IsValidAlive(client) )
        return Plugin_Stop;
        
    if ( !itemEnabled[client] )
        return Plugin_Stop;

    if (GetClientTeam(client) == CS_TEAM_T)
        return Plugin_Stop;

    GivePlayerItem(client, "weapon_hegrenade");
    GivePlayerItem(client, "weapon_flashbang");
    GivePlayerItem(client, "weapon_smokegrenade");
    return Plugin_Continue;
}