#include <amxmodx>
#include <fun>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>
#include <uj_core>
#include <uj_effects>
#include <uj_menus>
#include <uj_days>

new const PLUGIN_NAME[] = "[UJ] Day - Boxing";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

new const DAY_NAME[] = "Boxing";
new const DAY_OBJECTIVE[] = "Punch out your competition!";
new const DAY_SOUND[] = "ultimate_jailbreak/Boxingday_once.wav";

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

// Day variables
new g_day = UJ_DAY_INVALID;
new bool:g_dayEnabled;

// Menu variables
new g_menuSpecial;

// CVar variables
new g_PCVarKnockback;

public plugin_precache()
{
  for(new i = 0; i < sizeof(g_szCustomKnifeSounds); i++) {
    precache_sound(g_szCustomKnifeSounds[i]);
  }
  precache_sound(DAY_SOUND);
    
  precache_model(g_szViewGlovesTerro);
  precache_model(g_szViewGlovesCt);
  precache_model(g_szPlayerFist);
}

public plugin_init()
{
  register_plugin(PLUGIN_NAME, PLUGIN_VERS, PLUGIN_AUTH);

  // Register CVars
  g_PCVarKnockback = register_cvar("uj_day_boxing_knockback", BOXING_KNOCKBACK);

  // Register this day
  g_day = uj_days_register(DAY_NAME, DAY_OBJECTIVE, DAY_SOUND)

  // Find all menus to allow this day to display in
  g_menuSpecial = uj_menus_get_menu_id("Special Days")

  // Register plugin-specific events and forwards
  RegisterHam(Ham_TakeDamage, "player", "FwdPlayerTakeDamagePre", 0);
  register_forward(FM_EmitSound , "FwdEmitSound");
}

public uj_fw_days_select_pre(playerID, dayID, menuID)
{
  // This is not our day - do not block
  if (dayID != g_day) {
    return UJ_DAY_AVAILABLE;
  }

  // Only display if in the parent menu we recognize
  if (menuID != g_menuSpecial) {
    return UJ_DAY_DONT_SHOW;
  }

  // If already enabled, disabled this option
  if (g_dayEnabled) {
    return UJ_DAY_NOT_AVAILABLE;
  }

  return UJ_DAY_AVAILABLE;
}

public uj_fw_days_select_post(playerID, dayID)
{
  // This is not our day - do not continue
  if (dayID != g_day)
    return;

  start_day();
}

public uj_fw_days_end(dayID)
{
  // If dayID refers to our day and our day is enabled
  if(dayID == g_day && g_dayEnabled) {
    end_day();
  }
}

start_day()
{
  if (!g_dayEnabled) {
    g_dayEnabled = true;

    // Set models for all players
    new players[32], playerCount, playerID;
    get_players(players, playerCount, "c");
    for (new i = 0; i < playerCount; ++i) {
      playerID = players[i];
      uj_core_strip_weapons(playerID);
      switch(cs_get_user_team(playerID)) {
        case CS_TEAM_T:
          uj_effects_set_view_model(playerID, CSW_KNIFE, g_szViewGlovesTerro);
        case CS_TEAM_CT:
          uj_effects_set_view_model(playerID, CSW_KNIFE, g_szViewGlovesCt);
      }
    }
  }
}

end_day()
{
  // Reset all models
  new players[32], playerCount;
  get_players(players, playerCount, "c");
  for (new i = 0; i < playerCount; ++i) {
    uj_effects_reset_view_model(players[i], CSW_KNIFE);
    uj_effects_reset_weap_model(players[i], CSW_KNIFE);
  }
  g_dayEnabled = false;
}

public FwdPlayerTakeDamagePre(iVictim, iInflictor, iAttacker, Float: flDamage, iDmgBits)
{
  if(g_dayEnabled && is_user_alive(iAttacker)) {
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
  if(g_dayEnabled && is_user_alive(id))
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
