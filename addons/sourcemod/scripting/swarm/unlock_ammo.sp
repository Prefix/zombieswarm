#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <gum_shop>
#include <zombieswarm>
#include <swarm/utils>

GumItem small_ammopack;
GumItem medium_ammopack;
GumItem large_ammopack;

public Plugin myinfo =
{
    name = "[GUM Shop] Additional ammo",
    author = "Zombie Swarm Contributors",
    description = "Gives human additional ammo",
    version = "1.0",
    url = "https://github.com/Prefix/zombieswarm"
};

public void GUMShop_OnLoaded() {
    small_ammopack = GumItem(
        "small_ammopack",
        "category_ammopacks",
        "[Ammo pack] Small",
        "Gives you a small ammunition pack"
    );
    small_ammopack.LevelRequired = 1;
    small_ammopack.XPCost = 10;
    small_ammopack.RebuyTimes = itemBuyOnceRound;

    medium_ammopack = GumItem(
        "medium_ammopack",
        "category_ammopacks",
        "[Ammo pack] Medium",
        "Gives you a medium ammunition pack"
    );
    medium_ammopack.XPCost = 20;
    medium_ammopack.RebornRequired = 5;
    medium_ammopack.RebuyTimes = itemBuyOnceRound;

    large_ammopack = GumItem(
        "medium_ammopack",
        "category_ammopacks",
        "[Ammo pack] Large",
        "Gives you a medium ammunition pack"
    );
    large_ammopack.XPCost = 30;
    large_ammopack.EvolutionRequired = 1;
    large_ammopack.RebuyTimes = itemBuyOnceRound;
}

stock void setReserveAmmo(int client, int ammo)
{
    int primary = GetPlayerWeaponSlot( client, CS_SLOT_PRIMARY ); 
    int secondary = GetPlayerWeaponSlot( client, CS_SLOT_SECONDARY ); 
    
    // Set infinity ammo
    if (primary != -1)
    {
        int ammoType = GetEntProp(primary, Prop_Send, "m_iPrimaryAmmoType"); 
        SetEntProp(client, Prop_Send, "m_iAmmo", ammo, _, ammoType );
    }
    if (secondary != -1)  
    {
        int ammoType = GetEntProp(secondary, Prop_Send, "m_iPrimaryAmmoType"); 
        SetEntProp(client, Prop_Send, "m_iAmmo", ammo, _, ammoType);
    }
}