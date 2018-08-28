#include <amxmodx>
#include <cstrike>
#include <fun>
#include <uj_menus>
#include <uj_chargers>
#include <uj_core>
#include <uj_days>
#include <uj_effects>

new const PLUGIN_NAME[] = "UJ | Day - Guards vs Spartans";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

new const DAY_NAME[] = "Guards vs Spartans";
new const DAY_OBJECTIVE[] = "THIS. IS. SPAAR ... JAAIILBREAAAK!!!!!";
new const DAY_SOUND[] = "";

new const SPARTA_PRIMARY_AMMO[] = "200";
new const SPARTA_SECONDARY_AMMO[] = "50";

// Day variables
new g_day;
new bool:g_dayEnabled;

// Menu variables
new g_menuSpecial

// Cvars
new g_primaryAmmoPCVar;
new g_secondaryAmmoPCVar;

public plugin_init()
{
  register_plugin(PLUGIN_NAME, PLUGIN_VERS, PLUGIN_AUTH);

  // Find all valid menus to display this under
  g_menuSpecial = uj_menus_get_menu_id("Special Days");

  // CVars
  g_primaryAmmoPCVar = register_cvar("uj_day_spartans_primary_ammo", SPARTA_PRIMARY_AMMO);
  g_secondaryAmmoPCVar = register_cvar("uj_day_spartans_secondary_ammo", SPARTA_SECONDARY_AMMO);

  // Register day
  g_day = uj_days_register(DAY_NAME, DAY_OBJECTIVE, DAY_SOUND)
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
    new primaryAmmoCount = get_pcvar_num(g_primaryAmmoPCVar);
    new secondaryAmmoCount = get_pcvar_num(g_secondaryAmmoPCVar);

    new players[32], playerID;
    new playerCount = uj_core_get_players(players, true, CS_TEAM_T);
    for (new i = 0; i < playerCount; ++i) {
      playerID = players[i];

      // Give user items
      uj_core_strip_weapons(playerID);
      give_item(playerID, "weapon_shield");
      give_item(playerID, "weapon_deagle");
      cs_set_user_bpammo(playerID, CSW_DEAGLE, secondaryAmmoCount);
    }

    playerCount = uj_core_get_players(players, true, CS_TEAM_CT);
    for (new i = 0; i < playerCount; ++i) {
      playerID = players[i];

      // Give user items
      uj_core_strip_weapons(playerID);
      give_item(playerID, "weapon_m4a1");
      cs_set_user_bpammo(playerID, CSW_M4A1, primaryAmmoCount);
    }

    uj_core_block_weapon_pickup(0, true);
    uj_chargers_block_heal(0, true);
    uj_chargers_block_armor(0, true);
  }
}

end_day()
{
  new players[32], playerID;
  new playerCount = uj_core_get_players(players, true);
  for (new i = 0; i < playerCount; ++i) {
    playerID = players[i];
    uj_core_strip_weapons(playerID);
  }

  g_dayEnabled = false;
  uj_core_block_weapon_pickup(0, false);
  uj_chargers_block_heal(0, false);
  uj_chargers_block_armor(0, false);
}
