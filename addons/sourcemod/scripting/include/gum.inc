#if defined _gum_included_
  #endinput
#endif
#define _gum_included_

// Checks if user connected, whithout any errors.
#define IsValidClient(%1)  ( 1 <= %1 <= MaxClients && IsClientInGame(%1) )
// Checks if user alive, whithout any errors.
#define IsValidAlive(%1) ( 1 <= %1 <= MaxClients && IsClientInGame(%1) && IsPlayerAlive(%1) )

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
native void setPlayerUnlocks( id, value );


/**
 * Gets player's unlocks.
 *
 * @param id    An integer.
 * @return        Returns player's carrying unlocks.
 */
native int getPlayerUnlocks( id );


/**
 * Gets player's level.
 *
 * @param id    An integer.
 * @return        Returns player's level.
 */
native int getMaxLevel( );

/**
 * Gets maximum possible level
 *
 * @return        Returns possible max level in game
 */
native int getPlayerLevel( id );


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

/**
 * Precache models and also adding them into the downloading table.
 * 
 * @param modelPath			The model path.
 *
 * @return					The model index.
 **/
stock int FakePrecacheModel(const char[] modelPath)
{
	// Precache main model
	int modelIndex = PrecacheModel(modelPath);
	
	// Adding main model to the download list
	AddFileToDownloadsTable(modelPath);

	// Initialize path char
	char fullPath[PLATFORM_MAX_PATH];
	char typePath[4][SMALL_LINE_LENGTH] = { ".dx90", ".phy", ".vvd", ".dx90.vtx" };
	
	// Get number of the all types
	int iSize = sizeof(typePath);
	
	// i = type index
	for(int i = 0; i < iSize; i++)
	{
		// Adding other parts to download list
		Format(fullPath, sizeof(fullPath), "%s", modelPath);
		ReplaceString(fullPath, sizeof(fullPath), ".mdl", typePath[i]);
		if(FileExists(fullPath)) {
			AddFileToDownloadsTable(fullPath);
		} else {
			LogMessage("%s does not exist", fullPath);
		}
	}
	
	// Return model index
	return modelIndex;
}

/**
 * Precache sounds and also adding them into the downloading table.
 * 
 * @param soundPath			The sound path. .
 **/
stock void FakePrecacheSound(const char[] soundPath)
{
	// Initialize path char
	char fullPath[PLATFORM_MAX_PATH];
	
	// Adding sound to the download list
	Format(fullPath, sizeof(fullPath), "sound/%s", soundPath);
	if(FileExists(fullPath)) {
		AddFileToDownloadsTable(fullPath);
	} else {
		LogMessage("%s does not exist", fullPath);
	}
	
	// Precache sound
	Format(fullPath, sizeof(fullPath), "*/%s", soundPath);
	AddToStringTable(FindStringTable("soundprecache"), fullPath);
}