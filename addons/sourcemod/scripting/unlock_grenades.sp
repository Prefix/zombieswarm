#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <gum_shop>
#include <swarm/utils>
#include <zombieswarm>

public Plugin myinfo =
{
    name = "[Unlocks] Grenades pack",
    author = "Prefix",
    description = "none",
    version = "1.0",
    url = "https://rampage.lt"
};

#define ITEM_COST 5

GumItem nadepack_1;

bool itemEnabled_nadepack_1[MAXPLAYERS + 1];

public void GUMShop_OnLoaded() {
	nadepack_1 = GumItem(
		"nadepack_1",
		"category_grenadepacks",
		"Grenades pack",
		"Variuos grenades to detonate zombies."
	);
	nadepack_1.LevelRequired = 1;
	nadepack_1.XPCost = 15;
	nadepack_1.RebuyTimes = itemBuyOnceMap;
	nadepack_1.Keep = itemKeepAlways;
	nadepack_1.RebuyTimes = GUM_NO_REBUY_MAP;
	HookEvent("player_spawn", eventPlayerSpawn);
}

public eventPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	if ( !UTIL_IsValidAlive(client) )
		return;
		
	if ( !itemEnabled_nadepack_1[client] )
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
		
	if ( !itemEnabled_nadepack_1[client] )
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
    if (item == nadepack_1.ID) {
        itemEnabled_nadepack_1[client] = false;
    }
}

public Action GUMShop_OnBuyItem(int client, int item) {
	if (item == nadepack_1.ID) {
		itemEnabled_nadepack_1[client] = true;
		CreateTimer(0.1, TGiveGrenades, client);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action GUMShop_OnPreBuyItem(int client, int item) {
    if (item == nadepack_1.ID && ZS_IsClientZombie(client)) {
        return Plugin_Stop;
    }
    return Plugin_Continue;
}

// Take the item/unlock from the player
public void OnClientDisconnect(int client)
{
    if ( UTIL_IsValidClient(client) )
    {
        itemEnabled_nadepack_1[client] = false;
    }
}