#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <gum>

public Plugin myinfo =
{
    name = "Additional ammo",
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
	registerGumItem("Ammo Pack", "Additional ammo packs", ITEM_COST, 1, 0);
}

// Called when item/unlock was selected by menu
public void gumItemSetCallback(client)
{
	itemEnabled[client] = true;
	
	if (!IsValidAlive(client))
		return;
		
	setReserveAmmo(client, 100);
}

// Called when item/unlock was selected by menu
public void gumItemUnSetCallback(client)
{
	itemEnabled[client] = false;
}

// Take the item/unlock from the player
public void OnClientDisconnect(client)
{
	if ( IsValidClient(client) )
		itemEnabled[client] = false;
}

stock void setReserveAmmo(client, ammo)
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