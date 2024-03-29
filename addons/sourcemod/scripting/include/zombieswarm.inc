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
#define MAX_CLASS_MODEL_SIZE PLATFORM_MAX_PATH
#define MAX_CLASS_ARMS_SIZE PLATFORM_MAX_PATH
#define MAX_CLASS_UNIQUE_NAME_SIZE 64

#define MAX_ABILITY_NAME_SIZE 64
#define MAX_ABILITY_DESC_SIZE 128
#define MAX_ABILITY_UNIQUE_NAME_SIZE 64

#define MAX_CLASS_ID 10

#define ABILITY_NO_DURATION -1.0

#define API_MAX_PLAYER_ABILITIES 20

// Fowards
forward void ZS_OnLoaded();
forward void ZS_OnZombieSelected(int client);
forward void ZS_OnAbilityButtonPressed(int client, int playerability_id);
forward void ZS_OnAbilityButtonReleased(int client, int playerability_id);
// Ability Start, Ability Finish/Interrupted, Cooldown ended
forward void ZS_OnAbilityStarted(int client, int playerability_id);
forward void ZS_OnCooldownStarted(int client, int playerability_id);
forward void ZS_OnCooldownEnded(int client, int playerability_id);
forward Action ZS_ClassPreSelect(int client, int &classid);

native int ZS_GetRandomZombieClass();
native bool ZS_IsClientZombie(int client);

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
    // Methods
    public native void OverrideHintText(const char[] text);
    public native int GetAbilityByUnique(const char[] ability_unique_id);
    public native int GetAbilityByID(const int uniqueid);
    public native bool GetPlayerAbilities(int[] abilities, int &found_abilities);
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
    property float AttackSpeed {
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
    public native void GetName(char[] text, int size);
    public native void SetName(const char[] text, int size);
    public native void GetDesc(char[] text, int size);
    public native void SetDesc(const char[] text, int size);
    public native void GetModel(char[] text, int size);
    public native void SetModel(const char[] text, int size);
    public native void GetArms(char[] text, int size);
    public native void SetArms(const char[] text, int size);
    public native void GetUnique(char[] text, int size);
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
    property float Duration {
        public native get();
        public native set(const float val);
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
    public native void GetName(char[] text, int size);
    public native void SetName(const char[] text, int size);
    public native void GetDesc(char[] text, int size);
    public native void SetDesc(const char[] text, int size);
    public native void GetUnique(char[] text, int size);
}

// to be used later
#define stateIdle 0
#define stateRunning 1
#define stateCooldown 2
#define stateDisabled 3


methodmap PlayerAbility  {
    // Constructor
    public native PlayerAbility(int client, const char[] unique);
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
    property float Duration {
        public native get();
        public native set(const float val);
    }
    property float Cooldown {
        public native get();
        public native set(const float val);
    }
    property int Buttons {
        public native get();
        public native set(const int val);
    }
    property int Client {
        public native get();
    }
    property int State {
        public native get();
        public native set(const int val);
    }
    property float CurrentCooldown {
        public native get();
        public native set(const float val);
    }
    property float CurrentDuration {
        public native get();
        public native set(const float val);
    }
    // Methods
    public native void GetName(char[] text, int size);
    public native void SetName(const char[] text, int size);
    public native void GetDesc(char[] text, int size);
    public native void SetDesc(const char[] text, int size);
    public native void GetUnique(char[] text, int size);
    public native void AbilityFinished();
    public native void AbilityStarted();
    public native void AbilityStartedNoDuration();
    public native void ForceCooldownEnd();
}

