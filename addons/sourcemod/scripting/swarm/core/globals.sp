// Zombie class variables
ArrayList g_aZombieClass = null;
int numClasses;
// Player
int pTeam[MAXPLAYERS + 1];
int zombieClass[MAXPLAYERS + 1];
bool b_isGhost[MAXPLAYERS + 1];
bool g_isCooldown[MAXPLAYERS + 1];
bool shouldCollide[MAXPLAYERS + 1];
bool canJoin[MAXPLAYERS + 1];
bool canIgnore[MAXPLAYERS + 1];
int g_fLastButtons[MAXPLAYERS + 1 ];
float f_HintSpeed[MAXPLAYERS + 1 ];
bool b_OverrideHint[MAXPLAYERS + 1];
char c_OverrideHintText[MAXPLAYERS + 1][MAX_HINT_SIZE];
int timerZombieRespawnLeft[MAXPLAYERS + 1];
// Spawn list
int CTSpawns, TSpawns;
float Spawns[5][MAXPLAYERS + 1][3];
// Files
char downloadFilesPath[PLATFORM_MAX_PATH];
// Timers
Handle timerGhostHint[MAXPLAYERS + 1] = null;
Handle timerZombieRespawn[MAXPLAYERS + 1];
Handle timerCountDown = null;
Handle Cooldown[MAXPLAYERS + 1] = null;
// Forwards
Handle forwardZombieSelected = null;
Handle forwardZombieRightClick = null;
Handle fw_ZSOnLoaded = null;
Handle fw_ZSOnAbilityButtonPressed = null;
Handle fw_ZSOnAbilityButtonReleased = null;
// TODO: When we start implenting abilities
//Handle fw_ZSOnAbilityStarted = null;
//Handle fw_ZSOnAbilityFinished = null;
//Handle fw_ZSOnAbilityCDStarted = null;
//Handle fw_ZSOnAbilityCDEnded = null;
// Plugin ConVars
ConVar cvarRespawnTimeZ;
ConVar cvarRespawnTimeZVip;
ConVar cvarRespawnTimeS;
ConVar cvarRespawnTimeSVip;
ConVar cvarRoundStartZombies;
ConVar cvarRoundKillsTeamJoinHumans;
ConVar cvarFog;
ConVar cvarCountDown;
ConVar cvarFogDensity;
ConVar cvarFogStartDist;
ConVar cvarFogEndDist;
ConVar cvarFogColor;
ConVar cvarFogZPlane;
ConVar cvarOverlayCTWin;
ConVar cvarOverlayTWin;
ConVar cvarOverlayEnable;
ConVar cvarHumanGravity;
// Server ConVars
Handle cvarAlpha;
// Misc
bool isGhostCanSpawn, roundEnded;
int roundKillCounter;
int countdownNumber;
int collisionOffset;
// Fog
int FogIndex = -1;
int SunIndex = -1;
int SkyCameraIndex = -1;
int CascadeLightIndex = -1;
// TODO: Some arrays (Should be placed in files later)
char humansWinSounds[][] = 
{
    "swarm/hwin1.mp3",
    "swarm/hwin2.mp3",
    "swarm/hwin3.mp3"
};

char zombiesWinSounds[][] = 
{
    "swarm/zwin1.mp3",
    "swarm/zwin2.mp3",
    "swarm/zwin3.mp3"
};

char countdownSounds[][] = {
    "swarm/countdown/1.mp3",
    "swarm/countdown/2.mp3",
    "swarm/countdown/3.mp3",
    "swarm/countdown/4.mp3",
    "swarm/countdown/5.mp3",
    "swarm/countdown/6.mp3",
    "swarm/countdown/7.mp3",
    "swarm/countdown/8.mp3",
    "swarm/countdown/9.mp3",
    "swarm/countdown/10.mp3",
};