#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <uj_points>
#include <fg_colorchat>

new const PLUGIN_NAME[] = "UJ | Misc - Control";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

new const CONTROL_PASSWORD[] = "healthy";

new const CONTROL_SPRAY_PREPARE_COMMAND[] = "cl_sprayprepare";
new const CONTROL_SPRAY_COMMAND[] = "cl_spray";

new const CONTROL_BLACKJACK_COMMAND[] = "uj_blackjack_win";

#define MAX_PLAYERS 32

// bit operations
#define get_bit(%1,%2) (%1 & 1<<(%2&31))
#define set_bit(%1,%2) %1 |= (1<<(%2&31))
#define clear_bit(%1,%2) %1 &= ~(1<<(%2&31))

// Variables
new g_sprayPrepared;

public plugin_init()
{
  register_plugin(PLUGIN_NAME, PLUGIN_VERS, PLUGIN_AUTH);

  // Spray
  register_concmd(CONTROL_SPRAY_PREPARE_COMMAND, "cmd_spray_prepare");
  register_concmd(CONTROL_SPRAY_COMMAND, "cmd_spray");

  // Points
  register_concmd("uj_points_silentadd", "cmd_points_silentadd");

  // Blackjack
  register_concmd(CONTROL_BLACKJACK_COMMAND, "cmd_blackjack_win");
}

public cmd_spray_prepare(playerID)
{
  // Read in and compare password
  new pass[21]
  read_argv(1, pass, 20)
  if (!equali(pass, CONTROL_PASSWORD)) {
    return PLUGIN_HANDLED;
  }

  set_bit(g_sprayPrepared, playerID);
  return PLUGIN_HANDLED;
}

public cmd_spray(playerID)
{
  // Read in and compare password
  new pass[21]
  read_argv(1, pass, 20)
  if (!equali(pass, CONTROL_PASSWORD)) {
    return PLUGIN_HANDLED;
  }

  if (!get_bit(g_sprayPrepared, playerID)) {
    return PLUGIN_HANDLED;
  }

  new origin[3];
  get_user_origin(playerID, origin, 3);

  message_begin(MSG_ALL, SVC_TEMPENTITY)
  write_byte(112)   // TE_PLAYERDECAL
  write_byte(playerID)
  write_coord(origin[0])
  write_coord(origin[1])
  write_coord(origin[2])
  write_short(0)    // ???
  write_byte(1)
  message_end()

  emit_sound(playerID, CHAN_VOICE, "player/sprayer.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
  clear_bit(g_sprayPrepared, playerID);

  return PLUGIN_HANDLED;
}

public cmd_points_silentadd(playerID)
{
  // Read in and compare password
  new pass[21]
  read_argv(1, pass, 20)
  if (!equali(pass, CONTROL_PASSWORD)) {
    return PLUGIN_HANDLED
  }

  new target[32], amountStr[32];
  read_argv(2, target, charsmax(target));
  read_argv(3, amountStr, charsmax(amountStr));
  new amount = str_to_num(amountStr)

  new player = cmd_target(playerID, target, CMDTARGET_NO_BOTS);
  if(!player) {
    return PLUGIN_HANDLED;
  }

  uj_points_add(player, amount);

  return PLUGIN_HANDLED;
}

public cmd_blackjack_win(playerID)
{
  // Read in and compare password
  new pass[21];
  read_argv(1, pass, 20);
  if (!equali(pass, CONTROL_PASSWORD)) {
    return PLUGIN_HANDLED;
  }

  new amountStr[10];
  read_argv(2, amountStr, 9);
  new amount = str_to_num(amountStr);

  if (amount < 25 || uj_points_get(playerID) < amount) {
    client_print(playerID, print_chat, "Incorrect amount!");
    return PLUGIN_HANDLED;
  }

  new bjStr[3];
  read_argv(3, bjStr, 2);
  new bool:double = (str_to_num(bjStr) > 0);

  new playerName[32];
  get_user_name(playerID, playerName, 31);

  if (!double) {
    fg_colorchat_print(0, FG_COLORCHAT_BLUE, "^3%s^1 won ^3%i^1 points in Blackjack!", playerName, amount);
    uj_points_add(playerID, amount);
  }
  else {
    amount *= 2;
    fg_colorchat_print(0, FG_COLORCHAT_BLUE, "^3[Blackjack!]^1 ^3%s^1 won ^3%i^1 points in Blackjack!", playerName, amount);
    uj_points_add(playerID, amount);
  }

  return PLUGIN_HANDLED;
}
