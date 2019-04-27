#if defined _zombieswarm_utils_included
  #endinput
#endif
#define _zombieswarm_utils_included

ZS_ShowOverlayToClient(client, const String:overlaypath[]) {
	ClientCommand(client, "r_screenoverlay \"%s\"", overlaypath);
}

ZS_ShowOverlayToAll(const String:overlaypath[]) {
	for (int client = 1; client <= MaxClients; client++) {
		if (IsClientInGame(client) && !IsFakeClient(client)) {
			ZS_ShowOverlayToClient(client, overlaypath);
		}
	}
}