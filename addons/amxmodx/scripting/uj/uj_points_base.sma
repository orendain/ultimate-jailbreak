#include <amxmodx>
#include <uj_core>
#include <uj_points>
#include <uj_colorchat>

new const PLUGIN_NAME[] = "[UJ] Points - Base";
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
}

public uj_fw_core_round_end()
{
  if (is_minimum_met()) {
    points = get_pcvar_num(g_pointsPerRound);

    // Points to all who survived the round
    new players[32];
    new playerCount = uj_core_get_players(players, true);

    for (new i = 0; i < playerCount; ++i) {
      uj_points_add(players[i], points);
      uj_colorchat_print(players[i], players[i], "Way to survive the round!  Here, have ^4%i^1 points!", points);
    }
  }
}

public FwPlayerKilled()
{
  if (is_minimum_met()) {
    static killerID, victimID, headshot;
    killerID = read_data(1);
    victimID = read_data(2);

    // Server kill or self kill
    if (!killerID || (killerID == victimID)) {
      return;
    }

    headshot = read_data(3);

    points = get_pcvar_num(g_pointsPerKill);

    uj_points_add(killerID, points);
    uj_colorchat_print(killerID, killerID, "Sweet kill! That's worth ^4%i^1 point(s)!", points);

    if (headshot) {
      points = get_pcvar_num(g_pointsPerHeadshot);
      uj_points_add(killerID, points);
      uj_colorchat_print(killerID, killerID, "BOOM, HEADSHOT! ^4%i^1 point bonus!", points);
    }
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
  if (is_minimum_met()) {
    points = get_pcvar_num(g_pointsLastRequest);

    uj_points_add(playerID, points);
    uj_colorchat_print(playerID, playerID, "Last request, homie! ^4%i^1 points for you!", points);
  }
}
