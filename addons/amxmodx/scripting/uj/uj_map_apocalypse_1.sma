#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <uj_colorchat>

new const PLUGIN_NAME[] = "[UJ] Map - Apocalypse 1";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

/*
#1      ID: 246, classname: func_button
#2      ID: 247, classname: func_button
#3      ID: 249, classname: func_button
#4      ID: 245, classname: func_button
#5      ID: 248, classname: func_button
#6      ID: 250, classname: func_button
#7      ID: 244, classname: func_button
#8      ID: 252, classname: func_button
#9      ID: 251, classname: func_button
#0      ID: 253, classname: func_button
Red     ID: 243, classname: func_button
Green   ID: 254, classname: func_button
Door    ID: 225, classname: func_door
DButton ID: 221
*/

new const DOOR_BUTTONS_AVAILABLE[] = {
  246, 247, 249, 245, 248, 250, 244, 252, 251, 253, 243, 254
}

new const DOOR_BUTTON_SEQUENCE[] = {
  250, 250, 251, 254
}

new const DOOR_OPEN_BUTTON = 221;

new g_sequencePosition;

public plugin_init()
{
  register_plugin(PLUGIN_NAME, PLUGIN_VERS, PLUGIN_AUTH);

  RegisterHam(Ham_Think, "func_button", "FwdDoorButtonThink")

  //register_concmd("find_button", "find_button");
  //register_buttons();
}

public FwdDoorButtonThink(entityID)
{
  for (new i = 0; i < sizeof(DOOR_BUTTONS_AVAILABLE); ++i) {
    if (entityID == DOOR_BUTTONS_AVAILABLE[i]) {
      if (entityID == DOOR_BUTTON_SEQUENCE[g_sequencePosition]) {
        ++g_sequencePosition;
        //uj_colorchat_print(0, UJ_COLORCHAT_RED, "so far so good");
      }
      else {
        g_sequencePosition = 0;
        //uj_colorchat_print(0, UJ_COLORCHAT_RED, "Wrong, reset");
      }

      if (g_sequencePosition == sizeof(DOOR_BUTTON_SEQUENCE)) {
        // Success, open the door
        ExecuteHamB(Ham_Use, DOOR_OPEN_BUTTON, 0, 0 , 1, 1.0);
        g_sequencePosition = 0;
      }
      //uj_colorchat_print(0, UJ_COLORCHAT_RED, "buttonUsed: %i", entityID);
      return;
    }
  }
}

/*register_buttons()
{
  new entityID;
  for (new i = 0; i < sizeof(DOOR_BUTTONS_AVAILABLE); ++i) {
    entityID = DOOR_BUTTONS_AVAILABLE[i];
    if (pev_valid(entityID)) {
      RegisterHamFromEntity(Ham_Use, entityID, "FwdDoorButtonUsedPost", 1);
      server_print("Registered entity # %i : %i", i, entityID);
    }
  }

  new name[32];
  pev(225, pev_targetname, name, charsmax(name)) ;
  new doorButton = engfunc(EngFunc_FindEntityByString, 0, "target", name) // find button that opens this door
  server_print("door's targetname: %s, doorButton: %i", name, doorButton);
}

public FwdDoorButtonUsedPost(iButton, iCaller, iActivator, iUseType, Float: flValue)
{
  //uj_colorchat_print(0, UJ_COLORCHAT_RED, "iActivator = %i, buttonUsed: %i", iActivator, iButton);
  for(new i = 0; i < sizeof(g_buttons); i++) {
    if(iButton == g_buttons[i]) {
      ExecuteForward(g_forwards[FW_CORE_CELLS_OPENED], g_forwardResult, iActivator);
      break;
    }
  }
}

public find_button(playerID)
{

  ExecuteHamB(Ham_Use, 221, playerID, playerID, 1, 1.0);

  new szTempModel[64];
  new szTempClass[64];
  new szTemp[64];
  new szTempEnt;
  new Map[32];
  new szKey[32];
  
  szTempEnt = GetAimingEnt(playerID);
  
  if( pev_valid(szTempEnt) )
  {
    entity_get_string( szTempEnt, EV_SZ_classname, szTempClass, charsmax( szTempClass ) );
    uj_colorchat_print(playerID, playerID, "ID: %i, classname: %s", szTempEnt, szTempClass);
  }
  else{
    //fnColorPrint(id, "%L", LANG_SERVER, "JB_DAY_M70");
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
*/
