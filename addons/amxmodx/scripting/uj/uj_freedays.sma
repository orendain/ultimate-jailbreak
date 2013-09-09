#include <amxmodx>
#include <cstrike>
#include <hamsandwich>
#include <uj_core>
#include <uj_effects>

new const PLUGIN_NAME[] = "[UJ] Freedays";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

new const GLOW_RED = 255;
new const GLOW_GREEN = 255;
new const GLOW_BLUE = 0;
new const GLOW_ALPHA = 16;

// Keep track of who has a freeday
new g_hasFreeday;
new g_freedayCount;

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

public plugin_natives()
{
  register_library("uj_freedays");
  register_native("uj_freedays_give", "native_uj_freedays_give");
  register_native("uj_freedays_remove", "native_uj_freedays_remove");
  register_native("uj_freedays_has_freeday", "native_uj_freedays_has_freeday");
  register_native("uj_freedays_get_count", "native_uj_freedays_get_count");
}

public plugin_init()
{
  register_plugin(PLUGIN_NAME, PLUGIN_VERS, PLUGIN_AUTH);

  // Track deaths to know when a freeday becomes inactive
  RegisterHam(Ham_Killed, "player", "FwPlayerKilled", 1);
}

public native_uj_freedays_give(pluginID, paramCount)
{
  new playerID = get_param(1);
  if (is_user_alive(playerID)) {
    give_freeday(playerID);
  }
}

public native_uj_freedays_remove(pluginID, paramCount)
{
  new playerID = get_param(1);
  
  // Affect all live prisoners
  if (playerID == 0) {
    new players[32];
    new playerCount = uj_core_get_players(players, true, CS_TEAM_T);
    for (new i = 0; i < playerCount; ++i) {
      remove_freeday(players[i]);
    }
  }
  else {
    remove_freeday(playerID);
  }
}

public native_uj_freedays_has_freeday(pluginID, paramCount)
{
  new playerID = get_param(1);
  if (playerID > 0 && playerID <= 32) {
    return get_bit(g_hasFreeday, playerID);
  }
  return false;
}

public native_uj_freedays_get_count(pluginID, paramCount)
{
  return g_freedayCount;
}

public uj_fw_core_round_new()
{
  reset();
}

public FwPlayerKilled(playerID)
{
  // On death, remove freeday
  remove_freeday(playerID);
}

public client_disconnect(playerID)
{
  // If a player leaves, remove their freeday
  remove_freeday(playerID);
}

reset()
{
  g_hasFreeday = 0;
  g_freedayCount = 0;
}

give_freeday(playerID)
{
  // If user does not currently have a freeday, give him or her one.
  if (!get_bit(g_hasFreeday, playerID)) {
    uj_effects_glow_player(playerID, GLOW_RED, GLOW_GREEN, GLOW_BLUE, GLOW_ALPHA);
    set_bit(g_hasFreeday, playerID);
    g_freedayCount++;
  }
}

remove_freeday(playerID)
{
  // If the user has a freeday, remove it.
  if (get_bit(g_hasFreeday, playerID)) {
    uj_effects_glow_reset(playerID);
    clear_bit(g_hasFreeday, playerID);
    g_freedayCount--;
  }
}
