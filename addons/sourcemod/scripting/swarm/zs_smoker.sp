#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <zombieswarm>
#include <swarm/utils>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_NAME ZS_PLUGIN_NAME ... " - Zombie Class: Smoker"
#define ABILITY_UNIQUE "smoker_pull"

public Plugin myinfo =
{
    name = PLUGIN_NAME,
    author = ZS_PLUGIN_AUTHOR,
    description = ZS_PLUGIN_DESCRIPTION,
    version = ZS_PLUGIN_VERSION,
    url = ZS_PLUGIN_URL
};

#define SOUND_TONGUE "swarm/skills/smoker_ability_1.mp3"

ZombieClass registeredClass;
ZombieAbility abilityPull;

int LaserCache;

Handle SmokerTimer[MAXPLAYERS + 1] = {null, ...};
int pullTarget[MAXPLAYERS + 1];

ConVar zHP, zDamage, zSpeed, zGravity, zExcluded, zCooldown, zDuration, zAttackSpeed;

public void OnPluginStart() {                   
    HookEvent("player_spawn", eventPlayerSpawn);
    HookEvent("player_death", eventPlayerDeath);
    HookEvent("round_start", eventRoundStart, EventHookMode_Pre);
    HookEvent("round_end", eventRoundEnd);
    
    zHP = CreateConVar("zs_smoker_hp", "130", "Zombie Smoker HP");
    zDamage = CreateConVar("zs_smoker_damage","15.0","Zombie Smoker done damage");
    zAttackSpeed = CreateConVar("zs_smoker_attackspeed","1.0","Attack speed scale %. 1.0 = Default (Normal speed)",_,true,0.1);
    zSpeed = CreateConVar("zs_smoker_speed","0.9","Zombie Smoker speed");
    zGravity = CreateConVar("zs_smoker_gravity","0.8","Zombie Smoker gravity");
    zExcluded = CreateConVar("zs_smoker_excluded","0","1 - Excluded, 0 - Not excluded");
    zCooldown = CreateConVar("zs_smoker_cooldown","4.0","Time in seconds for cooldown",_,true,1.0);
    zDuration = CreateConVar("zs_smoker_duration","30.0","Time in seconds for maximum pulling duration",_,true,1.0);
    
    AutoExecConfig(true, "zombie.smoker", "sourcemod/zombieswarm");
}
public void ZS_OnLoaded() {
    // We are registering zombie
    registeredClass = ZombieClass("smoker");
    //registeredClass.SetName("Smoker", MAX_CLASS_NAME_SIZE);
    //registeredClass.SetDesc("Can drag other people (E button)", MAX_CLASS_DESC_SIZE);
    registeredClass.SetModel("models/player/custom_player/borodatm.ru/l4d2/smoker", MAX_CLASS_MODEL_SIZE);
    registeredClass.Health = zHP.IntValue;
    registeredClass.Damage = zDamage.FloatValue;
    registeredClass.AttackSpeed = zAttackSpeed.FloatValue;
    registeredClass.Speed = zSpeed.FloatValue;
    registeredClass.Gravity = zGravity.FloatValue;
    registeredClass.Excluded = zExcluded.BoolValue;
    //
    abilityPull = ZombieAbility(registeredClass, ABILITY_UNIQUE);
    abilityPull.Duration = zDuration.FloatValue;
    abilityPull.Cooldown = zCooldown.FloatValue;
    abilityPull.Buttons = IN_USE;
    //abilityPull.SetName("Pull", MAX_ABILITY_NAME_SIZE);
    //abilityPull.SetDesc("Can pull humans with tongue.", MAX_ABILITY_DESC_SIZE);
}

public void OnClientPutInServer(int client)
{
    if ( UTIL_IsValidClient(client) )
    {
        pullTarget[client] = 0;
    }
}
public void OnClientDisconnect(int client)
{
    if ( IsClientInGame(client) )
    {
        pullTarget[client] = 0;
    }
}

public Action eventRoundStart(Event event, const char[] name, bool dontBroadcast) {
    KillBeamTimer();
}

public Action eventRoundEnd(Event event, const char[] name, bool dontBroadcast) {
    KillBeamTimer();
}

public void KillBeamTimer() {

    for (int i = 1; i <= MaxClients; i++)
    {
        if (UTIL_IsValidClient(i))
        {
            if (SmokerTimer[i] != null)
            {
                delete SmokerTimer[i];
            }
            pullTarget[i] = 0;
        }
    }
}

public bool IsBeingPulled(int client) {
    
    bool found = false;
    
    for (int i = 1; i <= MaxClients; i++)
    {
        if (UTIL_IsValidClient(i))
        {
            if (SmokerTimer[i] != null)
            {
                int target = pullTarget[i];
                if (target == client) {
                    found = true;
                    break;
                }
            }
        }
    }
    return found;
}

public int WhoPulling(int client) {
    
    int found = 0;
    
    for (int i = 1; i <= MaxClients; i++)
    {
        if (UTIL_IsValidClient(i))
        {
            if (SmokerTimer[i] != null)
            {
                int target = pullTarget[i];
                if (target == client) {
                    found = target;
                    break;
                }
            }
        }
    }
    return found;
}

public Action eventPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));

    if ( !UTIL_IsValidAlive(client) )
        return Plugin_Continue;
        
    if (SmokerTimer[client] != null) {
        delete SmokerTimer[client];
    }
    pullTarget[client] = 0;
    return Plugin_Continue;
}
public Action eventPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
    int victim   = GetClientOfUserId(GetEventInt(event, "userid"));
    
    if ( !UTIL_IsValidClient(attacker) )
        return Plugin_Continue;
        
    if ( !UTIL_IsValidClient(victim) )
        return Plugin_Continue;

    ZMPlayer VictimPlayer = ZMPlayer(victim);
    //ZMPlayer AttackerPlayer = ZMPlayer(attacker);
        
    if ( VictimPlayer.Ghost )
        return Plugin_Continue;
        
    if ( VictimPlayer.Team != CS_TEAM_T)
        return Plugin_Continue;
        
    if ( VictimPlayer.ZombieClass != registeredClass.ID )
        return Plugin_Continue;
    
    if (SmokerTimer[victim] != null) {
        delete SmokerTimer[victim];
        SmokerTimer[victim] = null;
    }
    
    pullTarget[victim] = 0;
    
    float fadestart = 10.0; 
    float fadeend = 15.0; 
    
    float Origin[3];
    GetClientAbsOrigin( victim, Origin);

    int SmokeIndex = CreateEntityByName("env_particlesmokegrenade"); 
    if (SmokeIndex != -1) 
    { 
        SetEntProp(SmokeIndex, Prop_Send, "m_CurrentStage", 1); 
        SetEntPropFloat(SmokeIndex, Prop_Send, "m_FadeStartTime", fadestart); 
        SetEntPropFloat(SmokeIndex, Prop_Send, "m_FadeEndTime", fadeend); 
        DispatchSpawn(SmokeIndex); 
        ActivateEntity(SmokeIndex); 
        TeleportEntity( SmokeIndex, Origin, NULL_VECTOR, NULL_VECTOR); 
    }

    return Plugin_Continue;
}

public Action BeamTimer(Handle timer, any client)
{
    SmokerTimer[client] = null;
    
    int target = pullTarget[client];
    
    if ( !UTIL_IsValidAlive(client) )
        return Plugin_Handled;
    
    if (!UTIL_IsClientInTargetView(client, target)) {
        pullTarget[client] = 0;
        ZMPlayer player = ZMPlayer(client);
        int ability_id = player.GetAbilityByUnique(ABILITY_UNIQUE);
        int ability_index = player.GetAbilityByID(ability_id);
        if (ability_index > -1 && ability_id > -1) {
            PlayerAbility playerab = view_as<PlayerAbility>(ability_id);
            playerab.AbilityFinished();
        } 
        return Plugin_Handled;
    }

    float distancebetween, fl_Velocity[3], targetorigin[3], Origin[3], targetorigin2[3], Origin2[3];
    
    GetClientAbsOrigin ( client, Origin );
    GetClientAbsOrigin ( target, targetorigin );
    
    /*Origin2[0] = Origin[0];
    Origin2[1] = Origin[1];
    Origin2[2] = Origin[2] + 50.0;
    
    targetorigin2[0] = targetorigin[0];
    targetorigin2[1] = targetorigin[1];
    targetorigin2[2] = targetorigin[2] + 50.0;*/
    
    distancebetween = GetVectorDistance ( targetorigin, Origin );
    
    
    if ( distancebetween > 70.0 ) {
        // Original was 170 after all
        float fl_Time = distancebetween / 170.0;

        fl_Velocity[0] = (Origin[0] - targetorigin[0]) / fl_Time;
        fl_Velocity[1] = (Origin[1] - targetorigin[1]) / fl_Time;
        fl_Velocity[2] = (Origin[2] - targetorigin[2]) / fl_Time;
    } else {
        fl_Velocity[0] = 0.0;
        fl_Velocity[1] = 0.0;
        fl_Velocity[2] = 0.0;
    }
    
    TeleportEntity( target, NULL_VECTOR, NULL_VECTOR, fl_Velocity);
    
    int BeamColor[4] = {25, 25, 25, 200};
    
    TE_SetupBeamPoints( Origin2, targetorigin2, LaserCache, 0, 0, 0, 0.1, 5.0, 5.0, 0, 0.0, BeamColor, 0);
    TE_SendToAll();
    
    SmokerTimer[client] = CreateTimer(0.1, BeamTimer, client);
    
    return Plugin_Handled;
}


public void OnMapStart()
{
    PrecacheSound( SOUND_TONGUE );
    LaserCache = PrecacheModel("materials/sprites/laserbeam.vmt");
    
    // Format sound
    char sPath[PLATFORM_MAX_PATH];
    Format(sPath, sizeof(sPath), "sound/%s", SOUND_TONGUE);
    
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
    
    int target = WhoPulling(client);
    if(UTIL_IsValidClient(target) && target != client) {
        return;
    }
        
    target = GetClientAimTarget(client, true);

    if ( !UTIL_IsValidAlive(target) ) 
        return;
    if (!UTIL_IsClientInTargetView(client, target))
        return;
    if (IsBeingPulled(target) && WhoPulling(target) != client)
        return;
        
    ZMPlayer TargetPlayer = ZMPlayer(target);
    if (target == client || TargetPlayer.Team == player.Team)
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
    
    int target = WhoPulling(client);
    if(UTIL_IsValidClient(target) && target != client) {
        return;
    }
        
    target = GetClientAimTarget(client, true);

    if ( !UTIL_IsValidAlive(target) ) 
        return;
    if (!UTIL_IsClientInTargetView(client, target))
        return;
    if (IsBeingPulled(target) && WhoPulling(target) != client)
        return;
        
    ZMPlayer TargetPlayer = ZMPlayer(target);
    if (target == client || TargetPlayer.Team == player.Team)
        return;
        
    SmokerTimer[client] = CreateTimer( 0.1, BeamTimer, client);

    EmitSoundToAll(SOUND_TONGUE, client, SNDCHAN_VOICE, SNDLEVEL_SCREAMING);
        
    pullTarget[client] = target; 
}

public void ZS_OnAbilityButtonReleased(int client, int ability_id) {
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
    ability.AbilityFinished();
    
    if (SmokerTimer[client] != null) {
        delete SmokerTimer[client];
        SmokerTimer[client] = null;
    }
    pullTarget[client] = 0;
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
        
    if (SmokerTimer[client] != null) {
        delete SmokerTimer[client];
        SmokerTimer[client] = null;
    }
    pullTarget[client] = 0;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float velocity[3], float angles[3], int &weapon, int &subtype, int &cmdNum, int &tickCount, int &seed, int mouse[2])
{
    if ( !UTIL_IsValidAlive(client) )
        return Plugin_Continue;

    ZMPlayer player = ZMPlayer(client);
        
    if ( player.Ghost )
        return Plugin_Continue;
    
    // If not CT go away.
    if (player.Team != CS_TEAM_CT)
        return Plugin_Continue;
    
    // Prevent CT From running away while being pulled away
    if(IsBeingPulled(client)) {
        if(buttons & IN_FORWARD || buttons & IN_BACK || buttons & IN_MOVELEFT || buttons & IN_MOVERIGHT || buttons & IN_WALK || buttons & IN_JUMP || buttons & IN_DUCK) {
            buttons &= ~IN_FORWARD;
            buttons &= ~IN_BACK;
            buttons &= ~IN_MOVELEFT;
            buttons &= ~IN_MOVERIGHT;
            buttons &= ~IN_WALK;
            buttons &= ~IN_JUMP;
            buttons &= ~IN_DUCK;
            return Plugin_Changed;
        }
    }

    return Plugin_Continue;
}

public bool TraceRayNoPlayers( int entity, int mask, any data ) {

    if( entity == data || ( entity >= 1 && entity <= MaxClients ) ) {
        return false;
    }
    return true;
}  

public bool TraceEntityFilterHull(int entity, int contentsMask, any client)
{
    return entity != client;
} 

public bool TraceEntityFilterPlayer(int entity, int contentsMask, any client)
{
    if(UTIL_IsValidClient(client) && entity == client)
        return true;
    return false;
} 

public bool TraceEntityFilterRay(int entity, int contentsMask)
{
    return entity > MaxClients;
}
