#include <amxmodx>
#include <fakemeta>
#include <fg_colorchat>
#include <uj_logs>
#include <uj_menus>
#include <uj_points>

new const PLUGIN_NAME[] = "UJ | Fun - Point Raffle";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

new const MENU_NAME[] = "Point Raffle";
new const POINT_RAFFLE_URL[] = "http://www.factorialgaming.com/files/jailbreak/raffle_rules.html";

new const RAFFLE_TIME[] = "4";

// CS Player PData Offsets (win32)
new const OFFSET_CSMENUCODE = 205

#define MAX_PLAYERS 32
#define AUTH_SIZE 32
#define RAFFLE_TASKID 73212

new g_entryID;
new g_menuFun;

new g_timePCVar;
new Float:g_timeStarted;
new Float:raffleTime;

new g_playerBets[MAX_PLAYERS + 1];
new g_authIDs[MAX_PLAYERS + 1][AUTH_SIZE+1];
new g_raffleStarted;
new g_totalPoints;

public plugin_init()
{
  register_plugin(PLUGIN_NAME, PLUGIN_VERS, PLUGIN_AUTH);

  // Register a menu entry
  g_entryID = uj_menus_register_entry(MENU_NAME);

  // Find the menus this should display in
  g_menuFun = uj_menus_get_menu_id("Fun");

  // Cvars
  g_timePCVar = register_cvar("uj_fun_pointraffle", RAFFLE_TIME);

  // Commands
  register_clcmd("Raffle_Tickets_To_Buy", "enter_bet");

  reset_raffle();
}

public uj_fw_menus_select_pre(playerID, menuID, entryID)
{
  // This is not our item - do not block
  if (entryID != g_entryID)
    return UJ_MENU_AVAILABLE;

  // Do not show if it is not in this specific parent menu
  if (menuID != g_menuFun)
    return UJ_MENU_DONT_SHOW;
  
  return UJ_MENU_AVAILABLE;
}

public uj_fw_menus_select_post(playerID, menuid, entryID)
{
  // This is not our item
  if (g_entryID != entryID)
    return;
  
  // Display our menu
  show_raffle_menu(playerID);
}

public plugin_end()
{
  if (g_raffleStarted) {
    uj_logs_log("[uj_fun_pointraffle] Plugin ending before raffle could end! Total points: %i", g_totalPoints);
  }
}

show_raffle_menu(playerID)
{
  // Title
  new menuID = menu_create(MENU_NAME, "menu_handler");
  
  // List all the menu items
  menu_additem(menuID, "Buy Raffle Tickets");
  menu_additem(menuID, "View Current Raffle");
  menu_additem(menuID, "How It Works");

  // Fix for AMXX custom menus
  set_pdata_int(playerID, OFFSET_CSMENUCODE, 0);
  menu_display(playerID, menuID, 0);
}

public menu_handler(playerID, menuID, entrySelected)
{
  // Menu was closed
  if (entrySelected == MENU_EXIT) {
    menu_destroy(menuID);
    return PLUGIN_HANDLED;
  }

  menu_destroy(menuID);

  switch (entrySelected) {
    case 0: {
      client_cmd(playerID, "messagemode Raffle_Tickets_To_Buy");
    }
    case 1: {
      display_players(playerID);
    }
    case 2: {
      show_motd(playerID, POINT_RAFFLE_URL, "FG | Point Raffle Rules");
    }
  }
  
  return PLUGIN_HANDLED;
}

display_players(playerID)
{
  if (!g_raffleStarted) {
    fg_colorchat_print(playerID, FG_COLORCHAT_RED, "A raffle has not yet been started! Buy tickets to get it going!");
    return;
  }

  new szMessage[2048];
  formatex(szMessage, charsmax(szMessage), "<body bgcolor=#FFFFFF color=#3D3D3D font-size=18px><pre>");
  format(szMessage, charsmax(szMessage), "%s^n%32s - %13s^n", szMessage, "Raffle Player", "# of Tickets");
  
  new pointsBet;
  new playerName[32];
  for (new playerID = 1; playerID <= MAX_PLAYERS; ++playerID) {
    pointsBet = g_playerBets[playerID];
    if (!pointsBet) {
      continue;
    }
    get_user_name(playerID, playerName, 31);
    format(szMessage, charsmax(szMessage), "%s^n%32s - %13i", szMessage, playerName, g_playerBets[playerID]);
  }

  format(szMessage, charsmax(szMessage), "%s^n^nTotal Points in Pot: %i!", szMessage, g_totalPoints);

  show_motd(playerID, szMessage, "Current Raffle Details");
}

reset_raffle()
{
  for (new i = 1 ; i <= MAX_PLAYERS; ++i) {
    g_playerBets[i] = 0;
    g_authIDs[i] = "";
  }

  g_raffleStarted = false;
  g_totalPoints = 0;
}

start_raffle()
{
  g_raffleStarted = true;
  raffleTime = get_pcvar_num(g_timePCVar) * 60.0;
  g_timeStarted = get_gametime();

  if (raffleTime > 60.0) {
    set_task(60.0, "announce_raffle_time");
  }

  fg_colorchat_print(0, FG_COLORCHAT_RED, "A raffle has been started!  Feeling lucky?  ^3Join in!^1");
  set_task(raffleTime, "execute_raffle", RAFFLE_TASKID);
}

public announce_raffle_time()
{
  new secondsLeft = floatround((g_timeStarted + raffleTime) - get_gametime());
  fg_colorchat_print(0, FG_COLORCHAT_RED, "Raffle Status: ^3%i-point jackpot^1 with ^3%i seconds left^1!", g_totalPoints, secondsLeft);
  
  if (secondsLeft >= 70) {
    set_task(60.0, "announce_raffle_time");
  }
  /*else if (secondsLeft > 40) {
    set_task(30.0, "announce_raffle_time");
  }*/
}

public execute_raffle()
{
  fg_colorchat_print(0, FG_COLORCHAT_RED, "^3Raffle Time^1!  Mixing up tickets and picking one at random ...");
  set_task(5.0, "pick_raffle_winner");
}

public pick_raffle_winner()
{
  new winningNumber = random(g_totalPoints);
  fg_colorchat_print(0, FG_COLORCHAT_RED, "The raffle jackpot goes to ^3Ticket #%i^1!", winningNumber+1);

  new pointsBet;
  for (new playerID = 1; playerID <= MAX_PLAYERS; ++playerID) {
    
    pointsBet = g_playerBets[playerID];
    if (!pointsBet) {
      continue;
    }

    if (winningNumber < pointsBet) {
      award_player(playerID);
      break;
    }
    else {
      winningNumber -= pointsBet;
    }
  }

  reset_raffle();
}

award_player(playerID)
{
  new currentAuthID[AUTH_SIZE+1];
  get_user_authid(playerID, currentAuthID, AUTH_SIZE);

  if (!is_user_connected(playerID) || !equali(currentAuthID, g_authIDs[playerID])) {
    fg_colorchat_print(0, FG_COLORCHAT_RED, "The winner, [^3%s^1], has left the server and will get their points when they get bacK!", g_authIDs[playerID]);
    uj_logs_log("[uj_fun_pointraffle] <%s> won %i points but was not in server.", g_authIDs[playerID], g_totalPoints);
  }
  else {
  // Announce winner
  new playerName[32];
  get_user_name(playerID, playerName, 31);
  fg_colorchat_print(0, playerID, "^4%s^1 won ^3%i points^1 by buying ^3%i raffle tickets^1!", playerName, g_totalPoints, g_playerBets[playerID]);

  // Award points
  uj_points_add(playerID, g_totalPoints);
  uj_logs_log("[uj_fun_pointraffle] %s <%s> won and was awarded %i points.", playerName, g_authIDs[playerID], g_totalPoints);
  }
}

public enter_bet(playerID)
{
  new pointStr[16];
  read_argv(1, pointStr, charsmax(pointStr));

  new points = str_to_num(pointStr);

  if (points <= 0) {
    fg_colorchat_print(playerID, FG_COLORCHAT_RED, "Whoops, that's not a valid point value!");
  }
  else if (uj_points_get(playerID) >= points) {
    // Remove user pointsf
    uj_points_remove(playerID, points);

    // Save user's bet
    g_playerBets[playerID] += points;
    g_totalPoints += points;
    get_user_authid(playerID, g_authIDs[playerID], AUTH_SIZE);

    // Start a raffle if one hasn't been started
    if (!g_raffleStarted) {
      start_raffle();
    }

    new playerName[32];
    get_user_name(playerID, playerName, 31);
    fg_colorchat_print(0, FG_COLORCHAT_RED, "^4%s^1 has purchased ^3%i raffle tickets^1, for a total of ^3%i tickets^1!", playerName, points, g_playerBets[playerID]);
    fg_colorchat_print(0, FG_COLORCHAT_RED, "The ^4Raffle Jackpot^1 is now up to ^3%i points^1!", g_totalPoints);

    // Log bet
    uj_logs_log("[uj_fun_pointraffle] %s <%s> has bet %i points for a total bet of %i (jackpot now set at %i points)", playerName, g_authIDs[playerID], points, g_playerBets[playerID], g_totalPoints);
  }
  else {
    fg_colorchat_print(playerID, FG_COLORCHAT_RED, "Check yo' self homie, you can't afford that!");
  }
}
