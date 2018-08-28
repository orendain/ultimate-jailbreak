#include <amxmodx>
#include <fun>
#include <cstrike>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <uj_chargers>
#include <uj_core>
#include <uj_effects>
#include <uj_menus>
#include <uj_days>

new const PLUGIN_NAME[] = "UJ | Day - One In The Chamber";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

new const DAY_NAME[] = "One In The Chamber";
new const DAY_OBJECTIVE[] = "Get One-Deag'd!";
new const DAY_SOUND[] = "ultimate_jailbreak/oneinthechamber.wav";

// Day variables
new g_day = UJ_DAY_INVALID;
new bool:g_dayEnabled;

// Menu variables
new g_menuSpecial;

// Day necessities
new g_weaponEntityIDs[33];

public plugin_precache()
{
  precache_sound(DAY_SOUND);
}

public plugin_init()
{
  register_plugin(PLUGIN_NAME, PLUGIN_VERS, PLUGIN_AUTH);

  // Register this day
  g_day = uj_days_register(DAY_NAME, DAY_OBJECTIVE, DAY_SOUND);

  // Find all menus to allow this day to display in
  g_menuSpecial = uj_menus_get_menu_id("Special Days");

  // Track events
  register_event("DeathMsg", "FwPlayerKilled", "a")
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

  // If already enabled, disabled this option
  if (g_dayEnabled) {
    return UJ_DAY_NOT_AVAILABLE;
  }

  return UJ_DAY_AVAILABLE;
}

public uj_fw_days_select_post(playerID, dayID)
{
  // This is not our day - do not continue
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

    new players[32], playerID;
    new playerCount = uj_core_get_players(players, true, CS_TEAM_T);
    for (new i = 0; i < playerCount; ++i) {
      playerID = players[i];
      uj_core_strip_weapons(playerID);
      
      set_pev(playerID, pev_health, 1.0);

      g_weaponEntityIDs[playerID] = give_item(playerID, "weapon_deagle");
      cs_set_weapon_ammo(g_weaponEntityIDs[playerID], 1);
    }
    
    playerCount = uj_core_get_players(players, true, CS_TEAM_CT);
    for (new i = 0; i < playerCount; ++i) {
      set_user_godmode(players[i], 1);
    }

    uj_core_set_friendly_fire(true);
    uj_core_block_weapon_pickup(0, true);
    uj_chargers_block_heal(0, true);
    uj_chargers_block_armor(0, true);
  }
}

end_day()
{
  if (g_dayEnabled) {
    new players[32];
    new playerCount = uj_core_get_players(players, true, CS_TEAM_T);
    for (new i = 0; i < playerCount; ++i) {
      uj_core_strip_weapons(players[i]);
    }

    playerCount = uj_core_get_players(players, false, CS_TEAM_CT);
    for (new i = 0; i < playerCount; ++i) {
      set_user_godmode(players[i]); // Disables godmode
    }

    uj_core_set_friendly_fire(false);
    uj_core_block_weapon_pickup(0, false);
    uj_chargers_block_heal(0, false);
    uj_chargers_block_armor(0, false);

    g_dayEnabled = false;
  }
}

public FwPlayerKilled()
{
  if (g_dayEnabled) {
    static killerID, victimID, weapID;
    killerID = read_data(1);
    victimID = read_data(2);
    weapID = g_weaponEntityIDs[killerID];

    if ((1<= killerID <= 32) && (1<= victimID <= 32) && weapID) {
      cs_set_weapon_ammo(weapID, 1);
    }
  }
}
