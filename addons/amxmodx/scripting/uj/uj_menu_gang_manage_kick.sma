#include <amxmodx>
#include <fakemeta>
#include <fg_colorchat>
#include <uj_gangs>
#include <uj_logs>
#include <uj_menus>
#include <uj_player_stats>
#include <xs>

new const PLUGIN_NAME[] = "UJ | Menu - Gang Kick";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

new const MENU_NAME[] = "Kick members";

// CS Player PData Offsets (win32)
new const OFFSET_CSMENUCODE = 205;

#define MAX_MEMBERS 15
#define MAX_AUTHID_LENGTH 24

// Menu variables
new g_menuEntry;
new g_menuManage;

// Store member authIDs
new memberAuthIDs[MAX_MEMBERS][MAX_AUTHID_LENGTH + 1];
new memberCount;

// Simultaneous menus are not allowed, keep track of active user
new activePlayerID;

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

  activePlayerID = playerID;
  new gangID = uj_gangs_get_gang(playerID);
  
  memberCount = MAX_MEMBERS;

  // Temp
  //copy(memberAuthIDs[0], 5, "tomato");

  new allAuthIDs[1024];

  uj_gangs_get_membership(gangID, allAuthIDs, memberCount);

  xs_explode(allAuthIDs, memberAuthIDs, ',', sizeof(memberAuthIDs), MAX_AUTHID_LENGTH);

  //fg_colorchat_print(0, 1, "member[0] as int: %i", memberAuthIDs[0]);

  //fg_colorchat_print(0, 1, "first char of mem %c", get_addr_val((int)memberAuthIDs));
  //fg_colorchat_print(0, FG_COLORCHAT_RED, "First MemberAuthID: %s", memberAuthIDs[0]);
  //fg_colorchat_print(0, FG_COLORCHAT_RED, "Second MemberAuthID: %s", memberAuthIDs[1]);
  
  // Display a menu of gang members
  display_member_menu(playerID);
}

// Display menu
display_member_menu(playerID)
{
  //new colorName[32], red, green, blue, alpha;

  // Title
  new menuID = menu_create(MENU_NAME, "menu_handler");
  
  // List all players
  new memberName[32];
  for (new i = 0; i < memberCount; ++i) {
    uj_player_stats_get_name(memberAuthIDs[i], memberName, sizeof(memberName)-1);
    menu_additem(menuID, memberName);
  }

  // Fix for AMXX custom menus
  set_pdata_int(playerID, OFFSET_CSMENUCODE, 0);
  menu_display(playerID, menuID, 0);
}

// Items Menu
public menu_handler(playerID, menuID, entrySelected)
{
  // Menu was closed
  if (entrySelected == MENU_EXIT) {
    menu_destroy(menuID);
    return PLUGIN_HANDLED;
  }

  // Used simultaneously, thus data overwritten.  Kill this connection.
  if (playerID != activePlayerID) {
    fg_colorchat_print(playerID, FG_COLORCHAT_RED, "^3Oops, the system is busy!  Please try again!^1");
    menu_destroy(menuID);
    return PLUGIN_HANDLED;
  }

  // Find player and target names
  new playerName[32], targetName[32], gangName[32];
  new gangID = uj_gangs_get_gang(playerID);
  get_user_name(playerID, playerName, charsmax(playerName));
  uj_player_stats_get_name(memberAuthIDs[entrySelected], targetName, charsmax(targetName));
  uj_gangs_get_name(gangID, gangName, charsmax(gangName));

  uj_gangs_remove_member_auth(memberAuthIDs[entrySelected], gangID);

  fg_colorchat_print(0, FG_COLORCHAT_RED, "Daaayyyyaam!  ^3%s^1 has been kicked out of ^3%s^1!", targetName, gangName);
  uj_logs_log("[uj_menu_gang_manage_kick] %s kicked %s (%s) from %s.", playerName, targetName, memberAuthIDs[entrySelected], gangName);

  // Only destroy when the user exits on their own.
  // As such, comment this out.
  //menu_destroy(menuID);

  // Bring the glow menu up again
  menu_display(playerID, menuID, 0);

  return PLUGIN_HANDLED;
}
