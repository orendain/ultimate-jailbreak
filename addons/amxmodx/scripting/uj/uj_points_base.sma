#include <amxmodx>
#include <uj_core>
#include <uj_points>
#include <fg_colorchat>
#include <uj_logs>

new const PLUGIN_NAME[] = "UJ | Points - Base";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

new const POINTS_PER_KILL[] = "1";
new const POINTS_PER_HEADSHOT[] = "1";
new const POINTS_PER_ROUND[] = "5";
//new const POINTS_MOST_KILLS[] = "20";
new const POINTS_LAST_REQUEST[] = "20";

new const POINTS_MINIMUM_GUARDS[] = "1";
new const POINTS_MINIMUM_PRISONERS[] = "2";

// CVars
new g_pointsPerKill;
new g_pointsPerHeadshot;
new g_pointsPerRound;
//new g_pointsMostKills;
new g_pointsLastRequest;
new g_pointsMinimumGuards;
new g_pointsMinimumPrisoners;

// Variables
new points;
new pointsGiven;
new g_minimumMet;
new pointsForRound;

public plugin_init()
{
  register_plugin(PLUGIN_NAME, PLUGIN_VERS, PLUGIN_AUTH);

  // Register CVars
  g_pointsPerKill = register_cvar("uj_points_base_per_kill", POINTS_PER_KILL);
  g_pointsPerHeadshot = register_cvar("uj_points_base_per_headshot", POINTS_PER_HEADSHOT);
  g_pointsPerRound = register_cvar("uj_points_base_per_round", POINTS_PER_ROUND);
  //g_pointsMostKills = register_cvar("uj_points_base_most_kills", POINTS_MOST_KILLS);
  g_pointsLastRequest = register_cvar("uj_points_base_last_request", POINTS_LAST_REQUEST);

  g_pointsMinimumGuards = register_cvar("uj_points_base_minimum_guards", POINTS_MINIMUM_GUARDS);
  g_pointsMinimumPrisoners = register_cvar("uj_points_base_minimum_prisoners", POINTS_MINIMUM_PRISONERS);

  // Track events
  register_event("DeathMsg", "FwPlayerKilled", "a")
  // New round
  register_event("HLTV", "event_new_round", "a", "1=0", "2=0");
  // Round end
  register_logevent("LogeventRoundEnd",   2, "1=Round_End");
}

public LogeventRoundEnd()
{
  if (g_minimumMet) {
    //points = get_pcvar_num(g_pointsPerRound);

    /*
    // Points to all who survived the round
    new players[32];
    new playerCount = uj_core_get_players(players, true);
    static playerID;

    for (new i = 0; i < playerCount; ++i) {
      playerID = players[i];
      fg_colorchat_print(playerID, FG_COLORCHAT_RED, "Way to survive the round!  Here, have ^4%i^1 points!", points);
      uj_points_add(playerID, points);
    }*/

    //static data[2];
    //data[1] = points;

    for (new playerID = 1; playerID <= 32; ++playerID) {
      if (is_user_alive(playerID)) {
        fg_colorchat_print(playerID, FG_COLORCHAT_RED, "Way to survive the round!  Here, have ^4%i^1 points!", pointsForRound);
        //uj_points_add(playerID, points);
        //data[0] = playerID;
        set_task(0.3 * playerID, "delay_give_points", playerID);
      }
    }
  }
}

public delay_give_points(playerID)
{
  // data[0] = playerID, data[1] = point
  // Make sure the user is connected before giving points
  if (is_user_connected(playerID)) {
    uj_points_add(playerID, pointsForRound);
  }
}

public FwPlayerKilled()
{
  if (g_minimumMet) {
    static killerID, victimID;
    killerID = read_data(1);
    victimID = read_data(2);

    // Server kill or self kill
    if (!killerID || (killerID == victimID)) {
      return;
    }

    //new headshot = read_data(3);

    points = 0;
    if (read_data(3)) {
      points = get_pcvar_num(g_pointsPerHeadshot);
      fg_colorchat_print(killerID, FG_COLORCHAT_RED, "BOOM, HEADSHOT! ^4%i^1 point bonus!", points);
    }

    points += get_pcvar_num(g_pointsPerKill);
    fg_colorchat_print(killerID, FG_COLORCHAT_RED, "Sweet kill! That's worth ^4%i^1 point(s)!", points);
    uj_points_add(killerID, points);
  }
}

is_minimum_met()
{
  static minimumGuards, minimumPrisoners;
  minimumGuards = uj_core_get_guard_count();
  minimumPrisoners = uj_core_get_prisoner_count();

  return (minimumGuards >= get_pcvar_num(g_pointsMinimumGuards) &&
      minimumPrisoners >= get_pcvar_num(g_pointsMinimumPrisoners));
}

public uj_fw_requests_reached(playerID)
{
  if (!pointsGiven && g_minimumMet) {
    pointsGiven = true;
    points = get_pcvar_num(g_pointsLastRequest);

    uj_points_add(playerID, points);
    fg_colorchat_print(playerID, FG_COLORCHAT_RED, "Last request, homie! ^4%i^1 points for you!", points);

    new playerName[32];
    get_user_name(playerID, playerName, charsmax(playerName));
    uj_logs_log("[uj_points_base] %s won last request and received %i points.", playerName, points);
  }
}

public event_new_round()
{
  pointsGiven = false;
  g_minimumMet = is_minimum_met();
  pointsForRound = get_pcvar_num(g_pointsPerRound);
}
