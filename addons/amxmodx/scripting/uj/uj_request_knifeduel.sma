#include <amxmodx>
#include <cstrike>
#include <fakemeta>
#include <fun>
#include <uj_colorchat>
#include <uj_core>
#include <uj_menus>
#include <uj_requests>

new const PLUGIN_NAME[] = "[UJ] Request - Knife Duel";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

new const REQUEST_NAME[] = "Knife Duel";
new const REQUEST_OBJECTIVE[] = "Come at me, bro!";

// Request variables
new g_request;
new bool:g_requestEnabled;

// Menu variables
new g_menuLastRequests;

public plugin_precache()
{
  // Register request
  g_request = uj_requests_register(REQUEST_NAME, REQUEST_OBJECTIVE)
}

public plugin_init()
{
  register_plugin(PLUGIN_NAME, PLUGIN_VERS, PLUGIN_AUTH);

  // Find all valid menus to display this under
  g_menuLastRequests = uj_menus_get_menu_id("Last Request")
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
  if (!g_requestEnabled) {
    // Strip users of weapons, and give out knives
    uj_core_strip_weapons(playerID);
    uj_core_strip_weapons(targetID);

    // Set health
    set_pev(playerID, pev_health, 100.0);
    set_pev(targetID, pev_health, 100.0);

    // Give armor
    cs_set_user_armor(playerID, 100, CS_ARMOR_VESTHELM)
    cs_set_user_armor(targetID, 100, CS_ARMOR_VESTHELM)

    g_requestEnabled = true;
  }
}

public uj_fw_requests_end(requestID)
{
  // If requestID refers to our request and our request is enabled
  if(requestID == g_request && g_requestEnabled) {
    g_requestEnabled = false;
  }
}
