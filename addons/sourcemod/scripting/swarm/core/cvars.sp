void InitCvars() 
{
    CreateConVar("sm_zombieswarm_version", ZS_PLUGIN_VERSION, ZS_PLUGIN_NAME, FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_REPLICATED);
    
    g_cGhostMode = AutoExecConfig_CreateConVar("zm_enable_ghostmode", "0", "1 - Enable ghost mode, 0 - Disable",_,true,0.0,true,1.0);
    g_cRespawnTimeZ = AutoExecConfig_CreateConVar("zm_respawn_time_t", "3.0", "Vip players respawn time after team join or death");
    g_cRespawnTimeZVip = AutoExecConfig_CreateConVar("zm_respawn_time_t_vip", "3.0", "Vip players respawn time after team join or death");
    g_cRespawnTimeS = AutoExecConfig_CreateConVar("zm_respawn_time_ct", "60.0", "Players respawn time after team join or death");
    g_cRespawnTimeSVip = AutoExecConfig_CreateConVar("zm_respawn_time_ct_vip", "55.0", "Vip players respawn time after team join or death");
    g_cRoundStartZombies = AutoExecConfig_CreateConVar("zm_round_start_zombies", "5", "Round start zombies");
    g_cRoundKillsTeamJoinHumans = AutoExecConfig_CreateConVar("zm_round_kills_teamjoin_humans", "25", "Human can join team after he is connected depends on round kills");
    g_cFog = AutoExecConfig_CreateConVar("zm_env_fog", "0", "1 - Enable fog, 0 - Disable",_,true,0.0,true,1.0);
    g_cFogDensity = AutoExecConfig_CreateConVar("zm_env_fogdensity", "0.65", "Toggle the density of the fog effects", _ , true, 0.0, true, 1.0);
    g_cFogStartDist = AutoExecConfig_CreateConVar("zm_env_fogstart", "0", "Toggle how far away the fog starts", _ , true, 0.0, true, 8000.0);
    g_cFogEndDist = AutoExecConfig_CreateConVar("zm_env_fogend", "500", "Toggle how far away the fog is at its peak", _ , true, 0.0, true, 8000.0);
    g_cFogColor = AutoExecConfig_CreateConVar("zm_env_fogcolor", "200 200 200", "Modify the color of the fog" );
    g_cFogZPlane = AutoExecConfig_CreateConVar("zm_env_zplane", "8000", "Change the Z clipping plane", _ , true, 0.0, true, 8000.0);
    g_cCountDown = AutoExecConfig_CreateConVar("zm_countdown", "10", "Time then zombies will take class",_,true,1.0,true,10.0);
    g_cOverlayEnable = AutoExecConfig_CreateConVar("zm_overlay_enable","1","1 - Enable, 0 - Disable",_,true,0.0,true,1.0);
    g_cOverlayCTWin = AutoExecConfig_CreateConVar("zm_overlay_humans_win","overlays/swarm/humans_win","Show overlay then humans win");
    g_cOverlayTWin = AutoExecConfig_CreateConVar("zm_overlay_zombies_win","overlays/swarm/zombies_win","Show overlay then zombies win");
    g_cHumanGravity = AutoExecConfig_CreateConVar("zm_human_gravity","0.8","Gravity for humans. 1.0 - default");
    // Sounds
    g_cSoundsDeathEnable = AutoExecConfig_CreateConVar("zm_sounds_death_enable", "1", "1 - Enable Death sounds, 0 - Disable",_,true,0.0,true,1.0);
    g_cSoundsFootsteps = AutoExecConfig_CreateConVar("zm_sounds_footsteps_enable", "1", "1 - Enable Footstep sounds, 0 - Disable",_,true,0.0,true,1.0);
    g_cSoundsHit = AutoExecConfig_CreateConVar("zm_sounds_hit_enable", "1", "1 - Enable Hit sounds, 0 - Disable",_,true,0.0,true,1.0);
    g_cSoundsMiss = AutoExecConfig_CreateConVar("zm_sounds_miss_enable", "1", "1 - Enable Miss sounds, 0 - Disable",_,true,0.0,true,1.0);
    g_cSoundsPain = AutoExecConfig_CreateConVar("zm_sounds_pain_enable", "1", "1 - Enable Pain sounds, 0 - Disable",_,true,0.0,true,1.0);
    g_cSoundsIdle = AutoExecConfig_CreateConVar("zm_sounds_idle_enable", "0", "1 - Enable Idle sounds, 0 - Disable",_,true,0.0,true,1.0);
    g_cPainFrequency = AutoExecConfig_CreateConVar("zm_sounds_pain_frequency","1.25","How frequent pain sound. 1.25 - default",_,true,0.1);
    g_cFootstepFrequency = AutoExecConfig_CreateConVar("zm_sounds_footstep_frequency","0.75","How frequent footstep sound. 0.75 - default",_,true,0.1);
    g_cIdleMinFrequency = AutoExecConfig_CreateConVar("zm_sounds_idle_min_frequency","30.0","Min frequency of idle sound.",_,true,0.1);
    g_cIdleMaxFrequency = AutoExecConfig_CreateConVar("zm_sounds_idle_max_frequency","80.0","Max frequency of idle sound.",_,true,0.1);
}