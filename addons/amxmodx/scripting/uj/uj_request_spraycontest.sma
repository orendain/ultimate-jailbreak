#include <amxmodx>
#include <cstrike>
#include <fakemeta>
#include <fun>
#include <fg_colorchat>
#include <uj_core>
#include <uj_menus>
#include <uj_requests>

new const PLUGIN_NAME[] = "UJ | Request - Spray Contest";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

new const REQUEST_NAME[] = "Spray Contest";
new const REQUEST_OBJECTIVE[] = "Graffiti on the walls, homie!";

new const LAVA_SPRAY_FREQUENCY[] = "10";

// Request variables
new g_request;
new bool:g_requestEnabled;

// Menu variables
new g_menuLastRequests;

// CVars
new g_sprayFrequencyPCVar;
new g_decalFrequencyPCVar;

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

  // CVars
  g_sprayFrequencyPCVar = register_cvar("uj_request_spraycontest_sprayfrequency", LAVA_SPRAY_FREQUENCY);
  g_decalFrequencyPCVar = get_cvar_pointer("decalfrequency");
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

  start_request();
}

start_request()
{
  if(!g_requestEnabled) {
    g_requestEnabled = true;
    new frequency = get_pcvar_num(g_sprayFrequencyPCVar);
    set_pcvar_num(g_decalFrequencyPCVar, frequency);
  }
}

public uj_fw_requests_end(requestID)
{
  // If requestID refers to our request and our request is enabled
  if(requestID == g_request && g_requestEnabled) {
    g_requestEnabled = false;
    set_pcvar_num(g_decalFrequencyPCVar, 60);
  }
}
