#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <gum>
#include <gum_shop>
#include <prestige>
#include <zombieswarm>
#include <colorvariables>
#include <swarm/utils>
// Includes
#include "swarm/gumshop/globals.sp"
#include "swarm/gumshop/natives.sp"

#define PLUGIN_VERSION "1.0"
#define PLUGIN_NAME "[GUM SHOP] Core"
#define PLUGIN_DESC "Shop for [ Zombie Swarm + Gum + Prestige ]"

public Plugin myinfo =
{
    name = PLUGIN_NAME,
    author = "Zombie Swarm Contributors",
    description = PLUGIN_DESC,
    version = PLUGIN_VERSION,
    url = "https://github.com/Prefix/zombieswarm"
};

public void OnPluginStart()
{   
    g_aItems = new ArrayList(sizeof(ShopItem));
    g_aCategories = new ArrayList(sizeof(ShopCategory));
    g_aPlayerItems = new ArrayList(sizeof(ShopPlayerItem));
    g_aPlayerItemsRebuy = new ArrayList(sizeof(ShopPlayerRebuy));
    RegConsoleCmd("sm_shop", Command_Shop);
    RegConsoleCmd("sm_ul", Command_Shop);
    RegConsoleCmd("sm_unlocks", Command_Shop);
    LoadShopConfig();
    // Database
    databaseInit();
}

public void databaseInit()
{
    Database.Connect(databaseConnectionCallback);
}

public void OnClientPutInServer(int client)
{
    if ( UTIL_IsValidClient(client) && !IsFakeClient(client) )
    {
        loadData(client);
        loadDataFromRebuy(client);
    }
}

public void loadData(int client)
{
    char sQuery[ 256 ]; 
    
    char szKey[64];
    GetClientAuthId( client, AuthId_SteamID64, szKey, sizeof(szKey) );

    Format( sQuery, sizeof( sQuery ), "SELECT * FROM `gumshop_items` WHERE ( `player_id` = '%s' );", szKey );
    
    conDatabase.Query( querySelectDataCallback, sQuery, client);
}

public void querySelectDataCallback(Database db, DBResultSet results, const char[] error, any client)
{ 
    if (error[0] != EOS) {
        LogError( "Server misfunctioning come back later: %s", error );
        KickClientEx(client, "Server misfunctioning come back later!");
        return;
    }
    if ( db != null)
    {
        if (results.HasResults) {
            while ( results.FetchRow() ) 
            {
                char item_name[GUM_MAX_ITEM_UNIQUE];
                int upgrade_points = 0;

                int fieldItemName;
                results.FieldNameToNum("item_name", fieldItemName);
                results.FetchString(fieldItemName, item_name, sizeof(item_name));
                
                int fieldUpPoints;
                results.FieldNameToNum("upgrade_points", fieldUpPoints);
                upgrade_points = results.FetchInt(fieldUpPoints);
                AddItemToPlayer(client, item_name, upgrade_points);
            }
        }
        
    } 
    else
    {
        LogError( "%s", error ); 
        
        return;
    }
}

public void loadDataFromRebuy(int client) 
{

    if (!UTIL_IsValidClient(client))
        return;

    char szKey[64];
    GetClientAuthId( client, AuthId_SteamID64, szKey, sizeof(szKey) );

    for (int i = 0; i < g_aItems.Length; i++) {
        ShopPlayerRebuy tempItemRebuy;
        g_aPlayerItemsRebuy.GetArray(i, tempItemRebuy, sizeof(tempItemRebuy));
        if (StrEqual(tempItemRebuy.SteamID, szKey)) {
            AddItemToPlayer(client, tempItemRebuy.ItemUnique);
        }
    }
}

void AddItemToPlayer(int client, char[] item_name, int upgrade_points = 0) 
{

    if (!UTIL_IsValidClient(client))
        return;
    
    // Check if such item exist
    ShopItem item;
    bool found = false;
    for (int i = 0; i < g_aItems.Length; i++) {
        ShopItem tempItem;
        g_aItems.GetArray(i, tempItem, sizeof(tempItem));
        if (StrEqual(tempItem.Unique, item_name)) {
            item = tempItem;
            found = true;
            break;
        }
    }
    
    if (!found) return;

    if (PlayerHasItem(client, item_name)) return;

    char szKey[64];
    GetClientAuthId( client, AuthId_SteamID64, szKey, sizeof(szKey) );

    bool foundrebuy = false;
    ShopPlayerRebuy currentrebuy;
    for (int i = 0; i < g_aItems.Length; i++) {
        ShopPlayerRebuy tempItemRebuy;
        g_aItems.GetArray(i, tempItemRebuy, sizeof(tempItemRebuy));
        if (StrEqual(tempItemRebuy.ItemUnique, item_name) && StrEqual(tempItemRebuy.SteamID, szKey)) {
            currentrebuy = tempItemRebuy;
            foundrebuy = true;
            break;
        }
    }

    if (foundrebuy && !currentrebuy.CanBuy()) return;

    ShopPlayerItem newItem;
    
    newItem.ID = g_iRegisteredPlayerItems;
    newItem.Client = client;
    newItem.ItemID = item.ID;
    strcopy(newItem.ItemUnique, sizeof(ShopPlayerItem::ItemUnique), item.Unique);
    if (!foundrebuy) {
        ShopPlayerRebuy newItemRebuy;
        strcopy(newItemRebuy.SteamID, sizeof(ShopPlayerRebuy::SteamID), szKey);
        strcopy(newItemRebuy.ItemUnique, sizeof(ShopPlayerRebuy::ItemUnique), item.Unique);
        newItemRebuy.ItemID = item.ID;

        if (item.Rebuy == itemBuyOnceMap) {
            newItem.RebuyID = GUM_NO_REBUY_MAP;
            newItemRebuy.RebuyTimes = GUM_NO_REBUY_MAP;
        } else if ( item.Rebuy == itemBuyOnce) {
            // Save to sql
            SavePlayerShopItem(client, item.Unique);
            newItemRebuy.RebuyTimes = GUM_NO_REBUY;
            newItem.RebuyID = GUM_NO_REBUY;
        } else if ( item.Rebuy == itemBuyOnceRound) {
            // Clear such items after round
            newItem.RebuyID = g_iRegisteredPlayerRebuy;
            newItemRebuy.RebuyTimes = GUM_NO_REBUY_ROUND;
        } else if ( item.Rebuy == itemRebuy) {
            // Clear such items after round
            newItem.RebuyID = g_iRegisteredPlayerRebuy;
            newItemRebuy.RebuyTimes = item.RebuyTimes; // 0 for infinitive buys
        }
        newItem.Upgrades = upgrade_points;
        if (newItem.RebuyID != GUM_NO_REBUY) {
            newItemRebuy.ID = g_iRegisteredPlayerRebuy;
            g_aPlayerItemsRebuy.PushArray(newItemRebuy, sizeof(newItemRebuy));
            g_iRegisteredPlayerRebuy++;
        }
    } else {
        newItem.RebuyID = currentrebuy.ID;
        newItem.Upgrades = upgrade_points;
        currentrebuy.Buy();
    }
    if (item.Upgradeable)
        newItem.Upgrades = 0;
    else 
        newItem.Upgrades = GUM_NO_UPGRADES;

    g_aPlayerItems.PushArray(newItem, sizeof(newItem));

    g_iRegisteredPlayerItems++;
    // TODO forward on added item
}

public void OnClientDisconnect(int client)
{
    if ( IsClientInGame(client) )
    {
        if (!IsFakeClient(client)) {
            RemovePlayerItems(client);
        }
    }
}

public void RemovePlayerItems(int client)
{
    if (!UTIL_IsValidClient(client))
        return;
    for (int i = 0; i < g_aPlayerItems.Length; i++)
    {
        if (i == g_aPlayerItems.Length)
            break;
        ShopPlayerItem tempItem;
        g_aPlayerItems.GetArray(i, tempItem, sizeof(tempItem));
        if(tempItem.Client == client) {
            g_aPlayerItems.Erase(i--);
        }
    }
}

void SavePlayerShopItem(int client, char[] unique, int upgrade_points = 0) {
    if ( IsClientInGame(client) )
    {
        if (!IsFakeClient(client)) {
            char sQuery[256];
            char sKey[32], oName[32], pName[60];
            GetClientAuthId( client, AuthId_SteamID64, sKey, sizeof(sKey) );
            
            GetClientName(client, oName, sizeof(oName));
            conDatabase.Escape(oName, pName, sizeof(pName));
        
            Format( sQuery, sizeof( sQuery ), "SELECT * FROM `gumshop_items` WHERE  `player_id` = '%s' AND `item_name` = '%s", sKey, unique);
            
            DataPack dp = new DataPack();
            
            dp.WriteString(sKey);
            dp.WriteString(pName);
            dp.WriteString(unique);
            dp.WriteCell(upgrade_points);
            
            conDatabase.Query( querySelectSavedDataCallback, sQuery, dp);
        }
    }
}

public void querySelectSavedDataCallback(Database db, DBResultSet results, const char[] error, DataPack pack)
{ 
    if ( db != null )
    {
        int resultRows = results.RowCount;
        
        char sKey[32], pName[32], unique[GUM_MAX_ITEM_UNIQUE];
        
        pack.Reset();
        pack.ReadString(sKey, sizeof(sKey));
        pack.ReadString(pName, sizeof(pName));
        pack.ReadString(unique, sizeof(unique));
        int upgrade_points = pack.ReadCell();

        char sQuery[256];
        
        if (resultRows > 0) {
            Format( sQuery, sizeof( sQuery ), "UPDATE `gumshop_items` SET `player_name` = '%s',`upgrade_points` = '%i' WHERE `player_id` = '%s' AND `item_name` = '%s';", pName, upgrade_points, sKey, unique );
        } else {
            Format( sQuery, sizeof( sQuery ), "INSERT INTO `gumshop_items` (`player_id`, `player_name`, `item_name`, `upgrade_points`) VALUES ('%s', '%s', '%d', '%i');", sKey, pName, unique, upgrade_points );
        }
        conDatabase.Query( querySetDataCallback, sQuery);
    } 
    else
    {
        LogError( "%s", error ); 
        
        return;
    }
}

public void querySetDataCallback(Database db, DBResultSet results, const char[] error, any data)
{ 
    if ( db == null )
    {
        LogError( "%s", error ); 
        
        return;
    } 
} 

public void databaseConnectionCallback(Database db, const char[] error, any data)
{
    if ( db == null )
    {
        PrintToServer("Failed to connect: %s", error);
        LogError( "%s", error ); 
        
        return;
    }
    
    conDatabase = db;

    conDatabase.SetCharset("utf8mb4");
    
    char sQuery_Upgrades[512], driverName[16];
    conDatabase.Driver.GetIdentifier(driverName, sizeof(driverName));

    if ( StrEqual(driverName, "mysql") )
    {
        Format( sQuery_Upgrades, sizeof( sQuery_Upgrades ), "CREATE TABLE IF NOT EXISTS `gumshop_items` ( `id` int NOT NULL AUTO_INCREMENT, \
        `player_id` varchar(64) NOT NULL, \
        `player_name` varchar(64) default NULL, \
        `item_name` varchar(64) default NULL, \
        `upgrade_points` int default 0, \
        PRIMARY KEY (`id`), UNIQUE KEY `player_id` (`player_id`) ) ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4;" );
    }
    else
    {
        Format( sQuery_Upgrades, sizeof( sQuery_Upgrades ), "CREATE TABLE IF NOT EXISTS `gumshop_items` ( `id` INTEGER PRIMARY KEY AUTOINCREMENT, \
        `player_id` TEXT NOT NULL UNIQUE, \
        `player_name` TEXT DEFAULT NULL, \
        `item_name` TEXT DEFAULT NULL, \
        `upgrade_points` INTEGER DEFAULT 0 \
         );" );
    }

    conDatabase.Query( QueryCreateTable, sQuery_Upgrades);

}

public void QueryCreateTable(Database db, DBResultSet results, const char[] error, any data)
{ 
    if ( db == null )
    {
        LogError( "%s", error ); 
        
        return;
    } 
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    InitMethodMaps();
    InitForwards();
    // Register mod library
    RegPluginLibrary("gum_shop");

    return APLRes_Success;
}

public void OnAllPluginsLoaded() {
    g_aItems.Clear();
    g_aPlayerItems.Clear();
    g_aPlayerItemsRebuy.Clear();
    g_iRegisteredItems = 0;
    g_iRegisteredPlayerItems = 0;
    g_iRegisteredPlayerRebuy = 0;
    Call_StartForward(g_hForwardOnShopLoaded);
    Call_Finish();
}

public Action Command_Shop(int client, int args)
{
    if (!UTIL_IsValidClient(client))
        return Plugin_Continue;
    
    OpenMainMenu(client);
 
    return Plugin_Handled;
}

public void OpenMainMenu(int client) {
    Menu menu = new Menu(MenuHandler1);
    menu.SetTitle("Upgrades shop");
    for (int i = 0; i < g_aCategories.Length; i++) {
        ShopCategory category;
        g_aCategories.GetArray(i, category, sizeof(category)); 
        menu.AddItem(category.Unique,category.Name);
    }
    menu.ExitButton = true;
    //menu.ExitBackButton = true;
    menu.Display(client, 20);
}

public int MenuHandler1(Menu menu, MenuAction action, int client, int param2)
{
    switch(action)
    {
        case MenuAction_Select:
        {
            char info[32];
            menu.GetItem(param2, info, sizeof(info));
            DrawCategoryMenu(client, info);
        }
 
        case MenuAction_End:
        {
            delete menu;
        }
    }
 
    return 0;
}

void DrawCategoryMenu(int client, char[] info) {
    if (!UTIL_IsValidClient(client))
        return;

    ShopCategory category;
    bool found = false;
    for (int i = 0; i < g_aCategories.Length; i++) {
        ShopCategory temp_category;
        g_aCategories.GetArray(i, temp_category, sizeof(temp_category));
        if (StrEqual(temp_category.Unique, info)) {
            category = temp_category;
            found = true;
            break;
        } else {
            for (int y = 0; y < temp_category.SubCategories.Length; y++) {
                ShopCategory temp_sub_category;
                temp_category.SubCategories.GetArray(y, temp_sub_category, sizeof(temp_sub_category));
                if (StrEqual(temp_sub_category.Unique, info)) {
                    category = temp_sub_category;
                    found = true;
                    break;
                }
            }
        }
    }
    if (!found) {
        return;
    }

    Menu menu = new Menu(MenuHandlerCategory);
    menu.SetTitle(category.Name);
    int menuitems = 0;
    for (int i = 0; i < category.SubCategories.Length; i++) {
        ShopCategory print_category;
        category.SubCategories.GetArray(i, print_category, sizeof(print_category)); 
        menu.AddItem(print_category.Unique,print_category.Name);
        menuitems++;
    }
    for (int i = 0; i < g_aItems.Length; i++) {
        ShopItem temp_item;
        g_aItems.GetArray(i, temp_item, sizeof(temp_item)); 
        if (StrEqual(temp_item.UniqueCategory, info)) {
            char tempunique[64];
            Format(tempunique, sizeof(tempunique), "menuitem-%s", temp_item.Unique);
            if (PlayerHasItem(client, temp_item.Unique)) {
                char shopitemname[64];
                Format(shopitemname, sizeof(shopitemname), "[+] %s", temp_item.Name);
                menu.AddItem(tempunique,shopitemname);
            } else {
                menu.AddItem(tempunique,temp_item.Name);
            }
            
            menuitems++;
        }
    }
    if (menuitems == 0) {
        menu.AddItem("disabled","No categories/items in this category.",ITEMDRAW_DISABLED );
    }
    menu.ExitButton = true;
    menu.ExitBackButton = true;
    menu.Display(client, 30);
}

public int MenuHandlerCategory(Menu menu, MenuAction action, int client, int param2)
{
    switch(action)
    {
        case MenuAction_Select:
        {
            char info[32];
            menu.GetItem(param2, info, sizeof(info));
            
            if (StrContains( info, "menuitem-", false ) != -1) {
                ReplaceString(info, sizeof(info), "menuitem-", "", false);
                ShowGUMItemMenu(client, info);
            } else {
                DrawCategoryMenu(client, info);
            }
        }
        case MenuAction_Cancel:
        {
            if (param2 == MenuCancel_ExitBack) {
                OpenMainMenu(client);
            }
        }
        case MenuAction_End:
        {
            delete menu;
        }
    }
 
    return 0;
}

void ShowGUMItemMenu(int client, char[] info) {
    if (!UTIL_IsValidClient(client))
        return;

    ShopItem item;
    bool found = false;
    for (int i = 0; i < g_aItems.Length; i++) {
        ShopItem tempItem;
        g_aItems.GetArray(i, tempItem, sizeof(tempItem));
        if (StrEqual(tempItem.Unique, info)) {
            item = tempItem;
            found = true;
            break;
        }
    }
    if (!found) {
        return;
    }

    Menu menu = new Menu(MenuItemHandlerCategory);
    menu.SetTitle(item.Name);
    char buyid[32];
    char showdescid[32];
    Format(buyid, sizeof(buyid), "buyitem-%s", info);
    Format(showdescid, sizeof(showdescid), "buydesc-%s", info);

    // check for rebuy
    if (PlayerHasItem(client, info)) menu.AddItem(buyid, "You have it bought already", ITEMDRAW_DISABLED );
    else if (!CanBuyItem(client, info)) menu.AddItem(buyid, "You cannot buy this item", ITEMDRAW_DISABLED );
    else menu.AddItem(buyid,"Buy item" );


    menu.AddItem(showdescid,"Show item description" );
    
    if (item.LevelRequired > 0 || item.RebornRequired > 0 || item.EvolutionRequired > 0 || item.NirvanaRequired > 0) {
        menu.AddItem("disabled3","Requirements: ",ITEMDRAW_DISABLED );
        char requirements[32];
        if (item.NirvanaRequired > 0)
            Format(requirements, sizeof(requirements), "%i Nirvanas ", item.NirvanaRequired);
        if (item.EvolutionRequired > 0)
            Format(requirements, sizeof(requirements), "%i Evolutions ", item.EvolutionRequired);
        if (item.RebornRequired > 0)
            Format(requirements, sizeof(requirements), "%i Reborns ", item.RebornRequired);
        if (item.LevelRequired > 0)
            Format(requirements, sizeof(requirements), "%i Levels ", item.LevelRequired);
        menu.AddItem("disabled4", requirements ,ITEMDRAW_DISABLED );
    } else {
        menu.AddItem("disabled4","Requirements: Everyone can buy",ITEMDRAW_DISABLED );
    }
    menu.AddItem("disabled6","Cost",ITEMDRAW_DISABLED );
    if (item.XPCost > 0 || item.RBPointsCost > 0 || item.EvoPointsCost > 0 || item.NirvanaPointsCost > 0) {
        char cost[64];
        if (item.NirvanaPointsCost > 0)
            Format(cost, sizeof(cost), "%i Nirvana Points ", item.NirvanaPointsCost);
        if (item.EvoPointsCost > 0)
            Format(cost, sizeof(cost), "%i Evolution Points ", item.EvoPointsCost);
        if (item.RBPointsCost > 0)
            Format(cost, sizeof(cost), "%i Reborn Points", item.RBPointsCost);
        if (item.XPCost > 0)
            Format(cost, sizeof(cost), "%i XP ", item.XPCost);
        menu.AddItem("disabled7", cost ,ITEMDRAW_DISABLED );
    } else {
        menu.AddItem("disabled7","For free",ITEMDRAW_DISABLED );
    }

    menu.ExitButton = true;
    menu.ExitBackButton = true;
    menu.Display(client, 30);
}

bool CanBuyItem(int client, char[] info) {

    ShopItem item;
    bool found = false;
    for (int i = 0; i < g_aItems.Length; i++) {
        ShopItem tempItem;
        g_aItems.GetArray(i, tempItem, sizeof(tempItem));
        if (StrEqual(tempItem.Unique, info)) {
            item = tempItem;
            found = true;
            break;
        }
    }
    if (!found) return false;
    if (PlayerHasItem(client, info)) return false;

    PrestigePlayer pplayer = PrestigePlayer(client);
    if (!pplayer.DoesMeetRequirements(item.LevelRequired, item.RebornRequired, item.EvolutionRequired, item.NirvanaRequired))
        return false;

    if (item.XPCost > 0) {
        if (item.XPCost > GUM_GetPlayerUnlocks(client))
            return false;
    }

    if (item.RBPointsCost > 0) {
        if (item.RBPointsCost > pplayer.RebornPoints)
            return false;
    }

    if (item.EvoPointsCost > 0) {
        if (item.EvoPointsCost > pplayer.EvolutionPoints)
            return false;
    }

    if (item.NirvanaPointsCost > 0) {
        if (item.NirvanaPointsCost > pplayer.NirvanaPoints)
            return false;
    }
    if (item.AdminFlagOnly) {
        if (!CheckAdminFlagsByString(client, item.AdminFlags))
            return false;
    }

    Action result = Plugin_Continue;
    Call_StartForward(g_hForwardOnPreBuyItem);
    Call_PushCell(client);
    Call_PushCell(item.ID);
    Call_Finish(result);

    if (result == Plugin_Stop || result == Plugin_Handled)
    {
        return false;
    }
    // Add rebuy thing
    return true;
}

bool BuyItem(int client, char[] info) {

    ShopItem item;
    bool found = false;
    for (int i = 0; i < g_aItems.Length; i++) {
        ShopItem tempItem;
        g_aItems.GetArray(i, tempItem, sizeof(tempItem));
        if (StrEqual(tempItem.Unique, info)) {
            item = tempItem;
            found = true;
            break;
        }
    }

    if (!found) return false;
    // check if rebuy
    if (PlayerHasItem(client, info)) return false;

    PrestigePlayer pplayer = PrestigePlayer(client);

    if (!pplayer.DoesMeetRequirements(item.LevelRequired, item.RebornRequired, item.EvolutionRequired, item.NirvanaRequired))
        return false;

    // First check if have enought stuff to buy, than take it away.
    if (item.XPCost > 0) {
        if (item.XPCost > GUM_GetPlayerUnlocks(client))
            return false;
    }

    if (item.RBPointsCost > 0) {
        if (item.RBPointsCost > pplayer.RebornPoints)
            return false;
    }

    if (item.EvoPointsCost > 0) {
        if (item.EvoPointsCost > pplayer.EvolutionPoints)
            return false;
    }

    if (item.NirvanaPointsCost > 0) {
        if (item.NirvanaPointsCost > pplayer.NirvanaPoints)
            return false;
    }
    // it's shopping time
    if (item.XPCost > 0) {
        int xp = GUM_GetPlayerUnlocks(client);
        if (item.XPCost <= xp)
            GUM_SetPlayerUnlocks(client, xp-item.XPCost);
    }

    if (item.RBPointsCost > 0) {
        if (item.RBPointsCost <= pplayer.RebornPoints)
            pplayer.RebornPoints -= item.RBPointsCost;
    }

    if (item.EvoPointsCost > 0) {
        if (item.EvoPointsCost <= pplayer.EvolutionPoints)
            pplayer.EvolutionPoints -= item.EvoPointsCost;
    }

    if (item.NirvanaPointsCost > 0) {
        if (item.NirvanaPointsCost <= pplayer.NirvanaPoints)
            pplayer.NirvanaPoints -= item.NirvanaPointsCost;
    }

    char szKey[64];
    GetClientAuthId( client, AuthId_SteamID64, szKey, sizeof(szKey) );
    
    bool foundrebuy = false;
    ShopPlayerRebuy currentrebuy;
    for (int i = 0; i < g_aItems.Length; i++) {
        ShopPlayerRebuy tempItemRebuy;
        g_aItems.GetArray(i, tempItemRebuy, sizeof(tempItemRebuy));
        if (StrEqual(tempItemRebuy.ItemUnique, info) && StrEqual(tempItemRebuy.SteamID, szKey)) {
            currentrebuy = tempItemRebuy;
            foundrebuy = true;
            break;
        }
    }
    if (foundrebuy) 
    {
        if (!currentrebuy.CanBuy())
            return false;

        if (currentrebuy.Buy()) {
            return true;
        } else {
            return false;
        }
    }
    else 
    {
        AddItemToPlayer(client, info);
    }

    return true;
}

/**
 * Checks to see if a client has all of the specified admin flags
 *
 * @param client        Player's index.
 * @param flagString    String of flags to check for.
 * @return                True on admin having all flags, false otherwise.
 * Original taken from https://forums.alliedmods.net/showpost.php?p=886345&postcount=4
 */
stock bool CheckAdminFlagsByString(int client, const char[] flagString)
{
    AdminId admin = view_as<AdminId>(GetUserAdmin(client));
    if (admin != INVALID_ADMIN_ID){
        if(GetAdminFlag(admin, Admin_Root)) {
            return true;
        }
        int count, found, flags = ReadFlagString(flagString);
        for (int i = 0; i <= 20; i++){
            if (flags & (1<<i))
            {
                count++;

                if(GetAdminFlag(admin, view_as<AdminFlag>(i))){
                    found++;
                }
            }
        }

        if (count == found){
            return true;
        }
    }

    return false;
} 

bool PlayerHasItem(int client, char[] info) {
    ShopPlayerItem item;
    bool found = false;
    for (int i = 0; i < g_aPlayerItems.Length; i++) {
        ShopPlayerItem tempItem;
        g_aPlayerItems.GetArray(i, tempItem, sizeof(tempItem));
        if (StrEqual(tempItem.ItemUnique, info) && client == tempItem.Client) {
            item = tempItem;
            found = true;
            break;
        }
    }
    return found;
}

public int MenuItemHandlerCategory(Menu menu, MenuAction action, int client, int param2)
{
    switch(action)
    {
        case MenuAction_Select:
        {
            char info[32];
            menu.GetItem(param2, info, sizeof(info));
            
            if (StrContains( info, "buyitem-", false ) != -1) {
                ReplaceString(info, sizeof(info), "buyitem-", "", false);

                ShopItem item;
                bool found = false;
                for (int i = 0; i < g_aItems.Length; i++) {
                    ShopItem tempItem;
                    g_aItems.GetArray(i, tempItem, sizeof(tempItem));
                    if (StrEqual(tempItem.Unique, info)) {
                        item = tempItem;
                        found = true;
                        break;
                    }
                }

                if (!found) return 0;

                // check if can buy
                bool canbuy = CanBuyItem(client, info);
                if (!canbuy) {
                    CPrintToChat(client, "You cannot buy [%s]", item.Name);
                    return 0;
                }

                Action res = Plugin_Continue;
                Call_StartForward(g_hForwardOnBuyItem);
                Call_PushCell(client);
                Call_PushCell(item.ID);
                Call_Finish(res);
                // Use there Plugin_Stop to end cycle when we find our item from plugins side
                if (res == Plugin_Stop || res == Plugin_Handled)
                {
                    BuyItem(client, info);
                    CPrintToChat(client, "Item bought [%s]", item.Name);
                } else {
                    CPrintToChat(client, "Failed to buy item [%s] report to server owner.", item.Name);
                    LogMessage("%N Failed to buy item %s", client, item.Name);
                }
                
            } else if (StrContains( info, "buydesc-", false ) != -1) {
                ReplaceString(info, sizeof(info), "buydesc-", "", false);
                ShopItem item;
                bool found = false;
                for (int i = 0; i < g_aItems.Length; i++) {
                    ShopItem tempItem;
                    g_aItems.GetArray(i, tempItem, sizeof(tempItem));
                    if (StrEqual(tempItem.Unique, info)) {
                        item = tempItem;
                        found = true;
                        break;
                    }
                }
                if (!found) {
                    return 0;
                }

                CPrintToChat(client, "Description of [%s] : %s", item.Name, item.Description);
                ShowGUMItemMenu(client, info);
            }
        }
        case MenuAction_Cancel:
        {
            if (param2 == MenuCancel_ExitBack) {
                OpenMainMenu(client);
            }
        }
        case MenuAction_End:
        {
            delete menu;
        }
    }
 
    return 0;
}

stock void LoadShopConfig() {
    char ResetPath[PLATFORM_MAX_PATH];
    KeyValues ResetKV = new KeyValues("Shop");
    BuildPath(Path_SM, ResetPath, sizeof(ResetPath), "configs/prestige/gum_shop.cfg");
    
    if (!ResetKV.ImportFromFile(ResetPath)) {
        LogError("Couldn't import: \"%s\"", ResetPath);
        return;
    }

    if (!ResetKV.GotoFirstSubKey()) {
        LogError("No configs in: \"%s\"", ResetPath);
        return;
    }
    do
    {
        char sectioname[64];
        ResetKV.GetSectionName(sectioname, sizeof(sectioname));
        
        ShopCategory category;
        category.SubCategories = new ArrayList(sizeof(ShopCategory));
        strcopy(category.Unique, sizeof(ShopCategory::Unique), sectioname);
        strcopy(category.Name, sizeof(ShopCategory::Name), sectioname);
        strcopy(category.MotherCategory, sizeof(ShopCategory::MotherCategory), GUM_ROOT_CATEGORY);

        do
        {
            ResetKV.GotoFirstSubKey(false);
            if (ResetKV.GetDataType(NULL_STRING) != KvData_None)
            {
                char sectionkey[32];
                char sectionvalue[32];
                ResetKV.GetSectionName(sectionkey, sizeof(sectionkey));
                ResetKV.GetString(NULL_STRING, sectionvalue, sizeof(sectionvalue));
                ShopCategory subcategory;
                subcategory.SubCategories = new ArrayList(sizeof(ShopCategory));
                strcopy(subcategory.Unique, sizeof(ShopCategory::Unique), sectionkey);
                strcopy(subcategory.Name, sizeof(ShopCategory::Name), sectionvalue);
                strcopy(subcategory.MotherCategory, sizeof(ShopCategory::MotherCategory), sectioname);
                category.SubCategories.PushArray(subcategory, sizeof(subcategory)); 
            }
        } while (ResetKV.GotoNextKey(false));
        ResetKV.GoBack();
        g_aCategories.PushArray(category, sizeof(category)); 
    } while (ResetKV.GotoNextKey());

    delete ResetKV;
}