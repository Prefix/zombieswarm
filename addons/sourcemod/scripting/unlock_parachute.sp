#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <gum_shop>
#include <swarm/utils>
#include <zombieswarm>

public Plugin myinfo =
{
    name = "[GUM SHOP] Parachute",
    author = "Prefix",
    description = "none",
    version = "1.0",
    url = "https://rampage.lt"
};

#define ITEM_COST 20

int g_iVelocity = -1;

#define GUN_UNLOCK "parachute"
#define ParachuteModel "models/parachute/gargoyle.mdl"

bool itemEnabled[MAXPLAYERS + 1];

bool g_bParachute[MAXPLAYERS+1];
Handle g_hGiveParachuteTimer[MAXPLAYERS+1] = {null, ...};

bool g_bParachuteEnabled[MAXPLAYERS+1];
int g_iParachuteEntityRef[MAXPLAYERS+1] = {INVALID_ENT_REFERENCE, ...};

float fParachuteFallspeedMax = 50.0;
bool bParachuteAllowShooting = true;

GumItem parachute;

public void GUMShop_OnLoaded() 
{
	parachute = GumItem(
		"parachute",
		"category_generic",
		"[Utility] Parachute",
		"Let you fly as CT with E key."
	);
	parachute.LevelRequired = 1;
	parachute.XPCost = 1;
	parachute.RebuyTimes = itemBuyOnceMap;
	parachute.Keep = itemKeepAlways;
	parachute.RebuyTimes = GUM_NO_REBUY_MAP;
	g_iVelocity = FindSendPropInfo("CBasePlayer", "m_vecVelocity[0]");
}

public void OnMapStart(/*void*/)
{
	// Precache model
	FakePrecacheModel(ParachuteModel);
}

public void GUMShop_OnPlayerRemoveItem(int client, int item)
{
	if (!UTIL_IsValidClient(client))
		return;
	if (item == parachute.ID) {
		itemEnabled[client] = false;
		ResetParachute(client);
	}
}

public Action GUMShop_OnBuyItem(int client, int item) {
	if (item == parachute.ID) {
		itemEnabled[client] = true;
		GiveParachute(client);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action GUMShop_OnPreBuyItem(int client, int item) {
    if (item == parachute.ID && ZS_IsClientZombie(client)) {
        return Plugin_Stop;
    }
    return Plugin_Continue;
}

// Take the item/unlock from the player
public void OnClientDisconnect(client)
{
	if ( UTIL_IsValidClient(client) ) {
		itemEnabled[client] = false;
		ResetParachute(client);
	}
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float velocity[3], float angles[3], int &weapon, int &subtype, int &cmdNum, int &tickCount, int &seed, int mouse[2])
{
	if (!UTIL_IsValidAlive(client) )
		return;
	if (!itemEnabled[client])
		return;

	CheckParachute(client, buttons, weapon);
}

public Action Timer_GiveParachute(Handle timer, any client)
{
	GiveParachute(client);
	g_hGiveParachuteTimer[client] = null;
	
	return Plugin_Handled;
}

void GiveParachute(int client)
{
	if(!UTIL_IsValidAlive(client))
		return;
		
	if(GetClientTeam(client) <= CS_TEAM_SPECTATOR)
		return;
	
	if(HasParachute(client))
		return;
		
	g_bParachute[client] = true;
}

bool HasParachute(int client)
{
	return g_bParachute[client];
}

bool HasParachuteEnabled(int client)
{
	return g_bParachuteEnabled[client];
}

void ResetParachute(int client)
{
	DisableParachute(client);
	g_bParachute[client] = false;
}

void DisableParachute(int client)
{
	int iEntity = EntRefToEntIndex(g_iParachuteEntityRef[client]);
	if(iEntity != INVALID_ENT_REFERENCE)
	{
		AcceptEntityInput(iEntity, "ClearParent");
		AcceptEntityInput(iEntity, "kill");
	}
	
	g_bParachuteEnabled[client] = false;
	g_iParachuteEntityRef[client] = INVALID_ENT_REFERENCE;
}

void AbortParachute(int client)
{
	DisableParachute(client);
}

void CheckParachute(int client, int buttons, int weapon)
{
	// Check abort reasons
	if(HasParachuteEnabled(client))
	{
		// Abort by released button
		if(!(buttons & IN_USE) || !IsPlayerAlive(client))
		{
			AbortParachute(client);
			return;
		}
		
		// Abort by up speed
		float fVel[3];

		GetEntDataVector(client, g_iVelocity, fVel);
		
		if(fVel[2] >= 0.0)
		{
			AbortParachute(client);
			return;
		}
		
		// Abort by on ground flag
		if(GetEntityFlags(client) & FL_ONGROUND)
		{
			AbortParachute(client);
			BlockWeapon(client, weapon, 1.0);
			return;
		}
		
		// decrease fallspeed
		//float fOldSpeed = fVel[2];
		float fallspeed = fParachuteFallspeedMax * (-1.0);
		// Player is falling to fast, lets slow him to max fallspeed
		if(fVel[2] < fallspeed) {
			fVel[2] = fallspeed;
		} else {
			fVel[2] -= 2.0;
		}

		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, fVel);
		
		if(!bParachuteAllowShooting)
			BlockWeapon(client, weapon, 1.0);
	}
	// Should we start the parashute?
	else if(HasParachute(client))
	{
		// Reject by released button
		if(!(buttons & IN_USE))
			return;
		
		// Reject by on ground flag
		if(GetEntityFlags(client) & FL_ONGROUND)
			return;
		
		// Reject by up speed
		float fVel[3];
		GetEntDataVector(client, g_iVelocity, fVel);
		
		if(fVel[2] >= 0.0)
			return;
		
		// Open parachute
		int iEntity = CreateEntityByName("prop_dynamic_override");
		DispatchKeyValue(iEntity, "model", ParachuteModel);
		DispatchSpawn(iEntity);
		
		SetEntityMoveType(iEntity, MOVETYPE_NOCLIP);
		
		// Teleport to player
		float fPos[3];
		float fAng[3];
		GetClientAbsOrigin(client, fPos);
		GetClientAbsAngles(client, fAng);
		fAng[0] = 0.0;
		TeleportEntity(iEntity, fPos, fAng, NULL_VECTOR);
		
		// Parent to player
		char sClient[16];
		Format(sClient, 16, "client%d", client);
		DispatchKeyValue(client, "targetname", sClient);
		SetVariantString(sClient);
		AcceptEntityInput(iEntity, "SetParent", iEntity, iEntity, 0);
		
		g_iParachuteEntityRef[client] = EntIndexToEntRef(iEntity);
		g_bParachuteEnabled[client] = true;
	}
}

void BlockWeapon(int client, int weapon, float time)
{
	float fUnlockTime = GetGameTime() + time;
	
	SetEntPropFloat(client, Prop_Send, "m_flNextAttack", fUnlockTime);
	
	if(weapon <= 0)
		weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	
	if(weapon > 0)
		SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", fUnlockTime);
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
