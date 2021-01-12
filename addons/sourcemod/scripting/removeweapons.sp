#include <sourcemod>
#include <sdkhooks>

public OnClientPutInServer( int client)
{
    SDKHook(client, SDKHook_WeaponDrop, OnWeaponDrop);
}

public Action OnWeaponDrop(int client, int weapon)
{
    if (weapon && IsValidEdict(weapon) && IsValidEntity(weapon))
        if(GetClientHealth(client) <= 0)
            CreateTimer(5.0, deleteWeapon, weapon);

    return Plugin_Continue;
}

public Action deleteWeapon(Handle timer, any weapon)
{
    if (weapon && IsValidEdict(weapon) && IsValidEntity(weapon)) {
        int client = GetEntPropEnt(weapon, Prop_Data, "m_hOwnerEntity"); 
        if (client == -1)
            RemoveEdict(weapon);
    }
} 