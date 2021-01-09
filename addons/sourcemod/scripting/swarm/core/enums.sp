enum struct g_esZombieSounds {
    char Unique[64]; // Zombie Unique name.
    ArrayList DeathSounds; // When Zombie Dies
    ArrayList Footsteps; // When Zombie Walks
    ArrayList Hit; // When zombie hits person
    ArrayList Miss; // When zombie hits nothing (miss)
    ArrayList Pain; // When zombie gets hurt
    ArrayList Idle; // Sound every x seconds
}
enum struct g_esZombieClass {
    int dataID;
    int dataHP;
    int dataAbilityButton;
    float dataCooldown;
    float dataSpeed;
    float dataGravity;
    float dataDamage;
    float dataAttackSpeed;
    char dataName[MAX_CLASS_NAME_SIZE];
    char dataDescription[MAX_CLASS_DESC_SIZE];
    char dataModel[MAX_CLASS_DESC_SIZE];
    char dataArms[MAX_CLASS_DESC_SIZE];
    bool dataExcluded;
    char dataUniqueName[MAX_CLASS_UNIQUE_NAME_SIZE];
}

enum struct g_esZombieAbility {
    int abilityID;
    int abilityZombieClass;
    float abilityDuration;
    float abilityCooldown;
    int abilityButtons;
    bool abilityExcluded;
    char abilityName[MAX_ABILITY_NAME_SIZE];
    char abilityDescription[MAX_ABILITY_DESC_SIZE];
    char abilityUniqueName[MAX_ABILITY_UNIQUE_NAME_SIZE];
}

enum struct g_esPlayerAbility {
    int paID;
    int paClient;
    int paZombieClass;
    float paDuration;
    float paCooldown;
    float paCurrentDuration;
    float paCurrentCooldown;
    int paState;
    int paButtons;
    bool paExcluded;
    char paName[MAX_ABILITY_NAME_SIZE];
    char paDescription[MAX_ABILITY_DESC_SIZE];
    char paUniqueName[MAX_ABILITY_UNIQUE_NAME_SIZE];
    Handle paTimerDuration;
    Handle paTimerCooldown;
}