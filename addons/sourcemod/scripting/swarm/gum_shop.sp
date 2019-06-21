#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <gum>
#include <colorvariables>
#include <swarm/utils>
#define PLUGIN_VERSION "1.0"

#define MENU_DISPLAY_TIME 30

#define MAX_UNLOCKS 30
#define MAX_UNLOCKS_NAME_SIZE 64
#define MAX_UNLOCKS_DESC_SIZE 128

public Plugin myinfo =
{
    name = "Gun Unlocks Mod Shop",
    author = "Zombie Swarm Contributors",
    description = "Shop to buy items",
    version = PLUGIN_VERSION,
    url = "https://github.com/Prefix/zombieswarm"
};

int numItems;

bool playerItems[MAXPLAYERS + 1][MAX_UNLOCKS];

int playerItemRebuyTimes[MAXPLAYERS + 1][MAX_UNLOCKS];

Handle uItemId[MAX_UNLOCKS] = null;
int uItemPrice[MAX_UNLOCKS], uItemRebuy[MAX_UNLOCKS], uItemRebuyTimes[MAX_UNLOCKS];
char uItemName[MAX_UNLOCKS][MAX_UNLOCKS_NAME_SIZE], uItemDesc[MAX_UNLOCKS][MAX_UNLOCKS_DESC_SIZE];

Handle cvarItemDropRate, cvarItemDropMaxRate;

public void OnPluginStart()
{
    CreateConVar("gum_shop", PLUGIN_VERSION, "Gun Unlocks Mod Shop", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
    
    cvarItemDropRate = CreateConVar("gum_item_drop_rate", "50", "Item drop rate killing player");
    cvarItemDropMaxRate = CreateConVar("gum_item_drop_maxrate", "1000", "Item drop maximum rate");
    
    HookEvent("player_death", eventPlayerDeath);
    HookEvent("round_end",  eventRoundEnd);

    RegConsoleCmd("say", sayCommand);
}

public void OnClientPutInServer(int client)
{
    if ( UTIL_IsValidClient(client) )
    {
        for(int i = 0; i < MAX_UNLOCKS; i++) 
        {
            playerItems[client][i] = false;
            playerItemRebuyTimes[client][i] = 0;
        }
    }
}

public Action sayCommand(int client, int args)
{
    if ( !UTIL_IsValidClient(client) )
        return Plugin_Continue;
    
    char text[192];
    char sArg1[16];
    GetCmdArgString(text, sizeof(text));

    StripQuotes(text);

    BreakString(text, sArg1, sizeof(sArg1));
    
    if(StrEqual(sArg1, "!shop") || StrEqual(sArg1, "shop") || StrEqual(sArg1, "/shop") ||  StrEqual(sArg1, "!ul") || StrEqual(sArg1, "ul") || StrEqual(sArg1, "unlock") 
    || StrEqual(sArg1, "!unlocks") || StrEqual(sArg1, "!unlock") || StrEqual(sArg1, "unlocks") )
    {
        mainUnlocksMenu(client);
    
        return Plugin_Handled;
    }
    
    return Plugin_Continue;
}

public void eventPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    int victim = GetClientOfUserId(GetEventInt(event, "userid"));
    int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
    
    if (GetConVarInt(cvarItemDropRate) < 1)
        return;
    
    if (victim == attacker)
        return;
    
    if ( !UTIL_IsValidAlive(attacker) )
        return;
        
    if (GetRandomInt(0, GetConVarInt(cvarItemDropMaxRate)) > GetConVarInt(cvarItemDropRate))
        return;
        
    int itemId = GetRandomInt(0, numItems-1);
    
    if (playerItems[attacker][itemId])
        return;
    
    hookItemSet(attacker, itemId, true);
}

public void eventRoundEnd(Event event, const char[] name, bool dontBroadcast)
{
    for (int client = 1; client <= MaxClients; client++) 
    { 
        if (!UTIL_IsValidClient(client) )
            continue;
        for (int itemId = 0; itemId < numItems; itemId++)
        {
            if (uItemRebuy[itemId] == 2) {
                playerItems[client][itemId] = false;
                
                hookItemUnSetCallback(client, itemId);
            }
        }
    } 
}

public void mainUnlocksMenu(int client)
{
    char sMsg[64];
    char sItems[64];
    int getUnlocks = getPlayerUnlocks( client );
    
    Format(sMsg, sizeof( sMsg ), "Shop [Unlocks - %d]", getUnlocks );
    Menu menu = new Menu(unlocksMenuCallback);

    menu.SetTitle(sMsg);
    
    for (int itemId = 0; itemId < numItems; itemId++)
    {
        if( getUnlocks < uItemPrice[itemId] ) 
        {
            if(playerItems[client][itemId]) 
            {
                Format(sItems, sizeof(sItems), "%s (Bought)", uItemName[itemId]);

                menu.AddItem("item", sItems, ITEMDRAW_DISABLED);
            }
            else
            {
                Format(sItems, sizeof(sItems), "%s (%d UL)", uItemName[itemId], uItemPrice[itemId]);

                menu.AddItem("item", sItems, ITEMDRAW_DISABLED);
            }
        }
        else if (playerItems[client][itemId])
        {
            Format(sItems, sizeof(sItems), "%s (Bought)", uItemName[itemId]);

            menu.AddItem("item", sItems, ITEMDRAW_DISABLED);
        }
        else if (uItemRebuy[itemId] > 0 && uItemRebuyTimes[itemId] > 0 && playerItemRebuyTimes[client][itemId] >= uItemRebuyTimes[itemId])
        {
            Format(sItems, sizeof(sItems), "%s (Reached limit)", uItemName[itemId], uItemRebuyTimes[itemId]);

            menu.AddItem("item", sItems, ITEMDRAW_DISABLED);
        }
        else
        {
            Format(sItems, sizeof(sItems), "%s (%d UL) - Buy", uItemName[itemId], uItemPrice[itemId]);

            menu.AddItem("item", sItems);
        }

    }

    menu.ExitButton = true;
    
    menu.Display(client, MENU_DISPLAY_TIME );
}
public int unlocksMenuCallback(Handle menu, MenuAction action, int client, int itemId)
{
    if( action == MenuAction_Select )
    {    
        int getUnlocks = getPlayerUnlocks( client );
        
        int iPrice = uItemPrice[itemId];
        
        if (getUnlocks >= iPrice && !playerItems[client][itemId] && ((uItemRebuy[itemId] < 1) || (uItemRebuy[itemId] > 0
        && ((uItemRebuyTimes[itemId] < 1) || (uItemRebuyTimes[itemId] > 0 && playerItemRebuyTimes[client][itemId] < uItemRebuyTimes[itemId])))))
        {
            hookItemSet(client, itemId, false);
            
            setPlayerUnlocks( client, getUnlocks - iPrice );
            
            mainUnlocksMenu(client);
        }
    } 
    else if (action == MenuAction_End)    
    {
        delete menu;
    }
}

public void hookItemSet(int client, int itemId, bool itemDrop)
{
    hookItemSetCallback(client, itemId);
    
    if (uItemRebuy[itemId] < 1 || uItemRebuy[itemId] == 2) {
        playerItems[client][itemId] = true;
        
        if (uItemRebuy[itemId] == 2) {
            playerItemRebuyTimes[client][itemId]++;
        }
    } else {
        hookItemUnSetCallback(client, itemId);
        
        playerItemRebuyTimes[client][itemId]++;
        
        playerItems[client][itemId] = false;
    }
    
    if (itemDrop) {
        CPrintToChat(client, "{yellow}ITEM DROPPED!", uItemName[itemId]);
        CPrintToChat(client, "{default}Item: {yellow}%s{default}!", uItemName[itemId]);
        CPrintToChat(client, "{default}Description: {yellow}%s{default}.", uItemDesc[itemId]);
    } else {
        CPrintToChat(client, "{default}Item: {yellow}%s{default}.", uItemName[itemId]);
        CPrintToChat(client, "{default}Description: {yellow}%s{default}.", uItemDesc[itemId]);
    }
}

public void hookItemSetCallback(int client, int itemId)
{
    Handle pluginId = uItemId[itemId];
    if (pluginId == INVALID_HANDLE) {
        LogError("[Gum_shop] Handle was invalid for gumItemSetCallback in hookItemSetCallback");
        return;
    }
    Function func = GetFunctionByName (pluginId, "gumItemSetCallback");
    
    if (func == INVALID_FUNCTION) {
        LogError("[Gum_shop] not found for gumItemSetCallback in hookItemUnSetCallback");
        return;
    }
    
    Call_StartFunction(pluginId, func);
    Call_PushCell( client );
    Call_Finish();
}
public void hookItemUnSetCallback(int client, int itemId)
{
    Handle pluginId = uItemId[itemId];
    if (pluginId == INVALID_HANDLE) {
        LogError("[Gum_shop] Handle was invalid for gumItemUnSetCallback in hookItemUnSetCallback");
        return;
    }
    Function func = GetFunctionByName (pluginId, "gumItemUnSetCallback");
    
    if (func == INVALID_FUNCTION) {
        LogError("[Gum_shop] not found for gumItemUnSetCallback in hookItemUnSetCallback");
        return;
    }
    
    Call_StartFunction(pluginId, func);
    Call_PushCell( client );
    Call_Finish();
}

public int registerItemGum(Handle iIndex, const char[] iName, const char[] iDesc, int iPrice, int iRebuy, int iRebuyTimes)
{
    if( numItems == MAX_UNLOCKS )
    {
        return -1;
    }
    if (iIndex == INVALID_HANDLE) {
        LogError("[Gum_shop] Invalid plugin handle while registering plugin.");
        return -1;
    }
    uItemId[numItems] = iIndex;
    Format(uItemName[numItems], MAX_UNLOCKS_NAME_SIZE, iName);
    Format(uItemDesc[numItems], MAX_UNLOCKS_DESC_SIZE, iDesc);
    uItemPrice[numItems] = iPrice;
    uItemRebuy[numItems] = iRebuy;
    uItemRebuyTimes[numItems] = iRebuyTimes;
    
    numItems++;
    
    return numItems;
}