#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fun>
#include <hamsandwich>
#include <cs_player_models_api>
#include <cs_weap_models_api>
#include <fg_colorchat>
#include <uj_core>
#include <uj_logs>

new const PLUGIN_NAME[] = "UJ | Effects";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

new const ROCKET_SOUND[] = "weapons/rocket1.wav";
new const ROCKET_FIRE_SOUND[] = "weapons/rocketfire1.wav";

#define MAX_PLAYERS 32
#define CLAMP_SHORT(%1) clamp(%1, 0, 0xFFFF)

new Ham:Ham_Player_ResetMaxSpeed = Ham_Item_PreFrame;

enum _:TOTAL_FORWARDS
{
  FW_CORE_DETERMINE_SPEED = 0
};
new g_forwards[TOTAL_FORWARDS];
new g_forwardResult;

// For max speed
//new g_hasMaxSpeed;
//new Float:g_maxSpeeds[MAX_PLAYERS+1];

// For rocket
new gmsgDamage;
new rocket_z[33];
new mflash, smoke, blueflare2, white;

// For screen fade
new g_msgScreenFade;

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

public plugin_natives()
{
  register_library("uj_effects");

  //register_native("uj_effects_set_max_speed", "native_uj_effects_set_max_speed");
  register_native("uj_effects_reset_max_speed", "native_uj_effects_reset_speed");

  register_native("uj_effects_glow_player", "native_uj_effects_glow_player");
  register_native("uj_effects_glow_reset", "native_uj_effects_glow_reset");
  register_native("uj_effects_screen_fade", "native_uj_effects_screen_fade");
  register_native("uj_effects_set_visibility", "native_uj_e_set_visibility");
  register_native("uj_effects_reset_visibility", "native_uj_e_reset_visibility");
  register_native("uj_effects_rocket", "native_uj_effects_rocket");

  register_native("uj_effects_set_model", "native_uj_effects_set_model")
  register_native("uj_effects_reset_model", "native_uj_effects_reset_model")
  register_native("uj_effects_set_view_model", "native_uj_effects_set_v_m")
  register_native("uj_effects_reset_view_model", "native_uj_effects_reset_v_m")
  register_native("uj_effects_set_weap_model", "native_uj_effects_set_p_w_m")
  register_native("uj_effects_reset_weap_model", "native_uj_effects_reset_p_w_m")  
}

public plugin_precache()
{
  load_metamod();

  //Rocket Sounds
  precache_sound(ROCKET_SOUND);
  precache_sound(ROCKET_FIRE_SOUND);

  mflash = precache_model("sprites/muzzleflash.spr");
  smoke = precache_model("sprites/steam1.spr");
  blueflare2 = precache_model( "sprites/blueflare2.spr");
  white = precache_model("sprites/white.spr");
}

public plugin_init()
{
  register_plugin(PLUGIN_NAME, PLUGIN_VERS, PLUGIN_AUTH);

  // For controlling max speed
  RegisterHam(Ham_Player_ResetMaxSpeed, "player", "PlayerResetMaxSpeed", 1);

  // Forwards
  g_forwards[FW_CORE_DETERMINE_SPEED] = CreateMultiForward("uj_effects_determine_max_speed", ET_IGNORE, FP_CELL, FP_ARRAY);

  // For rocket
  gmsgDamage = get_user_msgid("Damage");
  g_msgScreenFade = get_user_msgid("ScreenFade");
}

public plugin_cfg()
{
  // Prevents CS from limiting player maxspeeds at 320
  server_cmd("sv_maxspeed 9999");
}

/*
 * Natives
 */
/*
public native_uj_effects_set_max_speed(pluginID, paramCount)
{
  new playerID = get_param(1);
  new Float:maxSpeed = get_param_f(2);

  set_bit(g_hasMaxSpeed, playerID);
  g_maxSpeeds[playerID] = maxSpeed;
}*/

public native_uj_effects_reset_speed(pluginID, paramCount)
{
  new playerID = get_param(1);
  //clear_bit(g_hasMaxSpeed, playerID);
  ExecuteHamB(Ham_Player_ResetMaxSpeed, playerID);
}

public native_uj_effects_glow_player(pluginID, paramCount)
{
  new playerID = get_param(1);
  new red = get_param(2);
  new green = get_param(3);
  new blue = get_param(4);
  new size = get_param(5);

  set_user_rendering(playerID, kRenderFxGlowShell, red, green, blue, kRenderNormal, size);
  screen_fade(playerID, red, green, blue);
}

public native_uj_effects_glow_reset(pluginID, paramCount)
{
  new playerID = get_param(1);
  set_user_rendering(playerID, kRenderFxNone, 0, 0, 0, kRenderNormal, 0);
}

public native_uj_effects_screen_fade(pluginID, paramCount)
{
  new playerID = get_param(1);
  new red = get_param(2);
  new green = get_param(3);
  new blue = get_param(4);
  new alpha = get_param(5);

  screen_fade(playerID, red, green, blue, alpha);
}

screen_fade(playerID, red, green, blue, alpha = 128, Float:duration = 1.5, Float:holdTime = 0.1)
{
  message_begin(MSG_ONE, g_msgScreenFade, _, playerID)
  write_short(CLAMP_SHORT(floatround(4096 * duration))); // duration, 1<<12 = 4096
  write_short(CLAMP_SHORT(floatround(4096 * holdTime))); // hold time
  write_short(0x0000); // fade type (fade in = 0x0000)
  write_byte(red); // red
  write_byte(green); // green
  write_byte(blue); // blue
  write_byte(alpha); // alpha
  message_end();
}

public native_uj_e_set_visibility(pluginID, paramCount)
{
  new playerID = get_param(1);
  new alpha = get_param(2);
  set_user_rendering(playerID, kRenderFxNone, 0, 0, 0, kRenderTransAlpha, alpha);
}

public native_uj_e_reset_visibility(pluginID, paramCount)
{
  new playerID = get_param(1);
  set_user_rendering(playerID, kRenderFxNone, 0, 0, 0, kRenderTransAlpha, 255);
}

public native_uj_effects_rocket(pluginID, paramCount)
{
  new playerID = get_param(1);
  emit_sound(playerID,CHAN_WEAPON ,"weapons/rocketfire1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM);
  fm_set_user_maxspeed(playerID, 0.01);
  set_task(1.2, "rocket_liftoff", playerID);
}


/*
 * Player models
 */
public native_uj_effects_set_model(pluginID, paramCount)
{
  new buffer[128]
  get_string(2, buffer, charsmax(buffer));
  cs_set_player_model(get_param(1), buffer)
}

public native_uj_effects_reset_model(pluginID, paramCount)
{
  cs_reset_player_model(get_param(1));
}


/*
 * View models
 */
public native_uj_effects_set_v_m(pluginID, paramCount)
{
  new buffer[192]
  get_string(3, buffer, charsmax(buffer));
  cs_set_player_view_model(get_param(1), get_param(2), buffer);
}

public native_uj_effects_reset_v_m(pluginID, paramCount)
{
  cs_reset_player_view_model(get_param(1), get_param(2));
}

public native_uj_effects_set_p_w_m(pluginID, paramCount)
{
  new buffer[128]
  get_string(3, buffer, charsmax(buffer));
  cs_set_player_weap_model(get_param(1), get_param(2), buffer);
}

public native_uj_effects_reset_p_w_m(pluginID, paramCount)
{
  cs_reset_player_weap_model(get_param(1), get_param(2));
}


/*
 * Forwards and Events
 */
public PlayerResetMaxSpeed(playerID)
{
  new Float:currentSpeed = entity_get_float(playerID, EV_FL_maxspeed);
  //fg_colorchat_print(playerID, playerID, "About to check speed - starting: %f", currentSpeed);
  if(is_user_alive(playerID) && currentSpeed != 1.0) {
    // Prepare data, execute forward, and set determined value
    new data[1];
    data[0] = floatround(currentSpeed);
    new arrayArg = PrepareArray(data, 1, 1);
  
    /*static Float:maxspeed;
    pev(playerID,pev_maxspeed,maxspeed)
    fg_colorchat_print(0,1, "%f", maxspeed); */

    ExecuteForward(g_forwards[FW_CORE_DETERMINE_SPEED], g_forwardResult, playerID, arrayArg);

    // Cast to make sure we have no problems
    new Float:result = float(data[0]);
    entity_set_float(playerID, EV_FL_maxspeed, result);

    //new authID[32];
    //get_user_authid(playerID, authID, charsmax(authID));
    //uj_logs_log_dev("[uj_effects] <%s> changed speed to %f", authID, result);
    //fg_colorchat_print(playerID, playerID, "changed speed to %f", result);
    //fg_colorchat_print(playerID, playerID, "total, %f, %f, %f", data[0], float(data[0]), result);
    //fg_colorchat_print(playerID, 1, "data %f and result %f", data[0], result);
  }
}


/*
 * Helper functions
 */
public rocket_liftoff(playerID)
{
  if (!is_user_alive(playerID)) return
  fm_set_user_gravity(playerID,-0.50)
  client_cmd(playerID, "+jump;wait;wait;-jump")
  emit_sound(playerID, CHAN_VOICE, ROCKET_SOUND, 1.0, 0.5, 0, PITCH_NORM)
  rocket_effects(playerID)
}

public rocket_effects(playerID)
{
  if (!is_user_alive(playerID)) return

  new vorigin[3]
  get_user_origin(playerID, vorigin)

  message_begin(MSG_ONE, gmsgDamage, {0,0,0}, playerID)
  write_byte(30) // dmg_save
  write_byte(30) // dmg_take
  write_long(1<<16) // visibleDamageBits
  write_coord(vorigin[0]) // damageOrigin.x
  write_coord(vorigin[1]) // damageOrigin.y
  write_coord(vorigin[2]) // damageOrigin.z
  message_end()

  if (rocket_z[playerID] == vorigin[2]) {
    rocket_explode(playerID)
  }

  rocket_z[playerID] = vorigin[2]

  //Draw Trail and effects

  //TE_SPRITETRAIL - line of moving glow sprites with gravity, fadeout, and collisions
  message_begin( MSG_BROADCAST, SVC_TEMPENTITY )
  write_byte( 15 )
  write_coord( vorigin[0]) // coord, coord, coord (start)
  write_coord( vorigin[1])
  write_coord( vorigin[2])
  write_coord( vorigin[0]) // coord, coord, coord (end)
  write_coord( vorigin[1])
  write_coord( vorigin[2] - 30)
  write_short( blueflare2 ) // short (sprite index)
  write_byte( 5 ) // byte (count)
  write_byte( 1 ) // byte (life in 0.1's)
  write_byte( 1 )  // byte (scale in 0.1's)
  write_byte( 10 ) // byte (velocity along vector in 10's)
  write_byte( 5 )  // byte (randomness of velocity in 10's)
  message_end()

  //TE_SPRITE - additive sprite, plays 1 cycle
  message_begin( MSG_BROADCAST,SVC_TEMPENTITY)
  write_byte( 17 )
  write_coord(vorigin[0])  // coord, coord, coord (position)
  write_coord(vorigin[1])
  write_coord(vorigin[2] - 30)
  write_short( mflash ) // short (sprite index)
  write_byte( 15 ) // byte (scale in 0.1's)
  write_byte( 255 ) // byte (brightness)
  message_end()

  set_task(0.2, "rocket_effects", playerID)
}

rocket_explode(playerID)
{
  if (is_user_alive(playerID)) {
    new vec1[3]
    get_user_origin(playerID,vec1)

    // blast circles
    message_begin( MSG_BROADCAST,SVC_TEMPENTITY,vec1)
    write_byte( 21 )
    write_coord(vec1[0])
    write_coord(vec1[1])
    write_coord(vec1[2] - 10)
    write_coord(vec1[0])
    write_coord(vec1[1])
    write_coord(vec1[2] + 1910)
    write_short( white )
    write_byte( 0 ) // startframe
    write_byte( 0 ) // framerate
    write_byte( 2 ) // life
    write_byte( 16 ) // width
    write_byte( 0 ) // noise
    write_byte( 188 ) // r
    write_byte( 220 ) // g
    write_byte( 255 ) // b
    write_byte( 255 ) //brightness
    write_byte( 0 ) // speed
    message_end()

    //Explosion2
    message_begin( MSG_BROADCAST,SVC_TEMPENTITY)
    write_byte( 12 )
    write_coord(vec1[0])
    write_coord(vec1[1])
    write_coord(vec1[2])
    write_byte( 188 ) // byte (scale in 0.1's)
    write_byte( 10 ) // byte (framerate)
    message_end()

    //smoke
    message_begin( MSG_BROADCAST,SVC_TEMPENTITY,vec1)
    write_byte( 5 )
    write_coord(vec1[0])
    write_coord(vec1[1])
    write_coord(vec1[2])
    write_short( smoke )
    write_byte( 2 )
    write_byte( 10 )
    message_end()

    user_kill(playerID,1)
  }

  //stop_sound
  emit_sound(playerID, CHAN_VOICE, ROCKET_SOUND, 0.0, 0.0, (1<<5), PITCH_NORM)

  fm_set_user_maxspeed(playerID,1.0)
  fm_set_user_gravity(playerID,1.00)
}

stock fm_set_user_maxspeed(index, Float:speed = -1.0) {
  engfunc(EngFunc_SetClientMaxspeed, index, speed)
  set_pev(index, pev_maxspeed, speed)
  return 1
}

stock fm_set_user_gravity(index, Float:gravity = 1.0) {
  set_pev(index, pev_gravity, gravity)
  return 1
}
