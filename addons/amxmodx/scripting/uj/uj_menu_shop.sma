#include <amxmodx>
#include <cstrike>
#include <uj_menus>

new const PLUGIN_NAME[] = "[UJ] Menu - Shop";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

new const MENU_NAME[] = "Shop Menu";

new g_menu
new g_menuEntry
new g_menuParent

public plugin_init()
{
  register_plugin(PLUGIN_NAME, PLUGIN_VERS, PLUGIN_AUTH);

  // Register a main menu
  g_menu = uj_menus_register_menu(MENU_NAME)

  // Now register this menu as an item of the main menu
  g_menuParent = uj_menus_get_menu_id("Main Menu")
  g_menuEntry = uj_menus_register_entry(MENU_NAME)
}

public uj_fw_menus_select_pre(playerID, menuID, entryID)
{
  // This is not our menu entry - do not block
  if (entryID != g_menuEntry)
    return UJ_MENU_AVAILABLE;
  
  // Only display to Terrorists
  if (cs_get_user_team(playerID) != CS_TEAM_T)
    return UJ_MENU_DONT_SHOW;

  // Do not show if it is not in this specific parent menu
  if (menuID != g_menuParent)
    return UJ_MENU_DONT_SHOW;
  
  return UJ_MENU_AVAILABLE;
}

public uj_fw_menus_select_post(playerID, menuID, entryID)
{
  // Open up our own menu if the player selects it.
  // Also re-open it if something from it is selected
  if (entryID != g_menuEntry && menuID != g_menu) {
    return;
  }
  
  uj_menus_show_menu(playerID, g_menu);
}
