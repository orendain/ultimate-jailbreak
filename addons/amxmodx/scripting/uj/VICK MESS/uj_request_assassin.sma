#include <amxmisc>
#include <amxmodx>
#include <fakemeta>
#include <fun>
#include <cstrike>
#include <uj_colorchat>
#include <uj_core>
#include <uj_menus>
#include <uj_requests>

new const PLUGIN_NAME[] = "[UJ] Request - Assassin";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

new const REQUEST_NAME[] = "Assassin";
new const REQUEST_OBJECTIVE[] = "Stealth is key";

//new g_iMaxPlayers;

// Request variables
new g_request;
new bool:g_requestEnabled;

// Menu variables
new g_menuLastRequests;

// Player variables
new g_playerID;
new g_targetID;


public plugin_precache()
{
// Register request
g_request = uj_requests_register(REQUEST_NAME, REQUEST_OBJECTIVE);
}

public plugin_init()
{
register_plugin(PLUGIN_NAME, PLUGIN_VERS, PLUGIN_AUTH);

// Find all valid menus to display this under
g_menuLastRequests = uj_menus_get_menu_id("Last Request");

//g_iMaxPlayers   = get_maxplayers(); 
}

public uj_fw_requests_select_pre(playerID, requestID, menuID)
{
// This is not our request - do not block
if (requestID != g_request) {
	return UJ_REQUEST_AVAILABLE;
}

// Only display if in the parent menu we recognize
if (menuID != g_menuLastRequests) {
	return UJ_REQUEST_DONT_SHOW;
}

// If we *can* show the menu, but it's already enabled,
// then have it be unavailable
if (g_requestEnabled) {
	return UJ_REQUEST_NOT_AVAILABLE;
}

return UJ_REQUEST_AVAILABLE;
}

public uj_fw_requests_select_post(playerID, targetID, requestID)
{
// This is not our request
if (requestID != g_request)
	return;
	
start_request(playerID, targetID);
}

start_request(playerID, targetID)
{
if(!g_requestEnabled) {
	g_requestEnabled = true;


	//prisoner
	uj_core_strip_weapons(playerID);
	set_pev(playerID, pev_health, 1.0);
	cs_set_user_armor(playerID, 100, CS_ARMOR_VESTHELM)
	give_item(playerID, "weapon_scout");
	cs_set_user_bpammo(playerID, CSW_SCOUT, 30);
	set_user_rendering(playerID, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 15);
	
	// guard
	
	set_pev(targetID, pev_health, 100.0);
	
	g_playerID = playerID;
	g_targetID = targetID;
}
}

public uj_fw_requests_end(requestID)
{
// If requestID refers to our request and our request is enabled
if(requestID == g_request && g_requestEnabled) {
	g_requestEnabled = false;
	
	uj_core_strip_weapons(g_playerID);
	uj_core_strip_weapons(g_targetID);
	
	set_user_gravity(g_playerID, 1.0);
	set_user_gravity(g_targetID, 1.0);
	
	uj_core_block_weapon_pickup(g_playerID, false);
	uj_core_block_weapon_pickup(g_targetID, false);
	
	}
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
