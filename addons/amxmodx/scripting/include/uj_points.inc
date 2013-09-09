#if defined _uj_points_included
  #endinput
#endif
#define _uj_points_included

#if AMXX_VERSION_NUM >= 175 
  #pragma reqlib uj_points
  #if !defined AMXMODX_NOAUTOLOAD
    #pragma loadlib uj_points
  #endif
#else
  #pragma library uj_points
#endif

/**
 * Retrives the amount of points a player has.
 * 
 * @param playerID        Player index
 *
 * @noreturn
 */
native uj_points_get(playerID);

/**
 * Set a player's total points value
 *
 * @param playerID        Player index
 * @param amount          Number of points to set to
 *
 * @noreturn
 */
native uj_points_set(playerID, amount);

/**
 * Add points to a player's total.
 *
 * @param playerID        Player index
 * @param amount          Number of points to add
 *
 * @noreturn
 */
native uj_points_add(playerID, amount);

/**
 * Remove points from a player's total.
 *
 * @param playerID        Player index
 * @param amount          Number of points to remove
 *
 * @noreturn
 */
native uj_points_remove(playerID, amount);

/**
 * Force the system to save points immediately.
 *
 * @noreturn
 */
native uj_points_save();
