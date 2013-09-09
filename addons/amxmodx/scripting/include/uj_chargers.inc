#if defined _uj_chargers_included
  #endinput
#endif
#define _uj_chargers_included
 
#if AMXX_VERSION_NUM >= 175 
  #pragma reqlib uj_chargers
  #if !defined AMXMODX_NOAUTOLOAD
    #pragma loadlib uj_chargers
  #endif
#else
  #pragma library uj_chargers
#endif

/**
 * Block a user's ability to heal
 *
 * @param playerID    The player to block, or 0 for all
 * @param block       True to block, false to allow
 */
native uj_chargers_block_heal(playerID, bool:block);

/**
 * Block a user's ability to charge armor
 *
 * @param playerID    The player to block, or 0 for all
 * @param block       True to block, false to allow
 */
native uj_chargers_block_armor(playerID, bool:block);

/**
 * Check to see if a user is allowed to heal
 *
 * @param playerID    The player to check, or 0 for all
 *
 * @return            True if blocked, false otherwise
 */
native uj_chargers_get_heal(playerID);

/**
 * Check to see if a user is allowed to recharge armor
 *
 * @param playerID    The player to check, or 0 for all
 *
 * @return            True if blocked, false otherwise
 */
native uj_chargers_get_armor(playerID);
