#if defined _uj_freedays_included
  #endinput
#endif
#define _uj_freedays_included

#if AMXX_VERSION_NUM >= 175 
  #pragma reqlib uj_freedays
  #if !defined AMXMODX_NOAUTOLOAD
    #pragma loadlib uj_freedays
  #endif
#else
  #pragma library uj_freedays
#endif

/**
 * Natives
 */

/**
 * Gives a player a freeday.
 *
 * @param playerID  Player index.
 *
 * @noreturn
 */
native uj_freedays_give(playerID);

/**
 * Removes a player's freeday.
 *
 * @param playerID        Player index, or 0 for all
 *
 * @noreturn
 */
native uj_freedays_remove(playerID);

/**
 * Check to see if a player has an active freeday.
 *
 * @param playerID        Player index
 *
 * @return                True if the user has an active freeday, false otherwise
 */
native uj_freedays_has_freeday(playerID);

/**
 * Check to see how many players have active freedays.
 *
 * @return      The number of currently active freedays.
 */
native uj_freedays_get_count();
