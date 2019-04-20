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

ZombieClass registeredClass;

public void OnPluginStart()
{
    // We are registering zombie
    registeredClass = ZombieClass();
    registeredClass.SetName("Zombie Classic", MAX_CLASS_NAME_SIZE);
    registeredClass.GetDesc("Default zombie class, has extra damage to humans.", MAX_CLASS_DESC_SIZE);
    registeredClass.SetModel("models/player/kuristaja/zombies/classic/classic", MAX_CLASS_MODEL_SIZE);
    registeredClass.Health = 120;
    registeredClass.Damage = 25.0;
    registeredClass.Speed = 1.0;
    registeredClass.Gravity = 0.8;
    registeredClass.Excluded = false;
}