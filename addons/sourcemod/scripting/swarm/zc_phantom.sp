#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <zombiemod>

public Plugin myinfo =
{
    name = "Zombie Phantom",
    author = "Zombie Swarm Contributors",
    description = "Can be invisible",
    version = "1.0",
    url = "https://github.com/Prefix/zombieswarm"
};

#define SOUND_INVISIBILITY "zombie_mod/invisibility.mp3"

#define INVISIBILITY_DURATION 3.0
#define INVISIBILITY_COOLDOWN 8.0

ZombieClass registeredClass;

float lastPressedButtons[MAXPLAYERS + 1];

float timeleft_countdown[MAXPLAYERS + 1];
float timeleft_cooldown[MAXPLAYERS + 1];

// Timers
Handle timerInvisibility[MAXPLAYERS + 1];
Handle timerCountdown[MAXPLAYERS + 1];
Handle timerCooldown[MAXPLAYERS + 1];

bool hasInvisibility[MAXPLAYERS + 1];

public void OnPluginStart()
{
    // We are registering item
    registeredClass = ZombieClass(
        "Zombie Phantom", // Class name
        "Can be invisible (ATTACK2 button)", // Class description
        "models/player/custom_player/caleon1/mummy/mummy", // Class model
        "", // Arms models
        80, // Class base HP
        12.0, // Class damage
        1.1, // Class speed
        0.8, // Class gravity 
        false // Is class excluded from normal rotation
    );
                        
    HookEvent("player_spawn", eventPlayerSpawn);
}
public void onZCSelected(int client, int classId)
{
    // TODO list
}

public eventPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));

    if ( !IsValidAlive(client) )
        return;
        
    if (timerInvisibility[client] != null) {
        delete timerInvisibility[client];
    }
    if (timerCountdown[client] != null) {
        delete timerCountdown[client];
    }
    
        
    // Back to first state
    hasInvisibility[client] = false;
}

public void OnMapStart()
{
    FakePrecacheSoundEx( SOUND_INVISIBILITY );
    
    // Format sound
    char sPath[PLATFORM_MAX_PATH];
    Format(sPath, sizeof(sPath), "sound/%s", SOUND_INVISIBILITY);
    
    AddFileToDownloadsTable( sPath );
}

public void OnClientPostAdminCheck(int client)
{
    lastPressedButtons[client] = 0.0
    
    SDKHook(client, SDKHook_SetTransmit, onSetTransmit);
    SDKHook(client, SDKHook_OnTakeDamage, onTakeDamage);
}

public void OnClientDisconnect(int client)
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
}

public Action onSetTransmit(int entity, int client) 
{
    if ( !IsValidAlive(entity) || !IsValidAlive(client) ) return Plugin_Continue;
    
    if (entity == client) return Plugin_Continue;
    
    if ( getTeam(entity) != getTeam(client) && getTeam(entity) == CS_TEAM_T && hasInvisibility[entity] )
        return Plugin_Handled; 
    
    return Plugin_Continue;
}

public Action onTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
    if ( !IsValidClient(victim) )
        return Plugin_Continue;
        
    if ( !IsValidClient(attacker) )
        return Plugin_Continue;
        
    if (victim == attacker)
        return Plugin_Continue;
    
    ZMPlayer attackerplayer = ZMPlayer(attacker);
    ZMPlayer victimplayer = ZMPlayer(victim);

    if ( attackerplayer.ZombieClass != registeredClass.ID )
        return Plugin_Continue;
        
    if ( victimplayer.Team != CS_TEAM_CT)
        return Plugin_Continue;

    if ( !hasInvisibility[attacker] )
        return Plugin_Continue;
    
    hasInvisibility[attacker] = false;

    if (timerCountdown[attacker] != null) {
        delete timerCountdown[attacker];
    }
        
    return Plugin_Continue;
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
            
    if (currentTime - (lastPressedButtons[client] + INVISIBILITY_DURATION) < INVISIBILITY_COOLDOWN)
    {
        return;
    }
        
    if (timerInvisibility[client] != null) {
        delete timerInvisibility[client];
    }
    if (timerCountdown[client] != null) {
        delete timerCountdown[client];
    }
    
    fadePlayer(client, 1, 1, {255, 255, 255, 150});
    
    // Make invisible zombie
    hasInvisibility[client] = true;
    
    // Format sound
    char sPath[PLATFORM_MAX_PATH];
    FormatEx(sPath, sizeof(sPath), "*/%s", SOUND_INVISIBILITY);
    
    EmitSoundToAll(sPath, client, SNDCHAN_VOICE, SNDLEVEL_SCREAMING);

    timeleft_countdown[client] = INVISIBILITY_DURATION;
    timerCountdown[client] = CreateTimer(0.1, countdownCallback, client, TIMER_FLAG_NO_MAPCHANGE);
    timerInvisibility[client] = CreateTimer(INVISIBILITY_DURATION, invisibilityCallback, client, TIMER_FLAG_NO_MAPCHANGE);
    
    lastPressedButtons[client] = currentTime;
}

public Action countdownCallback(Handle timer, any client)
{
    timerCountdown[client] = null;
    
    if ( !IsValidAlive(client) || getTeam(client) != CS_TEAM_T || isGhost(client) ) {
        timerCountdown[client] = null;
        return Plugin_Continue;
    } 

    ZMPlayer player = ZMPlayer(client);
    if (timeleft_countdown[client] <= 0.1 || !hasInvisibility[client]) {
        player.OverrideHint = false;
        timerCountdown[client] = null;        
        return Plugin_Continue;
    }
    timeleft_countdown[client] -= 0.1;
    player.OverrideHint = true;
    char hinttext[512];
    Format(hinttext, sizeof(hinttext), "<font color='#00FF00'>Invisible for %.1fs!</font>", timeleft_countdown[client])
    player.OverrideHintText(hinttext);

    timerCountdown[client] = CreateTimer(0.1, countdownCallback, client, TIMER_FLAG_NO_MAPCHANGE);

    return Plugin_Continue;
}

public Action invisibilityCallback(Handle timer, any client)
{
    timerInvisibility[client] = null;
    
    if ( !IsValidAlive(client) || getTeam(client) != CS_TEAM_T || isGhost(client) ) {
        return Plugin_Continue;
    }
    
    // Back to first state
    hasInvisibility[client] = false;
    timeleft_cooldown[client] = INVISIBILITY_COOLDOWN-INVISIBILITY_DURATION;
    timerCooldown[client] = CreateTimer(0.1, cooldownCallback, client, TIMER_FLAG_NO_MAPCHANGE);

    return Plugin_Continue;
}

public Action cooldownCallback(Handle timer, any client)
{
    timerCooldown[client] = null;
    
    if ( !IsValidAlive(client) || getTeam(client) != CS_TEAM_T || isGhost(client) ) {
        timerCooldown[client] = null;
        return Plugin_Continue;
    }
    ZMPlayer player = ZMPlayer(client);
    if (timeleft_cooldown[client] <= 0.1) {
        player.OverrideHint = false;
        timerCooldown[client] = null;        
        return Plugin_Continue;
    }
    timeleft_cooldown[client] -= 0.1;
    player.OverrideHint = true;
    char hinttext[512];
    Format(hinttext, sizeof(hinttext), "<font color='#00FF00'>Ability cooldown for %.1fs!</font>", timeleft_cooldown[client]);
    player.OverrideHintText(hinttext);

    timerCooldown[client] = CreateTimer(0.1, cooldownCallback, client, TIMER_FLAG_NO_MAPCHANGE);

    return Plugin_Continue;
}