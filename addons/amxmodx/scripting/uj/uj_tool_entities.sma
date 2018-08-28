#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <fg_colorchat>

new const PLUGIN_NAME[] = "UJ | Tool - Entities";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

public plugin_init()
{
  register_plugin(PLUGIN_NAME, PLUGIN_VERS, PLUGIN_AUTH);

  //list_classnames();
  //find_entity_info();
  //find_trigger();

  //register_buttons();
  register_concmd("find_button", "find_button");
}

register_buttons()
{
  new entityID;

  entityID = 1013;
  if (pev_valid(entityID)) {
    RegisterHamFromEntity(Ham_Use, entityID, "hook_entity_use_pre", 0);
    server_print("Registered entity with ID #%i", entityID);
  }

  entityID = 259; // cage floor
  if (pev_valid(entityID)) {
    RegisterHamFromEntity(Ham_Use, entityID, "hook_entity_use_pre", 0);
    server_print("Registered entity with ID #%i", entityID);
  }

  entityID = 109; // random env_explosion
  if (pev_valid(entityID)) {
    RegisterHamFromEntity(Ham_Use, entityID, "hook_entity_use_pre", 0);
    server_print("Registered entity with ID #%i", entityID);
  }

  entityID = 168; // random multi_manager
  if (pev_valid(entityID)) {
    RegisterHamFromEntity(Ham_Use, entityID, "hook_entity_use_pre", 0);
    server_print("Registered entity with ID #%i", entityID);
  }

  entityID = 759; // random env_beam
  if (pev_valid(entityID)) {
    RegisterHamFromEntity(Ham_Use, entityID, "hook_entity_use_pre", 0);
    server_print("Registered entity with ID #%i", entityID);
  }
}

public hook_entity_use_pre(iButton, iCaller, iActivator, iUseType, Float: flValue)
{
  // Ignore these callers' uses
  if (iCaller == 242 || iCaller == 602) {
    return HAM_IGNORED;
  }

  fg_colorchat_print(0, 1, "button: %i, caller: %i, activator: %i, usetype: %i, flvalue: %f", iButton, iCaller, iActivator, iUseType, flValue);
  return HAM_HANDLED;
}

public find_entity_info()
{
  new entityID;
  new szTempClass[64];

  entityID = 1013;
  if(pev_valid(entityID)) {
    entity_get_string(entityID, EV_SZ_classname, szTempClass, charsmax(szTempClass));
    server_print("ID: %i, classname: %s", entityID, szTempClass);
  }

  entityID = 125;
  if(pev_valid(entityID)) {
    entity_get_string(entityID, EV_SZ_classname, szTempClass, charsmax(szTempClass));
    server_print("ID: %i, classname: %s", entityID, szTempClass);
  }
}

public find_trigger()
{
  new name[32];
  new triggerID;

  pev(1013, pev_targetname, name, charsmax(name)) ;
  triggerID = engfunc(EngFunc_FindEntityByString, 0, "target", name); // Find trigger that exectures the entity
  server_print("Trigger classname: %s, Trigger ID: %i", name, triggerID);

  pev(125, pev_targetname, name, charsmax(name)) ;
  triggerID = engfunc(EngFunc_FindEntityByString, 0, "target", name); // Find trigger that exectures the entity
  server_print("Trigger classname: %s, Trigger ID: %i", name, triggerID);
}

/*
 * Finding entity IDs
 */
public find_button(playerID)
{
  new szTempClass[64];
  new szTempEnt;
  
  szTempEnt = GetAimingEnt(playerID);
  
  if(pev_valid(szTempEnt)) {
    entity_get_string(szTempEnt, EV_SZ_classname, szTempClass, charsmax(szTempClass));
    fg_colorchat_print(playerID, playerID, "ID: %i, classname: %s", szTempEnt, szTempClass);
  }

  return PLUGIN_HANDLED;
}

GetAimingEnt(id)
{
  static Float:start[3], Float:view_ofs[3], Float:dest[3], i;
  
  pev(id, pev_origin, start);
  pev(id, pev_view_ofs, view_ofs);
  
  for( i = 0; i < 3; i++ )
  {
    start[i] += view_ofs[i];
  }
  
  pev(id, pev_v_angle, dest);
  engfunc(EngFunc_MakeVectors, dest);
  global_get(glb_v_forward, dest);
  
  for( i = 0; i < 3; i++ )
  {
    dest[i] *= 9999.0;
    dest[i] += start[i];
  }

  engfunc(EngFunc_TraceLine, start, dest, DONT_IGNORE_MONSTERS, id, 0);
  
  return get_tr2(0, TR_pHit);
}

list_classnames()
{
  new szTempClass[64];
  for (new entityID = 0; entityID < 3000; ++entityID) {
    if(pev_valid(entityID)) {
      entity_get_string(entityID, EV_SZ_classname, szTempClass, charsmax(szTempClass));
      server_print("#%i - Classname: %s", entityID, szTempClass);
    }
  }
}
