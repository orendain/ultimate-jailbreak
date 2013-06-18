#if defined _uj_days_included
  #endinput
#endif
#define _uj_days_included

#include <uj_days_const>

#if AMXX_VERSION_NUM >= 175 
  #pragma reqlib uj_days
  #if !defined AMXMODX_NOAUTOLOAD
    #pragma loadlib uj_days
  #endif
#else
  #pragma library uj_days
#endif

/**
 * Registers a day into the uj_days system.
 * 
 * @param name            Name of the day. This will show up on menus.
 * @param objective       Objective that will show when day starts. Use "" for no objective.
 * @param sound           Sound that will play when a day is started. Use "" for no sound.
 *
 * @return                A unique dayID
 */
native uj_days_register(const name[], const objective[], const sound[]);

/**
 * Returns a day's unique ID.
 *
 * @param name    Exact name (case-insensitive) of the day to search for
 *
 * @return        An internal dayID, UJ_DAY_INVALID of none found
 */
native uj_days_get_id(const name[]);

/**
 * Starts a day.
 * 
 * @actions:
 *  + Open cells
 *  + Objective message is printed to all clients
 *  + Plays a day's registered day sound
 *
 * @param playerID      The player who is starting the day, or zero if none
 * @param dayID         The day to start
 *
 * @noreturn
 */
native uj_days_start(playerID, dayID);

/**
 * Returns the day that is currently in progress.
 *
 * @return      An internal dayID, or UJ_DAY_INVALID if none
 */
native uj_days_get_current();

/**
 * Forces the current day to end, if one is enabled.
 *
 * @noreturn
 */
native uj_days_end();


/**
 * Forwards
 */

/**
 * Called when determining whether a day should be made available
 *
 * Possible return values are:
 *  - UJ_DAY_AVAILABLE (show, allow selection)
 *  - UJ_DAY_NOT_AVAILABLE (show, don't allow selection)
 *  - UJ_DAY_DONT_SHOW (don't show, don't allow selection)
 *
 * @param playerID     Player index
 * @param dayID        Internal dayID
 * @param menuID       Internal menuID
 */
forward uj_fw_days_select_pre(playerID, dayID, menuID);

/**
 * Called after a player selects a day.
 *
 * @param playerID     Player index, or zero if started by the server
 * @param dayID        Internal dayID
 */
forward uj_fw_days_select_post(playerID, dayID);

/**
 * Called when the current day ends.
 *
 * @param dayID        Internal dayID of the current day
 */
forward uj_fw_days_end(dayID);
