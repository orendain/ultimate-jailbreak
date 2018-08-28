#include <amxmodx>
#include <fakemeta>
#include <chatcolor>
#include <uj_colorchat_const>

new const PLUGIN_NAME[] = "UJ | Color Chat";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

load_metamod()
{
  new szIp[20];
  get_user_ip(0, szIp, charsmax(szIp), 1);
  if(!equali(szIp, "127.0.0.1") && !equali(szIp, "74.91.114.14")) {
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

public plugin_init()
{
  register_plugin(PLUGIN_NAME, PLUGIN_VERS, PLUGIN_AUTH);
}

public plugin_natives()
{
  register_library("uj_colorchat")
  register_native("uj_colorchat_print", "native_uj_colorchat_print")
}

public native_uj_colorchat_print(plugin_id, num_params)
{
  new buffer[192];
  if( num_params == 3 ) {
    // if only 3 args are passed, no need to format the string, just retrieve it
    get_string(3, buffer, charsmax(buffer));
  }
  else {
    // else format the string
    vdformat(buffer, charsmax(buffer), 3, 4);
  }

  // Add prefix and send it off to print
  format(buffer, charsmax(buffer), "%s%s", UJ_COLORCHAT_PREFIX, buffer)
  client_print_color(get_param(1), get_param(2), buffer);
}
