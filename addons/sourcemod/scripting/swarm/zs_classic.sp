#include <sourcemod>
#include <sdktools>
#include <zombieswarm>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_NAME ZS_PLUGIN_NAME ... " - Zombie Class: Classic"

public Plugin myinfo =
{
    name = PLUGIN_NAME,
    author = ZS_PLUGIN_AUTHOR,
    description = ZS_PLUGIN_DESCRIPTION,
    version = ZS_PLUGIN_VERSION,
    url = ZS_PLUGIN_URL
};

ZombieClass registeredClass;

ConVar zHP, zDamage, zSpeed, zGravity, zExcluded;

public void OnPluginStart() {                 
    
    zHP = CreateConVar("zs_classic_hp", "120", "Zombie Classic HP");
    zDamage = CreateConVar("zs_classic_damage","25.0","Zombie Classic done damage");
    zSpeed = CreateConVar("zs_classic_speed","1.0","Zombie Classic speed");
    zGravity = CreateConVar("zs_classic_gravity","0.8","Zombie Classic gravity");
    zExcluded = CreateConVar("zs_classic_excluded","0","1 - Excluded, 0 - Not excluded");
    
    AutoExecConfig(true, "zombie.classic", "sourcemod/zombieswarm");
}

public void ZS_OnLoaded() {
    // We are registering zombie
    registeredClass = ZombieClass("classic");
    registeredClass.SetName("Zombie Classic", MAX_CLASS_NAME_SIZE);
    registeredClass.SetDesc("Default zombie class, has extra damage to humans.", MAX_CLASS_DESC_SIZE);
    registeredClass.SetModel("models/player/kuristaja/zombies/classic/classic", MAX_CLASS_MODEL_SIZE);
    registeredClass.Health = zHP.IntValue;
    registeredClass.Damage = zDamage.FloatValue;
    registeredClass.Speed = zSpeed.FloatValue;
    registeredClass.Gravity = zGravity.FloatValue;
    registeredClass.Excluded = zExcluded.BoolValue;
}