#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <zombieswarm>
#include <swarm/utils>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_NAME ZS_PLUGIN_NAME ... " - Zombie Class: Tank"

public Plugin myinfo =
{
    name = PLUGIN_NAME,
    author = ZS_PLUGIN_AUTHOR,
    description = ZS_PLUGIN_DESCRIPTION,
    version = ZS_PLUGIN_VERSION,
    url = ZS_PLUGIN_URL
};

#define SOUND_FURY "swarm/fury.mp3"

ZombieClass registeredClass;
ZombieAbility abilityRage;

Handle timerFury[MAXPLAYERS + 1];
Handle timerFuryEffect[MAXPLAYERS + 1];

int fireSprite, haloSprite;

bool tankAlive;
bool tankReady = true;
Handle timerNextTank;

#define SPAWNTIME 90.0

ConVar zHP, zDamage, zSpeed, zGravity, zExcluded, zCooldown, zDuration;

public void OnPluginStart()
{                  
    HookEvent("player_spawn", eventPlayerSpawn);
    HookEvent("player_death", eventPlayerDeath);
    HookEvent("round_start", eventRoundStart); 
    HookEvent("round_end", eventRoundEnd);
    
    zHP = CreateConVar("zs_tank_hp", "160", "Zombie Tank HP");
    zDamage = CreateConVar("zs_tank_damage","30.0","Zombie Tank done damage");
    zSpeed = CreateConVar("zs_tank_speed","1.15","Zombie Tank speed");
    zGravity = CreateConVar("zs_tank_gravity","0.8","Zombie Tank gravity");
    zExcluded = CreateConVar("zs_tank_excluded","1","1 - Excluded, 0 - Not excluded");
    zCooldown = CreateConVar("zs_tank_cooldown","12.0","Time in seconds for cooldown",_,true,1.0);
    zDuration = CreateConVar("zs_tank_duration","4.0","How long in second Tank using his ability");
    
    AutoExecConfig(true, "zombie.tank", "sourcemod/zombieswarm");
}
public void ZS_OnLoaded() {
    // We are registering zombie
    registeredClass = ZombieClass("tank");
    registeredClass.SetName("Zombie Fury [TANK]", MAX_CLASS_NAME_SIZE);
    registeredClass.SetDesc("Can rage (E button) with Iron skin", MAX_CLASS_DESC_SIZE);
    registeredClass.SetModel("models/player/custom_player/caleon1/l4d2_tank/l4d2_tank", MAX_CLASS_MODEL_SIZE);
    registeredClass.Health = zHP.IntValue;
    registeredClass.Damage = zDamage.FloatValue;
    registeredClass.Speed = zSpeed.FloatValue;
    registeredClass.Gravity = zGravity.FloatValue;
    registeredClass.Excluded = zExcluded.BoolValue;
    // Abilities
    abilityRage = ZombieAbility(registeredClass, "tank_rage");
    abilityRage.Duration = zDuration.FloatValue;
    abilityRage.Cooldown = zCooldown.FloatValue;
    abilityRage.Buttons = IN_USE;
    abilityRage.SetName("Fury", MAX_ABILITY_NAME_SIZE);
    abilityRage.SetDesc("Can rage with Iron skin.", MAX_ABILITY_DESC_SIZE);
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

    PrecacheSound( SOUND_FURY );
    
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
    
    UTIL_PrecacheParticle("firework_crate_ground_low_03");
    UTIL_PrecacheParticle("slime_splash_01");
}

public Action eventPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));

    if ( !UTIL_IsValidAlive(client) )
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

public Action eventPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    int victim = GetClientOfUserId(GetEventInt(event, "userid"));

    if ( !UTIL_IsValidClient(victim) )
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
    
    SDKHook(client, SDKHook_OnTakeDamage, onTakeDamage);
    SDKHook(client, SDKHook_TraceAttack, onTraceAttack);
}

public Action onTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
    if ( !UTIL_IsValidClient(victim) )
        return Plugin_Continue;
        
    if ( !UTIL_IsValidClient(attacker) )
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
    if ( !UTIL_IsValidClient(victim) )
        return Plugin_Continue;
        
    if ( !UTIL_IsValidClient(attacker) )
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
    if (timerFury[client] != null)
        delete timerFury[client];
    
    UTIL_Fade(client, 1, 1, {204, 0, 0, 150});
    
    // Make invisible zombie
    SetEntityRenderMode(client, RENDER_TRANSCOLOR);  
    SetEntityRenderColor(client, 204, 0, 0, 255);
    
    SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", zSpeed.FloatValue);
    
    float position[3];
    GetClientAbsOrigin(client, position);
    
    position[2] += 8.0;
    
    UTIL_CreateAttachParticle(client, "firework_crate_ground_low_03", position, "fwcgl", zDuration.FloatValue);
    
    position[2] += 5.0;
    
    TE_SetupBeamRingPoint(position, 10.0, 100.0, fireSprite, haloSprite, 0, 10, 0.2, 30.0, 0.7, view_as<int>({204,0,0,200}), 25, 0);
    TE_SendToAll();
    
    position[2] += 15.0;
    
    TE_SetupBeamRingPoint(position, 10.0, 100.0, fireSprite, haloSprite, 0, 10, 0.2, 30.0, 0.7, view_as<int>({204,0,0,200}), 25, 0);
    TE_SendToAll();
    
    EmitSoundToAll(SOUND_FURY, client, SNDCHAN_VOICE, SNDLEVEL_SCREAMING);
    
    timerFuryEffect[client] = CreateTimer(0.5, furyEffectCallback, client, TIMER_FLAG_NO_MAPCHANGE);
    
}

public void ZS_OnCooldownStarted(int client, int ability_id) {
    
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
    if (ability.State != stateCooldown)
        return;
        
    
    // Back to first state
    SetEntityRenderMode(client, RENDER_TRANSCOLOR);  
    SetEntityRenderColor(client, 255, 255, 255, 255);
    
    SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", zSpeed.FloatValue);
    
    if (timerFuryEffect[client] != null) {
        delete timerFuryEffect[client];
    }
}

public Action furyEffectCallback(Handle timer, any client)
{
    timerFuryEffect[client] = null;
    
    if ( !UTIL_IsValidAlive(client) || !ZS_IsClientZombie(client) ) {
        return Plugin_Continue;
    }

    ZMPlayer player = ZMPlayer(client);

    if (player.Ghost) {
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