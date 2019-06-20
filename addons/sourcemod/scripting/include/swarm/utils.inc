#if defined _zombieswarm_utils_included
  #endinput
#endif
#define _zombieswarm_utils_included

#define DISTANCE_BEFORE 3000.0

stock void UTIL_Fade(int client, int duration = 5, int hold = 300, int color[4]= {0, 0, 0, 255}) {
	Protobuf Fade = view_as<Protobuf>(StartMessageOne("Fade", client));
	
	if(Fade != null) {
		// Write shake information to message handle
		Fade.SetInt("duration", RoundToNearest(duration * 1000.0)); 
		Fade.SetInt("hold_time", RoundToNearest(hold * 1000.0)); 
		Fade.SetInt("flags", 0x0009); 
		Fade.SetColor("clr", color); 

		// End usermsg and send to the client
		EndMessage();
	}
} 
stock void UTIL_ShakeScreen(int client, float duration = 3.0, float amplitude = 2.0, float freq = 1.0) {
    // Create message
    Protobuf Shake = view_as<Protobuf>(StartMessageOne("Shake", client));

    // Validate message
    if(Shake != null) {
        // Write shake information to message handle
        Shake.SetInt("command", 0);
        Shake.SetFloat("local_amplitude", amplitude);
        Shake.SetFloat("frequency", freq);
        Shake.SetFloat("duration", duration);

        // End usermsg and send to the client
        EndMessage();
    }
}

stock bool UTIL_FakePrecacheSoundEx( const char[] szPath )
{
    char sPathStar[PLATFORM_MAX_PATH];
    Format(sPathStar, sizeof(sPathStar), "*/%s", szPath);
    
    AddToStringTable( FindStringTable( "soundprecache" ), sPathStar );
    return true;
}

stock void UTIL_VelocityByAim(int client, float distance, float velocity[3])
{
    float vAngles[3];
    
    GetClientEyeAngles(client, vAngles);
    
    velocity[0] = Cosine(DegToRad(vAngles[1])) * distance;
    velocity[1] = Sine(DegToRad(vAngles[1])) * distance;
    velocity[2] = Sine(DegToRad(-vAngles[0])) * distance;
}
stock bool UTIL_IsValidClient(int client)
{
    return ( 1 <= client <= MaxClients && IsClientInGame(client) );
}
stock bool UTIL_IsValidAlive(int client)
{
    return ( 1 <= client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client) );
}
stock void Util_PlaySoundToClient(int client, char[] sound, float volume = 0.8) {
	ClientCommand(client, "playgamesound Music.StopAllMusic");
	ClientCommand(client, "play */%s", sound);
	EmitSoundToClient(client, sound, -2, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SND_NOFLAGS, volume);
}
stock bool UTIL_IsClientInTargetView(int client, int target)
{
    float playerOrigin[3];

    bool HitPlayer = false;
                
    float targetOrigin[3], distanceBetween;

    GetClientAbsOrigin( client, playerOrigin);
    GetClientAbsOrigin ( target, targetOrigin );
    distanceBetween = GetVectorDistance ( targetOrigin, playerOrigin );
                        
    if ( distanceBetween >= DISTANCE_BEFORE )
    {
        HitPlayer = false;
        return HitPlayer;
    }
                        
    targetOrigin[0] -= 20.0;
    targetOrigin[2] -= 0.0;
                        
    playerOrigin[0] -= 20.0;
    playerOrigin[2] -= 0.0;
                
    for(int pos = 0; pos <= 11; pos++) // Check for position
    {
        targetOrigin[0] += 2.5;
        targetOrigin[2] += 6.0;
                            
        playerOrigin[0] += 2.5;
        playerOrigin[2] += 6.0;
                                        
        Handle trace = TR_TraceRayFilterEx( playerOrigin, targetOrigin, MASK_SOLID, RayType_EndPoint, UTIL_TraceEntityFilterRay);
                        
        if ( !TR_DidHit(trace) )
        {
            HitPlayer = true;
        }

        delete trace;
    }
    
    return HitPlayer;
}

public bool UTIL_TraceEntityFilterHull(int entity, int contentsMask, any client)
{
    return entity != client;
} 

public bool UTIL_TraceEntityFilterRay(int entity, int contentsMask)
{
    return entity > MaxClients;
}

public bool UTIL_IsClientInTargetsView(int client)
{
    int target;
    for (target = 1; target <= MaxClients; target++) 
    {
        if ( UTIL_IsValidAlive(target) && UTIL_IsClientInTargetView(client, target) && GetClientTeam(client) != GetClientTeam(target) ) {
            return true;
        }
    }
    
    return false;
}

stock void UTIL_CreateAttachParticle(int client, const char[] effectName, float fPos[3], const char[] attachTo, float lifetime)
{    
    int particle = UTIL_CreateParticle(effectName);
    
    if (IsValidEdict(particle))
    {
        TeleportEntity(particle, fPos, NULL_VECTOR, NULL_VECTOR);
        
        SetVariantString("!activator");
        AcceptEntityInput(particle, "SetParent", client, particle, 0);
        SetVariantString("primary");
        
        if (!StrEqual(attachTo, ""))
        {
            SetVariantString(attachTo);
            AcceptEntityInput(particle, "SetParentAttachment", particle, particle, 0);
        }
        
        DispatchSpawn(particle);
        
        AcceptEntityInput(particle, "Start");
        ActivateEntity(particle);
    }
    
    UTIL_ParticleDeathTimer(particle, lifetime);
}

stock int UTIL_CreateParticle(const char[] effectName)
{
    int particle = CreateEntityByName("info_particle_system");
    if (IsValidEdict(particle))
    {
        DispatchKeyValue(particle, "effect_name", effectName);

        return particle;
    }
    
    return -1;
}

stock void UTIL_ParticleDeathTimer(int entity, float lifetime)
{
    if (IsValidEdict(entity))
    {
        char variantString[60];
        Format(variantString, sizeof(variantString), "OnUser1 !self:Kill::%f:-1", lifetime);
                
        SetVariantString(variantString);
        AcceptEntityInput(entity, "AddOutput");
        AcceptEntityInput(entity, "FireUser1");
    }
}

stock void UTIL_PrecacheParticle( const char[] effectName )
{
    static numStringTable = INVALID_STRING_TABLE;
    
    if (numStringTable == INVALID_STRING_TABLE)
    {
        numStringTable = FindStringTable("ParticleEffectNames");
    }
    
    AddToStringTable(numStringTable, effectName );
}

stock void UTIL_PlayClientCommandSound(int client, const char[] sound)
{
    ClientCommand(client, "playgamesound Music.StopAllMusic");
    ClientCommand(client, "play */%s", sound);
}

public void UTIL_ShowHintMessage(int client, const char[] message)
{
    Handle hMessage = StartMessageOne("HintText", client);
    PbSetString(hMessage, "text", message);
    EndMessage();
}

public int UTIL_IsPlayerStuck(int client)
{
    int i_index = -1;

    float vecMin[3], vecMax[3], vecOrigin[3];
    
    GetClientMins(client, vecMin);
    GetClientMaxs(client, vecMax);
    
    GetClientAbsOrigin(client, vecOrigin);
    
    vecOrigin[0] -= 10.0;
    vecOrigin[1] -= 10.0;
    vecOrigin[2] -= 0.0;
    
    for(int pos = 0; pos <= 11; pos++) // Check for position
    {            
        vecOrigin[0] += 2.5;
        vecOrigin[1] += 2.5;
        vecOrigin[2] += 6.0;
        
        Handle trace = TR_TraceHullFilterEx(vecOrigin, vecOrigin, vecMin, vecMax, MASK_SOLID, UTIL_TraceEntityFilterHull, client);
        
        if(TR_DidHit(trace))
        {
            i_index = TR_GetEntityIndex( trace );
        }
        
        delete trace;
    }
    
    return i_index;
}

stock int UTIL_GetPlayerStuckVector(int client, float vecOrigin[3])
{
    int i_index = -1;

    float vecMin[3], vecMax[3], vecSaved[3];
    
    GetClientMins(client, vecMin);
    GetClientMaxs(client, vecMax);
    
    vecSaved[0] = vecOrigin[0]; // x
    vecSaved[1] = vecOrigin[1]; // y
    vecSaved[2] = vecOrigin[2];    
    
    vecOrigin[0] -= 100.0; // x
    vecOrigin[1] -= 0.0; // y
    vecOrigin[2] -= 0.0;
    
    for(int pos = 0; pos <= 11; pos++) // Check for position
    {            
        vecOrigin[0] += 10.5;
        vecOrigin[1] += 10.5;
        vecOrigin[2] += 10.0;
        
        Handle trace = TR_TraceHullFilterEx(vecOrigin, vecOrigin, vecMin, vecMax, MASK_PLAYERSOLID, UTIL_TraceEntityFilterHull, client);
        
        if(TR_DidHit(trace))
        {
            i_index = 1;
        } else {
            i_index = -1;
            delete trace;
            break;
        }
        
        delete trace;
    }
    
    vecOrigin[0] = vecSaved[0]; // x
    vecOrigin[1] = vecSaved[1]; // y
    vecOrigin[2] = vecSaved[2];

    vecOrigin[0] -= 100.0; // x
    vecOrigin[1] -= 100.0; // y
    vecOrigin[2] -= 0.0;
    
    for(int pos = 0; pos <= 11; pos++) // Check for position
    {            
        vecOrigin[0] += 10.5;
        vecOrigin[1] += 10.5;
        vecOrigin[2] += 10.0;
        
        Handle trace = TR_TraceHullFilterEx(vecOrigin, vecOrigin, vecMin, vecMax, MASK_PLAYERSOLID, UTIL_TraceEntityFilterHull, client);
        
        if(TR_DidHit(trace))
        {
            i_index = 1;
        } else {
            i_index = -1;
            delete trace;
            break;
        }
        
        delete trace;
    }
    
    vecOrigin[0] = vecSaved[0]; // x
    vecOrigin[1] = vecSaved[1]; // y
    vecOrigin[2] = vecSaved[2];

    vecOrigin[0] -= 0.0; // x
    vecOrigin[1] -= 100.0; // y
    vecOrigin[2] -= 0.0;
    
    for(int pos = 0; pos <= 11; pos++) // Check for position
    {            
        vecOrigin[0] += 10.5;
        vecOrigin[1] += 10.5;
        vecOrigin[2] += 10.0;
        
        Handle trace = TR_TraceHullFilterEx(vecOrigin, vecOrigin, vecMin, vecMax, MASK_PLAYERSOLID, UTIL_TraceEntityFilterHull, client);
        
        if(TR_DidHit(trace))
        {
            i_index = 1;
        } else {
            i_index = -1;
            delete trace;
            break;
        }
        
        delete trace;
    }
    
    vecOrigin[0] = vecSaved[0]; // x
    vecOrigin[1] = vecSaved[1]; // y
    vecOrigin[2] = vecSaved[2];

    vecOrigin[0] -= 0.0; // x
    vecOrigin[1] -= 0.0; // y
    vecOrigin[2] -= 0.0;
    
    for(int pos = 0; pos <= 11; pos++) // Check for position
    {            
        vecOrigin[0] += 10.5;
        vecOrigin[1] += 10.5;
        vecOrigin[2] += 10.0;
        
        Handle trace = TR_TraceHullFilterEx(vecOrigin, vecOrigin, vecMin, vecMax, MASK_PLAYERSOLID, UTIL_TraceEntityFilterHull, client);
        
        if(TR_DidHit(trace))
        {
            i_index = 1;
        } else {
            i_index = -1;
            delete trace;
            break;
        }
        
        delete trace;
    }
    
    return i_index;
}

stock int UTIL_GetRandomHuman() 
{ 
    int[] iClients = new int[MaxClients];
    int iClientsNum, i;
    
    for (i = 1; i <= MaxClients; i++) 
    { 
        if (UTIL_IsValidAlive(i) && GetClientTeam(i) == CS_TEAM_CT)
        {
            iClients[iClientsNum++] = i; 
        }
    } 
    
    if (iClientsNum > 0)
    {
        return iClients[GetRandomInt(0, iClientsNum-1)]; 
    }
    
    return 0;
}
stock void UTIL_LoadSounds() {
	char SoundPath[PLATFORM_MAX_PATH];
	KeyValues Sounds = new KeyValues("Sounds");
	BuildPath(Path_SM, SoundPath, sizeof(SoundPath), "configs/swarm/sounds.cfg");
	
	if (!Sounds.ImportFromFile(SoundPath)) {
		LogError("Couldn't import: \"%s\"", SoundPath);
		return;
	}

	if (!Sounds.GotoFirstSubKey(false)) {
		LogError("No sounds in: \"%s\"", SoundPath);
		return;
	}
	Sounds.Rewind();
	char key[64], sound[PLATFORM_MAX_PATH];
	
	if (Sounds.JumpToKey("human_win")) {
		if (Sounds.GotoFirstSubKey(false)) {
			int i;
			do {
				Sounds.GetSectionName(key, sizeof(key));
				Sounds.GetString(NULL_STRING,sound,sizeof(sound));
				g_HumanWinSounds[i] = sound;
				UTIL_LoadSound(g_HumanWinSounds[i]);
				i++;
				
			} while (Sounds.GotoNextKey(false));
		}
		else {
			LogMessage("No Human win sounds found. Skip");
		}
		Sounds.GoBack();
	}
	if (Sounds.JumpToKey("zombie_win")) {
		if (Sounds.GotoFirstSubKey(false)) {
			int i;
			do {
				Sounds.GetSectionName(key, sizeof(key));
				Sounds.GetString(NULL_STRING,sound,sizeof(sound));
				g_ZombieWinSounds[i] = sound;
				UTIL_LoadSound(g_ZombieWinSounds[i]);
				i++;
				
			} while (Sounds.GotoNextKey(false));
		}
		else {
			LogMessage("No Zombie win sounds found. Skip");
		}
		Sounds.GoBack();
	}
	if (Sounds.JumpToKey("countdown")) {
		if (Sounds.GotoFirstSubKey(false)) {
			int i;
			do {
				Sounds.GetSectionName(key, sizeof(key));
				Sounds.GetString(NULL_STRING,sound,sizeof(sound));
				g_CountdownSounds[i] = sound;
				UTIL_LoadSound(g_CountdownSounds[i]);
				i++;
				
			} while (Sounds.GotoNextKey(false));
		}
		else {
			LogMessage("No Countdown sounds found. Skip");
		}
		Sounds.GoBack();
	}
}

stock void UTIL_LoadSound(char[] sound) {
	char soundsPath[PLATFORM_MAX_PATH];
	Format(soundsPath, PLATFORM_MAX_PATH, "sound/%s", sound);
	if (FileExists(soundsPath)) {
		UTIL_FakePrecacheSoundEx(sound);
		AddFileToDownloadsTable(soundsPath);
	}
	else {
		LogError("Cannot locate sounds file: '%s'", soundsPath);
	}

}

stock void UTIL_DEBUG_PrintButtons(int buttons, const char[] message) {
    char button_text[128];
    Format(button_text, sizeof(button_text), "|");
    if (buttons & IN_ATTACK)
        Format(button_text, sizeof(button_text), "%sIN_ATTACK|", button_text);
    if (buttons & IN_JUMP)
        Format(button_text, sizeof(button_text), "%sIN_JUMP|", button_text);
    if (buttons & IN_DUCK)
        Format(button_text, sizeof(button_text), "%sIN_DUCK|", button_text);
    if (buttons & IN_FORWARD)
        Format(button_text, sizeof(button_text), "%sIN_FORWARD|", button_text);
    if (buttons & IN_BACK)
        Format(button_text, sizeof(button_text), "%sIN_BACK|", button_text);
    if (buttons & IN_USE)
        Format(button_text, sizeof(button_text), "%sIN_USE|", button_text);
    if (buttons & IN_CANCEL)
        Format(button_text, sizeof(button_text), "%sIN_CANCEL|", button_text);
    if (buttons & IN_LEFT)
        Format(button_text, sizeof(button_text), "%sIN_LEFT|", button_text);
    if (buttons & IN_RIGHT)
        Format(button_text, sizeof(button_text), "%sIN_RIGHT|", button_text);
    if (buttons & IN_MOVELEFT)
        Format(button_text, sizeof(button_text), "%sIN_MOVELEFT|", button_text);
    if (buttons & IN_MOVERIGHT)
        Format(button_text, sizeof(button_text), "%sIN_MOVERIGHT|", button_text);
    if (buttons & IN_ATTACK2)
        Format(button_text, sizeof(button_text), "%sIN_ATTACK2|", button_text);
    if (buttons & IN_RUN)
        Format(button_text, sizeof(button_text), "%sIN_RUN|", button_text);
    if (buttons & IN_RELOAD)
        Format(button_text, sizeof(button_text), "%sIN_RELOAD|", button_text);
    if (buttons & IN_ALT1)
        Format(button_text, sizeof(button_text), "%sIN_ALT1|", button_text);
    if (buttons & IN_ALT2)
        Format(button_text, sizeof(button_text), "%sIN_ALT2|", button_text);
    if (buttons & IN_SCORE)
        Format(button_text, sizeof(button_text), "%sIN_SCORE|", button_text);
    if (buttons & IN_SPEED)
        Format(button_text, sizeof(button_text), "%sIN_SPEED|", button_text);
    if (buttons & IN_ZOOM)
        Format(button_text, sizeof(button_text), "%sIN_ZOOM|", button_text);
    if (buttons & IN_WEAPON1)
        Format(button_text, sizeof(button_text), "%sIN_WEAPON1|", button_text);
    if (buttons & IN_WEAPON2)
        Format(button_text, sizeof(button_text), "%sIN_WEAPON2|", button_text);
    if (buttons & IN_BULLRUSH)
        Format(button_text, sizeof(button_text), "%sIN_BULLRUSH|", button_text);
    if (buttons & IN_GRENADE1)
        Format(button_text, sizeof(button_text), "%sIN_GRENADE1|", button_text);
    if (buttons & IN_GRENADE2)
        Format(button_text, sizeof(button_text), "%sIN_GRENADE2|", button_text);
    if (buttons & IN_ATTACK3)
        Format(button_text, sizeof(button_text), "%sIN_ATTACK3", button_text);
    PrintToChatAll("%s: %s", message, button_text);
}