#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <zombieswarm>

public Plugin myinfo =
{
    name = "Zombie Hunter",
    author = "Zombie Swarm Contributors",
    description = "Has leaping",
    version = "1.0",
    url = "https://github.com/Prefix/zombieswarm"
};

#define SOUND_LEAP "zombie_mod/hunter_leap.mp3"

ZombieClass registeredClass;

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
    registeredClass = ZombieClass();
    registeredClass.SetName("Zombie Hunter", MAX_CLASS_NAME_SIZE);
    registeredClass.SetDesc("Has leaping (CTRL + ATTACK2 button)", MAX_CLASS_DESC_SIZE);
    registeredClass.SetModel("models/player/custom/hunter/hunter", MAX_CLASS_MODEL_SIZE);
    registeredClass.Health = zHP.IntValue;
    registeredClass.Damage = zDamage.FloatValue;
    registeredClass.Speed = zSpeed.FloatValue;
    registeredClass.Gravity = zGravity.FloatValue;
    registeredClass.Excluded = zExcluded.BoolValue;
    registeredClass.Cooldown = zCooldown.FloatValue;
}

public void OnMapStart() {
    FakePrecacheSoundEx( SOUND_LEAP );
    
    // Format sound
    char sPath[PLATFORM_MAX_PATH];
    Format(sPath, sizeof(sPath), "sound/%s", SOUND_LEAP);
    
    AddFileToDownloadsTable( sPath );
}

public bool ZS_OnAbilityButtonPressed(int client, int ZClass, int buttons) {
    if ( !IsValidAlive(client) )
        return false;

    ZMPlayer player = ZMPlayer(client);
        
    if ( player.Ghost )
        return false;
        
    if ( player.Team != CS_TEAM_T)
        return false;
        
    if ( player.ZombieClass != registeredClass.ID )
        return false;
        
    if (!((buttons & IN_DUCK) && (GetEntityFlags(client) & FL_ONGROUND)))
        return false;

    float cVelocity[3];
    
    float eyePosition[3];
    GetClientEyeAngles(client, eyePosition);

    velocityByAim(client, zLeep.FloatValue, cVelocity)

    if ( eyePosition[0] > 15.0 ) {
        cVelocity[2] = 50.0
    }
    else {
        float countedVelocity = (eyePosition[0] > -30.0 ? (FloatAbs(eyePosition[0]) + 350.0) : (FloatAbs(eyePosition[0]) * 10.0 + 100.0));
        cVelocity[2] = FloatAbs( countedVelocity );
    }
    
    TeleportEntity( client, NULL_VECTOR, NULL_VECTOR, cVelocity);
    
    hunterNumLeapSounds[client]++;
    
    if (hunterNumLeapSounds[client] >= 3 ) {
        // Format sound
        char sPath[PLATFORM_MAX_PATH];
        FormatEx(sPath, sizeof(sPath), "*/%s", SOUND_LEAP);
    
        EmitSoundToAll(sPath, client, SNDCHAN_VOICE, SNDLEVEL_SCREAMING);
        
        hunterNumLeapSounds[client] = 0;
    }
    
    return true;
}

