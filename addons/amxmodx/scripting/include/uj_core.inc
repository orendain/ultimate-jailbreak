#if defined _uj_core_included
  #endinput
#endif
#define _uj_core_included

#include <cstrike>
#include <uj_core_const>

#if AMXX_VERSION_NUM >= 175 
  #pragma reqlib uj_core
  #if !defined AMXMODX_NOAUTOLOAD
    #pragma loadlib uj_core
  #endif
#else
  #pragma library uj_core
#endif

/**
 * Natives
 */

/**
 * Open all cell doors.
 *
 * @param playerID  The player to block or allow, or 0 for all
 *
 * @noreturn
 */
native uj_core_open_cell_doors(playerID);

/**
 * Block the ability to pickup weapons.
 *
 * @param playerID  The player to block or allow, or 0 for all
 * @param allow     True to block weapon pickup, false to allow it.
 *
 * @noreturn
 */
native uj_core_block_weapon_pickup(playerID, bool:block);

/**
 * Check to see if weapon pickup is blocked.
 *
 * @param playerID  The player to enquire about, or 0 for all
 *
 * @return          True if weapon pickup is blocked, false otherwise.
 */
native uj_core_get_weapon_pickup(playerID);

/**
 * Set friendly fire
 *
 * @param enabled   True to enable friendly fire, false to disable it.
 *
 * @noreturn
 */
native uj_core_set_friendly_fire(bool:enabled);

/**
 * Removes all glow effects from a player.
 *
 * @param playerID           Player index
 * @param give_knife   Whethor or not the player should be given a knife after stripped
 *
 * @noreturn
 */
native uj_core_strip_weapons(playerID, bool: give_knife = true);

/**
 * Determine a player's maximum health and have pev_max_health reflect that.
 *
 * @param playerID        Player index
 * @param health          The variable to store the player's max health
 */
native uj_core_determine_max_health(playerID, &health);

/**
 * Get number of players.  Replacement for get_players()
 *
 * @param players        Array to store playerIDs in
 * @param aliveOnly      True to find only living players, false otherwise.
 * @param CSTeam         The team, if any, to filter to. (see CsTeams enum in cstrike module)
 *
 * @return               The number of players returned.
 */
native uj_core_get_players(players[], bool:aliveOnly=false, CsTeams:CSTeam=CS_TEAM_UNASSIGNED);

/**
 * Get the number of prisoners
 */
native uj_core_get_prisoner_count();

/**
 * Get the number of live prisoners
 */
native uj_core_get_live_prisoner_count();

/**
 * Get the number of guards
 */
native uj_core_get_guard_count();

/**
 * Get the number of live guards
 */
native uj_core_get_live_guard_count();


/**
 * Forwards
 */

/**
 * Called when a new round is started.
 */
//forward uj_fw_core_round_new();

/**
 * Called each time a player is spawned.
 *
 * @param playerID          Player index.
 */
//forward uj_fw_core_player_spawn(playerID);

/**
 * Called when a round starts (after mp_freezetime)
 */
//forward uj_fw_core_round_start();

/**
 * Called when a round ends.
 */
//forward uj_fw_core_round_end();

/*
 * Called when determining a player's maximum health points.
 *
 * @param playerID          The player in question
 * @param dataArray         dataArray[0] should be checked/changed to reflect a
 *                          user's max health
 */
forward uj_fw_core_get_max_health(playerID, dataArray[]);

/*
 * Called when determing changes to damage a player has caused or taken.
 *
 * @param victimID          The victim in the exchange
 * @param inflictorID       The inflictor in the exchange
 * @param attackerID        The attacker in the exchange
 * @param originalDamage    The amount of damage initially computed, not adjusted for armor, etc.
 * @param damagebits        The damagebits set
 * @param dataArray         dataArray[0] should be checked/changed to reflect the damage that should be taken
 */
forward uj_fw_core_get_damage_taken(victimID, inflictorID, attackerID, float:originalDamage, damagebits, dataArray[]);

/*
 * Called when cell doors are opened.
 *
 * @param activateorID       The entity that activated this door (could be a player)
 */
forward uj_fw_core_cell_doors_opened(activatorID);
