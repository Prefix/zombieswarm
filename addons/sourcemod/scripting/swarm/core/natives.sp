public void InitNatives() {
    CreateNative("ZS_GetRandomZombieClass", nativeGetRandomZombieClass);
    CreateNative("ZS_IsClientZombie", nativeIsClientZombie);
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
    // Functions
    CreateNative("ZMPlayer.OverrideHintText", Native_ZMPlayer_OverrideHintText);
    CreateNative("ZMPlayer.GetAbilityByUnique", Native_ZMPlayer_GetPlayerAbilityUnique); 
    CreateNative("ZMPlayer.GetAbilityByID", Native_ZMPlayer_GetPlayerAbilityID); 
    CreateNative("ZMPlayer.GetPlayerAbilities", Native_ZMPlayer_GetPlayerAbilities);

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

    // Our MethodMap -> PlayerAbility
    CreateNative("PlayerAbility.PlayerAbility", Native_PlayerAbility_Constructor);
    // Class ID
    CreateNative("PlayerAbility.ID.get", Native_PlayerAbility_IDGet);
    // Properties
    CreateNative("PlayerAbility.Excluded.get", Native_PlayerAbility_ExcludedGet);
    CreateNative("PlayerAbility.Excluded.set", Native_PlayerAbility_ExcludedSet);
    CreateNative("PlayerAbility.Duration.get", Native_PlayerAbility_DurationGet);
    CreateNative("PlayerAbility.Duration.set", Native_PlayerAbility_DurationSet);
    CreateNative("PlayerAbility.Cooldown.get", Native_PlayerAbility_CooldownGet);
    CreateNative("PlayerAbility.Cooldown.set", Native_PlayerAbility_CooldownSet);
    CreateNative("PlayerAbility.Buttons.get", Native_PlayerAbility_ButtonsGet);
    CreateNative("PlayerAbility.Buttons.set", Native_PlayerAbility_ButtonsSet);
    CreateNative("PlayerAbility.CurrentDuration.get", Native_PlayerAbility_CurrentDurationGet);
    CreateNative("PlayerAbility.CurrentDuration.set", Native_PlayerAbility_CurrentDurationSet);
    CreateNative("PlayerAbility.CurrentCooldown.get", Native_PlayerAbility_CurrentCooldownGet);
    CreateNative("PlayerAbility.CurrentCooldown.set", Native_PlayerAbility_CurrentCooldownSet);
    CreateNative("PlayerAbility.State.get", Native_PlayerAbility_StateGet);
    CreateNative("PlayerAbility.State.set", Native_PlayerAbility_StateSet);
    // Functions
    CreateNative("PlayerAbility.GetName", Native_PlayerAbility_NameGet);
    CreateNative("PlayerAbility.SetName", Native_PlayerAbility_NameSet);
    CreateNative("PlayerAbility.GetDesc", Native_PlayerAbility_DescGet);
    CreateNative("PlayerAbility.SetDesc", Native_PlayerAbility_DescSet);
    CreateNative("PlayerAbility.GetUnique", Native_PlayerAbility_UniqueGet);
    CreateNative("PlayerAbility.AbilityFinished", Native_PlayerAbility_AbilityFinished);
    CreateNative("PlayerAbility.AbilityStarted", Native_PlayerAbility_AbilityStarted);
    CreateNative("PlayerAbility.AbilityStartedNoDuration", Native_PlayerAbility_AbilityStartedNoDuration);
    CreateNative("PlayerAbility.ForceCooldownEnd", Native_PlayerAbility_ForceCooldownEnd);
}

public int InitForwards() {
    // Forwards
    g_hForwardZombieSelected = CreateGlobalForward("onZCSelected", ET_Ignore, Param_Cell, Param_Cell);
    g_hForwardZombieRightClick = CreateGlobalForward("onZRightClick", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
    g_hForwardZSOnLoaded = CreateGlobalForward("ZS_OnLoaded", ET_Ignore);
    g_hForwardAbilityButtonPressed = CreateGlobalForward("ZS_OnAbilityButtonPressed", ET_Ignore, Param_Cell, Param_Cell);
    g_hForwardAbilityButtonReleased = CreateGlobalForward("ZS_OnAbilityButtonReleased", ET_Ignore, Param_Cell, Param_Cell);
    // TODO: When we start implenting abilities
    g_hForwardOnAbilityStarted = CreateGlobalForward("ZS_OnAbilityStarted", ET_Ignore, Param_Cell, Param_Cell);
    //g_hForwardOnAbilityFinished = CreateGlobalForward("ZS_OnAbilityFinished", ET_Ignore, Param_Cell, Param_Cell);
    g_hForwardOnAbilityCDStarted = CreateGlobalForward("ZS_OnCooldownStarted", ET_Ignore, Param_Cell, Param_Cell);
    g_hForwardOnAbilityCDEnded = CreateGlobalForward("ZS_OnCooldownEnded", ET_Ignore, Param_Cell, Param_Cell);
}

public int nativeIsClientZombie(Handle plugin, int numParams)
{
    int client = GetNativeCell( 1 );
    int iszombie = GetClientTeam(client) == CS_TEAM_T && IsPlayerAlive(client);
    return iszombie;
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
    if ( UTIL_IsValidClient( client ) ) {
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
    return GUM_GetPlayerLevel(player.Client);
}

public int Native_ZMPlayer_XPGet(Handle plugin, int numParams)
{
    ZMPlayer player = GetNativeCell(1);
    return GUM_GetPlayerUnlocks(player.Client);
}

public int Native_ZMPlayer_XPSet(Handle plugin, int numParams)
{
    ZMPlayer player = GetNativeCell(1);
    GUM_SetPlayerUnlocks( player.Client, GetNativeCell(2));
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
    if (!UTIL_IsValidClient(client))
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

public int Native_ZMPlayer_GetPlayerAbilityUnique(Handle plugin, int numParams)
{
    int found = -1;
    ZMPlayer player = GetNativeCell(1);
    int client = player.Client;
    char lookupfor[MAX_ABILITY_UNIQUE_NAME_SIZE];
    int bytes = 0;
    GetNativeString(2, lookupfor, sizeof(lookupfor), bytes);
    for (int i = 0; i < g_aPlayerAbility.Length; i++)
    {
        if (i == g_aPlayerAbility.Length)
            break;
        int temp_ability[g_ePlayerAbility];
        g_aPlayerAbility.GetArray(i, temp_ability[0]);
        if (temp_ability[paClient] != client)
            continue;
        if (StrEqual(temp_ability[paUniqueName], lookupfor, false)) {
            found = i;
            break;
        }
    }
    return found;
}

public int Native_ZMPlayer_GetPlayerAbilityID(Handle plugin, int numParams)
{
    int found = -1;
    ZMPlayer player = GetNativeCell(1);
    int client = player.Client;
    int uniqueid = GetNativeCell(2);
    if (uniqueid < 0 )
        return -1;
    for (int i = 0; i < g_aPlayerAbility.Length; i++)
    {
        if (i == g_aPlayerAbility.Length)
            break;
        int temp_ability[g_ePlayerAbility];
        g_aPlayerAbility.GetArray(i, temp_ability[0]);
        if (temp_ability[paClient] != client)
            continue;
        if (temp_ability[paID] == uniqueid) {
            found = i;
            break;
        }
    }
    return found;
}

public int Native_ZMPlayer_GetPlayerAbilities(Handle plugin, int numParams)
{
    ZMPlayer player = GetNativeCell(1);
    int client = player.Client;
    /*if (!UTIL_IsValidClient(client)) {
        return false;
    }*/
    int abilities[API_MAX_PLAYER_ABILITIES] = -1;
    GetNativeArray(2, abilities, sizeof(abilities));
    int found_ab = 0;
    for (int i = 0; i < g_aPlayerAbility.Length; i++)
    {
        int temp_ability[g_ePlayerAbility];
        g_aPlayerAbility.GetArray(i, temp_ability[0]);
        if (temp_ability[paClient] != client)
            continue;
        abilities[found_ab] = temp_ability[paID];
        found_ab++;
    }
    SetNativeArray(2, abilities, API_MAX_PLAYER_ABILITIES);
    SetNativeCellRef(3, found_ab);

    return found_ab > 0 ? true : false;
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
    g_aZombieAbility.PushArray(temp_ability[0]);
    // TODO on zombie ability register
    
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
    g_aZombieAbility.Set(ability_id, buttons, abilityButtons);
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
    g_aZombieAbility.Set(ability_id, cooldown, abilityCooldown);
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
    g_aZombieAbility.Set(ability_id, duration, abilityDuration);
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
    g_aZombieAbility.Set(ability_id, excluded, abilityExcluded);
}

public int Native_ZombieAbility_NameGet(Handle plugin, int numParams)
{
    int ability_id = FindZombieAbilityIndex(view_as<int>(GetNativeCell(1)));
    int temp_ability[g_eZombieAbility];
    if (ability_id < 0)
    {
        return ThrowNativeError(SP_ERROR_NATIVE, "Bad ability index (%i)", ability_id);
    }
    g_aZombieAbility.GetArray(ability_id, temp_ability[0]);
    int bytes = 0;
    SetNativeString(2, temp_ability[abilityName], GetNativeCell(3), true, bytes);
    return bytes;
}

public int Native_ZombieAbility_NameSet(Handle plugin, int numParams)
{
    int ability_id = FindZombieAbilityIndex(view_as<int>(GetNativeCell(1)));
    int temp_ability[g_eZombieAbility];
    g_aZombieAbility.GetArray(ability_id, temp_ability[0]);
    int bytes = 0;
    GetNativeString(2, temp_ability[abilityName], GetNativeCell(3), bytes);
    g_aZombieAbility.SetArray(ability_id, temp_ability[0]);
    return bytes;
}

public int Native_ZombieAbility_DescGet(Handle plugin, int numParams)
{
    int ability_id = FindZombieAbilityIndex(view_as<int>(GetNativeCell(1)));
    int temp_ability[g_eZombieAbility];
    g_aZombieAbility.GetArray(ability_id, temp_ability[0]);
    int bytes = 0;
    SetNativeString(2, temp_ability[abilityDescription], GetNativeCell(3), true, bytes);
    return bytes;
}

public int Native_ZombieAbility_DescSet(Handle plugin, int numParams)
{
    int ability_id = FindZombieAbilityIndex(view_as<int>(GetNativeCell(1)));
    int temp_ability[g_eZombieAbility];
    g_aZombieAbility.GetArray(ability_id, temp_ability[0]);
    int bytes = 0;
    GetNativeString(2, temp_ability[abilityDescription], GetNativeCell(3), bytes);
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

//    Natives for MethodMap PlayerAbility
public int Native_PlayerAbility_Constructor(Handle plugin, int numParams)
{
    int client = view_as<int>(GetNativeCell(1));
    // Check if valid client exists
    if (!UTIL_IsValidClient(client))
        return -1;
    char temp_unique[MAX_ABILITY_UNIQUE_NAME_SIZE];
    GetNativeString(2, temp_unique, sizeof(temp_unique));
    int temp_checker[g_ePlayerAbility];
    for (int i = 0; i < g_aPlayerAbility.Length; i++)
    {
        g_aPlayerAbility.GetArray(i, temp_checker[0]);
        if (StrEqual(temp_checker[abilityUniqueName], temp_unique, false) &&
            temp_checker[paClient] == client)
        {
            return -1;
        }
    }
    int temp_ability[g_ePlayerAbility];
    Format(temp_ability[paName], MAX_ABILITY_NAME_SIZE, "%s", DEFAULT_ABILITY_NAME);
    Format(temp_ability[paDescription], MAX_ABILITY_DESC_SIZE, "%s", DEFAULT_ABILITY_DESC);
    Format(temp_ability[paUniqueName], MAX_ABILITY_UNIQUE_NAME_SIZE, "%s", temp_unique);

    temp_ability[paButtons] = view_as<int>(DEFAULT_ABILITY_BUTTONS);
    temp_ability[paCooldown] = view_as<float>(DEFAULT_ABILITY_COOLDOWN);
    temp_ability[paDuration] = view_as<float>(DEFAULT_ABILITY_DURATION);
    temp_ability[paCurrentDuration] = 0.0;
    temp_ability[paCurrentCooldown] = 0.0;
    // todo forward ZS_PlayerAbilityStateChange
    temp_ability[paState] = stateIdle; // from <zombieswarm.inc>
    temp_ability[paExcluded] = view_as<bool>(DEFAULT_ABILITY_EXCLUDED);
    temp_ability[paZombieClass] = -1;
    temp_ability[paClient] = client;
    temp_ability[paID] = g_iNumPlayerAbilities;
    temp_ability[paTimerDuration] = null;
    temp_ability[paTimerCooldown] = null;
    g_aPlayerAbility.PushArray(temp_ability[0]);
    // TODO on zombie ability register
    
    g_iNumPlayerAbilities++;
    return temp_ability[paID];
}

public int Native_PlayerAbility_IDGet(Handle plugin, int numParams)
{
    int temp_ability = view_as<int>(GetNativeCell(1));
    return view_as<int>(temp_ability);
}

public int Native_PlayerAbility_ButtonsGet(Handle plugin, int numParams)
{
    int ability_id = FindPlayerAbilityIndex(view_as<int>(GetNativeCell(1)));
    return view_as<int>(g_aPlayerAbility.Get(ability_id, paButtons));
}

public int Native_PlayerAbility_ButtonsSet(Handle plugin, int numParams)
{
    int ability_id = FindPlayerAbilityIndex(view_as<int>(GetNativeCell(1)));
    int buttons = GetNativeCell(2);
    g_aPlayerAbility.Set(ability_id, buttons, paButtons);
}

public int Native_PlayerAbility_CooldownGet(Handle plugin, int numParams)
{
    int ability_id = FindPlayerAbilityIndex(view_as<int>(GetNativeCell(1)));
    return view_as<int>(g_aPlayerAbility.Get(ability_id, paCooldown));
}

public int Native_PlayerAbility_CooldownSet(Handle plugin, int numParams)
{
    int ability_id = FindPlayerAbilityIndex(view_as<int>(GetNativeCell(1)));
    float cooldown = GetNativeCell(2);
    g_aPlayerAbility.Set(ability_id, cooldown, paCooldown);
}

public int Native_PlayerAbility_DurationGet(Handle plugin, int numParams)
{
    int ability_id = FindPlayerAbilityIndex(view_as<int>(GetNativeCell(1)));
    return view_as<int>(g_aPlayerAbility.Get(ability_id, paDuration));
}

public int Native_PlayerAbility_DurationSet(Handle plugin, int numParams)
{
    int ability_id = FindPlayerAbilityIndex(view_as<int>(GetNativeCell(1)));
    float duration = GetNativeCell(2);
    g_aPlayerAbility.Set(ability_id, duration, paDuration);
}

public int Native_PlayerAbility_ExcludedGet(Handle plugin, int numParams)
{
    int ability_id = FindPlayerAbilityIndex(view_as<int>(GetNativeCell(1)));
    return view_as<int>(g_aPlayerAbility.Get(ability_id, paExcluded));
}

public int Native_PlayerAbility_ExcludedSet(Handle plugin, int numParams)
{
    int ability_id = FindPlayerAbilityIndex(view_as<int>(GetNativeCell(1)));
    bool excluded = GetNativeCell(2);
    g_aPlayerAbility.Set(ability_id, excluded, paExcluded);
}

public int Native_PlayerAbility_NameGet(Handle plugin, int numParams)
{
    int ability_id = FindPlayerAbilityIndex(view_as<int>(GetNativeCell(1)));
    int temp_ability[g_ePlayerAbility];
    g_aPlayerAbility.GetArray(ability_id, temp_ability[0]);
    int bytes = 0;
    SetNativeString(2, temp_ability[paName], GetNativeCell(3), true, bytes);
    return bytes;
}

public int Native_PlayerAbility_NameSet(Handle plugin, int numParams)
{
    int ability_id = FindPlayerAbilityIndex(view_as<int>(GetNativeCell(1)));
    int temp_ability[g_ePlayerAbility];
    g_aPlayerAbility.GetArray(ability_id, temp_ability[0]);
    int bytes = 0;
    GetNativeString(2, temp_ability[paName], GetNativeCell(3), bytes);
    g_aPlayerAbility.SetArray(ability_id, temp_ability[0]);
    return bytes;
}

public int Native_PlayerAbility_DescGet(Handle plugin, int numParams)
{
    int ability_id = FindPlayerAbilityIndex(view_as<int>(GetNativeCell(1)));
    int temp_ability[g_ePlayerAbility];
    g_aPlayerAbility.GetArray(ability_id, temp_ability[0]);
    int bytes = 0;
    SetNativeString(2, temp_ability[paDescription], GetNativeCell(3), true, bytes);
    return bytes;
}

public int Native_PlayerAbility_DescSet(Handle plugin, int numParams)
{
    int ability_id = FindPlayerAbilityIndex(view_as<int>(GetNativeCell(1)));
    int temp_ability[g_ePlayerAbility];
    g_aPlayerAbility.GetArray(ability_id, temp_ability[0]);
    int bytes = 0;
    GetNativeString(2, temp_ability[paDescription], GetNativeCell(3), bytes);
    g_aPlayerAbility.SetArray(ability_id, temp_ability[0]);
    return bytes;
}

public int Native_PlayerAbility_UniqueGet(Handle plugin, int numParams)
{
    int ability_id = FindPlayerAbilityIndex(view_as<int>(GetNativeCell(1)));
    int temp_ability[g_ePlayerAbility];
    g_aPlayerAbility.GetArray(ability_id, temp_ability[0]);
    int bytes = 0;
    SetNativeString(2, temp_ability[paUniqueName], GetNativeCell(3), true, bytes);
    return bytes;
}

public int Native_PlayerAbility_CurrentCooldownGet(Handle plugin, int numParams)
{
    int ability_id = FindPlayerAbilityIndex(view_as<int>(GetNativeCell(1)));
    return view_as<int>(g_aPlayerAbility.Get(ability_id, paCurrentCooldown));
}

public int Native_PlayerAbility_CurrentCooldownSet(Handle plugin, int numParams)
{
    int ability_id = FindPlayerAbilityIndex(view_as<int>(GetNativeCell(1)));
    float cooldown = GetNativeCell(2);
    g_aPlayerAbility.Set(ability_id, cooldown, paCurrentCooldown);
}

public int Native_PlayerAbility_CurrentDurationGet(Handle plugin, int numParams)
{
    int ability_id = FindPlayerAbilityIndex(view_as<int>(GetNativeCell(1)));
    return view_as<int>(g_aPlayerAbility.Get(ability_id, paCurrentDuration));
}

public int Native_PlayerAbility_CurrentDurationSet(Handle plugin, int numParams)
{
    int ability_id = FindPlayerAbilityIndex(view_as<int>(GetNativeCell(1)));
    float duration = GetNativeCell(2);
    g_aPlayerAbility.Set(ability_id, duration, paCurrentDuration);
}

public int Native_PlayerAbility_StateGet(Handle plugin, int numParams)
{
    int ability_id = FindPlayerAbilityIndex(view_as<int>(GetNativeCell(1)));
    return view_as<int>(g_aPlayerAbility.Get(ability_id, paState));
}

public int Native_PlayerAbility_StateSet(Handle plugin, int numParams)
{
    int ability_id = FindPlayerAbilityIndex(view_as<int>(GetNativeCell(1)));
    float state = GetNativeCell(2);
    g_aPlayerAbility.Set(ability_id, state, paState);
}

public int Native_PlayerAbility_AbilityFinished(Handle plugin, int numParams)
{
    int ability_id = view_as<int>(GetNativeCell(1));
    int ability_index = FindPlayerAbilityIndex(ability_id);
    int client = view_as<int>(g_aPlayerAbility.Get(ability_index, paClient));
    float cooldown = view_as<float>(g_aPlayerAbility.Get(ability_index, paCooldown));

    g_aPlayerAbility.Set(ability_index, stateCooldown, paState);
    g_aPlayerAbility.Set(ability_index, cooldown, paCurrentCooldown);

    DataPack pack;
    CreateDataTimer(0.1, Timer_SetOnIdle, pack, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
    pack.WriteCell(client);
    pack.WriteCell(ability_id);

    Call_StartForward(g_hForwardOnAbilityCDStarted);
    Call_PushCell(client);
    Call_PushCell(ability_id);
    Call_Finish();

}

public int Native_PlayerAbility_AbilityStarted(Handle plugin, int numParams)
{
    int ability_id = view_as<int>(GetNativeCell(1));
    int ability_index = FindPlayerAbilityIndex(ability_id);
    int client = view_as<int>(g_aPlayerAbility.Get(ability_index, paClient));
    float duration = view_as<float>(g_aPlayerAbility.Get(ability_index, paDuration));

    g_aPlayerAbility.Set(ability_index, stateRunning, paState);
    if (duration != ABILITY_NO_DURATION) {
        g_aPlayerAbility.Set(ability_index, duration, paCurrentDuration);
        DataPack pack;
        CreateDataTimer(0.1, Timer_SetOnCooldown, pack, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
        pack.WriteCell(client);
        pack.WriteCell(ability_id);
    }
    Call_StartForward(g_hForwardOnAbilityStarted);
    Call_PushCell(client);
    Call_PushCell(ability_id);
    Call_Finish();
}

public int Native_PlayerAbility_AbilityStartedNoDuration(Handle plugin, int numParams)
{
    int ability_id = view_as<int>(GetNativeCell(1));
    int ability_index = FindPlayerAbilityIndex(ability_id);
    int client = view_as<int>(g_aPlayerAbility.Get(ability_index, paClient));
    g_aPlayerAbility.Set(ability_index, stateRunning, paState);
    g_aPlayerAbility.Set(ability_index, ABILITY_NO_DURATION, paCurrentDuration);

    Call_StartForward(g_hForwardOnAbilityStarted);
    Call_PushCell(client);
    Call_PushCell(ability_id);
    Call_Finish();
    

    float cooldown = view_as<float>(g_aPlayerAbility.Get(ability_index, paCooldown));
    g_aPlayerAbility.Set(ability_index, cooldown, paCurrentCooldown);
    g_aPlayerAbility.Set(ability_index, stateCooldown, paState);

    DataPack pack;
    
    CreateDataTimer(0.1, Timer_SetOnIdle, pack, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
    pack.WriteCell(client);
    pack.WriteCell(ability_id);

    Call_StartForward(g_hForwardOnAbilityCDStarted);
    Call_PushCell(client);
    Call_PushCell(ability_id);
    Call_Finish();
}

public Action Timer_SetOnIdle(Handle timer, DataPack pack)
{
    if (g_bRoundEnded) {
        return Plugin_Stop;
    }
    pack.Reset();
    int client = pack.ReadCell();
    int ability_id = pack.ReadCell();
    int ability_index = FindPlayerAbilityIndex(ability_id);
    if (!UTIL_IsValidAlive(client)) {
        return Plugin_Stop;
    }
    if (ability_index < 0) {
        return Plugin_Stop;
    }
    abilityState state = g_aPlayerAbility.Get(ability_index, paState);
    if (state != stateCooldown) {
        return Plugin_Stop;
    }
    float cooldown = view_as<float>(g_aPlayerAbility.Get(ability_index, paCurrentCooldown));
    if (cooldown <= 0.1) {
        g_aPlayerAbility.Set(ability_index, stateIdle, paState);
        g_aPlayerAbility.Set(ability_index, 0.0, paCurrentCooldown);
        Call_StartForward(g_hForwardOnAbilityCDEnded);
        Call_PushCell(client);
        Call_PushCell(ability_id);
        Call_Finish();
        return Plugin_Stop;
    }
    g_aPlayerAbility.Set(ability_index, cooldown-0.1, paCurrentCooldown);
    return Plugin_Continue;
    // TODO: set timer to null, delete timers on disconnect, deaths.
}
public Action Timer_SetOnCooldown(Handle timer, DataPack pack)
{
    if (g_bRoundEnded) {
        return Plugin_Stop;
    }
    pack.Reset();
    int client = pack.ReadCell();
    int ability_id = pack.ReadCell();
    int ability_index = FindPlayerAbilityIndex(ability_id);
    if (!UTIL_IsValidAlive(client)) {
        return Plugin_Stop;
    }
    if (ability_index < 0) {
        return Plugin_Stop;
    }
    abilityState state = g_aPlayerAbility.Get(ability_index, paState);
    if (state != stateRunning) {
        return Plugin_Stop;
    }
    float duration = view_as<float>(g_aPlayerAbility.Get(ability_index, paCurrentDuration));
    
    if (duration <= 0.1) {
        float cooldown = view_as<float>(g_aPlayerAbility.Get(ability_index, paCooldown));
        g_aPlayerAbility.Set(ability_index, cooldown, paCurrentCooldown);
        g_aPlayerAbility.Set(ability_index, 0.0, paCurrentDuration);
        g_aPlayerAbility.Set(ability_index, stateCooldown, paState);

        DataPack otherpack;
        CreateDataTimer(0.1, Timer_SetOnIdle, otherpack, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
        otherpack.WriteCell(client);
        otherpack.WriteCell(ability_id);

        Call_StartForward(g_hForwardOnAbilityCDStarted);
        Call_PushCell(client);
        Call_PushCell(ability_id);
        Call_Finish();
        return Plugin_Stop;
    }
    g_aPlayerAbility.Set(ability_index, duration-0.1, paCurrentDuration);
    return Plugin_Continue;
    // TODO: set timer to null, delete timers on disconnect, deaths.
}

public int Native_PlayerAbility_ForceCooldownEnd(Handle plugin, int numParams)
{
    int ability_id = view_as<int>(GetNativeCell(1));
    int ability_index = FindPlayerAbilityIndex(ability_id);
    int client = view_as<int>(g_aPlayerAbility.Get(ability_index, paClient));

    g_aPlayerAbility.Set(ability_index, stateIdle, paState);

    Call_StartForward(g_hForwardOnAbilityCDEnded);
    Call_PushCell(client);
    Call_PushCell(ability_id);
    Call_Finish();
}