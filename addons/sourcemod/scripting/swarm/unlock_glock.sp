#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <gum>
#include <swarm/utils>

public Plugin myinfo =
{
    name = "Glock damage booster",
    author = "Zombie Swarm Contributors",
    description = "none",
    version = "1.0",
    url = "https://github.com/Prefix/zombieswarm"
};

#define DamageBoost 2.0

#define ITEM_COST 20

#define GUN_UNLOCK "glock"

bool itemEnabled[MAXPLAYERS + 1];

public void OnPluginStart()
{
    // We are registering item here with parameters
    // itemRebuy - 0 = Item can be bought one time per connect, 1 = Buy item many times, 2 = Item can be bought one time per round
    // itemRebuyTimes - 0 = Infinite buy, >0 = Item rebuy times
    registerGumItem("Glock 2x damage", "Glock does 2x damage", ITEM_COST, 0, 0);
}

// Called when item/unlock was selected by menu
public void gumItemSetCallback(client)
{
    itemEnabled[client] = true;
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

public OnClientPutInServer(client)
{
    if ( UTIL_IsValidClient(client) && !IsFakeClient(client) )
        SDKHook(client, SDKHook_TraceAttack, OnTraceAttack);
}

public Action OnTraceAttack(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &ammotype, int hitbox, int hitgroup)
{
    if (victim == attacker)
        return Plugin_Continue;

    if (!UTIL_IsValidAlive(attacker))
        return Plugin_Continue;
        
    if (!UTIL_IsValidClient(victim))
        return Plugin_Continue;
        
    if (GetClientTeam(victim) == GetClientTeam(attacker))
        return Plugin_Continue;
        
    if (!itemEnabled[attacker])
        return Plugin_Continue;
        
    char weaponName[16];
    
    int iWeapon = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
    if(!(iWeapon > 0 && IsValidEdict(iWeapon))) return Plugin_Continue;
    GetEdictClassname(iWeapon, weaponName, sizeof(weaponName));
    
    if (StrContains(weaponName, GUN_UNLOCK) == -1)
        return Plugin_Continue;
    
    damage = damage*DamageBoost;
    return Plugin_Changed;
}
