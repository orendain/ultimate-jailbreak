#include <amxmodx>
#include <fun>
#include <cstrike>
#include <fakemeta>
#include <uj_menus>
#include <uj_days>

new const PLUGIN_NAME[] = "UJ | Day - Lava Day";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

new const DAY_NAME[] = "Lava Day";
new const DAY_OBJECTIVE[] = "Oh dang, hot hot hot HOT HOT!!!";
new const DAY_SOUND[] = "";

new const LAVA_SPRAY_FREQUENCY[] = "5";

// Day variables
new g_day
new bool: g_dayEnabled

// Menu variables
new g_menuSpecial

// CVars
new g_sprayFrequencyPCVar;
new g_decalFrequencyPCVar;

public plugin_init()
{
  register_plugin(PLUGIN_NAME, PLUGIN_VERS, PLUGIN_AUTH);

  // Find all valid menus to display this under
  g_menuSpecial = uj_menus_get_menu_id("Special Days")

  // CVars
  g_sprayFrequencyPCVar = register_cvar("uj_day_lava_sprayfrequency", LAVA_SPRAY_FREQUENCY);
  g_decalFrequencyPCVar = get_cvar_pointer("decalfrequency");

  // Register day
  g_day = uj_days_register(DAY_NAME, DAY_OBJECTIVE, DAY_SOUND)
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
    new frequency = get_pcvar_num(g_sprayFrequencyPCVar);
    set_pcvar_num(g_decalFrequencyPCVar, frequency);
  }
}

end_day()
{
  g_dayEnabled = false;
  set_pcvar_num(g_decalFrequencyPCVar, 60);
}
