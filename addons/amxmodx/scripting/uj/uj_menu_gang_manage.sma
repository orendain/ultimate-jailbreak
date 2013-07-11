#include <amxmodx>
#include <cstrike>
#include <uj_gangs>
#include <uj_menus>

new const PLUGIN_NAME[] = "[UJ] Menu - Gang Manage";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

new const MENU_NAME[] = "Manage gang";

// Menu variables
new g_menu;
new g_menuEntry;
new g_menuGangMenu;

public plugin_precache()
{
  // Register a menu
  g_menu = uj_menus_register_menu(MENU_NAME);
}

public plugin_init()
{
  register_plugin(PLUGIN_NAME, PLUGIN_VERS, PLUGIN_AUTH);

  // Register a menu entry
  g_menuEntry = uj_menus_register_entry(MENU_NAME)

  // The menu we will display in
  g_menuGangMenu = uj_menus_get_menu_id("Gang Menu")
}

public uj_fw_menus_select_pre(playerID, menuID, entryID)
{
  // This is not our menu entry - do not block
  if (entryID != g_menuEntry) {
    return UJ_MENU_AVAILABLE;
  }

  // Do not show if it is not in this specific parent menu
  if (menuID != g_menuGangMenu) {
    return UJ_MENU_DONT_SHOW;
  }
  
  // Only display menu to Terrorists
  if (cs_get_user_team(playerID) != CS_TEAM_T) {
    return UJ_MENU_DONT_SHOW;
  }

  // Only display to leaders of gangs
  new gangRank = uj_gangs_get_member_rank(playerID);
  if (gangRank != UJ_GANG_RANK_LEADER) {
    return UJ_MENU_DONT_SHOW;
  }

  return UJ_MENU_AVAILABLE;
}

public uj_fw_menus_select_post(playerID, menuID, entryID)
{
  // This is not our menu entry
  if (g_menuEntry != entryID)
    return;
  
  uj_menus_show_menu(playerID, g_menu);
}
