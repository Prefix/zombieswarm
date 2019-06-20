#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <zombieswarm>
#include <swarm/utils>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_NAME ZS_PLUGIN_NAME ... " - Zombie Class: Phantom"

public Plugin myinfo =
{
    name = PLUGIN_NAME,
    author = ZS_PLUGIN_AUTHOR,
    description = ZS_PLUGIN_DESCRIPTION,
    version = ZS_PLUGIN_VERSION,
    url = ZS_PLUGIN_URL
};

#define SOUND_INVISIBILITY "zombie_mod/invisibility.mp3"
#define ABILITY_UNIQUE_INVIS "phantom_invisibility"

ZombieClass Zombie;
ZombieAbility abilityInvisibility;

bool hasInvisibility[MAXPLAYERS + 1];

ConVar zHP, zDamage, zSpeed, zGravity, zExcluded, zCooldown, zInvisibility;

public void OnPluginStart() {                 
    HookEvent("player_spawn", eventPlayerSpawn);
    
    zHP = CreateConVar("zs_phantom_hp", "80", "Zombie Phantom HP");
    zDamage = CreateConVar("zs_phantom_damage","15.0","Zombie Phantom done damage");
    zSpeed = CreateConVar("zs_phantom_speed","1.2","Zombie Phantom speed");
    zGravity = CreateConVar("zs_phantom_gravity","0.8","Zombie Phantom gravity");
    zExcluded = CreateConVar("zs_phantom_excluded","0","1 - Excluded, 0 - Not excluded");
    zCooldown = CreateConVar("zs_phantom_cooldown","8.0","Time in seconds for cooldown",_,true,1.0);
    zInvisibility = CreateConVar("zs_phantom_invisibility","3.0","Time in second until Phantom invisible");
    
    AutoExecConfig(true, "zombie.phantom", "sourcemod/zombieswarm");
}

public void ZS_OnLoaded() {
    // We are registering zombie
    Zombie = ZombieClass("phantom");
    Zombie.SetName("Zombie Phantom", MAX_CLASS_NAME_SIZE);
    Zombie.SetDesc("Can be invisible (ATTACK button)", MAX_CLASS_DESC_SIZE);
    Zombie.SetModel("models/player/custom_player/caleon1/mummy/mummy", MAX_CLASS_MODEL_SIZE);
    Zombie.Health = zHP.IntValue;
    Zombie.Damage = zDamage.FloatValue;
    Zombie.Speed = zSpeed.FloatValue;
    Zombie.Gravity = zGravity.FloatValue;
    Zombie.Excluded = zExcluded.BoolValue;
    // Abilities
    abilityInvisibility = ZombieAbility(Zombie, ABILITY_UNIQUE_INVIS);
    abilityInvisibility.Duration = zInvisibility.FloatValue;
    abilityInvisibility.Cooldown = zCooldown.FloatValue;
    abilityInvisibility.Buttons = IN_ATTACK2;
    abilityInvisibility.SetName("Invisibility", MAX_ABILITY_NAME_SIZE);
    abilityInvisibility.SetDesc("Becomes invisible for few seconds.", MAX_ABILITY_DESC_SIZE);
}

public Action eventPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));

    if ( !UTIL_IsValidAlive(client) )
        return;
        
    // Back to first state
    hasInvisibility[client] = false;
}

public void OnMapStart()
{
    UTIL_FakePrecacheSoundEx( SOUND_INVISIBILITY );
    
    // Format sound
    char sPath[PLATFORM_MAX_PATH];
    Format(sPath, sizeof(sPath), "sound/%s", SOUND_INVISIBILITY);
    
    AddFileToDownloadsTable( sPath );
}

public void OnClientPostAdminCheck(int client)
{
    SDKHook(client, SDKHook_SetTransmit, onSetTransmit);
    SDKHook(client, SDKHook_OnTakeDamage, onTakeDamage);
}

/*public void OnClientDisconnect(int client)
{
    if ( IsClientInGame(client) )
    {
        if (timerInvisibility[client] != null) {
            delete timerInvisibility[client];
        }
        if (timerCountdown[client] != null) {
            delete timerCountdown[client];
        }
    }
}*/

public Action onSetTransmit(int entity, int client) 
{
    if ( !UTIL_IsValidAlive(entity) || !UTIL_IsValidAlive(client) ) return Plugin_Continue;
    
    if (entity == client) return Plugin_Continue;
    
    if ( getTeam(entity) != getTeam(client) && getTeam(entity) == CS_TEAM_T && hasInvisibility[entity] )
        return Plugin_Handled; 
    
    return Plugin_Continue;
}

public Action onTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
    if ( !UTIL_IsValidClient(victim) )
        return Plugin_Continue;
        
    if ( !UTIL_IsValidClient(attacker) )
        return Plugin_Continue;
        
    if (victim == attacker)
        return Plugin_Continue;
    
    ZMPlayer attackerplayer = ZMPlayer(attacker);
    ZMPlayer victimplayer = ZMPlayer(victim);

    if ( attackerplayer.ZombieClass != Zombie.ID )
        return Plugin_Continue;
        
    if ( victimplayer.Team != CS_TEAM_CT)
        return Plugin_Continue;

    // TODO force ability stop
    if ( !hasInvisibility[attacker] )
        return Plugin_Continue;
    
    hasInvisibility[attacker] = false;
        
    return Plugin_Continue;
}

public void ZS_OnAbilityButtonPressed(int client, int ability_id) { 
    if ( !UTIL_IsValidAlive(client) )
        return;

    ZMPlayer player = ZMPlayer(client);
    
    if ( player.Ghost )
        return;
        
    if ( player.Team != CS_TEAM_T)
        return;
        
    if ( player.ZombieClass != Zombie.ID )
        return;

    if ( ability_id < 0)
        return;
        
    int ability_index = player.GetAbilityByID(ability_id);

    if (ability_index < 0)
        return;

    PlayerAbility ability = view_as<PlayerAbility>(ability_index);
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
        
    if ( player.ZombieClass != Zombie.ID )
        return;

    if ( ability_id < 0)
        return;
        
    int ability_index = player.GetAbilityByID(ability_id);

    if (ability_index < 0)
        return;

    PlayerAbility ability = view_as<PlayerAbility>(ability_index);
    if (ability.State != stateRunning)
        return;
    
    UTIL_Fade(client, 1, 1, {255, 255, 255, 150});
    
    // Make invisible zombie
    hasInvisibility[client] = true;
    
    // Format sound
    char sPath[PLATFORM_MAX_PATH];
    FormatEx(sPath, sizeof(sPath), "*/%s", SOUND_INVISIBILITY);
    
    EmitSoundToAll(sPath, client, SNDCHAN_VOICE, SNDLEVEL_SCREAMING);
}

public void ZS_OnCooldownStarted(int client, int ability_id) {
    if ( !UTIL_IsValidAlive(client) )
        return;

    ZMPlayer player = ZMPlayer(client);
    
    if ( player.Ghost )
        return;
        
    if ( player.Team != CS_TEAM_T)
        return;
        
    if ( player.ZombieClass != Zombie.ID )
        return;

    if ( ability_id < 0)
        return;
        
    int ability_index = player.GetAbilityByID(ability_id);

    if (ability_index < 0)
        return;

    PlayerAbility ability = view_as<PlayerAbility>(ability_index);
    if (ability.State != stateCooldown)
        return;
        
    hasInvisibility[client] = false;
}