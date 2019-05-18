#if defined _zombieswarm_utils_included
  #endinput
#endif
#define _zombieswarm_utils_included


stock Util_Fade(int client, int duration = 5, int hold = 300, int color[4]= {0, 0, 0, 255}) {
	Protobuf Fade = view_as<Protobuf>(StartMessageOne("Fade", client));
	
	if(Fade != null) {
		// Write shake information to message handle
		Fade.SetInt("duration", RoundToNearest(duration * 1000.0)); 
		Fade.SetInt("hold_time", RoundToNearest(hold * 1000.0)); 
		Fade.SetInt("flags", 0x0009); 
		Fade.SetColor("clr", color); 

		// End usermsg and send to the client
		EndMessage();
	}
} 
stock void Util_ShakeScreen(int client, float duration = 3.0, float amplitude = 2.0, float freq = 1.0) {
    // Create message
    Protobuf Shake = view_as<Protobuf>(StartMessageOne("Shake", client));

    // Validate message
    if(Shake != null) {
        // Write shake information to message handle
        Shake.SetInt("command", 0);
        Shake.SetFloat("local_amplitude", amplitude);
        Shake.SetFloat("frequency", freq);
        Shake.SetFloat("duration", duration);

        // End usermsg and send to the client
        EndMessage();
    }
}
stock void Util_PlaySoundToClient(int client, char[] sound, float volume = 0.8) {
	ClientCommand(client, "playgamesound Music.StopAllMusic");
	ClientCommand(client, "play */%s", sound);
	EmitSoundToClient(client, sound, -2, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SND_NOFLAGS, volume);
}
