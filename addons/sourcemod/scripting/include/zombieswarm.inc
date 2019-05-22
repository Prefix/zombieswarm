#if defined _zombieswarm_included
  #endinput
#endif
#define _zombieswarm_included

#define ZS_PLUGIN_NAME "Zombie Swarm"
#define ZS_PLUGIN_AUTHOR "Zombie Swarm Contributors"
#define ZS_PLUGIN_DESCRIPTION "Zombie Swarm mod. On this mod you need to kill humans, not to infect them. Also zombie classes with special powers."
#define ZS_PLUGIN_VERSION "Untracked"
#define ZS_PLUGIN_URL "https://github.com/Prefix/zombieswarm/"

#define ZOMBIES_TEAM 2
#define HUMAN_TEAM 3

#define MAX_CLASS_NAME_SIZE 64
#define MAX_CLASS_DESC_SIZE 128
#define MAX_CLASS_MODEL_SIZE 128
#define MAX_CLASS_ARMS_SIZE 128
#define MAX_CLASS_UNIQUE_NAME_SIZE 64

#define MAX_ABILITY_NAME_SIZE 64
#define MAX_ABILITY_DESC_SIZE 128
#define MAX_ABILITY_UNIQUE_NAME_SIZE 64

#define MAX_CLASS_ID 10

#define DISTANCE_BEFORE 3000.0 // Distance before pulling

// Checks if user connected, whithout any errors.
#define IsValidClient(%1)  ( 1 <= %1 <= MaxClients && IsClientInGame(%1) )

// Checks if user alive, whithout any errors.
#define IsValidAlive(%1) ( 1 <= %1 <= MaxClients && IsClientInGame(%1) && IsPlayerAlive(%1) )

// Fowards
forward void ZS_OnLoaded();
forward void ZS_OnAbilityButtonPressed(int client, int buttons);
forward void ZS_OnAbilityButtonReleased(int client, int buttons);
forward void ZS_OnCooldownEnded(int client);
forward void ZS_OnCooldownStarted(int client);
forward void ZS_OnZombieSelected(int client);

// natives

native void ZS_AbilityFinished(int client);
native void ZS_AbilityStarted(int client);

methodmap ZMPlayer {
    // Constructor
    public native ZMPlayer(int client);
    // Properties
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
    property bool isCooldown {
        public native get();
        public native set(const bool val);
    }
    // Methods
    public native void OverrideHintText(char[] text);
}

methodmap PlayerAbility {
    // Constructor
    public native PlayerAbility(ZMPlayer client, ZombieAbility ability);
    // Properties
    property int ID {
    	public native get();
    }
    property bool isCooldown {
        public native get();
        public native set(const bool val);
    }
    property int Client {
        public native get();
    }
    property int ZombieClass {
        public native get();
    }
    property bool isPassive {
        public native get();
    }
    property bool isActive {
        public native get();
    }
    property float Cooldown {
        public native get();
        public native set(const float val);
    }
    property int Buttons {
        public native get();
        public native set(const int val);
    }
}

enum AbilityTypes {
    ZM_ABILITY_NONE,
    ZM_ABILITY_PASSIVE,
    ZM_ABILITY_ACTIVE,
    ZM_ABILITY_TRIGGERED
}
enum StartType {
    ZM_ABILITY_START_NONE,
    ZM_ABILITY_START_PASSIVE,
    ZM_ABILITY_START_TRIGGERED,
    ZM_ABILITY_START_PRESSBUTTON,
    ZM_ABILITY_START_HOLDBUTTON,
}
enum EndType {
    ZM_ABILITY_END_NONE = (1 << 0),
    ZM_ABILITY_END_RELEASEBUTTON = (1 << 1),
    ZM_ABILITY_END_TRIGGERED = (1 << 2),
    ZM_ABILITY_END_DURATION = (1 << 3)
}

methodmap ZombieAbility {
    // Constructor
    public native ZombieAbility(ZombieClass zclass, const char[] unique);
    // Properties
    property int ZombieClass {
        public native get();
    }
    property int ID {
    	public native get();
    }
    property bool Excluded {
        public native get();
        public native set(const bool val);
    }
    property int AbilityType {
        public native get();
        public native set(const int val);
    }
    property int StartType {
        public native get();
        public native set(const int val);
    }
    property int EndType {
        public native get();
        public native set(const int val);
    }
    property int MaximumDuration {
        public native get();
        public native set(const int val);
    }
    property float Cooldown {
        public native get();
        public native set(const float val);
    }
    property int Buttons {
        public native get();
        public native set(const int val);
    }
    // Methods
    public native void GetUniqueName(char[] text, int size);
    public native void SetUniqueName(const char[] text, int size);
    public native void GetName(char[] text, int size);
    public native void SetName(const char[] text, int size);
    public native void GetDesc(char[] text, int size);
    public native void SetDesc(const char[] text, int size);
    public native void GetUnique(char[] text, int size);
}

methodmap ZombieClass {
    // Constructor
    public native ZombieClass(const char[] unique);
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
    property int Button {
        public native get();
        public native set(int val);
    }
    property float Cooldown {
        public native get();
        public native set(float val);
    }
    // Zombie class related
    public native void GetUniqueName(char[] text, int size);
    public native void SetUniqueName(const char[] text, int size);
    public native void GetName(char[] text, int size);
    public native void SetName(const char[] text, int size);
    public native void GetDesc(char[] text, int size);
    public native void SetDesc(const char[] text, int size);
    public native void GetModel(char[] text, int size);
    public native void SetModel(const char[] text, int size);
    public native void GetUnique(char[] text, int size);
}

native bool isGhost( int client );

native int getTeam( int client, bool trueform = false );

native void setTeam( int client, int team );

native int getRandomZombieClass();

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
