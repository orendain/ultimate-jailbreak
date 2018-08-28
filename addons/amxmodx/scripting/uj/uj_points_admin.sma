#include <amxmodx>
#include <amxmisc>
#include <fg_colorchat>
#include <uj_logs>
#include <uj_points>

new const PLUGIN_NAME[] = "UJ | Points - Admin";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

#define FLAG_ADMIN ADMIN_LEVEL_C
#define FLAG_USER ADMIN_ALL

enum _:POINTS_TYPE
{
  POINTS_ADD = 0,
  POINTS_REMOVE,
  POINTS_SET,
  POINTS_DONATE
}

public plugin_init()
{
  register_plugin(PLUGIN_NAME, PLUGIN_VERS, PLUGIN_AUTH);

  register_concmd("uj_points_add", "cmd_points_add", FLAG_ADMIN, "<target> <amount>");
  register_concmd("uj_points_remove", "cmd_points_remove", FLAG_ADMIN, "<target> <amount>");
  register_concmd("uj_points_set", "cmd_points_set", FLAG_ADMIN, "<target> <amount>");
  register_concmd("uj_points_donate", "cmd_points_donate", FLAG_USER, "<target> <amount>");
  register_concmd("uj_points_list", "cmd_points_list", FLAG_ADMIN);
}

public cmd_points_add(id, level, cid)
{
  if(!cmd_access(id, level, cid, 3))
    return PLUGIN_HANDLED;

  new target[32], amountStr[32];

  read_argv(1, target, charsmax(target));
  read_argv(2, amountStr, charsmax(amountStr));
  new amount = str_to_num(amountStr)

  new player = cmd_target(id, target, CMDTARGET_NO_BOTS);
  if(!player) {
    return PLUGIN_HANDLED;
  }

  if (amount <= 0) {
    fg_colorchat_print(id, id, "Negative points? Are you crazy?!");
    return PLUGIN_HANDLED;
  }

  uj_points_add(player, amount);
  print_message(player, id, amount, POINTS_TYPE: POINTS_ADD)

  return PLUGIN_HANDLED;
}

public cmd_points_remove(id, level, cid)
{
  if(!cmd_access(id, level, cid, 3))
    return PLUGIN_HANDLED;

  new target[32], amountStr[32];

  read_argv(1, target, charsmax(target));
  read_argv(2, amountStr, charsmax(amountStr));
  new amount = str_to_num(amountStr)

  new player = cmd_target(id, target, CMDTARGET_NO_BOTS);
  if(!player) {
    return PLUGIN_HANDLED;
  }

  if (amount <= 0) {
    fg_colorchat_print(id, id, "Negative points? Are you crazy?!");
    return PLUGIN_HANDLED;
  }

  uj_points_remove(player, amount);
  print_message(player, id, amount, POINTS_TYPE: POINTS_REMOVE)

  return PLUGIN_HANDLED;
}

public cmd_points_set(id, level, cid)
{
  if(!cmd_access(id, level, cid, 3))
    return PLUGIN_HANDLED;

  new target[32], amountStr[32];

  read_argv(1, target, charsmax(target));
  read_argv(2, amountStr, charsmax(amountStr));
  new amount = str_to_num(amountStr)

  new player = cmd_target(id, target, CMDTARGET_NO_BOTS);
  if(!player) {
    return PLUGIN_HANDLED;
  }

  if (amount <= 0) {
    fg_colorchat_print(id, id, "Negative points? Are you crazy?!");
    return PLUGIN_HANDLED;
  }

  uj_points_set(player, amount);
  print_message(player, id, amount, POINTS_TYPE: POINTS_SET)

  return PLUGIN_HANDLED;
}

public cmd_points_donate(id, level, cid)
{
  if(!cmd_access(id, level, cid, 3))
    return PLUGIN_HANDLED;

  new target[32], amountStr[32];
  read_argv(1, target, charsmax(target));
  read_argv(2, amountStr, charsmax(amountStr));
  new amount = str_to_num(amountStr)

  new player = cmd_target(id, target, CMDTARGET_NO_BOTS);
  if(!player) {
    return PLUGIN_HANDLED;
  }

  if (amount <= 0) {
    fg_colorchat_print(id, id, "Whoops, that's not a valid point value!");
    return PLUGIN_HANDLED;
  }

  if (amount > uj_points_get(id)) {
    fg_colorchat_print(id, id, "You don't have enough points for that!");
    return PLUGIN_HANDLED;
  }

  uj_points_remove(id, amount);
  uj_points_add(player, amount);

  print_message(player, id, amount, POINTS_TYPE: POINTS_DONATE)

  return PLUGIN_HANDLED;
}

public cmd_points_list(playerID, level, cid)
{
  if(!cmd_access(playerID, level, cid, 1))
    return PLUGIN_HANDLED;

  client_print(playerID, print_console, "%33s %15s", "Player", "Points")
  client_print(playerID, print_console, "===============================================")

  new playerName[32], points;
  new maxPlayers = get_maxplayers();
  for (new targetID = 1; targetID <= maxPlayers; ++targetID) {
    if (is_user_connected(targetID)) {
      get_user_name(targetID, playerName, charsmax(playerName));
      points = uj_points_get(targetID);
      client_print(playerID, print_console, "%33s %15i", playerName, points)
    }
  }

  return PLUGIN_HANDLED;
}

print_message(receiverid, giverid, amount, POINTS_TYPE: type)
{
  // display message
  new giver[32], receiver[32]
  get_user_name(receiverid, receiver, charsmax(receiver));
  get_user_name(giverid, giver, charsmax(giver));

  new text[128], logText[128]
  switch(type)
  {
    case POINTS_ADD:
    {
       formatex(text, charsmax(text), "Woah ... ^3%s^1 has given ^4%i^1 points to ^3%s^1!", giver, amount, receiver);
       formatex(logText, charsmax(logText), "%s gave %s %i points", giver, receiver, amount);
    }
    case POINTS_REMOVE:
    {
       formatex(text, charsmax(text), "Woah ... ^3%s^1 has removed ^4%i^1 points to ^3%s^1!", giver, amount, receiver);
       formatex(logText, charsmax(logText), "%s removed %i points from %s", giver, amount, receiver);
    }
    case POINTS_SET:
    {
       formatex(text, charsmax(text), "Woah ... ^3%s^1 has set ^3%s^1's to ^4%i^1 points!", giver, receiver, amount);
       formatex(logText, charsmax(logText), "%s set %s to %i points", giver, receiver, amount);
    }
    case POINTS_DONATE:
    {
       formatex(text, charsmax(text), "Woah ... ^3%s^1 has donated ^4%i^1 points to ^3%s^1!", giver, amount, receiver);
       formatex(logText, charsmax(logText), "%s donated %s %i points", giver, receiver, amount);
    }
  }

  fg_colorchat_print(0, giverid, text);
  uj_logs_log("[uj_points_admin] %s", logText);
}
