#include <amxmodx>
#include <fun>
#include <cstrike>
#include <fakemeta>
#include <uj_menus>
#include <uj_days>
#include <uj_colorchat>

new const PLUGIN_NAME[] = "[UJ] Day - Low Gravity Day";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

new const DAY_NAME[] = "Low Gravity";
new const DAY_OBJECTIVE[] = "Time to fly, ese...";
new const DAY_SOUND[] = "";

new const GRAVITY_GRAVITY[] = "200";

// Day variables
new g_day
new bool: g_dayEnabled

// Menu variables
new g_menuSpecial

// CVars
new g_gravityPCVar;
new g_customGravityPCVar;

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
  g_customGravityPCVar = register_cvar("uj_day_gravity_gravity", GRAVITY_GRAVITY);
  g_gravityPCVar = get_cvar_pointer("sv_gravity");
}

public uj_fw_days_select_pre(id, dayID, menuID)
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

public uj_fw_days_select_post(id, dayID)
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
    new gravity = get_pcvar_num(g_customGravityPCVar);
    set_pcvar_num(g_gravityPCVar, gravity);
  }
}

end_day()
{
  set_pcvar_num(g_gravityPCVar, 800);
  g_dayEnabled = false;
}
