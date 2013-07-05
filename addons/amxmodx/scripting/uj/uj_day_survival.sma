#include <amxmodx>
#include <cstrike>
#include <fun>
#include <uj_menus>
#include <uj_chargers>
#include <uj_core>
#include <uj_days>
#include <uj_effects>

new const PLUGIN_NAME[] = "[UJ] Day - Survival";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

new const DAY_NAME[] = "Survival Day";
new const DAY_OBJECTIVE[] = "Guards, kill prisoners on sight!";
new const DAY_SOUND[] = "";

new const SURVIVAL_MAX_SPEED[] = "0.8";
new const SURVIVAL_AMMO[] = "50";

// Day variables
new g_day;
new bool:g_dayEnabled;

// Menu variables
new g_menuSpecial

// Cvars
new g_speedPCVar;
new g_ammoPCVar;

public plugin_precache()
{
  // Register day
  g_day = uj_days_register(DAY_NAME, DAY_OBJECTIVE, DAY_SOUND)
}

public plugin_init()
{
  register_plugin(PLUGIN_NAME, PLUGIN_VERS, PLUGIN_AUTH);

  // Find all valid menus to display this under
  g_menuSpecial = uj_menus_get_menu_id("Special Days");

  // CVars
  g_speedPCVar = register_cvar("uj_day_survival_maxspeed", SURVIVAL_MAX_SPEED);
  g_ammoPCVar = register_cvar("uj_day_survival_ammo", SURVIVAL_AMMO);
}

public uj_fw_days_select_pre(playerID, dayID, menuID)
{
  // This is not our day - do not block
  if (dayID != g_day) {
    return UJ_DAY_AVAILABLE;
  }

  // Only display if in the parent menu we recognize
  if (menuID != g_menuSpecial) {
    return UJ_DAY_DONT_SHOW;
  }

  // If we *can* show the menu, but it's already enabled,
  // then have it be unavailable
  if (g_dayEnabled) {
    return UJ_DAY_NOT_AVAILABLE;
  }

  return UJ_DAY_AVAILABLE;
}

public uj_fw_days_select_post(playerID, dayID)
{
  // This is not our item
  if (dayID != g_day)
    return;

  start_day();
}

public uj_fw_days_end(dayID)
{
  // If dayID refers to our day and our day is enabled
  if(dayID == g_day && g_dayEnabled) {
    end_day();
  }
}

start_day()
{
  if (!g_dayEnabled) {
    g_dayEnabled = true;

    // Find settings
    new ammoCount = get_pcvar_num(g_ammoPCVar);
    //new Float:maxspeed = get_pcvar_float(g_speedPCVar);

    new players[32], playerID;
    new playerCount = uj_core_get_players(players, true, CS_TEAM_CT);
    for (new i = 0; i < playerCount; ++i) {
      playerID = players[i];

      // Give user items and set effects
      uj_core_strip_weapons(playerID);
      give_item(playerID, "weapon_usp");
      cs_set_user_bpammo(playerID, CSW_USP, ammoCount);
      //uj_effects_set_max_speed(playerID, maxspeed);
      uj_effects_reset_max_speed(playerID);
    }

    uj_core_block_weapon_pickup(0, true);
    uj_chargers_block_heal(0, true);
    uj_chargers_block_armor(0, true);
  }
}

end_day()
{
  if (g_dayEnabled) {
    new players[32], playerID;
    new playerCount = uj_core_get_players(players, true, CS_TEAM_CT);
    for (new i = 0; i < playerCount; ++i) {
      playerID = players[i];

      uj_core_strip_weapons(playerID);
      uj_effects_reset_max_speed(playerID);
    }

    uj_core_block_weapon_pickup(0, false);
    uj_chargers_block_heal(0, false);
    uj_chargers_block_armor(0, false);
    g_dayEnabled = false;
  }
}

/*
 * Called when determining a player's max speed
 */
public uj_effects_determine_max_speed(playerID, data[])
{
  if (g_dayEnabled && cs_get_user_team(playerID) == CS_TEAM_CT) {
    new Float:result = float(data[0]);
    result *= get_pcvar_float(g_speedPCVar);
    data[0] = floatround(result);
    //uj_colorchat_print(playerID, playerID, "survival speed is %f", data[0]);
  }
}
