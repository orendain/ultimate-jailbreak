#include <amxmodx>
#include <cstrike>
#include <fun>
#include <uj_colorchat>
#include <uj_gangs>
#include <uj_gang_skill_db>
#include <uj_gang_skills>
#include <uj_logs>

new const PLUGIN_NAME[] = "[UJ] Gang Skill - Damage";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

// PER * MAX = 15%
new const SKILL_NAME[] = "Damage";
new const SKILL_COST[] = "500";
new const SKILL_PER[] = "0.01";
new const SKILL_MAX[] = "30";

new g_skillCost;
new g_skillPer;
new g_skillMax;

new g_skill;

public plugin_init()
{
  register_plugin(PLUGIN_NAME, PLUGIN_VERS, PLUGIN_AUTH);

  // Register skill attributes
  g_skillCost = register_cvar("uj_gang_skill_damage_cost", SKILL_COST);
  g_skillPer = register_cvar("uj_gang_skill_damage_per", SKILL_PER);
  g_skillMax = register_cvar("uj_gang_skill_damage_max", SKILL_MAX);

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

// Called when determining the final damage to compute
public uj_fw_core_get_damage_taken(victimID, inflictorID, attackerID, float:originalDamage, damagebits, data[])
{
  if ((1<=attackerID<=32) && cs_get_user_team(attackerID) == CS_TEAM_T) {
    new gangID = uj_gangs_get_gang(attackerID);
    new skillLevel = uj_gang_skill_db_get_level(gangID, g_skill);

    if (skillLevel > 0) {
      new Float:per = get_pcvar_float(g_skillPer);

      new Float:damage = float(data[0]);
      damage *= 1.0 + (skillLevel * per);

      //uj_colorchat_print(attackerID, attackerID, "Upgrading your damage from %i to %i", data[0], floatround(damage));
      uj_logs_log_dev("[uj_gang_skill_damage] Player %i: upgrading damage from %i to %i", attackerID, data[0], floatround(damage));

      data[0] = floatround(damage);
    }
  }

  // Not sure if needed or not
  return;
}
