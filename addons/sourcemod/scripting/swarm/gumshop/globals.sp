#define GUM_ROOT_CATEGORY "ShopRoot"

enum struct ShopCategory {
    char Unique[GUM_MAX_CATEGORY_UNIQUE];
    char Name[GUM_MAX_CATEGORY_NAME_UNIQUE];
    char MotherCategory[GUM_MAX_CATEGORY_NAME_UNIQUE];
    ArrayList SubCategories;
}

enum struct ShopPlayerItem {
    int ID;
    int Client;
    int ItemID;
    char ItemUnique[GUM_MAX_ITEM_UNIQUE];
    int RebuyID;
    int Upgrades; // With those later
}

enum struct ShopPlayerRebuy {
    int ID;
    char SteamID[GUM_MAX_STEAMID]; // We do SteamID in case of reconnects
    int ItemID;
    char ItemUnique[GUM_MAX_ITEM_UNIQUE];
    int RebuyTimes;
    g_eItemBuy RebuyType;
    bool CanBuy() {
        if (this.RebuyType == itemBuyOnce)
            return false;
        if (this.RebuyType == itemBuyOnceMap)
            return false;
        if (this.RebuyType == itemBuyOnceRound)
            return false;
        if (this.RebuyType == itemRebuy) {
            return (this.RebuyTimes > 0 ? true : false);
        }
        return true;
    }
    bool Buy() {
        if (this.CanBuy()) {
            if (this.RebuyType == itemRebuy) {
                this.RebuyTimes--;
                return true;
            }
        }
        return false;
    }
}

enum struct ShopItem {
    int ID;
    char Unique[GUM_MAX_ITEM_UNIQUE];
    char UniqueCategory[GUM_MAX_CATEGORY_UNIQUE];
    char Name[GUM_MAX_ITEM_NAME];
    char Description[GUM_MAX_ITEM_DESC];
    int XPCost;
    int RBPointsCost;
    int EvoPointsCost;
    int NirvanaPointsCost;
    int LevelRequired;
    int RebornRequired;
    int EvolutionRequired;
    int NirvanaRequired;
    g_eItemKeep Keep;
    g_eItemBuy Rebuy;
    bool AdminFlagOnly;
    char AdminFlags[GUM_MAX_FLAGS];
    char AdminFlagDesc[GUM_MAX_FLAGS_DESC];
    int RebuyTimes; // If limited / map
    bool Upgradeable;
    ArrayList Upgrades;
}

enum struct ShopItemUpgrade {
    int ItemID;
    char ItemUnique[GUM_MAX_ITEM_UPGRADE_UNIQUE];
    int XPCost;
    int RBPointsCost;
    int EvoPointsCost;
    int NirvanaPointsCost;
    int LevelRequired;
    int RebornRequired;
    int EvolutionRequired;
    int NirvanaRequired;
}

ArrayList g_aCategories;
ArrayList g_aItems;
ArrayList g_aPlayerItems;
ArrayList g_aPlayerItemsRebuy; // we do not remove these after disconnect
int g_iRegisteredItems = 0;
int g_iRegisteredPlayerItems = 0;
int g_iRegisteredPlayerRebuy = 0;

// Forwards
Handle g_hForwardOnPreBuyItem;
Handle g_hForwardOnBuyItem;
Handle g_hForwardOnShopLoaded;

#define DEFAULT_XP_COST 0
#define DEFAULT_RB_P_COST 0
#define DEFAULT_EVO_P_COST 0
#define DEFAULT_NIRVANA_P_COST 0
#define DEFAULT_LEVEL_REQ 0
#define DEFAULT_REBORN_REQ 0
#define DEFAULT_EVO_REQ 0
#define DEFAULT_NIRVANA_REQ 0
#define DEFAULT_KEEP itemKeepRound
#define DEFAULT_REBUY itemBuyOnceRound
#define DEFAULT_REBUY_TIMES 0 // 0 - unlimited
#define DEFAULT_ADMFLAG_ONLY false
#define DEFAULT_ADMFLAGS ""
#define DEFAULT_ADMFLAG_DESC ""
#define DEFAULT_UPGRADEABLE false

Database conDatabase = null;