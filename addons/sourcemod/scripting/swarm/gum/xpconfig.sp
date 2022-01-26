char xpConfig[PLATFORM_MAX_PATH];

ConVar g_cEXP_Damage;
ConVar g_cEXP_Kill;
ConVar g_cEXP_MultiKill;
ConVar g_cEXP_HappyHour;
ConVar g_cEXP_ExtraName;
ConVar g_cEXP_ExtraClan;
ConVar g_cEXP_WinRound;
ConVar g_cEXP_SurviveTime;
ConVar g_cEXP_MostDamage;

ArrayList g_aExperienceDamage;
ArrayList g_aExperienceKill;
ArrayList g_aExperienceHappyHour;
ArrayList g_aExperienceWin;
ArrayList g_aExperienceMostDamage;
ArrayList g_aExperienceName;
ArrayList g_aExperienceClan;
ArrayList g_aExperienceSurvive;
ArrayList g_aExperienceMulti;

ArrayList g_aPlayerRewardDamage;
ArrayList g_aPlayerSurviveTimers;
ArrayList g_aPlayerMultiKillTimers;

int g_iPlayersOnline = 0;

ArrayList g_aActiveHappyHours;

#pragma unused g_iTotalPMK,g_aPlayerMultiKillTimers,g_cEXP_MultiKill,g_aExperienceMulti

int pKillDone[MAXPLAYERS + 1];
int pDamageDone[MAXPLAYERS + 1];

enum typesBonus {
    configDamage,
    configKills,
    configWinRound
}

#define WAIT_AFTER_KILL 1.0
#define MAX_MKILL_TIER 15

int g_iTotalPMK = 0;

enum struct PlayerMultiKill {
    int unique;
    int client;
    int kills;
    int start_id; // So it wont duplicate
    int seeking_mkill; // if max than seeking_mkill == current_mkill
    int current_mkill; // -1 if haven't reached any seeking_mkill yet
    float nextsound; // Lets not play sound every x seconds? GetGameTime()
    float expires; // GetGameTime() expires 
    Handle sound; // Run timer to make sound ;)
    Handle expiration; // Run timer to expire multi kill if havent reached seeking_mkill ;)
}

enum struct PlayerSurviveBonus {
    int client;
    int survive_id;
    Handle timer;
}

enum struct HappyHourBonus {
    char Unique[64];
    typesBonus Type;
    bool T; // Terrorist
    bool CT; // Counter-Terrorist
    bool UseFlags;
    char Flags[32]; // flags
    int XP;
    int Damage; // For damage type only
    int MinLevel;
    int MaxLevel;
    int MinPlayers;
    int MaxPlayers;
}

enum struct PlayerRewardDamage {
    char Unique[64];
    int Client;
    int Damage;
    bool IsEvent;
}

enum struct XPConfigDamage {
    char Unique[64];
    bool T; // Terrorist
    bool CT; // Counter-Terrorist
    bool UseFlags;
    char Flags[32]; // flags
    int XP;
    int Damage;
    int MinLevel;
    int MaxLevel;
    int MinPlayers;
    int MaxPlayers;
}
enum struct XPConfigKill {
    char Unique[64];
    bool T; // Terrorist
    bool CT; // Counter-Terrorist
    bool UseFlags;
    char Flags[32]; // flags
    int XP;
    int MinLevel;
    int MaxLevel;
    int MinPlayers;
    int MaxPlayers;
}

enum struct XPConfigMulti {
    char Unique[64];
    bool T; // Terrorist
    bool CT; // Counter-Terrorist
    bool UseFlags;
    char Flags[32]; // flags
    int XP;
    int ActiveSeconds;
    int Kills;
    char Prev_Unique[64];
    ArrayList EnemySounds;
    ArrayList TeamSounds;
    char EnemyMessage[64];
    char TeamMessage[64];
}

enum struct XPConfigHappyHour {
    char Unique[64];
    char name[64];
    bool Excluded;
    int startH;
    int startM;
    int endH;
    int endM;
    int MinPlayers;
    int MaxPlayers;
    ArrayList Bonus;
}

enum struct XPConfigName {
    char Unique[64];
    bool T; // Terrorist
    bool CT; // Counter-Terrorist
    bool UseFlags;
    char Flags[32]; // flags
    int XP;
    char ExtraIdentifier[64];
    char Message[128];
    int BonusTimerSeconds;
    bool AllowSpectator;
    int MinPlayers;
    int MaxPlayers;
}

enum struct XPConfigClan {
    char Unique[64];
    bool T; // Terrorist
    bool CT; // Counter-Terrorist
    bool UseFlags;
    char Flags[32]; // flags
    int XP;
    char ExtraIdentifier[64];
    char Message[128];
    int BonusTimerSeconds;
    bool AllowSpectator;
    int MinPlayers;
    int MaxPlayers;
}

enum struct XPConfigWin {
    char Unique[64];
    bool T; // Terrorist
    bool CT; // Counter-Terrorist
    bool UseFlags;
    char Flags[32]; // flags
    int XP;
    bool Alive;
    int MinPlayers;
    int MaxPlayers;
    int MinLevel;
    int MaxLevel;
}

enum struct XPConfigMostDamage {
    char Unique[64];
    bool T; // Terrorist
    bool CT; // Counter-Terrorist
    bool UseFlags;
    char Flags[32]; // flags
    int XP;
    int MinPlayers;
    int MaxPlayers;
}

enum struct XPConfigSurvive {
    char Unique[64];
    bool T; // Terrorist
    bool CT; // Counter-Terrorist
    bool UseFlags;
    char Flags[32]; // flags
    int XP;
    int time;
    int MinPlayers;
    int MaxPlayers;
    int MinLevel;
    int MaxLevel;
}


public void InitExperience()
{
    // Experience
    g_cEXP_Damage = AutoExecConfig_CreateConVar("gum_enable_damage", "1", "Enable damage module experiance");
    g_cEXP_Kill = AutoExecConfig_CreateConVar("gum_enable_kill", "1", "Enable kill module experiance");
    g_cEXP_MultiKill = AutoExecConfig_CreateConVar("gum_enable_multidamage", "1", "Enable multi kill module experiance");
    g_cEXP_HappyHour = AutoExecConfig_CreateConVar("gum_enable_happyhour", "1", "Enable happyhour module experiance");
    g_cEXP_ExtraName = AutoExecConfig_CreateConVar("gum_enable_extraname", "1", "Enable extra name module experiance");
    g_cEXP_ExtraClan = AutoExecConfig_CreateConVar("gum_enable_extraclan", "1", "Enable extra clan module experiance");
    g_cEXP_WinRound = AutoExecConfig_CreateConVar("gum_enable_winround", "1", "Enable win round module experiance");
    g_cEXP_SurviveTime = AutoExecConfig_CreateConVar("gum_enable_survivetime", "1", "Enable survive time module experiance");
    g_cEXP_MostDamage = AutoExecConfig_CreateConVar("gum_enable_mostdamage", "1", "Enable most damage module experiance");
}
public void ImportEXPConfig()
{
    BuildPath(Path_SM, xpConfig, sizeof(xpConfig), "configs/gunxpmod/gum_experience.cfg");
    KeyValues kvModCfg = CreateKeyValues("Experience");

    if (!kvModCfg.ImportFromFile(xpConfig)) {
        LogError("Couldn't import: \"%s\"", xpConfig);
        SetFailState("Couldn't import: \"%s\"", xpConfig);
        return;
    }
    if (!kvModCfg.GotoFirstSubKey()) {
        LogError("Couldn't import [EMPTY FILE]: \"%s\"", xpConfig);
        SetFailState("Couldn't import [EMPTY FILE]: \"%s\"", xpConfig);
        return;
    }

    g_aExperienceDamage = new ArrayList(sizeof(XPConfigDamage));
    g_aExperienceKill = new ArrayList(sizeof(XPConfigKill));
    //g_aExperienceMulti = new ArrayList(sizeof(XPConfigMulti));
    g_aExperienceHappyHour = new ArrayList(sizeof(XPConfigHappyHour));
    g_aExperienceName = new ArrayList(sizeof(XPConfigName));
    g_aExperienceClan = new ArrayList(sizeof(XPConfigClan));
    g_aExperienceWin = new ArrayList(sizeof(XPConfigWin));
    g_aExperienceMostDamage = new ArrayList(sizeof(XPConfigMostDamage));
    g_aExperienceSurvive = new ArrayList(sizeof(XPConfigSurvive));
    g_aPlayerRewardDamage = new ArrayList(sizeof(PlayerRewardDamage));
    g_aActiveHappyHours = new ArrayList();
    g_aPlayerSurviveTimers = new ArrayList(sizeof(PlayerSurviveBonus));
    //g_aPlayerMultiKillTimers = new ArrayList(sizeof(PlayerMultiKill));
    
    char sectionname[PLATFORM_MAX_PATH];
    int xyz = 0;
    do
    {
        kvModCfg.GetSectionName(sectionname, sizeof(sectionname));
        char newkey[32];
        Format(newkey, sizeof(newkey), "%s-%i", sectionname, xyz);
        //kvModCfg.JumpToKey(newkey, false);
        
        if (!kvModCfg.GotoFirstSubKey()) {
            continue;
        }
        do
        {
            kvModCfg.GetSectionName(newkey, sizeof(newkey));
            if (kvModCfg.GetNum("enabled", 0) == 0)
            {
                xyz++;
                continue;
            }
            char unique[64];
            kvModCfg.GetString("unique", unique, sizeof(unique), "not-found");
            if (StrEqual(unique, "not-found")) {
                LogError("Unique name field not found in [%s->%s] %s", sectionname,newkey, xpConfig);
                xyz++;
                continue;
            }
            char flags[32];
            if (StrEqual(sectionname, "damage")) {
                int ct = kvModCfg.GetNum("CounterTerrorist", -1);
                int t = kvModCfg.GetNum("Terrorist", -1);
                int damage = kvModCfg.GetNum("damage", -1);
                int xp = kvModCfg.GetNum("xp", -1);
                int minlevel = kvModCfg.GetNum("minlevel", 0);
                int maxlevel = kvModCfg.GetNum("maxlevel", weaponEntities.Length-1);
                int minplayers = kvModCfg.GetNum("minplayers", 1);
                int maxplayers = kvModCfg.GetNum("maxplayers", MAXPLAYERS);
                if (minplayers > maxplayers || minplayers < 0 || maxplayers < 0 || maxplayers > MAXPLAYERS){
                    LogError("Min level should not be higher max level [%s->%s] %s", sectionname,newkey, xpConfig);
                    xyz++;
                    continue;
                }
                if (minlevel > maxlevel){
                    LogError("Min level should not be higher max level [%s->%s] %s", sectionname,newkey, xpConfig);
                    xyz++;
                    continue;
                }
                if (minlevel > weaponEntities.Length-1 || minlevel < 0){
                    LogError("Misconfigurated minlevel found in [%s->%s] %s", sectionname,newkey, xpConfig);
                    xyz++;
                    continue;
                }
                if (maxlevel > weaponEntities.Length-1 || maxlevel < 0){
                    LogError("Misconfigurated maxlevel found in [%s->%s] %s", sectionname,newkey, xpConfig);
                    xyz++;
                    continue;
                }
                kvModCfg.GetString("flags", flags, sizeof(flags), "");
                // todo add check if unique already exists
                if (ct == -1 || t == -1 || damage == -1 || xp == -1) {
                    LogError("Misconfigurated field found in [%s->%s] %s", sectionname,newkey, xpConfig);
                    xyz++;
                    continue;
                }
                XPConfigDamage config;
                strcopy(config.Unique, sizeof(XPConfigDamage::Unique), unique);
                config.T = t == 1 ? true : false;
                config.CT = ct == 1 ? true : false;
                config.XP = xp > 0 ? xp : 0;
                config.MinLevel = minlevel;
                config.MaxLevel = maxlevel;
                config.MinPlayers = minplayers;
                config.MaxPlayers = maxplayers;
                strcopy(config.Flags, sizeof(XPConfigDamage::Flags), flags);
                config.UseFlags = strlen(flags) > 0 ? true : false;
                config.Damage = damage;
                g_aExperienceDamage.PushArray(config, sizeof(config));
            } else if (StrEqual(sectionname, "kill")) {
                int ct = kvModCfg.GetNum("CounterTerrorist", -1);
                int t = kvModCfg.GetNum("Terrorist", -1);
                int xp = kvModCfg.GetNum("xp", -1);
                kvModCfg.GetString("flags", flags, sizeof(flags), "");
                int minlevel = kvModCfg.GetNum("minlevel", 0);
                int maxlevel = kvModCfg.GetNum("maxlevel", weaponEntities.Length-1);
                int minplayers = kvModCfg.GetNum("minplayers", 1);
                int maxplayers = kvModCfg.GetNum("maxplayers", MAXPLAYERS);
                if (minplayers > maxplayers || minplayers < 0 || maxplayers < 0 || maxplayers > MAXPLAYERS){
                    LogError("Min level should not be higher max level [%s->%s] %s", sectionname,newkey, xpConfig);
                    xyz++;
                    continue;
                }
                if (minlevel > maxlevel){
                    LogError("Min level should not be higher max level [%s->%s] %s", sectionname,newkey, xpConfig);
                    xyz++;
                    continue;
                }
                if (minlevel > weaponEntities.Length-1 || minlevel < 0){
                    LogError("Misconfigurated minlevel found in [%s->%s] %s", sectionname,newkey, xpConfig);
                    xyz++;
                    continue;
                }
                if (maxlevel > weaponEntities.Length-1 || maxlevel < 0){
                    LogError("Misconfigurated maxlevel found in [%s->%s] %s", sectionname,newkey, xpConfig);
                    xyz++;
                    continue;
                }
                // todo add check if unique already exists
                if (ct == -1 || t == -1|| xp == -1) {
                    LogError("Misconfigurated field found in [%s->%s] %s", sectionname,newkey, xpConfig);
                    xyz++;
                    continue;
                }
                XPConfigKill config;
                strcopy(config.Unique, sizeof(XPConfigKill::Unique), unique);
                config.T = t == 1 ? true : false;
                config.CT = ct == 1 ? true : false;
                config.XP = xp > 0 ? xp : 0;
                config.MinLevel = minlevel;
                config.MaxLevel = maxlevel;
                config.MinPlayers = minplayers;
                config.MaxPlayers = maxplayers;
                strcopy(config.Flags, sizeof(XPConfigKill::Flags), flags);
                config.UseFlags = strlen(flags) > 0 ? true : false;
                g_aExperienceKill.PushArray(config, sizeof(config));
            /*} else if (StrEqual(sectionname, "multi")) {
                int ct = kvModCfg.GetNum("CounterTerrorist", -1);
                int t = kvModCfg.GetNum("Terrorist", -1);
                int xp = kvModCfg.GetNum("xp", -1);
                kvModCfg.GetString("flags", flags, sizeof(flags), "");
                char prev_unique[64];
                int secsbefore = kvModCfg.GetNum("activeseconds", -1);
                int kills = kvModCfg.GetNum("kills", -1);
                kvModCfg.GetString("previuos_unique", prev_unique, sizeof(prev_unique), "");
                // todo add check if unique already exists
                if (ct == -1 || t == -1|| xp == -1 || kills == -1 || secsbefore == -1) {
                    LogError("Misconfigurated field found in [%s->%s] %s", sectionname,newkey, xpConfig);
                    xyz++;
                    continue;
                }
                XPConfigMulti config;
                strcopy(config.Unique, sizeof(XPConfigMulti::Unique), unique);
                config.T = t == 1 ? true : false;
                config.CT = ct == 1 ? true : false;
                config.XP = xp > 0 ? xp : 0;
                strcopy(config.Flags, sizeof(XPConfigKill::Flags), flags);
                config.UseFlags = strlen(flags) > 0 ? true : false;
                
                config.Kills = kills;
                config.ActiveSeconds = secsbefore;
                config.EnemySounds = new ArrayList(ByteCountToCells(PLATFORM_MAX_PATH));
                config.TeamSounds = new ArrayList(ByteCountToCells(PLATFORM_MAX_PATH));
                if (kvModCfg.JumpToKey("enemy", false))
                {
                    char enemymessage[64];
                    kvModCfg.GetString("message", enemymessage, sizeof(enemymessage), "not-found");
                    if (strlen(enemymessage) > 0 && !StrEqual(enemymessage, "not-found"))
                    {
                        strcopy(config.EnemyMessage, sizeof(XPConfigMulti::EnemyMessage), enemymessage);
                    }
                    int fieldenemy = 1;
                    bool scatter = false;
                    while (!scatter) {
                        char formatsoundkey[10];
                        char enemysoundbuffer[PLATFORM_MAX_PATH];
                        Format(formatsoundkey, sizeof(formatsoundkey), "sound%i", fieldenemy);
                        kvModCfg.GetString(formatsoundkey, enemysoundbuffer, sizeof(enemysoundbuffer), "notexists");
                        if (StrEqual(enemysoundbuffer, "notexists")) {
                            break;
                        }

                        if (strlen(enemysoundbuffer) > 0) {
                            PrecacheSoundAny( enemysoundbuffer, true );
                            char sPath[PLATFORM_MAX_PATH];
                            Format(sPath, sizeof(sPath), "sound/%s", enemysoundbuffer);
                            AddFileToDownloadsTable( sPath );
                            config.EnemySounds.PushString(enemysoundbuffer);
                        }

                        fieldenemy++;
                    }
                    kvModCfg.GoBack();
                }
                if (kvModCfg.JumpToKey("team", false))
                {
                    char teammessage[64];
                    kvModCfg.GetString("message", teammessage, sizeof(teammessage), "not-found");
                    if (strlen(teammessage) > 0 && !StrEqual(teammessage, "not-found"))
                    {
                        strcopy(config.TeamMessage, sizeof(XPConfigMulti::TeamMessage), teammessage);
                    }
                    int fieldteam = 1;
                    bool scatter = false;
                    while (!scatter) {
                        char formatsoundkey[10];
                        char teamsoundbuffer[PLATFORM_MAX_PATH];
                        Format(formatsoundkey, sizeof(formatsoundkey), "sound%i", fieldteam);
                        kvModCfg.GetString(formatsoundkey, teamsoundbuffer, sizeof(teamsoundbuffer), "notexists");
                        if (StrEqual(teamsoundbuffer, "notexists")) {
                            break;
                        }

                        if (strlen(teamsoundbuffer) > 0) {
                            PrecacheSoundAny( teamsoundbuffer, true );
                            char sPath[PLATFORM_MAX_PATH];
                            Format(sPath, sizeof(sPath), "sound/%s", teamsoundbuffer);
                            AddFileToDownloadsTable( sPath );
                            config.EnemySounds.PushString(teamsoundbuffer);
                        }

                        fieldteam++;
                    }
                    kvModCfg.GoBack();
                }

                strcopy(config.Unique, sizeof(XPConfigMulti::Unique), unique);
                strcopy(config.Prev_Unique, sizeof(XPConfigMulti::Prev_Unique), prev_unique);
                g_aExperienceMulti.PushArray(config, sizeof(config));*/
            } else if (StrEqual(sectionname, "happyhour")) {
                char name[64];
                kvModCfg.GetString("name", name, sizeof(name), "");
                if (strlen(name) < 1) {
                    xyz++;
                    continue;
                }
                int excluded = kvModCfg.GetNum("excluded", 0);
                int startHH = kvModCfg.GetNum("startHour", -1);
                int startMM = kvModCfg.GetNum("startMinute", -1);
                int endHH = kvModCfg.GetNum("endHour", -1);
                int endMM = kvModCfg.GetNum("endMinute", -1);
                int minplayers = kvModCfg.GetNum("minplayers", 1);
                int maxplayers = kvModCfg.GetNum("maxplayers", MAXPLAYERS);
                if (minplayers > maxplayers || minplayers < 0 || maxplayers < 0 || maxplayers > MAXPLAYERS){
                    LogError("Min level should not be higher max level [%s->%s] %s", sectionname,newkey, xpConfig);
                    xyz++;
                    continue;
                }

                if (startHH > 24 || startHH < 0 || startMM > 60 || startMM < 0 || endHH > 24 || endHH < 0 || endMM > 60 || endMM < 0) 
                {
                    LogError("Misconfigurated hours/minutes found in [%s->%s] %s", sectionname,newkey, xpConfig);
                    xyz++;
                    continue;
                }
                XPConfigHappyHour config;
                char hourkey[64];
                int foundbonus = 0;
                if (!kvModCfg.GotoFirstSubKey()) 
                {
                    LogError("No bonus sections found in [%s->%s] %s", sectionname,newkey, xpConfig);
                    xyz++;
                    continue;
                } 
                config.Bonus = new ArrayList(sizeof(HappyHourBonus));
                do
                {
                    kvModCfg.GetSectionName(hourkey, sizeof(hourkey));
                    int bonus_ct = kvModCfg.GetNum("CounterTerrorist", -1);
                    int bonus_t = kvModCfg.GetNum("Terrorist", -1);
                    int bonus_damage = kvModCfg.GetNum("damage", -1);
                    int bonus_xp = kvModCfg.GetNum("xp", -1);
                    int bonus_minlevel = kvModCfg.GetNum("minlevel", 0);
                    int bonus_maxlevel = kvModCfg.GetNum("maxlevel", weaponEntities.Length-1);
                    int bonus_minplayers = kvModCfg.GetNum("minplayers", 1);
                    int bonus_maxplayers = kvModCfg.GetNum("maxplayers", MAXPLAYERS);
                    if (bonus_minplayers > bonus_maxplayers || bonus_minplayers < 0 || bonus_maxplayers < 0 || bonus_maxplayers > MAXPLAYERS){
                        LogError("Min level should not be higher max level [%s->%s->%s] %s", sectionname,newkey,hourkey, xpConfig);
                        continue;
                    }
                    if (bonus_minlevel > bonus_maxlevel){
                        LogError("Min level should not be higher max level [%s->%s->%s] %s", sectionname,newkey,hourkey, xpConfig);
                        continue;
                    }
                    if (bonus_minlevel > weaponEntities.Length-1 || bonus_minlevel < 0){
                        LogError("Misconfigurated minlevel found in [%s->%s->%s] %s", sectionname,newkey,hourkey, xpConfig);
                        continue;
                    }
                    if (bonus_maxlevel > weaponEntities.Length-1 || bonus_maxlevel < 0){
                        LogError("Misconfigurated maxlevel found in [%s->%s->%s] %s", sectionname,newkey,hourkey, xpConfig);
                        continue;
                    }
                    char bonus_flags[32];
                    kvModCfg.GetString("flags", bonus_flags, sizeof(bonus_flags), "");
                    char bonus_unique[32];
                    kvModCfg.GetString("unique", bonus_unique, sizeof(bonus_unique), "not-found");
                    if (StrEqual(bonus_unique, "not-found")) {
                        LogError("Misconfigurated unique found in [%s->%s->%s] %s", sectionname,newkey,hourkey, xpConfig);
                        continue;
                    }
                    char bonus_type[32];
                    kvModCfg.GetString("type", bonus_type, sizeof(bonus_type), "not-found");
                    if (StrEqual(bonus_type, "not-found")) {
                        LogError("Misconfigurated type found in [%s->%s->%s] %s", sectionname,newkey,hourkey, xpConfig);
                        continue;
                    }

                    // todo add check if unique already exists
                    if (bonus_ct == -1 || bonus_t == -1 || bonus_xp == -1) {
                        LogError("Misconfigurated field found (One of these: CT, T, XP) in [%s->%s->%s] %s", sectionname,newkey,hourkey, xpConfig);
                        continue;
                    }
                    HappyHourBonus bonus_config;
                    if (StrEqual(bonus_type, "kill")) {
                        bonus_config.Type = configKills;
                    } else if (StrEqual(bonus_type, "damage")) {
                        bonus_config.Type = configDamage;
                        if (bonus_damage < 1) {
                            LogError("Misconfigurated bonus damage found in [%s->%s->%s] %s", sectionname,newkey,hourkey, xpConfig);
                            continue;
                        }
                    } else if (StrEqual(bonus_type, "winround")) {
                        bonus_config.Type = configWinRound;
                    } else {
                        LogError("Misconfigurated bonus type found in [%s->%s->%s] %s", sectionname,newkey,hourkey, xpConfig);
                        continue;
                    }
                    strcopy(bonus_config.Unique, sizeof(HappyHourBonus::Unique), bonus_unique);
                    bonus_config.T = view_as<bool>(bonus_t);
                    bonus_config.CT = view_as<bool>(bonus_ct);
                    bonus_config.XP = bonus_xp > 0 ? bonus_xp : 0;
                    if (bonus_xp == 0) {
                        LogError("Misconfigurated bonus xp found in [%s->%s->%s] %s", sectionname,newkey,hourkey, xpConfig);
                        continue;
                    }
                    bonus_config.MinLevel = bonus_minlevel;
                    bonus_config.MaxLevel = bonus_maxlevel;
                    bonus_config.MinPlayers = bonus_minplayers;
                    bonus_config.MaxPlayers = bonus_maxplayers;
                    strcopy(bonus_config.Flags, sizeof(HappyHourBonus::Flags), bonus_flags);
                    bonus_config.UseFlags = strlen(bonus_flags) > 0 ? true : false;
                    bonus_config.Damage = bonus_damage;
                    config.Bonus.PushArray(bonus_config, sizeof(bonus_config));
                    foundbonus++;
                } while (kvModCfg.GotoNextKey());
                kvModCfg.GoBack();
                // Comment because of custom happy hours like FreeVIP :)
                /*if (foundbonus == 0) {
                    LogError("Not valid bonus found in [%s->%s] %s", sectionname,newkey, xpConfig);
                    continue;
                }*/
                
                strcopy(config.Unique, sizeof(XPConfigHappyHour::Unique), unique);
                strcopy(config.name, sizeof(XPConfigHappyHour::name), name);
                config.startH = startHH;
                config.startM = startMM;
                config.endH = endHH;
                config.Excluded = excluded == 1 ? true : false;
                config.endM = endMM;
                config.MinPlayers = minplayers;
                config.MaxPlayers = maxplayers;
                
                g_aExperienceHappyHour.PushArray(config, sizeof(config));
            } else if (StrEqual(sectionname, "extraname")) {
                int ct = kvModCfg.GetNum("CounterTerrorist", -1);
                int t = kvModCfg.GetNum("Terrorist", -1);
                int xp = kvModCfg.GetNum("xp", -1);
                kvModCfg.GetString("flags", flags, sizeof(flags), "");
                // todo add check if unique already exists
                char extra[64];
                char message[128];
                kvModCfg.GetString("ExtraIdentifier", extra, sizeof(extra), "not-found");
                kvModCfg.GetString("Message", message, sizeof(message), "");
                int timer = kvModCfg.GetNum("BonusTimerSeconds", -1);
                int spectate = kvModCfg.GetNum("AllowSpectator", 0);
                int minplayers = kvModCfg.GetNum("minplayers", 1);
                int maxplayers = kvModCfg.GetNum("maxplayers", MAXPLAYERS);
                if (minplayers > maxplayers || minplayers < 0 || maxplayers < 0 || maxplayers > MAXPLAYERS){
                    LogError("Min level should not be higher max level [%s->%s] %s", sectionname,newkey, xpConfig);
                    xyz++;
                    continue;
                }
                
                // todo add check if unique already exists
                if (timer == -1 || xp == -1 || ct == -1 || t == -1 || StrEqual(extra, "not-found")) {
                    LogError("Misconfigurated field found in [%s->%s] %s", sectionname,newkey, xpConfig);
                    xyz++;
                    continue;
                }
                XPConfigName config;
                strcopy(config.Unique, sizeof(XPConfigName::Unique), unique);
                strcopy(config.ExtraIdentifier, sizeof(XPConfigName::ExtraIdentifier), extra);
                strcopy(config.Unique, sizeof(XPConfigName::Unique), message);
                config.T = t == 1 ? true : false;
                config.CT = ct == 1 ? true : false;
                config.MinPlayers = minplayers;
                config.MaxPlayers = maxplayers;
                config.BonusTimerSeconds = timer < 1 ? 60 : timer;
                config.AllowSpectator = view_as<bool>(spectate);
                config.XP = xp > 0 ? xp : 0;
                strcopy(config.Flags, sizeof(XPConfigName::Flags), flags);
                config.UseFlags = strlen(flags) > 0 ? true : false;
                g_aExperienceName.PushArray(config, sizeof(config));
            } else if (StrEqual(sectionname, "extraclan")) {
                int ct = kvModCfg.GetNum("CounterTerrorist", -1);
                int t = kvModCfg.GetNum("Terrorist", -1);
                int xp = kvModCfg.GetNum("xp", -1);
                kvModCfg.GetString("flags", flags, sizeof(flags), "");
                // todo add check if unique already exists
                char extra[64];
                char message[128];
                kvModCfg.GetString("ExtraIdentifier", extra, sizeof(extra), "not-found");
                kvModCfg.GetString("Message", message, sizeof(message), "");
                int timer = kvModCfg.GetNum("BonusTimerSeconds", -1);
                int spectate = kvModCfg.GetNum("AllowSpectator", 0);
                int minplayers = kvModCfg.GetNum("minplayers", 1);
                int maxplayers = kvModCfg.GetNum("maxplayers", MAXPLAYERS);
                if (minplayers > maxplayers || minplayers < 0 || maxplayers < 0 || maxplayers > MAXPLAYERS){
                    LogError("Min level should not be higher max level [%s->%s] %s", sectionname,newkey, xpConfig);
                    xyz++;
                    continue;
                }
                // todo add check if unique already exists
                if (timer == -1 || xp == -1 || ct == -1 || t == -1 || StrEqual(extra, "not-found")) {
                    LogError("Misconfigurated field found in [%s->%s] %s", sectionname,newkey, xpConfig);
                    xyz++;
                    continue;
                }
                XPConfigClan config;
                strcopy(config.Unique, sizeof(XPConfigClan::Unique), unique);
                strcopy(config.ExtraIdentifier, sizeof(XPConfigClan::ExtraIdentifier), extra);
                strcopy(config.Unique, sizeof(XPConfigClan::Unique), message);
                config.T = t == 1 ? true : false;
                config.CT = ct == 1 ? true : false;
                config.MinPlayers = minplayers;
                config.MaxPlayers = maxplayers;
                config.BonusTimerSeconds = timer < 1 ? 60 : timer;
                config.AllowSpectator = view_as<bool>(spectate);
                config.XP = xp > 0 ? xp : 0;
                strcopy(config.Flags, sizeof(XPConfigClan::Flags), flags);
                config.UseFlags = strlen(flags) > 0 ? true : false;
                g_aExperienceClan.PushArray(config, sizeof(config));
            } else if (StrEqual(sectionname, "winround")) {
                int ct = kvModCfg.GetNum("CounterTerrorist", -1);
                int t = kvModCfg.GetNum("Terrorist", -1);
                int xp = kvModCfg.GetNum("xp", -1);
                int alive = kvModCfg.GetNum("MustBeAlive", 0);
                kvModCfg.GetString("flags", flags, sizeof(flags), "");
                int minlevel = kvModCfg.GetNum("minlevel", 0);
                int maxlevel = kvModCfg.GetNum("maxlevel", weaponEntities.Length-1);
                int minplayers = kvModCfg.GetNum("minplayers", 1);
                int maxplayers = kvModCfg.GetNum("maxplayers", MAXPLAYERS);
                if (minlevel > maxlevel){
                    LogError("Min level should not be higher max level [%s->%s] %s", sectionname,newkey, xpConfig);
                    xyz++;
                    continue;
                }
                if (minlevel > weaponEntities.Length-1 || minlevel < 0){
                    LogError("Misconfigurated minlevel found in [%s->%s] %s", sectionname,newkey, xpConfig);
                    xyz++;
                    continue;
                }
                if (maxlevel > weaponEntities.Length-1 || maxlevel < 0){
                    LogError("Misconfigurated maxlevel found in [%s->%s] %s", sectionname,newkey, xpConfig);
                    xyz++;
                    continue;
                }
                if (minplayers > maxplayers || minplayers < 0 || maxplayers < 0 || maxplayers > MAXPLAYERS){
                    LogError("Min level should not be higher max level [%s->%s] %s", sectionname,newkey, xpConfig);
                    xyz++;
                    continue;
                }
                // todo add check if unique already exists
                if (ct == -1 || t == -1|| xp == -1 || alive < 0) {
                    LogError("Misconfigurated field found in [%s->%s] %s", sectionname,newkey, xpConfig);
                    xyz++;
                    continue;
                }
                XPConfigWin config;
                strcopy(config.Unique, sizeof(XPConfigWin::Unique), unique);
                config.T = t == 1 ? true : false;
                config.CT = ct == 1 ? true : false;
                config.Alive = view_as<bool>(alive);
                config.MinPlayers = minplayers;
                config.MaxPlayers = maxplayers;
                config.MinLevel = minlevel;
                config.MaxLevel = maxlevel;
                config.XP = xp > 0 ? xp : 0;
                strcopy(config.Flags, sizeof(XPConfigWin::Flags), flags);
                config.UseFlags = strlen(flags) > 0 ? true : false;
                g_aExperienceWin.PushArray(config, sizeof(config));
            } else if (StrEqual(sectionname, "mostdamage")) {
                int ct = kvModCfg.GetNum("CounterTerrorist", -1);
                int t = kvModCfg.GetNum("Terrorist", -1);
                int xp = kvModCfg.GetNum("xp", -1);
                kvModCfg.GetString("flags", flags, sizeof(flags), "");
                int minplayers = kvModCfg.GetNum("minplayers", 1);
                int maxplayers = kvModCfg.GetNum("maxplayers", MAXPLAYERS);
                if (minplayers > maxplayers || minplayers < 0 || maxplayers < 0 || maxplayers > MAXPLAYERS){
                    LogError("Min level should not be higher max level [%s->%s] %s", sectionname,newkey, xpConfig);
                    xyz++;
                    continue;
                }
                // todo add check if unique already exists
                if (ct == -1 || t == -1|| xp == -1) {
                    LogError("Misconfigurated field found in [%s->%s] %s", sectionname,newkey, xpConfig);
                    xyz++;
                    continue;
                }
                XPConfigMostDamage config;
                strcopy(config.Unique, sizeof(XPConfigMostDamage::Unique), unique);
                config.T = t == 1 ? true : false;
                config.CT = ct == 1 ? true : false;
                config.MinPlayers = minplayers;
                config.MaxPlayers = maxplayers;
                config.XP = xp > 0 ? xp : 0;
                strcopy(config.Flags, sizeof(XPConfigMostDamage::Flags), flags);
                config.UseFlags = strlen(flags) > 0 ? true : false;
                g_aExperienceMostDamage.PushArray(config, sizeof(config));
            }  else if (StrEqual(sectionname, "survivetime")) {
                int ct = kvModCfg.GetNum("CounterTerrorist", -1);
                int t = kvModCfg.GetNum("Terrorist", -1);
                int time = kvModCfg.GetNum("time", -1);
                int xp = kvModCfg.GetNum("xp", -1);
                kvModCfg.GetString("flags", flags, sizeof(flags), "");
                int minlevel = kvModCfg.GetNum("minlevel", 0);
                int maxlevel = kvModCfg.GetNum("maxlevel", weaponEntities.Length-1);
                int minplayers = kvModCfg.GetNum("minplayers", 1);
                int maxplayers = kvModCfg.GetNum("maxplayers", MAXPLAYERS);
                if (minlevel > maxlevel){
                    LogError("Min level should not be higher max level [%s->%s] %s", sectionname,newkey, xpConfig);
                    xyz++;
                    continue;
                }
                if (minlevel > weaponEntities.Length-1 || minlevel < 0){
                    LogError("Misconfigurated minlevel found in [%s->%s] %s", sectionname,newkey, xpConfig);
                    xyz++;
                    continue;
                }
                if (maxlevel > weaponEntities.Length-1 || maxlevel < 0){
                    LogError("Misconfigurated maxlevel found in [%s->%s] %s", sectionname,newkey, xpConfig);
                    xyz++;
                    continue;
                }
                if (minplayers > maxplayers || minplayers < 0 || maxplayers < 0 || maxplayers > MAXPLAYERS){
                    LogError("Min level should not be higher max level [%s->%s] %s", sectionname,newkey, xpConfig);
                    xyz++;
                    continue;
                }
                if (minplayers > maxplayers || minplayers < 0 || maxplayers < 0 || maxplayers > MAXPLAYERS){
                    LogError("Min level should not be higher max level [%s->%s] %s", sectionname,newkey, xpConfig);
                    xyz++;
                    continue;
                }
                // todo add check if unique already exists
                if (ct == -1 || t == -1|| xp == -1 || time == -1) {
                    LogError("Misconfigurated field found in [%s->%s] %s", sectionname,newkey, xpConfig);
                    xyz++;
                    continue;
                }
                XPConfigSurvive config;
                strcopy(config.Unique, sizeof(XPConfigSurvive::Unique), unique);
                config.T = t == 1 ? true : false;
                config.CT = ct == 1 ? true : false;
                config.XP = xp > 0 ? xp : 0;
                config.time = time > 0 ? time : 60;
                config.MinPlayers = minplayers;
                config.MaxPlayers = maxplayers;
                config.MinLevel = minlevel;
                config.MaxLevel = maxlevel;
                strcopy(config.Flags, sizeof(XPConfigSurvive::Flags), flags);
                config.UseFlags = strlen(flags) > 0 ? true : false;
                g_aExperienceSurvive.PushArray(config, sizeof(config));
            }
            xyz++;
        } while (kvModCfg.GotoNextKey());
        xyz = 0;
        kvModCfg.GoBack();
    } while (kvModCfg.GotoNextKey());

    delete kvModCfg;
    CalculatePlayerAmount();
    if (g_aExperienceHappyHour.Length > 0)
        CreateTimer(60.0, Timer_HappyHourCheck, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
        
    if (g_cEXP_ExtraName.BoolValue && g_aExperienceName.Length > 0)
    {
        for (int names = 0; names < g_aExperienceName.Length; names++)
        {
            XPConfigName tempConfig;
            g_aExperienceName.GetArray(names, tempConfig, sizeof(tempConfig));
            CreateTimer(float(tempConfig.BonusTimerSeconds), Timer_BonusNickname, names, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
        }
    }
    if (g_cEXP_ExtraClan.BoolValue && g_aExperienceClan.Length > 0)
    {
        for (int clantag = 0; clantag < g_aExperienceClan.Length; clantag++)
        {
            XPConfigClan tempConfig;
            g_aExperienceClan.GetArray(clantag, tempConfig, sizeof(tempConfig));
            CreateTimer(float(tempConfig.BonusTimerSeconds), Timer_BonusNickname, clantag, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
        }
    }
    
}

public Action Timer_BonusClan(Handle timer, any data)
{
    XPConfigClan tempConfig;
    g_aExperienceClan.GetArray(data, tempConfig, sizeof(tempConfig));

    for (int client = 1; client <= MaxClients; client++) 
    { 
        if (!UTIL_IsValidClient(client))
            continue;
        char clantag[64];
        CS_GetClientClanTag(client, clantag, sizeof(clantag));
        if (!StrEqual(clantag, tempConfig.ExtraIdentifier, false))
            continue;
        int team = GetClientTeam(client);
        if (!tempConfig.AllowSpectator) {
            if (!((team == CS_TEAM_CT && tempConfig.CT) || (team == CS_TEAM_T && tempConfig.T)))
                continue;
        }
        if (!CheckAdminFlagsByString(client, tempConfig.Flags)) 
            continue;
        if (g_iPlayersOnline < tempConfig.MinPlayers)
            continue;
        if (g_iPlayersOnline > tempConfig.MaxPlayers)
            continue;

        if (strlen(tempConfig.Message) > 0) {
            char NewMessage[64];
            strcopy(NewMessage, sizeof(NewMessage), tempConfig.Message);
            char xpstring[10];
            IntToString(tempConfig.XP, xpstring, sizeof(xpstring));
            ReplaceString(NewMessage, sizeof(NewMessage), "&xp&", xpstring, false);
            CPrintToChat(client, NewMessage);
        }
        setPlayerUnlocks(client, pUnlocks[client] + tempConfig.XP );
    }

    return Plugin_Continue;
}

public Action Timer_BonusNickname(Handle timer, any data)
{
    XPConfigName tempConfig;
    g_aExperienceName.GetArray(data, tempConfig, sizeof(tempConfig));

    for (int client = 1; client <= MaxClients; client++) 
    { 
        if (!UTIL_IsValidClient(client))
            continue;
        char name[64];
        Format(name, sizeof(name), "%N", client);
        if (StrContains(name, tempConfig.ExtraIdentifier, false) == -1)
            continue;
        int team = GetClientTeam(client);
        if (!tempConfig.AllowSpectator) {
            if (!((team == CS_TEAM_CT && tempConfig.CT) || (team == CS_TEAM_T && tempConfig.T)))
                continue;
        }
        if (!CheckAdminFlagsByString(client, tempConfig.Flags)) 
            continue;
        if (g_iPlayersOnline < tempConfig.MinPlayers)
            continue;
        if (g_iPlayersOnline > tempConfig.MaxPlayers)
            continue;

        if (strlen(tempConfig.Message) > 0) {
            char NewMessage[64];
            strcopy(NewMessage, sizeof(NewMessage), tempConfig.Message);
            char xpstring[10];
            IntToString(tempConfig.XP, xpstring, sizeof(xpstring));
            ReplaceString(NewMessage, sizeof(NewMessage), "&xp&", xpstring, false);
            CPrintToChat(client, NewMessage);
        }
        setPlayerUnlocks(client, pUnlocks[client] + tempConfig.XP );
    }

    return Plugin_Continue;
}

public Action Timer_HappyHourCheck(Handle timer, any data)
{
    if (!g_cEXP_HappyHour.BoolValue) return Plugin_Continue;
    char stringHour[10];
    char stringMinute[10];
    int time = GetTime();
    FormatTime(stringHour, sizeof(stringHour), "%H", time);
    FormatTime(stringMinute, sizeof(stringMinute), "%M", time);
    int hour = StringToInt(stringHour);
    int minute = StringToInt(stringMinute);
    for (int i = 0; i < g_aExperienceHappyHour.Length; i++) {
        XPConfigHappyHour tempConfig;
        g_aExperienceHappyHour.GetArray(i, tempConfig, sizeof(tempConfig));
        
        bool canstart = true;
        if (hour < tempConfig.startH || (hour == tempConfig.startH && minute < tempConfig.startM)) {
            canstart = false;
        }
        if (hour > tempConfig.endH || (hour == tempConfig.endH && minute >= tempConfig.endM)) {
            canstart = false;
        }
        if (g_iPlayersOnline < tempConfig.MinPlayers) {
            canstart = false;
        }
        if (g_iPlayersOnline > tempConfig.MaxPlayers) {
            canstart = false;
        }
        if (tempConfig.Excluded) {
            canstart = false;
        }
        if (g_aActiveHappyHours.Length == 0 && canstart) {
            g_aActiveHappyHours.Push(i);
            // TODO call forward on event started
        } else {
            bool found = false;
            for (int y = 0; y < g_aActiveHappyHours.Length; y++) {
                int value = g_aActiveHappyHours.Get(y);
                if (i == value) {
                    found = true;
                    break;
                }
            }
            if (canstart && !found) {
                g_aActiveHappyHours.Push(i);
                // TODO call forward on event started
                break;
            }
            if (!canstart && found) {
                g_aActiveHappyHours.Erase(i);
                // TODO call forward on event ended
                break;
            }
        }
    }
    return Plugin_Continue;
}

public void CalculatePlayerAmount()
{
    RequestFrame(RealCalculate);

}
void RealCalculate(any data)
{
    int players = 0;
    for(int client = 1; client <= MaxClients; client++) 
    {
        if(UTIL_IsValidClient(client)) {
            players++;
        }
    }
    g_iPlayersOnline = players;
}

void GiveHappyHourBonus(int client, typesBonus type, any data = -1)
{
    if (!g_cEXP_HappyHour.BoolValue)
        return;
    if (g_aActiveHappyHours.Length == 0)
        return;
    for (int i = 0; i < g_aActiveHappyHours.Length; i++) {
        int index = g_aActiveHappyHours.Get(i);
        if (index == -1)
            continue;
        XPConfigHappyHour tempConfig;
        g_aExperienceHappyHour.GetArray(index, tempConfig, sizeof(tempConfig));
        if (tempConfig.Bonus.Length == 0)
            continue;
        for (int y = 0; y < tempConfig.Bonus.Length; y++) {
            HappyHourBonus tempBonus;
            tempConfig.Bonus.GetArray(y, tempBonus, sizeof(tempBonus));
            if (tempBonus.Type != type)
                continue;
            int team = GetClientTeam(client);
            if (type == configWinRound && team != data)
                continue;
            if (!((team == CS_TEAM_CT && tempBonus.CT) || (team == CS_TEAM_T && tempBonus.T)))
                continue;
            if (!CheckAdminFlagsByString(client, tempBonus.Flags)) 
                continue;
            if (playerLevel[client] < tempBonus.MinLevel)
                continue;
            if (playerLevel[client] > tempBonus.MaxLevel)
                continue;
            if (g_iPlayersOnline < tempBonus.MinPlayers)
                continue;
            if (g_iPlayersOnline > tempBonus.MaxPlayers)
                continue;
            if (type == configDamage) 
            {
                bool found = false;
                
                if (g_aPlayerRewardDamage.Length > 0) {
                    for (int z = 0; z < g_aPlayerRewardDamage.Length; z++) {
                        PlayerRewardDamage tempReward;
                        g_aPlayerRewardDamage.GetArray(z, tempReward, sizeof(tempReward));
                        if (tempReward.Client != client)
                            continue;
                        if (!StrEqual(tempReward.Unique, tempBonus.Unique))
                            continue;
                        found = true;
                        // check xp
                        tempReward.Damage += view_as<int>(data);
                        while (tempReward.Damage >= tempBonus.Damage) {
                            tempReward.Damage -= tempBonus.Damage;
                            setPlayerUnlocks(client, pUnlocks[client] + tempBonus.XP );    
                            CPrintToChat(client, "[Happy hour#1 %s] Gained %i for making damage", tempBonus.Unique, tempBonus.XP);
                        }
                        g_aPlayerRewardDamage.SetArray(z, tempReward, sizeof(tempReward));
                        break;
                    }
                }
                if (found)
                    continue;
                PlayerRewardDamage reward;
                strcopy(reward.Unique, sizeof(PlayerRewardDamage::Unique), tempBonus.Unique);
                reward.Damage = view_as<int>(data);
                reward.Client = client;
                reward.IsEvent = true;
                while (reward.Damage >= tempBonus.Damage) {
                    reward.Damage -= tempBonus.Damage;
                    setPlayerUnlocks(client, pUnlocks[client] + tempBonus.XP );
                    CPrintToChat(client, "[Happy hour#2 %s] Gained %i for making damage", tempBonus.Unique, tempBonus.XP);
                }
                g_aPlayerRewardDamage.PushArray(reward, sizeof(reward)); 
            } else {
                CPrintToChat(client, "[Happyhour %s] Gained %i for %s", tempBonus.Unique, tempBonus.XP, type == configKills ? "killing" : "win round");
                setPlayerUnlocks(client, pUnlocks[client] + tempBonus.XP );
            }
        }
    }
}


void ClearSurviveTimers(int client = -1) 
{
    if (!g_cEXP_SurviveTime.BoolValue) return;
    if (g_aExperienceSurvive.Length == 0) return;
    if (g_aPlayerSurviveTimers.Length == 0) return;

    for (int i = 0; i < g_aPlayerSurviveTimers.Length; i++) 
    {
        if (i == g_aPlayerSurviveTimers.Length)
            break;
        PlayerSurviveBonus tempConfig;
        g_aPlayerSurviveTimers.GetArray(i, tempConfig, sizeof(tempConfig));
        if (client != tempConfig.client && client != -1)
            continue;

        delete tempConfig.timer;
        g_aPlayerSurviveTimers.Erase(i--);
    }

}

public void StartSurviveTimers(int client) 
{
    if (!g_cEXP_SurviveTime.BoolValue) return;
    if (g_aExperienceSurvive.Length == 0) return;

    // Clear timers first
    ClearSurviveTimers(client);
    // Start new
    for (int i = 0; i < g_aExperienceSurvive.Length; i++) 
    {
        XPConfigSurvive tempConfig;
        g_aExperienceSurvive.GetArray(i, tempConfig, sizeof(tempConfig));
        
        int team = GetClientTeam(client);
        if (!((team == CS_TEAM_CT && tempConfig.CT) || (team == CS_TEAM_T && tempConfig.T)))
            continue;
        if (!CheckAdminFlagsByString(client, tempConfig.Flags)) 
            continue;
        if (playerLevel[client] < tempConfig.MinLevel)
            continue;
        if (playerLevel[client] > tempConfig.MaxLevel)
            continue;
        if (g_iPlayersOnline < tempConfig.MinPlayers)
            continue;
        if (g_iPlayersOnline > tempConfig.MaxPlayers)
            continue;

        PlayerSurviveBonus bonus;
        bonus.client = client;
        bonus.survive_id = i;
        DataPack dp;
        //PrintToChatAll("[SurviveTime] Start %s in %f", tempConfig.Unique, float(tempConfig.time));
        bonus.timer = CreateDataTimer(float(tempConfig.time), Timer_SurviveTime, dp, TIMER_FLAG_NO_MAPCHANGE);
        dp.WriteCell(GetClientSerial(client));
        dp.WriteCell(i);
        g_aPlayerSurviveTimers.PushArray(bonus, sizeof(bonus)); 
    }
}

public Action Timer_SurviveTime(Handle timer, DataPack pack)
{
    pack.Reset();
    int client = GetClientFromSerial(pack.ReadCell()); 
    int config_id = pack.ReadCell(); 

    if ( g_aPlayerSurviveTimers.Length == 0 || g_aExperienceSurvive.Length == 0)
    {
        return Plugin_Stop;
    }
    if (!g_cEXP_SurviveTime.BoolValue)
    {
        RemoveSurviveTimer(client, config_id);
        return Plugin_Stop;
    } 
    if (!UTIL_IsValidAlive(client))
    {
        RemoveSurviveTimer(client, config_id);
        return Plugin_Stop;
    }

    XPConfigSurvive tempConfig;
    g_aExperienceSurvive.GetArray(config_id, tempConfig, sizeof(tempConfig));

    PlayerSurviveBonus bonus;
    for (int i = 0; i < g_aPlayerSurviveTimers.Length; i++) 
    {
        g_aPlayerSurviveTimers.GetArray(i, bonus, sizeof(bonus));
        if (bonus.client != client)
            continue;
        if (bonus.survive_id != config_id)
            continue;

        bonus.timer = null;
        g_aPlayerSurviveTimers.SetArray(i, bonus, sizeof(bonus));
    }

    bool cangetbonus = true;
    int team = GetClientTeam(client);
    if (!((team == CS_TEAM_CT && tempConfig.CT) || (team == CS_TEAM_T && tempConfig.T)))
        cangetbonus = false;
    if (!CheckAdminFlagsByString(client, tempConfig.Flags)) 
        cangetbonus = false;
    if (g_iPlayersOnline < tempConfig.MinPlayers)
        cangetbonus = false;
    if (g_iPlayersOnline > tempConfig.MaxPlayers)
        cangetbonus = false;
    if (playerLevel[client] < tempConfig.MinLevel)
        cangetbonus = false;
    if (playerLevel[client] > tempConfig.MaxLevel)
        cangetbonus = false;
    
    if (cangetbonus)
    {
        CPrintToChat(client, "[Survive Time %s] Gained %i for surviving %i seconds in round", tempConfig.Unique, tempConfig.XP, tempConfig.time);
        setPlayerUnlocks(client, pUnlocks[client] + tempConfig.XP );
    }
    RemoveSurviveTimer(client, config_id);

    return Plugin_Stop;
}

void RemoveSurviveTimer(int client = -1, int config_id = -1)
{
    for (int i = 0; i < g_aPlayerSurviveTimers.Length; i++)
    {
        if (i == g_aPlayerSurviveTimers.Length)
            break; 

        PlayerSurviveBonus tempBonus;
        g_aPlayerSurviveTimers.GetArray(i, tempBonus, sizeof(tempBonus));

        if (client != tempBonus.client && client != -1)
            continue;
        if (tempBonus.survive_id != config_id && client != -1)
            continue;

        delete tempBonus.timer;
        g_aPlayerSurviveTimers.Erase(i--);

    }
}



void XPonHurt(int attacker, int victim, int damage)
{
    for (int i = 0; i < g_aExperienceDamage.Length; i++) {
        XPConfigDamage tempConfig;
        g_aExperienceDamage.GetArray(i, tempConfig, sizeof(tempConfig));
        int team = GetClientTeam(attacker);
        int team2 = GetClientTeam(victim);
        if (team == team2)
            continue;
        if (!((team == CS_TEAM_CT && tempConfig.CT) || (team == CS_TEAM_T && tempConfig.T)))
            continue;
        if (!CheckAdminFlagsByString(attacker, tempConfig.Flags)) 
            continue;
        if (playerLevel[attacker] < tempConfig.MinLevel)
            continue;
        if (playerLevel[attacker] > tempConfig.MaxLevel)
            continue;
        if (g_iPlayersOnline < tempConfig.MinPlayers)
            continue;
        if (g_iPlayersOnline > tempConfig.MaxPlayers)
            continue;   
        bool found = false;
        
        if (g_aPlayerRewardDamage.Length > 0) {
            for (int y = 0; y < g_aPlayerRewardDamage.Length; y++) {
                PlayerRewardDamage tempReward;
                g_aPlayerRewardDamage.GetArray(y, tempReward, sizeof(tempReward));
                if (tempReward.Client != attacker)
                    continue;
                if (!StrEqual(tempReward.Unique, tempConfig.Unique))
                    continue;
                found = true;
                // check xp
                tempReward.Damage += damage;
                while (tempReward.Damage >= tempConfig.Damage) {
                    tempReward.Damage -= tempConfig.Damage;
                    setPlayerUnlocks(attacker, pUnlocks[attacker] + tempConfig.XP );    
                    CPrintToChat(attacker, "[Damage#1 %s] Gained %i for making damage", tempConfig.Unique, tempConfig.XP);
                }
                g_aPlayerRewardDamage.SetArray(y, tempReward, sizeof(tempReward));
                break;
            }
        }
        if (found)
            continue;
        PlayerRewardDamage reward;
        strcopy(reward.Unique, sizeof(PlayerRewardDamage::Unique), tempConfig.Unique);
        reward.Damage = damage;
        reward.Client = attacker;
        reward.IsEvent = false;
        while (reward.Damage >= tempConfig.Damage) {
            reward.Damage -= tempConfig.Damage;
            setPlayerUnlocks(attacker, pUnlocks[attacker] + tempConfig.XP );
            CPrintToChat(attacker, "[Damage#2 %s] Gained %i for making damage", tempConfig.Unique, tempConfig.XP);
        }
        g_aPlayerRewardDamage.PushArray(reward, sizeof(reward)); 
    }
}

void RoundWinnerBonus(int winner)
{
    if (g_cEXP_WinRound.BoolValue && (winner == CS_TEAM_CT || winner == CS_TEAM_T))
    {
        for (int i = 0; i < g_aExperienceWin.Length; i++) {
            XPConfigWin tempConfig;
            g_aExperienceWin.GetArray(i, tempConfig, sizeof(tempConfig));
            for (int client = 1; client <= MaxClients; client++) 
            { 
                if (!UTIL_IsValidClient(client))
                    continue;
                int team = GetClientTeam(client);
                if (team != winner)
                    continue;
                if (!((team == CS_TEAM_CT && tempConfig.CT) || (team == CS_TEAM_T && tempConfig.T)))
                    continue;
                if (!CheckAdminFlagsByString(client, tempConfig.Flags)) 
                    continue;
                if (playerLevel[client] < tempConfig.MinLevel)
                    continue;
                if (playerLevel[client] > tempConfig.MaxLevel)
                    continue;
                if (g_iPlayersOnline < tempConfig.MinPlayers)
                    continue;
                if (g_iPlayersOnline > tempConfig.MaxPlayers)
                    continue;
                if (tempConfig.Alive && IsPlayerAlive(client))
                    continue;
                CPrintToChat(client, "[Round end %s] Gained %i for winning round", tempConfig.Unique, tempConfig.XP);
                setPlayerUnlocks(client, pUnlocks[client] + tempConfig.XP );
            }
        }
    }
}

void MostDamageBonus(int winner)
{
    if (g_cEXP_MostDamage.BoolValue && (winner == CS_TEAM_CT || winner == CS_TEAM_T))
    {
        for (int i = 0; i < g_aExperienceMostDamage.Length; i++) {
            XPConfigMostDamage tempConfig;
            g_aExperienceMostDamage.GetArray(i, tempConfig, sizeof(tempConfig));
            if (g_iPlayersOnline < tempConfig.MinPlayers)
                continue;
            if (g_iPlayersOnline > tempConfig.MaxPlayers)
                continue;
            int mvp = -1;
            int damage = 1;
            for (int client = 1; client <= MaxClients; client++) 
            { 
                if (!UTIL_IsValidClient(client))
                    continue;
                int team = GetClientTeam(client);
                if (!((team == CS_TEAM_CT && tempConfig.CT) || (team == CS_TEAM_T && tempConfig.T)))
                    continue;
                if (!CheckAdminFlagsByString(client, tempConfig.Flags)) 
                    continue;

                if (pDamageDone[client] > damage)
                {
                    damage = pDamageDone[client];
                    mvp = client;
                }
            }
            if (UTIL_IsValidClient(mvp)) {
                CPrintToChatAll("[Most damage %s] %N gained %i for most damage", tempConfig.Unique, mvp, tempConfig.XP);
                setPlayerUnlocks(mvp, pUnlocks[mvp] + tempConfig.XP );
            }
        }
    }
}

void HappyHourEndRound(int winner)
{
    if (g_aActiveHappyHours.Length > 0) 
    {
        for (int client = 1; client <= MaxClients; client++) 
        { 
            if (!UTIL_IsValidClient(client))
                continue;
            GiveHappyHourBonus(client, configWinRound, winner);
        }
    }
}

void ResetDamageNKills()
{
    for (int client = 1; client <= MaxClients; client++) 
    { 
        if (!UTIL_IsValidClient(client))
            continue;
        pDamageDone[client] = 0;
        pKillDone[client] = 0;
    }
}

void XPonKills(int attacker)
{
    if (g_cEXP_Kill.BoolValue && g_aExperienceKill.Length > 0)
    {
        for (int i = 0; i < g_aExperienceKill.Length; i++) {
            XPConfigKill tempConfig;
            g_aExperienceKill.GetArray(i, tempConfig, sizeof(tempConfig));
            int team = GetClientTeam(attacker);
            if (!((team == CS_TEAM_CT && tempConfig.CT) || (team == CS_TEAM_T && tempConfig.T)))
                continue;
            if (!CheckAdminFlagsByString(attacker, tempConfig.Flags)) 
                continue;
            if (playerLevel[attacker] < tempConfig.MinLevel)
                continue;
            if (playerLevel[attacker] > tempConfig.MaxLevel)
                continue;
            if (g_iPlayersOnline < tempConfig.MinPlayers)
                continue;
            if (g_iPlayersOnline > tempConfig.MaxPlayers)
                continue;
            CPrintToChat(attacker, "[Kill %s] Gained %i for killing", tempConfig.Unique, tempConfig.XP);
            setPlayerUnlocks(attacker, pUnlocks[attacker] + tempConfig.XP );
        }
    }
}

/*void DeathMultiKillLogic(int attacker)
{
    if (g_cEXP_MultiKill.BoolValue && g_aExperienceMulti.Length > 0)
    {
        int starters = 0; // Seek for all possible start up tiers
        int starters_id[MAX_MKILL_TIER];

        for (int i = 0; i < g_aExperienceMulti.Length; i++) 
        {
            XPConfigMulti tempConfig;
            g_aExperienceMulti.GetArray(i, tempConfig, sizeof(tempConfig));
            // check if had prev == not starter
            if (strlen(tempConfig.Prev_Unique) > 0)
                continue;
            int team = GetClientTeam(attacker);
            if (!((team == CS_TEAM_CT && tempConfig.CT) || (team == CS_TEAM_T && tempConfig.T)))
                continue;
            if (!CheckAdminFlagsByString(attacker, tempConfig.Flags)) 
                continue;
            //if (playerLevel[attacker] < tempConfig.MinLevel)
            //    continue;
            //if (playerLevel[attacker] > tempConfig.MaxLevel)
            //    continue;
            //if (g_iPlayersOnline < tempConfig.MinPlayers)
            //    continue;
            //if (g_iPlayersOnline > tempConfig.MaxPlayers)
            //    continue;
            starters_id[starters] = i;
            starters++;
        }
        if (starters > 0)
        {
            int running = 0;
            int running_id[MAX_MKILL_TIER]; // 10 tiers should be more than enough
            for (int w = 0; w < g_aPlayerMultiKillTimers.Length; w++) 
            {
                PlayerMultiKill tempConfig;
                g_aPlayerMultiKillTimers.GetArray(w, tempConfig, sizeof(tempConfig));
                if (tempConfig.client != attacker)
                    continue;
                // do more validation etc if team, if timers running, if not expired
                running_id[running] = w;
                running++;
            }
            // in this logic if running > 0 and some expired we should recheck expired ones i guess too?
            if (running == 0)
            {
                for (int e = 0; e < starters; e++)
                {
                    XPConfigMulti tempConfig;
                    g_aExperienceMulti.GetArray(starters_id[e], tempConfig, sizeof(tempConfig));
                    PlayerMultiKill multi_nr;
                    multi_nr.client = attacker;
                    multi_nr.kills = 1;
                    multi_nr.start_id = starters_id[e];
                    multi_nr.seeking_mkill = -1;
                    for (int o = 0; o < g_aExperienceMulti.Length; o++) 
                    {
                        XPConfigMulti tempMulti;
                        g_aExperienceMulti.GetArray(o, tempMulti, sizeof(tempMulti));
                        if (StrEqual(tempConfig.Unique, tempMulti.Prev_Unique, false))
                        {
                            multi_nr.seeking_mkill = o;
                            break;
                        }
                    }
                    if (tempConfig.Kills == 1)
                    {
                        CPrintToChat(attacker, "%N reached new starter", attacker);
                        multi_nr.current_mkill = starters_id[e];
                    }
                    else
                    {
                        CPrintToChat(attacker, "%N appending new starter", attacker);
                        multi_nr.current_mkill = -1;
                    }

                    DataPack dp_sound;
                    multi_nr.sound = CreateDataTimer(WAIT_AFTER_KILL, Timer_MultiSound, dp_sound, TIMER_FLAG_NO_MAPCHANGE);
                    dp_sound.WriteCell(GetClientSerial(attacker));
                    dp_sound.WriteCell(g_iTotalPMK);

                    multi_nr.nextsound = GetGameTime() + WAIT_AFTER_KILL;

                    DataPack dp_expire;
                    float expiration = float(tempConfig.ActiveSeconds);
                    multi_nr.expiration = CreateDataTimer(expiration, Timer_MultiExpire, dp_expire, TIMER_FLAG_NO_MAPCHANGE);
                    dp_expire.WriteCell(GetClientSerial(attacker));
                    dp_expire.WriteCell(g_iTotalPMK);

                    multi_nr.expires = GetGameTime() + expiration;
                    
                    g_aPlayerMultiKillTimers.PushArray(multi_nr, sizeof(multi_nr));
                    g_iTotalPMK++;
                }
            } else {
                for (int t = 0; t < running; t++)
                {
                    bool made_next = false;
                    PlayerMultiKill tempPMulti;
                    g_aPlayerMultiKillTimers.GetArray(running_id[t], tempPMulti, sizeof(tempPMulti));
                    tempPMulti.kills += 1;
                    XPConfigMulti nextmkill;
                    if (tempPMulti.seeking_mkill != -1)
                    {
                        g_aExperienceMulti.GetArray(tempPMulti.seeking_mkill, nextmkill, sizeof(nextmkill));
                        // change tier if enough kills
                        if (nextmkill.Kills >= tempPMulti.kills)
                        {
                            CPrintToChat(attacker, "%N reached new kill state", attacker);
                            made_next = true;
                            tempPMulti.seeking_mkill = -1;
                            for (int e = 0; e < g_aExperienceMulti.Length; e++) 
                            {
                                XPConfigMulti tempMulti;
                                g_aExperienceMulti.GetArray(e, tempMulti, sizeof(tempMulti));
                                if (StrEqual(nextmkill.Unique, tempMulti.Prev_Unique, false))
                                {
                                    tempPMulti.seeking_mkill = e;
                                    break;
                                }
                            }
                        }
                    }
                    // todo check tempPMulti.expires is expired
                    delete tempPMulti.expiration;
                    DataPack dp_expire;
                    tempPMulti.expiration = CreateDataTimer(WAIT_AFTER_KILL, Timer_MultiExpire, dp_expire, TIMER_FLAG_NO_MAPCHANGE);
                    dp_expire.WriteCell(GetClientSerial(attacker));
                    dp_expire.WriteCell(tempPMulti.unique);
                    g_aPlayerMultiKillTimers.SetArray(t, tempPMulti, sizeof(tempPMulti));
                    if (made_next)
                    {
                        CPrintToChat(attacker, "%N made to next tier", attacker);
                    }
                }
            }
        }
    }
}

public Action Timer_MultiExpire(Handle timer, DataPack pack)
{
    pack.Reset();
    int client = GetClientFromSerial(pack.ReadCell()); 
    int config_id = pack.ReadCell(); 

    if (g_aPlayerMultiKillTimers.Length == 0)
    {
        return Plugin_Stop;
    }

    RemoveMultiKill(client, config_id);
    CPrintToChat(client, "%N runned timer Timer_MultiExpire index %i", client, config_id);

    return Plugin_Continue;
}

public Action Timer_MultiSound(Handle timer, DataPack pack)
{
    pack.Reset();
    int client = GetClientFromSerial(pack.ReadCell()); 
    int config_id = pack.ReadCell();

    PlayerMultiKill passedMulti;
    bool found_passed = false;
    int index = -1;
    for (int x = 0; x < g_aPlayerMultiKillTimers.Length; x++) 
    {   
        g_aPlayerMultiKillTimers.GetArray(x, passedMulti, sizeof(passedMulti));
        if (config_id == passedMulti.unique)
        {
            found_passed = true;
            index = x;
            break;
        }
    }

    if (!found_passed)
        return Plugin_Stop;
    
    passedMulti.sound = null;
    g_aPlayerMultiKillTimers.SetArray(index, passedMulti, sizeof(passedMulti));

    // || g_aPlayerMultiKillTimers.Length == 0 || g_aExperienceMulti.Length == 0)

    if (!UTIL_IsValidAlive(client))
    {
        RemoveMultiKill(client, config_id);
        return Plugin_Stop;
    }

    //bool found = false;
    //PlayerMultiKill tempMulti;
    //for (int o = 0; o < g_aExperienceMulti.Length; o++) 
    //{   
    //    g_aExperienceMulti.GetArray(o, tempMulti, sizeof(tempMulti));
    //    if (StrEqual(tempConfig.Unique, tempMulti.Prev_Unique, false))
    //    {
    //        multi_nr.seeking_mkill = o;
    //        break;
    //    }
    //}
    CPrintToChat(client, "%N runned timer Timer_MultiSound index %i", client, config_id);
    
    return Plugin_Continue;

}

void RemoveMultiKill(int client = -1, int config_id = -1)
{
    for (int i = 0; i < g_aPlayerMultiKillTimers.Length; i++)
    {
        if (i == g_aPlayerMultiKillTimers.Length)
            break; 

        PlayerMultiKill tempMK;
        g_aPlayerMultiKillTimers.GetArray(i, tempMK, sizeof(tempMK));

        if (client != tempMK.client && client != -1)
            continue;
        if (tempMK.unique != config_id && config_id != -1)
            continue;

        delete tempMK.sound;
        delete tempMK.expiration;
        g_aPlayerMultiKillTimers.Erase(i--);

    }
}
*/