enum g_eZombieClass {
    dataID,
    dataHP,
    dataAbilityButton,
    Float:dataCooldown,
    Float:dataSpeed,
    Float:dataGravity,
    Float:dataDamage,
    String:dataName[MAX_CLASS_NAME_SIZE],
    String:dataDescription[MAX_CLASS_DESC_SIZE],
    String:dataModel[MAX_CLASS_DESC_SIZE],
    String:dataArms[MAX_CLASS_DESC_SIZE],
    bool:dataExcluded,
    String:dataUniqueName[MAX_CLASS_UNIQUE_NAME_SIZE]
}

enum g_eZombieAbility {
    abilityID,
    abilityZombieClass,
    Float:abilityDuration,
    Float:abilityCooldown,
    abilityButtons,
    bool:abilityExcluded,
    String:abilityName[MAX_ABILITY_NAME_SIZE],
    String:abilityDescription[MAX_ABILITY_DESC_SIZE],
    String:abilityUniqueName[MAX_ABILITY_UNIQUE_NAME_SIZE]
}

enum g_ePlayerAbility {
    paID,
    paClient,
    paZombieClass,
    Float:paDuration,
    Float:paCooldown,
    Float:paCurrentDuration,
    Float:paCurrentCooldown,
    abilityState:paState,
    paButtons,
    bool:paExcluded,
    String:paName[MAX_ABILITY_NAME_SIZE],
    String:paDescription[MAX_ABILITY_DESC_SIZE],
    String:paUniqueName[MAX_ABILITY_UNIQUE_NAME_SIZE]
}