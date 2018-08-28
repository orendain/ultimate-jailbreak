#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <sqlvault_ex>
#include <fg_colorchat>
#include <uj_logs>

new const PLUGIN_NAME[] = "UJ | Cells";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

#define FLAG_ADMIN ADMIN_RCON

enum _:TOTAL_FORWARDS
{
  FW_CELLS_DOORS_OPENED
};
new g_forwards[TOTAL_FORWARDS];
new g_forwardResult;

// DB to store button entity info
new SQLVault:g_vault;

// Information about cell door button
new g_cellButton;
new g_buttonModel[32];
new g_buttonClass[32];

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

  // Handle cell door button (needs to be in plugin_precache or else Ham_Spawn isn't caught)
  g_vault = sqlv_open_local("uj_cells", true);
  load_cell_button();
  RegisterHam(Ham_Spawn, "func_button", "find_cell_button");
}

public plugin_natives()
{
  register_library("uj_cells");
  register_native("uj_cells_open_doors", "native_uj_cells_open_doors");
}

public plugin_init()
{
  register_plugin(PLUGIN_NAME, PLUGIN_VERS, PLUGIN_AUTH);

  // Setup for uj_core_open_cell_doors
  //setup_open_cell_doors_buttons();

  // Set cell door button
  register_concmd("uj_cells_set_button", "set_cell_button", FLAG_ADMIN);

  // Attack door to open
  //RegisterHam(Ham_TraceAttack, "func_door", "Fwd_DoorAttack");

  // Forwards
  g_forwards[FW_CELLS_DOORS_OPENED] = CreateMultiForward("uj_fw_cells_doors_opened", ET_IGNORE, FP_CELL);
}

public plugin_end()
{
  sqlv_close(g_vault);
}

/*
 * Natives
 */
public native_uj_cells_open_doors(pluginID, paramCount)
{
  new playerID = get_param(1);
  ExecuteHamB(Ham_Use, g_cellButton, playerID, playerID, 1, 1.0);
  entity_set_float(g_cellButton, EV_FL_frame, 0.0);
}

public set_cell_button(playerID, level, cid)
{
  if(!cmd_access(playerID,level,cid,1))
    return PLUGIN_HANDLED;
    
  new szTempModel[64];
  new szTempClass[64];
  new szTemp[64];
  new szTempEnt;
  new mapName[32];
  
  szTempEnt = GetAimingEnt(playerID);
  
  if(pev_valid(szTempEnt)) {
    entity_get_string(szTempEnt, EV_SZ_classname, szTempClass, charsmax(szTempClass));
    if(equal(szTempClass, "func_button")) {
      /*equal(szTempClass, "func_rot_button") ||
      equal(szTempClass, "button_target"))*/
      
      pev(szTempEnt, pev_model, szTempModel, 63);
      
      get_mapname(mapName, 31);
      strtolower(mapName);
      formatex(szTemp , 64, "%s#%s#", szTempModel, szTempClass);
      
      // Since find_cell_button was not called this map, activate this button manually
      g_cellButton = szTempEnt;
      RegisterHamFromEntity(Ham_Use, g_cellButton, "FwdCellButtonUsedPost", 1);

      sqlv_set_data(g_vault, mapName, szTemp);
      fg_colorchat_print(playerID, FG_COLORCHAT_BLUE, "^4Button saved!^1 (%s, %s)", szTempModel, szTempClass);
    
    }
    else{
      fg_colorchat_print(playerID, FG_COLORCHAT_RED, "^4Nope^1: That's not a button entity.");
    }
  }
  else{
    fg_colorchat_print(playerID, FG_COLORCHAT_RED, "^4Nope^1: Invalid entity.");
  }

  return PLUGIN_HANDLED;
}

public load_cell_button()
{
  //server_print("[uj_cells] Attampting to load from database");
  new szData[64];
  new mapName[32];
    
  get_mapname(mapName, 31);
  strtolower(mapName);
  
  sqlv_get_data(g_vault, mapName, szData, 64);
  //server_print("[uj_cells] Raw database values are (%s, %s)", mapName, szData);

  replace_all(szData , sizeof(szData)-1, "#", " ");
  parse(szData, g_buttonModel, 31, g_buttonClass, 31);
  //uj_logs_log_dev("[uj_cells] Cell button loaded from database (%s, %s).", g_buttonModel, g_buttonClass);
  server_print("[uj_cells] Cell button loaded from database (%s, %s).", g_buttonModel, g_buttonClass);
  
  return PLUGIN_HANDLED;
}

public find_cell_button(entityID)
{
  new entModel[32];
  new entClass[32];
  pev(entityID, pev_model, entModel, 31);
  entity_get_string(entityID, EV_SZ_classname, entClass, charsmax(entClass));

  //server_print("[uj_cells] Attempting to match (%s, %s) with (%s, %s).", entModel, entClass, g_buttonModel, g_buttonClass);
  
  if(equali(entModel, g_buttonModel) && equali(entClass, g_buttonClass)) {
    g_cellButton = entityID;
    server_print("[uj_cells] Accepted the button (%s, %s).", g_buttonModel, g_buttonClass);
    uj_logs_log_dev("[uj_cells] Accepted the button (%s, %s).", g_buttonModel, g_buttonClass);
    RegisterHamFromEntity(Ham_Use, entityID, "FwdCellButtonUsedPost", 1);
  }
}

/*
 * Events and Forwards
 */
public FwdCellButtonUsedPost(iButton, iCaller, iActivator, iUseType, Float: flValue)
{
  new entModel[32];
  new entClass[32];
  pev(iButton, pev_model, entModel, 31);
  entity_get_string(iButton, EV_SZ_classname, entClass, charsmax(entClass));

  if(equali(entModel, g_buttonModel) && equali(entClass, g_buttonClass)) {
    ExecuteForward(g_forwards[FW_CELLS_DOORS_OPENED], g_forwardResult, iActivator);
  }
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
