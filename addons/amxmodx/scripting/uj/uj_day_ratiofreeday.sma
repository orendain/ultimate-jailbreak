#include <amxmodx>
#include <fun>
#include <cstrike>
#include <fakemeta>
#include <uj_menus>
#include <uj_days>

new const PLUGIN_NAME[] = "[UJ] Day - Ratio Freeday";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

new const DAY_NAME[] = "Ratio Freeday";
new const DAY_OBJECTIVE[] = "The first guard to die must become a prisoner!";
new const DAY_SOUND[] = "";

// Day variables
new g_day
new bool: g_dayEnabled

// Menu variables
new g_menuSpecial;

public plugin_precache()
{
  // Register day
  g_day = uj_days_register(DAY_NAME, DAY_OBJECTIVE, DAY_SOUND)
}

public plugin_init()
{
  register_plugin(PLUGIN_NAME, PLUGIN_VERS, PLUGIN_AUTH);

  // Find the menus we want to restrict
  g_menuSpecial = uj_menus_get_menu_id("Special Days")
}

// This day is meant to be called by elsewhere in the system
// Never show this day to players
public uj_fw_days_select_pre(id, dayID, menuID)
{
  // If this day is enabled, disable all other days
  if (g_dayEnabled && (menuID == g_menuSpecial)) {
    return UJ_DAY_NOT_AVAILABLE;
  }

  // This is not our day - do not block
  if (dayID != g_day) {
    return UJ_DAY_AVAILABLE;
  }
  
  return UJ_DAY_DONT_SHOW;
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
  }
}

end_day()
{
  g_dayEnabled = false;
}
