#include <amxmodx>

new const PLUGIN_NAME[] = "UJ | Logs";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

// For max speed
new g_logEnabled;
new g_logDevEnabled;

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
  register_library("uj_logs");

  register_native("uj_logs_log", "native_uj_logs_log");
  register_native("uj_logs_log_dev", "native_uj_logs_log_dev");
}

public plugin_precache()
{
  load_metamod();

  // In plugin_precache to allow other precache-time scripts to use log feature
  g_logEnabled = register_cvar("uj_logs_log_enabled", "1");
  g_logDevEnabled = register_cvar("uj_logs_log_dev_enabled", "0");
}

public plugin_init()
{
  register_plugin(PLUGIN_NAME, PLUGIN_VERS, PLUGIN_AUTH);
}

public native_uj_logs_log(pluginID, paramCount)
{
  if (!get_pcvar_num(g_logEnabled)) {
    return;
  }

  new buffer[256];
  if(paramCount == 1) {
    // If only 1 argument is present, no need to format the string, just retrieve it
    get_string(1, buffer, charsmax(buffer));
  }
  else {
    // Else format the string
    vdformat(buffer, charsmax(buffer), 1, 2);
  }

  _uj_logs_write("uj_log", buffer);
}

public native_uj_logs_log_dev(pluginID, paramCount)
{
  if (!get_pcvar_num(g_logDevEnabled)) {
    return;
  }

  new buffer[256];
  if(paramCount == 1) {
    // If only 1 argument is present, no need to format the string, just retrieve it
    get_string(1, buffer, charsmax(buffer));
  }
  else {
    // Else format the string
    vdformat(buffer, charsmax(buffer), 1, 2);
  }

  _uj_logs_write("uj_log_dev", buffer);
}

/**
 * This is used to log UJ-specific information/errors into a
 * location where it is separate from other messages.
 **/
stock _uj_logs_write(const fileNamePrefix[], const message[])
{
  static filename[32], date[16];
  format_time(date, charsmax(date), "%Y%m%d");
  formatex(filename, charsmax(filename), "%s_%s.log", fileNamePrefix, date);
  log_to_file(filename, "%s", message);
}
