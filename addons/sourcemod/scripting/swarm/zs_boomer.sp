#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <zombieswarm>

public Plugin myinfo =
{
    name = "Zombie Boom",
    author = "Zombie Swarm Contributors",
    description = "Explodes on death",
    version = "1.0",
    url = "https://github.com/Prefix/zombieswarm"
};

#define DAMAGE_EXPLODE 30.0
#define DAMAGE_DISTANCE 250.0

ZombieClass registeredClass;

int fireSprite;
int haloSprite;
int explosionSprite;

public void OnPluginStart()
{
    // We are registering zombie
    registeredClass = ZombieClass();
    registeredClass.SetName("Boomer", MAX_CLASS_NAME_SIZE);
    registeredClass.SetDesc("Explodes on death", MAX_CLASS_DESC_SIZE);
    registeredClass.SetModel("models/player/custom_player/borodatm.ru/l4d2/boomer", MAX_CLASS_MODEL_SIZE);
    registeredClass.Health = 105;
    registeredClass.Damage = 20.0;
    registeredClass.Speed = 1.1;
    registeredClass.Gravity = 0.8;
    registeredClass.Excluded = false;
                        
    HookEventEx("player_death", eventPlayerDeath, EventHookMode_Pre);
}
public void onZCSelected(int client, int classId)
{
    // TODO list
}

public void OnClientPostAdminCheck(int client)
{
    
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
    FakePrecacheSoundEx( "ambient/explosions/explode_8.mp3" );
    AddFileToDownloadsTable( "sound/ambient/explosions/explode_8.mp3" );
}

public Action eventPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    int victim = GetClientOfUserId(GetEventInt(event,"userid"));

    //if (IsValidClient(victim) && getZombieClass(victim) == registeredClass && !isGhost(victim) && getTeam(victim) == CS_TEAM_T)
    
    if ( !IsValidClient(victim) )
        return Plugin_Continue;

    ZMPlayer player = ZMPlayer(victim);

    if ( player.ZombieClass != registeredClass.ID )
        return Plugin_Continue;

    if ( player.Team != CS_TEAM_T )
        return Plugin_Continue;
    
    explodePlayer(victim);
    
    return Plugin_Continue;
}

stock explodePlayer(int client)
{
    float location[3];
    GetClientAbsOrigin(client, location);
    
    float targetOrigin[3], distanceBetween;
    for(int enemy = 1; enemy <= MaxClients; enemy++) 
    {
        ZMPlayer player = ZMPlayer(client);
        ZMPlayer enemyplayer = ZMPlayer(client);
        if ( !IsValidAlive(enemy) || enemy == client || enemyplayer.Team != player.Team )
            continue;

        GetClientAbsOrigin ( enemy, targetOrigin );
        distanceBetween = GetVectorDistance ( targetOrigin, location );
        
        if ( ( distanceBetween < DAMAGE_DISTANCE ) )
        {
            SDKHooks_TakeDamage(enemy, client, client, DAMAGE_EXPLODE, DMG_BLAST, -1, NULL_VECTOR, NULL_VECTOR);
            
            fadePlayer(enemy, 9, 10, {0, 133, 33, 210});
        }
    }
            
    explode1(location);
    explode2(location);
}

public explode1(float vec[3])
{
    int color[4] = {188,220,255,200};
    
    boomSound("ambient/explosions/explode_8.mp3", vec);
    
    TE_SetupExplosion(vec, explosionSprite, 10.0, 1, 0, 400, 5000);
    TE_SendToAll();
    TE_SetupBeamRingPoint(vec, 10.0, 500.0, fireSprite, haloSprite, 0, 10, 0.6, 10.0, 0.5, color, 10, 0);
    TE_SendToAll();
}

public explode2(float vec[3])
{
    vec[2] += 10;
    
    boomSound("ambient/explosions/explode_8.mp3", vec);
    
    TE_SetupExplosion(vec, explosionSprite, 10.0, 1, 0, 400, 5000);
    TE_SendToAll();
}

public boomSound(const char[] sound, const float origin[3])
{
    char sPathStar[PLATFORM_MAX_PATH];
    Format(sPathStar, sizeof(sPathStar), "*/%s", sound);

    EmitSoundToAll(sPathStar, SOUND_FROM_WORLD,SNDCHAN_AUTO,SNDLEVEL_NORMAL,SND_NOFLAGS,SNDVOL_NORMAL,SNDPITCH_NORMAL,-1,origin,NULL_VECTOR,true,0.0);
}