#if defined _uj_colorchat_included
  #endinput
#endif
#define _uj_colorchat_included

#include <uj_colorchat_const>

#if AMXX_VERSION_NUM >= 175 
  #pragma reqlib uj_colorchat
  #if !defined AMXMODX_NOAUTOLOAD
    #pragma loadlib uj_colorchat
  #endif
#else
  #pragma library uj_colorchat
#endif

/**
 * Sends a colored message to a player, or all players.
 *
 * Example: uj_colored_print(playerID, senderID, "^4This is green ^3this is red, ^1this is your default chat text color");
 * Example: uj_colored_print(playerID, UJ_COLORCHAT_RED, "^4 %s %i", "Hello, world!", 1337);
 *
 * @param playerID      This is the player index you want to send the message to.  Use 0 to send to all players.
 * @param senderID      This is the player index you want to use the team color.  Use an enum above if you want to force a color.
 * @param str           Formatted string in which patterns will be replaced with the argument list.
 * 
 * @return              Returns 1 if the message has been sent.
 *                      Returns 0 playerID is not a connected player, or, if playerID = 0, if there are no humans players.
 */
native uj_colorchat_print(playerID, senderID, const str[], any:...);
