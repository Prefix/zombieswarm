#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <zombieswarm>

public Plugin myinfo =
{
    name = "Zombie Fury",
    author = "Zombie Swarm Contributors",
    description = "Can rage",
    version = "1.0",
    url = "https://github.com/Prefix/zombieswarm"
};

#define ZOMBIE_SPEED 1.0

#define SOUND_FURY "zombie_mod/fury.mp3"

#define FURY_DURATION 4.0
#define FURY_COOLDOWN 12.0
#define FURY_SPEED 1.15

ZombieClass registeredClass;

float lastPressedButtons[MAXPLAYERS + 1];

Handle timerFury[MAXPLAYERS + 1];
Handle timerFuryEffect[MAXPLAYERS + 1];

int fireSprite, haloSprite;

bool tankAlive;
bool tankReady = true;
Handle timerNextTank;

#define SPAWNTIME 90.0

public void OnPluginStart()
{
    // We are registering zombie
    registeredClass = ZombieClass();
    registeredClass.SetName("Zombie Fury [TANK]", MAX_CLASS_NAME_SIZE);
    registeredClass.SetDesc("Can rage (ATTACK2 button) with Iron skin", MAX_CLASS_DESC_SIZE);
    registeredClass.SetModel("models/player/custom_player/caleon1/l4d2_tank/l4d2_tank", MAX_CLASS_MODEL_SIZE);
    registeredClass.Health = 135;
    registeredClass.Damage = 30.0;
    registeredClass.Speed = ZOMBIE_SPEED;
    registeredClass.Gravity = 0.8;
    registeredClass.Excluded = false;
                        
    HookEvent("player_spawn", eventPlayerSpawn);
    HookEvent("player_death", eventPlayerDeath);
    HookEvent("round_start", eventRoundStart); 
    HookEvent("round_end", eventRoundEnd);
}
public void onZCSelected(int client, int classId)
{
    if(!tankAlive && tankReady && GetAliveCount() >= 4) {
        ZMPlayer player = ZMPlayer(client);
        player.ZombieClass = registeredClass.ID;
        tankAlive = true;
        tankReady = false;
    }
}

public int GetAliveCount() {
    int alive = 0;
    for (int i = 1; i <= MaxClients; i++) {
        if (IsClientInGame(i) && (!IsFakeClient(i)) && IsPlayerAlive(i))
        {
            alive++;    
        }
    }  
    return alive;
}

public void OnMapStart()
{
    tankAlive = false;
    tankReady = true;

    FakePrecacheSoundEx( SOUND_FURY );
    
    // Format sound
    char sPath[PLATFORM_MAX_PATH];
    Format(sPath, sizeof(sPath), "sound/%s", SOUND_FURY);
    
    AddFileToDownloadsTable( sPath );
    
    fireSprite = PrecacheModel( "sprites/fire2.vmt" );
    AddFileToDownloadsTable( "materials/sprites/fire2.vtf" );
    AddFileToDownloadsTable( "materials/sprites/fire2.vmt");
    
    haloSprite = PrecacheModel( "sprites/halo01.vmt" );
    AddFileToDownloadsTable( "materials/sprites/halo01.vtf" );
    AddFileToDownloadsTable( "materials/sprites/halo01.vmt" );
    
    precacheParticle("firework_crate_ground_low_03");
    precacheParticle("slime_splash_01");
}

public eventPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));

    if ( !IsValidAlive(client) )
        return;
        
    if (timerFury[client] != null) {
        delete timerFury[client];
    }
    
    if (timerFuryEffect[client] != null) {
        delete timerFuryEffect[client];
    }
        
    // Back to first state
    SetEntityRenderMode(client, RENDER_TRANSCOLOR);  
    SetEntityRenderColor(client, 255, 255, 255, 255);
}

public eventPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    int victim = GetClientOfUserId(GetEventInt(event, "userid"));

    if ( !IsValidClient(victim) )
        return;
        
    if (timerFury[victim] != null) {
        delete timerFury[victim];
    }
    
    if (timerFuryEffect[victim] != null) {
        delete timerFuryEffect[victim];
    }

    ZMPlayer victimplayer = ZMPlayer(victim);
    
    if (victimplayer.ZombieClass == registeredClass.ID && victimplayer.Team == CS_TEAM_T)
    {
        tankAlive = false;
        timerNextTank = CreateTimer(SPAWNTIME, TimerNextTank);
    }
}

public Action eventRoundEnd(Event event, const char[] name, bool dontBroadcast)
{
    if(timerNextTank != null)
        delete timerNextTank;
        
    tankAlive = false;
    tankReady = true;
        
    return Plugin_Continue;
}

public Action eventRoundStart(Event event, const char[] name, bool dontBroadcast)
{
    tankAlive = false;
    tankReady = true;
    return Plugin_Continue;
}

public void OnClientPostAdminCheck(int client)
{
    lastPressedButtons[client] = 0.0;
    
    SDKHook(client, SDKHook_OnTakeDamage, onTakeDamage);
    SDKHook(client, SDKHook_TraceAttack, onTraceAttack);
}

public Action onTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
    if ( !IsValidClient(victim) )
        return Plugin_Continue;
        
    if ( !IsValidClient(attacker) )
        return Plugin_Continue;
        
    if (victim == attacker)
        return Plugin_Continue;
    
    ZMPlayer victimplayer = ZMPlayer(victim);

    if ( victimplayer.ZombieClass != registeredClass.ID )
        return Plugin_Continue;
        
    if ( victimplayer.Team != CS_TEAM_T)
        return Plugin_Continue;
        
    if (timerFury[victim] != null)
        return Plugin_Handled;
        
    return Plugin_Continue;
}

public Action onTraceAttack(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &ammotype, int hitbox, int hitgroup)
{
    if ( !IsValidClient(victim) )
        return Plugin_Continue;
        
    if ( !IsValidClient(attacker) )
        return Plugin_Continue;
        
    if (victim == attacker)
        return Plugin_Continue;
        
    ZMPlayer victimplayer = ZMPlayer(victim);

    if ( victimplayer.ZombieClass != registeredClass.ID )
        return Plugin_Continue;
        
    if ( victimplayer.Team != CS_TEAM_T)
        return Plugin_Continue;
        
    if (timerFury[victim] != null)
        return Plugin_Handled;
        
    return Plugin_Continue;
}

public void OnClientDisconnect(int client)
{
    if ( !IsClientInGame(client) )
        return;

    if (timerFury[client] != null)
        delete timerFury[client];
    
    if (timerFuryEffect[client] != null) 
        delete timerFuryEffect[client];

    ZMPlayer player = ZMPlayer(client);
    
    if ( player.ZombieClass == registeredClass.ID )
    {
        if(timerNextTank != null)
            delete timerNextTank;

        tankAlive = false;
        tankReady = true;
    }
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
            
    if (currentTime - lastPressedButtons[client] < FURY_COOLDOWN)
        return;
        
    if (timerFury[client] != null)
        delete timerFury[client];
    
    fadePlayer(client, 1, 1, {204, 0, 0, 150});
    
    // Make invisible zombie
    SetEntityRenderMode(client, RENDER_TRANSCOLOR);  
    SetEntityRenderColor(client, 204, 0, 0, 255);
    
    SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", FURY_SPEED);
    
    float position[3];
    GetClientAbsOrigin(client, position);
    
    position[2] += 8.0;
    
    createAttachParticle(client, "firework_crate_ground_low_03", position, "fwcgl", FURY_DURATION);
    
    position[2] += 5.0;
    
    TE_SetupBeamRingPoint(position, 10.0, 100.0, fireSprite, haloSprite, 0, 10, 0.2, 30.0, 0.7, view_as<int>({204,0,0,200}), 25, 0);
    TE_SendToAll();
    
    position[2] += 15.0;
    
    TE_SetupBeamRingPoint(position, 10.0, 100.0, fireSprite, haloSprite, 0, 10, 0.2, 30.0, 0.7, view_as<int>({204,0,0,200}), 25, 0);
    TE_SendToAll();
    
    // Format sound
    char sPath[PLATFORM_MAX_PATH];
    FormatEx(sPath, sizeof(sPath), "*/%s", SOUND_FURY);
    
    EmitSoundToAll(sPath, client, SNDCHAN_VOICE, SNDLEVEL_SCREAMING);
    
    timerFuryEffect[client] = CreateTimer(0.5, furyEffectCallback, client, TIMER_FLAG_NO_MAPCHANGE);
    
    timerFury[client] = CreateTimer(FURY_DURATION, furyCallback, client, TIMER_FLAG_NO_MAPCHANGE);

    lastPressedButtons[client] = currentTime;
}

public Action furyCallback(Handle timer, any client)
{
    timerFury[client] = null;
    
    if ( !IsValidAlive(client) || getTeam(client) != CS_TEAM_T || isGhost(client) ) {
    //if ( !IsValidAlive(client) || getTeam(client) != CS_TEAM_T ) {
        return Plugin_Continue;
    }
    
    // Back to first state
    SetEntityRenderMode(client, RENDER_TRANSCOLOR);  
    SetEntityRenderColor(client, 255, 255, 255, 255);
    
    SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", ZOMBIE_SPEED);
    
    if (timerFuryEffect[client] != null) {
        delete timerFuryEffect[client];
    }

    return Plugin_Continue;
}

public Action furyEffectCallback(Handle timer, any client)
{
    timerFuryEffect[client] = null;
    
    if ( !IsValidAlive(client) || getTeam(client) != CS_TEAM_T || isGhost(client) ) {
    //if ( !IsValidAlive(client) || getTeam(client) != CS_TEAM_T ) {
        return Plugin_Continue;
    }
    
    float position[3];
    GetClientAbsOrigin(client, position);
    
    position[2] += 13.0;
        
    TE_SetupBeamRingPoint(position, 10.0, 100.0, fireSprite, haloSprite, 0, 10, 0.3, 30.0, 0.7, view_as<int>({204,0,0,200}), 25, 0);
    TE_SendToAll();
        
    position[2] += 15.0;
    
    TE_SetupBeamRingPoint(position, 10.0, 100.0, fireSprite, haloSprite, 0, 10, 0.3, 30.0, 0.7, view_as<int>({204,0,0,200}), 25, 0);
    TE_SendToAll();
    
    timerFuryEffect[client] = CreateTimer(0.5, furyEffectCallback, client, TIMER_FLAG_NO_MAPCHANGE);

    return Plugin_Continue;
}

public Action TimerNextTank(Handle timer)
{
    timerNextTank = null;
    
    tankReady = true;
}