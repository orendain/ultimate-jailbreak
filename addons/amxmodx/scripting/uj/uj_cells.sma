#include <amxmodx>
#include <sqlvault_ex>
#include <uj_colorchat>

new const PLUGIN_NAME[] = "[UJ] Cells";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

#define FLAG_ADMIN ADMIN_RCON

enum _:TOTAL_FORWARDS
{
  FW_CORE_CELLS_OPENED
};
new g_forwards[TOTAL_FORWARDS];
new g_forwardResult;

// DB to store button entity info
new SQLVault:g_vault;

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
  register_library("uj_cells")
  register_native("uj_core_open_cell_doors", "native_uj_core_open_cell_doors");
}

public plugin_init()
{
  register_plugin(PLUGIN_NAME, PLUGIN_VERS, PLUGIN_AUTH);

  // Setup for uj_core_open_cell_doors
  setup_open_cell_doors_buttons();

  // Set cell door button
	register_concmd("uj_cells_set_button", "set_cell_button", FLAG_ADMIN);

	// Handle cell door button
	g_vault = sqlv_open_local("uj_cells", true);
	load_cell_button();
	RegisterHam(Ham_Spawn, "func_button", "find_cell_button");

	// Attack door to open
	RegisterHam(Ham_TraceAttack, "func_door", "Fwd_DoorAttack");

	// Forwards
  g_forwards[FW_CORE_CELLS_OPENED] = CreateMultiForward("uj_fw_cells_doors_opened", ET_IGNORE, FP_CELL);
}

public plugin_end(
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
  entity_set_float(g_buttons[i], EV_FL_frame, 0.0);
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
  new szKey[32];
  
  szTempEnt = GetAimingEnt(playerID);
  
  if(pev_valid(szTempEnt)) {
    entity_get_string(szTempEnt, EV_SZ_classname, szTempClass, charsmax(szTempClass));
    if(equal(szTempClass, "func_button") {
    	/*equal(szTempClass, "func_rot_button") ||
    	equal(szTempClass, "button_target"))*/
      
      pev(szTempEnt, pev_model, szTempModel, 63);
      iEnt = szTempEnt;
      log_amx("%s", iEnt);
      
      get_mapname(mapName, 31);
      strtolower(mapName);
      formatex(szTemp , 64, "%s#%s#", szTempModel, szTempClass);
      
      sqlv_set_data(g_vault, mapName, szTemp);
      uj_colorchat_print(playerID, UJ_COLORCHAT_BLUE, "^4Button saved!^1 (%s, %s)", szTempModel, szTempClass);
    
    }
    else{
      uj_colorchat_print(playerID, UJ_COLORCHAT_RED, "^4Nope^1: That's not a button entity.");
    }
  }
  else{
    uj_colorchat_print(playerID, UJ_COLORCHAT_RED, "^4Nope^1: Invalid entity.");
  }

  return PLUGIN_HANDLED;
}

public load_cell_button()
{
	new szData[64];
	new mapName[32];
	new szKey[32];
		
	get_mapname(mapName, 31);
	strtolower(mapName);
	
	sqlv_get_data(g_vault, mapName, szData, 64);

	replace_all(szData , sizeof(szData)-1, "#", " ");
	parse(szData, g_buttonModel, 31, g_buttonClass, 31);
	uj_logs_log_dev("[uj_cells] Cell button loaded from database (%s, %s).", g_buttonModel, g_buttonClass);
	
	return PLUGIN_HANDLED;
}

public find_cell_button(entityID)
{
	new entModel[32];
	new entClass[32];
	pev(entityID, pev_model, entModel, 31);
	entity_get_string(entityID, EV_SZ_classname, entClass, charsmax(entClass));
	
	if(equali(entModel, g_buttonModel) && equali(entClass, g_buttonClass)) {
		g_cellButton = entityID;
		//RegisterHamFromEntity(Ham_Use, entityID, "FwdCellButtonUsedPost", 1);
	}
}

/*
 * Events and Forwards
 */
public FwdCellButtonUsedPost(iButton, iCaller, iActivator, iUseType, Float: flValue)
{
  ExecuteForward(g_forwards[FW_CELLS_DOORS_OPENED], g_forwardResult, iActivator);
}

public Fwd_DoorAttack(const door, const id, Float:damage, Float:direction[3], const tracehandle, const damagebits)
{	
	if(is_valid_ent(door)) {
		ExecuteHamB(Ham_Use, door, id, 0, 1, 1.0);
		entity_set_float(door, EV_FL_frame, 0.0);
	}
	return HAM_IGNORED;
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
