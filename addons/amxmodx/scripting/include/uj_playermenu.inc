#if defined _uj_playermenu_included
  #endinput
#endif
#define _uj_playermenu_included

#if AMXX_VERSION_NUM >= 175 
  #pragma reqlib uj_playermenu
  #if !defined AMXMODX_NOAUTOLOAD
    #pragma loadlib uj_playermenu
  #endif
#else
  #pragma library uj_playermenu
#endif


/**
 * Display a menu that lists teams all teams
 *
 * @param playerID   The player to display the menu to
 * @param showSpec   Whethor or not to include the spectator team
 *
 * @noreturn
 */
native uj_playermenu_show_teams(playerID, bool:showSpectatorTeam);

/**
 * Display a menu that lists players (filterable by team).
 *
 * @param playerID   The player to display the menu to
 * @param flags[]    Flags to pass onto get_players(), to filter the players listed
 * @param team[]     The team name to pass onto get_players(), if any ("CT", "TERRORIST" or "SPEC")
 *
 * @noreturn
 */
native uj_playermenu_show_team_players(playerID, const flags[], const team[]="");

/**
 * Display a menu that lists players whose player IDs are passed in as arguments.
 *
 * @param playerID   The player to display the menu to
 * @param players[]  The players to list in the menu
 *
 * @noreturn
 */
native uj_playermenu_show_players(playerID, const players[], playerCount);


/**
 * Forwards
 */

/**
 * Called when a player has made a player selection through uj_playermenu_show_menu()
 *
 * @param pluginID        The plugin that initiated the process
 * @param playerID        The player who made the selection.
 * @param teamID          The selected team (CS_TEAM_T, CS_TEAM_CT).
 */
forward uj_fw_playermenu_team_select(pluginID, playerID, targetID);

/**
 * Called when a player has made a player selection through uj_playermenu_show_menu()
 *
 * @param pluginID        The plugin that initiated the process
 * @param playerID        The player who made the selection.
 * @param targetID        The selected player.
 */
forward uj_fw_playermenu_player_select(pluginID, playerID, targetID);
