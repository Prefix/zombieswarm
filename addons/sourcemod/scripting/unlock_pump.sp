#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <gum>

#define AirMultiplier 0.5
#define KnockBack 4.0

public Plugin myinfo =
{
    name = "Pump knockback",
    author = "Zombie Swarm Contributors",
    description = "none",
    version = "1.0",
    url = "https://github.com/Prefix/zombieswarm"
};

#define ITEM_COST 50

#define PUMP_FORCE 9.0

bool itemEnabled[MAXPLAYERS + 1];

int g_iToolsVelocity;

public void OnPluginStart()
{
	// We are registering item here
	// itemRebuy - 0 = Item can be bought one time per connect, 1 = Buy item many times, 2 = Item can be bought one time per round
	// itemRebuyTimes - 0 = Infinite buy, >0 = Item rebuy times
	registerGumItem("Pump knockback", "Knocks back enemies with pump", ITEM_COST, 0, 0);
	
	HookEvent("player_hurt", eventPlayerHurt);
	g_iToolsVelocity = FindSendPropInfo("CBasePlayer", "m_vecVelocity[0]");
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
	if ( IsValidClient(client) )
		itemEnabled[client] = false;
}

public void eventPlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(GetEventInt(event, "userid"));
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if (victim == attacker)
		return;

	if (!IsValidAlive(attacker))
		return;
		
	if (!IsValidAlive(victim))
		return;
		
	if (GetClientTeam(victim) == GetClientTeam(attacker))
		return;
		
	if (!itemEnabled[attacker])
		return;
		
	char weaponName[16];

	GetEventString(event, "weapon", weaponName, sizeof(weaponName));

	if (StrContains(weaponName, "nova") == -1 && StrContains(weaponName, "xm1014") == -1 && StrContains(weaponName, "mag7") == -1
	&& StrContains(weaponName, "sawedoff") == -1)
		return;
		
	float clientloc[3];
	float attackerloc[3];
	float knockback = KnockBack;
	// Get attackers eye position.
	GetClientEyePosition(attacker, attackerloc);
	
	// Get attackers eye angles.
	new Float:attackerang[3];
	GetClientEyeAngles(attacker, attackerang);
	
	// Calculate knockback end-vector.
	TR_TraceRayFilter(attackerloc, attackerang, MASK_ALL, RayType_Infinite, KnockbackTRFilter);
	TR_GetEndPosition(clientloc);
	// Apply damage knockback multiplier.
	//knockback *= float(health);
	
	// Apply multiplier if client on air
	if(GetEntPropEnt(victim, Prop_Send, "m_hGroundEntity") == -1) knockback *= AirMultiplier;

	// Apply knockback.
	KnockbackSetVelocity(victim, attackerloc, clientloc, knockback);
}

stock KnockbackSetVelocity(client, const Float:startpoint[3], const Float:endpoint[3], Float:magnitude)
{
	// Create vector from the given starting and ending points.
	float vector[3];
	MakeVectorFromPoints(startpoint, endpoint, vector);
	
	// Normalize the vector (equal magnitude at varying distances).
	NormalizeVector(vector, vector);
	
	// Apply the magnitude by scaling the vector (multiplying each of its components).
	ScaleVector(vector, magnitude);
	
	// ADD the given vector to the client's current velocity.
	ToolsClientVelocity(client, vector, true, false);
}


public bool KnockbackTRFilter(int entity, int contentsMask)
{
	// If entity is a player, continue tracing.
	if (entity > 0 && entity < MAXPLAYERS)
	{
		return false;
	}
	
	// Allow hit.
	return true;
}
stock ToolsClientVelocity(int client, float vecVelocity[3], bool apply = true, bool stack = true)
{
	// If retrieve if true, then get client's velocity.
	if (!apply)
	{
		// x = vector component.
		for (int x = 0; x < 3; x++)
		{
			vecVelocity[x] = GetEntDataFloat(client, g_iToolsVelocity + (x*4));
		}
		
		// Stop here.
		return;
	}
	
	// If stack is true, then add client's velocity.
	if (stack)
	{
		// Get client's velocity.
		new Float:vecClientVelocity[3];
		
		// x = vector component.
		for (new x = 0; x < 3; x++)
		{
			vecClientVelocity[x] = GetEntDataFloat(client, g_iToolsVelocity + (x*4));
		}
		
		AddVectors(vecClientVelocity, vecVelocity, vecVelocity);
	}
	
	// Apply velocity on client.
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vecVelocity);
}