
void InitMethodMaps() {
    // Our MethodMap -> GumItem
    CreateNative("GumItem.GumItem", Native_GumItem_Constructor);
    // Class ID
    CreateNative("GumItem.ID.get", Native_GumItem_IDGet);
    // Properties
    CreateNative("GumItem.XPCost.get", Native_GumItem_XPCostGet);
    CreateNative("GumItem.XPCost.set", Native_GumItem_XPCostSet);
    CreateNative("GumItem.RBPointsCost.get", Native_GumItem_RBPointsCostGet);
    CreateNative("GumItem.RBPointsCost.set", Native_GumItem_RBPointsCostSet);
    CreateNative("GumItem.EvoPointsCost.get", Native_GumItem_EvoPointsCostGet);
    CreateNative("GumItem.EvoPointsCost.set", Native_GumItem_EvoPointsCostSet);
    CreateNative("GumItem.NirvanaPointsCost.get", Native_GumItem_NirvanaPointsCostGet);
    CreateNative("GumItem.NirvanaPointsCost.set", Native_GumItem_NirvanaPointsCostSet);
    CreateNative("GumItem.LevelRequired.get", Native_GumItem_LevelRequiredGet);
    CreateNative("GumItem.LevelRequired.set", Native_GumItem_LevelRequiredSet);
    CreateNative("GumItem.RebornRequired.get", Native_GumItem_RebornRequiredGet);
    CreateNative("GumItem.RebornRequired.set", Native_GumItem_RebornRequiredSet);
    CreateNative("GumItem.EvolutionRequired.get", Native_GumItem_EvolutionRequiredGet);
    CreateNative("GumItem.EvolutionRequired.set", Native_GumItem_EvolutionRequiredSet);
    CreateNative("GumItem.NirvanaRequired.get", Native_GumItem_EvolutionRequiredGet);
    CreateNative("GumItem.NirvanaRequired.set", Native_GumItem_EvolutionRequiredSet);
    CreateNative("GumItem.Rebuy.get", Native_GumItem_RebuyGet);
    CreateNative("GumItem.Rebuy.set", Native_GumItem_RebuySet);
    CreateNative("GumItem.RebuyTimes.get", Native_GumItem_RebuyTimesGet);
    CreateNative("GumItem.RebuyTimes.set", Native_GumItem_RebuyTimesSet);
    CreateNative("GumItem.AdminFlagOnly.get", Native_GumItem_AdminFlagOnlyGet);
    CreateNative("GumItem.AdminFlagOnly.set", Native_GumItem_AdminFlagOnlySet);
    CreateNative("GumItem.Upgradeable.get", Native_GumItem_UpgradeableGet);
    CreateNative("GumItem.Upgradeable.set", Native_GumItem_UpgradeableSet);
    // Functions
    CreateNative("GumItem.GetName", Native_GumItem_NameGet);
    CreateNative("GumItem.SetName", Native_GumItem_NameSet);
    CreateNative("GumItem.GetDesc", Native_GumItem_DescGet);
    CreateNative("GumItem.SetDesc", Native_GumItem_DescSet);
    CreateNative("GumItem.GetAdminFlags", Native_GumItem_GetAdminFlags);
    CreateNative("GumItem.SetAdminFlags", Native_GumItem_SetAdminFlags);
    CreateNative("GumItem.GetAdminFlagsDesc", Native_GumItem_GetAdminFlagsDesc);
    CreateNative("GumItem.SetAdminFlagsDesc", Native_GumItem_SetAdminFlagsDesc);
    CreateNative("GumItem.GetUnique", Native_GumItem_GetUnique);
    CreateNative("GumItem.GetUniqueCategory", Native_GumItem_GetUniqueCategory);
}
void InitForwards() {
    g_hForwardOnShopLoaded = CreateGlobalForward("GUMShop_OnLoaded", ET_Ignore);
    g_hForwardOnPreBuyItem = CreateGlobalForward("GUMShop_OnPreBuyItem", ET_Event, Param_Cell, Param_Cell);
    g_hForwardOnBuyItem = CreateGlobalForward("GUMShop_OnBuyItem", ET_Event, Param_Cell, Param_Cell);
}

// Natives for MethodMap GumItem
public int Native_GumItem_Constructor(Handle plugin, int numParams)
{
    char temp_unique[GUM_MAX_ITEM_UNIQUE];
    char temp_unique_category[GUM_MAX_CATEGORY_UNIQUE];
    char temp_unique_name[GUM_MAX_ITEM_NAME];
    char temp_unique_desc[GUM_MAX_ITEM_DESC];

    GetNativeString(1, temp_unique, sizeof(temp_unique));
    GetNativeString(2, temp_unique_category, sizeof(temp_unique_category));
    GetNativeString(3, temp_unique_name, sizeof(temp_unique_name));
    GetNativeString(4, temp_unique_desc, sizeof(temp_unique_desc));

    for (int i = 0; i < g_aItems.Length; i++)
    {
        ShopItem tempitem;
        g_aItems.GetArray(0, tempitem, sizeof(tempitem)); 
        if (StrEqual(tempitem.Unique, temp_unique, false))
        {
            return -1;
        }
    }

    ShopItem newItem;

    newItem.ID = g_iRegisteredItems;
    strcopy(newItem.Unique, sizeof(ShopItem::Unique), temp_unique);
    strcopy(newItem.UniqueCategory, sizeof(ShopItem::UniqueCategory), temp_unique_category);
    strcopy(newItem.Name, sizeof(ShopItem::Name), temp_unique_name);
    strcopy(newItem.Description, sizeof(ShopItem::Description), temp_unique_desc);
    newItem.XPCost = DEFAULT_XP_COST;
    newItem.RBPointsCost = DEFAULT_RB_P_COST;
    newItem.EvoPointsCost = DEFAULT_EVO_P_COST;
    newItem.NirvanaPointsCost = DEFAULT_NIRVANA_P_COST;
    newItem.LevelRequired = DEFAULT_LEVEL_REQ;
    newItem.RebornRequired = DEFAULT_REBORN_REQ;
    newItem.EvolutionRequired = DEFAULT_EVO_REQ;
    newItem.NirvanaRequired = DEFAULT_NIRVANA_REQ;
    newItem.Rebuy = DEFAULT_REBUY;
    newItem.RebuyTimes = DEFAULT_REBUY_TIMES;
    newItem.AdminFlagOnly = DEFAULT_ADMFLAG_ONLY;
    newItem.Upgradeable = DEFAULT_UPGRADEABLE;
    newItem.Upgrades = new ArrayList(sizeof(ShopItemUpgrade));
    strcopy(newItem.AdminFlags, sizeof(ShopItem::AdminFlags), DEFAULT_ADMFLAGS);
    strcopy(newItem.AdminFlagDesc, sizeof(ShopItem::AdminFlagDesc), DEFAULT_ADMFLAG_DESC);

    g_aItems.PushArray(newItem, sizeof(newItem));

    g_iRegisteredItems++;
    return newItem.ID;
}

public int Native_GumItem_IDGet(Handle plugin, int numParams)
{
    int temp_item = view_as<int>(GetNativeCell(1));
    return view_as<int>(temp_item);
}

public int FindGUMItemIndex(int uniqueid) {
    int found = -1;
    for (int i = 0; i < g_aItems.Length; i++)
    {
        ShopItem tempItem;
        g_aItems.GetArray(i, tempItem, sizeof(tempItem)); 
        if (uniqueid == tempItem.ID)
        {
            found = i;
            break;
        }
    }
    return found;
}

public int Native_GumItem_XPCostGet(Handle plugin, int numParams)
{
    int item_unique = view_as<int>(GetNativeCell(1));
    int item_id = FindGUMItemIndex(item_unique);
    if (item_id == -1)
    {
        return ThrowNativeError(SP_ERROR_NATIVE, "Invalid Unique ID (%i)", item_unique);
    }
    ShopItem tempItem;
    g_aItems.GetArray(item_id, tempItem, sizeof(tempItem)); 
    return view_as<int>(tempItem.XPCost);
}

public int Native_GumItem_XPCostSet(Handle plugin, int numParams)
{
    int item_unique = view_as<int>(GetNativeCell(1));
    int item_id = FindGUMItemIndex(item_unique);
    int value = GetNativeCell(2);
    if (item_id == -1)
    {
        return ThrowNativeError(SP_ERROR_NATIVE, "Invalid Unique ID (%i)", item_unique);
    }
    ShopItem tempItem;
    g_aItems.GetArray(item_id, tempItem, sizeof(tempItem)); 
    tempItem.XPCost = value;
    g_aItems.SetArray(item_id, tempItem, sizeof(tempItem));
    return 1;
}


public int Native_GumItem_RBPointsCostGet(Handle plugin, int numParams)
{
    int item_unique = view_as<int>(GetNativeCell(1));
    int item_id = FindGUMItemIndex(item_unique);
    if (item_id == -1)
    {
        return ThrowNativeError(SP_ERROR_NATIVE, "Invalid Unique ID (%i)", item_unique);
    }
    ShopItem tempItem;
    g_aItems.GetArray(item_id, tempItem, sizeof(tempItem)); 
    return view_as<int>(tempItem.RBPointsCost);
}

public int Native_GumItem_RBPointsCostSet(Handle plugin, int numParams)
{
    int item_unique = view_as<int>(GetNativeCell(1));
    int item_id = FindGUMItemIndex(item_unique);
    int value = GetNativeCell(2);
    if (item_id == -1)
    {
        return ThrowNativeError(SP_ERROR_NATIVE, "Invalid Unique ID (%i)", item_unique);
    }
    ShopItem tempItem;
    g_aItems.GetArray(item_id, tempItem, sizeof(tempItem)); 
    tempItem.RBPointsCost = value;
    g_aItems.SetArray(item_id, tempItem, sizeof(tempItem));
    return 1;
}

public int Native_GumItem_EvoPointsCostGet(Handle plugin, int numParams)
{
    int item_unique = view_as<int>(GetNativeCell(1));
    int item_id = FindGUMItemIndex(item_unique);
    if (item_id == -1)
    {
        return ThrowNativeError(SP_ERROR_NATIVE, "Invalid Unique ID (%i)", item_unique);
    }
    ShopItem tempItem;
    g_aItems.GetArray(item_id, tempItem, sizeof(tempItem)); 
    return view_as<int>(tempItem.EvoPointsCost);
}

public int Native_GumItem_EvoPointsCostSet(Handle plugin, int numParams)
{
    int item_unique = view_as<int>(GetNativeCell(1));
    int item_id = FindGUMItemIndex(item_unique);
    int value = GetNativeCell(2);
    if (item_id == -1)
    {
        return ThrowNativeError(SP_ERROR_NATIVE, "Invalid Unique ID (%i)", item_unique);
    }
    ShopItem tempItem;
    g_aItems.GetArray(item_id, tempItem, sizeof(tempItem)); 
    tempItem.EvoPointsCost = value;
    g_aItems.SetArray(item_id, tempItem, sizeof(tempItem));
    return 1;
}

public int Native_GumItem_NirvanaPointsCostGet(Handle plugin, int numParams)
{
    int item_unique = view_as<int>(GetNativeCell(1));
    int item_id = FindGUMItemIndex(item_unique);
    if (item_id == -1)
    {
        return ThrowNativeError(SP_ERROR_NATIVE, "Invalid Unique ID (%i)", item_unique);
    }
    ShopItem tempItem;
    g_aItems.GetArray(item_id, tempItem, sizeof(tempItem)); 
    return view_as<int>(tempItem.NirvanaPointsCost);
}

public int Native_GumItem_NirvanaPointsCostSet(Handle plugin, int numParams)
{
    int item_unique = view_as<int>(GetNativeCell(1));
    int item_id = FindGUMItemIndex(item_unique);
    int value = GetNativeCell(2);
    if (item_id == -1)
    {
        return ThrowNativeError(SP_ERROR_NATIVE, "Invalid Unique ID (%i)", item_unique);
    }
    ShopItem tempItem;
    g_aItems.GetArray(item_id, tempItem, sizeof(tempItem)); 
    tempItem.NirvanaPointsCost = value;
    g_aItems.SetArray(item_id, tempItem, sizeof(tempItem));
    return 1;
}

public int Native_GumItem_LevelRequiredGet(Handle plugin, int numParams)
{
    int item_unique = view_as<int>(GetNativeCell(1));
    int item_id = FindGUMItemIndex(item_unique);
    if (item_id == -1)
    {
        return ThrowNativeError(SP_ERROR_NATIVE, "Invalid Unique ID (%i)", item_unique);
    }
    ShopItem tempItem;
    g_aItems.GetArray(item_id, tempItem, sizeof(tempItem)); 
    return view_as<int>(tempItem.LevelRequired);
}

public int Native_GumItem_LevelRequiredSet(Handle plugin, int numParams)
{
    int item_unique = view_as<int>(GetNativeCell(1));
    int item_id = FindGUMItemIndex(item_unique);
    int value = GetNativeCell(2);
    if (item_id == -1)
    {
        return ThrowNativeError(SP_ERROR_NATIVE, "Invalid Unique ID (%i)", item_unique);
    }
    ShopItem tempItem;
    g_aItems.GetArray(item_id, tempItem, sizeof(tempItem)); 
    tempItem.LevelRequired = value;
    g_aItems.SetArray(item_id, tempItem, sizeof(tempItem));
    return 1;
}

public int Native_GumItem_RebornRequiredGet(Handle plugin, int numParams)
{
    int item_unique = view_as<int>(GetNativeCell(1));
    int item_id = FindGUMItemIndex(item_unique);
    if (item_id == -1)
    {
        return ThrowNativeError(SP_ERROR_NATIVE, "Invalid Unique ID (%i)", item_unique);
    }
    ShopItem tempItem;
    g_aItems.GetArray(item_id, tempItem, sizeof(tempItem)); 
    return view_as<int>(tempItem.RebornRequired);
}

public int Native_GumItem_RebornRequiredSet(Handle plugin, int numParams)
{
    int item_unique = view_as<int>(GetNativeCell(1));
    int item_id = FindGUMItemIndex(item_unique);
    int value = GetNativeCell(2);
    if (item_id == -1)
    {
        return ThrowNativeError(SP_ERROR_NATIVE, "Invalid Unique ID (%i)", item_unique);
    }
    ShopItem tempItem;
    g_aItems.GetArray(item_id, tempItem, sizeof(tempItem)); 
    tempItem.RebornRequired = value;
    g_aItems.SetArray(item_id, tempItem, sizeof(tempItem));
    return 1;
}

public int Native_GumItem_EvolutionRequiredGet(Handle plugin, int numParams)
{
    int item_unique = view_as<int>(GetNativeCell(1));
    int item_id = FindGUMItemIndex(item_unique);
    if (item_id == -1)
    {
        return ThrowNativeError(SP_ERROR_NATIVE, "Invalid Unique ID (%i)", item_unique);
    }
    ShopItem tempItem;
    g_aItems.GetArray(item_id, tempItem, sizeof(tempItem)); 
    return view_as<int>(tempItem.EvolutionRequired);
}

public int Native_GumItem_EvolutionRequiredSet(Handle plugin, int numParams)
{
    int item_unique = view_as<int>(GetNativeCell(1));
    int item_id = FindGUMItemIndex(item_unique);
    int value = GetNativeCell(2);
    if (item_id == -1)
    {
        return ThrowNativeError(SP_ERROR_NATIVE, "Invalid Unique ID (%i)", item_unique);
    }
    ShopItem tempItem;
    g_aItems.GetArray(item_id, tempItem, sizeof(tempItem)); 
    tempItem.EvolutionRequired = value;
    g_aItems.SetArray(item_id, tempItem, sizeof(tempItem));
    return 1;
}

public int Native_GumItem_RebuyGet(Handle plugin, int numParams)
{
    int item_unique = view_as<int>(GetNativeCell(1));
    int item_id = FindGUMItemIndex(item_unique);
    if (item_id == -1)
    {
        return ThrowNativeError(SP_ERROR_NATIVE, "Invalid Unique ID (%i)", item_unique);
    }
    ShopItem tempItem;
    g_aItems.GetArray(item_id, tempItem, sizeof(tempItem)); 
    return view_as<int>(tempItem.Rebuy);
}

public int Native_GumItem_RebuySet(Handle plugin, int numParams)
{
    int item_unique = view_as<int>(GetNativeCell(1));
    int item_id = FindGUMItemIndex(item_unique);
    g_eItemBuy value = GetNativeCell(2);
    if (item_id == -1)
    {
        return ThrowNativeError(SP_ERROR_NATIVE, "Invalid Unique ID (%i)", item_unique);
    }
    ShopItem tempItem;
    g_aItems.GetArray(item_id, tempItem, sizeof(tempItem)); 
    tempItem.Rebuy = value;
    g_aItems.SetArray(item_id, tempItem, sizeof(tempItem));
    return 1;
}

public int Native_GumItem_RebuyTimesGet(Handle plugin, int numParams)
{
    int item_unique = view_as<int>(GetNativeCell(1));
    int item_id = FindGUMItemIndex(item_unique);
    if (item_id == -1)
    {
        return ThrowNativeError(SP_ERROR_NATIVE, "Invalid Unique ID (%i)", item_unique);
    }
    ShopItem tempItem;
    g_aItems.GetArray(item_id, tempItem, sizeof(tempItem)); 
    return view_as<int>(tempItem.RebuyTimes);
}

public int Native_GumItem_RebuyTimesSet(Handle plugin, int numParams)
{
    int item_unique = view_as<int>(GetNativeCell(1));
    int item_id = FindGUMItemIndex(item_unique);
    int value = GetNativeCell(2);
    if (item_id == -1)
    {
        return ThrowNativeError(SP_ERROR_NATIVE, "Invalid Unique ID (%i)", item_unique);
    }
    ShopItem tempItem;
    g_aItems.GetArray(item_id, tempItem, sizeof(tempItem)); 
    tempItem.RebuyTimes = value;
    g_aItems.SetArray(item_id, tempItem, sizeof(tempItem));
    return 1;
}

public int Native_GumItem_AdminFlagOnlyGet(Handle plugin, int numParams)
{
    int item_unique = view_as<int>(GetNativeCell(1));
    int item_id = FindGUMItemIndex(item_unique);
    if (item_id == -1)
    {
        return ThrowNativeError(SP_ERROR_NATIVE, "Invalid Unique ID (%i)", item_unique);
    }
    ShopItem tempItem;
    g_aItems.GetArray(item_id, tempItem, sizeof(tempItem)); 
    return view_as<int>(tempItem.AdminFlagOnly);
}

public int Native_GumItem_AdminFlagOnlySet(Handle plugin, int numParams)
{
    int item_unique = view_as<int>(GetNativeCell(1));
    int item_id = FindGUMItemIndex(item_unique);
    bool value = GetNativeCell(2);
    if (item_id == -1)
    {
        return ThrowNativeError(SP_ERROR_NATIVE, "Invalid Unique ID (%i)", item_unique);
    }
    ShopItem tempItem;
    g_aItems.GetArray(item_id, tempItem, sizeof(tempItem)); 
    tempItem.AdminFlagOnly = value;
    g_aItems.SetArray(item_id, tempItem, sizeof(tempItem));
    return 1;
}

public int Native_GumItem_UpgradeableGet(Handle plugin, int numParams)
{
    int item_unique = view_as<int>(GetNativeCell(1));
    int item_id = FindGUMItemIndex(item_unique);
    if (item_id == -1)
    {
        return ThrowNativeError(SP_ERROR_NATIVE, "Invalid Unique ID (%i)", item_unique);
    }
    ShopItem tempItem;
    g_aItems.GetArray(item_id, tempItem, sizeof(tempItem)); 
    return view_as<int>(tempItem.Upgradeable);
}

public int Native_GumItem_UpgradeableSet(Handle plugin, int numParams)
{
    int item_unique = view_as<int>(GetNativeCell(1));
    int item_id = FindGUMItemIndex(item_unique);
    bool value = GetNativeCell(2);
    if (item_id == -1)
    {
        return ThrowNativeError(SP_ERROR_NATIVE, "Invalid Unique ID (%i)", item_unique);
    }
    ShopItem tempItem;
    g_aItems.GetArray(item_id, tempItem, sizeof(tempItem)); 
    tempItem.Upgradeable = value;
    g_aItems.SetArray(item_id, tempItem, sizeof(tempItem));
    return 1;
}

public int Native_GumItem_NameGet(Handle plugin, int numParams)
{
    int item_unique = view_as<int>(GetNativeCell(1));
    int item_id = FindGUMItemIndex(item_unique);
    if (item_id == -1)
    {
        return ThrowNativeError(SP_ERROR_NATIVE, "Invalid Unique ID (%i)", item_unique);
    }
    ShopItem tempItem;
    g_aItems.GetArray(item_id, tempItem, sizeof(tempItem)); 
    SetNativeString(2, tempItem.Name, sizeof(ShopItem::Name), true);
    return 1;
}

public int Native_GumItem_NameSet(Handle plugin, int numParams)
{
    int item_unique = view_as<int>(GetNativeCell(1));
    int item_id = FindGUMItemIndex(item_unique);
    if (item_id == -1)
    {
        return ThrowNativeError(SP_ERROR_NATIVE, "Invalid Unique ID (%i)", item_unique);
    }
    ShopItem tempItem;
    g_aItems.GetArray(item_id, tempItem, sizeof(tempItem)); 
    char temp_name[GUM_MAX_ITEM_NAME];
    GetNativeString(2, temp_name, sizeof(temp_name));
    strcopy(tempItem.Name, sizeof(ShopItem::Name), temp_name);
    g_aItems.SetArray(item_id, tempItem, sizeof(tempItem));
    return 1;
}

public int Native_GumItem_DescGet(Handle plugin, int numParams)
{
    int item_unique = view_as<int>(GetNativeCell(1));
    int item_id = FindGUMItemIndex(item_unique);
    if (item_id == -1)
    {
        return ThrowNativeError(SP_ERROR_NATIVE, "Invalid Unique ID (%i)", item_unique);
    }
    ShopItem tempItem;
    g_aItems.GetArray(item_id, tempItem, sizeof(tempItem)); 
    SetNativeString(2, tempItem.Description, sizeof(ShopItem::Description), true);
    return 1;
}

public int Native_GumItem_DescSet(Handle plugin, int numParams)
{
    int item_unique = view_as<int>(GetNativeCell(1));
    int item_id = FindGUMItemIndex(item_unique);
    if (item_id == -1)
    {
        return ThrowNativeError(SP_ERROR_NATIVE, "Invalid Unique ID (%i)", item_unique);
    }
    ShopItem tempItem;
    g_aItems.GetArray(item_id, tempItem, sizeof(tempItem)); 
    char temp_desc[GUM_MAX_ITEM_DESC];
    GetNativeString(2, temp_desc, sizeof(temp_desc));
    strcopy(tempItem.Description, sizeof(ShopItem::Description), temp_desc);
    g_aItems.SetArray(item_id, tempItem, sizeof(tempItem));
    return 1;
}

public int Native_GumItem_GetAdminFlags(Handle plugin, int numParams)
{
    int item_unique = view_as<int>(GetNativeCell(1));
    int item_id = FindGUMItemIndex(item_unique);
    if (item_id == -1)
    {
        return ThrowNativeError(SP_ERROR_NATIVE, "Invalid Unique ID (%i)", item_unique);
    }
    ShopItem tempItem;
    g_aItems.GetArray(item_id, tempItem, sizeof(tempItem)); 
    SetNativeString(2, tempItem.AdminFlags, sizeof(ShopItem::AdminFlags), true);
    return 1;
}

public int Native_GumItem_SetAdminFlags(Handle plugin, int numParams)
{
    int item_unique = view_as<int>(GetNativeCell(1));
    int item_id = FindGUMItemIndex(item_unique);
    if (item_id == -1)
    {
        return ThrowNativeError(SP_ERROR_NATIVE, "Invalid Unique ID (%i)", item_unique);
    }
    ShopItem tempItem;
    g_aItems.GetArray(item_id, tempItem, sizeof(tempItem)); 
    char temp_desc[GUM_MAX_FLAGS];
    GetNativeString(2, temp_desc, sizeof(temp_desc));
    strcopy(tempItem.AdminFlags, sizeof(ShopItem::AdminFlags), temp_desc);
    g_aItems.SetArray(item_id, tempItem, sizeof(tempItem));
    return 1;
}

public int Native_GumItem_GetAdminFlagsDesc(Handle plugin, int numParams)
{
    int item_unique = view_as<int>(GetNativeCell(1));
    int item_id = FindGUMItemIndex(item_unique);
    if (item_id == -1)
    {
        return ThrowNativeError(SP_ERROR_NATIVE, "Invalid Unique ID (%i)", item_unique);
    }
    ShopItem tempItem;
    g_aItems.GetArray(item_id, tempItem, sizeof(tempItem)); 
    SetNativeString(2, tempItem.AdminFlagDesc, sizeof(ShopItem::AdminFlagDesc), true);
    return 1;
}

public int Native_GumItem_SetAdminFlagsDesc(Handle plugin, int numParams)
{
    int item_unique = view_as<int>(GetNativeCell(1));
    int item_id = FindGUMItemIndex(item_unique);
    if (item_id == -1)
    {
        return ThrowNativeError(SP_ERROR_NATIVE, "Invalid Unique ID (%i)", item_unique);
    }
    ShopItem tempItem;
    g_aItems.GetArray(item_id, tempItem, sizeof(tempItem)); 
    char temp_desc[GUM_MAX_FLAGS_DESC];
    GetNativeString(2, temp_desc, sizeof(temp_desc));
    strcopy(tempItem.AdminFlagDesc, sizeof(ShopItem::AdminFlagDesc), temp_desc);
    g_aItems.SetArray(item_id, tempItem, sizeof(tempItem));
    return 1;
}

public int Native_GumItem_GetUnique(Handle plugin, int numParams)
{
    int item_unique = view_as<int>(GetNativeCell(1));
    int item_id = FindGUMItemIndex(item_unique);
    if (item_id == -1)
    {
        return ThrowNativeError(SP_ERROR_NATIVE, "Invalid Unique ID (%i)", item_unique);
    }
    ShopItem tempItem;
    g_aItems.GetArray(item_id, tempItem, sizeof(tempItem)); 
    SetNativeString(2, tempItem.Unique, sizeof(ShopItem::Unique), true);
    return 1;
}

public int Native_GumItem_GetUniqueCategory(Handle plugin, int numParams)
{
    int item_unique = view_as<int>(GetNativeCell(1));
    int item_id = FindGUMItemIndex(item_unique);
    if (item_id == -1)
    {
        return ThrowNativeError(SP_ERROR_NATIVE, "Invalid Unique ID (%i)", item_unique);
    }
    ShopItem tempItem;
    g_aItems.GetArray(item_id, tempItem, sizeof(tempItem)); 
    SetNativeString(2, tempItem.UniqueCategory, sizeof(ShopItem::UniqueCategory), true);
    return 1;
}

