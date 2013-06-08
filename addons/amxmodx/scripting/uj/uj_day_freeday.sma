#include <amxmodx>
#include <fun>
#include <cstrike>
#include <fakemeta>
#include <uj_menus>
#include <uj_days>
#include <uj_colorchat>

new const PLUGIN_NAME[] = "[UJ] Day - Freeday";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

new const DAY_NAME[] = "Freeday";
new const DAY_OBJECTIVE[] = "FREEEEEEEEEEDDDDOOOOOOOOOOMMMMM!";
new const DAY_SOUND[] = "";

// Day variables
new g_day
new bool: g_dayEnabled

// Menu variables
new g_menuSpecial
new g_menuActivities

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
  g_menuActivities = uj_menus_get_menu_id("Activities")
}

public uj_fw_days_select_pre(id, dayid, menuid)
{
  // Block all days from being enabled if a freeday is in effect
  if (g_dayEnabled && dayid != g_day) {
    return UJ_DAY_NOT_AVAILABLE;
  }

  // This is not our day - do not block
  if (dayid != g_day) {
    return UJ_DAY_AVAILABLE;
  }

  // Only display if in the parent menu we recognize
  if (menuid != g_menuActivities && menuid != g_menuSpecial) {
    return UJ_DAY_DONT_SHOW;
  }

  // If we *can* show the menu, but it's already enabled,
  // then have it be unavailable
  if (g_dayEnabled) {
    return UJ_DAY_NOT_AVAILABLE;
  }

  return UJ_DAY_AVAILABLE;
}

public uj_fw_days_select_post(id, dayid)
{
  // This is not our item
  if (dayid != g_day)
    return;

  g_dayEnabled = true;
}

public uj_fw_days_end(dayID)
{
  // If dayID refers to our day and our day is enabled
  if(dayID == g_day && g_dayEnabled) {
    g_dayEnabled = false;
  }
}
