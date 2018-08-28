#include <amxmodx>
#include <cstrike>
#include <fun>
#include <uj_gangs>
#include <uj_gang_skill_db>
#include <uj_gang_skills>
#include <uj_requests>

new const PLUGIN_NAME[] = "UJ | Gang Skill - Disarm";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

new const SKILL_NAME[] = "Disarm";
new const SKILL_COST[] = "400";
new const SKILL_PER[] = "1";
new const SKILL_MAX[] = "25";

new g_skillCost;
new g_skillPer;
new g_skillMax;

new g_skill;

public plugin_init()
{
  register_plugin(PLUGIN_NAME, PLUGIN_VERS, PLUGIN_AUTH);

  // Register skill attributes
  g_skillCost = register_cvar("uj_gang_skill_disarm_cost", SKILL_COST);
  g_skillPer = register_cvar("uj_gang_skill_disarm_per", SKILL_PER);
  g_skillMax = register_cvar("uj_gang_skill_disarm_max", SKILL_MAX);

  // Register a new gang skill
  g_skill = uj_gang_skills_register(SKILL_NAME, g_skillCost, g_skillMax);
}

// Called when a player takes damage
public uj_fw_core_get_damage_taken(victimID, inflictorID, attackerID, float:originalDamage, damagebits, data[])
{
  if ((1<=attackerID<=32) &&
      (cs_get_user_team(attackerID) == CS_TEAM_T) &&
      (cs_get_user_team(victimID) == CS_TEAM_CT) &&
      (get_user_weapon(attackerID) == CSW_KNIFE) &&
      (uj_requests_get_current() == UJ_REQUEST_INVALID)) {
    new gangID = uj_gangs_get_gang(attackerID);
    new skillLevel = uj_gang_skill_db_get_level(gangID, g_skill);
    if (skillLevel) {
      new chance = skillLevel * get_pcvar_num(g_skillPer);
      if (chance > random(100)) {
        client_cmd(victimID, "drop");
      }
    }
  }

  // Not sure if needed or not
  return;
}
