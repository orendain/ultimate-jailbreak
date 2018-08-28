#include <amxmodx>
#include <cstrike>
#include <fg_colorchat>
#include <uj_gangs>
#include <uj_logs>
#include <uj_menus>

new const PLUGIN_NAME[] = "UJ | Menu - Gang Disband";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

new const MENU_NAME[] = "Disband crew";

// Menu variables
new g_menuEntry;
new g_menuManage;

public plugin_init()
{
  register_plugin(PLUGIN_NAME, PLUGIN_VERS, PLUGIN_AUTH);

  // Register a menu entry
  g_menuEntry = uj_menus_register_entry(MENU_NAME);

  // The menu we will display in
  g_menuManage = uj_menus_get_menu_id("Manage gang");
}

public uj_fw_menus_select_pre(playerID, menuID, entryID)
{
  // This is not our menu entry - do not block
  if (entryID != g_menuEntry) {
    return UJ_MENU_AVAILABLE;
  }

  // Do not show if it is not in this specific parent menu
  if (menuID != g_menuManage) {
    return UJ_MENU_DONT_SHOW;
  }
  
  // Only display menu to Terrorists
  /* // Already filtered by manageMenu
  if (cs_get_user_team(playerID) != CS_TEAM_T) {
    return UJ_MENU_DONT_SHOW;
  }

  // Only display to leaders of gangs
  new gangRank = uj_gangs_get_member_rank(playerID);
  if (gangRank != UJ_GANG_RANK_LEADER) {
    return UJ_MENU_DONT_SHOW;
  }*/

  return UJ_MENU_AVAILABLE;
}

public uj_fw_menus_select_post(playerID, menuID, entryID)
{
  // This is not our menu entry
  if (g_menuEntry != entryID)
    return;
  
  // Retrieve necessary information
  new gangID = uj_gangs_get_gang(playerID);
  new gangName[32];
  uj_gangs_get_name(gangID, gangName, charsmax(gangName));

  fg_colorchat_print(0, playerID, "Oh, snap! ^3%s^1 has been disbanded! Peace out!", gangName);
  uj_logs_log("[uj_menu_gang_manage_disband] Gang %s was disbanded.", gangName);

  // Display announcement to online members of the gang
  /*new players[32];
  new playerCount = uj_gangs_get_online_members(gangID, players, sizeof(players));
  for (new i = 0; i < playerCount; ++i) {
    fg_colorchat_print(players[i], playerID, "Your gang leader, ^3%s^1, has decided to disband ^3%s^1! Peace out!", playerName, gangName);
  }*/

  // Disband the gang
  uj_gangs_destroy_gang(gangID);
}
