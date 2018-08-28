#include <amxmodx>
#include <cstrike>
#include <uj_gangs>
#include <uj_menus>

new const PLUGIN_NAME[] = "UJ | Menu - Gang";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

new const MENU_NAME[] = "Gang Menu";

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
  g_menuEntry = uj_menus_register_entry(MENU_NAME);

  // The menu we will display in
  g_menuMain = uj_menus_get_menu_id("Main Menu");
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

  return UJ_MENU_AVAILABLE;
}

public uj_fw_menus_select_post(playerID, menuID, entryID)
{
  // This is not our menu entry
  if (g_menuEntry != entryID)
    return;
  
  // Prepare the menu
  new gangID = uj_gangs_get_gang(playerID);
  if (gangID != UJ_GANG_INVALID) {
    new memberCount = uj_gangs_get_member_count(gangID);
    new memberLimit = 10;

    new gangName[32];
    uj_gangs_get_name(gangID, gangName, charsmax(gangName));

    new text[128];
    formatex(text, charsmax(text), "\yCrew Name: \w%s", gangName);
    formatex(text, charsmax(text), "%s^n\yHomies: \w%i / %i", text, memberCount, memberLimit);
    uj_menus_add_text(text);
  }

  // Now open up our own menu
  uj_menus_show_menu(playerID, g_menu);
}
