#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <gum_shop>
#include <zombieswarm>
#include <swarm/utils>
#include <colorvariables>

//GumItem usp_boost;
GumItem glock_boost;

bool itemEnabled_dmg_2x_glock[MAXPLAYERS + 1];
//bool itemEnabled_dmg_2x_usp[MAXPLAYERS + 1];

#define DamageBoost 2.0

public Plugin myinfo =
{
    name = "[GUM Shop] Additional ammo",
    author = "Zombie Swarm Contributors",
    description = "Gives human additional ammo",
    version = "1.0",
    url = "https://github.com/Prefix/zombieswarm"
};

public void GUMShop_OnLoaded() {
    glock_boost = GumItem(
        "glock_boost",
        "weapon_pistols",
        "[Damage boost 2x] Glock",
        "Gives 2x damage boost for Glock"
    );
    glock_boost.LevelRequired = 1;
    glock_boost.XPCost = 10;
    glock_boost.RebuyTimes = itemBuyOnceMap;
    glock_boost.Keep = itemKeepAlways;
    glock_boost.RebuyTimes = GUM_NO_REBUY_MAP;

    /*usp_boost = GumItem(
        "usp_boost",
        "weapon_pistols",
        "[Damage boost 2x] USP",
        "Gives 2x damage boost for USP"
    );
    usp_boost.XPCost = 20;
    usp_boost.RebornRequired = 5;
    usp_boost.RebuyTimes = itemRebuy;
    usp_boost.Keep = itemKeepRound;
    usp_boost.RebuyTimes = 3;*/
}
public void GUMShop_OnPlayerRemoveItem(int client, int item)
{
    if (!UTIL_IsValidClient(client))
        return;
    if (item == glock_boost.ID) {
        itemEnabled_dmg_2x_glock[client] = false;
    }
    /*if (item == usp_boost.ID) {
        itemEnabled_dmg_2x_glock[client] = false;
    }*/
}

public Action GUMShop_OnBuyItem(int client, int item) {
    if (item == glock_boost.ID) {
        itemEnabled_dmg_2x_glock[client] = true;
        return Plugin_Handled;
    }
    /*if (item == usp_boost.ID) {
        itemEnabled_dmg_2x_usp[client] = true;
        return Plugin_Handled;
    }*/
    return Plugin_Continue;
}

public Action GUMShop_OnPreBuyItem(int client, int item) {
    if (item == glock_boost.ID && ZS_IsClientZombie(client)) {
        return Plugin_Stop;
    }
    /*if (item == usp_boost.ID && ZS_IsClientZombie(client)) {
        return Plugin_Stop;
    }*/
    return Plugin_Continue;
}

// Take the item/unlock from the player
public void OnClientDisconnect(int client)
{
    if ( UTIL_IsValidClient(client) )
    {
        itemEnabled_dmg_2x_glock[client] = false;
        //itemEnabled_dmg_2x_usp[client] = false;
    }
}

public void OnClientPutInServer(int client)
{
    if ( UTIL_IsValidClient(client) )
        SDKHook(client, SDKHook_OnTakeDamage, onTakeDamage);
}

public Action onTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
    if (victim == attacker)
        return Plugin_Continue;

    if (!UTIL_IsValidAlive(attacker))
        return Plugin_Continue;
        
    if (!UTIL_IsValidClient(victim))
        return Plugin_Continue;
        
    if (GetClientTeam(victim) == GetClientTeam(attacker))
        return Plugin_Continue;
        
    //if (!itemEnabled_dmg_2x_glock[attacker] && itemEnabled_dmg_2x_usp[attacker])
    if (!itemEnabled_dmg_2x_glock[attacker])
        return Plugin_Continue;
        
    char weaponName[16];
    bool changed = false;
    int iWeapon = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
    if(!(iWeapon > 0 && IsValidEdict(iWeapon))) return Plugin_Continue;
    GetEdictClassname(iWeapon, weaponName, sizeof(weaponName));
    if (StrContains(weaponName, "glock") != -1) {
        if (itemEnabled_dmg_2x_glock[attacker]) {
            changed = true;
        }
    }/* else if (StrContains(weaponName, "usp") != -1 || StrContains(weaponName, "hkp2000") != -1) {
        if (itemEnabled_dmg_2x_usp[attacker]) {
            changed = true;
        }
    }*/
    if (changed) 
    {
        //PrintToChatAll("[DEBUG] '%N' daro dviguba UL DMG", attacker);
        damage = damage*DamageBoost;
        return Plugin_Changed;
    }
    return Plugin_Continue;
}
