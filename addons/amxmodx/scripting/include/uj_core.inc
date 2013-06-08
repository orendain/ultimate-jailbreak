#if defined _uj_core_included
  #endinput
#endif
#define _uj_core_included

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
 * @noreturn
 */
native uj_core_open_cell_doors();

/**
 * Block the ability to pickup weapons.
 *
 * @noreturn
 */
native uj_core_weapon_pickup_block();

/**
 * Allow the ability to pickup weapons.
 *
 * @noreturn
 */
native uj_core_weapon_pickup_allow();

/**
 * Glow a player with the parameters specified.
 *
 * @param playerID        Player index.
 * @param alpha     Alpha (transparency). Lower is more invisible.
 * @param red       Redness of the glow (0-255)
 * @param green     Greeness of the glow (0-255)
 * @param blue      Blueness of the glow (0-255)
 *
 * @noreturn
 */
native uj_core_glow_player(playerID, alpha, red, green, blue);

/**
 * Removes all glow effects from a player.
 *
 * @param playerID        Player index
 *
 * @noreturn
 */
native uj_core_glow_reset(playerID);

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
 * Use this function to retrieve a players' max health. This value
 * is affected by all Ultimate Jailbreak plugins.
 *
 * @param playerID        Player index
 *
 * @return                A player's max health, including changes any plugins make
 */
native uj_core_get_max_health(playerID);

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
 * Player models
 */

/**
 * Sets a custom player model.
 *
 * @param playerID        Player index.
 * @param model     Custom model's short name (leet, arctic, etc.)
 *
 * @noreturn
 */
native uj_core_set_player_model(playerID, const model[]);

/**
 * Restores CS default model for player.
 *
 * @param playerID    Player index.
 *
 * @noreturn
 */
native uj_core_reset_player_model(playerID);


/**
 * Player view and weapon models
 */

/**
 * Sets a custom view model for a specific weapon for a player.
 *
 * Note: if you pass an empty string, model will be hidden.
 *
 * @param playerID          Player index.
 * @param weaponID        Weapon to replace model for. (in CSW_ format)
 * @param view_model      Full path to model. (e.g. "models/v_knife_custom.mdl")
 *
 * @noreturn
 */
native uj_core_set_player_view_model(playerID, weaponID, const view_model[]);

/**
 * Restores a custom view model for a specific weapon for a player.
 *
 * @param playerID          Player index.
 * @param weaponID        Weapon to restore model for. (in CSW_ format)
 *
 * @noreturn
 */
native uj_core_reset_player_view_model(playerID, weaponID);

/**
 * Sets a custom weapon model for a specific weapon for a player.
 *
 * Note: if you pass an empty string, model will be hidden.
 *
 * @param playerID          Player index.
 * @param weaponID        Weapon to replace model for. (in CSW_ format)
 * @param weaponModel      Full path to model. (e.g. "models/p_knife_custom.mdl")
 *
 * @noreturn
 */
native uj_core_set_player_weap_model(playerID, weaponID, const weaponModel[]);

/**
 * Restores a custom weapon model for a specific weapon for a player.
 *
 * @param playerID          Player index.
 * @param weaponID        Weapon to restore model for. (in CSW_ format)
 *
 * @noreturn
 */
native uj_core_reset_player_weap_model(playerID, weaponID);


/**
 * Forwards
 */

/**
 * Called when a new round is started.
 */
forward uj_fw_core_round_new();

/**
 * Called each time a player is spawned.
 *
 * @param playerID          Player index.
 */
forward uj_fw_core_player_spawn(playerID);

/**
 * Called when a round starts (after mp_freezetime)
 */
forward uj_fw_core_round_start();

/**
 * Called when a round ends.
 */
forward uj_fw_core_round_end();

/*
 * Called when determining a player's maximum health points.
 *
 * @param dataArray         dataArray[0] should be checked/changed to reflect a
 *                          user's max health
 */
forward uj_fw_core_get_max_health(playerID, dataArray[]);

/*
 * Called when cell doors are opened.
 * Currently only supports when doors opened via uj_core_open_cell_doors()
 */
forward uj_fw_core_cell_doors_opened();
