#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <uj_core>

new const PLUGIN_NAME[] = "UJ | Chargers";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

#define MAX_PLAYERS 32

// Variables
new bool:g_blockHeal;
new bool:g_blockArmor;

new g_hasHealBlocked;
new g_hasArmorBlocked;

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

public plugin_init()
{
  register_plugin(PLUGIN_NAME, PLUGIN_VERS, PLUGIN_AUTH);

  // Register forward
  // /RegisterHam(Ham_Use, "func_healthcharger", "FwdHealthBoxUse", false);
  RegisterHam(Ham_Use, "func_recharge", "FwdArmorBoxUse");
  //RegisterHam(Ham_Think,"func_healthcharger","fw_ReThink", 1)

  RegisterHam(Ham_TakeHealth, "player", "FwdTakeHealth");
}

public plugin_natives()
{
  register_library("uj_chargers");
  register_native("uj_chargers_block_heal", "native_uj_chargers_block_heal");
  register_native("uj_chargers_block_armor", "native_uj_chargers_block_armor");
  register_native("uj_chargers_get_heal", "native_uj_chargers_get_heal");
  register_native("uj_chargers_get_armor", "native_uj_chargers_get_armor");
}

public native_uj_chargers_block_heal(pluginID, paramCount)
{
  new playerID = get_param(1);
  new bool:block = (get_param(2) ? true : false);

  // If affecting all players
  if (playerID == 0) {
    g_blockHeal = block;
    g_hasHealBlocked = 0;
    return;
  }
  else {
    if (block) {
      set_bit(g_hasHealBlocked, playerID);
    }
    else {
      clear_bit(g_hasHealBlocked, playerID);
    }
  }
}

public native_uj_chargers_block_armor(pluginID, paramCount)
{
  new playerID = get_param(1);
  new bool:block = (get_param(2) ? true : false);

  // If affecting all players
  if (playerID == 0) {
    g_blockArmor = block;
    g_hasArmorBlocked = 0;
    return;
  }
  else {
    if (block) {
      set_bit(g_hasArmorBlocked, playerID);
    }
    else {
      clear_bit(g_hasArmorBlocked, playerID);
    }
  }
}

public native_uj_chargers_get_heal(pluginID, paramCount)
{
  new playerID = get_param(1);

  if (g_blockHeal || playerID == 0) {
    return g_blockHeal;
  }
  return get_bit(g_hasHealBlocked, playerID);
}

public native_uj_chargers_get_armor(pluginID, paramCount)
{
  new playerID = get_param(1);

  if (g_blockArmor || playerID == 0) {
    return g_blockArmor;
  }
  return get_bit(g_hasArmorBlocked, playerID);
}

public FwdArmorBoxUse(const entityID, const callerID)
{
  if (g_blockArmor || get_bit(g_hasArmorBlocked, callerID)) {
    return HAM_SUPERCEDE;
  }
  return HAM_IGNORED;
}

public FwdTakeHealth(playerID, Float:flHealth, bitsDamageType)
{
  if (g_blockHeal || get_bit(g_hasHealBlocked, playerID)) {
    return HAM_SUPERCEDE;
  }
  return HAM_HANDLED;
}

/*
public fw_ReThink(ent)
{
  fg_colorchat_print(0,1, "THINK - EntityID is %i", ent);
}
*/
