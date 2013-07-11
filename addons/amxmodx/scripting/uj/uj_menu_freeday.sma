#include <amxmodx>
#include <cstrike>
#include <uj_colorchat>
#include <uj_core>
#include <uj_freedays>
#include <uj_logs>
#include <uj_menus>
#include <uj_playermenu>

new const PLUGIN_NAME[] = "[UJ] Menu - Freeday";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

new const MENU_NAME[] = "Freedays";

new const MENU_ENTRY_GIVE_FREEDAY[] = "Give a Freeday"
new const MENU_ENTRY_REMOVE_FREEDAYS[] = "Remove all Freedays"

new g_menu
new g_menuFreedayEntry
new g_menuFreedayGiveEntry
new g_menuFreedayRemoveEntry
new g_menuMain

new g_pluginID;

public plugin_precache()
{
  // Register this menu
  g_menu = uj_menus_register_menu(MENU_NAME);
}

public plugin_init()
{
  g_pluginID = register_plugin(PLUGIN_NAME, PLUGIN_VERS, PLUGIN_AUTH);

  // Register menu entries
  g_menuFreedayEntry = uj_menus_register_entry(MENU_NAME);
  g_menuFreedayGiveEntry = uj_menus_register_entry(MENU_ENTRY_GIVE_FREEDAY);
  g_menuFreedayRemoveEntry = uj_menus_register_entry(MENU_ENTRY_REMOVE_FREEDAYS);

  // Retrieve the menus this will display under
  g_menuMain = uj_menus_get_menu_id("Main Menu");
}

public uj_fw_menus_select_pre(playerID, menuID, entryID)
{
  // This is not our menu entry - do not block
  if (entryID != g_menuFreedayEntry &&
      entryID != g_menuFreedayGiveEntry &&
      entryID != g_menuFreedayRemoveEntry) {
    return UJ_MENU_AVAILABLE;
  }
  
  // Only display to Counter Terrorists
  if (cs_get_user_team(playerID) != CS_TEAM_CT) {
    return UJ_MENU_DONT_SHOW;
  }

  // Do not show if it not in the correct parent menu
  if (entryID == g_menuFreedayEntry && menuID != g_menuMain) {
    return UJ_MENU_DONT_SHOW;
  }
  else if (entryID == g_menuFreedayGiveEntry && menuID != g_menu) {
    return UJ_MENU_DONT_SHOW;
  }
  else if (entryID == g_menuFreedayRemoveEntry && menuID != g_menu) {
    return UJ_MENU_DONT_SHOW;
  }

  return UJ_MENU_AVAILABLE;
}

public uj_fw_menus_select_post(playerID, menuID, entryID)
{
  // This is not our menu entry -- skip
  if (entryID != g_menuFreedayEntry &&
      entryID != g_menuFreedayGiveEntry &&
      entryID != g_menuFreedayRemoveEntry) {
    return;
  }

  if (entryID == g_menuFreedayEntry) {
    uj_menus_show_menu(playerID, g_menu);
  }
  else if (entryID == g_menuFreedayGiveEntry) {
    show_freeday_menu(playerID);
  }
  else if (entryID == g_menuFreedayRemoveEntry) {
    uj_freedays_remove(0);
  }
}

show_freeday_menu(playerID)
{
  // Alive T's only
  //new flags[] = "ae";
  //new team[] = "TERRORIST";

  // After calling this, wait for a response by listening to uj_fw_playermenu_select_post()
  //uj_playermenu_show_team_players(playerID, flags, team);

  new players[32];
  new playerCount = uj_core_get_players(players, true, CS_TEAM_T);
  uj_playermenu_show_players(playerID, players, playerCount);
}

// Called after a player has selected a target
public uj_fw_playermenu_player_select(pluginID, playerID, targetID)
{
  // Not intiated by us - don't continue;
  if (pluginID != g_pluginID) {
    return;
  }

  uj_freedays_give(targetID);

  // Find names and display message
  new playerName[32], targetName[32];
  get_user_name(playerID, playerName, charsmax(playerName));
  get_user_name(targetID, targetName, charsmax(targetName));

  uj_colorchat_print(0, playerID, "^3%s^1 has given ^3%s^1 a sweet, sweet ^4Freeday^1!", playerName, targetName)
  uj_logs_log("[uj_menu_freeday] %s has given %s a freeday", playerName, targetName);

  // Display menu again
  show_freeday_menu(playerID);
}
