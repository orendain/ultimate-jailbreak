#include <amxmodx>
#include <cstrike>
#include <uj_gangs>
#include <uj_menus>
#include <uj_gang_skill_db>
#include <uj_gang_skills>
#include <uj_points>

new const PLUGIN_NAME[] = "UJ | Menu - Gang Skill Upgrade";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

new const MENU_NAME[] = "Upgrade skills";

// Plugin variables
new g_pluginID;

// Menu variables
new g_menu;
new g_menuGang;

public plugin_precache()
{
  // Register a menu entry
  g_menu = uj_menus_register_entry(MENU_NAME);
}

public plugin_init()
{
  g_pluginID = register_plugin(PLUGIN_NAME, PLUGIN_VERS, PLUGIN_AUTH);

  // The menu we will display in
  g_menuGang = uj_menus_get_menu_id("Gang Menu");
}

public uj_fw_menus_select_pre(playerID, menuID, entryID)
{
  // This is not our menu entry - do not block
  if (entryID != g_menu) {
    return UJ_MENU_AVAILABLE;
  }

  // Do not show if it is not in this specific parent menu
  if (menuID != g_menuGang) {
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

  return UJ_MENU_AVAILABLE;
}

public uj_fw_menus_select_post(playerID, menuID, entryID)
{
  // This is not our menu entry, and neither is the menu selected from
  if (g_menu != entryID)
    return;
  
  // Show a menu of all available skills
  // When selected, a forward should be called
  new gangID = uj_gangs_get_gang(playerID);
  uj_gang_skills_show_menu(playerID, gangID, true, false, true);
}

// Called after a player has selected a target
public uj_fw_gang_skills_select_post(pluginID, playerID, gangID, skillID)
{
  // Not intiated by us - don't continue;
  if (pluginID != g_pluginID) {
    return;
  }

  // Remove points, update skill, and announce change
  new cost = uj_gang_skills_get_cost(skillID);
  uj_points_remove(playerID, cost);
  uj_gang_skill_db_add_level(gangID, skillID);
  uj_gang_skills_announce_upgrade(playerID, gangID, skillID);

  // After upgrading, display menu again
  // Show a menu of all available skills
  // When selected, a forward should be called
  uj_gang_skills_show_menu(playerID, gangID, true, false, true);
}
