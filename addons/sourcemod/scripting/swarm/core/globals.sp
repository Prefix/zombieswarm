// Zombie class variables
ArrayList g_aZombieClass = null;
ArrayList g_aZombieAbility = null;
ArrayList g_aPlayerAbility = null;
int g_iNumClasses = 0;
int g_iNumAbilities = 0;
int g_iNumPlayerAbilities = 0;
// Player
int g_iTeam[MAXPLAYERS + 1];
int g_iZombieClass[MAXPLAYERS + 1];
bool g_bGhost[MAXPLAYERS + 1];
bool g_bCooldown[MAXPLAYERS + 1];
bool g_bShouldCollide[MAXPLAYERS + 1];
bool g_bCanJoin[MAXPLAYERS + 1];
bool g_bCanIgnore[MAXPLAYERS + 1];
int g_fLastButtons[MAXPLAYERS + 1 ];
float g_fHintSpeed[MAXPLAYERS + 1 ];
bool g_bOverrideHint[MAXPLAYERS + 1];
char g_sOverrideHintText[MAXPLAYERS + 1][MAX_HINT_SIZE];
int g_iZombieRespawnLeft[MAXPLAYERS + 1];
// Spawn list
int g_iCTSpawns;
int g_iTSpawns;
float g_fSpawns[5][MAXPLAYERS + 1][3];
// Files
char g_sDownloadFilesPath[PLATFORM_MAX_PATH];
// Timers
Handle g_hTimerGhostHint[MAXPLAYERS + 1] = null;
Handle g_hTimerZombieRespawn[MAXPLAYERS + 1];
Handle g_hTimerCountDown = null;
Handle g_hTimerCooldown[MAXPLAYERS + 1] = null;
// Forwards
Handle g_hForwardZombieSelected = null;
Handle g_hForwardZombieRightClick = null;
Handle g_hForwardZSOnLoaded = null;
Handle g_hForwardAbilityButtonPressed = null;
Handle g_hForwardAbilityButtonReleased = null;
// TODO: When we start implenting abilities
Handle g_hForwardOnAbilityStarted = null;
//Handle g_hForwardOnAbilityFinished = null;
Handle g_hForwardOnAbilityCDStarted = null;
Handle g_hForwardOnAbilityCDEnded = null;
// Plugin ConVars
ConVar g_cRespawnTimeZ;
ConVar g_cRespawnTimeZVip;
ConVar g_cRespawnTimeS;
ConVar g_cRespawnTimeSVip;
ConVar g_cRoundStartZombies;
ConVar g_cRoundKillsTeamJoinHumans;
ConVar g_cFog;
ConVar g_cCountDown;
ConVar g_cFogDensity;
ConVar g_cFogStartDist;
ConVar g_cFogEndDist;
ConVar g_cFogColor;
ConVar g_cFogZPlane;
ConVar g_cOverlayCTWin;
ConVar g_cOverlayTWin;
ConVar g_cOverlayEnable;
ConVar g_cHumanGravity;
ConVar g_cGhostMode;
// Server ConVars
Handle g_cAlpha;
// Misc
bool g_bGhostCanSpawn;
bool g_bRoundEnded;
int g_iRoundKillCounter;
int g_iCountdownNumber;
int g_iCollisionOffset;
// Fog
int g_iFogIndex = -1;
int g_iSunIndex = -1;
int g_iSkyCameraIndex = -1;
int g_iCascadeLightIndex = -1;

// Sounds
char g_HumanWinSounds[64][PLATFORM_MAX_PATH];
char g_ZombieWinSounds[64][PLATFORM_MAX_PATH];
char g_CountdownSounds[64][PLATFORM_MAX_PATH];

int g_iTotalHumanWinSounds = 0;
int g_iTotalZombieWinSounds = 0;
int g_iTotalCountdownSounds = 0;