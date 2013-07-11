#include <amxmodx>
#include <uj_menus>

new const PLUGIN_NAME[] = "[UJ] Menu Entry - Rules";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

new const MENU_NAME[] = "Read the Rules";

new const RULES_URL[] = "http://allied-gamers.com/JB/AG_rules.html";

new g_menuEntry;
new g_mainMain;

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
  
  // Open up the rules
  show_motd(playerID, RULES_URL, "The Rules");
}
