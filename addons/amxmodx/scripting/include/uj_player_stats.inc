#if defined _uj_player_stats_included
  #endinput
#endif
#define _uj_player_stats_included

#if AMXX_VERSION_NUM >= 175 
  #pragma reqlib uj_player_stats
  #if !defined AMXMODX_NOAUTOLOAD
    #pragma loadlib uj_player_stats
  #endif
#else
  #pragma library uj_player_stats
#endif


/**
 * Find a player's last known name
 *
 * @param authID[]          The authID of the player to look up
 * @param playerName[]      The argument to store the player's name in
 * @param playerNameLength  The max number of characters to store in playerName[]
 *
 * @noreturn
 */
native uj_player_stats_get_name(authID[], playerName[], playerNameLength);
