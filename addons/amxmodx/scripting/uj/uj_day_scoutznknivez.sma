#include <amxmodx>
#include <fun>
#include <cstrike>
#include <fakemeta>
#include <uj_chargers>
#include <uj_core>
#include <uj_days>
#include <uj_menus>

new const PLUGIN_NAME[] = "[UJ] Day - Scoutz N Knivez";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

new const DAY_NAME[] = "Scoutz N Knivez";
new const DAY_OBJECTIVE[] = "The old-school game!";
new const DAY_SOUND[] = "";

new const GRAVITY_GRAVITY[] = "200";
new const GRAVITY_AMMO_COUNT[] = "50";

// Day variables
new g_day
new bool: g_dayEnabled

// Menu variables
new g_menuSpecial

// CVars
new g_gravityPCVar;
new g_customGravityPCVar;
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
  g_menuSpecial = uj_menus_get_menu_id("Special Days")

  // CVars
  g_customGravityPCVar = register_cvar("uj_day_scoutznknivez_gravity", GRAVITY_GRAVITY);
  g_ammoPCVar = register_cvar("uj_day_scoutznknivez_ammo", GRAVITY_AMMO_COUNT);
  g_gravityPCVar = get_cvar_pointer("sv_gravity");
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

  if (!g_dayEnabled) {
    start_day();
  } 
}

start_day()
{
  g_dayEnabled = true;
  new ammoCount = get_pcvar_num(g_ammoPCVar);
  set_pcvar_num(g_gravityPCVar, get_pcvar_num(g_customGravityPCVar));

  new players[32], playerID;
  new playerCount = uj_core_get_players(players, true);
  for (new i = 0; i < playerCount; ++i) {
    playerID = players[i];
    uj_core_strip_weapons(playerID);
    give_item(playerID, "weapon_scout");
    cs_set_user_bpammo(playerID, CSW_SCOUT, ammoCount);
  }

  uj_core_block_weapon_pickup(0, true);
  uj_chargers_block_heal(0, true);
  uj_chargers_block_armor(0, true);
}

public uj_fw_days_end(dayID)
{
  // If dayID refers to our day and our day is enabled
  if(dayID == g_day && g_dayEnabled) {
    end_day();
  }
}

end_day()
{
  set_pcvar_num(g_gravityPCVar, 800);

  new players[32], playerID;
  new playerCount = uj_core_get_players(players, true);
  for (new i = 0; i < playerCount; ++i) {
    playerID = players[i];
    uj_core_strip_weapons(playerID);
  }

  uj_core_block_weapon_pickup(0, false);
  uj_chargers_block_heal(0, false);
  uj_chargers_block_armor(0, false);
  g_dayEnabled = false;
}
