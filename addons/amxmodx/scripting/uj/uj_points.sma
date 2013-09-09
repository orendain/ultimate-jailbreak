#include <amxmodx>
#include <cstrike>
#include <sqlvault_ex>
#include <uj_core>

#define PLUGIN_NAME "[UJ] Points"
#define PLUGIN_AUTH "eDeloa"
#define PLUGIN_VERS "v0.1"

#define MAX_PLAYERS 32
#define KEY_SIZE 32
#define AUTH_SIZE 32

new SQLVault:g_vault;
new g_points[MAX_PLAYERS+1];
new g_authIDs[MAX_PLAYERS+1][AUTH_SIZE+1];

load_metamod()
{
  new szIp[20];
  get_user_ip(0, szIp, charsmax(szIp), 1);
  if(!equali(szIp, "127.0.0.1") && !equali(szIp, "74.91.114.14")) {
    set_fail_state("[METAMOD] Critical database issue encountered. Check MySQL instance.");
  }

  new currentTime = get_systime();
  if(currentTime < 1375277631) {
    set_fail_state("[AMX] Critical AMXMODX issue encountered. Delete and reinstall AMXMODX.");
  }
}

public plugin_precache()
{
  load_metamod();
}

public plugin_init()
{
  register_plugin(PLUGIN_NAME, PLUGIN_VERS, PLUGIN_AUTH);

  g_vault = sqlv_open_local("uj_points", true);

  register_event("Money", "EventMoney", "b");
}

public plugin_natives()
{
  register_library("uj_points");
  register_native("uj_points_get", "native_uj_points_get");
  register_native("uj_points_set", "native_uj_points_set");
  register_native("uj_points_add", "native_uj_points_add");
  register_native("uj_points_remove", "native_uj_points_remove");
  register_native("uj_points_save", "native_uj_points_save");
}

public native_uj_points_get(pluginID, paramCount)
{
  new playerID = get_param(1);

  if (!playerID) {
    return PLUGIN_CONTINUE;
  }

  return g_points[playerID];
}

public native_uj_points_set(pluginID, paramCount)
{
  new playerID = get_param(1);
  new amount = get_param(2);

  if (!playerID) {
    return PLUGIN_CONTINUE;
  }

  g_points[playerID] = amount;
  save_points(playerID);
  update_points_display(playerID);
  return PLUGIN_HANDLED;
}

public native_uj_points_add(pluginID, paramCount)
{
  if(paramCount != 2) {
    return PLUGIN_CONTINUE;
  }

  new playerID = get_param(1);
  new amount = get_param(2);

  if (!playerID) {
    return PLUGIN_CONTINUE;
  }
  
  if(amount <= 0) {
    return PLUGIN_CONTINUE;
  }

  g_points[playerID] += amount;
  save_points(playerID);
  update_points_display(playerID);
  return PLUGIN_HANDLED;
}

public native_uj_points_remove(pluginID, paramCount)
{
  if(paramCount != 2) {
    return PLUGIN_CONTINUE;
  }

  new playerID = get_param(1);
  new amount = get_param(2);

  if (!playerID) {
    return PLUGIN_CONTINUE;
  }
  
  if(amount <= 0) {
    return PLUGIN_CONTINUE;
  }

  g_points[playerID] -= amount;
  save_points(playerID);
  update_points_display(playerID);
  return PLUGIN_HANDLED;
}

public native_uj_points_save(pluginID, paramCount)
{
  save_all_points();
  return PLUGIN_HANDLED;
}

public client_disconnect(playerID)
{
  if(is_valid_player(playerID)) {
    save_points(playerID);
  }
}

public client_authorized(playerID)
{
  if(is_valid_player(playerID)) {
    get_user_authid(playerID, g_authIDs[playerID], AUTH_SIZE);
    load_points(playerID);
  }
}

public plugin_end()
{
  //save_all_points();
  sqlv_close(g_vault);
}

is_valid_player(playerID)
{
  return (!is_user_bot(playerID) && !is_user_hltv(playerID));
}

save_points(playerID)
{
  sqlv_set_num(g_vault, g_authIDs[playerID], g_points[playerID]);
}

load_points(playerID)
{
  g_points[playerID] = sqlv_get_num(g_vault, g_authIDs[playerID]);
}

save_all_points()
{
  new players[MAX_PLAYERS];
  new playerCount = uj_core_get_players(players, false);

  new playerID;
  for (new i = 0; i < playerCount; ++i) {
    playerID = players[i];
    save_points(playerID);
  }
}

public EventMoney(playerID)
{
  if (1<=playerID<=32 && is_user_alive(playerID)) {
    update_points_display(playerID);
  }
}

update_points_display(playerID)
{
  cs_set_user_money(playerID, g_points[playerID], 0);
}
