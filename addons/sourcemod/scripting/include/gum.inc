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
 * @param client    An integer.
 * @param value    An integer.
 * @return        None.
 */
native void GUM_SetPlayerUnlocks(int client, int value );

/**
 * Sets player's unlocks.
 *
 * @param id    An integer.
 * @param value    An integer.
 * @return        None.
 */
native void GUM_SetPlayerLevel(int client, int level );

/**
 * Gets player's unlocks.
 *
 * @param client    An integer.
 * @return        Returns player's carrying unlocks.
 */
native int GUM_GetPlayerUnlocks(int client );


/**
 * Gets max possible level
 *
 * @return        Returns max possible level
 */
native int GUM_GetMaxLevel( );

/*
 * Gets player's level.
 *
 * @param client    An integer.
 * @return        returns Player level
 */
native int GUM_GetPlayerLevel(int client );

/**
 * Gets player's total unlocks to level up.
 *
 * @return        Returns possible max level in game
 */
native int GUM_GetUnlocksToLevel(int client );

/**
 * Gets player verbose rank by level
 * @param client    An integer.
 * @param char      String to write result.
 * @return        Bytes written to string
 */
native int GUM_GetRankName(int client, char[] rankname );


/**
 * Called when player level up or being assigned levels
 * @param client    An integer.
 * @return        void
 */
forward void GUM_OnLevelUp(int client);

