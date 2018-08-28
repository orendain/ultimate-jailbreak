#include <amxmodx>
#include <cstrike>
#include <fun>
#include <uj_effects>
#include <uj_gangs>
#include <uj_gang_skill_db>
#include <uj_gang_skills>
#include <uj_requests>

new const PLUGIN_NAME[] = "UJ | Gang Skill - Speed";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

new const SKILL_NAME[] = "Speed";
new const SKILL_COST[] = "250";
new const SKILL_PER[] = "0.004";
new const SKILL_MAX[] = "50";

new g_skillCost;
new g_skillPer;
new g_skillMax;

new g_skill;

public plugin_init()
{
  register_plugin(PLUGIN_NAME, PLUGIN_VERS, PLUGIN_AUTH);

  // Register skill attributes
  g_skillCost = register_cvar("uj_gang_skill_speed_cost", SKILL_COST);
  g_skillPer = register_cvar("uj_gang_skill_speed_per", SKILL_PER);
  g_skillMax = register_cvar("uj_gang_skill_speed_max", SKILL_MAX);

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
}*/
/*
public uj_fw_gang_skill_menus_s_post(playerID, menuID, skillEntryID)
{
  // This is not our skill menu entry
  if (skillEntryID != g_skillEntry)
    return;

  new const SCOUTDUEL_GRAVITY[] = "0.25";
  set_user_gravity(targetID, gravity);
}*/

public uj_effects_determine_max_speed(playerID, data[])
{
  if (cs_get_user_team(playerID) == CS_TEAM_T && (uj_requests_get_current() == UJ_REQUEST_INVALID)) {
    new gangID = uj_gangs_get_gang(playerID);
    new skillLevel = uj_gang_skill_db_get_level(gangID, g_skill);
    if (skillLevel > 0) {
      //fg_colorchat_print(playerID, playerID, "skill speed affecting.");
      // Need to first cast as Floats
      new Float:result = float(data[0]);
      result *= 1.0 + (skillLevel * get_pcvar_float(g_skillPer));
      data[0] = floatround(result);
      //fg_colorchat_print(playerID, playerID, "skill, data %f, result %f", data[0], result)
      //fg_colorchat_print(playerID, playerID, "gang %i, skill %i", gangID, skillLevel)
    }
  }

  // Not sure if needed or not
  return;
}

// When an LR event is selected, remove gang skill
public uj_fw_requests_select_post(playerID, targetID, requestID)
{
  // Re-traverse through modules implementing uj_effects_determine_max_speed().
  // Ours will be skipped due to the uj_requests_get_current() check.
  uj_effects_reset_max_speed(playerID);
}
