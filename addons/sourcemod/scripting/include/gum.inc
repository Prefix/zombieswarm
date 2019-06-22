#if defined _gum_included_
  #endinput
#endif
#define _gum_included_
/**
 * Number of valid player slots.
 **/
enum
{ 
	WEAPON_SLOT_INVALID = -1,
	
	WEAPON_SLOT_PRIMARY, 
	WEAPON_SLOT_SECONDARY, 
	WEAPON_SLOT_MELEE, 
	WEAPON_SLOT_EQUEPMENT
};

/**
 * Lenth of usual strings.
 **/
#define SMALL_LINE_LENGTH 	32
#define NORMAL_LINE_LENGTH 	64
#define BIG_LINE_LENGTH 	128
#define HUGE_LINE_LENGTH	512

/**
 * Sets player's unlocks.
 *
 * @param id    An integer.
 * @param value    An integer.
 * @return        None.
 */
native void GUM_SetPlayerUnlocks(int id, int value );


/**
 * Gets player's unlocks.
 *
 * @param id    An integer.
 * @return        Returns player's carrying unlocks.
 */
native int GUM_GetPlayerUnlocks(int id );


/**
 * Gets max possible level
 *
 * @return        Returns max possible level
 */
native int GUM_GetMaxLevel( );

/*
 * Gets player's level.
 *
 * @param id    An integer.
 * @return        returns Player level
 */
native int GUM_GetPlayerLevel(int id );

/**
 * Gets player's total unlocks to level up.
 *
 * @return        Returns possible max level in game
 */
native int GUM_GetUnlocksToLevel(int id );

/**
 * Gets player verbose rank by level
 * @param client    An integer.
 * @param char      String to write result.
 * @return        Bytes written to string
 */
native int GUM_GetRankName(int client, char[] rankname );


/* Search and get plugin item index */
public Handle findItemIndex()
{
	char name[64], pluginName[64];
	Handle iter = GetPluginIterator();
	Handle pluginId;
	
	GetPluginFilename( null, pluginName, sizeof ( pluginName ) );
	
	while (MorePlugins(iter))
	{
		pluginId = ReadPlugin(iter);
	
		GetPluginFilename( pluginId, name, sizeof( name ) );
		
 		if(StrEqual(name, pluginName))
		{
			return pluginId;
		}
	}
	
	CloseHandle(iter);

 	return null;
}

/* Register item function */
public int registerGumItem(const char[] itemName, const char[] itemDesc, int itemCost, int itemRebuy, int itemRebuyTimes)
{
	Handle itemIndex = findItemIndex();
	Handle itemPlugin = FindPluginByFile( "swarm/gum_shop.smx" );
	if (itemPlugin == INVALID_HANDLE) {
		LogError ( "Couldn't find swarm/gum_shop.smx!" );
		return 0;
	}
	Function itemRegFunc = GetFunctionByName (itemPlugin, "registerItemGum");
	
	int temp = 0;
	Call_StartFunction(itemPlugin, itemRegFunc);

	Call_PushCell(itemIndex);
	Call_PushString(itemName);
	Call_PushString(itemDesc);
	Call_PushCell(itemCost);
	Call_PushCell(itemRebuy);
	Call_PushCell(itemRebuyTimes);
	
	temp = Call_Finish();
	
	if( temp == -1 ) 
	{
		LogError ( "MAX_UNLOCKS are reached maximum limit!" );
		return 0;
	} else {
		LogError("temp: %d", temp);
	}

	return temp;
}