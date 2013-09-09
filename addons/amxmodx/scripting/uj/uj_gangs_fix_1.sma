#include <amxmodx>
#include <uj_gangs>
#include <uj_gang_skill_db>

new const PLUGIN_NAME[] = "[UJ] Gangs - Fix 1";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

public plugin_init()
{
  register_plugin(PLUGIN_NAME, PLUGIN_VERS, PLUGIN_AUTH);

  register_concmd("uj_gangs_fix_1", "fix_1");
  register_concmd("uj_gangs_fix_2", "fix_2");

  register_concmd("uj_gangs_fix_3", "fix_3");
  register_concmd("uj_gangs_fix_4", "fix_4");
}

public fix_1(playerID)
{
  // Find gang
  new gangID = uj_gangs_get_gang_id("Mats");
  uj_gangs_destroy_gang(gangID);

  return PLUGIN_HANDLED;
}

public fix_2(playerID)
{
  // Find gang and remove user
  new gangID = uj_gangs_get_gang_id("The Gangstas");
  uj_gangs_remove_member_auth("STEAM_0:0:9837404", gangID);

  return PLUGIN_HANDLED;
}

public fix_3(playerID)
{
  new gang_names[][] =
  {
    "The Gangstas",
    "LOL",
    "Cant Touch This.",
    " Brotherhood",
    "DontReachYoungBlood",
    "Bomb",
    "Kyrie Irving ",
    "Dinosaurs",
    "Unagi C.I.A",
    "The MOB",
    "Don Inc.",
    "DEATHGRIPS"
  }

  new skill_names[][] =
  {
    "Disarm",
    "Health",
    "Gravity",
    "Damage",
    "Speed"
  }

  new skill_levels[][] = 
  {
    {0, 48, 30, 19, 50},
    {3, 7, 14, 1, 7},
    {5, 8, 26, 5, 14},
    {10, 0, 0, 0, 35},
    {0, 0 ,0, 0, 1},
    {0, 0, 0, 0, 0}, // Bomb
    {0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0}, // Dino
    {0, 0, 0, 0, 0},  //Unagi
    {0, 3, 10, 0, 41}, // mob
    {0, 0, 0, 0, 25}, //don inc
    {0, 0, 0, 0, 50} //deathgrips
  }

  new gangID, skillID, skillLevel;
  new result;
  for (new i = 0; i < sizeof(gang_names); ++i) {
    gangID = uj_gangs_get_gang_id(gang_names[i]);

    for (new j = 0; j < sizeof(skill_names); ++j) {
      skillID = uj_gang_skill_db_get_id(skill_names[j]);
      skillLevel = skill_levels[i][j];
      result = uj_gang_skill_db_set_level(gangID, skillID, skillLevel);

      server_print("%s, %s, %i", gang_names[i], skill_names[j], skillLevel);
      if (result == UJ_GANG_SKILL_INVALID) {
        server_print("^^ That failed.");
      }
    }
  }

  return PLUGIN_HANDLED;
}

public fix_4(playerID)
{
  // Find gang
  new gangID = uj_gangs_get_gang_id("Faggots");
  uj_gangs_destroy_gang(gangID);

  return PLUGIN_HANDLED;
}
