#define MENU_DISPLAY_TIME 20
#define MAX_HINT_SIZE 512
#define HIDEHUD_RADAR 1 << 12
#define EF_NOSHADOW                 (1 << 4)
#define EF_NORECEIVESHADOW          (1 << 6)
#define TIMER_SPEED 1.0
#define MAX_SOUNDS 64
// Default for zm class
#define DEFAULT_ZM_NAME "Unnamed Zombie"
#define DEFAULT_ZM_DESC "This zombie needs more information"
#define DEFAULT_ZM_MODEL_PATH "models/player/kuristaja/zombies/classic/classic"
#define DEFAULT_ZM_ARMS_PATH ""
#define DEFAULT_ZM_HEALTH 100
#define DEFAULT_ZM_DAMAGE 20.0
#define DEFAULT_ZM_SPEED 1.0
#define DEFAULT_ZM_ATTACKSPEED 1.0
#define DEFAULT_ZM_GRAVITY 1.0
#define DEFAULT_ZM_EXCLUDED false
#define DEFAULT_ZM_ABILITY_BUTTON IN_BULLRUSH // use unused one
#define DEFAULT_ZM_COOLDOWN 5.0
#define DEFAULT_ARMS "models/weapons/ct_arms_gign.mdl"
// Default for Zombie ability
#define DEFAULT_ABILITY_NAME "Unnamed Ability"
#define DEFAULT_ABILITY_DESC "This ability needs a description"
#define DEFAULT_ABILITY_DURATION 5.0
#define DEFAULT_ABILITY_COOLDOWN 5.0
#define DEFAULT_ABILITY_BUTTONS 0
#define DEFAULT_ABILITY_EXCLUDED false

#define TRANSLATION_CLASS_FILE "zombieswarm_class_%s.phrases"
#define TRANSLATION_CLASS_DISPLAY "Zombie Class [%s] Display Name"
#define TRANSLATION_CLASS_DESC "Zombie Class [%s] Description"

#define TRANSLATION_ABILITY_FILE "zombieswarm_ability_%s.phrases"
#define TRANSLATION_ABILITY_DISPLAY "Zombie Ability [%s] Display Name"
#define TRANSLATION_ABILITY_DESC "Zombie Ability [%s] Description"