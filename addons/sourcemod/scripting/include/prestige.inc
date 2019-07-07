#if defined _prestige_included_
  #endinput
#endif
#define _prestige_included_

forward void Prestige_OnReborn(int client);
forward void Prestige_OnEvolution(int client);
forward void Prestige_OnNirvana(int client);

methodmap PrestigePlayer {
    // Constructor
    public native PrestigePlayer(int client);
    // Properties
    property int Client {
        public native get();
    }
    property int MaxLevel {
        public native get();
    }
    property int MaxReborns {
        public native get();
    }
    property int MaxEvolutions {
        public native get();
    }
    property int Level {
        public native get();
        public native set(const int val);
    }
    property int Reborn {
        public native get();
        public native set(const int val);
    }
    property int Evolution {
        public native get();
        public native set(const int val);
    }
    property int Nirvana {
        public native get();
        public native set(const int val);
    }
    property int RebornPoints {
        public native get();
        public native set(const int val);
    }
    property int EvolutionPoints {
        public native get();
        public native set(const int val);
    }
    property int NirvanaPoints {
        public native get();
        public native set(const int val);
    }
    property int TotalReborns {
        public native get();
    }
    // Methods
    public native bool DoesMeetRequirements(const int level = 0, int rb = 0, int evo = 0, int nirvana = 0);
}