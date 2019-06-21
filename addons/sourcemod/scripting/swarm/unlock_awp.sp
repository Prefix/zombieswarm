#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <gum>
#include <swarm/utils>

public Plugin myinfo =
{
    name = "AWP Bullet Chain Lightning",
    author = "Zombie Swarm Contributors",
    description = "none",
    version = "1.0",
    url = "https://github.com/Prefix/zombieswarm"
};

#define CHAIN_LIGHTNING_DAMAGE 70.0
#define CHAIN_LIGHTNING_DISTANCE 500.0
#define CHAIN_LIGHTNING_JUMPS 3

#define ITEM_COST 20

#define GUN_UNLOCK "awp"

bool itemEnabled[MAXPLAYERS + 1];

int traceLightning;

public void OnPluginStart()
{
    // We are registering item here with parameters
    // itemRebuy - 0 = Item can be bought one time per connect, 1 = Buy item many times, 2 = Item can be bought one time per round
    // itemRebuyTimes - 0 = Infinite buy, >0 = Item rebuy times
    registerGumItem("AWP Chain Lightning", "AWP bullet chain lightning between players", ITEM_COST, 0, 0);
    
    HookEvent("weapon_fire", eventWeaponFire);
    HookEvent("player_hurt", eventPlayerHurt);
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

public void OnMapStart()
{
    traceLightning = PrecacheModel("particle/bendibeam.vmt");
}

public void eventWeaponFire(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));

    if (!UTIL_IsValidAlive(client))
        return;
        
    if (!itemEnabled[client])
        return;
    
    char weaponName[16];
    float position[3], eyePosition[3]; 
    
    GetEventString(event, "weapon", weaponName, sizeof(weaponName));

    if (StrContains(weaponName, GUN_UNLOCK) != -1)
    {
        getLookPosition(client, position);
        GetClientEyePosition(client, eyePosition);
        
        TE_SetupBeamPoints(eyePosition, position, traceLightning, 0, 0, 0, 0.3, 4.0, 4.0, 1, 1.1, {0, 100, 125, 190}, 1);
        TE_SendToAll();
        TE_SetupBeamPoints(position, eyePosition, traceLightning, 0, 0, 0, 0.3, 6.0, 8.0, 1, 0.0, {0, 0, 255, 190}, 6); 
        TE_SendToAll();
    }
}

public void eventPlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
    static bool bIgnore = false;
    if(bIgnore)
    {
        bIgnore = false;
        return;
    }
    
    int victim = GetClientOfUserId(GetEventInt(event, "userid"));
    int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

    if (victim == attacker)
        return;

    if (!UTIL_IsValidAlive(attacker))
        return;
        
    if (!UTIL_IsValidClient(victim))
        return;
        
    if (GetClientTeam(victim) == GetClientTeam(attacker))
        return;
        
    if (!itemEnabled[attacker])
        return;
        
    char weaponName[16];

    GetEventString(event, "weapon", weaponName, sizeof(weaponName));
    
    if (StrContains(weaponName, GUN_UNLOCK) == -1)
        return;
    
    float victimLocation[3], targetLocation[3];
    GetClientAbsOrigin(victim, victimLocation);
        
    int targets[CHAIN_LIGHTNING_JUMPS] = -1;
    
    int target = GetRandomClient(victim, targets);
    
    targets[0] = victim;

    if (UTIL_IsValidAlive(target)) {
        GetClientAbsOrigin(target, targetLocation);

        float distanceBetween = GetVectorDistance ( victimLocation, targetLocation );
        
        if ( ( distanceBetween < CHAIN_LIGHTNING_DISTANCE ) )
        {
            victimLocation[2] += 50.0;
            targetLocation[2] += 50.0;
            
            bIgnore = true;
            
            fadePlayer(target, 3, 4, {255, 255, 255, 210});
            SDKHooks_TakeDamage(target, attacker, attacker, CHAIN_LIGHTNING_DAMAGE, DMG_SHOCK, -1, NULL_VECTOR, NULL_VECTOR);
            
            TE_SetupBeamPoints(victimLocation, targetLocation, traceLightning, 0, 0, 0, 0.3, 4.0, 4.0, 1, 1.1, {0, 100, 125, 190}, 1);
            TE_SendToAll();
            TE_SetupBeamPoints(victimLocation, targetLocation, traceLightning, 0, 0, 0, 0.3, 6.0, 8.0, 1, 0.0, {0, 0, 255, 190}, 6); 
            TE_SendToAll();
            
            int lastTarget = -1;
            for (int i = 0; i < CHAIN_LIGHTNING_JUMPS-1; i++) 
            {
                GetClientAbsOrigin(target, victimLocation);
                
                if (lastTarget > -1)
                    GetClientAbsOrigin(lastTarget, victimLocation);
            
                int nextTarget = GetRandomClient(target, targets);
                targets[i+1] = target;
                
                if (lastTarget > -1) {
                    nextTarget = GetRandomClient(lastTarget, targets);
                    targets[i+1] = lastTarget;
                }
                
                if (UTIL_IsValidAlive(nextTarget)) {
                    GetClientAbsOrigin(nextTarget, targetLocation);
                    
                    distanceBetween = GetVectorDistance ( victimLocation, targetLocation );
                    
                    if ( ( distanceBetween < CHAIN_LIGHTNING_DISTANCE ) )
                    {
                        victimLocation[2] += 50.0;
                        targetLocation[2] += 50.0;
                        
                        bIgnore = true;
                        
                        fadePlayer(nextTarget, 3, 4, {255, 255, 255, 210});
                        SDKHooks_TakeDamage(nextTarget, attacker, attacker, CHAIN_LIGHTNING_DAMAGE, DMG_SHOCK, -1, NULL_VECTOR, NULL_VECTOR);
                        
                        TE_SetupBeamPoints(victimLocation, targetLocation, traceLightning, 0, 0, 0, 0.3, 4.0, 4.0, 1, 1.1, {0, 100, 125, 190}, 1);
                        TE_SendToAll();
                        TE_SetupBeamPoints(victimLocation, targetLocation, traceLightning, 0, 0, 0, 0.3, 6.0, 8.0, 1, 0.0, {0, 0, 255, 190}, 6); 
                        TE_SendToAll();
                    }
                    
                    lastTarget = nextTarget;
                }
            }
        }        
    }
}

public void getLookPosition(int client, float eyePositionReference[3])
{
    float eyePosition[3], eyeAngles[3];
    Handle trace; 
    
    GetClientEyePosition(client, eyePosition); 
    GetClientEyeAngles(client, eyeAngles); 
    
    trace = TR_TraceRayFilterEx(eyePosition, eyeAngles, MASK_SOLID, RayType_Infinite, getLookPositionFilter, client); 
    
    TR_GetEndPosition(eyePositionReference, trace); 
    
    delete trace;
}

public bool getLookPositionFilter(int entity, int contentsMask, any client)
{ 
    return client != entity; 
}

public int GetRandomClient(int client, int targets[CHAIN_LIGHTNING_JUMPS]) 
{ 
    int[] iClients = new int[MaxClients];
    int iClientsNum, i;
    
    float location[3], targetOrigin[3], distanceBetween;
    GetClientAbsOrigin(client, location);
    
    for (i = 1; i <= MaxClients; i++) 
    { 
        int inJump = false;
        
        for (int jumps = 0; jumps < CHAIN_LIGHTNING_JUMPS; jumps++) 
        {
            if (targets[jumps] > -1) {
                inJump = targets[jumps];
                break;
            }
        }
        
        if (UTIL_IsValidAlive(i) && GetClientTeam(i) == GetClientTeam(client) && i != client && i != inJump)
        {
            GetClientAbsOrigin( i, targetOrigin );
            distanceBetween = GetVectorDistance ( targetOrigin, location );
            
            if ( ( distanceBetween < CHAIN_LIGHTNING_DISTANCE ) )
            {
                iClients[iClientsNum++] = i; 
            }
        }
    } 
    
    if (iClientsNum > 0)
    {
        return iClients[GetRandomInt(0, iClientsNum-1)]; 
    }
    
    return -1;
}

stock fadePlayer(int client, int duration = 5, int time = 6, color[4] = {0, 0, 0, 255} )
{
    Handle message = StartMessageOne("Fade", client, USERMSG_RELIABLE);
    PbSetInt(message, "duration", duration*300);
    PbSetInt(message, "hold_time", time*300);
    PbSetInt(message, "flags", 0x0009);
    PbSetColor(message, "clr", color);
    EndMessage();
} 