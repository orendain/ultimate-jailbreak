#if defined _uj_gangs_included
  #endinput
#endif
#define _uj_gangs_included

#include <uj_gangs_const>

#if AMXX_VERSION_NUM >= 175 
  #pragma reqlib uj_gangs
  #if !defined AMXMODX_NOAUTOLOAD
    #pragma loadlib uj_gangs
  #endif
#else
  #pragma library uj_gangs
#endif

/**
 * Create a new Gang to store in the system
 *
 * @param playerID      Creator (and now leader) of the gang
 * @param name          Name of the gang
 *
 * @return              An internal, unique, persistant gang ID, or UJ_GANG_INVALID on failure.
 */
native uj_gangs_create_gang(playerID, const gangName[]);

/**
 * Create a new Gang to store in the system
 *
 * @param gangID      The ID of the gang to destroy
 *
 * @noreturn
 */
native uj_gangs_destroy_gang(gangID);

/*
 * Total number of gangs that have been registered, including destroyed gangs.
 *
 * @return        Gang count
 */
native uj_gangs_get_gang_count();

/**
 * Get the name of a gang.
 *
 * @param gangID            Internal gangID
 * @param gangName          The array to store the name into.
 * @param gangNameLength    The max length of the gang name.
 *
 * @noreturn
 */
native uj_gangs_get_name(gangID, gangName[], gangNameLength);

/**
 * Create a new Gang to store in the system
 *
 * @param gangID        Internal gangID
 * @param gangName      The name to rename the gang with
 *
 * @noreturn
 */
native uj_gangs_set_name(gangID, const gangName[]);

/**
 * Find the gang a player belongs to
 *
 * @param playerID      Player index
 *
 * @return              An internal gang ID, or UJ_GANG_INVALID if gang not found or on failure.
 */
native uj_gangs_get_gang(playerID);

/**
 * Find a gang by name
 *
 * @param gangName    The name of a gang
 *
 * @return            An internal gang ID, or UJ_GANG_INVALID if gang not found or on failure.
 */
native uj_gangs_get_gang_id(const gangName[]);

/**
 * Adds a member to the specified gang
 *
 * @param playerID      Player index
 * @param gangID        Gang to add the specified player to
 *
 * @noreturn
 */
native uj_gangs_add_member(playerID, gangID);

/**
 * Removes a member from a specified gang
 *
 * @param playerID      Player index
 * @param gangID        Gang to remove the player from.
 *
 * @noreturn
 */
native uj_gangs_remove_member(playerID, gangID);

/**
 * Return a Trie of all members, and their rank, in a gang
 *
 * Possible ranks include:
 *  - UJ_GANG_RANK_MEMBER
 *  - UJ_GANG_RANK_ADMIN
 *  - UJ_GANG_RANK_LEADER
 *t
 * @return        A Trie structure where a player's authID is the key
 *                and the player's rank is the value.
 */
native uj_gangs_get_membership(gangID);

/**
 * Return a list of all members in a gang
 *
 * @param gangID           The gang to look for members of
 * @param players[]        An array to store playerIDs in (must be at least 32-cells long)
 * @param playersLength    The max length of the players array
 *
 * @return                 The number of online gang members.
 */
native uj_gangs_get_online_members(gangID, players[], playersLength);

/**
 * Adds a member to the specified gang
 *
 * @param playerID      Player index
 * @param gangID        Gang to add the specified player to
 *
 * @noreturn
 */
native uj_gangs_add_admin(playerID, gangID);

/**
 * Removes a member to the specified gang
 *
 * @param playerID      Player index
 * @param gangID        Gang to add the specified player to
 *
 * @noreturn
 */
native uj_gangs_remove_admin(playerID, gangID);

/**
 * Find a user's rank within a gang
 *
 * @param playerID      Player index
 *
 * @return              A player's rank within the gang, or UJ_GANG_RANK_INVALID on fail
 */
native uj_gangs_get_member_rank(playerID);

/**
 * Sets a player as a gang's leader
 *
 * @param playerID      Player index
 * @param gangID        Gang to set the leader of
 *
 * @noreturn
 */
native uj_gangs_set_leader(playerID, gangID);


/**
 * Forwards
 */

/**
 * Called after a gang is created.
 *
 * @param gangID        The gang that was created
 * @param gangName      The name of the gang that was created
 */
forward uj_fw_gangs_gang_created(gangID, const gangName[]);

/**
 * Called after a gang is destroyed.
 *
 * @param gangID        The gang that was destroyed
 * @param gangName      The name of the gang that was destroyed
 */
forward uj_fw_gangs_gang_destroyed(gangID, const gangName[]);
