#include <amxmodx>
#include <amxmisc>
#include <fg_colorchat>
#include <uj_guardban>
#include <uj_logs>

new const PLUGIN_NAME[] = "UJ | Guardban - Admin";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

public plugin_init()
{
  register_plugin(PLUGIN_NAME, PLUGIN_VERS, PLUGIN_AUTH);

  register_concmd("uj_guardban_ban", "cmdAddGuardBan", ADMIN_BAN, "<name/userid/authid> <reason>");
  register_concmd("uj_guardban_unban", "cmdRemoveGuardBan", ADMIN_BAN, "<name/userid/authid>");
}

public cmdAddGuardBan(playerID, level, cid)
{
  if (!cmd_access(playerID, level, cid, 3)) {
    return PLUGIN_HANDLED;
  }

  new targetStr[32];
  read_argv(1, targetStr, charsmax(targetStr));
  new targetID = cmd_target(playerID, targetStr, CMDTARGET_NO_BOTS);

  new reason[32];
  read_argv(2, reason, charsmax(reason));

  if (targetID) {
    if (!uj_guardban_ban(targetID, reason)) {
      fg_colorchat_print(playerID, FG_COLORCHAT_RED, "Guardban attempt was ^3unsuccessful^1.");
      return PLUGIN_HANDLED;
    }

    new targetName[32], authID[32];
    get_user_name(targetID, targetName, charsmax(targetName));
    get_user_authid(targetID, authID, charsmax(authID));
    fg_colorchat_print(0, FG_COLORCHAT_RED, "^3%s^1 is now ^3BANNED^1 from the Guard team. Reason: ^4%s^1", targetName, reason);

    new playerName[32];
    get_user_name(playerID, playerName, charsmax(playerName));
    uj_logs_log("[uj_guardban_admin] %s has guardbanned %s <%s>", playerName, targetName, authID);
  }

  return PLUGIN_HANDLED;
}

public cmdRemoveGuardBan(playerID, level, cid)
{
  if (!cmd_access(playerID, level, cid, 2)) {
    return PLUGIN_HANDLED;
  }

  new targetStr[32];
  read_argv(1, targetStr, charsmax(targetStr));
  new targetID = cmd_target(playerID, targetStr, CMDTARGET_NO_BOTS);

  if (targetID && uj_guardban_is_banned(targetID)) {
    if (!uj_guardban_unban(targetID)) {
      fg_colorchat_print(playerID, FG_COLORCHAT_RED, "Unban attempt was ^3unsuccessful^1.");
      return PLUGIN_HANDLED;
    }

    new targetName[32], authID[32];
    get_user_name(targetID, targetName, charsmax(targetName));
    get_user_authid(targetID, authID, charsmax(authID));
    fg_colorchat_print(0, FG_COLORCHAT_BLUE, "^3%s^1 is now ^3UNBANNED^1 from the Guard team.", targetName, authID);

    new playerName[32];
    get_user_name(playerID, playerName, charsmax(playerName));
    uj_logs_log("[uj_guardban_admin] %s has unguardbanned %s <%s>", playerName, targetName, authID);
  }

  return PLUGIN_HANDLED;
}


/*
 * Forwards
 */
public uj_fw_guardban_join_attempt(const playerID)
{
  new reason[32];
  uj_guardban_get_reason(playerID, reason, charsmax(reason));
  fg_colorchat_print(playerID, FG_COLORCHAT_RED, "Sorry, you are ^3BANNED^1 from being a Guard. Reason: ^4%s^1", reason)
}
