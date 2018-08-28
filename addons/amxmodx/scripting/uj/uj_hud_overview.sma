#include <amxmodx>
#include <cstrike>
#include <engine>
#include <fg_colorchat>
#include <uj_core>

new const PLUGIN_NAME[] = "UJ | HUD - Overview";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

// HUD variables
new g_timerEntity;

public plugin_init()
{
  register_plugin(PLUGIN_NAME, PLUGIN_VERS, PLUGIN_AUTH);

  // Find timerEntity
  g_timerEntity = create_entity("info_target");
  entity_set_string(g_timerEntity, EV_SZ_classname, "hud_entity");
  register_think("hud_entity", "FwdHudThink");
  entity_set_float(g_timerEntity, EV_FL_nextthink, get_gametime() + 1.0);
}

public FwdHudThink(iEntity)
{
  if (iEntity != g_timerEntity)
    return;
  
  // Find the number of players
  new prisonerCount = uj_core_get_prisoner_count();
  new prisonerLiveCount = uj_core_get_live_prisoner_count();
  
  new guardCount = uj_core_get_guard_count();
  new guardLiveCount = uj_core_get_live_guard_count();
  
  //set_hudmessage(0, 255, 0, -1.0, 0.01, 0, 0.75, 0.75, 0.75, 0.75, 3);
  ////set_dhudmessage( red = 0, green = 160, blue = 0, Float:x = -1.0, Float:y = 0.65, effects = 2, Float:fxtime = 6.0, Float:holdtime = 3.0, Float:fadeintime = 0.1, Float:fadeouttime = 1.5, channel = 4 (1-4, -1 for next free))
  set_hudmessage(0, 255, 0, -1.0, 0.01, 0, 2.0, 2.0, 0.0, 0.0, 3);
  show_hudmessage(0,"%s^nPrisoners Alive:   %i / %i^nGuards Alive:   %i / %i", FG_COLORCHAT_PREFIX, prisonerLiveCount, prisonerCount, guardLiveCount, guardCount);
  
  entity_set_float( g_timerEntity, EV_FL_nextthink, get_gametime() + 1.0 );
}
