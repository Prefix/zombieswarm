ArrayList weaponEntities;
ArrayList weaponUnlocks;
ArrayList weaponAmmo;
ArrayList weaponNames;
ArrayList rankNames;

bool weaponSelected[MAXPLAYERS + 1];

#if defined _zombieplaguemod_included
bool zpLoaded;
#endif

#if defined _zr_included
bool zrLoaded;
#endif

#if defined _zombieswarm_included
bool zmLoaded;
#endif

Handle cvarMenuTime, cvarWeaponMenu,
cvarMenuDelay, cvarMenuReOpen, cvarSaveType, cvarEnableTop10, 
cvarWeaponRestriction, cvarMenuAutoReOpenTime, cvarMaxSecondary, ClientPrimaryCookie = INVALID_HANDLE,
ClientSecondaryCookie = INVALID_HANDLE;

Database conDatabase = null;
Handle menuTimer[MAXPLAYERS + 1] = null;
Handle g_hForwardOnLevelUp;

int playerLevel[MAXPLAYERS + 1], pUnlocks[MAXPLAYERS + 1];
int rememberPrimary[MAXPLAYERS + 1], rememberSecondary[MAXPLAYERS + 1];

char modConfig[PLATFORM_MAX_PATH];