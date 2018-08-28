#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <uj_core>
#include <uj_days>
#include <uj_effects>

new const PLUGIN_NAME[] = "UJ | Misc - Fists";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

new const FISTS_MODEL_V[] = "models/fg_knives/v_bknuckles.mdl";
new const FISTS_MODEL_P[] = "models/fg_knives/p_bknuckles.mdl";

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
  "ultimate_jailbreak/bknuckles/knife_hit4.wav"
};

new g_hasFists;

public plugin_init()
{
  register_plugin(PLUGIN_NAME, PLUGIN_VERS, PLUGIN_AUTH);

  // Player spawn
  RegisterHam(Ham_Spawn, "player", "fwHamPlayerSpawnPost", 1);

  // To override sounds
  register_forward(FM_EmitSound , "FwdEmitSound");
}

public plugin_precache()
{
  for(new i = 0; i < sizeof(g_szCustomKnifeSounds); i++) {
    precache_sound(g_szCustomKnifeSounds[i]);
  }

  precache_model(FISTS_MODEL_V);
  precache_model(FISTS_MODEL_P);
}

/*
public client_putinserver(playerID)
{
  uj_effects_set_view_model(playerID, CSW_KNIFE, FISTS_MODEL_V);
  uj_effects_set_weap_model(playerID, CSW_KNIFE, FISTS_MODEL_P);
}
*/

public client_disconnect(playerID)
{
  clear_bit(g_hasFists, playerID);
}

public fwHamPlayerSpawnPost(playerID)
{
  if(!get_bit(g_hasFists, playerID) && is_user_connected(playerID)) {
    uj_effects_set_view_model(playerID, CSW_KNIFE, FISTS_MODEL_V);
    uj_effects_set_weap_model(playerID, CSW_KNIFE, FISTS_MODEL_P);

    set_bit(g_hasFists, playerID);
  }
}

// Models can be reset during the following:
// End of special days (e.g. boxing, nightcrawlers)

public uj_fw_days_end(requestID)
{
  // Make sure we still have our custom model enabled
  for (new playerID = 1; playerID <= 32; ++playerID) {
    if (is_user_connected(playerID)) {
      uj_effects_set_view_model(playerID, CSW_KNIFE, FISTS_MODEL_V);
      uj_effects_set_weap_model(playerID, CSW_KNIFE, FISTS_MODEL_P);
    }
  }
}

public FwdEmitSound(id, iChannel, const szSound[], Float: flVolume, Float: iAttn, iFlags, iPitch)
{
  if(is_user_alive(id)) {
    for(new i = 0; i < sizeof(g_szKnifeSounds); i++) {
      if(equal(szSound, g_szKnifeSounds[i])) {
        switch (i) {
          case 3: i = 1;
          case 4: i = 3;
          case 5: i = 3;
          case 6: i = -1;
          case 7: i = -1;
          case 8: i = 1;
        }
        if (i != -1) {
          emit_sound(id, iChannel, g_szCustomKnifeSounds[i], flVolume, iAttn, iFlags, iPitch);
          return FMRES_SUPERCEDE;
        }
        else {
          return FMRES_IGNORED;
        }
      }
    }
  }
  
  return FMRES_IGNORED;
}
