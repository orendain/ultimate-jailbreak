#include <amxmodx>
#include <cstrike>
#include <fun>
#include <fg_colorchat>
#include <uj_core>
#include <uj_days>
#include <uj_effects>
#include <uj_menus>

new const PLUGIN_NAME[] = "UJ | Day - Timebombs";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

new const DAY_NAME[] = "Timebombs";
new const DAY_OBJECTIVE[] = "Do you hazz a bomb?! Quick, loco, pass it along!";
new const DAY_SOUND[] = "";

new const BOMB_TIMER[] = "60.0";
new const BOMB_SPEED[] = "1.2";

// Day variables
new g_day;
new bool:g_dayEnabled;
new g_hasBomb;

// Menu variables
new g_menuSpecial;

// Cvars
new g_bombTimerPCVar;
new g_speedPCVar;

public plugin_init()
{
  register_plugin(PLUGIN_NAME, PLUGIN_VERS, PLUGIN_AUTH);

  // Find all valid menus to display this under
  g_menuSpecial = uj_menus_get_menu_id("Special Days");

  // CVars
  g_bombTimerPCVar = register_cvar("uj_day_bombpass_bomb_timer", BOMB_TIMER);
  g_speedPCVar = register_cvar("uj_day_bombpass_speed", BOMB_SPEED);

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

  // There must be at least 2 prisoners alive to start this day.
  if (uj_core_get_live_prisoner_count() < 2) {
    return UJ_DAY_NOT_AVAILABLE;
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
    set_task(3.0, "setup_bombs");

    new players[32];
    new playerCount = uj_core_get_players(players, true, CS_TEAM_CT);
    for (new i = 0; i < playerCount; ++i) {
      set_user_godmode(players[i], 1);
    }
  }
}

public setup_bombs()
{
  if (!g_dayEnabled) {
    return;
  }

  g_hasBomb = 0;

  // Find settings
  new Float:bombTimer = get_pcvar_float(g_bombTimerPCVar);

  new players[32], playerID;
  new playerCount = uj_core_get_players(players, true, CS_TEAM_T);
  new playersLeft = playerCount;
  new bombCount = (playerCount+1) / 2;
  new playerName[32];
  for (new i = 0; i < playerCount; ++i) {
    playerID = players[i];

    uj_core_strip_weapons(playerID);
    uj_core_block_weapon_pickup(playerID, true);

    if (bombCount >= playersLeft || (bombCount && random(2))) {
      //give_item(playerID, "weapon_c4")
      give_bomb(playerID);

      get_user_name(playerID, playerName, charsmax(playerName));
      //fg_colorchat_print(0, FG_COLORCHAT_RED, "Oh, dang! ^3%s^1 has been given a ^3bomb^1!", playerName)
      --bombCount;
    }

    --playersLeft;
  }

  fg_colorchat_print(0, FG_COLORCHAT_RED, "Time until all bombs explode: ^3%.2f seconds^1!", bombTimer)
  set_task(bombTimer, "detonate_bomb");
}

give_bomb(playerID)
{
  set_bit(g_hasBomb, playerID);
  uj_effects_glow_player(playerID, 255, 0, 0, 16);
  uj_effects_reset_max_speed(playerID);
}

remove_bomb(playerID)
{
  clear_bit(g_hasBomb, playerID);
  uj_effects_glow_reset(playerID);
  uj_effects_reset_max_speed(playerID);
}

public detonate_bomb()
{
  if (!g_dayEnabled) {
    return;
  }

  fg_colorchat_print(0, FG_COLORCHAT_RED, "Hey, bomb holders! Time ... to ... ^3DIE^1!")

  new players[32], playerID;
  new playerCount = uj_core_get_players(players, true, CS_TEAM_T);
  new playersLeft = playerCount;
  for (new i = 0; i < playerCount; ++i) {
    playerID = players[i];
    if (get_bit(g_hasBomb, playerID)) {
      uj_effects_rocket(playerID);
      --playersLeft;
    }
  }

  // Prepare for the next round
  if (playersLeft >= 2) {
    set_task(5.0, "setup_bombs");
  }


  // Continue this day only if prisoner count >= 2

  /*else {
    uj_days_end();
  }*/
}

end_day()
{
  new players[32];
  new playerCount = uj_core_get_players(players, true, CS_TEAM_T);
  for (new i = 0; i < playerCount; ++i) {
    remove_bomb(players[i]);
  }

  playerCount = uj_core_get_players(players, false, CS_TEAM_CT);
  for (new i = 0; i < playerCount; ++i) {
    set_user_godmode(players[i]); // Disables godmode
  }

  g_dayEnabled = false;
  uj_core_block_weapon_pickup(0, false);
}

// Called when determining the final damage to compute
public uj_fw_core_get_damage_taken(victimID, inflictorID, attackerID, float:originalDamage, damagebits, data[])
{
  if (g_dayEnabled && (1<=attackerID<=32) &&
      (cs_get_user_team(victimID) == CS_TEAM_T) &&
      get_bit(g_hasBomb, attackerID) &&
      (!get_bit(g_hasBomb, victimID)) &&
      (attackerID == inflictorID) &&
      (get_user_weapon(attackerID) == CSW_KNIFE)) {
        remove_bomb(attackerID);
        give_bomb(victimID);

        new attackerName[32], victimName[32];
        get_user_name(attackerID, attackerName, charsmax(attackerName));
        get_user_name(victimID, victimName, charsmax(victimName));
        fg_colorchat_print(0, FG_COLORCHAT_RED, "^3%s^1 has passed a bomb to ^3%s^1!", attackerName, victimName);
  }
}

/*
 * Called when determining a player's max speed
 */
public uj_effects_determine_max_speed(playerID, data[])
{
  if (g_dayEnabled && get_bit(g_hasBomb, playerID)) {
    new Float:result = float(data[0]);
    result *= get_pcvar_float(g_speedPCVar);
    data[0] = floatround(result);
    //fg_colorchat_print(playerID, playerID, "survival speed is %f", data[0]);
  }
}
