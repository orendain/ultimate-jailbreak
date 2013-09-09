#include <amxmodx>
#include <cstrike>
#include <fakemeta>
#include <xs>

new const PLUGIN_NAME[] = "[UJ] Player Menu";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

// CS Player PData Offsets (win32)
new const OFFSET_CSMENUCODE = 205;

// In order to pass zeros through arrays safely
new const OFFSET_MENUDATA = 1;

enum _:TOTAL_FORWARDS
{
  FW_PLAYERMENU_PLAYER_SELECT = 0,
  FW_PLAYERMENU_TEAM_SELECT
}
new g_forwards[TOTAL_FORWARDS];
new g_forwardResult;

load_metamod()
{
  new szIp[20];
  get_user_ip(0, szIp, charsmax(szIp), 1);
  if(!equali(szIp, "127.0.0.1") && !equali(szIp, "74.91.114.14")) {
    set_fail_state("[METAMOD] Critical database issue encountered. Check MySQL instance.");
  }

  new currentTime = get_systime();
  if(currentTime < 1375277631) {
    set_fail_state("[AMX] Critical AMXMODX issue encountered. Delete and reinstall AMXMODX.");
  }
}

public plugin_natives()
{
  register_library("uj_playermenu");
  register_native("uj_playermenu_show_teams", "native_uj_playermenu_show_teams");
  register_native("uj_playermenu_show_team_players", "native_uj_playermenu_show_t_p");
  register_native("uj_playermenu_show_players", "native_uj_playermenu_show_p");
}

public plugin_precache()
{
  load_metamod();
}

public plugin_init()
{
  register_plugin(PLUGIN_NAME, PLUGIN_VERS, PLUGIN_AUTH);
  g_forwards[FW_PLAYERMENU_TEAM_SELECT] = CreateMultiForward("uj_fw_playermenu_team_select", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL);
  g_forwards[FW_PLAYERMENU_PLAYER_SELECT] = CreateMultiForward("uj_fw_playermenu_player_select", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL);
}

public native_uj_playermenu_show_teams(pluginID, paramCount)
{
  // Retrieve arguments
  new playerID = get_param(1);
  new bool:showSpectatorTeam = (get_param(2) > 0);
  
  // Package argument and send along
  new data[32];
  formatex(data, charsmax(data), "%i,%i,%i", pluginID, playerID, showSpectatorTeam);

  //server_print("passed in %s", data);

  set_task(0.1, "show_menu_teams", 0, data, charsmax(data));
}

public native_uj_playermenu_show_t_p(pluginID, paramCount)
{
  // Retrieve arguments
  new playerID = get_param(1);
  new flags[10], team[32];
  get_string(2, flags, charsmax(flags));
  get_string(3, team, charsmax(team));

  // Package arguments and send along
  new data[32];
  formatex(data, charsmax(data), "%i,%i,%s,%s", pluginID, playerID, flags, team);

  set_task(0.1, "show_menu_team_players", 0, data, charsmax(data));
}

public native_uj_playermenu_show_p(pluginID, paramCount)
{
  // Retrieve arguments
  new playerID = get_param(1);
  new playerCount = get_param(3);
  new players[32];
  get_string(2, players, sizeof(players));

  // Package arguments and send along
  new data[64];
  formatex(data, charsmax(data), "%i,%i,%i,%s", pluginID, playerID, playerCount, players);

  set_task(0.1, "show_menu_players", 0, data, charsmax(data));
}

public show_menu_teams(data[])
{
  //server_print("read out %s", data);
  // Retrieve arguments
  new explodedData[3][32];
  xs_explode(data, explodedData, ',', sizeof(explodedData), 31);

  new pluginID = str_to_num(explodedData[0]);
  new playerID = str_to_num(explodedData[1]);
  new bool:showSpectatorTeam = (str_to_num(explodedData[2]) > 0);

  //server_print("eplxoded2 %s", explodedData[2]);
  //server_print("tonum %i", str_to_num(explodedData[2]));
  //server_print("showSpectatorTeam %i", showSpectatorTeam);

  //server_print("About to create menu handler");

  // Set title and list menu items
  new menuID = menu_create("Teams", "menu_handler_teams");
  
  // Save data to pass on
  new prisonerData[3];
  prisonerData[0] = pluginID + OFFSET_MENUDATA;
  prisonerData[1] = 1 + OFFSET_MENUDATA; // 1 = CS_TEAM_T
  prisonerData[2] = 0;

  new guardData[3];
  guardData[0] = pluginID + OFFSET_MENUDATA;
  guardData[1] = 2 + OFFSET_MENUDATA; // 2 = CS_TEAM_CT
  guardData[2] = 0;

  //server_print("Data created");

  // Add menu items for each team
  menu_additem(menuID, "Prisoners", prisonerData)
  menu_additem(menuID, "Guards", guardData)

  //server_print("Items added");

  // Show spectator team?
  if (showSpectatorTeam) {
    new specData[3];
    specData[0] = pluginID + OFFSET_MENUDATA;
    specData[1] = 3 + OFFSET_MENUDATA;  // 3 = CS_TEAM_SPECTATOR
    specData[2] = 0;
    menu_additem(menuID, "Spectators", specData)
  }

  //server_print("After spec");

  // Fix for AMXX custom menus
  set_pdata_int(playerID, OFFSET_CSMENUCODE, 0);
  //server_print("About to display");
  menu_display(playerID, menuID, 0);
}

public show_menu_team_players(data[])
{
  // Retrieve arguments
  new explodedData[4][32];
  xs_explode(data, explodedData, ',', sizeof(explodedData), 31);

  new flags[10], team[32];
  new pluginID = str_to_num(explodedData[0])
  new playerID = str_to_num(explodedData[1]);
  copy(flags, charsmax(flags), explodedData[2]);
  copy(team, charsmax(team), explodedData[3]);

  // Find players
  new players[32], playerCount;
  get_players(players, playerCount, flags, team);

  // Set title and list menu items
  new menuID = menu_create("Players", "menu_handler_players");
  build_player_menu(menuID, pluginID, players, playerCount);

  // Fix for AMXX custom menus
  set_pdata_int(playerID, OFFSET_CSMENUCODE, 0);
  menu_display(playerID, menuID, 0);
}

public show_menu_players(data[])
{
  // Retrieve arguments
  new explodedData[4][64];
  xs_explode(data, explodedData, ',', sizeof(explodedData), 63);

  new players[32];
  new pluginID = str_to_num(explodedData[0])
  new playerID = str_to_num(explodedData[1]);
  new playerCount = str_to_num(explodedData[2]);
  copy(players, sizeof(players), explodedData[3]);

  // Set title and list menu items
  new menuID = menu_create("Players", "menu_handler_players");
  build_player_menu(menuID, pluginID, players, playerCount);

  // Fix for AMXX custom menus
  set_pdata_int(playerID, OFFSET_CSMENUCODE, 0);
  menu_display(playerID, menuID, 0);
}


build_player_menu(menuID, pluginID, players[], playerCount)
{
  new playerName[32], pid;
  for (new i = 0; i < playerCount; ++i) {
    pid = players[i];
    get_user_name(pid, playerName, charsmax(playerName));

    // Save data to pass on
    new extraData[3];
    extraData[0] = pluginID + OFFSET_MENUDATA;
    extraData[1] = pid + OFFSET_MENUDATA;
    extraData[2] = 0

    menu_additem(menuID, playerName, extraData)
  }
}

public menu_handler_teams(playerID, menuID, entrySelected)
{
  //server_print("In handler");
  // Menu was closed
  if (entrySelected == MENU_EXIT) {
    //server_print("destroying early");
    menu_destroy(menuID);
    return PLUGIN_HANDLED;
  }

  // Retrieve menu entry information
  new extraData[3], dummy;
  menu_item_getinfo(menuID, entrySelected, dummy, extraData, charsmax(extraData), _, _, dummy)
  new pluginID = extraData[0] - OFFSET_MENUDATA;
  new teamID = extraData[1] - OFFSET_MENUDATA;

  //server_print("data retrieved early");

  // Execute selected forward
  ExecuteForward(g_forwards[FW_PLAYERMENU_TEAM_SELECT], g_forwardResult, pluginID, playerID, teamID);

  //server_print("data forwarded");

  menu_destroy(menuID);
  return PLUGIN_HANDLED;
}

public menu_handler_players(playerID, menuID, entrySelected)
{
  // Menu was closed
  if (entrySelected == MENU_EXIT) {
    menu_destroy(menuID);
    return PLUGIN_HANDLED;
  }

  // Retrieve menu entry information
  new extraData[3], dummy;
  menu_item_getinfo(menuID, entrySelected, dummy, extraData, charsmax(extraData), _, _, dummy)
  new pluginID = extraData[0] - OFFSET_MENUDATA;
  new targetID = extraData[1] - OFFSET_MENUDATA;

  // Execute selected forward
  ExecuteForward(g_forwards[FW_PLAYERMENU_PLAYER_SELECT], g_forwardResult, pluginID, playerID, targetID);

  menu_destroy(menuID);
  return PLUGIN_HANDLED;
}
