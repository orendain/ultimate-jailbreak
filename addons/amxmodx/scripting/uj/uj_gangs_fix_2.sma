#include <amxmodx>
#include <uj_gangs>
#include <uj_gang_skill_db>

new const PLUGIN_NAME[] = "[UJ] Gangs - Fix 2";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

public plugin_init()
{
  register_plugin(PLUGIN_NAME, PLUGIN_VERS, PLUGIN_AUTH);

  register_concmd("uj_gangs_fix_2_1", "fix_2_1");
}

public fix_2_1(playerID)
{
  // Find gang
  new gangID = uj_gangs_get_gang_id("Run NigguH Ruuuuun");
  new skillID = uj_gang_skill_db_get_id("Damage");
  new result = uj_gang_skill_db_set_level(gangID, skillID, 30);

  if (result == UJ_GANG_SKILL_INVALID) {
    server_print("That failed.");
  }

  return PLUGIN_HANDLED;
}
