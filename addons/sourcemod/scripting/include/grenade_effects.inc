/** 
 * Called when a player is about to be freezed by a grenade 
 * 
 * @param client     The victim index 
 * @param attacker     The client index who threw the grenade 
 * @param duration    The freeze duration, set by reference  
 * @return        Plugin_Changed to apply new values, Plugin_Contninue to allow as is and >= Plugin_Handled to block 
 */ 
forward Action ZM_OnClientFreeze(int client, int attacker, float &duration); 

/** 
 * Called when a player has been freezed by a grenade 
 * 
 * @param client     The victim index 
 * @param attacker     The client index who threw the grenade 
 * @param duration    The freeze duration 
 * @noreturn 
 */ 
forward void ZM_OnClientFreezed(int client, int attacker, float duration); 

/** 
 * Called when a player is about to be ignited by a grenade 
 * 
 * @param client     The victim index 
 * @param attacker     The client index who threw the grenade 
 * @param duration    The ignite duration, set by reference  
 * @return        Plugin_Changed to apply new values, Plugin_Contninue to allow as is and >= Plugin_Handled to block 
 */ 
forward Action ZM_OnClientIgnite(int client, int attacker, float &duration); 

/** 
 * Called when a player has been ignited by a grenade 
 * 
 * @param client     The victim index 
 * @param attacker     The client index who threw the grenade 
 * @param duration    The freeze duration 
 * @noreturn 
 */ 
forward void ZM_OnClientIgnited(client, attacker, float duration);  

/** 
 * Called when a grenade will get his effect
 * 
 * @param client     Client that throw the grenade
 * @param grenade     Grenade index
 * @return        Plugin_Continue to allow as is and Plugin_Handled to block effect in the grenade
 */ 
forward Action ZM_OnGrenadeEffect(client, grenade); 