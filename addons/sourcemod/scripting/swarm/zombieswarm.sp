#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <zombieswarm>
#include <gum>
#include <cstrike>
#include <colorvariables>
#include <overlays>
#include <swarm/utils>

#pragma semicolon 1
#pragma newdecls required

// Globals
#include "swarm/core/defines.sp"
#include "swarm/core/enums.sp"
#include "swarm/core/globals.sp"
#include "swarm/core/natives.sp"

public Plugin myinfo =
{
    name = ZS_PLUGIN_NAME,
    author = ZS_PLUGIN_AUTHOR,
    description = ZS_PLUGIN_DESCRIPTION,
    version = ZS_PLUGIN_VERSION,
    url = ZS_PLUGIN_URL
};

public void OnPluginStart()
{   
    g_cRespawnTimeZ = CreateConVar("zm_respawn_time_t", "3.0", "Vip players respawn time after team join or death");
    g_cRespawnTimeZVip = CreateConVar("zm_respawn_time_t_vip", "3.0", "Vip players respawn time after team join or death");
    g_cRespawnTimeS = CreateConVar("zm_respawn_time_ct", "60.0", "Players respawn time after team join or death");
    g_cRespawnTimeSVip = CreateConVar("zm_respawn_time_ct_vip", "55.0", "Vip players respawn time after team join or death");
    g_cRoundStartZombies = CreateConVar("zm_round_start_zombies", "5", "Round start zombies");
    g_cRoundKillsTeamJoinHumans = CreateConVar("zm_round_kills_teamjoin_humans", "25", "Human can join team after he is connected depends on round kills");
    
    // Added, but disabled by default
    g_cFog = CreateConVar("zm_env_fog", "0", "1 - Enable fog, 0 - Disable",_,true,0.0,true,1.0);
    g_cFogDensity = CreateConVar("zm_env_fogdensity", "0.65", "Toggle the density of the fog effects", _ , true, 0.0, true, 1.0);
    g_cFogStartDist = CreateConVar("zm_env_fogstart", "0", "Toggle how far away the fog starts", _ , true, 0.0, true, 8000.0);
    g_cFogEndDist = CreateConVar("zm_env_fogend", "500", "Toggle how far away the fog is at its peak", _ , true, 0.0, true, 8000.0);
    g_cFogColor = CreateConVar("zm_env_fogcolor", "200 200 200", "Modify the color of the fog" );
    g_cFogZPlane = CreateConVar("zm_env_zplane", "8000", "Change the Z clipping plane", _ , true, 0.0, true, 8000.0);
    // End of Fog CVARS
    g_cCountDown = CreateConVar("zm_countdown", "10", "Time then zombies will take class",_,true,1.0,true,10.0);
    g_cOverlayEnable = CreateConVar("zm_overlay_enable","1","1 - Enable, 0 - Disable",_,true,0.0,true,1.0);
    g_cOverlayCTWin = CreateConVar("zm_overlay_humans_win","overlays/swarm/humans_win","Show overlay then humans win");
    g_cOverlayTWin = CreateConVar("zm_overlay_zombies_win","overlays/swarm/zombies_win","Show overlay then zombies win");
    g_cHumanGravity = CreateConVar("zm_human_gravity","0.8","Gravity for humans. 1.0 - default");
    
    g_aZombieClass = new ArrayList(view_as<int>(g_eZombieClass));
    
    HookConVarChange(g_cFog, OnConVarChange);
    
    HookEvent("player_spawn", eventPlayerSpawn);
    HookEvent("round_start", eventRoundStartNoCopy, EventHookMode_PostNoCopy);
    HookEvent("round_freeze_end", eventRoundFreezeEnd, EventHookMode_Post);
    HookEvent("cs_win_panel_round", eventWinPanelRound, EventHookMode_Pre);
    HookEvent("player_team", eventTeamChange, EventHookMode_Pre);
    HookEvent("player_death", eventPlayerDeath);
    HookEvent("round_end", eventRoundEnd);
    
    AddCommandListener( blockKill, "kill");
    AddCommandListener( blockKill, "spectate");
    AddCommandListener( blockKill, "explode");
    AddCommandListener( joinTeam, "jointeam");
    
    g_iCollisionOffset = FindSendPropInfo("CBaseEntity", "m_CollisionGroup");
    
    g_cAlpha = FindConVar("sv_disable_immunity_alpha");
    
    if(g_cAlpha != null) SetConVarInt(g_cAlpha, 1);
    
    // Configs
    BuildPath(Path_SM, g_sDownloadFilesPath, sizeof(g_sDownloadFilesPath), "configs/swarm/zm_downloads.txt");
    AutoExecConfig(true, "zombieswarm", "sourcemod/zombieswarm");
    CreateConVar("sm_zombieswarm_version", ZS_PLUGIN_VERSION, ZS_PLUGIN_NAME, FCVAR_NONE|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
    
    AddNormalSoundHook(view_as<NormalSHook>(Event_SoundPlayed));
}
public void OnAllPluginsLoaded() {
    Call_StartForward(g_hForwardZSOnLoaded);
    Call_Finish();
}
public void OnConVarChange(ConVar convar, const char[] oldValue, const char[] newValue) {
    if (convar == g_cFog) {
        g_cFog.SetInt(StringToInt(newValue));
        FogEnable(g_cFog.BoolValue);
    }
    else if (convar == g_cFogDensity) {
        float val = StringToFloat(newValue);
        g_cFogDensity.SetFloat(val);
        if (g_iFogIndex != -1) {
            DispatchKeyValueFloat(g_iFogIndex, "fogmaxdensity", val);
        }
    }
    else if (convar == g_cFogStartDist) {
        int val = StringToInt(newValue);
        g_cFogStartDist.SetInt(val);
        if (g_iFogIndex != -1) {
            SetVariantInt(val);
            AcceptEntityInput(g_iFogIndex, "SetStartDist");
        }
    }
    else if (convar == g_cFogEndDist) {
        int val = StringToInt(newValue);
        g_cFogEndDist.SetInt(val);
        if (g_iFogIndex != -1) {
            SetVariantInt(val);
            AcceptEntityInput(g_iFogIndex, "SetEndDist");
        }
    }
    else if (convar == g_cFogColor) {
        g_cFogColor.SetString(newValue);
        if (g_iFogIndex != -1) {
            SetVariantString(newValue);
            AcceptEntityInput(g_iFogIndex, "SetColor");
            SetVariantString(newValue);
            AcceptEntityInput(g_iFogIndex, "SetColorSecondary");
        }
    }
    else if (convar == g_cFogZPlane) {
        int val = StringToInt(newValue);
        g_cFogZPlane.SetInt(val);
        if (g_iFogIndex != -1) {
            SetVariantInt(val);
            AcceptEntityInput(g_iFogIndex, "SetFarZ");
        }
    }
    else if (convar == g_cCountDown) {
        int value = StringToInt(newValue) > 10?10:StringToInt(newValue);
        g_cCountDown.SetInt(value);
        g_iCountdownNumber = value;
    }
}
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    InitMethodMaps();
    InitNatives();
    InitForwards();
    // Register mod library
    RegPluginLibrary("zombieswarm");

    return APLRes_Success;
}
public void OnEntityCreated(int entity, const char[] classname) {
    if(!entity)
        return;
    
    if (StrEqual("info_player_terrorist",classname)) {
        SDKHook(entity, SDKHook_SpawnPost, OnTsEntitySpawnPost);
    }
    else if (StrEqual("info_player_counterterrorist",classname)) {
        SDKHook(entity, SDKHook_SpawnPost, OnCTsEntitySpawnPost);
    }
    else if (StrEqual("sky_camera",classname)) {
        SDKHook(entity, SDKHook_SpawnPost, OnSkyCameraSpawnPost);
    }
    else if (StrEqual("env_cascade_light",classname)) {
        SDKHook(entity, SDKHook_SpawnPost, OnCascadeLightSpawnPost);
    }
}

public void OnTsEntitySpawnPost(int EntRef) {
    int entity = EntRefToEntIndex(EntRef);
    float Vec[3];
    
    GetEntPropVector(entity, Prop_Data, "m_vecOrigin", Vec);
    Vec[2] = (Vec[2] + 73);
    g_fSpawns[CS_TEAM_T][g_iTSpawns] = Vec;
    g_iTSpawns++;
    
    SDKUnhook(entity, SDKHook_SpawnPost, OnTsEntitySpawnPost);
}
public void OnCTsEntitySpawnPost(int EntRef) {
    int entity = EntRefToEntIndex(EntRef);
    float Vec[3];

    GetEntPropVector(entity, Prop_Data, "m_vecOrigin", Vec);
    Vec[2] = (Vec[2] + 73);
    g_fSpawns[CS_TEAM_CT][g_iCTSpawns] = Vec;
    g_iCTSpawns++;
    
    SDKUnhook(entity, SDKHook_SpawnPost, OnCTsEntitySpawnPost);
}
public void OnSkyCameraSpawnPost(int EntRef) {
    g_iSkyCameraIndex = EntRefToEntIndex(EntRef);
    AcceptEntityInput(g_iSkyCameraIndex, "Kill");
}
public void OnCascadeLightSpawnPost(int EntRef) {
    g_iCascadeLightIndex = EntRefToEntIndex(EntRef);
}
public void OnMapEnd() {
    float Vec[3];
    Vec[0] = 0.0;
    Vec[1] = 0.0;
    Vec[2] = 0.0;
    for (int i = 0; i <= g_iTSpawns; i++) {
        g_fSpawns[CS_TEAM_T][i] = Vec;
    }
    for (int i = 0; i <= g_iCTSpawns; i++) {
        g_fSpawns[CS_TEAM_T][i] = Vec;
    }
    
    g_iTSpawns = 0;
    g_iCTSpawns = 0;
}
public void OnMapStart()
{
    g_bRoundEnded = false;
    
    g_iCountdownNumber = g_cCountDown.IntValue > 10?10:g_cCountDown.IntValue;
    
    PrecacheModel(DEFAULT_ARMS);
    
    UTIL_FakePrecacheSoundEx("sound/radio/terwin.wav");
    UTIL_FakePrecacheSoundEx("sound/radio/ctwin.wav");
    
    char overlay_ct[125], overlay_t[125];
    g_cOverlayTWin.GetString(overlay_t,sizeof(overlay_t));
    g_cOverlayCTWin.GetString(overlay_ct,sizeof(overlay_ct));
    
    PrecacheDecalAnyDownload(overlay_t);
    PrecacheDecalAnyDownload(overlay_ct);
    
    // Set team names
    SetConVarString(FindConVar("mp_teamname_1"), "HUMANS");
    SetConVarString(FindConVar("mp_teamname_2"), "ZOMBIES");
    
    // Get round time
    float roundTime = GetConVarFloat(FindConVar("mp_roundtime"));
    
    // Bug fix for standart maps
    SetConVarFloat(FindConVar("mp_roundtime_hostage"), roundTime);
    SetConVarFloat(FindConVar("mp_roundtime_defuse"),  roundTime);
    
    // Remove free armor
    SetConVarInt(FindConVar("mp_free_armor"), 0);
    
    SetConVarInt(FindConVar("mp_timelimit"), 20);
    SetConVarInt(FindConVar("mp_maxrounds"), 0);
    SetConVarInt(FindConVar("mp_friendlyfire"), 0);

    int ent; 
    ent = FindEntityByClassname(-1, "env_fog_controller");
    if (ent != -1)  {
        g_iFogIndex = ent;
    }
    else {
        g_iFogIndex = CreateEntityByName("env_fog_controller");
        DispatchSpawn(g_iFogIndex);
    }

    g_iSunIndex = FindEntityByClassname(-1, "env_sun");

    CreateFog();
    FogEnable(g_cFog.BoolValue);
    
    Util_LoadSounds();
    
    // Initialize some chars
    char zBuffer[PLATFORM_MAX_PATH];

    //**********************************************
    //* Zombie class precache                          *
    //**********************************************
    int temp_checker[g_eZombieClass];
    for (int i = 0; i < g_aZombieClass.Length; i++)
    {
        g_aZombieClass.GetArray(i, temp_checker[0]);
        //****************  Player ****************//
        // Path should be models/player/custom_player/cso2_zombi/zombie
        
        Format(zBuffer, sizeof(zBuffer), "%s.mdl", temp_checker[dataModel]);
        PrecacheModel(zBuffer);
        AddFileToDownloadsTable(zBuffer);

        Format(zBuffer, sizeof(zBuffer), "%s.dx90.vtx", temp_checker[dataModel]);
        AddFileToDownloadsTable(zBuffer);
        
        Format(zBuffer, sizeof(zBuffer), "%s.phy", temp_checker[dataModel]);
        AddFileToDownloadsTable(zBuffer);
        
        Format(zBuffer, sizeof(zBuffer), "%s.vvd", temp_checker[dataModel]);
        AddFileToDownloadsTable(zBuffer);
        
        if (strlen(temp_checker[dataArms])) {
            Format(zBuffer,sizeof(zBuffer),"%s",temp_checker[dataArms]);
            AddFileToDownloadsTable(zBuffer);
        }
    }

    // Open file
    File iDocument = OpenFile(g_sDownloadFilesPath, "r");
    
    // Initialize chars
    char szBuffer[PLATFORM_MAX_PATH];
    int szBufferText = sizeof(szBuffer);
    
    // If doesn't exist turn off server
    if(iDocument == null)
    {
        SetFailState("[ZM] File zm_downloads.txt doesn't exist!\n\n");
        return;
    }
    
    // Read through file
    while (ReadFileLine(iDocument, szBuffer, szBufferText))
    {    
        // If end of file, stop
        if (IsEndOfFile(iDocument))
        break;

        // If char long, make sure that it will be split
        int iLength = strlen(szBuffer);
        
        if (szBuffer[iLength-1] == '\n')
        {
            szBuffer[--iLength] = '\0';
        }
        
        // Removes whitespace at the begin and end of char
        TrimString(szBuffer);
        
        // If char have commentaries, skip
        if(StrContains(szBuffer, "//", false) != -1 || StrContains(szBuffer, "/*", false) != -1 || StrContains(szBuffer, ";", false) != -1)
        continue;
        
        // Read not empty char
        if(!StrEqual(szBuffer, "", false))
        {
            AddFileToDownloadsTable(szBuffer);
        }
    }
    
    if(iDocument != null)
    {
        // We're done with this file now, so we can close it
        delete iDocument;
    }
}
public Action Event_SoundPlayed(int clients[MAXPLAYERS-1], int &numClients, char[] sample, int &entity, int &iChannel, float &flVolume, int &iLevel, int &iPitch, int &iFlags) {
    if (entity && entity <= MaxClients && (StrContains(sample, "physics") != -1 || StrContains(sample, "footsteps") != -1)) {
        if (IsClientInGame(entity) && g_bGhost[entity]){
            return Plugin_Handled;
        }
    }

    return Plugin_Continue;
}
void CreateFog() {
    if(g_iFogIndex != -1)  {
        float FogDensity = GetConVarFloat(g_cFogDensity);
        int FogStartDist = GetConVarInt(g_cFogStartDist);
        int FogEndDist = GetConVarInt(g_cFogEndDist);
        int FogZPlane = GetConVarInt(g_cFogZPlane);
        DispatchKeyValueFloat(g_iFogIndex, "fogmaxdensity", FogDensity);
        SetVariantInt(FogStartDist);
        AcceptEntityInput(g_iFogIndex, "SetStartDist");
        SetVariantInt(FogEndDist);
        AcceptEntityInput(g_iFogIndex, "SetEndDist");
        SetVariantInt(FogZPlane);
        AcceptEntityInput(g_iFogIndex, "SetFarZ");
    
        char FogColor[32];
        GetConVarString(g_cFogColor, FogColor, sizeof(FogColor));    

        SetVariantString(FogColor);
        AcceptEntityInput(g_iFogIndex, "SetColor");
        
        SetVariantString(FogColor);
        AcceptEntityInput(g_iFogIndex, "SetColorSecondary");
        
    }
}

void FogEnable(bool status) {
    if (g_iFogIndex != -1) {
        if (status) {
            AcceptEntityInput(g_iFogIndex, "TurnOn");
        }
        else
            AcceptEntityInput(g_iFogIndex, "TurnOff");
    }
    
    if (g_iSunIndex != -1) {
        if (status)
            AcceptEntityInput(g_iSunIndex, "TurnOff");
        else
            AcceptEntityInput(g_iSunIndex, "TurnOn");
    }
    
    if (status) {
        AcceptEntityInput(g_iCascadeLightIndex, "Disable");
        SetLightStyle(0,"a");
    }
    else {
        AcceptEntityInput(g_iCascadeLightIndex, "Enable");
        SetLightStyle(0,"");
    }
    
    DispatchKeyValue(0, "skyname", "embassy");
}

public void OnGameFrame()
{
    int client;
    for (client = 1; client <= MaxClients; client++) 
    {
        if (UTIL_IsValidClient(client)) {
            int target = UTIL_IsPlayerStuck(client); 
            
            if (target < 0) {
                g_bShouldCollide[client] = false;
            } else {
                if (UTIL_IsValidClient(target) && (g_bGhost[client] || g_bGhost[target])) {
                    //if (UTIL_IsValidClient(target)) {
                    g_bShouldCollide[target] = true;
                    g_bShouldCollide[client] = true;
                }
            }
        }
    }
}

/*public void OnClientPutInServer(client)
{

}*/

public void OnClientPostAdminCheck(int client)
{
    g_bCanJoin[client] = true;
    g_bCanIgnore[client] = false;
    
    SDKHook(client, SDKHook_OnTakeDamage, onTakeDamage);
    SDKHook(client, SDKHook_TraceAttack, onTraceAttack);
    SDKHook(client, SDKHook_WeaponCanUse, onWeaponCanUse);
    // Ghost mod related
    SDKHook(client, SDKHook_ShouldCollide, onShouldCollide);
    SDKHook(client, SDKHook_SetTransmit, onSetTransmit);
    //SDKHook(client, SDKHook_StartTouch, onTouch);
    //SDKHook(client, SDKHook_Touch, onTouch);
    SDKHook(client, SDKHook_PostThinkPost, onPostThinkPost);
}

public void OnClientDisconnect(int client)
{
    if ( IsClientInGame(client) )
    {
        g_bCanJoin[client] = false;
        g_bCanIgnore[client] = false;
        
        g_iTeam[client] = CS_TEAM_NONE;

        g_bOverrideHint[client] = false;
        
        if (g_hTimerGhostHint[client] != null) {
            delete g_hTimerGhostHint[client];
        }
        
        if (g_hTimerZombieRespawn[client] != null) {
            delete g_hTimerZombieRespawn[client];
        }
        
        if (g_hTimerCooldown[client] != null) {
            delete g_hTimerCooldown[client];
        }
        g_iZombieRespawnLeft[client] = 0;
        g_fLastButtons[client] = 0;
        g_bCooldown[client] = false;
    }
}

public void onPostThinkPost(int client)
{
    if(g_bGhost[client]) {
        SetEntData(client, g_iCollisionOffset, 2, 1, true);
    } else {
        SetEntData(client, g_iCollisionOffset, 5, 4, true);
    }
}

public Action onWeaponCanUse(int client, int weapon)
{
    if ( !UTIL_IsValidAlive(client) )
    return Plugin_Handled;
    
    char sWeapon[32];
    GetEdictClassname(weapon, sWeapon, sizeof(sWeapon));
    
    if (GetClientTeam(client) == CS_TEAM_T && !(StrContains(sWeapon, "knife")>=0)) {
        return Plugin_Handled;
    }
    
    return Plugin_Continue;
}

public Action onTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
    if ( !UTIL_IsValidClient(victim) )
    return Plugin_Continue;
    
    if (GetClientTeam(victim) == CS_TEAM_T) {
        if (damagetype & DMG_FALL)
        return Plugin_Handled;
    }
    
    if ( !UTIL_IsValidClient(attacker) )
    return Plugin_Continue;
    
    if (victim == attacker)
    return Plugin_Continue;
    
    if (g_bRoundEnded)
    return Plugin_Handled;
    
    if (g_bGhost[victim] || g_bGhost[attacker])
    return Plugin_Handled;

    // If both players in tunnel (ducking), lets give zombie some advantage by making human dmg lower.
    if (GetClientTeam(victim) == CS_TEAM_T && GetClientTeam(attacker) == CS_TEAM_CT && GetEntityFlags(victim) & FL_DUCKING && GetEntityFlags(attacker) & FL_DUCKING) {
        damage *= 0.33;
        return Plugin_Changed;
    }
    
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
    
    if (g_bRoundEnded)
    return Plugin_Handled;
    
    if (g_bGhost[victim] || g_bGhost[attacker])
    return Plugin_Handled;
    
    return Plugin_Continue;
}

public Action onSetTransmit(int entity, int client) 
{
    if ( !UTIL_IsValidAlive(entity) || !UTIL_IsValidAlive(client) ) return Plugin_Continue;
    
    if (entity == client) return Plugin_Continue;
    
    if ( g_iTeam[entity] != g_iTeam[client] && !g_bGhost[client]
            && g_iTeam[entity] == CS_TEAM_T && g_bGhost[entity] )
    return Plugin_Handled; 
    
    // Hide near human for ghost zombie    
    if ( g_iTeam[entity] != g_iTeam[client] && !g_bGhost[entity]
            && GetClientTeam(client) == CS_TEAM_T && g_bGhost[client] && g_bShouldCollide[client] && g_bShouldCollide[entity] )
    return Plugin_Handled; 
    
    if (g_iTeam[entity] == g_iTeam[client] && !g_bGhost[client] && g_iTeam[entity] == CS_TEAM_T 
            && g_bGhost[entity])
    return Plugin_Handled;
    
    if (g_iTeam[entity] == g_iTeam[client] && g_bGhost[client] && g_iTeam[entity] == CS_TEAM_T 
            && g_bGhost[entity] && g_bShouldCollide[client] && g_bShouldCollide[entity])
    return Plugin_Handled;
    
    return Plugin_Continue;
}

public bool onShouldCollide(int entity, int collisiongroup, int contentsmask, bool result ) 
{
    if (g_bShouldCollide[entity]) {
        collisiongroup = 2;
        contentsmask = (CONTENTS_SOLID | CONTENTS_MOVEABLE | CONTENTS_PLAYERCLIP | CONTENTS_WINDOW | CONTENTS_MONSTER | CONTENTS_GRATE | CONTENTS_TEAM1 | CONTENTS_TEAM2);
        result = false;
        return false;
    }

    result = true;
    return true;
}

public void onTouch(int ent1, int ent2)
{
    if(ent1 == ent2)
    return;
    
    if(!UTIL_IsValidClient(ent1))
    return;
    
    if(!UTIL_IsValidClient(ent2))
    return;
    
    //if(g_iTeam[ent1] != g_iTeam[ent2] && g_bGhost[ent1])
    if(g_iTeam[ent1] != g_iTeam[ent2])
    {
        g_bShouldCollide[ent1] = true;
        g_bShouldCollide[ent2] = true;
        return;
    }
    
    g_bShouldCollide[ent1] = false;
    g_bShouldCollide[ent2] = false;
}

public Action blockKill(int client, const char[] command, int argc)
{
    return Plugin_Handled;
}

public Action joinTeam(int client, const char[] command, int argc)
{
    if (IsFakeClient(client))
    return Plugin_Continue;
    
    if (!UTIL_IsValidClient(client)) 
    return Plugin_Handled;
    
    if (IsPlayerAlive(client)) 
    return Plugin_Handled;
    
    if (IsClientSourceTV(client)) 
    return Plugin_Handled;
    
    if (!g_bCanJoin[client])
    return Plugin_Handled;
    
    char sTeam[4];
    GetCmdArg( 1, sTeam, sizeof(sTeam));
    int iTeam = StringToInt(sTeam);

    if ( iTeam == CS_TEAM_CT || iTeam == CS_TEAM_T || iTeam == CS_TEAM_NONE
            || iTeam == CS_TEAM_SPECTATOR ) {
        g_bCanJoin[client] = false;
        
        if (getHumans() >= GetConVarInt(g_cRoundStartZombies)) {
            CS_SwitchTeam( client, CS_TEAM_T );
            CreateTimer( 0.5, respawnClientOnConnect, client, TIMER_FLAG_NO_MAPCHANGE);
        } else {
            if ( getHumans() > getZombies() ) {
                CS_SwitchTeam( client, CS_TEAM_T );    
                CreateTimer( 0.5, respawnClientOnConnect, client, TIMER_FLAG_NO_MAPCHANGE);
            } else {
                CS_SwitchTeam( client, CS_TEAM_CT );
                if ( g_iRoundKillCounter < GetConVarInt(g_cRoundKillsTeamJoinHumans) )    
                CreateTimer( 0.5, respawnClientOnConnect, client, TIMER_FLAG_NO_MAPCHANGE);
            }
        }

        if(getTrueCT() == getTrueT()) {
            g_iTeam[client] = CS_TEAM_CT;
        } else if (getTrueCT() > getTrueT()) {
            g_iTeam[client] = CS_TEAM_T;
        } else {
            g_iTeam[client] = CS_TEAM_CT;
        }


    }
    
    return Plugin_Handled;
}

public void eventPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    g_iRoundKillCounter++;
    
    int victim = GetClientOfUserId(GetEventInt(event, "userid"));

    if ( !UTIL_IsValidClient(victim) )
        return;
    if (IsClientSourceTV(victim)) 
        return;

    if (g_hTimerGhostHint[victim] != null) {
        delete g_hTimerGhostHint[victim];
    }
    if (GetClientTeam(victim) == CS_TEAM_CT && getHumans() > 1) {
        g_bCanIgnore[victim] = true;
        //CS_SwitchTeam( victim, CS_TEAM_T );
        g_iZombieRespawnLeft[victim] = (IsClientVip(victim)) ? GetConVarInt(g_cRespawnTimeSVip) : GetConVarInt(g_cRespawnTimeS);
        g_hTimerZombieRespawn[victim] = CreateTimer( 1.0, timerZombieRespawnCallback, victim, TIMER_FLAG_NO_MAPCHANGE);
    } else if (GetClientTeam(victim) == CS_TEAM_T) {
        g_iZombieRespawnLeft[victim] = (IsClientVip(victim)) ? GetConVarInt(g_cRespawnTimeZVip) : GetConVarInt(g_cRespawnTimeZ);
        g_hTimerZombieRespawn[victim] = CreateTimer( 1.0, timerZombieRespawnCallback, victim, TIMER_FLAG_NO_MAPCHANGE);
        
        if (g_hTimerCooldown[victim] != null) {
            delete g_hTimerCooldown[victim];
        }
    }
}

stock bool IsClientVip(int client)
{
    if (GetUserFlagBits(client) & ADMFLAG_RESERVATION || GetUserFlagBits(client) & ADMFLAG_ROOT) 
    return true;
    return false;
}

public void eventPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));

    if ( !UTIL_IsValidAlive(client) )
    return;
    
    if (g_hTimerZombieRespawn[client] != null) {
        delete g_hTimerZombieRespawn[client];
    }
    
    g_fHintSpeed[client] = TIMER_SPEED;
    g_bOverrideHint[client] = false;

    g_iZombieRespawnLeft[client] = 0;
    
    SetEntData(client, g_iCollisionOffset, 2, 1, true);
    
    setZombieGhostMode(client, false);

    if (GetClientTeam(client) == CS_TEAM_T && UTIL_IsValidClient(client)) {
        
        // Set zombie ghost mode
        setZombieGhostMode(client, true);
        
        g_hTimerGhostHint[client] = CreateTimer( 1.0, ghostHint, client, TIMER_FLAG_NO_MAPCHANGE);
        
        Menu menu = new Menu(ZombieClassMenuHandler);
        menu.SetTitle("Select zombie class:");
        
        char className[MAX_CLASS_NAME_SIZE], key[MAX_CLASS_ID];
        int temp_checker[g_eZombieClass];
        for (int i = 0; i < g_aZombieClass.Length; i++)
        {
            g_aZombieClass.GetArray(i, temp_checker[0]);
            if(!temp_checker[dataExcluded]) {
                Format(className,sizeof(className),"%s",temp_checker[dataName]);
                IntToString(i,key,sizeof(key));
                menu.AddItem(key, className);
            }
        }
        menu.ExitButton = true;
        menu.Display(client, 0);
        
    } else if (GetClientTeam(client) == CS_TEAM_CT) {
        SetEntityGravity(client, g_cHumanGravity.FloatValue); 
    }
    // Hide RADAR
    CreateTimer(0.0, RemoveRadar, client);
}
public int ZombieClassMenuHandler(Menu menu, MenuAction action, int client, int param2) {
    int temp_checker[g_eZombieClass];
    if (action == MenuAction_Select && GetClientTeam(client) == CS_TEAM_T) {
        char key[MAX_CLASS_ID];
        menu.GetItem(param2, key, sizeof(key));
        int classInt = StringToInt(key);
        g_aZombieClass.GetArray(classInt, temp_checker[0]);

        g_iZombieClass[client] = classInt;
        setZombieClassParameters(client);
        callZombieSelected(client, g_iZombieClass[client]);
        
        CPrintToChat(client,"You selected: {red}%s",temp_checker[dataName]);
        if (strlen(temp_checker[dataDescription])) {
            CPrintToChat(client,"{red}%s",temp_checker[dataDescription]);
        }
    }
    else if (action == MenuAction_Cancel) {
        int random = getRandomZombieClass();
        g_iZombieClass[client] = random;
        setZombieClassParameters(client);
        callZombieSelected(client, g_iZombieClass[client]);
        g_aZombieClass.GetArray(random, temp_checker[0]);
        
        CPrintToChat(client,"Random Zombie class: {red}%s",temp_checker[dataName]);
        if (strlen(temp_checker[dataDescription])) {
            CPrintToChat(client,"{red}%s",temp_checker[dataDescription]);
        }
    }
}
public Action eventRoundFreezeEnd(Event event, const char[] name, bool dontBroadcast)
{
    g_bGhostCanSpawn = false;
    if (g_hTimerCountDown != INVALID_HANDLE) {
        KillTimer(g_hTimerCountDown);
    }
    
    g_hTimerCountDown = CreateTimer(1.0, CountDown, _, TIMER_REPEAT);
}

public Action eventRoundStartNoCopy(Event event, const char[] name, bool dontBroadcast)
{
    
    g_iRoundKillCounter = 0;
    g_bRoundEnded = false;
    g_bGhostCanSpawn = false;
    
    int ent = -1;
    while((ent = FindEntityByClassname(ent, "light"))!=-1){
        AcceptEntityInput(ent, "TurnOff");
        break;
    }
    
    // Names of entities, which will be remove every round
    #define ROUNDSTART_OBJECTIVE_ENTITIES "func_bomb_target_hostage_entity_func_hostage_rescue_func_buyzoneprop_physics_overrideprop_physics_multiplayer"
    
    // Removes all entities with a targetname that match in ROUNDSTART_OBJECTIVE_ENTITIES,
    // and removes them, so standart map will avalible for playing
    removeMapEventEntity(ROUNDSTART_OBJECTIVE_ENTITIES); 
}

public Action eventWinPanelRound(Event event, const char[] name, bool dontBroadcast)
{
    // Set dont broadcast for panel
    if(dontBroadcast == false) 
    {
        SetEventBroadcast(event, true); 
    }
    
    return Plugin_Continue; 
}

public void eventRoundEnd(Event event, const char[] name, bool dontBroadcast)
{
    g_iRoundKillCounter = 0;
    
    g_bRoundEnded = true;
    
    int winner = GetEventInt(event, "winner");
    
    for (int client = 1; client <= MaxClients; client++) 
    { 
        if (UTIL_IsValidClient(client) )
        {    
            if (g_hTimerZombieRespawn[client] != null) {
                delete g_hTimerZombieRespawn[client];
            }

            g_iZombieRespawnLeft[client] = 0;
            
            /*StopSound(client, SNDCHAN_STATIC, "radio/ctwin.wav");
            StopSound(client, SNDCHAN_STATIC, "radio/rounddraw.wav");
            StopSound(client, SNDCHAN_STATIC, "radio/terwin.wav");*/
            
            char overlay[125];
            
            if(winner == CS_TEAM_T) {
                int randomSound = GetRandomInt(0, sizeof(g_ZombieWinSounds)-1);
                g_cOverlayTWin.GetString(overlay,sizeof(overlay));
                
                UTIL_PlayClientCommandSound(client, g_ZombieWinSounds[randomSound]);
            } else if(winner == CS_TEAM_CT) {
                int randomSound = GetRandomInt(0, sizeof(g_HumanWinSounds)-1);
                g_cOverlayCTWin.GetString(overlay,sizeof(overlay));
                
                UTIL_PlayClientCommandSound(client, g_HumanWinSounds[randomSound]);
            }
            
            if (g_cOverlayEnable.BoolValue) {
                if (strlen(overlay) > 0) {
                    ShowOverlayAll(overlay,5.0);
                }
            }
            
            g_bCooldown[client] = false;
            if (g_hTimerCooldown[client] != null) {
                delete g_hTimerCooldown[client];
            }
        }
    }

    // Use custom plugin for handling it.
    //setTeamBalance();
}



public Action eventTeamChange(Event event, const char[] name, bool dontBroadcast)
{
    //int client = GetClientOfUserId(GetEventInt(event, "userid"));
    //int team = GetEventInt(event, "team");
    
    // Block change team message
    if(!dontBroadcast) 
    { 
        // Execute event and block it
        Event sEvent = CreateEvent("player_team", true);  

        SetEventInt(sEvent, "userid", GetEventInt(event, "userid")); 
        SetEventInt(sEvent, "team", GetEventInt(event, "team")); 
        SetEventInt(sEvent, "oldteam", GetEventInt(event, "oldteam")); 
        SetEventBool(sEvent, "disconnect", GetEventBool(event, "disconnect")); 
        
        FireEvent(sEvent, true); 
    }
    
    return Plugin_Handled;
}

public int nativeAbilityFinished(Handle plugin, int numParams) {
    int client = GetNativeCell(1);

    if (!UTIL_IsValidClient(client))
        return false;

    DataPack pack;
    float time = view_as<float>(g_aZombieClass.Get(g_iZombieClass[client], dataAbilityButton));
    g_hTimerCooldown[client] = CreateDataTimer(0.1, cooldownCallback, pack, TIMER_REPEAT);
    pack.WriteCell(client);
    pack.WriteFloat(time);

    return true;
}
public Action cooldownCallback(Handle timer, DataPack pack) {
    pack.Reset();
    int client = pack.ReadCell();
    float end = pack.ReadFloat();
        
    if (!UTIL_IsValidAlive(client) || getTeam(client) != CS_TEAM_T || isGhost(client)) {
        return Plugin_Stop;
    }
    else {
        float now = GetGameTime();
        ZMPlayer player = ZMPlayer(client);
        
        if (now > end) {
            player.isCooldown = false;
            player.OverrideHint = false;
            
            return Plugin_Stop;
        }
        else {
            player.OverrideHint = true;
            player.isCooldown = true;
            float left = end - now;
            char hintText[512];
            Format(hintText, sizeof(hintText), "<font color='#00FF00'>Ability cooldown for %.1fs!</font>",left);
            player.OverrideHintText(hintText);
        }
    }

    return Plugin_Continue;
}
public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float velocity[3], float angles[3], int &weapon, int &subtype, int &cmdNum, int &tickCount, int &seed, int mouse[2])
{
    if ( !UTIL_IsValidAlive(client) )
    return Plugin_Continue;
    
    if (GetClientTeam(client) == CS_TEAM_T) {
        ZMPlayer player = ZMPlayer(client);
        if (UTIL_IsValidAlive(client) && !player.Ghost && !player.isCooldown) {
            int tButtons = view_as<int>(g_aZombieClass.Get(g_iZombieClass[client], dataAbilityButton));
            if (GetEntProp(client, Prop_Data, "m_afButtonPressed") == tButtons) {
                Call_StartForward(g_hForwardAbilityButtonPressed);
                Call_PushCell(client);
                Call_PushCell(buttons);
                Call_Finish();

                player.isCooldown = true;
            }
            else if (GetEntProp(client, Prop_Data, "m_afButtonReleased") == tButtons) {
                Call_StartForward(g_hForwardAbilityButtonReleased);
                Call_PushCell(client);
                Call_PushCell(buttons);
                Call_Finish();

                player.isCooldown = true;
        }
    }

        if (player.Ghost) {
            if ((buttons & IN_ATTACK)) {
                if (!UTIL_IsClientInTargetsView(client)) {
                    if (g_bGhostCanSpawn) {
                        setZombieGhostMode(client, false);
                        float tSpeed = view_as<float>(g_aZombieClass.Get(g_iZombieClass[client], view_as<int>(dataSpeed)));
                        // Set zombie speed
                        SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", tSpeed);
                        
                        UTIL_ShowHintMessage(client, "<font color='#FFFFFF'>You've been revived! Slash and Smash!</font>");
                    } else {
                        UTIL_ShowHintMessage(client, "<font color='#FF0000'>Wait a little bit! <br/> Players are warming up.</font>");
                    }
                } else {
                    UTIL_ShowHintMessage(client, "<font color='#FF0000'>Hide from humans to respawn!</font>");
                }
            }
            if ((buttons & IN_RELOAD)) {
                if (g_iTSpawns > 0) {
                    int random = GetRandomInt(0,g_iTSpawns);
                    float spawn[3];
                    spawn = g_fSpawns[CS_TEAM_T][random];
                    if (UTIL_IsValidClient(client) && g_bGhost[client] && (spawn[0] != 0.0 && spawn[1] != 0.0 && spawn[2] != 0.0))
                        TeleportEntity(client, spawn, NULL_VECTOR, NULL_VECTOR);
                }
                else {
                    CPrintToChat(client,"{red}No valid spawns found. Can't teleport");
                }
            }
        }
    }
    return Plugin_Continue;
}

public Action teleportZombieToHuman(Handle timer, any client)
{
    if ( !UTIL_IsValidAlive(client) || g_iTeam[client] != CS_TEAM_T || !g_bGhost[client] ) {
        return Plugin_Continue;
    }
    
    float targetOrigin[3], changedTargetOrigin[3];
    
    int rClient = UTIL_GetRandomHuman();
    if (UTIL_IsValidClient(rClient))
    {
        GetClientAbsOrigin(rClient, targetOrigin);
        changedTargetOrigin[0] = targetOrigin[0];
        changedTargetOrigin[1] = targetOrigin[1];
        changedTargetOrigin[2] = targetOrigin[2];
        
        int isStuck = UTIL_GetPlayerStuckVector(client, changedTargetOrigin);
        if (isStuck < 0) {
            targetOrigin[0] = changedTargetOrigin[0];
            targetOrigin[1] = changedTargetOrigin[1];
            targetOrigin[2] = changedTargetOrigin[2];
        } else {
            
        }
        
        TeleportEntity(client, targetOrigin, NULL_VECTOR, NULL_VECTOR);
    }

    return Plugin_Continue;
}

public Action RemoveRadar(Handle timer, any client) 
{
    if ( !UTIL_IsValidAlive(client) )
    return Plugin_Continue;

    SetEntProp(client, Prop_Send, "m_iHideHUD", GetEntProp(client, Prop_Send, "m_iHideHUD") | HIDEHUD_RADAR);
    
    return Plugin_Continue;
} 

public Action ghostHint(Handle timer, any client)
{
    g_hTimerGhostHint[client] = null;

    if ( !UTIL_IsValidAlive(client) || GetClientTeam(client) != CS_TEAM_T )
    return Plugin_Continue;
    
    if (g_bOverrideHint[client]) {
        UTIL_ShowHintMessage(client, g_sOverrideHintText[client]);
    }
    else if (g_bGhost[client]) {
        UTIL_ShowHintMessage(client, "<font color='#FFFFFF'>Currently you are a ghost</font>\n<font color='#00FF00'>E</font><font color='#FFFFFF'> to teleport.\n<font color='#00FF00'>MOUSE1</font><font color='#FFFFFF'> to spawn.</font>");
    } else {
        char sHintText[196];
        int temp_checker[g_eZombieClass];
        g_aZombieClass.GetArray(g_iZombieClass[client], temp_checker[0]);
        Format(sHintText, sizeof(sHintText), "<font color='#00FF00'>%s</font><br/><font color='#FFFFFF'>%s</font>", temp_checker[dataName], temp_checker[dataDescription]);
        
        UTIL_ShowHintMessage(client, sHintText);
    }
    
    g_hTimerGhostHint[client] = CreateTimer( g_fHintSpeed[client], ghostHint, client, TIMER_FLAG_NO_MAPCHANGE);
    
    return Plugin_Continue;
}

public Action respawnClientOnConnect( Handle timer, any client )
{
    if ( !UTIL_IsValidClient(client) || IsPlayerAlive(client) )
    {
        return Plugin_Continue;
    }
    
    CS_RespawnPlayer( client );
    
    return Plugin_Continue;
}

public Action timerZombieRespawnCallback( Handle timer, any client )
{    
    g_hTimerZombieRespawn[client] = null;
    if ( !UTIL_IsValidClient(client) )
    return Plugin_Continue;
    
    if (IsPlayerAlive(client))
    return Plugin_Continue;

    if (GetClientTeam(client) == CS_TEAM_SPECTATOR) {
        return Plugin_Continue;
    }

    if (g_iZombieRespawnLeft[client] == 0) {
        CS_RespawnPlayer( client );
        UTIL_ShowHintMessage(client, "<font color='#FF0000'>Go Go Go!</font>");
    } else {
        char sHintText[196];
        Format(sHintText, sizeof(sHintText), "<font color='#FF0000'>Respawn cooldown! <br/> Wait for %i seconds</font>", g_iZombieRespawnLeft[client]);
        UTIL_ShowHintMessage(client, sHintText);
        g_iZombieRespawnLeft[client]--;
        g_hTimerZombieRespawn[client] = CreateTimer( 1.0, timerZombieRespawnCallback, client, TIMER_FLAG_NO_MAPCHANGE);
    }
    
    return Plugin_Continue;
}

stock int getZombieHealthRate(int client)
{
    int health = view_as<int>(g_aZombieClass.Get(g_iZombieClass[client], view_as<int>(dataHP)));
    int value = (RoundToCeil(SquareRoot(float(health)/(getZombies()+1)/2.0))+2)*health;

    if (getHumans() < getZombies()) {
        value = (RoundToCeil(SquareRoot(float(health)/(getZombies()+1)/2.0)))*health;
    }
    
    return value;
}

stock int getHumans(bool alive = false)
{
    int humans, i;
    
    for (i = 1; i <= MaxClients; i++)
    {
        if (UTIL_IsValidClient(i) && !IsClientSourceTV(i) && GetClientTeam(i) == CS_TEAM_CT)
        {
            if (!alive || (alive && IsPlayerAlive(i)))
            humans++;
        }
    }
    
    return humans;
}

stock int getZombies(bool alive = false)
{
    int zombies, i;
    
    for (i = 1; i <= MaxClients; i++)
    {
        if (UTIL_IsValidClient(i) && !IsClientSourceTV(i) && GetClientTeam(i) == CS_TEAM_T)
        {
            if (!alive || (alive && IsPlayerAlive(i)))
            zombies++;
        }
    }
    
    return zombies;
}

stock int getTrueCT(bool alive = false)
{
    int humans, i;
    
    for (i = 1; i <= MaxClients; i++)
    {
        if (UTIL_IsValidClient(i) && !IsClientSourceTV(i) && g_iTeam[i] == CS_TEAM_CT)
        {
            if (!alive || (alive && IsPlayerAlive(i)))
            humans++;
        }
    }
    
    return humans;
}

stock int getTrueT(bool alive = false)
{
    int zombies, i;
    
    for (i = 1; i <= MaxClients; i++)
    {
        if (UTIL_IsValidClient(i) && !IsClientSourceTV(i) && g_iTeam[i] == CS_TEAM_T)
        {
            if (!alive || (alive && IsPlayerAlive(i)))
            zombies++;
        }
    }
    
    return zombies;
}

public void setZombieGhostMode(int client, bool mode) 
{
    g_bGhost[client] = mode;
    setZombieClassParameters(client);
}

public void removeMapEventEntity(const char[] objects)
{
    // Initialize char
    char sClass[64];
    
    // Save max amount of entities
    int maxEntities = GetMaxEntities();
    
    // Check all entities and remove it
    for (int i = 0; i <= maxEntities; i++)
    {
        if(IsValidEdict(i) && IsValidEntity(i))
        {
            // Get classname
            GetEdictClassname(i, sClass, sizeof(sClass));
            
            // Compare classname
            if(StrContains(objects, sClass) != -1) 
            {
                RemoveEdict(i);
            }
        }
    }
}

public int getRandZombieClass() 
{
    int[] tclasses = new int[g_iNumClasses];
    int classCount;
    for (int i = 0; i < g_aZombieClass.Length; i++)
    {
        int temp_checker[g_eZombieClass];
        g_aZombieClass.GetArray(i, temp_checker[0]);
        bool excluded = temp_checker[dataExcluded];
        if(!excluded) {
            tclasses[classCount++] = i;
        }
    }
    
    return tclasses[GetRandomInt(0, classCount - 1)];
}

public void setZombieClassParameters(int client) 
{
    if (g_iTeam[client] != CS_TEAM_T) return;
    // Set zombie class model
    int temp_checker[g_eZombieClass];
    g_aZombieClass.GetArray(g_iZombieClass[client], temp_checker[0]);
    char zBuffer[PLATFORM_MAX_PATH];
    Format(zBuffer, sizeof(zBuffer), "%s.mdl", temp_checker[dataModel]);
    SetEntityModel(client, zBuffer);
    
    // Set zombie arms
    if (strlen(temp_checker[dataArms]) > 0) {
        int ent = GetEntPropEnt(client, Prop_Send, "m_hMyWearables");
        if(ent != -1) {
            AcceptEntityInput(ent, "KillHierarchy");
        }
        SetEntPropString(client, Prop_Send, "m_szArmsModel", temp_checker[dataArms]);
    }
    else {
        int ent = GetEntPropEnt(client, Prop_Send, "m_hMyWearables");
        if(ent != -1) {
            AcceptEntityInput(ent, "KillHierarchy");
        }
        SetEntPropString(client, Prop_Send, "m_szArmsModel", DEFAULT_ARMS);
    }
    
    // Set zombie health
    SetEntProp(client, Prop_Send, "m_iHealth", getZombieHealthRate(client), 4);
    
    // Set zombie speed
    if(g_bGhost[client])
    SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.4);
    else
    SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", temp_checker[dataSpeed]);
    
    // Set zombie gravity
    SetEntityGravity(client, temp_checker[dataGravity]);
}

public Action CountDown(Handle timer) {
    if (g_iCountdownNumber <= 0) {
        g_iCountdownNumber = g_cCountDown.IntValue > 10?10:g_cCountDown.IntValue;
        g_bGhostCanSpawn = true;
        g_hTimerCountDown = INVALID_HANDLE;
        
        return Plugin_Stop;
    }
    
    for (int client = 1; client <= MaxClients; client++) {
        if (!UTIL_IsValidClient(client))
            continue;
        if(GetClientTeam(client) != CS_TEAM_T)
            continue;
        
        Util_PlaySoundToClient(client,g_CountdownSounds[(g_iCountdownNumber - 1)]);
    }
    
    g_iCountdownNumber--;
    g_bGhostCanSpawn = false;
    
    return Plugin_Continue;
}
public ZombieClass FindZombieClassByID(int id) {
    return view_as<ZombieClass>(g_aZombieClass.FindValue(id, view_as<int>(dataID)));
}
public int FindZombieIndex(int id) {
    return view_as<int>(g_aZombieClass.FindValue(id, view_as<int>(dataID)));
}