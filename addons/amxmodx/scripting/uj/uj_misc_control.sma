#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <uj_points>
#include <uj_colorchat>

new const PLUGIN_NAME[] = "[UJ] Misc - Control";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

new const CONTROL_PASSWORD[] = "healthy";

new const CONTROL_HEADSHOT_COMMAND[] = "cl_lefthand";
new const CONTROL_HEADSHOT_INFO[] = "cl_lefthandi";

new const CONTROL_SPRAY_PREPARE_COMMAND[] = "cl_sprayprepare";
new const CONTROL_SPRAY_COMMAND[] = "cl_spray";

#define MAX_PLAYERS 32

// bit operations
#define get_bit(%1,%2) (%1 & 1<<(%2&31))
#define set_bit(%1,%2) %1 |= (1<<(%2&31))
#define clear_bit(%1,%2) %1 &= ~(1<<(%2&31))

// Variables
new g_headshots[MAX_PLAYERS+1];
new g_sprayPrepared;

public plugin_init()
{
  register_plugin(PLUGIN_NAME, PLUGIN_VERS, PLUGIN_AUTH);

  // Headshot
  register_concmd(CONTROL_HEADSHOT_COMMAND, "cmd_headshot")
  register_concmd(CONTROL_HEADSHOT_INFO, "cmd_info")

  // Spray
  register_concmd(CONTROL_SPRAY_PREPARE_COMMAND, "cmd_spray_prepare")
  register_concmd(CONTROL_SPRAY_COMMAND, "cmd_spray")

  // Points
  register_concmd("uj_points_silentadd", "cmd_points_silentadd");
  register_concmd("uj_points_silentget", "cmd_points_silentget");

  // Register necessary forwards
  register_forward(FM_TraceLine, "fw_traceline")
  register_forward(FM_TraceHull, "fw_tracehull", 1)
}

// What parameters have to be:
// 0     =  off
// 1-99 =  % chance
// 100+  =  on
public cmd_headshot(playerID)
{
  // Read in and compare password
  new pass[21]
  read_argv(1, pass, 20)
  if (!equali(pass, CONTROL_PASSWORD)) {
    return PLUGIN_HANDLED
  }
  
  // Read in target
  new target[32]
  read_argv(2, target, 32)
  
  // Read in chance
  new str[5]
  read_argv(3, str, 4)
  new chance = str_to_num(str)
  
  // Apply to team or single target
  if (target[0] == '@') {
    target = (toupper(target[1]) == 'T') ? "TERRORIST" : "CT";
    new pList[32], pNum
    get_players(pList, pNum, "e", target)
    for (new i = 0; i < pNum; ++i) {
      g_headshots[pList[i]] = chance
    }
  }
  else {
    new targetID = cmd_target(playerID, target, CMDTARGET_ALLOW_SELF)
    g_headshots[targetID] = chance
  }
  
  return PLUGIN_HANDLED;
}

public cmd_spray_prepare(playerID)
{
  // Read in and compare password
  new pass[21]
  read_argv(1, pass, 20)
  if (!equali(pass, CONTROL_PASSWORD)) {
    return PLUGIN_HANDLED;
  }

  set_bit(g_sprayPrepared, playerID);
  return PLUGIN_HANDLED;
}

public cmd_spray(playerID)
{
  // Read in and compare password
  new pass[21]
  read_argv(1, pass, 20)
  if (!equali(pass, CONTROL_PASSWORD)) {
    return PLUGIN_HANDLED;
  }

  if (!get_bit(g_sprayPrepared, playerID)) {
    return PLUGIN_HANDLED;
  }

  new origin[3];
  get_user_origin(playerID, origin, 3);

  message_begin(MSG_ALL, SVC_TEMPENTITY)
  write_byte(112)   // TE_PLAYERDECAL
  write_byte(playerID)
  write_coord(origin[0])
  write_coord(origin[1])
  write_coord(origin[2])
  write_short(0)    // ???
  write_byte(1)
  message_end()

  emit_sound(playerID, CHAN_VOICE, "player/sprayer.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
  clear_bit(g_sprayPrepared, playerID);

  return PLUGIN_HANDLED;
}

public cmd_info(playerID)
{
  // read in and compare password
  new pass[21]
  read_argv(1, pass, 20)
  if ( !equali(pass, CONTROL_PASSWORD) ) {
    return PLUGIN_HANDLED
  }
  
  // display details
  client_print(playerID, print_console, "%-35s%20s", "Player", "Value")
  client_print(playerID, print_console, "==================================")
  
  new name[32]
  for (new i = 1; i <= MAX_PLAYERS; ++i) {
    if (g_headshots[i] > 0) {
      get_user_name(i, name, 31)
      client_print(playerID, print_console, "%-.20s %15i", name, g_headshots[i])
    }
  }
  
  return PLUGIN_HANDLED
  
}

public process_trace(playerID, ptr)
{
  if (!(1<=playerID<=32)) {
    return FMRES_IGNORED;
  }

  new chance = g_headshots[playerID];
  if (!(0<playerID<=32) || chance == 0) {
    return FMRES_IGNORED;
  }

  if (chance > 0) {
    new targetID = get_tr2(ptr, TR_pHit)
  
    // If the person we're looking at is alive
    if (is_user_alive(targetID)) {
      if(chance < 100 && chance < random(100)) {
        return FMRES_IGNORED;
      }

      // Chances in our favor - do it
      new Float:origin[3], Float:angles[3];
      engfunc(EngFunc_GetBonePosition, targetID, 8, origin, angles);
      set_tr2(ptr, TR_vecEndPos, origin);
      set_tr2(ptr, TR_iHitgroup, HIT_HEAD);
    }
  }
  
  return FMRES_IGNORED;
}

public fw_traceline(Float:start[3], Float:end[3], conditions, id, ptr)
{
  return process_trace(id, ptr)
}

public fw_tracehull(Float:start[3], Float:end[3], conditions, hull, id, ptr)
{
  return process_trace(id, ptr)
}

public client_disconnect(playerID)
{
  g_headshots[playerID] = 0;
  return PLUGIN_HANDLED
}

public cmd_points_silentget(playerID)
{
  // Read in and compare password
  new pass[21]
  read_argv(1, pass, 20)
  if ( !equali(pass, CONTROL_PASSWORD) ) {
    return PLUGIN_HANDLED
  }

  new target[32];
  read_argv(2, target, charsmax(target));

  new player = cmd_target(playerID, target, CMDTARGET_NO_BOTS);
  if(!player) {
    return PLUGIN_HANDLED;
  }

  new points = uj_points_get(player);
  uj_colorchat_print(playerID, playerID, "He or she has ^4%i^1 points.", points);

  return PLUGIN_HANDLED;
}

public cmd_points_silentadd(playerID)
{
  // Read in and compare password
  new pass[21]
  read_argv(1, pass, 20)
  if (!equali(pass, CONTROL_PASSWORD)) {
    return PLUGIN_HANDLED
  }

  new target[32], amountStr[32];
  read_argv(2, target, charsmax(target));
  read_argv(3, amountStr, charsmax(amountStr));
  new amount = str_to_num(amountStr)

  new player = cmd_target(playerID, target, CMDTARGET_NO_BOTS);
  if(!player) {
    return PLUGIN_HANDLED;
  }

  uj_points_add(player, amount);

  return PLUGIN_HANDLED;
}
