#include <amxmodx>
#include <cstrike>
#include <uj_menus>

new const PLUGIN_NAME[] = "[UJ] Menu - Activities";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

new const MENU_NAME[] = "Activities";

new g_menu
new g_entryID
new g_menuMain

public plugin_precache()
{
  // Register a menu
  g_menu = uj_menus_register_menu(MENU_NAME)
}

public plugin_init()
{
  register_plugin(PLUGIN_NAME, PLUGIN_VERS, PLUGIN_AUTH);

  // Register this menu as a menu entry
  g_entryID = uj_menus_register_entry(MENU_NAME);

  // Find the menus this should display in
  g_menuMain = uj_menus_get_menu_id("Main Menu");
}

public uj_fw_menus_select_pre(playerID, menuID, entryID)
{
  // This is not our item - do not block
  if (entryID != g_entryID)
    return UJ_MENU_AVAILABLE;
  
  // Only display to Counter Terrorists
  if (cs_get_user_team(playerID) != CS_TEAM_CT)
    return UJ_MENU_DONT_SHOW;

  // Do not show if it is not in this specific parent menu
  if (menuID != g_menuMain)
    return UJ_MENU_DONT_SHOW;
  
  return UJ_MENU_AVAILABLE;
}

public uj_fw_menus_select_post(playerID, menuID, entryID)
{
  // This is not our item
  if (g_entryID != entryID)
    return;
  
  // Now open up our own menu
  uj_menus_show_menu(playerID, g_menu);
}
