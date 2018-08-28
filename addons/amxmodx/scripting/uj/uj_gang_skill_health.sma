#include <amxmodx>
#include <cstrike>
#include <fg_colorchat>
#include <uj_core>
#include <uj_gangs>
#include <uj_gang_skill_db>
#include <uj_gang_skills>
#include <uj_requests>

new const PLUGIN_NAME[] = "UJ | Gang Skill - Health";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

new const SKILL_NAME[] = "Health";
new const SKILL_COST[] = "400";
new const SKILL_PER[] = "1.0";
new const SKILL_MAX[] = "50";

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
  if (cs_get_user_team(playerID) == CS_TEAM_T && (uj_requests_get_current() == UJ_REQUEST_INVALID)) {
    // Find user's gang and the gang's skill level
    new gangID = uj_gangs_get_gang(playerID);
    new skillLevel = uj_gang_skill_db_get_level(gangID, g_skill);

    if (skillLevel > 0) {
      // Determine the user's maximum health
      new Float:totalHealth = 100.0 + (skillLevel * get_pcvar_float(g_skillPer));
      new Float:currentHealth = float(dataArray[0]);

      //fg_colorchat_print(playerID, playerID, "data[0]_int = %i, data[0]_float = %f, currentHealth = %f", dataArray[0], float(dataArray[0]), currentHealth);

      if (currentHealth < totalHealth) {
        dataArray[0] = floatround(totalHealth);
      }
    }
  }
}

// When an LR event is selected, remove gang skill
public uj_fw_requests_select_post(playerID, targetID, requestID)
{
  // Re-traverse through modules implementing uj_fw_core_get_max_health().
  // Ours will be skipped due to the uj_requests_get_current() check.
  new health;
  uj_core_determine_max_health(playerID, health);
}
