#include <amxmodx>
#include <cstrike>
#include <fakemeta>
#include <fun>
#include <hamsandwich>
#include <uj_colorchat>
#include <uj_core>
#include <uj_effects>
#include <uj_menus>
#include <uj_requests>

new const PLUGIN_NAME[] = "[UJ] Request - Boxing Duel";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

new const REQUEST_NAME[] = "Boxing Duel";
new const REQUEST_OBJECTIVE[] = "Do you even lift, bro?!";

new const BOXING_KNOCKBACK[] = "10";

new const g_szViewGlovesTerro[] = "models/ultimate_jailbreak/v_gloves_t.mdl";
new const g_szViewGlovesCt[]    = "models/ultimate_jailbreak/v_gloves_ct.mdl";
new const g_szPlayerFist[]      = "models/ultimate_jailbreak/p_bknuckles.mdl";

new const g_szKnifeSounds[][] =
{
  "weapons/knife_deploy1.wav",
  "weapons/knife_hit1.wav",
  "weapons/knife_hit2.wav",
  "weapons/knife_hit3.wav",
  "weapons/knife_hit4.wav",
  "weapons/knife_hitwall1.wav",
  "weapons/knife_slash1.wav",
  "weapons/knife_slash2.wav",
  "weapons/knife_stab.wav"
};

new const g_szCustomKnifeSounds[][] = 
{
  "ultimate_jailbreak/boxing_deploy1.wav",
  "ultimate_jailbreak/bknuckles/knife_hit1.wav",
  "ultimate_jailbreak/bknuckles/knife_hit2.wav",
  "ultimate_jailbreak/bknuckles/knife_hit3.wav",
  "ultimate_jailbreak/bknuckles/knife_hit4.wav",
  "ultimate_jailbreak/bknuckles/knife_hit4.wav",
  "weapons/knife_slash1.wav",
  "weapons/knife_slash2.wav",
  "ultimate_jailbreak/bknuckles/knife_stab.wav"
};

// Request variables
new g_request;
new bool:g_requestEnabled;
new g_playerID;
new g_targetID;

// Menu variables
new g_menuLastRequests;

// CVar variables
new g_PCVarKnockback;

public plugin_precache()
{
  for(new i = 0; i < sizeof(g_szCustomKnifeSounds); i++) {
    precache_sound(g_szCustomKnifeSounds[i]);
  }
    
  precache_model(g_szViewGlovesTerro);
  precache_model(g_szViewGlovesCt);
  precache_model(g_szPlayerFist);
}

public plugin_init()
{
  register_plugin(PLUGIN_NAME, PLUGIN_VERS, PLUGIN_AUTH);

  // Find all valid menus to display this under
  g_menuLastRequests = uj_menus_get_menu_id("Last Request")

  // Register CVars
  g_PCVarKnockback = register_cvar("uj_request_boxingduel_knockback", BOXING_KNOCKBACK);

  // Register request
  g_request = uj_requests_register(REQUEST_NAME, REQUEST_OBJECTIVE)

  // Register plugin-specific events and forwards
  RegisterHam(Ham_TakeDamage, "player", "FwdPlayerTakeDamagePre", 0);
  register_forward(FM_EmitSound , "FwdEmitSound");
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

  return UJ_REQUEST_AVAILABLE;
}

public uj_fw_requests_select_post(playerID, targetID, requestID)
{
  // This is not our request
  if (requestID != g_request)
    return;

  start_request(playerID, targetID);
}

start_request(playerID, targetID)
{
  if (!g_requestEnabled) {
    // Strip users of weapons, and give out knives/gloves
    uj_core_strip_weapons(playerID);
    uj_core_strip_weapons(targetID);

    uj_effects_set_view_model(playerID, CSW_KNIFE, g_szViewGlovesTerro);
    uj_effects_set_view_model(targetID, CSW_KNIFE, g_szViewGlovesCt);

    // Set health
    set_pev(playerID, pev_health, 150.0);
    set_pev(targetID, pev_health, 150.0);

    // Give armor
    cs_set_user_armor(playerID, 100, CS_ARMOR_VESTHELM)
    cs_set_user_armor(targetID, 100, CS_ARMOR_VESTHELM)

    g_playerID = playerID;
    g_targetID = targetID;
    g_requestEnabled = true;
  }
}

public uj_fw_requests_end(requestID)
{
  // If requestID refers to our request and our request is enabled
  if(g_requestEnabled && requestID == g_request) {

    uj_effects_reset_view_model(g_playerID, CSW_KNIFE);
    uj_effects_reset_view_model(g_targetID, CSW_KNIFE);

    g_requestEnabled = false;
  }
}

public FwdPlayerTakeDamagePre(iVictim, iInflictor, iAttacker, Float: flDamage, iDmgBits)
{
  if(g_requestEnabled && is_user_alive(iAttacker)) {
    new Float: vecVelocity[3];
    new Float: vecOldVelocity[3];
    pev(iVictim, pev_velocity, vecOldVelocity);
    create_velocity_vector(iVictim, iAttacker , vecVelocity);

    vecVelocity[0] += vecOldVelocity[0];
    vecVelocity[1] += vecOldVelocity[1];
    
    set_pev(iVictim, pev_velocity, vecVelocity);
    
    new Float: vecPunchAngle[3];
    for(new i = 0; i < 3; i++) 
      vecPunchAngle[i] = random_float(100.0, 150.0);
      
    set_pev(iVictim, pev_punchangle, vecPunchAngle);
  }
  
  return HAM_IGNORED;
}

public FwdEmitSound(id, iChannel, const szSound[], Float: flVolume, Float: iAttn, iFlags, iPitch)
{
  if(g_requestEnabled && is_user_alive(id))
  {
    for(new i = 0; i < sizeof(g_szKnifeSounds); i++)
    {
      if(equal(szSound, g_szKnifeSounds[i]))
      {
        emit_sound(id, iChannel, g_szCustomKnifeSounds[i], flVolume, iAttn, iFlags, iPitch);
        return FMRES_SUPERCEDE;
      }
    }
  }
  
  return FMRES_IGNORED;
}

create_velocity_vector(iVictim, iAttacker, Float: vVelocity[3])
{
  if(!is_user_alive(iVictim) || !is_user_alive(iAttacker))
    return 0;

  new Float:vVictimOrigin[3];
  new Float:vAttackerOrigin[3];
  // entity_get_vector(iVictim   , EV_VEC_origin , vVictimOrigin);
  // entity_get_vector(iAttacker , EV_VEC_origin , vAttackerOrigin);
  pev(iVictim, pev_origin, vVictimOrigin);
  pev(iAttacker, pev_origin, vAttackerOrigin);

  new Float: vOrigin2[3]
  vOrigin2[0] = vVictimOrigin[0] - vAttackerOrigin[0];
  vOrigin2[1] = vVictimOrigin[1] - vAttackerOrigin[1];

  new Float: flLargestNumber = 0.0;
  if(floatabs(vOrigin2[0]) > flLargestNumber) 
    flLargestNumber = floatabs(vOrigin2[0]);
    
  if(floatabs(vOrigin2[1]) > flLargestNumber) 
    flLargestNumber = floatabs(vOrigin2[1]);

  vOrigin2[0] /= flLargestNumber;
  vOrigin2[1] /= flLargestNumber;

  new Float: flForce = get_pcvar_float(g_PCVarKnockback);
  // new iDistance = get_entity_distance(iVictim, iAttacker);
  new iDistance = floatround(get_distance_f(vVictimOrigin, vAttackerOrigin));
  vVelocity[0] = (vOrigin2[0] * (flForce * 3000)) / iDistance;
  vVelocity[1] = (vOrigin2[1] * (flForce * 3000)) / iDistance;
  
  if(vVelocity[0] <= 20.0 || vVelocity[1] <= 20.0)
    vVelocity[2] = random_float(200.0 , 275.0);

  return 1;
}
