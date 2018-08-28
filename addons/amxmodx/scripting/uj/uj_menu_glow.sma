#include <amxmodx>
#include <fakemeta>
#include <cstrike>
#include <fg_colorchat>
#include <uj_effects>
#include <uj_menus>

new const PLUGIN_NAME[] = "UJ | Menu - Glow";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

new const MENU_NAME[] = "Glow";

new const GLOW_COLORS[][][] =
{
  {"Red", 255, 0, 0, 16},
  {"Green", 0, 255, 0, 16},
  {"Blue", 0, 0, 255, 16},
  {"Orange", 255, 63, 0, 16},
  {"Pink", 255, 152, 144, 16},
  {"Brown", 102, 83, 0, 16}
};

// CS Player PData Offsets (win32)
new const OFFSET_CSMENUCODE = 205;

new g_menuEntry;
new g_mainMain;

public plugin_init()
{
  register_plugin(PLUGIN_NAME, PLUGIN_VERS, PLUGIN_AUTH);

  // Now register this menu as an item of the main menu
  g_mainMain = uj_menus_get_menu_id("Main Menu");
  g_menuEntry = uj_menus_register_entry(MENU_NAME);
}

public uj_fw_menus_select_pre(playerID, menuID, entryID)
{
  // This is not our item - do not block
  if (entryID != g_menuEntry)
    return UJ_MENU_AVAILABLE;
  
  // Only display to Counter Terrorists
  if (cs_get_user_team(playerID) != CS_TEAM_CT) {
    return UJ_MENU_DONT_SHOW;
  }

  // Do not show if it is not in this specific parent menu
  if (menuID != g_mainMain) {
    return UJ_MENU_DONT_SHOW;
  }

  if (!is_user_alive(playerID)) {
    return UJ_MENU_NOT_AVAILABLE;
  }
  
  return UJ_MENU_AVAILABLE;
}

public uj_fw_menus_select_post(playerID, menuID, entryID)
{
  // This is not our item
  if (g_menuEntry != entryID)
    return;
  
  // Now open up our own menu
  display_glow_menu(playerID);
}

// Display menu
display_glow_menu(playerID)
{
  //new colorName[32], red, green, blue, alpha;
  
  // Title
  new menuID = menu_create(MENU_NAME, "menu_handler");
  
  // First item on the list
  menu_additem(menuID, "Remove glow");

  // List all different colors
  for (new i = 0; i < sizeof(GLOW_COLORS); ++i) {
    
    // Retrieve color name and RGBA values
    //copy(colorName, charsmax(colorName), GLOW_COLORS[i][0]);
    /*red = GLOW_COLORS[i][1];
    green = GLOW_COLORS[i][2];
    blue = GLOW_COLORS[i][3];
    alpha = GLOW_COLORS[i][4];
    
    new data[5];
    data[0] = red + OFFSET_MENUDATA;
    data[1] = green + OFFSET_MENUDATA;
    data[2] = blue + OFFSET_MENUDATA;
    data[3] = alpha + OFFSET_MENUDATA;
    data[4] = 0;*/
    menu_additem(menuID, GLOW_COLORS[i][0]);
  }

  // Fix for AMXX custom menus
  set_pdata_int(playerID, OFFSET_CSMENUCODE, 0);
  menu_display(playerID, menuID, 0);
}

// Items Menu
public menu_handler(playerID, menuID, entrySelected)
{
  // Menu was closed
  if (entrySelected == MENU_EXIT) {
    menu_destroy(menuID)
    return PLUGIN_HANDLED;
  }
  
/*  // Retrieve menu entry information
  new data[5], dummy;
  menu_item_getinfo(menuID, entrySelected, dummy, data, charsmax(data), _, _, dummy)
  new red = data[0] - OFFSET_MENUDATA;
  new green = data[1] - OFFSET_MENUDATA;
  new blue = data[2] - OFFSET_MENUDATA;
  new alpha = data[3] - OFFSET_MENUDATA;
*/
  // Now find the target the player was pointing at
  new targetID = get_aimed_entity(playerID);

  // Only process if the target is a player
  if(!pev_valid(targetID)) {
    return PLUGIN_HANDLED;
  }
  
  new szTempClass[64];
  pev(targetID, pev_classname, szTempClass, 63);
  if(!equali(szTempClass, "player", 0)) {
    return PLUGIN_HANDLED;
  }

  if (cs_get_user_team(targetID) != CS_TEAM_T) {
    return PLUGIN_HANDLED;
  }

  // Find player and target names
  new playerName[32], targetName[32];
  get_user_name(playerID, playerName, charsmax(playerName));
  get_user_name(targetID, targetName, charsmax(targetName));
  
  // First item on the list - unglow
  if (entrySelected == 0) {
    uj_effects_glow_reset(targetID);
    fg_colorchat_print(0, playerID, "^3%s^1 has removed the glow from ^3%s^1!", playerName, targetName);
  }
  else {
    // If they didn't select the first entry (unglow),
    // Then entrySelected is now the color's index
    entrySelected--;

    // Retrieve glow information
    new red = GLOW_COLORS[entrySelected][1][0];
    new green = GLOW_COLORS[entrySelected][2][0];
    new blue = GLOW_COLORS[entrySelected][3][0];
    new alpha = GLOW_COLORS[entrySelected][4][0];

    uj_effects_glow_player(targetID, red, green, blue, alpha);
    fg_colorchat_print(0, playerID, "^3%s^1 has made ^3%s^1 glow ^4%s^1!", playerName, targetName, GLOW_COLORS[entrySelected][0]);
  }

  // Only destroy when the user exits on their own.
  // As such, comment this out.
  //menu_destroy(menuID);

  // Bring the glow menu up again
  menu_display(playerID, menuID, 0);

  return PLUGIN_HANDLED;
}

/*
 * Helper functions
 */
get_aimed_entity(playerID)
{
  static Float:start[3], Float:view_ofs[3], Float:dest[3], i;
  
  pev(playerID, pev_origin, start);
  pev(playerID, pev_view_ofs, view_ofs);
  
  for( i = 0; i < 3; i++ ) {
    start[i] += view_ofs[i];
  }
  
  pev(playerID, pev_v_angle, dest);
  engfunc(EngFunc_MakeVectors, dest);
  global_get(glb_v_forward, dest);
  
  for( i = 0; i < 3; i++ ) {
    dest[i] *= 9999.0;
    dest[i] += start[i];
  }

  engfunc(EngFunc_TraceLine, start, dest, DONT_IGNORE_MONSTERS, playerID, 0);

  return get_tr2(0, TR_pHit);
}
