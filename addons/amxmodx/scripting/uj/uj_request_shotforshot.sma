#include <amxmodx>
#include <cstrike>
#include <fakemeta>
#include <fun>
#include <uj_colorchat>
#include <uj_core>
#include <uj_menus>
#include <uj_requests>

new const PLUGIN_NAME[] = "[UJ] Request - Shot For Shot";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

new const REQUEST_NAME[] = "Shot For Shot";
new const REQUEST_OBJECTIVE[] = "Oh yeah ... time to face-off!";

new const MENU_NAME[] = "Select a weapon";

// CS Player PData Offsets (win32)
new const OFFSET_CSMENUCODE = 205

// Request variables
new g_request;
new bool:g_requestEnabled;

// Menu variables
new g_menuLastRequests;

// Player variables
new g_playerID;
new g_targetID;
new g_shooterID;
//new g_weaponIndex;

new g_playerWeaponEntityID;
new g_targetWeaponEntityID;

new const g_weaponNames[][] =
{
  "Deagle",
  "AK47",
  "Scout",
  "M4A1",
  "AWP",
  "USP",
  "Bullpup",
  "Para",
  "Elites",
  "Galil",
  "Glock",
  "MAC10",
  "UMP45",
  "M3"
}

new const g_weaponValues[][][] =
{
  {"weapon_deagle", CSW_DEAGLE},
  {"weapon_ak47", CSW_AK47},
  {"weapon_scout", CSW_SCOUT},
  {"weapon_m4a1", CSW_M4A1},
  {"weapon_awp", CSW_AWP},
  {"weapon_usp", CSW_USP},
  {"weapon_aug", CSW_AUG},
  {"weapon_m249", CSW_M249},
  {"weapon_elite", CSW_ELITE},
  {"weapon_galil", CSW_GALIL},
  {"weapon_glock18", CSW_GLOCK18},
  {"weapon_mac10", CSW_MAC10},
  {"weapon_ump45", CSW_UMP45},
  {"weapon_m3", CSW_M3}
}

new g_fwdID;
new g_iMaxPlayers;
#define IsPlayer(%0)    ( 1 <= (%0) <= g_iMaxPlayers )

new g_iGunsEventsIdBitSum;

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

  new const szGunsEvents[][] = {
      "events/awp.sc", "events/g3sg1.sc", "events/ak47.sc", "events/scout.sc", "events/m249.sc",
      "events/m4a1.sc", "events/sg552.sc", "events/aug.sc", "events/sg550.sc", "events/m3.sc",
      "events/xm1014.sc", "events/usp.sc", "events/mac10.sc", "events/ump45.sc", "events/fiveseven.sc",
      "events/p90.sc", "events/deagle.sc", "events/p228.sc", "events/glock18.sc", "events/mp5n.sc",
      "events/tmp.sc", "events/elite_left.sc", "events/elite_right.sc", "events/galil.sc", "events/famas.sc"
  };
  for(new i; i<sizeof(szGunsEvents); i++) {
      g_iGunsEventsIdBitSum |= 1<<engfunc(EngFunc_PrecacheEvent, 1, szGunsEvents[i]);
  }
  
  g_iMaxPlayers = get_maxplayers();
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

  g_playerID = playerID;
  g_targetID = targetID;

  show_weapons_menu(playerID);
}

show_weapons_menu(playerID)
{
  // Title
  new menuID = menu_create(MENU_NAME, "menu_handler");
  
  // List all different weapons
  for (new i = 0; i < sizeof(g_weaponNames); ++i) {
    menu_additem(menuID, g_weaponNames[i]);
  }

  // Fix for AMXX custom menus
  set_pdata_int(playerID, OFFSET_CSMENUCODE, 0);
  menu_display(playerID, menuID, 0);
}

public menu_handler(playerID, menuID, entrySelected)
{
  // Menu was closed
  if (entrySelected == MENU_EXIT) {
    menu_destroy(menuID);
    return PLUGIN_HANDLED;
  }

  menu_destroy(menuID);
  start_request(playerID, entrySelected);
  
  return PLUGIN_HANDLED;
}

start_request(playerID, weaponIndex)
{
  if(!g_requestEnabled) {
    g_requestEnabled = true;
    g_fwdID = register_forward(FM_PlaybackEvent, "OnPlaybackEvent");

    // Strip weapons
    uj_core_strip_weapons(playerID);
    uj_core_strip_weapons(g_targetID);

    // Give armor
    cs_set_user_armor(playerID, 100, CS_ARMOR_VESTHELM);
    cs_set_user_armor(g_targetID, 100, CS_ARMOR_VESTHELM);

    // Give weapons
    g_playerWeaponEntityID = give_item(playerID, g_weaponValues[weaponIndex][0]);
    cs_set_weapon_ammo(g_playerWeaponEntityID, 1);
    g_targetWeaponEntityID = give_item(g_targetID, g_weaponValues[weaponIndex][0]);
    cs_set_weapon_ammo(g_targetWeaponEntityID, 0);

    // Set health
    set_pev(playerID, pev_health, 100.0);
    set_pev(g_targetID, pev_health, 100.0);
    // Give armor
    
    cs_set_user_armor(playerID, 100, CS_ARMOR_VESTHELM)
    cs_set_user_armor(g_targetID, 100, CS_ARMOR_VESTHELM)

    // Give the prisoner one bullet to start out with
    //g_shooterID = playerID;
    //cs_set_user_bpammo(g_shooterID, g_weaponValues[weaponIndex][1][0], 1);

    // Do not allow participants to pick up any guns
    //uj_core_block_weapon_pickup(playerID, true);
    //uj_core_block_weapon_pickup(targetID, true);

    g_shooterID = playerID;
    g_playerID = playerID;
    //g_weaponIndex = weaponIndex;
  }
}

public uj_fw_requests_end(requestID)
{
  // If requestID refers to our request and our request is enabled
  if(requestID == g_request && g_requestEnabled) {
    g_requestEnabled = false;
    unregister_forward(FM_PlaybackEvent, g_fwdID, 1);

    //uj_core_block_weapon_pickup(g_playerID, false);
    //uj_core_block_weapon_pickup(g_targetID, false);
  }
}

public OnPlaybackEvent(flags, id, eventid)
{
  //uj_colorchat_print(0, 1, "PRE - Shots fired by user #%i", g_shooterID);
  //uj_colorchat_print(0, 1, "PRE - playback ID is #%i", id);
  if (!g_requestEnabled || (g_shooterID != id)) {
    return FMRES_IGNORED;
  }

  //uj_colorchat_print(0, 1, "MID - Shots fired by user #%i", g_shooterID);
  
  if(IsPlayer(id) && g_iGunsEventsIdBitSum & (1<<eventid)){
    // Gun fired
    //uj_colorchat_print(0, 1, "INSIDE - Shots fired by user #%i", g_shooterID);
    g_shooterID = (g_shooterID == g_playerID) ? g_targetID : g_playerID;
    //cs_set_user_bpammo(g_shooterID, g_weaponValues[g_weaponIndex][1][0], 1);
    //cs_set_weapon_ammo(g_targetWeaponEntityID, 0);

    if (g_shooterID == g_playerID) {
      cs_set_weapon_ammo(g_playerWeaponEntityID, 1);
    }
    else if (g_shooterID == g_targetID) {
      cs_set_weapon_ammo(g_targetWeaponEntityID, 1);
    }
    return FMRES_HANDLED;
  }
  return FMRES_IGNORED;
}
