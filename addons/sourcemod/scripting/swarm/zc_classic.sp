#include <sourcemod>
#include <sdktools>
#include <zombiemod>

public Plugin myinfo =
{
    name = "Zombie Classic",
    author = "Zombie Swarm Contributors",
    description = "none",
    version = "1.0",
    url = "https://github.com/Prefix/zombieswarm"
};

public void OnPluginStart()
{
    // We are registering item
    ZombieClass(
        "Zombie Classic", // Class name
        "Default zombie class, has extra damage to humans.", // Class description
        "models/player/kuristaja/zombies/classic/classic", // Class model
        120, // Class base HP
        25.0, // Class Damage
        1.0, // Class Speed
        0.8, // Class Gravity
        false  // Is class excluded from normal rotation
    );
}