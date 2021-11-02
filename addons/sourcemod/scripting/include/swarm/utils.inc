#if defined _zombieswarm_utils_included
  #endinput
#endif
#define _zombieswarm_utils_included
#include <autoexecconfig>
#include <sdktools>

#define DISTANCE_BEFORE 3000.0

stock void ZS_StartConfig(char[] filename, char[] directory = "zombieswarm")
{
    AutoExecConfig_SetCreateDirectory(true);
    AutoExecConfig_SetCreateFile(true);
    AutoExecConfig_SetFile(filename, directory);
}

stock void ZS_EndConfig()
{
    AutoExecConfig_ExecuteFile();
    AutoExecConfig_CleanFile();
}

stock void UTIL_Fade(int client, int duration = 5, int hold = 300, int color[4]= {0, 0, 0, 255}) {

    Handle message = StartMessageOne("Fade", client, USERMSG_RELIABLE);
    PbSetInt(message, "duration", duration*300);
    PbSetInt(message, "hold_time", hold*300);
    PbSetInt(message, "flags", 0x0009);
    PbSetColor(message, "clr", color);
    EndMessage();

} 
stock void UTIL_ShakeScreen(int client, float duration = 3.0, float amplitude = 2.0, float freq = 1.0) {

    Handle message = StartMessageOne("Shake", client, 1);
    PbSetInt(message, "command", 0);
    PbSetFloat(message, "local_amplitude", amplitude);
    PbSetFloat(message, "frequency", freq);
    PbSetFloat(message, "duration", duration);
    EndMessage();
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
stock void UTIL_PlaySoundToClient(int client, char[] sound, float volume = 0.8) {
    ClientCommand(client, "playgamesound Music.StopAllMusic");
    EmitSoundToClient(client, sound, _, _, _, _, volume);
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
