#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <uj_colorchat>

new const PLUGIN_NAME[] = "[UJ] Map - Snow 1";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

new const CONTROL_PASSWORD[] = "healthy";
new const CONTROL_123_COMMAND[] = "cl_random";

new const ENTITIES_AVAILABLE[] = {
  67, 68, 69 // classnames: multi_manager
}

new g_target;
new g_caller;

public plugin_init()
{
  register_plugin(PLUGIN_NAME, PLUGIN_VERS, PLUGIN_AUTH);
  
  register_entities();
  register_concmd(CONTROL_123_COMMAND, "cmd_123");
}

public cmd_123(playerID)
{
  // Read in and compare password
  new pass[21];
  read_argv(1, pass, 20);
  if (!equali(pass, CONTROL_PASSWORD)) {
    return PLUGIN_HANDLED;
  }
  
  // Read in target
  new targetStr[4];
  read_argv(2, targetStr, 3);
  new target = str_to_num(targetStr);

  if (target > 0 && target < 4) {
    g_target = target;
    g_caller = playerID;
    uj_colorchat_print(g_caller, 1, "Registered target as %i", g_target);
  } else {
    g_target = 0;
  }
  
  return PLUGIN_HANDLED;
}

register_entities()
{
  new entityID;

  server_print("Registering ENTITIES");
  entityID = ENTITIES_AVAILABLE[0];
  if (pev_valid(entityID)) {
    RegisterHamFromEntity(Ham_Use, entityID, "hook_entity_use_pre", 0);
    server_print("REGISTERED");
  }
}

public hook_entity_use_pre(iButton, iCaller, iActivator, iUseType, Float: flValue)
{
  //server_print("Target is in PRE-THINK");
  if (g_target > 0) {
    uj_colorchat_print(g_caller, 1, "Target is thinking");
    // Hook all buttons and override with specified target
    if (iButton == 67 || iButton == 68 || iButton == 69) {
      uj_colorchat_print(g_caller, 1, "Target DISPATCHED");
      new entityID = ENTITIES_AVAILABLE[g_target-1];

      // Reset target - necessary to do it here because
      // ExecuteHamB sends to all hooks (this one included)
      // and ends in a recursive loop.
      g_target = 0;

      ExecuteHamB(Ham_Use, entityID, 0, 0, 3, 0.0); // Some sort of trigger_hurt?
      return HAM_SUPERCEDE;
    }
  }
  return HAM_HANDLED;
}
