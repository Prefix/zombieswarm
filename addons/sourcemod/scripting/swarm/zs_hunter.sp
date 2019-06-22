#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <zombieswarm>
#include <swarm/utils>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_NAME ZS_PLUGIN_NAME ... " - Zombie Class: Hunter"

public Plugin myinfo =
{
    name = PLUGIN_NAME,
    author = ZS_PLUGIN_AUTHOR,
    description = ZS_PLUGIN_DESCRIPTION,
    version = ZS_PLUGIN_VERSION,
    url = ZS_PLUGIN_URL
};

#define SOUND_LEAP "swarm/hunter_leap.mp3"

ZombieClass Zombie;
ZombieAbility abilityLeap;

int hunterNumLeapSounds[MAXPLAYERS + 1];

ConVar zHP, zDamage, zSpeed, zGravity, zExcluded, zCooldown, zLeep;

public void OnPluginStart() {                   
    
    zHP = CreateConVar("zs_hunter_hp", "80", "Zombie Hunter HP");
    zDamage = CreateConVar("zs_hunter_damage","17.0","Zombie Hunter done damage");
    zSpeed = CreateConVar("zs_hunter_speed","1.0","Zombie Hunter speed");
    zGravity = CreateConVar("zs_hunter_gravity","0.8","Zombie Hunter gravity");
    zExcluded = CreateConVar("zs_hunter_excluded","0","1 - Excluded, 0 - Not excluded");
    zCooldown = CreateConVar("zs_hunter_cooldown","4.0","Time in seconds for cooldown",_,true,1.0);
    zLeep = CreateConVar("zs_hunter_leap","500.0","How dar Hunter can jump");
    
    AutoExecConfig(true, "zombie.hunter", "sourcemod/zombieswarm");
}

public void ZS_OnLoaded() {
    // We are registering zombie
    Zombie = ZombieClass("hunter");
    Zombie.SetName("Zombie Hunter", MAX_CLASS_NAME_SIZE);
    Zombie.SetDesc("Has leaping (CTRL + ATTACK2 button)", MAX_CLASS_DESC_SIZE);
    Zombie.SetModel("models/player/custom/hunter/hunter", MAX_CLASS_MODEL_SIZE);
    Zombie.Health = zHP.IntValue;
    Zombie.Damage = zDamage.FloatValue;
    Zombie.Speed = zSpeed.FloatValue;
    Zombie.Gravity = zGravity.FloatValue;
    Zombie.Excluded = zExcluded.BoolValue;
    Zombie.Cooldown = zCooldown.FloatValue;
    // Abilities
    abilityLeap = ZombieAbility(Zombie, "hunter_leap");
    abilityLeap.Duration = ABILITY_NO_DURATION; // This is for classes who has no durations on skills
    abilityLeap.Cooldown = zCooldown.FloatValue;
    abilityLeap.Buttons = IN_DUCK|IN_ATTACK2;
    abilityLeap.SetName("Leap", MAX_ABILITY_NAME_SIZE);
    abilityLeap.SetDesc("Can make leap where hunter looks to", MAX_ABILITY_DESC_SIZE);
}

public void OnMapStart() {
    PrecacheSound( SOUND_LEAP );
    
    // Format sound
    char sPath[PLATFORM_MAX_PATH];
    Format(sPath, sizeof(sPath), "sound/%s", SOUND_LEAP);
    
    AddFileToDownloadsTable( sPath );
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

    PlayerAbility ability = view_as<PlayerAbility>(ability_id);
    if (ability.State != stateIdle)
        return;

    ability.AbilityStartedNoDuration();
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

    PlayerAbility ability = view_as<PlayerAbility>(ability_id);
    if (ability.State != stateRunning)
        return;
        
    if (!(GetEntityFlags(client) & FL_ONGROUND))
        return;

    float cVelocity[3];
    
    float eyePosition[3];
    GetClientEyeAngles(client, eyePosition);

    UTIL_VelocityByAim(client, zLeep.FloatValue, cVelocity);

    if ( eyePosition[0] > 15.0 ) {
        cVelocity[2] = 50.0;
    }
    else {
        float countedVelocity = (eyePosition[0] > -30.0 ? (FloatAbs(eyePosition[0]) + 350.0) : (FloatAbs(eyePosition[0]) * 10.0 + 100.0));
        cVelocity[2] = FloatAbs( countedVelocity );
    }
    
    TeleportEntity( client, NULL_VECTOR, NULL_VECTOR, cVelocity);
    
    hunterNumLeapSounds[client]++;
    
    if (hunterNumLeapSounds[client] >= 3 ) {
    
        EmitSoundToAll(SOUND_LEAP, client, SNDCHAN_VOICE, SNDLEVEL_SCREAMING);
        
        hunterNumLeapSounds[client] = 0;
    }
}

