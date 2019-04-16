#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <zombiemod>

public Plugin myinfo =
{
    name = "Zombie Hunter",
    author = "Zombie Swarm Contributors",
    description = "Has leaping",
    version = "1.0",
    url = "https://github.com/Prefix/zombieswarm"
};

#define SOUND_LEAP "zombie_mod/hunter_leap.mp3"

#define LEAP_FORCE 500.0

ZombieClass registeredClass;

int hunterNumLeapSounds[MAXPLAYERS + 1];

float lastPressedButtons[MAXPLAYERS + 1];

public void OnPluginStart()
{
    // We are registering item
    registeredClass = ZombieClass(
        "Zombie Hunter", // Class name
        "Has leaping (CTRL + ATTACK2 button)", // Class description
        "models/player/custom/hunter/hunter", // Class model
        80, // Class base HP
        17.0, // Class damage
        1.0, // Class speed
        0.8, // Class gravity
        false // Is class excluded from normal rotation
    );
}
public void onZCSelected(int client, int classId)
{
    // TODO list
}

public void OnMapStart()
{
    FakePrecacheSoundEx( SOUND_LEAP );
    
    // Format sound
    char sPath[PLATFORM_MAX_PATH];
    Format(sPath, sizeof(sPath), "sound/%s", SOUND_LEAP);
    
    AddFileToDownloadsTable( sPath );
}

public void OnClientPostAdminCheck(int client)
{
    lastPressedButtons[client] = 0.0
}

//public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float velocity[3], float angles[3], int &weapon, int &subtype, int &cmdNum, int &tickCount, int &seed, int mouse[2])
public void onZRightClick(int client, int class, int buttons)
{
    if ( !IsValidAlive(client) )
        return;

    ZMPlayer player = ZMPlayer(client);
        
    if ( player.Ghost )
        return;
        
    if ( player.Team != CS_TEAM_T)
        return;
        
    if ( player.ZombieClass != registeredClass.ID )
        return;
            
    float currentTime = GetGameTime();
            
    if (currentTime - lastPressedButtons[client] < 2.0)
    {
        return;
    }
        
    if (!((buttons & IN_DUCK) && (GetEntityFlags(client) & FL_ONGROUND)))
        return;

    float cVelocity[3];
    
    float eyePosition[3];
    GetClientEyeAngles(client, eyePosition);

    velocityByAim(client, LEAP_FORCE, cVelocity)

    if ( eyePosition[0] > 15.0 )
    {
        cVelocity[2] = 50.0
    }
    else
    {
        float countedVelocity = (eyePosition[0] > -30.0 ? (FloatAbs(eyePosition[0]) + 350.0) : (FloatAbs(eyePosition[0]) * 10.0 + 100.0));
        cVelocity[2] = FloatAbs( countedVelocity );
    }
    
    TeleportEntity( client, NULL_VECTOR, NULL_VECTOR, cVelocity);
    
    hunterNumLeapSounds[client]++;
    
    if ( hunterNumLeapSounds[client] >= 3 )
    {
        // Format sound
        char sPath[PLATFORM_MAX_PATH];
        FormatEx(sPath, sizeof(sPath), "*/%s", SOUND_LEAP);
    
        EmitSoundToAll(sPath, client, SNDCHAN_VOICE, SNDLEVEL_SCREAMING);
        
        hunterNumLeapSounds[client] = 0;
    }
    
    lastPressedButtons[client] = currentTime;
}

