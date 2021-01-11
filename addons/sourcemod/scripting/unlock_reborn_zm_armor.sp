#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <gum_shop>
#include <swarm/utils>
#include <zombieswarm>

public Plugin myinfo =
{
    name = "[Gum SHOP] Reborn armor",
    author = "Prefix",
    description = "none",
    version = "1.0",
    url = "http://rampage.lt"
};

#define ITEM_COST 5

GumItem reborn_armor_1;
#define UNIQUE_NAME "reborn_armor_1"

bool itemEnabled_reborn_armor_1[MAXPLAYERS + 1];

public void GUMShop_OnLoaded() {
	reborn_armor_1 = GumItem(
		UNIQUE_NAME,
		"category_grenadepacks",
		"Grenades pack",
		"Variuos grenades to detonate zombies."
	);
	reborn_armor_1.LevelRequired = 1;
	reborn_armor_1.XPCost = 15;
	reborn_armor_1.RebuyTimes = itemRebuy;
	reborn_armor_1.Keep = itemKeepRound;
	reborn_armor_1.RebuyTimes = 3;
	HookEvent("player_spawn", eventPlayerSpawn);
}

public eventPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	if ( !UTIL_IsValidAlive(client) )
		return;
		
	if ( !itemEnabled_reborn_armor_1[client] )
		return;

	if (GetClientTeam(client) == CS_TEAM_CT)
		return;
		
	CreateTimer(3.0, TGiveGrenades, client);

	//GivePlayerItem(client, "weapon_molotov");
}

public Action TGiveGrenades(Handle timer, any client)
{
	if ( !UTIL_IsValidAlive(client) )
		return Plugin_Stop;
		
	if ( !itemEnabled_reborn_armor_1[client] )
		return Plugin_Stop;

	if (GetClientTeam(client) == CS_TEAM_T)
		return Plugin_Stop;

	GivePlayerItem(client, "weapon_hegrenade");
	GivePlayerItem(client, "weapon_flashbang");
	GivePlayerItem(client, "weapon_smokegrenade");
	return Plugin_Continue;
}

public void GUMShop_OnPlayerRemoveItem(int client, int item)
{
    if (!UTIL_IsValidClient(client))
        return;
    if (item == reborn_armor_1.ID) {
        itemEnabled_reborn_armor_1[client] = false;
    }
}

public Action GUMShop_OnBuyItem(int client, int item) {
	if (item == reborn_armor_1.ID) {
		itemEnabled_reborn_armor_1[client] = true;
		CreateTimer(0.1, TGiveGrenades, client);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action GUMShop_OnPreBuyItem(int client, int item) {
    if (item == reborn_armor_1.ID && ZS_IsClientZombie(client)) {
        return Plugin_Stop;
    }
    return Plugin_Continue;
}

// Take the item/unlock from the player
public void OnClientDisconnect(int client)
{
    if ( UTIL_IsValidClient(client) )
    {
        itemEnabled_reborn_armor_1[client] = false;
    }
}