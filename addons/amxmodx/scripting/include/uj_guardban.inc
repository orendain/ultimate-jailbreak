#if defined _uj_guardban_included
  #endinput
#endif
#define _uj_guardban_included

#if AMXX_VERSION_NUM >= 175 
  #pragma reqlib uj_guardban
  #if !defined AMXMODX_NOAUTOLOAD
    #pragma loadlib uj_guardban
  #endif
#else
  #pragma library uj_guardban
#endif

/**
 * Natives
 */

/**
 * Guardban a player
 * 
 * @param playerID    The player to ban
 * @param reason      The reason player is being banned
 *
 * @return            True on success, false on failure
 */
native uj_guardban_ban(const playerID, const reason[]);

/**
 * Unguardban a player
 * 
 * @param playerID    The player to unban
 *
 * @return            True on success, false on failure
 */
native uj_guardban_unban(const playerID);

/**
 * Check if player is guardbanned
 * 
 * @param playerID    The player to check for
 *
 * @return            True if user is guardbanned, false otherwise
 */
native uj_guardban_is_banned(const playerID);

/**
 * Find the reason for a player being banned
 * 
 * @param playerID      The banned player
 * @param reason        The array to store the reason in.
 * @param reasonLength  Maximum number of characers to use for the reason
 *
 * @return              True if the player was banned and a reason found, false otherwise.
 */
native uj_guardban_get_reason(const playerID, reason[], reasonLength);


/*
 * Forwards
 */

/**
 *
 * Called when a guardbanned player attempted to join the guard team.
 *
 * @param playerID      The index of the guardbanned player
 *
 * @return              Return values are ignored.
 *
 */
forward uj_fw_guardban_join_attempt(const playerID);
