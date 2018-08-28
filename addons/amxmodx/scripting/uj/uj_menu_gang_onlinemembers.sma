#include <amxmodx>
#include <cstrike>
#include <fg_colorchat>
#include <uj_gangs>
#include <uj_menus>
#include <uj_playermenu>

new const PLUGIN_NAME[] = "UJ | Menu - Gang Online Members";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

new const MENU_NAME[] = "Online members";

#define MAX_PLAYERS 32

// Menu variables
new g_menuEntry
new g_menuMain

public plugin_init()
{
  register_plugin(PLUGIN_NAME, PLUGIN_VERS, PLUGIN_AUTH);

  // Register a menu entry
  g_menuEntry = uj_menus_register_entry(MENU_NAME)

  // The menu we will crowbardisplay in
  g_menuMain = uj_menus_get_menu_id("Gang Menu")
}

public uj_fw_menus_select_pre(playerID, menuID, entryID)
{
  // This is not our menu entry - do not block
  if (entryID != g_menuEntry) {
    return UJ_MENU_AVAILABLE;
  }

  // Do not show if it is not in this specific parent menu
  if (menuID != g_menuMain) {
    return UJ_MENU_DONT_SHOW;
  }
  
  // Only display menu to Terrorists
  if (cs_get_user_team(playerID) != CS_TEAM_T) {
    return UJ_MENU_DONT_SHOW;
  }

  // Only display to those in a gang
  new gangId = uj_gangs_get_gang(playerID);
  if (gangId == UJ_GANG_INVALID) {
    return UJ_MENU_DONT_SHOW;
  }

  return UJ_MENU_AVAILABLE;
}

public uj_fw_menus_select_post(playerID, menuID, entryID)
{
  // This is not our menu entry
  if (g_menuEntry != entryID)
    return;

  new gangID = uj_gangs_get_gang(playerID);
  new players[32];
  new playerCount = uj_gangs_get_online_members(gangID, players, sizeof(players));
  
  // After calling this, wait for a response by listening to uj_fw_playermenu_select_post()
  uj_playermenu_show_players(playerID, players, playerCount);
}

// Called after a player has selected a target
// Don't actually have to do anything here - this menu is only a visual
/*
public uj_fw_playermenu_player_select(pluginID, playerID, targetID)
{
  // Not intiated by us - don't continue;
  if (pluginID != g_pluginID) {
    return;
  }
}
*/
