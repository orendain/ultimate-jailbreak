#include <amxmodx>
#include <cstrike>
#include <uj_gangs>
#include <uj_gang_skills>
#include <uj_gang_skill_menus>
#include <uj_colorchat>

new const PLUGIN_NAME[] = "[UJ] Gang Skill - Health";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

new const SKILL_NAME[] = "Health";
new const SKILL_COST[] = "50";
new const SKILL_PER[] = "2";
new const SKILL_MAX[] = "20";

new g_skillCost
new g_skillPer
new g_skillMax

new g_skill
new g_skillEntry
new g_skillMain

public plugin_init()
{
  register_plugin(PLUGIN_NAME, PLUGIN_VERS, PLUGIN_AUTH);

  // Register skill attributes
  g_skillCost = register_cvar("uj_gang_skill_health_cost", SKILL_COST);
  g_skillPer = register_cvar("uj_gang_skill_health_per", SKILL_PER);
  g_skillMax = register_cvar("uj_gang_skill_health_max", SKILL_MAX);

  // Register a new gang skill
  g_skill = uj_gang_skills_register(SKILL_NAME);
  g_skillEntry = uj_gang_skill_menus_register(g_skill, SKILL_NAME, g_skillCost, g_skillMax);

  // Find the correct parent menus
  g_skillMain = uj_menus_get_menu_id("Buy Skills");
}

public uj_fw_gang_skill_menus_s_pre(playerID, menuID, skillEntryID)
{
  // This is not our menu entry - do not block
  if (skillEntryID != g_skillEntry) {
    return UJ_MENU_AVAILABLE;
  }

  // Do not show if it is not in this specific parent menu
  if (menuID != g_skillMain) {
    return UJ_MENU_DONT_SHOW;
  }
  
  // Only display menu to Terrorists
  if (cs_get_user_team(playerID) != CS_TEAM_T) {
    return UJ_MENU_DONT_SHOW;
  }

  return UJ_MENU_AVAILABLE;
}

public uj_fw_gang_skill_menus_s_post(playerID, menuID, skillEntryID)
{
  // This is not our skill menu entry
  if (skillEntryID != g_skillEntry)
    return;

  // Hmmm ... don't really have to do anything at the moment ...
}

public uj_fw_core_get_max_health(playerID, dataArray[])
{
  // Find user's gang and the gang's skill level
  new gangID = uj_gangs_get_gang(playerID);
  new skillLevel = uj_gang_skills_get_level(gangID, g_skill);

  // Determine the user's maximum health
  new totalHealth = 100 + (skillLevel * get_pcvar_num(g_skillPer));

  if (dataArray[0] < totalHealth) {
    dataArray[0] = totalHealth;
  }
}
