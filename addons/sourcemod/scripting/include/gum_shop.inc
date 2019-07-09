#if defined _gum_shop_included_
  #endinput
#endif
#define _gum_shop_included_

// Category
#define GUM_MAX_CATEGORY_NAME_UNIQUE 32
#define GUM_MAX_SUB_CATEGORIES 64
#define GUM_MAX_CATEGORY_UNIQUE 32
#define GUM_MAX_FLAGS 21
#define GUM_MAX_FLAGS_DESC 32
// Max items
#define GUM_MAX_ITEM_UNIQUE 16
#define GUM_MAX_ITEM_NAME 32
#define GUM_MAX_ITEM_DESC 64
#define GUM_MAX_STEAMID 32
// UPGRADES
#define GUM_MAX_ITEM_UPGRADE_UNIQUE 16
// No need to rebuy (saved on sql)
#define GUM_NO_REBUY -1
// No need to rebuy whole map
#define GUM_
#define GUM_NO_REBUY_ROUND -3
#define GUM_NO_REBUY_MAP -2
#define GUM_NO_UPGRADES -1

// Fowards
forward void GUMShop_OnLoaded();

// Return Plugin_Stop to disable buying it.
forward Action GUMShop_OnPreBuyItem(int client, int item);
// Return Plugin_Stop on 3rd party plugins when buying to enable buying.
forward Action GUMShop_OnBuyItem(int client, int item);

enum g_eItemBuy {
    itemBuyOnce,
    itemBuyOnceMap,
    itemBuyOnceRound,
    itemBuyUnlimited, // keep = none only?
    itemRebuy
}

enum g_eItemKeep {
    itemKeepNone, // doesnt even add to item list, just rebuy if needed
    itemKeepRound, // default
    itemKeepAlways // map or always
}

methodmap GumItem {
    // Constructor
    public native GumItem(const char[] unique, const char[] uniquecategory, const char[] Name, const char[] Description);
    // Properties
    property int ID {
        public native get();
    }
    property int XPCost {
        public native get();
        public native set(const int val);
    }
    property int RBPointsCost {
        public native get();
        public native set(const int val);
    }
    property int EvoPointsCost {
        public native get();
        public native set(const int val);
    }
    property int NirvanaPointsCost {
        public native get();
        public native set(const int val);
    }
    property int LevelRequired {
        public native get();
        public native set(const int val);
    }
    property int RebornRequired {
        public native get();
        public native set(const int val);
    }
    property int EvolutionRequired {
        public native get();
        public native set(const int val);
    }
    property int NirvanaRequired {
        public native get();
        public native set(const int val);
    }
    property g_eItemBuy Rebuy {
        public native get();
        public native set(const g_eItemBuy val);
    }
    property g_eItemKeep Keep {
        public native get();
        public native set(const g_eItemKeep val);
    }
    // If Rebuy = itemRebuy
    property int RebuyTimes {
        public native get();
        public native set(const int val);
    }
    property bool AdminFlagOnly {
        public native get();
        public native set(const bool val);
    }
    property bool Upgradeable {
        public native get();
        public native set(const bool val);
    }
    // Methods
    public native void GetName(char[] text, int size);
    public native void SetName(const char[] text, int size);
    public native void GetDesc(char[] text, int size);
    public native void SetDesc(const char[] text, int size);
    public native void GetAdminFlags(char[] text, int size);
    public native void SetAdminFlags(const char[] text, int size);
    public native void GetAdminFlagsDesc(char[] text, int size);
    public native void SetAdminFlagsDesc(const char[] text, int size);
    public native void GetUnique(char[] text, int size);
    public native void GetUniqueCategory(char[] text, int size);
}