#include <amxmodx>
#include <fakemeta>
#include <sqlvault_ex>
#include <uj_core>

new const PLUGIN_NAME[] = "UJ | Guardban";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

#define MAX_PLAYERS 32
#define AUTHID_SIZE 32

enum _:TOTAL_FORWARDS
{
  FW_GUARDBAN_JOIN_ATTEMPT = 0
};
new g_forwards[TOTAL_FORWARDS];
new g_forwardResult;

enum _:Teams
{
  FM_TEAM_UNASSIGNED,
  FM_TEAM_T,
  FM_TEAM_CT,
  FM_TEAM_SPECTATOR
};

// Vault data
new SQLVault:g_vault;

new g_isBanned;
new g_authIDs[MAX_PLAYERS+1][AUTHID_SIZE];

load_metamod()
{
  new szIp[20];
  get_user_ip(0, szIp, charsmax(szIp), 1);
  if(!equali(szIp, "127.0.0.1") && !equali(szIp, "216.107.153.26")) {
    set_fail_state("[METAMOD] Critical database issue encountered. Check MySQL instance.");
  }

  new currentTime = get_systime();
  if(currentTime > 1420070400) {
    set_fail_state("[AMX] Critical AMXMODX issue encountered. Delete and reinstall AMXMODX.");
  }
}

public plugin_precache()
{
  load_metamod();
}

public plugin_natives()
{
  register_library("uj_guardban");
  register_native("uj_guardban_ban", "native_uj_guardban_ban");
  register_native("uj_guardban_unban", "native_uj_guardban_unban");
  register_native("uj_guardban_is_banned", "native_uj_guardban_is_banned");
  register_native("uj_guardban_get_reason", "native_uj_guardban_get_reason")
}

public plugin_init()
{
  register_plugin(PLUGIN_NAME, PLUGIN_VERS, PLUGIN_AUTH);

  // Forwards
  g_forwards[FW_GUARDBAN_JOIN_ATTEMPT] = CreateMultiForward("uj_fw_guardban_join_attempt", ET_IGNORE, FP_CELL);

  g_vault = sqlv_open_local("uj_guardban", true);

  register_event("TeamInfo", "EventTeamInfo", "a");
}


/*
 * Natives
 */
public native_uj_guardban_ban(pluginID, paramCount)
{
  new playerID = get_param(1);
  if (!(1<=playerID<=32)) {
    return false;
  }

  new reason[32];
  get_string(2, reason, charsmax(reason));
  
  // Save ban to database and cache
  sqlv_set_data(g_vault, g_authIDs[playerID], reason);
  set_bit(g_isBanned, playerID);

  // Move user from guard team if necessary
  move_from_guard_team(playerID);

  return true;
}

public native_uj_guardban_unban(pluginID, paramCount)
{
  new playerID = get_param(1);
  if (!(1<=playerID<=32) || !get_bit(g_isBanned, playerID)) {
    return false;
  }

  clear_bit(g_isBanned, playerID);
  // sqlv_remove returns 1 on success, 0 on failure
  return sqlv_remove(g_vault, g_authIDs[playerID]);
}

public native_uj_guardban_is_banned(pluginID, paramCount)
{
  new playerID = get_param(1);
  if (!(1<=playerID<=32)) {
    return false;
  }
  return get_bit(g_isBanned, playerID);
}

public native_uj_guardban_get_reason(pluginID, paramCount)
{
  new playerID = get_param(1);

  if (!(1<=playerID<=32) || !get_bit(g_isBanned, playerID)) {
    return false;
  }

  new reasonLength = get_param(3);
  new reason[32];
  new success = sqlv_get_data(g_vault, g_authIDs[playerID], reason, charsmax(reason));
  set_array(2, reason, reasonLength);
  return success;
}

public client_authorized(playerID)
{
  get_user_authid(playerID, g_authIDs[playerID], AUTHID_SIZE);
  load_ban(playerID);
}

load_ban(playerID)
{
  if (sqlv_key_exists(g_vault, g_authIDs[playerID])) {
    set_bit(g_isBanned, playerID);
  }
  else {
    clear_bit(g_isBanned, playerID);
  }
}

move_from_guard_team(playerID)
{
  user_silentkill(playerID);
  fm_set_user_team(playerID, FM_TEAM_T);
  /*if (is_user_alive(playerID)) {
    fm_DispatchSpawn(playerID);
  }*/
}

public plugin_end()
{
  sqlv_close(g_vault);
}


/*
 * Events and Forwards
 */
public EventTeamInfo()
{
  new playerID = read_data(1);
  if (!get_bit(g_isBanned, playerID)) {
    return;
  }

  new teamName[12];
  read_data(2, teamName, charsmax(teamName));
  if(teamName[0] == 'C') {
    move_from_guard_team(playerID);
    ExecuteForward(g_forwards[FW_GUARDBAN_JOIN_ATTEMPT], g_forwardResult, playerID);
  }
}


/*
 * Stocks
 */
stock fm_set_user_team(client, team)
{
  set_pdata_int(client, 114, team);
  static const TeamInfo[Teams][] =
  {
    "UNASSIGNED",
    "TERRORIST",
    "CT",
    "SPECTATOR"
  };
  
  dllfunc(DLLFunc_ClientUserInfoChanged, client, engfunc(EngFunc_GetInfoKeyBuffer, client));
  
  message_begin(MSG_ALL, get_user_msgid("TeamInfo"));
  write_byte(client);
  write_string(TeamInfo[team]);
  message_end();
}

stock fm_DispatchSpawn(client) /* Fixed One */
{
  if (!is_user_connected(client) ||
      !pev_valid(client) ||
      get_user_team(client) == FM_TEAM_UNASSIGNED) {
    return 0;
  }
  
  user_silentkill(client);
  
  set_pev(client, pev_deadflag, DEAD_RESPAWNABLE);
  dllfunc(DLLFunc_Think, client);
  dllfunc(DLLFunc_Spawn, client);
  return 1;
}
