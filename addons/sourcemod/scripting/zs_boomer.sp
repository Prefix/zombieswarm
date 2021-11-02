#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <zombieswarm>
#include <autoexecconfig>
#include <swarm/utils>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_NAME ZS_PLUGIN_NAME ... " - Zombie Class: Boomer"

public Plugin myinfo =
{
    name = PLUGIN_NAME,
    author = ZS_PLUGIN_AUTHOR,
    description = ZS_PLUGIN_DESCRIPTION,
    version = ZS_PLUGIN_VERSION,
    url = ZS_PLUGIN_URL
};

ZombieClass registeredClass;
ZombieAbility abilityVomit;

int fireSprite;
int haloSprite;
int explosionSprite;

#define ABILITY_UNIQUE_EXPLODE "boomer_explosion"
#define ABILITY_NAME "Vomit"
#define ABILITY_DESCRIPTION "Vomit humans"
#define CLASS_DESCRIPTION "Vomits humans and explodes on death"
static const char colors[][]        = {"R", "G", "B", "A"};
int g_iColor[4];
int g_iColorAbility[4];

#define MAX_ABILITY_SOUNDS 4

ConVar zHP, zDamage, zSpeed, zGravity, zAttackSpeed, zExcluded, zExplodeDamage, zRadius, zCooldown, zDuration, zVomitDuration, zVomitDurationDeath;

public void OnPluginStart() {                 
    HookEventEx("player_death", eventPlayerDeath, EventHookMode_Pre);
    
    ZS_StartConfig("zombie.boomer");
    zHP = AutoExecConfig_CreateConVar("zs_boomer_hp", "150", "Zombie Boomer HP");
    zDamage = AutoExecConfig_CreateConVar("zs_boomer_damage","20.0","Zombie Boomer done damage");
    zAttackSpeed = AutoExecConfig_CreateConVar("zs_boomer_attackspeed","1.0","Attack speed scale %. 1.0 = Default (Normal speed)",_,true,0.1);
    zSpeed = AutoExecConfig_CreateConVar("zs_boomer_speed","0.8","Zombie Boomer speed");
    zGravity = AutoExecConfig_CreateConVar("zs_boomer_gravity","0.8","Zombie Boomer gravity");
    zExcluded = AutoExecConfig_CreateConVar("zs_boomer_excluded","0","1 - Excluded, 0 - Not excluded");
    zExplodeDamage = AutoExecConfig_CreateConVar("zs_boomer_explode_damage","30.0","Zombie Boomer damage done then he explode");
    zRadius = AutoExecConfig_CreateConVar("zs_boomer_radius","250.0","Explosion radius");
    zCooldown = AutoExecConfig_CreateConVar("zs_boomer_cooldown","8.0","Time in seconds for cooldown",_,true,1.0);
    zDuration = AutoExecConfig_CreateConVar("zs_boomer_duration","2.0","How long in second Boomer using his ability");
    zVomitDuration = AutoExecConfig_CreateConVar("zs_boomer_vomit_duration_ability","3.0","For how many seconds humans are blinded when used ability");
    zVomitDurationDeath = AutoExecConfig_CreateConVar("zs_boomer_vomit_duration_death","4.0","For how many seconds humans are blinded when zombie died");
    
    ConVar CVar;
    char sBuffer[16];
    HookConVarChange((CVar = AutoExecConfig_CreateConVar("zs_boomer_vomit_color_ability", "0 133 33 210","Vomit color when blinded [Ability]. Set by RGBA (0 - 255).")), CVarChange_Ability_Color);
    CVar.GetString(sBuffer, sizeof(sBuffer));
    String2Color(sBuffer, true);

    HookConVarChange((CVar = AutoExecConfig_CreateConVar("zs_boomer_vomit_color_death", "0 133 33 210","Vomit color when blinded [Death]. Set by RGBA (0 - 255).")), CVarChange_Color);
    CVar.GetString(sBuffer, sizeof(sBuffer));
    String2Color(sBuffer);
    ZS_EndConfig();
}



public void ZS_OnLoaded() {

    // We are registering zombie
    registeredClass = ZombieClass("boomer");
    //registeredClass.SetName("Boomer", MAX_CLASS_NAME_SIZE);
    //registeredClass.SetDesc(CLASS_DESCRIPTION, MAX_CLASS_DESC_SIZE);
    registeredClass.SetModel("models/player/custom_player/borodatm.ru/l4d2/boomer", MAX_CLASS_MODEL_SIZE);
    registeredClass.Health = zHP.IntValue;
    registeredClass.Damage = zDamage.FloatValue;
    registeredClass.Speed = zSpeed.FloatValue;
    registeredClass.AttackSpeed = zAttackSpeed.FloatValue;
    registeredClass.Gravity = zGravity.FloatValue;
    registeredClass.Excluded = zExcluded.BoolValue;

    abilityVomit = ZombieAbility(registeredClass, ABILITY_UNIQUE_EXPLODE);
    //abilityVomit.SetName(ABILITY_NAME, MAX_ABILITY_NAME_SIZE);
    //abilityVomit.SetDesc(ABILITY_DESCRIPTION, MAX_ABILITY_DESC_SIZE);
    abilityVomit.Duration = zDuration.FloatValue;
    abilityVomit.Cooldown = zCooldown.FloatValue;
    abilityVomit.Buttons = IN_USE;
    // TODO ADD properties for explosion. Range, Damage etc.
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

    PrecacheSound( "swarm/skills/boomer_ability_1.mp3" ,true);
    AddFileToDownloadsTable( "sound/swarm/skills/boomer_ability_1.mp3" );
    PrecacheSound( "swarm/skills/boomer_ability_2.mp3" ,true);
    AddFileToDownloadsTable( "sound/swarm/skills/boomer_ability_2.mp3" );
    PrecacheSound( "swarm/skills/boomer_ability_3.mp3" ,true);
    AddFileToDownloadsTable( "sound/swarm/skills/boomer_ability_3.mp3" );
    PrecacheSound( "swarm/skills/boomer_ability_4.mp3" ,true);
    AddFileToDownloadsTable( "sound/swarm/skills/boomer_ability_4.mp3" );

    PrecacheSound( "swarm/skills/boomer_death_ability_1.mp3" ,true);
    AddFileToDownloadsTable( "sound/swarm/skills/boomer_death_ability_1.mp3" );
    PrecacheSound( "swarm/skills/boomer_death_ability_2.mp3" ,true);
    AddFileToDownloadsTable( "sound/swarm/skills/boomer_death_ability_2.mp3" );
    PrecacheModel("models/player/custom_player/borodatm.ru/l4d2/boomer.mdl");
}

public Action eventPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    int victim = GetClientOfUserId(GetEventInt(event,"userid"));
    
    if ( !UTIL_IsValidClient(victim) )
        return Plugin_Continue;

    ZMPlayer player = ZMPlayer(victim);

    if ( player.ZombieClass != registeredClass.ID )
        return Plugin_Continue;

    if ( player.Team != CS_TEAM_T )
        return Plugin_Continue;
    
    explodePlayer(victim);
    
    return Plugin_Continue;
}

stock void explodePlayer(int client)
{
    float location[3];
    GetClientAbsOrigin(client, location);
    
    float targetOrigin[3], distanceBetween;
    for(int enemy = 1; enemy <= MaxClients; enemy++) 
    {
        if (!UTIL_IsValidAlive(enemy) || ZS_IsClientZombie(enemy))
            continue;

        GetClientAbsOrigin ( enemy, targetOrigin );
        distanceBetween = GetVectorDistance ( targetOrigin, location );
        
        if (( distanceBetween <= zRadius.FloatValue)) {
            SDKHooks_TakeDamage(enemy, client, client, zExplodeDamage.FloatValue, DMG_BLAST, -1, NULL_VECTOR, NULL_VECTOR);
            
            int seconds = zVomitDurationDeath.IntValue;
            UTIL_Fade(enemy, seconds, seconds+1, g_iColor);
            UTIL_ShakeScreen(enemy);
        }
    }
            
    explode1(location);
    explode2(location);
}

public void explode1(float vec[3])
{
    int color[4] = {188,220,255,200};
    
    boomSound("swarm/skills/boomer_death_ability_1.mp3", vec);
    
    TE_SetupExplosion(vec, explosionSprite, 10.0, 1, 0, 400, 5000);
    TE_SendToAll();
    TE_SetupBeamRingPoint(vec, 10.0, 500.0, fireSprite, haloSprite, 0, 10, 0.6, 10.0, 0.5, color, 10, 0);
    TE_SendToAll();
}

public void explode2(float vec[3])
{
    vec[2] += 10;
    
    boomSound("swarm/skills/boomer_death_ability_2.mp3", vec);
    
    TE_SetupExplosion(vec, explosionSprite, 10.0, 1, 0, 400, 5000);
    TE_SendToAll();
}

public void boomSound(const char[] sound, const float origin[3])
{
    EmitSoundToAll(sound, SOUND_FROM_WORLD,SNDCHAN_AUTO,SNDLEVEL_NORMAL,SND_NOFLAGS,SNDVOL_NORMAL,SNDPITCH_NORMAL,-1,origin,NULL_VECTOR,true,0.0);
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
    float location[3];
    GetClientAbsOrigin(client, location);
    
    float targetOrigin[3], distanceBetween;
    for(int enemy = 1; enemy <= MaxClients; enemy++) 
    {
        if (!UTIL_IsValidAlive(enemy) || ZS_IsClientZombie(enemy))
            continue;

        GetClientAbsOrigin ( enemy, targetOrigin );
        distanceBetween = GetVectorDistance ( targetOrigin, location );
        
        if (( distanceBetween <= zRadius.FloatValue)) {
            int seconds = zVomitDuration.IntValue;
            UTIL_Fade(enemy, seconds, seconds+1, g_iColorAbility);
            UTIL_ShakeScreen(enemy);
        }
    }
    GetClientAbsOrigin(client, location);
    int randomnumber = GetRandomInt(1, MAX_ABILITY_SOUNDS);
    char randomsound[PLATFORM_MAX_PATH];
    Format(randomsound, sizeof(randomsound), "swarm/skills/boomer_ability_%i.mp3", randomnumber);
    boomSound(randomsound, location);
}

public void CVarChange_Color(ConVar CVar, const char[] oldValue, const char[] newValue)
{
    char sBuffer[16];
    CVar.GetString(sBuffer, sizeof(sBuffer));
    String2Color(sBuffer);
}

public void CVarChange_Ability_Color(ConVar CVar, const char[] oldValue, const char[] newValue)
{
    char sBuffer[16];
    CVar.GetString(sBuffer, sizeof(sBuffer));
    String2Color(sBuffer, true);
}


void String2Color(const char[] str, bool ability = false)
{
    static char Splitter[4][16];
    if(ExplodeString(str, " ", Splitter, sizeof(Splitter), sizeof(Splitter[])) > 3)
    {
        for(int i; i < 4; i++)
        {
            if(String_IsNumeric(Splitter[i]))
            {
                if (ability) {
                    g_iColorAbility[i] = StringToInt(Splitter[i]);
                    if(g_iColorAbility[i] < 0 || g_iColorAbility[i] > 255)
                    {
                        PrintToServer("[Boomer] ability warning: incorrect '%s' color parameter (%i)! Correct: 0 - 255.", colors[i], g_iColorAbility[i]);
                        g_iColorAbility[i] = 255;
                    }
                } else {
                    g_iColor[i] = StringToInt(Splitter[i]);
                    if(g_iColor[i] < 0 || g_iColor[i] > 255)
                    {
                        PrintToServer("[Boomer] death warning: incorrect '%s' color parameter (%i)! Correct: 0 - 255.", colors[i], g_iColor[i]);
                        g_iColor[i] = 255;
                    }
                }
            }
            else
            {
                if (ability) g_iColorAbility[i] = 255;
                else g_iColor[i] = 255;
                PrintToServer("[Boomer] %s warning: incorrect '%s' color parameter ('%s' is not numeric)!", ability ? "Ability" : "Death" , colors[i], Splitter[i]);
            }
        }
    }
    else PrintToServer("[Boomer] %s warning: not all parameters of color are specified ('%s' < 'R G B A')!",  ability ? "Ability" : "Death", str);
}

bool String_IsNumeric(const char[] str)
{
    int x, numbersFound;

    while (str[x] != '\0')
    {
        if(IsCharNumeric(str[x])) numbersFound++;
        else return false;
        x++;
    }

    return view_as<bool>(numbersFound);
}