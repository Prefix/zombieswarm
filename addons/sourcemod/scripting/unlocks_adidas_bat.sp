#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <swarm/utils>
#include <zombieswarm>
#include <fpvm_interface>
#include <gum_shop>

public Plugin myinfo =
{
	name        	= "[GUM] Unlocks: Adidas Baseball Bat",
	author      	= "Prefix", 	
	description 	= "",
	version     	= "1.0",
	url         	= "https://rampage.lt"
}

#define WEAPON_NAME					"adidasbat"
#define WEAPON_REFERANCE			"weapon_knife"

#define MODEL_WORLD 				"models/weapons/eminem/adidas_baseball_bat/w_adidas_baseball_bat.mdl"
#define MODEL_VIEW					"models/weapons/eminem/adidas_baseball_bat/v_adidas_baseball_bat.mdl"

#define PUMP_FORCE 25.0
#define AirMultiplier 0.9
#define KnockBack 25.0

// Weapon model indexes
int iViewModel;
int iWorldModel;

GumItem adidas_bat;
bool itemEnabled_knocback_adidas[MAXPLAYERS + 1];
bool itemOwned_knocback_adidas[MAXPLAYERS + 1];
/**
 * Plugin is loading.
 **/
public void GUMShop_OnLoaded() 
{
	adidas_bat = GumItem(
		"adidas_bat",
		"weapon_knives",
		"[Knockback] Adidas Bat",
		"Gives knockback when used on zombie."
	);
	adidas_bat.LevelRequired = 1;
	adidas_bat.XPCost = 1;
	adidas_bat.RebuyTimes = itemBuyOnceMap;
	adidas_bat.Keep = itemKeepAlways;
	adidas_bat.RebuyTimes = GUM_NO_REBUY_MAP;
	HookEvent("player_hurt", eventPlayerHurt);
	HookEvent("player_spawn", eventPlayerSpawn);
}

public void GUMShop_OnPlayerRemoveItem(int client, int item)
{
	if (!UTIL_IsValidClient(client))
	return;
	if (item == adidas_bat.ID) {
		itemEnabled_knocback_adidas[client] = false;
		itemOwned_knocback_adidas[client] = false;
		FPVMI_RemoveViewModelToClient(client, WEAPON_REFERANCE);
		FPVMI_RemoveWorldModelToClient(client, WEAPON_REFERANCE);
		FPVMI_RemoveDropModelToClient(client, WEAPON_REFERANCE);
		if (IsPlayerAlive(client)){
			GiveWeapon(client);
		}
	}
}

public Action GUMShop_OnBuyItem(int client, int item) {
    if (item == adidas_bat.ID) {
		itemEnabled_knocback_adidas[client] = true;
		itemOwned_knocback_adidas[client] = true;
		FPVMI_AddViewModelToClient(client, WEAPON_REFERANCE, iViewModel);
		FPVMI_AddWorldModelToClient(client, WEAPON_REFERANCE, iWorldModel);
		FPVMI_AddDropModelToClient(client, WEAPON_REFERANCE, MODEL_WORLD);
		GiveWeapon(client);
		return Plugin_Handled;
    }
    return Plugin_Continue;
}

public Action GUMShop_OnPreBuyItem(int client, int item) {
    if (item == adidas_bat.ID && ZS_IsClientZombie(client)) {
        return Plugin_Stop;
    }
    return Plugin_Continue;
}

public void eventPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	if ( !UTIL_IsValidAlive(client) )
		return;
	if (!itemOwned_knocback_adidas[client])
		return;
	int team = GetClientTeam(client);
	if (team == CS_TEAM_CT)
	{
		itemEnabled_knocback_adidas[client] = true;
		FPVMI_AddViewModelToClient(client, WEAPON_REFERANCE, iViewModel);
		FPVMI_AddWorldModelToClient(client, WEAPON_REFERANCE, iWorldModel);
		FPVMI_AddDropModelToClient(client, WEAPON_REFERANCE, MODEL_WORLD);
	} 
	if (team == CS_TEAM_T)
	{
		itemEnabled_knocback_adidas[client] = false;
		FPVMI_RemoveViewModelToClient(client, WEAPON_REFERANCE);
		FPVMI_RemoveWorldModelToClient(client, WEAPON_REFERANCE);
		FPVMI_RemoveDropModelToClient(client, WEAPON_REFERANCE);
		if (IsPlayerAlive(client)){
			GiveWeapon(client);
		}
	} 

}
// Take the item/unlock from the player
public void OnClientDisconnect(int client)
{
	if ( UTIL_IsValidClient(client) )
	{
		itemEnabled_knocback_adidas[client] = false;
		itemOwned_knocback_adidas[client] = false;
	}
}

public void GiveWeapon(int client) {
	if(!UTIL_IsValidClient(client)) return;
	if(!IsPlayerAlive(client)) return;
	if(GetClientTeam(client) != CS_TEAM_CT) return;
	if(!itemOwned_knocback_adidas[client]) return;
	// Get weapon index from slot
	int weaponIndex = GetPlayerWeaponSlot(client, CS_SLOT_KNIFE);

	// If weapon is invalid, then drop
	if (IsValidEdict(weaponIndex))
	{
		// Get the owner of the weapon
		int ownerIndex = GetEntPropEnt(weaponIndex, Prop_Send, "m_hOwnerEntity");

		// If owner index is different, so set it again
		if (ownerIndex != client) 
		{
			SetEntPropEnt(weaponIndex, Prop_Send, "m_hOwnerEntity", client);
		}
		char sName[32];
		GetEdictClassname(weaponIndex, sName, sizeof(sName));
		// Forces a player to drop weapon
		if ((StrContains(sName, "knife", false) != -1) || (StrContains(sName, "bayonet", false) != -1))
		{
			SDKHooks_DropWeapon(client, weaponIndex);
		}
	}

	// Give item
	GivePlayerItem(client, WEAPON_REFERANCE);
	FakeClientCommandEx(client, "use %s", WEAPON_REFERANCE);
}


/**
 * The map is starting.
 **/
public void OnMapStart(/*void*/)
{
	// Precache models and their parts
	iWorldModel = FakePrecacheModel(MODEL_WORLD);
	iViewModel  = FakePrecacheModel(MODEL_VIEW);
}

/**
 * Precache models and also adding them into the downloading table.
 * 
 * @param modelPath			The model path.
 *
 * @return					The model index.
 **/
stock int FakePrecacheModel(const char[] modelPath)
{
	// Precache main model
	int modelIndex = PrecacheModel(modelPath);
	
	// Adding main model to the download list
	AddFileToDownloadsTable(modelPath);

	// Initialize path char
	char fullPath[PLATFORM_MAX_PATH];
	char typePath[4][64] = { ".dx90", ".phy", ".vvd", ".dx90.vtx" };
	
	// Get number of the all types
	int iSize = sizeof(typePath);
	
	// i = type index
	for(int i = 0; i < iSize; i++)
	{
		// Adding other parts to download list
		Format(fullPath, sizeof(fullPath), "%s", modelPath);
		ReplaceString(fullPath, sizeof(fullPath), ".mdl", typePath[i]);
		if(FileExists(fullPath)) {
			AddFileToDownloadsTable(fullPath);
		} else {
			LogMessage("%s does not exist", fullPath);
		}
	}
	
	// Return model index
	return modelIndex;
}
public void eventPlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(GetEventInt(event, "userid"));
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if (victim == attacker)
		return;

	if (!UTIL_IsValidAlive(attacker))
		return;
		
	if (!UTIL_IsValidAlive(victim))
		return;
		
	if (GetClientTeam(victim) == GetClientTeam(attacker))
		return;
		
	if (!itemEnabled_knocback_adidas[attacker])
		return;
	
	char weaponName[16];
	int weapon = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
	if(!IsValidEdict(weapon))
	{
		return;
	}

	GetEdictClassname(weapon, weaponName, sizeof(weaponName));
	if (StrContains(weaponName, "knife", false) == -1)
		return;
	float cVelocity[3];

	float eyePosition[3];
	GetClientEyeAngles(attacker, eyePosition);

	UTIL_VelocityByAim(attacker, 600.0, cVelocity);

	if ( eyePosition[0] > 15.0 ) {
		cVelocity[2] = 20.0;
	}
	else {
		float countedVelocity = (eyePosition[0] > -30.0 ? (FloatAbs(eyePosition[0]) + 350.0) : (FloatAbs(eyePosition[0]) * 10.0 + 100.0));
		cVelocity[2] = FloatAbs( countedVelocity );
	}

	TeleportEntity( victim, NULL_VECTOR, NULL_VECTOR, cVelocity);
}
