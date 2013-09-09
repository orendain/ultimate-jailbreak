#include <amxmodx>
#include <cstrike>
#include <uj_freedays>
#include <uj_menus>

new const PLUGIN_NAME[] = "[UJ] Menu - Special Days";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

new const MENU_NAME[] = "Special Days";

new g_menu
new g_menuEntry
new g_menuMain

public plugin_precache()
{
  // Register a menu
  g_menu = uj_menus_register_menu(MENU_NAME)
}

public plugin_init()
{
  register_plugin(PLUGIN_NAME, PLUGIN_VERS, PLUGIN_AUTH);

  // Register a menu entry
  g_menuEntry = uj_menus_register_entry(MENU_NAME)

  // Find the menus this should display under
  g_menuMain = uj_menus_get_menu_id("Main Menu")
}

public uj_fw_menus_select_pre(playerID, menuID, entryID)
{
  // This is not our item - do not block
  if (entryID != g_menuEntry)
    return UJ_MENU_AVAILABLE;

  // Do not show if it is not in this specific parent menu
  if (menuID != g_menuMain) {
    return UJ_MENU_DONT_SHOW;
  }

  // Only display to Counter Terrorists
  if (cs_get_user_team(playerID) != CS_TEAM_CT) {
    return UJ_MENU_DONT_SHOW;
  }

  // If someone has a freeday, disable this menu entry
  if (uj_freedays_get_count() > 0) {
    return UJ_MENU_NOT_AVAILABLE;
  }

  if (!is_user_alive(playerID)) {
    return UJ_MENU_NOT_AVAILABLE;
  }

  return UJ_MENU_AVAILABLE;
}

public uj_fw_menus_select_post(playerID, menuID, entryID)
{
  // This is not our menu item
  if (g_menuEntry != entryID)
    return;
  
  // Now open up our own menu
  uj_menus_show_menu(playerID, g_menu);
}
