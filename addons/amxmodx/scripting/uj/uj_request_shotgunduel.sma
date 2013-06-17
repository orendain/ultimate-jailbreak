#include <amxmodx>
#include <cstrike>
#include <fakemeta>
#include <fun>
#include <uj_colorchat>
#include <uj_core>
#include <uj_menus>
#include <uj_requests>

new const PLUGIN_NAME[] = "[UJ] Request - Shotgun Duel";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

new const REQUEST_NAME[] = "Shotgun Duel";
new const REQUEST_OBJECTIVE[] = "Here come the boomsticks!";

new const SHOTGUNDUAL_HEALTH[] = "300";
new const SHOTGUNDUAL_AMMO[] = "50";

// Request variables
new g_request;
new bool:g_requestEnabled;

// Menu variables
new g_menuLastRequests;

// Player variables
new g_playerID;
new g_targetID;

// CVar variables
new g_healthCVar;
new g_ammoPCVar;

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

  g_healthCVar = register_cvar("uj_request_shotgunduel_health", SHOTGUNDUAL_HEALTH);

  g_ammoPCVar = register_cvar("uj_request_shotgunduel_ammo", SHOTGUNDUAL_AMMO);
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

    new ammoCount = get_pcvar_num(g_ammoPCVar);
    
    // Strip users of weapons, and give out scourts and knives
    uj_core_strip_weapons(playerID);
    uj_core_strip_weapons(targetID);
    give_item(playerID, "weapon_m3");
    give_item(targetID, "weapon_m3");
    cs_set_user_bpammo(playerID, CSW_M3, ammoCount);
    cs_set_user_bpammo(targetID, CSW_M3, ammoCount);

    // Do not allow participants to pick up any guns
    uj_core_set_weapon_pickup(playerID, true);
    uj_core_set_weapon_pickup(targetID, true);

    // Find health settings
    new health = get_pcvar_num(g_healthCVar);

    // Set health
    set_pev(playerID, pev_health, 100.0);
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

    uj_core_set_weapon_pickup(g_playerID, false);
    uj_core_set_weapon_pickup(g_targetID, false);
  }
}
