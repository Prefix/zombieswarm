#if defined _zombiemod_included
  #endinput
#endif
#define _zombiemod_included

#define ZOMBIES_TEAM 2
#define HUMAN_TEAM 3

#define DISTANCE_BEFORE 3000.0 // Distance before pulling

// Checks if user connected, whithout any errors.
#define IsValidClient(%1)  ( 1 <= %1 <= MaxClients && IsClientInGame(%1) )

// Checks if user alive, whithout any errors.
#define IsValidAlive(%1) ( 1 <= %1 <= MaxClients && IsClientInGame(%1) && IsPlayerAlive(%1) )

methodmap ZMPlayer {
      // Constructor
      public native ZMPlayer(int client);
      // Methods
      // XP related
      property int Client {
            public native get();
      }
      property int Level {
            public native get();
      }
      property int XP {
            public native get();
            public native set(const int val);
      }
      property bool Ghost {
            public native get();
            public native set(const bool val);
      }
      property int Team {
            public native get();
            public native set(const int val);
      }
      property int ZombieClass {
            public native get();
            public native set(const int val);
      }
      property int LastButtons {
            public native get();
            public native set(const int val);
      }
      property bool OverrideHint {
            public native get();
            public native set(const bool val);
      }
      // Zombie class related
      public native void OverrideHintText(char[] text);
}

methodmap ZombieClass {
      // Constructor
      public native ZombieClass(char[] name, char[] desc, char[] model,char[] arms = "", int health, float damage, float speed, float gravity, bool excluded = false);
      // Methods
      property int ID {
            public native get();
      }
      property int Health {
            public native get();
            public native set(const int val);
      }
      property float Speed {
            public native get();
            public native set(const float val);
      }
      property float Gravity {
            public native get();
            public native set(const float val);
      }
      property float Damage {
            public native get();
            public native set(const float val);
      }
      property bool Excluded {
            public native get();
            public native set(const bool val);
      }
      // Zombie class related
      public native void GetName(char[] text, int size);
      public native void SetName(char[] text, int size);
      public native void GetDesc(char[] text, int size);
      public native void SetDesc(char[] text, int size);
      public native void GetModel(char[] text, int size);
      public native void SetModel(char[] text, int size);
}

forward void onZCSelected(int client, int zClass);

forward void onZRightClick(int client, int zClass, int buttons);

native bool isGhost( int client );

native int getTeam( int client, bool trueform = false );

native void setTeam( int client, int team );

native int getZombieClass( int client );

native int getRandomZombieClass();

native void setZombieClass( int client, int class );

native int registerZombieClass(char[] name, char[] desc, char[] model, int health, float damage, float speed, float gravity, bool excluded = false);

native int getLastButtons( int client );

stock void velocityByAim(int client, float distance, float velocity[3])
{
	float vAngles[3];
	
	GetClientEyeAngles(client, vAngles);
	
	velocity[0] = Cosine(DegToRad(vAngles[1])) * distance;
	velocity[1] = Sine(DegToRad(vAngles[1])) * distance;
	velocity[2] = Sine(DegToRad(-vAngles[0])) * distance;
}

stock bool FakePrecacheSoundEx( const char[] szPath )
{
	char sPathStar[PLATFORM_MAX_PATH];
	Format(sPathStar, sizeof(sPathStar), "*/%s", szPath);
	
	AddToStringTable( FindStringTable( "soundprecache" ), sPathStar );
	return true;
}

stock bool IsClientInTargetView(int client, int target)
{
	float playerOrigin[3];

	bool HitPlayer = false;
				
	float targetOrigin[3], distanceBetween;

	GetClientAbsOrigin( client, playerOrigin);
	GetClientAbsOrigin ( target, targetOrigin );
	distanceBetween = GetVectorDistance ( targetOrigin, playerOrigin );
						
	if ( distanceBetween >= DISTANCE_BEFORE )
	{
		HitPlayer = false
		return HitPlayer;
	}
						
	targetOrigin[0] -= 20.0;
	targetOrigin[2] -= 0.0;
						
	playerOrigin[0] -= 20.0
	playerOrigin[2] -= 0.0
				
	for(new pos = 0; pos <= 11; pos++) // Check for position
	{
		targetOrigin[0] += 2.5;
		targetOrigin[2] += 6.0;
							
		playerOrigin[0] += 2.5;
		playerOrigin[2] += 6.0;
										
		Handle trace = TR_TraceRayFilterEx( playerOrigin, targetOrigin, MASK_SOLID, RayType_EndPoint, TraceEntityFilterRay);
						
		if ( !TR_DidHit(trace) )
		{
			HitPlayer = true;
		}

		delete trace;
	}
	
	return HitPlayer;
}

stock fadePlayer(int client, int duration = 5, int time = 6, color[4] = {0, 0, 0, 255} )
{
	Handle message = StartMessageOne("Fade", client, USERMSG_RELIABLE);
	PbSetInt(message, "duration", duration*300);
	PbSetInt(message, "hold_time", time*300);
	PbSetInt(message, "flags", 0x0009);
	PbSetColor(message, "clr", color);
	EndMessage();
} 

stock void createAttachParticle(int client, const char[] effectName, float fPos[3], const char[] attachTo, float lifetime)
{    
    int particle = createParticle(effectName);
    
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
    
    particleDeathTimer(particle, lifetime);
}

stock int createParticle(const char[] effectName)
{
    int particle = CreateEntityByName("info_particle_system");
    if (IsValidEdict(particle))
    {
        DispatchKeyValue(particle, "effect_name", effectName);

        return particle;
    }
    
    return -1;
}

stock void particleDeathTimer(int entity, float lifetime)
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

stock void precacheParticle( const char[] effectName )
{
    static numStringTable = INVALID_STRING_TABLE;
    
    if (numStringTable == INVALID_STRING_TABLE)
    {
        numStringTable = FindStringTable("ParticleEffectNames");
    }
    
    AddToStringTable(numStringTable, effectName );
}

stock void playClientCommandSound(int client, const char[] sound)
{
	ClientCommand(client, "playgamesound Music.StopAllMusic");
	ClientCommand(client, "play */%s", sound);
}

public void showHintMessage(int client, const char[] message)
{
	Handle hMessage = StartMessageOne("HintText", client);
	PbSetString(hMessage, "text", message);
	EndMessage();
}
