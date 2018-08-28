#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fun>
#include <uj_chargers>
#include <uj_core>
#include <uj_effects>
#include <uj_menus>
#include <uj_requests>

new const PLUGIN_NAME[] = "UJ | Request - Assassin";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

new const REQUEST_NAME[] = "Assassin";
new const REQUEST_OBJECTIVE[] = "Damn, motherf***er went rogue on us!  Kill on sight!";

// Request variables
new g_request;
new bool:g_requestEnabled;

// Menu variables
new g_menuLastRequests;

// Player variables
new g_playerID;

public plugin_precache()
{
  // Register request
  g_request = uj_requests_register(REQUEST_NAME, REQUEST_OBJECTIVE);
}

public plugin_init()
{
  register_plugin(PLUGIN_NAME, PLUGIN_VERS, PLUGIN_AUTH);

  // Find all valid menus to display this under
  g_menuLastRequests = uj_menus_get_menu_id("Last Request");

  // For wallclimbing
  register_forward(FM_PlayerPreThink, "Fwd_PlayerPreThink");
  register_forward(FM_Touch, "Fwd_Touch");
}

public uj_fw_requests_select_pre(playerID, requestID, menuID)
{
  // This is not our request - do not block
  if (requestID != g_request) {
    return UJ_REQUEST_AVAILABLE;
  }

  // Only display if in the parent menu we recognize
  if (menuID != g_menuLastRequests) {
    return UJ_REQUEST_DONT_SHOW;
  }

  // If we *can* show the menu, but it's already enabled,
  // then have it be unavailable
  if (g_requestEnabled) {
    return UJ_REQUEST_NOT_AVAILABLE;
  }

  // Set request as endless
  uj_requests_set_endless();

  return UJ_REQUEST_AVAILABLE;
}

public uj_fw_requests_select_post(playerID, targetID, requestID)
{
  // This is not our request
  if (requestID != g_request)
    return;

  start_request(playerID);
}

start_request(playerID)
{
  if(!g_requestEnabled) {
    g_requestEnabled = true;

    // Set health and armor
    set_pev(playerID, pev_health, 1.0);
    uj_effects_set_visibility(playerID, 0);
    set_user_footsteps(playerID, 1);
    set_user_gravity(playerID, 0.6);

    uj_core_strip_weapons(playerID);
    uj_core_block_weapon_pickup(playerID, true);

    uj_chargers_block_heal(0, true);
    uj_chargers_block_armor(0, true);
    
    set_lights("c");

    g_playerID = playerID;
  }
}

public uj_fw_requests_end(requestID)
{
  // If requestID refers to our request and our request is enabled
  if(requestID == g_request && g_requestEnabled) {
    g_requestEnabled = false;

    uj_effects_reset_visibility(g_playerID);
    set_user_footsteps(g_playerID, 0);
    set_user_gravity(g_playerID, 1.0);
    
    uj_core_block_weapon_pickup(g_playerID, false);

    uj_chargers_block_heal(0, false);
    uj_chargers_block_armor(0, false);

    set_lights("m");
  }
}

public Fwd_PlayerPreThink(playerID)  
{ 
  if(g_requestEnabled && (playerID == g_playerID)) {
    new button = get_user_button(playerID);
    if(button & IN_USE || button & IN_RELOAD) {
      // Use button = climb
      wallclimb(playerID, button);
    }
  }
}

new Float:g_wallorigin[32][3];
public Fwd_Touch(playerID, world)
{
  if(!g_requestEnabled || (playerID != g_playerID))
    return FMRES_IGNORED;
    
  static classname[32];
  pev(world, pev_classname, classname, 31);
  
  if((cs_get_user_team(playerID) == CS_TEAM_CT) &&
    (equal(classname, "worldspawn") ||
      equal(classname, "func_wall") ||
      equal(classname, "func_breakable"))) {
        pev(playerID, pev_origin, g_wallorigin[playerID]);
  }
  return FMRES_IGNORED;
}

public wallclimb(playerID, button)
{
  static Float:origin[3]; 
  pev(playerID, pev_origin, origin);
  
  /*if(button & IN_RELOAD && !get_bit(g_bTeleport, playerID) && g_bTeleportUsed[playerID] < 3)
  { 
    g_bTeleportUsed[playerID]++;
    fg_colorchat_print(playerID, FG_COLORCHAT_BLUE, "You have ^4%d^1 teleports left!", (3-g_bTeleportUsed[playerID]));

    emit_sound(playerID, CHAN_AUTO, NIGHTCRAWLERS_TELEPORT_SOUND, 1.0, ATTN_NORM, 0, PITCH_NORM);
    set_bit(g_bTeleport, playerID);
    set_task(5.0, "resetteleport", playerID);
    static Float:start[3], Float:dest[3];
    pev(playerID, pev_origin, start);
    pev(playerID, pev_view_ofs, dest);
    xs_vec_add(start, dest, start);
    
    pev(playerID, pev_v_angle, dest);
    engfunc(EngFunc_MakeVectors, dest);
    global_get(glb_v_forward, dest);
    xs_vec_mul_scalar(dest, 9999.0, dest);
    xs_vec_add(start, dest, dest);
    
    engfunc(EngFunc_TraceLine, start, dest, IGNORE_MONSTERS, playerID, 0);
    get_tr2(0, TR_vecEndPos, start);
    get_tr2(0, TR_vecPlaneNormal, dest);
    
    static const player_hull[] = { HULL_HUMAN, HULL_HEAD };
    engfunc(EngFunc_TraceHull, start, start, DONT_IGNORE_MONSTERS, player_hull[_:!!(pev(playerID, pev_flags) & FL_DUCKING)], playerID, 0);
    if (!get_tr2(0, TR_StartSolid) && !get_tr2(0, TR_AllSolid) && get_tr2(0, TR_InOpen)) {
      engfunc(EngFunc_SetOrigin, playerID, start);
      return FMRES_HANDLED;
    }
    
    static Float:size[3];
    pev(playerID, pev_size, size);
    xs_vec_mul_scalar(dest, (size[0] + size[1]) / 2.0, dest);
    xs_vec_add(start, dest, dest);
    
    engfunc(EngFunc_SetOrigin, playerID, dest);
    if(is_user_stuck(playerID))
      ClientCommand_UnStuck(playerID);
    return FMRES_HANDLED;
  } */
  
  if(get_distance_f(origin, g_wallorigin[playerID]) > 10.0) 
    return FMRES_IGNORED;
  
  if(get_entity_flags(playerID) & FL_ONGROUND) 
    return FMRES_IGNORED; 

  if(button & IN_FORWARD) {
    static Float:velocity[3]; 
    velocity_by_aim(playerID, 275, velocity); 
    set_user_velocity(playerID, velocity); 
  }
  else if(button & IN_BACK) {
    static Float:velocity[3]; 
    velocity_by_aim(playerID, -120, velocity);
    set_user_velocity(playerID, velocity);
  }
  return FMRES_IGNORED; 
}
