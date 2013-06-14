#include <amxmodx>
#include <cstrike>
#include <uj_gangs>
#include <uj_gang_skill_db>
#include <uj_gang_skills>

new const PLUGIN_NAME[] = "[UJ] Gang Skill - Health";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

new const SKILL_NAME[] = "Health";
new const SKILL_COST[] = "50";
new const SKILL_PER[] = "2";
new const SKILL_MAX[] = "20";

// CVars
new g_skillCost
new g_skillPer
new g_skillMax

// Skill variables
new g_skill

public plugin_init()
{
  register_plugin(PLUGIN_NAME, PLUGIN_VERS, PLUGIN_AUTH);

  // Register skill attributes
  g_skillCost = register_cvar("uj_gang_skill_health_cost", SKILL_COST);
  g_skillPer = register_cvar("uj_gang_skill_health_per", SKILL_PER);
  g_skillMax = register_cvar("uj_gang_skill_health_max", SKILL_MAX);

  // Register a new gang skill
  g_skill = uj_gang_skills_register(SKILL_NAME, g_skillCost, g_skillMax);
}

/*
public uj_fw_gang_skills_select_pre(playerID, menuID, skillID)
{
  // This is not our menu entry - do not block
  if (skillID != g_skill) {
    return UJ_MENU_AVAILABLE;
  }

  // Only if player can afford it
  new cost = get_pcvar_num(g_skillCost);
  if (uj_points_get(playerID) < cost) {
    return UJ_MENU_NOT_AVAILABLE;
  }

  return UJ_MENU_AVAILABLE;
}
*/
/*
public uj_fw_gang_skills_select_post(playerID, menuID, skillEntryID)
{
  // This is not our skill menu entry
  if (skillEntryID != g_skillEntry)
    return;

  // If found in the upgrade menu
  if (menuID == g_menuUpgrade) {
    // Remove points, update skill, and announce change
    new cost = get_pcvar_num(g_skillCost);
    new gangID = uj_gangs_get_gang(playerID);
    uj_points_remove(playerID, cost);
    uj_gang_skill_db_add_level(gangID, g_skill);
    uj_gang_skills_announce_upgrade(playerID, gangID, g_skill);
  }
}
*/

public uj_fw_core_get_max_health(playerID, dataArray[])
{
  // Only affect prisoners
  if (cs_get_user_team(playerID) == CS_TEAM_T) {
    // Find user's gang and the gang's skill level
    new gangID = uj_gangs_get_gang(playerID);
    new skillLevel = uj_gang_skill_db_get_level(gangID, g_skill);

    if (skillLevel) {
      // Determine the user's maximum health
      new totalHealth = 100 + (skillLevel * get_pcvar_num(g_skillPer));

      if (dataArray[0] < totalHealth) {
        dataArray[0] = totalHealth;
      }
    }
  }
}
