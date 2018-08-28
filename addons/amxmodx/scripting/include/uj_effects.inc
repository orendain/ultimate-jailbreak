#if defined _uj_effects_included
  #endinput
#endif
#define _uj_effects_included

#if AMXX_VERSION_NUM >= 175 
  #pragma reqlib uj_effects
  #if !defined AMXMODX_NOAUTOLOAD
    #pragma loadlib uj_effects
  #endif
#else
  #pragma library uj_effects
#endif

/**
 * Natives
 */

/**
 * Reset a player's max speed.
 *
 * @noreturn
 */
native uj_effects_reset_max_speed(playerID);

/**
 * Glow a player with the parameters specified.
 *
 * @param playerID  Player index.
 * @param red       Redness of the glow (0-255)
 * @param green     Greeness of the glow (0-255)
 * @param blue      Blueness of the glow (0-255)
 * @param size      Shell size (0-255)
 *
 * @noreturn
 */
native uj_effects_glow_player(playerID, red, green, blue, size);

/**
 * Removes all glow effects from a player.
 *
 * @param playerID        Player index
 *
 * @noreturn
 */
native uj_effects_glow_reset(playerID);

/**
 * Glow a player with the parameters specified.
 *
 * @param playerID  Player index
 * @param red       Redness of the fade (0-255)
 * @param green     Greeness of the fade (0-255)
 * @param blue      Blueness of the fade (0-255)
 * @param alpha     Transparency (0 = invisible, 255 = visible)
 *
 * @noreturn
 */
native uj_effects_screen_fade(playerID, red, green, blue, alpha);

/**
 * Set a player's visibility.
 *
 * @param playerID        Player index
 * @param alpha           Transparency (0: invisible - 255:visible)
 *
 * @noreturn
 */
native uj_effects_set_visibility(playerID, alpha);

/**
 * Reset a player's visibility.
 *
 * @param playerID        Player index
 *
 * @noreturn
 */
native uj_effects_reset_visibility(playerID);

/**
 * Turn a player into a rocket
 *
 * @param playerID        Player index
 *
 * @noreturn
 */
native uj_effects_rocket(playerID);

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
native uj_effects_set_model(playerID, const model[]);

/**
 * Restores CS default model for player.
 *
 * @param playerID    Player index.
 *
 * @noreturn
 */
native uj_effects_reset_model(playerID);


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
native uj_effects_set_view_model(playerID, weaponID, const view_model[]);

/**
 * Restores a custom view model for a specific weapon for a player.
 *
 * @param playerID          Player index.
 * @param weaponID        Weapon to restore model for. (in CSW_ format)
 *
 * @noreturn
 */
native uj_effects_reset_view_model(playerID, weaponID);

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
native uj_effects_set_weap_model(playerID, weaponID, const weaponModel[]);

/**
 * Restores a custom weapon model for a specific weapon for a player.
 *
 * @param playerID          Player index.
 * @param weaponID        Weapon to restore model for. (in CSW_ format)
 *
 * @noreturn
 */
native uj_effects_reset_weap_model(playerID, weaponID);


/*
 * Forwards
 */

/**
 * Called when a player's maxspeed needs to be determined
 *
 * @param playerID          Player index.
 * @param data              data[0] should be checked/changed to reflect the damage that should be taken
 */
forward uj_effects_determine_max_speed(player, data[]);
