#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <zombieswarm>

public Plugin myinfo =
{
    name = "Zombie Smoker",
    author = "Zombie Swarm Contributors",
    description = "Has drag and makes smoke after death",
    version = "1.0",
    url = "https://github.com/Prefix/zombieswarm"
};

#define SOUND_TONGUE "zombie_mod/smoker_tongue.mp3"
#define ABILITY_COOLDOWN 4.0 // Ability cooldown in seconds

ZombieClass registeredClass;

float g_LastTime[MAXPLAYERS + 1] = {0.0, ...};
int g_fLastButtons[MAXPLAYERS + 1 ], LaserCache;

Handle SmokerTimer[MAXPLAYERS + 1] = {null, ...};
int pullTarget[MAXPLAYERS + 1];

public void OnPluginStart()
{
    // We are registering zombie
    registeredClass = ZombieClass();
    registeredClass.SetName("Zombie Smoker", MAX_CLASS_NAME_SIZE);
    registeredClass.SetDesc("Can drag other people (ATTACK2 button)", MAX_CLASS_DESC_SIZE);
    registeredClass.SetModel("models/player/custom_player/borodatm.ru/l4d2/smoker", MAX_CLASS_MODEL_SIZE);
    registeredClass.Health = 80;
    registeredClass.Damage = 15.0;
    registeredClass.Speed = 1.0;
    registeredClass.Gravity = 0.8;
    registeredClass.Excluded = false;
                        
    HookEvent("player_spawn", eventPlayerSpawn);
    HookEvent("player_death", eventPlayerDeath);
    HookEvent("round_start", eventRoundStart, EventHookMode_Pre);
    HookEvent("round_end", eventRoundEnd);
}
public void onZCSelected(int client, int classId)
{
    // TODO list
}

public void OnClientPutInServer(int client)
{
    if ( IsValidClient(client) )
    {
        pullTarget[client] = 0;
        g_LastTime[client] = 0.0;
    }
}
public void OnClientDisconnect(int client)
{
    if ( IsClientInGame(client) )
    {
        pullTarget[client] = 0;
        g_fLastButtons[client] = 0;
        g_LastTime[client] = 0.0;
    }
}

public Action eventRoundStart(Event event, const char[] name, bool dontBroadcast) {
    KillBeamTimer();
}

public Action eventRoundEnd(Event event, const char[] name, bool dontBroadcast) {
    KillBeamTimer();
}

public KillBeamTimer() {

    for (new i = 1; i <= MaxClients; i++)
    {
        if (IsValidClient(i))
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
    
    for (new i = 1; i <= MaxClients; i++)
    {
        if (IsValidClient(i))
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
    
    for (new i = 1; i <= MaxClients; i++)
    {
        if (IsValidClient(i))
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

public eventPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));

    if ( !IsValidAlive(client) )
        return;
        
    if (SmokerTimer[client] != null) {
        delete SmokerTimer[client];
    }
    pullTarget[client] = 0;
}
public Action eventPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
    int victim   = GetClientOfUserId(GetEventInt(event, "userid"));
    
    if ( !IsValidClient(attacker) )
        return Plugin_Continue;
        
    if ( !IsValidClient(victim) )
        return Plugin_Continue;

    ZMPlayer VictimPlayer = ZMPlayer(victim);
    //ZMPlayer AttackerPlayer = ZMPlayer(attacker);
        
    if ( VictimPlayer.Ghost )
        return Plugin_Continue;
        
    if ( VictimPlayer.Team != CS_TEAM_T)
        return Plugin_Continue;
        
    if ( VictimPlayer.ZombieClass != registeredClass.ID )
        return Plugin_Continue;
    
    if (SmokerTimer[victim] != null)
        delete SmokerTimer[victim];
    
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
    
    if ( !IsValidAlive(client) )
        return Plugin_Handled;
    
    if (!IsClientInTargetView(client, target)) {
        pullTarget[client] = 0;
        
        return Plugin_Handled;
    }

    float distancebetween, fl_Velocity[3], targetorigin[3], Origin[3], targetorigin2[3], Origin2[3];
    
    GetClientAbsOrigin ( client, Origin );
    GetClientAbsOrigin ( target, targetorigin );
    
    Origin2[0] = Origin[0];
    Origin2[1] = Origin[1];
    Origin2[2] = Origin[2] + 50.0;
    
    targetorigin2[0] = targetorigin[0];
    targetorigin2[1] = targetorigin[1];
    targetorigin2[2] = targetorigin[2] + 50.0;
    
    distancebetween = GetVectorDistance ( targetorigin, Origin );
    
    if ( distancebetween > 70.0 ) {
        float fl_Time = distancebetween / 220.0;

        fl_Velocity[0] = (Origin[0] - targetorigin[0]) / fl_Time;
        fl_Velocity[1] = (Origin[1] - targetorigin[1]) / fl_Time;
        fl_Velocity[2] = (Origin[2] - targetorigin[2]) / fl_Time;
    } else {
        fl_Velocity[0] = 0.0
        fl_Velocity[1] = 0.0
        fl_Velocity[2] = 0.0
    }
    
    TeleportEntity( target, NULL_VECTOR, NULL_VECTOR, fl_Velocity);
    
    int BeamColor[4] = {25, 25, 25, 200}
    
    TE_SetupBeamPoints( Origin2, targetorigin2, LaserCache, 0, 0, 0, 0.1, 5.0, 5.0, 0, 0.0, BeamColor, 0);
    TE_SendToAll();
    
    SmokerTimer[client] = CreateTimer(0.1, BeamTimer, client);
    
    return Plugin_Handled;
}


public void OnMapStart()
{
    FakePrecacheSoundEx( SOUND_TONGUE );
    LaserCache = PrecacheModel("materials/sprites/laserbeam.vmt");
    
    // Format sound
    char sPath[PLATFORM_MAX_PATH];
    Format(sPath, sizeof(sPath), "sound/%s", SOUND_TONGUE);
    
    AddFileToDownloadsTable( sPath );
    
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float velocity[3], float angles[3], int &weapon, int &subtype, int &cmdNum, int &tickCount, int &seed, int mouse[2])
{
    if ( !IsValidAlive(client) )
        return Plugin_Continue;

    ZMPlayer player = ZMPlayer(client);
        
    if ( player.Ghost )
        return Plugin_Continue;
    
    // If not CT and not T go away.
    if (player.Team != CS_TEAM_CT && player.Team != CS_TEAM_T)
        return Plugin_Continue;
    
    // Prevent CT From running away while being pulled away
    if(IsBeingPulled(client) && player.Team == CS_TEAM_CT) {
        if(buttons & IN_FORWARD || buttons & IN_BACK || buttons & IN_LEFT || buttons & IN_RIGHT || buttons & IN_WALK || buttons & IN_JUMP || buttons & IN_DUCK) {
            buttons &= ~IN_FORWARD;
            buttons &= ~IN_BACK;
            buttons &= ~IN_LEFT;
            buttons &= ~IN_RIGHT;
            buttons &= ~IN_WALK;
            buttons &= ~IN_JUMP;
            buttons &= ~IN_DUCK;
            return Plugin_Changed;
        }
        return Plugin_Continue;
    }
        
    if ( player.ZombieClass != registeredClass.ID )
        return Plugin_Continue;

    if ( player.Team == CS_TEAM_CT )
        return Plugin_Continue;
        
    // OnButtonRelease
    if ((player.LastButtons & IN_ATTACK2) && !(buttons & IN_ATTACK2)) {
        if (SmokerTimer[client] != null)
            delete SmokerTimer[client];
        pullTarget[client] = 0;
    }
    
    return Plugin_Continue;
}

public void onZRightClick(int client, int class, int buttons)
{
    if ( !IsValidAlive(client) )
        return;

    ZMPlayer player = ZMPlayer(client);
        
    if ( player.Ghost )
        return;
    if ( player.Team != CS_TEAM_T )
        return;
    if ( player.ZombieClass != registeredClass.ID )
        return;
        
    // OnButtonPress
    if (!(player.LastButtons & IN_ATTACK2) && (buttons & IN_ATTACK2)) {
        float currentTime = GetGameTime();
        
        if (currentTime - g_LastTime[client] < ABILITY_COOLDOWN)
        {
            return;
        }
        
        int target = WhoPulling(client);
        if(IsValidClient(target) && target != client) {
            return;
        }
        
        target = GetClientAimTarget(client, true);

        if ( !IsValidAlive(target) ) 
            return;
        if (!IsClientInTargetView(client, target))
            return;
        if (IsBeingPulled(target) && WhoPulling(target) != client) 
            return;
        ZMPlayer TargetPlayer = ZMPlayer(target);
        if (target == client || TargetPlayer.Team == player.Team)
            return;
    
        SmokerTimer[client] = CreateTimer( 0.1, BeamTimer, client);
        
        char sPath[PLATFORM_MAX_PATH];
        FormatEx(sPath, sizeof(sPath), "*/%s", SOUND_TONGUE);
        
        EmitSoundToAll(sPath, client, SNDCHAN_VOICE, SNDLEVEL_SCREAMING);
        
        g_LastTime[client] = currentTime;
        pullTarget[client] = target;
    }
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
    if(IsValidClient(client) && entity == client)
        return true;
    return false;
} 

public bool TraceEntityFilterRay(int entity, int contentsMask)
{
    return entity > MaxClients;
}
