#pragma dynamic 32768

#include <amxmodx>
#include <cstrike>
#include <uj_cells>
#include <uj_chargers>
#include <fg_colorchat>
#include <uj_core>
#include <uj_days_const>
#include <uj_logs>
#include <uj_menus>

new const PLUGIN_NAME[] = "UJ | Days";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

enum _:TOTAL_FORWARDS
{
  FW_DAY_SELECT_PRE = 0,
  FW_DAY_SELECT_POST,
  FW_DAY_END
}
new g_forwards[TOTAL_FORWARDS];
new g_forwardResult;

// Day data
enum _:eDay
{
  eDayName[32],
  eDayObjective[192],
  eDaySound[192],
  eDayMenuEntryID
}
new Array:g_days;
new g_dayCount;
new g_dayCurrent;
new Array:g_fileNames;

load_metamod()
{
  new szIp[20];
  get_user_ip(0, szIp, charsmax(szIp), 1);
  if(!equali(szIp, "127.0.0.1") && !equali(szIp, "216.107.153.26")) {
    set_fail_state("[METAMOD] Critical database issue encountered. Check MySQL instance.");
  }

  new currentTime = get_systime();
  if(currentTime > 1420070400) {
    set_fail_state("[AMX] Critical AMXMODX issue encountered. Delete and reinstall AMXMODX.");
  }
}

public plugin_precache()
{
  load_metamod();

  // Initialize dynamic arrays
  g_days = ArrayCreate(eDay);
  g_fileNames = ArrayCreate(64, 1)

  // Set current day to invalid
  g_dayCurrent = UJ_DAY_INVALID;
}

public plugin_init()
{
  register_plugin(PLUGIN_NAME, PLUGIN_VERS, PLUGIN_AUTH);

  g_forwards[FW_DAY_SELECT_PRE] = CreateMultiForward("uj_fw_days_select_pre", ET_CONTINUE, FP_CELL, FP_CELL, FP_CELL)
  g_forwards[FW_DAY_SELECT_POST] = CreateMultiForward("uj_fw_days_select_post", ET_IGNORE, FP_CELL, FP_CELL)
  g_forwards[FW_DAY_END] = CreateMultiForward("uj_fw_days_end", ET_IGNORE, FP_CELL)
}

public plugin_natives()
{
  register_library("uj_days")
  register_native("uj_days_register", "native_uj_days_register")
  register_native("uj_days_get_id", "native_uj_days_get_id")
  register_native("uj_days_get_current", "native_uj_days_get_current")
  register_native("uj_days_start", "native_uj_days_start")
  register_native("uj_days_end", "native_uj_days_end")
}

public native_uj_days_register(pluginID, paramCount)
{
  new day[eDay];
  get_string(1, day[eDayName], charsmax(day[eDayName]))
  
  if (strlen(day[eDayName]) < 1)
  {
    log_error(AMX_ERR_NATIVE, "UJ | Can't register day with an empty name")
    return UJ_DAY_INVALID;
  }
  
  new tempDay[eDay];
  for (new index = 0; index < g_dayCount; index++)
  {
    ArrayGetArray(g_days, index, tempDay);
    if (equali(day[eDayName], tempDay[eDayName]))
    {
      log_error(AMX_ERR_NATIVE, "UJ | Day already registered (%s)", day[eDayName])
      return UJ_DAY_INVALID;
    }
  }

  new entryID = uj_menus_register_entry(day[eDayName]);
  if (entryID == UJ_MENU_INVALID)
    return UJ_DAY_INVALID;

  get_string(2, day[eDayObjective], charsmax(day[eDayObjective]))
  get_string(3, day[eDaySound], charsmax(day[eDaySound]))
  day[eDayMenuEntryID] = entryID;
  ArrayPushArray(g_days, day);

  // Pause Game Mode plugin after registering
  new filename[64]
  get_plugin(pluginID, filename, charsmax(filename))
  ArrayPushString(g_fileNames, filename)
  pause("ac", filename)
  //server_print("%s is now paused", filename)

  g_dayCount++
  return g_dayCount - 1;
}

public native_uj_days_get_id(pluginID, paramCount)
{
  new name[32];
  get_string(1, name, charsmax(name));

  new day[eDay];
  for(new i = 0; 0 < g_dayCount; ++i) {
    ArrayGetArray(g_days, i, day);
    if (equali(name, day[eDayName])) {
      return i;
    }
  }
  return UJ_DAY_INVALID;
}

public native_uj_days_get_current(pluginID, paramCount)
{
  return (g_dayCurrent >= 0) ? g_dayCurrent : UJ_DAY_INVALID;
}

public native_uj_days_start(pluginID, paramCount)
{
  new playerID = get_param(1);
  new dayID = get_param(2);

  // Check to see if dayID is even a valid day
  if (dayID >= 0 && dayID < g_dayCount) {
    start_day(playerID, dayID);
  }
}

public native_uj_days_end(pluginID, paramCount)
{
  end_current_day();
}

end_current_day()
{
  if (g_dayCurrent != UJ_DAY_INVALID) {
    new day[eDay];
    ArrayGetArray(g_days, g_dayCurrent, day);

    ExecuteForward(g_forwards[FW_DAY_END], g_forwardResult, g_dayCurrent);

    // Pause the day
    new filename[64]
    ArrayGetString(g_fileNames, g_dayCurrent, filename, charsmax(filename))
    pause("ac", filename)
    //server_print("%s is now paused", filename)

    fg_colorchat_print(0, FG_COLORCHAT_RED, "^4%s^1 is now over!", day[eDayName]);

    // Reallow healing and recharging
    uj_chargers_block_heal(0, false);
    uj_chargers_block_armor(0, false);

    g_dayCurrent = UJ_DAY_INVALID;
  }
}

/*
 * Menu forwards
 */
public uj_fw_menus_select_pre(playerID, menuID, entryID)
{
  new dayID = find_dayID(entryID);
  if (dayID < 0) { // not a day, do not block
    return UJ_MENU_AVAILABLE;
  }

  // Only available to live CTs
  if (!is_user_alive(playerID) || cs_get_user_team(playerID) != CS_TEAM_CT) {
    return UJ_MENU_DONT_SHOW;
  }

  // Unpause day in order to execute forward
  new filename[64]
  ArrayGetString(g_fileNames, dayID, filename, charsmax(filename))
  unpause("ac", filename)
  //server_print("%s is now unpaused", filename)

  // Execute item forward and store result
  ExecuteForward(g_forwards[FW_DAY_SELECT_PRE], g_forwardResult, playerID, dayID, menuID)

  // Repause if not the active day
  if (g_dayCurrent != dayID) {
    pause("ac", filename)
    //server_print("%s is now paused", filename)
  }

  if(g_forwardResult == UJ_DAY_NOT_AVAILABLE) {
    return UJ_MENU_NOT_AVAILABLE;
  }
  else if(g_forwardResult == UJ_DAY_DONT_SHOW) {
    return UJ_MENU_DONT_SHOW;
  }

  return UJ_MENU_AVAILABLE;
}

public uj_fw_menus_select_post(playerID, menuID, entryID)
{
  new dayID = find_dayID(entryID);
  if (dayID < 0) { // not an item, do not forward
    return;
  }

  // Unpause day in order to execute forward
  new filename[64]
  ArrayGetString(g_fileNames, dayID, filename, charsmax(filename))
  unpause("ac", filename)
  //server_print("%s is now unpaused", filename)

  // Before starting the day, check for validity one more time
  ExecuteForward(g_forwards[FW_DAY_SELECT_PRE], g_forwardResult, playerID, dayID, menuID)
  if (g_forwardResult != UJ_DAY_AVAILABLE) {
    // Repause if day is now invalid
    pause("ac", filename)
    //server_print("%s is now paused", filename)
    return;
  }

  start_day(playerID, dayID);
}


start_day(playerID, dayID)
{
  // End current day
  end_current_day();

  // Set new day
  g_dayCurrent = dayID;

  // Retrieve day data
  new day[eDay];
  ArrayGetArray(g_days, g_dayCurrent, day);

  // Play the day's sound
  play_day_sound(g_dayCurrent);

  // Open cell doors
  uj_cells_open_doors(0);

  // Display message
  new playerName[32];
  if (playerID > 0) {
    get_user_name(playerID, playerName, charsmax(playerName));  
  }
  else {
    copy(playerName, charsmax(playerName), FG_COLORCHAT_PREFIX_TEXT);
  }
  fg_colorchat_print(0, FG_COLORCHAT_BLUE, "Awesome! ^3%s^1 has started ^4%s^1! %s", playerName, day[eDayName], day[eDayObjective]);
  uj_logs_log("[uj_days] %s has started the day %s", playerName, day[eDayName]);

  // Unpause day in order to execute forward
  new filename[64]
  ArrayGetString(g_fileNames, dayID, filename, charsmax(filename))
  unpause("ac", filename)
  //server_print("%s is now unpaused", filename)

  // Execute day forward
  ExecuteForward(g_forwards[FW_DAY_SELECT_POST], g_forwardResult, playerID, g_dayCurrent);
}

play_day_sound(dayID)
{
  new day[eDay];
  ArrayGetArray(g_days, dayID, day);

  if(strlen(day[eDaySound])) {
    new soundPath[192];
    formatex(soundPath, charsmax(soundPath), "sound/%s", day[eDaySound]);
    client_cmd(0, "spk ^"%s^"", soundPath);
  }
}

stock find_dayID(entryID)
{
  new day[eDay];
  for (new dayID = 0; dayID < g_dayCount; ++dayID)
  {
    ArrayGetArray(g_days, dayID, day);
    if (entryID == day[eDayMenuEntryID]) {
      return dayID;
    }
  }
  return UJ_DAY_INVALID;
}

