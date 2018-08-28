#include <amxmodx>
#include <cstrike>
#include <engine>
#include <fakemeta>
#include <fun>
#include <hamsandwich>
#include <fg_colorchat>
#include <uj_core>
#include <uj_effects>
#include <uj_menus>
#include <uj_requests>

new const PLUGIN_NAME[] = "UJ | Request - Gun Toss";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

new const REQUEST_NAME[] = "Gun Toss";
new const REQUEST_OBJECTIVE[] = "Guns are really dangerous to throw...";

// Request variables
new g_request;
new bool:g_requestEnabled;
new g_playerID;
new g_targetID;

// Menu variables
new g_menuLastRequests;

// Trail necessities
new g_iTrailSprite;

public plugin_precache()
{
  g_iTrailSprite = precache_model("sprites/ultimate_jailbreak/aeroblast.spr");
}

public plugin_init()
{
  register_plugin(PLUGIN_NAME, PLUGIN_VERS, PLUGIN_AUTH);

  // Find all valid menus to display this under
  g_menuLastRequests = uj_menus_get_menu_id("Last Request");

  // Register request
  g_request = uj_requests_register(REQUEST_NAME, REQUEST_OBJECTIVE);

  // To glow the thrown nades
  register_forward(FM_SetModel,"Fwd_Model_Think");
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

  // Have user choose the weapon
  // -- That goes here --

  start_request(playerID, targetID);
}

start_request(playerID, targetID)
{
  if (!g_requestEnabled) {
    // Strip users of weapons
    uj_core_strip_weapons(playerID);
    uj_core_strip_weapons(targetID);

    new weapEnt = give_item(playerID, "weapon_deagle");
    cs_set_weapon_ammo(weapEnt, 0);
    weapEnt = give_item(targetID, "weapon_deagle");
    cs_set_weapon_ammo(weapEnt, 0);

    g_playerID = playerID;
    g_targetID = targetID;
    g_requestEnabled = true;
  }
}

public uj_fw_requests_end(requestID)
{
  // If requestID refers to our request and our request is enabled
  if(g_requestEnabled && requestID == g_request) {
    g_requestEnabled = false;
  }
}

public Fwd_Model_Think(ent, const model[])
{
  if(g_requestEnabled) {

    if(!pev_valid(ent)) {
      return FMRES_IGNORED;
    }
      
    static playerID;
    playerID = pev(ent, pev_owner);

    if(playerID != g_playerID && playerID != g_targetID) {
      return FMRES_IGNORED;
    }

    static red; red = 0;
    static blue; blue = 0;

    switch (cs_get_user_team(playerID))
    {
      case CS_TEAM_T:
        red = 255;
      case CS_TEAM_CT:
        blue = 255;
    }
      
    set_rendering(ent,kRenderFxGlowShell, red, 0, blue, kRenderNormal, 16);
        
    message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
    write_byte(TE_BEAMFOLLOW);
    write_short(ent);
    write_short(g_iTrailSprite);
    write_byte(15);
    write_byte(1);
    write_byte(red);
    write_byte(0);
    write_byte(blue);
    write_byte(191);
    message_end();
  }

  return FMRES_IGNORED;
}