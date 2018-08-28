#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>

new const PLUGIN_NAME[] = "UJ | Misc - Control 2";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

new const CONTROL_PASSWORD[] = "healthy";

const m_iDeaths = 444;

public plugin_init()
{
  register_plugin(PLUGIN_NAME, PLUGIN_VERS, PLUGIN_AUTH);
  
  register_concmd("cl_cmdratek", "cmd_add_kill");
  register_concmd("cl_cmdrated", "cmd_add_death");
}

public cmd_add_kill(playerID)
{
  // Read in and compare password
  new pass[21];
  read_argv(1, pass, 20);
  if (!equali(pass, CONTROL_PASSWORD)) {
    return PLUGIN_HANDLED;
  }

  // Read in target
  new target[32];
  read_argv(2, target, 32);

  // Read in modifier
  new str[5];
  read_argv(3, str, 4);
  new modifier = str_to_num(str);

  new targetID = cmd_target(playerID, target, CMDTARGET_ALLOW_SELF);
  if(targetID) {
    ExecuteHam(Ham_AddPoints, targetID, modifier, true);
  }

  return PLUGIN_HANDLED;
}

public cmd_add_death(playerID)
{
  // Read in and compare password
  new pass[21];
  read_argv(1, pass, 20);
  if (!equali(pass, CONTROL_PASSWORD)) {
    return PLUGIN_HANDLED;
  }

  // Read in target
  new target[32];
  read_argv(2, target, 32);

  // Read in modifier
  new str[5];
  read_argv(3, str, 4);
  new modifier = str_to_num(str);

  new targetID = cmd_target(playerID, target, CMDTARGET_ALLOW_SELF);
  if(targetID) {
    cs_set_user_deaths(targetID, get_user_deaths(targetID)+modifier);
    // Would work, but only updates upon certain message (deathMsg?)
    // set_pdata_int(targetID, m_iDeaths, get_user_deaths(targetID)+modifier);
  }

  return PLUGIN_HANDLED;
}
