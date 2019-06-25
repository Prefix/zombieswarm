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
    RegConsoleCmd("sm_shop", Command_Shop);
    RegConsoleCmd("sm_ul", Command_Shop);
    RegConsoleCmd("sm_unlocks", Command_Shop);
    LoadShopConfig();
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
    g_iRegisteredItems = 0;
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
            PrintToChatAll("Client %N selected %s", client, info);
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
            menu.AddItem(tempunique,temp_item.Name);
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
                PrintToChatAll("Client %N selected item %s", client, info);
                ReplaceString(info, sizeof(info), "menuitem-", "", false);
                ShowGUMItemMenu(client, info);
            } else {
                PrintToChatAll("Client %N selected menu %s", client, info);
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
    menu.AddItem(buyid,"Buy item" );
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

public int MenuItemHandlerCategory(Menu menu, MenuAction action, int client, int param2)
{
    switch(action)
    {
        case MenuAction_Select:
        {
            char info[32];
            menu.GetItem(param2, info, sizeof(info));
            
            if (StrContains( info, "buyitem-", false ) != -1) {
                PrintToChatAll("Client %N selected to buy item %s", client, info);
                ReplaceString(info, sizeof(info), "buyitem-", "", false);
                ShowGUMItemMenu(client, info);
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