#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <zombieswarm>
#include <swarm/utils>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_NAME ZS_PLUGIN_NAME ... " - Zombie Class: Boomer"

public Plugin myinfo =
{
    name = PLUGIN_NAME,
    author = ZS_PLUGIN_AUTHOR,
    description = ZS_PLUGIN_DESCRIPTION,
    version = ZS_PLUGIN_VERSION,
    url = ZS_PLUGIN_URL
};

ZombieClass registeredClass;
ZombieAbility abilityVomit;

int fireSprite;
int haloSprite;
int explosionSprite;

#define ABILITY_UNIQUE_EXPLODE "boomer_explosion"
#define ABILITY_NAME "Vomit"
#define ABILITY_DESCRIPTION "Vomit humans"
#define CLASS_DESCRIPTION "Vomits humans and explodes on death"


ConVar zHP, zDamage, zSpeed, zGravity, zExcluded, zExplodeDamage, zRadius, zCooldown, zDuration;

public void OnPluginStart() {                 
    HookEventEx("player_death", eventPlayerDeath, EventHookMode_Pre);
    
    zHP = CreateConVar("zs_boomer_hp", "150", "Zombie Boomer HP");
    zDamage = CreateConVar("zs_boomer_damage","20.0","Zombie Boomer done damage");
    zSpeed = CreateConVar("zs_boomer_speed","0.8","Zombie Boomer speed");
    zGravity = CreateConVar("zs_boomer_gravity","0.8","Zombie Boomer gravity");
    zExcluded = CreateConVar("zs_boomer_excluded","0","1 - Excluded, 0 - Not excluded");
    zExplodeDamage = CreateConVar("zs_boomer_explode_damage","30.0","Zombie Boomer damage done then he explode");
    zRadius = CreateConVar("zs_boomer_radius","250.0","Explosion radius");
    zCooldown = CreateConVar("zs_boomer_cooldown","8.0","Time in seconds for cooldown",_,true,1.0);
    zDuration = CreateConVar("zs_boomer_duration","2.0","How long in second Boomer using his ability");
    
    AutoExecConfig(true, "zombie.boomer", "sourcemod/zombieswarm");
}
public void ZS_OnLoaded() {

    // We are registering zombie
    registeredClass = ZombieClass("boomer");
    registeredClass.SetName("Boomer", MAX_CLASS_NAME_SIZE);
    registeredClass.SetDesc(CLASS_DESCRIPTION, MAX_CLASS_DESC_SIZE);
    registeredClass.SetModel("models/player/custom_player/borodatm.ru/l4d2/boomer", MAX_CLASS_MODEL_SIZE);
    registeredClass.Health = zHP.IntValue;
    registeredClass.Damage = zDamage.FloatValue;
    registeredClass.Speed = zSpeed.FloatValue;
    registeredClass.Gravity = zGravity.FloatValue;
    registeredClass.Excluded = zExcluded.BoolValue;

    abilityVomit = ZombieAbility(registeredClass, ABILITY_UNIQUE_EXPLODE);
    abilityVomit.SetName(ABILITY_NAME, MAX_ABILITY_NAME_SIZE);
    abilityVomit.SetDesc(ABILITY_DESCRIPTION, MAX_ABILITY_DESC_SIZE);
    abilityVomit.Duration = zDuration.FloatValue;
    abilityVomit.Cooldown = zCooldown.FloatValue;
    abilityVomit.Buttons = IN_USE;
    // TODO ADD properties for explosion. Range, Damage etc.
}

public void OnMapStart()
{
    fireSprite = PrecacheModel( "sprites/fire2.vmt" );
    AddFileToDownloadsTable( "materials/sprites/fire2.vtf" );
    AddFileToDownloadsTable( "materials/sprites/fire2.vmt");
    haloSprite = PrecacheModel( "sprites/halo01.vmt" );
    AddFileToDownloadsTable( "materials/sprites/halo01.vtf" );
    AddFileToDownloadsTable( "materials/sprites/halo01.vmt" );
    explosionSprite = PrecacheModel( "sprites/sprite_fire01.vmt" );
    AddFileToDownloadsTable( "materials/sprites/sprite_fire01.vtf" );
    AddFileToDownloadsTable( "materials/sprites/sprite_fire01.vmt" );
    PrecacheSound( "ambient/explosions/explode_8.mp3" );
    AddFileToDownloadsTable( "sound/ambient/explosions/explode_8.mp3" );
    PrecacheSound( "swarm/vomiting.mp3" );
    AddFileToDownloadsTable( "sound/swarm/vomiting.mp3" );
}

public Action eventPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    int victim = GetClientOfUserId(GetEventInt(event,"userid"));
    
    if ( !UTIL_IsValidClient(victim) )
        return Plugin_Continue;

    ZMPlayer player = ZMPlayer(victim);

    if ( player.ZombieClass != registeredClass.ID )
        return Plugin_Continue;

    if ( player.Team != CS_TEAM_T )
        return Plugin_Continue;
    
    explodePlayer(victim);
    
    return Plugin_Continue;
}

stock void explodePlayer(int client)
{
    float location[3];
    GetClientAbsOrigin(client, location);
    
    float targetOrigin[3], distanceBetween;
    for(int enemy = 1; enemy <= MaxClients; enemy++) 
    {
        if (!UTIL_IsValidAlive(enemy) || ZS_IsClientZombie(enemy))
            continue;

        GetClientAbsOrigin ( enemy, targetOrigin );
        distanceBetween = GetVectorDistance ( targetOrigin, location );
        
        if (( distanceBetween <= zRadius.FloatValue)) {
            SDKHooks_TakeDamage(enemy, client, client, zExplodeDamage.FloatValue, DMG_BLAST, -1, NULL_VECTOR, NULL_VECTOR);
            
            UTIL_Fade(enemy, 5, 6, {0, 133, 33, 210});
            UTIL_ShakeScreen(enemy);
        }
    }
            
    explode1(location);
    explode2(location);
}

public void explode1(float vec[3])
{
    int color[4] = {188,220,255,200};
    
    boomSound("ambient/explosions/explode_8.mp3", vec);
    
    TE_SetupExplosion(vec, explosionSprite, 10.0, 1, 0, 400, 5000);
    TE_SendToAll();
    TE_SetupBeamRingPoint(vec, 10.0, 500.0, fireSprite, haloSprite, 0, 10, 0.6, 10.0, 0.5, color, 10, 0);
    TE_SendToAll();
}

public void explode2(float vec[3])
{
    vec[2] += 10;
    
    boomSound("ambient/explosions/explode_8.mp3", vec);
    
    TE_SetupExplosion(vec, explosionSprite, 10.0, 1, 0, 400, 5000);
    TE_SendToAll();
}

public void boomSound(const char[] sound, const float origin[3])
{
    EmitSoundToAll(sound, SOUND_FROM_WORLD,SNDCHAN_AUTO,SNDLEVEL_NORMAL,SND_NOFLAGS,SNDVOL_NORMAL,SNDPITCH_NORMAL,-1,origin,NULL_VECTOR,true,0.0);
}

public void ZS_OnAbilityButtonPressed(int client, int ability_id) { 

    if ( !UTIL_IsValidAlive(client) )
        return;

    ZMPlayer player = ZMPlayer(client);
    
    if ( player.Ghost )
        return;
        
    if ( player.Team != CS_TEAM_T)
        return;
        
    if ( player.ZombieClass != registeredClass.ID )
        return;

    if ( ability_id < 0)
        return;
        
    int ability_index = player.GetAbilityByID(ability_id);

    if (ability_index < 0)
        return;

    PlayerAbility ability = view_as<PlayerAbility>(ability_id);
    if (ability.State != stateIdle)
        return;

    ability.AbilityStarted();  
}

 public void ZS_OnAbilityStarted(int client, int ability_id) {
    if ( !UTIL_IsValidAlive(client) )
        return;

    ZMPlayer player = ZMPlayer(client);
    
    if ( player.Ghost )
        return;
        
    if ( player.Team != CS_TEAM_T)
        return;
        
    if ( player.ZombieClass != registeredClass.ID )
        return;

    if ( ability_id < 0)
        return;
        
    int ability_index = player.GetAbilityByID(ability_id);

    if (ability_index < 0)
        return;

    PlayerAbility ability = view_as<PlayerAbility>(ability_id);
    if (ability.State != stateRunning)
        return;     
    
    float location[3];
    GetClientAbsOrigin(client, location);
    
    float targetOrigin[3], distanceBetween;
    for(int enemy = 1; enemy <= MaxClients; enemy++) 
    {
        if (!UTIL_IsValidAlive(enemy) || ZS_IsClientZombie(enemy))
            continue;

        GetClientAbsOrigin ( enemy, targetOrigin );
        distanceBetween = GetVectorDistance ( targetOrigin, location );
        
        if (( distanceBetween <= zRadius.FloatValue)) {
            
            UTIL_Fade(enemy, 2, 3, {0, 133, 33, 210});
            UTIL_ShakeScreen(enemy);
        }
    }
    GetClientAbsOrigin(client, location);
    boomSound("swarm/vomiting.mp3", location);
}