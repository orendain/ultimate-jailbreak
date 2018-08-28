#include <amxmodx>
#include <cstrike>
#include <fakemeta>
#include <fun>
#include <uj_menus>
#include <uj_chargers>
#include <uj_core>
#include <uj_days>

new const PLUGIN_NAME[] = "UJ | Day - SWAT";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

new const DAY_NAME[] = "Koolaid's SWAT";
new const DAY_OBJECTIVE[] = "Lock and load, boys. It's time to get our hands dirty.";
new const DAY_SOUND[] = "";

new const SWAT_PRIMARY_AMMO[] = "200";
new const SWAT_SECONDARY_AMMO[] = "50";
new const SWAT_PRISONER_HEALTH[] = "100.0";
new const SWAT_GUARD_HEALTH[] = "250.0";

// Day variables
new g_day;
new bool:g_dayEnabled;

// Menu variables
new g_menuSpecial

// Cvars
new g_primaryAmmoPCVar;
new g_secondaryAmmoPCVar;
new g_prisonerHealthPCVar;
new g_guardHealthPCVar;

public plugin_init()
{
  register_plugin(PLUGIN_NAME, PLUGIN_VERS, PLUGIN_AUTH);

  // Find all valid menus to display this under
  g_menuSpecial = uj_menus_get_menu_id("Special Days");

  // CVars
  g_primaryAmmoPCVar = register_cvar("uj_day_swat_primary_ammo", SWAT_PRIMARY_AMMO);
  g_secondaryAmmoPCVar = register_cvar("uj_day_swat_secondary_ammo", SWAT_SECONDARY_AMMO);
  g_prisonerHealthPCVar = register_cvar("uj_day_swat_prisoner_health", SWAT_PRISONER_HEALTH);
  g_guardHealthPCVar = register_cvar("uj_day_swat_guard_health", SWAT_GUARD_HEALTH);

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
    new Float:prisonerHealth = get_pcvar_float(g_prisonerHealthPCVar);
    new Float:guardHealth = get_pcvar_float(g_guardHealthPCVar);

    new players[32], playerID;
    new playerCount = uj_core_get_players(players, true, CS_TEAM_T);
    for (new i = 0; i < playerCount; ++i) {
      playerID = players[i];

      uj_core_strip_weapons(playerID);
      cs_set_user_armor(playerID, 100, CS_ARMOR_VESTHELM);
      set_pev(playerID, pev_health, prisonerHealth);

      give_item(playerID, "weapon_hegrenade");
      give_item(playerID, "weapon_mac10");
      cs_set_user_bpammo(playerID, CSW_MAC10, primaryAmmoCount);
    }

    playerCount = uj_core_get_players(players, true, CS_TEAM_CT);
    new halfCount = playerCount / 2;
    for (new i = 0; i < playerCount; ++i) {
      playerID = players[i];

      uj_core_strip_weapons(playerID);
      cs_set_user_armor(playerID, 100, CS_ARMOR_VESTHELM);
      set_pev(playerID, pev_health, guardHealth);
      give_item(playerID, "weapon_flashbang");
      give_item(playerID, "weapon_flashbang");

      // Give this to the first half of the guards
      if (i < halfCount) {
        give_item(playerID, "weapon_shield");
        give_item(playerID, "weapon_usp");
        cs_set_user_bpammo(playerID, CSW_USP, secondaryAmmoCount);
      }
      else {
        give_item(playerID, "weapon_m4a1");
        cs_set_user_bpammo(playerID, CSW_M4A1, primaryAmmoCount);
      }
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
    set_pev(playerID, pev_health, 100.0);
  }

  g_dayEnabled = false;
  uj_core_block_weapon_pickup(0, false);
  uj_chargers_block_heal(0, false);
  uj_chargers_block_armor(0, false);
}
