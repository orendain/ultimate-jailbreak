#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fun>
#include <uj_chargers>
#include <uj_core>
#include <uj_menus>
#include <uj_requests>

new const PLUGIN_NAME[] = "UJ | Request - Rambo";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

new const REQUEST_NAME[] = "Rambo";
new const REQUEST_OBJECTIVE[] = "One vs All!  Kill on sight!";

new const RAMBO_HEALTH[] = "250";
new const RAMBO_AMMO[] = "50";

// Request variables
new g_request;
new bool:g_requestEnabled;

// Menu variables
new g_menuLastRequests;

// Player variables
new g_playerID;

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

  g_healthCVar = register_cvar("uj_request_rambo_health", RAMBO_HEALTH);
  g_ammoPCVar = register_cvar("uj_request_rambo_ammo", RAMBO_AMMO);
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

  // Only display when 2+ guards are alive
  if (uj_core_get_live_guard_count() < 2) {
    return UJ_REQUEST_NOT_AVAILABLE;
  }

  // If we *can* show the menu, but it's already enabled,
  // then have it be unavailable
  if (g_requestEnabled) {
    return UJ_REQUEST_NOT_AVAILABLE;
  }

  // Set request as endless
  uj_requests_set_endless();

  return UJ_REQUEST_AVAILABLE;
}

public uj_fw_requests_select_post(playerID, targetID, requestID)
{
  // This is not our request
  if (requestID != g_request)
    return;

  start_request(playerID);
}

start_request(playerID)
{
  if(!g_requestEnabled) {
    g_requestEnabled = true;

    // Find health settings
    new Float:health = float(get_pcvar_num(g_healthCVar));

    // Set health and armor
    set_pev(playerID, pev_health, health);
    cs_set_user_armor(playerID, 100, CS_ARMOR_VESTHELM);
    
    // Give out weapons
    new ammoCount = get_pcvar_num(g_ammoPCVar);
    give_item(playerID, "weapon_m249");
    give_item(playerID, "weapon_galil");
    give_item(playerID, "weapon_xm1014");
    give_item(playerID, "weapon_deagle");
    cs_set_user_bpammo(playerID, CSW_M249, ammoCount);
    cs_set_user_bpammo(playerID, CSW_GALIL, ammoCount);
    cs_set_user_bpammo(playerID, CSW_XM1014, ammoCount);
    cs_set_user_bpammo(playerID, CSW_DEAGLE, ammoCount);

    uj_chargers_block_heal(0, true);
    uj_chargers_block_armor(0, true);

    g_playerID = playerID;
  }
}

public uj_fw_requests_end(requestID)
{
  // If requestID refers to our request and our request is enabled
  if(requestID == g_request && g_requestEnabled) {
    g_requestEnabled = false;

    uj_core_strip_weapons(g_playerID);

    uj_chargers_block_heal(0, false);
    uj_chargers_block_armor(0, false);
  }
}
