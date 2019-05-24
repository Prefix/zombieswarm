public void InitNatives() {
    CreateNative("isGhost", nativeIsGhost);
    CreateNative("getTeam", nativeGetTeam);
    CreateNative("setTeam", nativeSetTeam);
    CreateNative("getRandomZombieClass", nativeGetRandomZombieClass);
    CreateNative("ZS_AbilityFinished", nativeAbilityFinished); 
}

public void InitMethodMaps() {
    // Our MethodMap

    // use MethodMapName.FunctionName format
    CreateNative("ZMPlayer.ZMPlayer", Native_ZMPlayer_Constructor);
    // Properties
    CreateNative("ZMPlayer.Client.get", Native_ZMPlayer_ClientGet);
    CreateNative("ZMPlayer.Level.get", Native_ZMPlayer_LevelGet);
    //CreateNative("ZMPlayer.Level.set", Native_ZMPlayer_LevelSet);
    CreateNative("ZMPlayer.XP.get", Native_ZMPlayer_XPGet);
    CreateNative("ZMPlayer.XP.set", Native_ZMPlayer_XPSet);
    CreateNative("ZMPlayer.Ghost.get", Native_ZMPlayer_GhostGet);
    CreateNative("ZMPlayer.Ghost.set", Native_ZMPlayer_GhostSet);
    CreateNative("ZMPlayer.Team.get", Native_ZMPlayer_TeamGet);
    CreateNative("ZMPlayer.Team.set", Native_ZMPlayer_TeamSet);
    CreateNative("ZMPlayer.ZombieClass.get", Native_ZMPlayer_ZMClassGet);
    CreateNative("ZMPlayer.ZombieClass.set", Native_ZMPlayer_ZMClassSet);
    CreateNative("ZMPlayer.LastButtons.get", Native_ZMPlayer_LastButtonsGet);
    CreateNative("ZMPlayer.LastButtons.set", Native_ZMPlayer_LastButtonsSet);
    CreateNative("ZMPlayer.OverrideHint.get", Native_ZMPlayer_OverrideHintGet);
    CreateNative("ZMPlayer.OverrideHint.set", Native_ZMPlayer_OverrideHintSet);
    CreateNative("ZMPlayer.isCooldown.get", Native_ZMPlayer_isCooldownGet);
    CreateNative("ZMPlayer.isCooldown.set", Native_ZMPlayer_isCooldownSet);
    // Functions
    CreateNative("ZMPlayer.OverrideHintText", Native_ZMPlayer_OverrideHintText);

    // Our MethodMap -> ZombieClass
    CreateNative("ZombieClass.ZombieClass", Native_ZombieClass_Constructor);
    // Class ID
    CreateNative("ZombieClass.ID.get", Native_ZombieClass_IDGet);
    // Properties
    CreateNative("ZombieClass.Health.get", Native_ZombieClass_HealthGet);
    CreateNative("ZombieClass.Health.set", Native_ZombieClass_HealthSet);
    CreateNative("ZombieClass.Speed.get", Native_ZombieClass_SpeedGet);
    CreateNative("ZombieClass.Speed.set", Native_ZombieClass_SpeedSet);
    CreateNative("ZombieClass.Gravity.get", Native_ZombieClass_GravityGet);
    CreateNative("ZombieClass.Gravity.set", Native_ZombieClass_GravitySet);
    CreateNative("ZombieClass.Damage.get", Native_ZombieClass_DamageGet);
    CreateNative("ZombieClass.Damage.set", Native_ZombieClass_DamageSet);
    CreateNative("ZombieClass.Excluded.get", Native_ZombieClass_ExcludedGet);
    CreateNative("ZombieClass.Excluded.set", Native_ZombieClass_ExcludedSet);
    CreateNative("ZombieClass.Button.get", Native_ZombieClass_ButtonGet);
    CreateNative("ZombieClass.Button.set", Native_ZombieClass_ButtonSet);
    CreateNative("ZombieClass.Cooldown.get", Native_ZombieClass_CooldownGet);
    CreateNative("ZombieClass.Cooldown.set", Native_ZombieClass_CooldownSet);
    // Functions
    CreateNative("ZombieClass.GetName", Native_ZombieClass_NameGet);
    CreateNative("ZombieClass.SetName", Native_ZombieClass_NameSet);
    CreateNative("ZombieClass.GetDesc", Native_ZombieClass_DescGet);
    CreateNative("ZombieClass.SetDesc", Native_ZombieClass_DescSet);
    CreateNative("ZombieClass.GetModel", Native_ZombieClass_ModelGet);
    CreateNative("ZombieClass.SetModel", Native_ZombieClass_ModelSet);
    CreateNative("ZombieClass.GetArms", Native_ZombieClass_ArmsGet);
    CreateNative("ZombieClass.SetArms", Native_ZombieClass_ArmsSet);
    CreateNative("ZombieClass.GetUnique", Native_ZombieClass_UniqueGet);

    // Our MethodMap -> ZombieAbility
    CreateNative("ZombieAbility.ZombieAbility", Native_ZombieAbility_Constructor);
    // Class ID
    CreateNative("ZombieAbility.ID.get", Native_ZombieAbility_IDGet);
    // Properties
    CreateNative("ZombieAbility.Excluded.get", Native_ZombieAbility_ExcludedGet);
    CreateNative("ZombieAbility.Excluded.set", Native_ZombieAbility_ExcludedSet);
    CreateNative("ZombieAbility.Duration.get", Native_ZombieAbility_DurationGet);
    CreateNative("ZombieAbility.Duration.set", Native_ZombieAbility_DurationSet);
    CreateNative("ZombieAbility.Cooldown.get", Native_ZombieAbility_CooldownGet);
    CreateNative("ZombieAbility.Cooldown.set", Native_ZombieAbility_CooldownSet);
    CreateNative("ZombieAbility.Buttons.get", Native_ZombieAbility_ButtonsGet);
    CreateNative("ZombieAbility.Buttons.set", Native_ZombieAbility_ButtonsSet);
    // Functions
    CreateNative("ZombieAbility.GetName", Native_ZombieAbility_NameGet);
    CreateNative("ZombieAbility.SetName", Native_ZombieAbility_NameSet);
    CreateNative("ZombieAbility.GetDesc", Native_ZombieAbility_DescGet);
    CreateNative("ZombieAbility.SetDesc", Native_ZombieAbility_DescSet);
    CreateNative("ZombieAbility.GetUnique", Native_ZombieAbility_UniqueGet);
}

public int InitForwards() {
    // Forwards
    g_hForwardZombieSelected = CreateGlobalForward("onZCSelected", ET_Ignore, Param_Cell, Param_Cell);
    g_hForwardZombieRightClick = CreateGlobalForward("onZRightClick", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
    g_hForwardZSOnLoaded = CreateGlobalForward("ZS_OnLoaded", ET_Ignore);
    g_hForwardAbilityButtonPressed = CreateGlobalForward("ZS_OnAbilityButtonPressed", ET_Ignore, Param_Cell, Param_Cell);
    g_hForwardAbilityButtonReleased = CreateGlobalForward("ZS_OnAbilityButtonReleased", ET_Ignore, Param_Cell, Param_Cell);
    // TODO: When we start implenting abilities
    //g_hForwardOnAbilityStarted = CreateGlobalForward("ZS_OnAbilityStarted", ET_Ignore, Param_Cell, Param_Cell);
    //g_hForwardOnAbilityFinished = CreateGlobalForward("ZS_OnAbilityFinished", ET_Ignore, Param_Cell, Param_Cell);
    //g_hForwardOnAbilityCDStarted = CreateGlobalForward("ZS_OnCooldownStarted", ET_Ignore, Param_Cell, Param_Cell);
    //g_hForwardOnAbilityCDEnded = CreateGlobalForward("ZS_OnCooldownEnded", ET_Ignore, Param_Cell, Param_Cell);
}


public int nativeIsGhost(Handle plugin, int numParams)
{
    int client = GetNativeCell( 1 );

    return g_bGhost[client];
}

public int nativeGetTeam(Handle plugin, int numParams)
{
    int client = GetNativeCell( 1 );
    bool trueform = GetNativeCell( 2 );
    if (trueform == true)
        return g_iTeam[client];

    return GetClientTeam(client);
}

public int nativeSetTeam(Handle plugin, int numParams)
{
    int client = GetNativeCell( 1 );
    int team = GetNativeCell( 2 );

    g_iTeam[client] = team;
    if (!IsValidClient(client))
        return;

    if (!IsPlayerAlive(client)) 
        ChangeClientTeam(client, team);
    else 
        CS_SwitchTeam(client, team);
}

public int nativeGetZombieClass(Handle plugin, int numParams)
{
    int client = GetNativeCell( 1 );

    return g_iZombieClass[client];
}

public int nativeGetRandomZombieClass(Handle plugin, int numParams)
{
    return getRandZombieClass();
}

public void callZombieSelected(int client, int zClass)
{
    // Start forward call
    Call_StartForward(g_hForwardZombieSelected);

    // Push the parameters
    Call_PushCell(client);
    Call_PushCell(zClass);

    // Finish the call
    Call_Finish();
}

public void callZombieRightClick(int client, int zClass, int buttons)
{
    // Start forward call
    Call_StartForward(g_hForwardZombieRightClick);

    // Push the parameters
    Call_PushCell(client);
    Call_PushCell(zClass);
    Call_PushCell(buttons);

    // Finish the call
    Call_Finish();
}
//    CreateNative("ZMPlayer.ZMPlayer", Native_ZMPlayer_Constructor);
public int Native_ZMPlayer_Constructor(Handle plugin, int numParams)
{
    int client = view_as<int>(GetNativeCell(1));
    if ( IsValidClient( client ) ) {
        return view_as< int >( GetClientUserId( client ) );
    }
    return view_as< int >(-1);
}

public int Native_ZMPlayer_ClientGet(Handle plugin, int numParams) 
{
    ZMPlayer player = GetNativeCell(1);
    return GetClientOfUserId( view_as<int>(player) );
}

public int Native_ZMPlayer_LevelGet(Handle plugin, int numParams)
{
    ZMPlayer player = GetNativeCell(1);
    return getPlayerLevel(player.Client);
}

public int Native_ZMPlayer_XPGet(Handle plugin, int numParams)
{
    ZMPlayer player = GetNativeCell(1);
    return getPlayerUnlocks(player.Client);
}

public int Native_ZMPlayer_XPSet(Handle plugin, int numParams)
{
    ZMPlayer player = GetNativeCell(1);
    setPlayerUnlocks( player.Client, GetNativeCell(2));
}

public int Native_ZMPlayer_GhostGet(Handle plugin, int numParams)
{
    ZMPlayer player = GetNativeCell(1);
    return g_bGhost[player.Client];
}

public int Native_ZMPlayer_GhostSet(Handle plugin, int numParams)
{
    ZMPlayer player = GetNativeCell(1);
    setZombieGhostMode(player.Client, GetNativeCell(2));
}

public int Native_ZMPlayer_TeamGet(Handle plugin, int numParams)
{
    ZMPlayer player = GetNativeCell(1);
    return g_iTeam[player.Client];
}

public int Native_ZMPlayer_TeamSet(Handle plugin, int numParams)
{
    ZMPlayer player = GetNativeCell(1);
    int client = player.Client;
    int team = GetNativeCell( 2 );

    g_iTeam[client] = team;
    if (!IsValidClient(client))
        return;
    if (GetClientTeam(client) == team)
        return;

    if (!IsPlayerAlive(client)) 
        ChangeClientTeam(client, team);
    else 
        CS_SwitchTeam(client, team);
}

public int Native_ZMPlayer_ZMClassGet(Handle plugin, int numParams)
{
    ZMPlayer player = GetNativeCell(1);
    int client = player.Client;
    return g_iZombieClass[client];
}

public int Native_ZMPlayer_ZMClassSet(Handle plugin, int numParams)
{
    ZMPlayer player = GetNativeCell(1);
    int client = player.Client;
    // Set random zombie class
    g_iZombieClass[client] = GetNativeCell(2);
    setZombieClassParameters(client);
    callZombieSelected(client, g_iZombieClass[client]);
}

public int Native_ZMPlayer_LastButtonsGet(Handle plugin, int numParams)
{
    ZMPlayer player = GetNativeCell(1);
    int client = player.Client;
    return g_fLastButtons[client];
}

public int Native_ZMPlayer_LastButtonsSet(Handle plugin, int numParams)
{
    ZMPlayer player = GetNativeCell(1);
    int client = player.Client;
    g_fLastButtons[client] = GetNativeCell(2);
}

public int Native_ZMPlayer_OverrideHintGet(Handle plugin, int numParams)
{
    ZMPlayer player = GetNativeCell(1);
    int client = player.Client;
    return g_bOverrideHint[client];
}

public int Native_ZMPlayer_OverrideHintSet(Handle plugin, int numParams)
{
    ZMPlayer player = GetNativeCell(1);
    int client = player.Client;
    bool hint = GetNativeCell(2);
    if (g_bOverrideHint[client] == hint) return;

    if (!hint) {
        g_fHintSpeed[client] = TIMER_SPEED;
    } else {
        g_fHintSpeed[client] = 0.1;
    }

    if (g_hTimerGhostHint[client] != null) {
        delete g_hTimerGhostHint[client];
        g_hTimerGhostHint[client] = CreateTimer( g_fHintSpeed[client], ghostHint, client, TIMER_FLAG_NO_MAPCHANGE);
    }

    g_bOverrideHint[client] = hint;
}

public int Native_ZMPlayer_OverrideHintText(Handle plugin, int numParams)
{
    ZMPlayer player = GetNativeCell(1);
    int client = player.Client;
    GetNativeString(2, g_sOverrideHintText[client], MAX_HINT_SIZE);
}
public int Native_ZMPlayer_isCooldownSet(Handle plugin, int numParams) {
    ZMPlayer player = GetNativeCell(1);
    int client = player.Client;
    g_bCooldown[client] = GetNativeCell(2);
}
public int Native_ZMPlayer_isCooldownGet(Handle plugin, int numParams) {
    ZMPlayer player = GetNativeCell(1);
    int client = player.Client;
    return g_bCooldown[client];
}

//    Natives for MethodMap ZombieClass
public int Native_ZombieClass_Constructor(Handle plugin, int numParams)
{
    char temp_unique[MAX_CLASS_UNIQUE_NAME_SIZE];
    GetNativeString(1, temp_unique, sizeof(temp_unique));
    int temp_checker[g_eZombieClass];
    for (int i = 0; i < g_aZombieClass.Length; i++)
    {
        g_aZombieClass.GetArray(i, temp_checker[0]);
        if (StrEqual(temp_checker[dataUniqueName], temp_unique, false))
        {
            return -1;
        }
    }
    int temp_class[g_eZombieClass];
    Format(temp_class[dataName], MAX_CLASS_NAME_SIZE, "%s", DEFAULT_ZM_NAME);
    Format(temp_class[dataDescription], MAX_CLASS_DESC_SIZE, "%s", DEFAULT_ZM_DESC);
    Format(temp_class[dataModel], MAX_CLASS_MODEL_SIZE, "%s", DEFAULT_ZM_MODEL_PATH);
    Format(temp_class[dataArms], MAX_CLASS_ARMS_SIZE, "%s", DEFAULT_ZM_ARMS_PATH);
    Format(temp_class[dataUniqueName], MAX_CLASS_UNIQUE_NAME_SIZE, "%s", temp_unique);

    temp_class[dataHP] = view_as<int>(DEFAULT_ZM_HEALTH);
    temp_class[dataDamage] = view_as<float>(DEFAULT_ZM_DAMAGE);
    temp_class[dataSpeed] = view_as<float>(DEFAULT_ZM_SPEED);
    temp_class[dataGravity] = view_as<float>(DEFAULT_ZM_GRAVITY);
    temp_class[dataExcluded] = view_as<bool>(DEFAULT_ZM_EXCLUDED);
    temp_class[dataAbilityButton] = view_as<int>(DEFAULT_ZM_ABILITY_BUTTON);
    temp_class[dataCooldown] = view_as<float>(DEFAULT_ZM_COOLDOWN);
    temp_class[dataID] = g_iNumClasses;
    g_aZombieClass.PushArray(temp_class[0]);
    // TODO on zombie class register
    
    LogMessage("Zombie ID %i",g_iNumClasses);
    g_iNumClasses++;
    return temp_class[dataID];
}

public int Native_ZombieClass_IDGet(Handle plugin, int numParams)
{
    int temp_class = view_as<int>(GetNativeCell(1));
    return view_as<int>(temp_class);
}

public int Native_ZombieClass_HealthGet(Handle plugin, int numParams)
{
    int class_id = FindZombieIndex(view_as<int>(GetNativeCell(1)));
    return view_as<int>(g_aZombieClass.Get(class_id, dataHP));
}

public int Native_ZombieClass_HealthSet(Handle plugin, int numParams)
{
    int class_id = FindZombieIndex(view_as<int>(GetNativeCell(1)));
    int health = GetNativeCell(2);
    g_aZombieClass.Set(class_id, health, dataHP);
}

public int Native_ZombieClass_SpeedGet(Handle plugin, int numParams)
{
    int class_id = FindZombieIndex(view_as<int>(GetNativeCell(1)));
    return view_as<int>(g_aZombieClass.Get(class_id, dataSpeed));
}

public int Native_ZombieClass_SpeedSet(Handle plugin, int numParams)
{
    int class_id = FindZombieIndex(view_as<int>(GetNativeCell(1)));
    float speed = GetNativeCell(2);
    g_aZombieClass.Set(class_id, speed, dataSpeed);  
}

public int Native_ZombieClass_GravityGet(Handle plugin, int numParams)
{
    int class_id = FindZombieIndex(view_as<int>(GetNativeCell(1)));
    return view_as<int>(g_aZombieClass.Get(class_id, dataGravity));
}

public int Native_ZombieClass_GravitySet(Handle plugin, int numParams)
{
    int class_id = FindZombieIndex(view_as<int>(GetNativeCell(1)));
    float gravity = GetNativeCell(2);
    return view_as<int>(g_aZombieClass.Set(class_id, gravity, dataGravity));
}

public int Native_ZombieClass_ExcludedGet(Handle plugin, int numParams)
{
    int class_id = FindZombieIndex(view_as<int>(GetNativeCell(1)));
    return view_as<int>(g_aZombieClass.Set(class_id, dataExcluded));
}

public int Native_ZombieClass_ExcludedSet(Handle plugin, int numParams)
{
    int class_id = FindZombieIndex(view_as<int>(GetNativeCell(1)));
    bool excluded = GetNativeCell(2);
    g_aZombieClass.Set(class_id, excluded, dataExcluded);
}

public int Native_ZombieClass_ButtonGet(Handle plugin, int numParams)
{
    int class_id = FindZombieIndex(view_as<int>(GetNativeCell(1)));
    return view_as<int>(g_aZombieClass.Get(class_id, dataAbilityButton));
}

public int Native_ZombieClass_ButtonSet(Handle plugin, int numParams)
{
    int class_id = FindZombieIndex(view_as<int>(GetNativeCell(1)));
    int buttons = GetNativeCell(2);
    g_aZombieClass.Set(class_id, buttons, dataAbilityButton);
}

public int Native_ZombieClass_CooldownGet(Handle plugin, int numParams)
{
    int class_id = FindZombieIndex(view_as<int>(GetNativeCell(1)));
    return view_as<int>(g_aZombieClass.Get(class_id, dataCooldown));
}

public int Native_ZombieClass_CooldownSet(Handle plugin, int numParams)
{
    int class_id = FindZombieIndex(view_as<int>(GetNativeCell(1)));
    float cooldown = GetNativeCell(2);
    g_aZombieClass.Set(class_id, cooldown, dataCooldown);  
}

public int Native_ZombieClass_DamageGet(Handle plugin, int numParams)
{
    int class_id = FindZombieIndex(view_as<int>(GetNativeCell(1)));
    int temp_class[g_eZombieClass];
    g_aZombieClass.GetArray(class_id, temp_class[0]);
    return view_as<int>(temp_class[dataDamage]);
}

public int Native_ZombieClass_DamageSet(Handle plugin, int numParams)
{
    int class_id = FindZombieIndex(view_as<int>(GetNativeCell(1)));
    float damage = GetNativeCell(2);
    g_aZombieClass.Set(class_id, damage, dataDamage); 
}

public int Native_ZombieClass_NameGet(Handle plugin, int numParams)
{
    int class_id = FindZombieIndex(view_as<int>(GetNativeCell(1)));
    int temp_class[g_eZombieClass];
    g_aZombieClass.GetArray(class_id, temp_class[0]);
    int bytes = 0;
    SetNativeString(2, temp_class[dataName], GetNativeCell(3), true, bytes);
    return bytes;
}

public int Native_ZombieClass_NameSet(Handle plugin, int numParams)
{
    int class_id = FindZombieIndex(view_as<int>(GetNativeCell(1)));
    int temp_class[g_eZombieClass];
    g_aZombieClass.GetArray(class_id, temp_class[0]);
    int bytes = 0;
    GetNativeString(2, temp_class[dataName], GetNativeCell(3), bytes);
    g_aZombieClass.SetArray(class_id, temp_class[0]);
    return bytes;
}

public int Native_ZombieClass_DescGet(Handle plugin, int numParams)
{
    int class_id = FindZombieIndex(view_as<int>(GetNativeCell(1)));
    int temp_class[g_eZombieClass];
    g_aZombieClass.GetArray(class_id, temp_class[0]);
    int bytes = 0;
    SetNativeString(2, temp_class[dataDescription], GetNativeCell(3), true, bytes);
    return bytes;
}

public int Native_ZombieClass_DescSet(Handle plugin, int numParams)
{
    int class_id = FindZombieIndex(view_as<int>(GetNativeCell(1)));
    int temp_class[g_eZombieClass];
    g_aZombieClass.GetArray(class_id, temp_class[0]);
    int bytes = 0;
    GetNativeString(2, temp_class[dataDescription], GetNativeCell(3), bytes);
    g_aZombieClass.SetArray(class_id, temp_class[0]);
    return bytes;
}

public int Native_ZombieClass_ModelGet(Handle plugin, int numParams)
{
    int class_id = FindZombieIndex(view_as<int>(GetNativeCell(1)));
    int temp_class[g_eZombieClass];
    g_aZombieClass.GetArray(class_id, temp_class[0]);
    int bytes = 0;
    SetNativeString(2, temp_class[dataModel], GetNativeCell(3), true, bytes);
    return bytes;
}

public int Native_ZombieClass_ModelSet(Handle plugin, int numParams)
{
    int class_id = FindZombieIndex(view_as<int>(GetNativeCell(1)));
    int temp_class[g_eZombieClass];
    g_aZombieClass.GetArray(class_id, temp_class[0]);
    int bytes = 0;
    GetNativeString(2, temp_class[dataModel], GetNativeCell(3), bytes);
    g_aZombieClass.SetArray(class_id, temp_class[0]);
    return bytes;
}

public int Native_ZombieClass_ArmsGet(Handle plugin, int numParams)
{
    int class_id = FindZombieIndex(view_as<int>(GetNativeCell(1)));
    int temp_class[g_eZombieClass];
    g_aZombieClass.GetArray(class_id, temp_class[0]);
    int bytes = 0;
    SetNativeString(2, temp_class[dataArms], GetNativeCell(3), true, bytes);
    return bytes;
}

public int Native_ZombieClass_ArmsSet(Handle plugin, int numParams)
{
    int class_id = FindZombieIndex(view_as<int>(GetNativeCell(1)));
    int temp_class[g_eZombieClass];
    g_aZombieClass.GetArray(class_id, temp_class[0]);
    int bytes = 0;
    GetNativeString(2, temp_class[dataArms], GetNativeCell(3), bytes);
    g_aZombieClass.SetArray(class_id, temp_class[0]);
    return bytes;
}

public int Native_ZombieClass_UniqueGet(Handle plugin, int numParams)
{
    int class_id = FindZombieIndex(view_as<int>(GetNativeCell(1)));
    int temp_class[g_eZombieClass];
    g_aZombieClass.GetArray(class_id, temp_class[0]);
    int bytes = 0;
    SetNativeString(2, temp_class[dataUniqueName], GetNativeCell(3), true, bytes);
    return bytes;
}

//    Natives for MethodMap ZombieAbility
public int Native_ZombieAbility_Constructor(Handle plugin, int numParams)
{
    int zombie_id = view_as<int>(GetNativeCell(1));
    // Check if valid zombie class exists
    int zombie_index = view_as<int>(FindZombieClassByID(zombie_id));
    if (zombie_index == -1)
        return -1;
    char temp_unique[MAX_CLASS_UNIQUE_NAME_SIZE];
    GetNativeString(2, temp_unique, sizeof(temp_unique));
    int temp_checker[g_eZombieAbility];
    for (int i = 0; i < g_aZombieAbility.Length; i++)
    {
        g_aZombieAbility.GetArray(i, temp_checker[0]);
        if (StrEqual(temp_checker[abilityUniqueName], temp_unique, false))
        {
            return -1;
        }
    }
    int temp_ability[g_eZombieAbility];
    Format(temp_ability[abilityName], MAX_ABILITY_NAME_SIZE, "%s", DEFAULT_ABILITY_NAME);
    Format(temp_ability[abilityDescription], MAX_ABILITY_DESC_SIZE, "%s", DEFAULT_ABILITY_DESC);
    Format(temp_ability[abilityUniqueName], MAX_ABILITY_UNIQUE_NAME_SIZE, "%s", temp_unique);

    temp_ability[abilityButtons] = view_as<int>(DEFAULT_ABILITY_BUTTONS);
    temp_ability[abilityCooldown] = view_as<float>(DEFAULT_ABILITY_COOLDOWN);
    temp_ability[abilityDuration] = view_as<float>(DEFAULT_ABILITY_DURATION);
    temp_ability[abilityExcluded] = view_as<bool>(DEFAULT_ABILITY_EXCLUDED);
    temp_ability[abilityZombieClass] = zombie_id;
    temp_ability[abilityID] = g_iNumAbilities;
    g_aZombieClass.PushArray(temp_ability[0]);
    // TODO on zombie ability register
    
    LogMessage("Zombie Ability Register %i [Unique: %s]", temp_ability[abilityID], temp_unique);
    g_iNumAbilities++;
    return temp_ability[abilityID];
}

public int Native_ZombieAbility_IDGet(Handle plugin, int numParams)
{
    int temp_ability = view_as<int>(GetNativeCell(1));
    return view_as<int>(temp_ability);
}

public int Native_ZombieAbility_ButtonsGet(Handle plugin, int numParams)
{
    int ability_id = FindZombieAbilityIndex(view_as<int>(GetNativeCell(1)));
    return view_as<int>(g_aZombieAbility.Get(ability_id, abilityButtons));
}

public int Native_ZombieAbility_ButtonsSet(Handle plugin, int numParams)
{
    int ability_id = FindZombieAbilityIndex(view_as<int>(GetNativeCell(1)));
    int buttons = GetNativeCell(2);
    g_aZombieClass.Set(ability_id, buttons, abilityButtons);
}

public int Native_ZombieAbility_CooldownGet(Handle plugin, int numParams)
{
    int ability_id = FindZombieAbilityIndex(view_as<int>(GetNativeCell(1)));
    return view_as<int>(g_aZombieAbility.Get(ability_id, abilityCooldown));
}

public int Native_ZombieAbility_CooldownSet(Handle plugin, int numParams)
{
    int ability_id = FindZombieAbilityIndex(view_as<int>(GetNativeCell(1)));
    float cooldown = GetNativeCell(2);
    g_aZombieClass.Set(ability_id, cooldown, abilityCooldown);
}

public int Native_ZombieAbility_DurationGet(Handle plugin, int numParams)
{
    int ability_id = FindZombieAbilityIndex(view_as<int>(GetNativeCell(1)));
    return view_as<int>(g_aZombieAbility.Get(ability_id, abilityDuration));
}

public int Native_ZombieAbility_DurationSet(Handle plugin, int numParams)
{
    int ability_id = FindZombieAbilityIndex(view_as<int>(GetNativeCell(1)));
    float duration = GetNativeCell(2);
    g_aZombieClass.Set(ability_id, duration, abilityDuration);
}

public int Native_ZombieAbility_ExcludedGet(Handle plugin, int numParams)
{
    int ability_id = FindZombieAbilityIndex(view_as<int>(GetNativeCell(1)));
    return view_as<int>(g_aZombieAbility.Get(ability_id, abilityExcluded));
}

public int Native_ZombieAbility_ExcludedSet(Handle plugin, int numParams)
{
    int ability_id = FindZombieAbilityIndex(view_as<int>(GetNativeCell(1)));
    bool excluded = GetNativeCell(2);
    g_aZombieClass.Set(ability_id, excluded, abilityExcluded);
}

public int Native_ZombieAbility_NameGet(Handle plugin, int numParams)
{
    int ability_id = FindZombieAbilityIndex(view_as<int>(GetNativeCell(1)));
    int temp_ability[g_eZombieAbility];
    g_aZombieAbility.GetArray(ability_id, temp_ability[0]);
    int bytes = 0;
    SetNativeString(2, temp_ability[dataName], GetNativeCell(3), true, bytes);
    return bytes;
}

public int Native_ZombieAbility_NameSet(Handle plugin, int numParams)
{
    int ability_id = FindZombieAbilityIndex(view_as<int>(GetNativeCell(1)));
    int temp_ability[g_eZombieAbility];
    g_aZombieAbility.GetArray(ability_id, temp_ability[0]);
    int bytes = 0;
    GetNativeString(2, temp_ability[dataName], GetNativeCell(3), bytes);
    g_aZombieAbility.SetArray(ability_id, temp_ability[0]);
    return bytes;
}

public int Native_ZombieAbility_DescGet(Handle plugin, int numParams)
{
    int ability_id = FindZombieAbilityIndex(view_as<int>(GetNativeCell(1)));
    int temp_ability[g_eZombieAbility];
    g_aZombieAbility.GetArray(ability_id, temp_ability[0]);
    int bytes = 0;
    SetNativeString(2, temp_ability[dataDescription], GetNativeCell(3), true, bytes);
    return bytes;
}

public int Native_ZombieAbility_DescSet(Handle plugin, int numParams)
{
    int ability_id = FindZombieAbilityIndex(view_as<int>(GetNativeCell(1)));
    int temp_ability[g_eZombieAbility];
    g_aZombieAbility.GetArray(ability_id, temp_ability[0]);
    int bytes = 0;
    GetNativeString(2, temp_ability[dataDescription], GetNativeCell(3), bytes);
    g_aZombieAbility.SetArray(ability_id, temp_ability[0]);
    return bytes;
}

public int Native_ZombieAbility_UniqueGet(Handle plugin, int numParams)
{
    int ability_id = FindZombieAbilityIndex(view_as<int>(GetNativeCell(1)));
    int temp_ability[g_eZombieAbility];
    g_aZombieAbility.GetArray(ability_id, temp_ability[0]);
    int bytes = 0;
    SetNativeString(2, temp_ability[abilityUniqueName], GetNativeCell(3), true, bytes);
    return bytes;
}