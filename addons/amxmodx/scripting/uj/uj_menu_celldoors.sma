#include <amxmodx>
#include <cstrike>
#include <uj_cells>
#include <uj_menus>

new const PLUGIN_NAME[] = "UJ | Menu Entry - Cells Doors";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

new const MENU_NAME[] = "Cell Doors";

new g_menuEntry
new g_mainMain

public plugin_init()
{
  register_plugin(PLUGIN_NAME, PLUGIN_VERS, PLUGIN_AUTH);

  // Register the menu entry
  g_menuEntry = uj_menus_register_entry(MENU_NAME)

  // Find the menu this should appear under
  g_mainMain = uj_menus_get_menu_id("Main Menu")
}

public uj_fw_menus_select_pre(playerID, menuID, entryID)
{
  // This is not our entry - do not block
  if (entryID != g_menuEntry)
    return UJ_MENU_AVAILABLE;
  
  // Only display to alive Counter Terrorists
  if (!is_user_alive(playerID) || cs_get_user_team(playerID) != CS_TEAM_CT)
    return UJ_MENU_DONT_SHOW;

  // Do not show if it is not in this specific parent menu
  if (menuID != g_mainMain)
    return UJ_MENU_DONT_SHOW;
  
  return UJ_MENU_AVAILABLE;
}

public uj_fw_menus_select_post(playerID, menuID, entryID)
{
  // This is not our item
  if (g_menuEntry != entryID)
    return;
  
  // Open up cells
  uj_cells_open_doors(playerID);
}
