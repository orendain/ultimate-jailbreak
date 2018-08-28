#include <amxmodx>
#include <sqlvault_ex>
#include <uj_logs>

new const PLUGIN_NAME[] = "UJ | Player Stats";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

#define COL_NAME "Name"

// Vault data
new SQLVault:g_vault;

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

public plugin_natives()
{
  register_library("uj_player_stats");
  register_native("uj_player_stats_get_name", "native_uj_player_stats_get_name");
}

public plugin_precache()
{
  load_metamod();
}

public plugin_init()
{
  register_plugin(PLUGIN_NAME, PLUGIN_VERS, PLUGIN_AUTH);

  g_vault = sqlv_open_local("uj_player_stats", false);
  sqlv_init_ex(g_vault);
}

public plugin_end()
{
  sqlv_close(g_vault);
}

public client_authorized(playerID)
{
  // Retrieve and save player's name
  new authID[32], playerName[32];
  get_user_authid(playerID, authID, charsmax(authID));
  get_user_name(playerID, playerName, charsmax(playerName));

  sqlv_set_data_ex(g_vault, authID, COL_NAME, playerName);
}

public native_uj_player_stats_get_name(pluginID, paramCount)
{
  new authID[32], playerName[32];
  get_string(1, authID, charsmax(authID));
  new playerNameLength = get_param(3);

  new result = sqlv_get_data_ex(g_vault, authID, COL_NAME, playerName, charsmax(playerName));

  uj_logs_log_dev("[uj_player_stats] result: %i, name %s", result, playerName);

  if (!result || strlen(playerName) < 1) {
    formatex(playerName, playerNameLength, "Unknown Name (%s)", authID);
  }
  set_array(2, playerName, playerNameLength);
}
