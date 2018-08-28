#include <amxmodx>
#include <cstrike>
#include <fg_colorchat>
#include <uj_gangs>
#include <uj_logs>
#include <uj_menus>

new const PLUGIN_NAME[] = "UJ | Menu - Gang Leave";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

new const MENU_NAME[] = "Leave gang";

// Menu variables
new g_menuEntry
new g_menuMain

public plugin_precache()
{
  // Register a menu entry
  g_menuEntry = uj_menus_register_entry(MENU_NAME);
}

public plugin_init()
{
  register_plugin(PLUGIN_NAME, PLUGIN_VERS, PLUGIN_AUTH);

  // The menu we will display in
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

  // Prisoners must be in a gang to see this option
  new gangRank = uj_gangs_get_member_rank(playerID);
  if (gangRank == UJ_GANG_RANK_INVALID) {
    return UJ_MENU_DONT_SHOW;
  }

  // Do not allow leaders to leave gangs
  if (gangRank == UJ_GANG_RANK_LEADER) {
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
  if (gangID != UJ_GANG_INVALID) {
    new playerName[32], gangName[32];
    get_user_name(playerID, playerName, charsmax(playerName));
    uj_gangs_get_name(gangID, gangName, charsmax(gangName));
    uj_gangs_remove_member(playerID, gangID);
    fg_colorchat_print(0, playerID, "^3%s^1 has left ^3%s^1! Watch your back, homie!", playerName, gangName);
    uj_logs_log("[uj_menu_gang_leave] %s has left the gang %s.", playerName, gangName);
  }
}
