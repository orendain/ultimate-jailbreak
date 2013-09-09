#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <engine>
#include <entity_maths> //this has the function for the "heat-seeking" rockets
#include <fakemeta>
#include <fun>
#include <uj_core>
#include <uj_effects>
#include <uj_menus>
#include <uj_items>
#include <uj_colorchat>

new const PLUGIN_NAME[] = "[UJ] Item - Bazooka";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

new const ITEM_NAME[] = "Bazooka";
new const ITEM_MESSAGE[] = "Awwwww yeeeaaaah ... time to blow this joint!";
new const ITEM_COST[] = "300";
new const ITEM_REBEL[] = "1";

new const BAZOOKA_MODES[][] =
{
  "Bazooka",
  "Heat-Seeking",
  "User-Guided"
}

#define MAX_PLAYERS 32

// Menu variables
new g_menuShop;
new g_item;

// Common CVars
new g_costCVar;
new g_rebelCVar;

// Specific item CVars
new g_ammoPCVar;
new g_damageRadiusPCVar;
new g_maxDamagePCVar;
new g_reloadTimePCVar;
new g_trailTimePCVar;
new g_velocityPCVar;
new g_teamColorsPCVar;
new g_gibPCVar;

// Keep track of who has this item
new g_hasItem;
new g_bazookaAmmo[MAX_PLAYERS+1];
new g_canShoot;
new g_bazookaMode[MAX_PLAYERS+1];

// Set this value to 1 if you are using Condition Zero
// I have NOT tested this plugin with CZ so I do not know if it will work
#define CZERO 0

#define TE_EXPLOSION    3
#define TE_EXPLFLAG_NONE  0
#define TE_SMOKE    5
#define TE_BLOODSPRITE    115
#define TE_BLOODSTREAM    101
#define TE_MODEL    106
#define TE_WORLDDECAL   116
#define BA_NORMAL     (1<<0) // "a"
#define BA_HEAT     (1<<1) // "b"
#define BA_USER     (1<<2) // "c"

new g_sModelIndexFireball, g_sModelIndexSmoke, rocketsmoke
new user_controll[32]
new mdl_gib_flesh, mdl_gib_head, mdl_gib_legbone, mdl_gib_lung, mdl_gib_meat, mdl_gib_spine, spr_blood_drop, spr_blood_spray
new gHealthIndex[33]

public plugin_precache()
{
  precache_model("models/rpgrocket.mdl")
  //precache_model("models/w_rpg.mdl")
  precache_model("models/v_rpg.mdl")
  precache_model("models/p_rpg.mdl")

  precache_sound("weapons/rocketfire1.wav")
  //precache_sound("items/gunpickup4.wav")
  precache_sound("weapons/nuke_fly.wav")// <-- this is the only non-game sound file, make sure you have it
  //precache_sound("weapons/dryfire1.wav")

  // Also set g_gibPCVar to 0
  /*spr_blood_drop = precache_model("sprites/blood.spr")
  spr_blood_spray = precache_model("sprites/bloodspray.spr")
  mdl_gib_flesh = precache_model("models/Fleshgibs.mdl")
  mdl_gib_head = precache_model("models/GIB_Skull.mdl")
  mdl_gib_legbone = precache_model("models/GIB_Legbone.mdl")
  mdl_gib_lung = precache_model("models/GIB_Lung.mdl")
  mdl_gib_meat = precache_model("models/GIB_B_Gib.mdl")
  mdl_gib_spine = precache_model("models/GIB_B_Bone.mdl")
  */
  
  g_sModelIndexFireball = precache_model("sprites/zerogxplode.spr")
  g_sModelIndexSmoke  = precache_model("sprites/steam1.spr")
  rocketsmoke = precache_model("sprites/smoke.spr")
}

public plugin_init()
{
  register_plugin(PLUGIN_NAME, PLUGIN_VERS, PLUGIN_AUTH);

  // Register CVars
  g_costCVar = register_cvar("uj_item_bazooka_cost", ITEM_COST);
  g_rebelCVar = register_cvar("uj_item_bazooka_rebel", ITEM_REBEL);
  
  g_ammoPCVar = register_cvar("uj_item_bazooka_ammo", "5")// how much ammo per bazooka
  g_damageRadiusPCVar = register_cvar("uj_item_bazooka_damageradius", "250")
  g_maxDamagePCVar = register_cvar("uj_item_bazooka_maxdamage", "150")
  g_reloadTimePCVar = register_cvar("uj_item_bazooka_reloadtime", "2.5")// in seconds
  g_trailTimePCVar = register_cvar("uj_item_bazooka_trailtime", "30")// roughly 3 seconds
  g_velocityPCVar = register_cvar("uj_item_bazooka_velocity", "700")
  g_teamColorsPCVar = register_cvar("uj_item_bazooka_teamcolors", "1")// set to 1 for team colored trails
  g_gibPCVar = register_cvar("uj_item_bazooka_gib", "0")// set to 1 for gib deaths (may cause lag on slower computers)

  // Register this item
  g_item = uj_items_register(ITEM_NAME, ITEM_MESSAGE, g_costCVar, g_rebelCVar);

  // Find the menu that item should appear in
  g_menuShop = uj_menus_get_menu_id("Shop Menu");

  register_event("ResetHUD","event_respawn","be","1=1")
  //register_logevent("round_end", 2, "1=Round_End")
  //register_logevent("round_start", 2, "1=Round_Start")
  
  //register_clcmd("drop", "handle_drop")  
  register_forward(FM_SetModel, "forward_setmodel");
  register_event("TextMsg", "bomb_msg", "b", "2=#C4_Plant_At_Bomb_Spot");
}

/*
 * This is called when determining if an item should be displayed
 * on a certain menu.
 */
public uj_fw_items_select_pre(playerID, itemID, menuID)
{
  // This is not our item - so do not block from showing
  if (itemID != g_item) {
    return UJ_ITEM_AVAILABLE;
  }

  // Only display if it appears in the menu we retrieved in plugin_init()
  if (menuID != g_menuShop) {
    return UJ_ITEM_DONT_SHOW;
  }

  // Disable if player already has this item
  if (get_bit(g_hasItem, playerID)) {
    return UJ_ITEM_NOT_AVAILABLE;
  }
  
  return UJ_ITEM_AVAILABLE;
}

/*
 * This is called after an item has been selected from a menu.
 */
public uj_fw_items_select_post(playerID, itemID, menuID)
{
  // This is not our item - do not continue
  if (g_item != itemID)
    return;

  give_uj_item(playerID);
}

/*
 * This is called when an item should be removed from a player.
 */
public uj_fw_items_strip_item(playerID, itemID)
{
  // This is not our item - do not continue
  // If itemID is UJ_ITEM_ALL_ITEMS, then all items are affected
  if ((itemID != g_item) &&
      (itemID != UJ_ITEM_ALL_ITEMS)) {
    return;
  }

  remove_uj_item(playerID);
}

give_uj_item(playerID)
{
  if (!get_bit(g_hasItem, playerID)) {
    give_item(playerID, "weapon_c4")
    uj_effects_set_view_model(playerID, CSW_C4, "models/v_rpg.mdl");
    uj_effects_set_weap_model(playerID, CSW_C4, "models/p_rpg.mdl");
    g_bazookaAmmo[playerID] += get_pcvar_num(g_ammoPCVar);
    g_bazookaMode[playerID] = 0;

    update_bazooka_hud(playerID);

    set_bit(g_hasItem, playerID);
    set_bit(g_canShoot, playerID);
  }
  return PLUGIN_HANDLED;
}

remove_uj_item(playerID)
{
  if (get_bit(g_hasItem, playerID)) {
    clear_bit(g_hasItem, playerID);
    g_bazookaAmmo[playerID] = 0;
    uj_effects_reset_view_model(playerID, CSW_C4);
    uj_effects_reset_weap_model(playerID, CSW_C4);
  }
}

public fire_rocket(playerID)
{
  clear_bit(g_canShoot, playerID);
  
  new data[1]
  data[0] = playerID
  new rtime = get_pcvar_num(g_reloadTimePCVar)
  if (cs_get_user_plant(playerID) != 1){
    set_task((rtime + 0.0), "rpg_reload", playerID+9477, data, 1)
    if (g_bazookaAmmo[playerID] <= 0) {
      //emit_sound(playerID, CHAN_WEAPON, "weapons/dryfire1.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
      return PLUGIN_HANDLED
    }
    else{
      new Float:StartOrigin[3], Float:Angle[3]
      
      new PlayerOrigin[3]
      get_user_origin(playerID, PlayerOrigin, 1)
      
      StartOrigin[0] = float(PlayerOrigin[0])
      StartOrigin[1] = float(PlayerOrigin[1])
      StartOrigin[2] = float(PlayerOrigin[2])
      
      entity_get_vector(playerID, EV_VEC_v_angle, Angle)
      Angle[0] = Angle[0] * -1.0
      new RocketEnt = create_entity("info_target")
      entity_set_string(RocketEnt, EV_SZ_classname, "rpgrocket")
      entity_set_model(RocketEnt, "models/rpgrocket.mdl")
      entity_set_origin(RocketEnt, StartOrigin)
      entity_set_vector(RocketEnt, EV_VEC_angles, Angle)
      
      new Float:MinBox[3] = {-1.0, -1.0, -1.0}
      new Float:MaxBox[3] = {1.0, 1.0, 1.0}
      entity_set_vector(RocketEnt, EV_VEC_mins, MinBox)
      entity_set_vector(RocketEnt, EV_VEC_maxs, MaxBox)
      
      entity_set_int(RocketEnt, EV_INT_solid, 2)
      entity_set_int(RocketEnt, EV_INT_movetype, 5)
      entity_set_edict(RocketEnt, EV_ENT_owner, playerID)
      
      new Float:Velocity[3]
      new myvelocity = get_pcvar_num(g_velocityPCVar);
      VelocityByAim(playerID, myvelocity, Velocity)
      entity_set_vector(RocketEnt, EV_VEC_velocity, Velocity)
      
      emit_sound(RocketEnt, CHAN_WEAPON, "weapons/rocketfire1.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
      emit_sound(RocketEnt, CHAN_VOICE, "weapons/nuke_fly.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
      
      --g_bazookaAmmo[playerID];
      update_bazooka_hud(playerID);

      new CsTeams:iTeam =cs_get_user_team(playerID)
      new trailtime =get_pcvar_num(g_trailTimePCVar)
      new colorr =random_num(0,255)
      new colorg =random_num(0,255)
      new colorb =random_num(0,255)
      if (get_pcvar_num(g_teamColorsPCVar) == 1) {
        switch(iTeam) {
          case CS_TEAM_T: { //if team T color=red
            message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
            write_byte(22)
            write_short(RocketEnt)
            write_short(rocketsmoke)
            write_byte(trailtime)
            write_byte(3)
            write_byte(255)
            write_byte(0)
            write_byte(0)
            write_byte(255)
            message_end() 
          }
          case CS_TEAM_CT: { // if team CT color=blue
            message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
            write_byte(22)
            write_short(RocketEnt)
            write_short(rocketsmoke)
            write_byte(trailtime)
            write_byte(3)
            write_byte(0)
            write_byte(0)
            write_byte(255)
            write_byte(255)
            message_end()
          }
        }
      }
      else { // random colors anyone?
        message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
        write_byte(22)
        write_short(RocketEnt)
        write_short(rocketsmoke)
        write_byte(trailtime)
        write_byte(3)
        write_byte(colorr)
        write_byte(colorg)
        write_byte(colorb)
        write_byte(255)
        message_end()
      }
      
      if (g_bazookaMode[playerID] == 1) {
        new info[1]
        info[0] = RocketEnt
        set_task(1.0, "find_and_follow", 0, info, 1)
      }
      else if (g_bazookaMode[playerID] == 2) {
        entity_set_int(RocketEnt, EV_INT_rendermode, 1)
        attach_view(playerID, RocketEnt)
        user_controll[playerID] = RocketEnt
      }
      return PLUGIN_HANDLED
    }
    return PLUGIN_HANDLED
  }
  return PLUGIN_HANDLED
}

public rpg_reload(data[])
{
  set_bit(g_canShoot, data[0])
}

public find_and_follow(info[])
{
  new RocketEnt = info[0]
  new Float:shortestDist = 10000.0
  new nearestPlayer = 0
  
  if (is_valid_ent(RocketEnt)) {
    new players[32], count
    get_players(players, count)
    for (new i = 0; i < count; i++) {
      if (is_user_alive(players[i]) && (entity_get_edict(RocketEnt, EV_ENT_owner) != players[i]) && (get_user_team(players[i]) != get_user_team(entity_get_edict(RocketEnt, EV_ENT_owner)))) {
        new Float:PlayerOrigin[3], Float:RocketOrigin[3]
        entity_get_vector(players[i], EV_VEC_origin, PlayerOrigin)
        entity_get_vector(RocketEnt, EV_VEC_origin, RocketOrigin)
        
        new Float:distance = vector_distance(PlayerOrigin, RocketOrigin)
        
        if (distance <= shortestDist) {
          shortestDist = distance
          nearestPlayer = players[i]
        }
      }
    }
  }
  
  if (nearestPlayer > 0) {
    new data[2]
    data[0] = RocketEnt
    data[1] = nearestPlayer
    set_task(0.1, "follow_and_catch", RocketEnt, data, 2, "b")
  }
  else {
    pfn_touch(RocketEnt, 0)
  }
}

public follow_and_catch(data[])
{
  new RocketEnt = data[0]
  new target = data[1]
  new myvelocity = get_pcvar_num(g_velocityPCVar);
  
  if (is_user_alive(target) && is_valid_ent(RocketEnt)) {
    entity_set_follow(RocketEnt, target, (myvelocity+0.0))
    
    new Float:Velocity[3]
    new Float:NewAngle[3]
    entity_get_vector(RocketEnt, EV_VEC_velocity, Velocity)
    vector_to_angle(Velocity, NewAngle)
    entity_set_vector(RocketEnt, EV_VEC_angles, NewAngle)
  }
  else {
    remove_task(RocketEnt)
    new info[1]
    info[0] = RocketEnt
    set_task(0.1, "find_and_follow", 0, data, 1)
  }
}

public pfn_touch(ptr, ptd)
{
  new ClassName[32]
  new ClassNameptd[32]
  if ((ptr > 0) && is_valid_ent(ptr)) {
    entity_get_string(ptr, EV_SZ_classname, ClassName, 31)
  }
  if ((ptd > 0) && is_valid_ent(ptd)) {
    entity_get_string(ptd, EV_SZ_classname, ClassNameptd, 31)
  }
  if (equal(ClassName, "rpgrocket")) {
    if (equal(ClassNameptd, "func_breakable")) {
      force_use(ptr,ptd)
      remove_task(ptr)
    }
    remove_task(ptr)
    new Float:EndOrigin[3]
    entity_get_vector(ptr, EV_VEC_origin, EndOrigin)
    
    message_begin( MSG_BROADCAST, SVC_TEMPENTITY)  // Explosion
    write_byte(TE_EXPLOSION)
    write_coord(floatround(EndOrigin[0]))
    write_coord(floatround(EndOrigin[1]))
    write_coord(floatround(EndOrigin[2])+5)
    write_short(g_sModelIndexFireball)
    write_byte(random_num(0,20) + 20)
    write_byte(12) // framerate
    write_byte(TE_EXPLFLAG_NONE)
    message_end()
    
    message_begin(MSG_BROADCAST, SVC_TEMPENTITY)  // Smoke
    write_byte(TE_SMOKE)
    write_coord(floatround(EndOrigin[0]))
    write_coord(floatround(EndOrigin[1]))
    write_coord(floatround(EndOrigin[2])+15)
    write_short(g_sModelIndexSmoke)
    write_byte(60)
    write_byte(10)
    message_end()
    new maxdamage = get_pcvar_num(g_maxDamagePCVar)
    new damageradius = get_pcvar_num(g_damageRadiusPCVar)
    
    new PlayerPos[3], distance, damage
    for (new i = 1; i < 32; i++) {
      if (is_user_alive(i) == 1) {
        get_user_origin(i, PlayerPos)
        
        new NonFloatEndOrigin[3]
        NonFloatEndOrigin[0] = floatround(EndOrigin[0])
        NonFloatEndOrigin[1] = floatround(EndOrigin[1])
        NonFloatEndOrigin[2] = floatround(EndOrigin[2])
        
        distance = get_distance(PlayerPos, NonFloatEndOrigin)
        if (distance <= damageradius) {  // Screenshake Radius
          message_begin(MSG_ONE, get_user_msgid("ScreenShake"), {0,0,0}, i)  // Shake Screen
          write_short(1<<14)
          write_short(1<<14)
          write_short(1<<14)
          message_end()
          
          damage = maxdamage - floatround(floatmul(float(maxdamage), floatdiv(float(distance), float(damageradius))))
          new attacker = entity_get_edict(ptr, EV_ENT_owner)
          
          if (get_user_team(attacker) != get_user_team(i)) {
            if (damage < get_user_health(i)) {
              set_user_health(i, get_user_health(i) - damage)
            }
            else {
              set_msg_block(get_user_msgid("DeathMsg"), BLOCK_SET)
              user_kill(i, 1)
              set_msg_block(get_user_msgid("DeathMsg"), BLOCK_NOT)
              
              message_begin(MSG_BROADCAST, get_user_msgid("DeathMsg"))  // Kill-Log oben rechts
              write_byte(attacker)  // Attacker
              write_byte(i)  // Victim
              write_byte(0)  // Headshot
              write_string("bazooka")
              message_end()
              if (damage > 100 && get_pcvar_num(g_gibPCVar) == 1) { //begin gibs and effects (made by mike_cao)
                new iOrigin[3]
                get_user_origin(i,iOrigin) // Effects
                fx_trans(i,0)
                fx_gib_explode(iOrigin,3)
                fx_blood_large(iOrigin,5)
                fx_blood_small(iOrigin,15)
                iOrigin[2] = iOrigin[2]-20 // Hide body
                set_user_origin(i,iOrigin)
              } //end gibs and effects
              set_user_frags(attacker, get_user_frags(attacker) + 1)
             
            }
          }
          if (get_user_team(attacker) == get_user_team(i)) {
            
            if (attacker == i) {
              if (damage < get_user_health(i)) {
                set_user_health(i, get_user_health(i) - damage)
              }
              else {
                set_msg_block(get_user_msgid("DeathMsg"), BLOCK_SET)
                user_kill(i, 1)
                set_msg_block(get_user_msgid("DeathMsg"), BLOCK_NOT)
                
                message_begin(MSG_BROADCAST, get_user_msgid("DeathMsg")) // Kill-Log oben rechts
                write_byte(attacker)  // Attacker
                write_byte(i)  // Victim
                write_byte(0)  // Headshot
                write_string("bazooka")
                message_end()
                if ((damage > 100) && get_pcvar_num(g_gibPCVar) == 1) { //begin gibs and effects (made by mike_cao)
                  new iOrigin[3]
                  get_user_origin(i,iOrigin)// Effects
                  fx_trans(i,0)
                  fx_gib_explode(iOrigin,3)
                  fx_blood_large(iOrigin,5)
                  fx_blood_small(iOrigin,15)
                  iOrigin[2] = iOrigin[2]-20 // Hide body
                  set_user_origin(i,iOrigin)
                } //end gibs and effects
                set_user_frags(attacker, get_user_frags(attacker) - 1)
              }
            }
          }
        }
      }
    }
    attach_view(entity_get_edict(ptr, EV_ENT_owner), entity_get_edict(ptr, EV_ENT_owner))
    user_controll[entity_get_edict(ptr, EV_ENT_owner)] = 0
    remove_entity(ptr)
  }
  
  /*
  if (equal(ClassName, "rpg") || equal(ClassName, "rpg_temp")) {
    new Picker[32]
    if ((ptd > 0) && is_valid_ent(ptd)) {
      entity_get_string(ptd, EV_SZ_classname, Picker, 31)
    } 
    if (equal(Picker, "player")) {
      give_item(ptd, "weapon_c4")
      hasBazooka[ptd] = true
      g_bazookaAmmo[ptd] = g_bazookaAmmo[ptd] + entity_get_int(ptr, EV_INT_iuser1)
      client_print(ptd, print_chat, "[Bazooka] You have picked up a bazooka!")
      ammo_hud(ptd, 0)
      ammo_hud(ptd, 1)
      emit_sound(ptd, CHAN_WEAPON, "items/gunpickup2.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
      remove_entity(ptr)
    }
  }
  */
}

public client_PreThink(playerID)
{
  if (is_user_alive(playerID)) {
    new weaponid, clip, ammo
    weaponid = get_user_weapon(playerID, clip, ammo)
    if ((weaponid == CSW_C4) && get_bit(g_hasItem, playerID)) {
      new attack = get_user_button(playerID) & IN_ATTACK
      new oldattack = get_user_oldbutton(playerID) & IN_ATTACK
      new attack2 = get_user_button(playerID) & IN_ATTACK2
      new oldattack2 = get_user_oldbutton(playerID) & IN_ATTACK2
      if (attack && !oldattack) {
        if (get_bit(g_canShoot, playerID) && (user_controll[playerID] == 0)) {
          fire_rocket(playerID)
        }
      }
      else if (attack2 && !oldattack2) {
        switch(g_bazookaMode[playerID]) {
          case 0: {
            ++g_bazookaMode[playerID];
            update_bazooka_hud(playerID);
            //emit_sound(playerID, CHAN_ITEM, "common/wpn_select.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
            //emit_sound(playerID, CHAN_WEAPON, "items/nvg_on.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
          }
          case 1: {
            ++g_bazookaMode[playerID];
            update_bazooka_hud(playerID);
            //emit_sound(playerID, CHAN_ITEM, "common/wpn_select.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
            //emit_sound(playerID, CHAN_WEAPON, "items/gunpickup4.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
          }
          case 2: {
            g_bazookaMode[playerID] = 0;
            update_bazooka_hud(playerID);
            //emit_sound(playerID, CHAN_ITEM, "common/wpn_select.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
          }
        }
      }
    }
  }

  // When user controlled, change the projectile's direction vector
  if (user_controll[playerID] > 0) {
    new RocketEnt = user_controll[playerID]
    if (is_valid_ent(RocketEnt)) {
      new Float:Velocity[3]
      VelocityByAim(playerID, 500, Velocity)
      entity_set_vector(RocketEnt, EV_VEC_velocity, Velocity)
      new Float:NewAngle[3]
      entity_get_vector(playerID, EV_VEC_v_angle, NewAngle)
      entity_set_vector(RocketEnt, EV_VEC_angles, NewAngle)
    }
    else {
      attach_view(playerID, playerID)
    }
  }

  return FMRES_IGNORED
}

// Remove the C4 backpack model from appearing
public forward_setmodel(entity, model[])
{
  if (!is_valid_ent(entity)) {
    return FMRES_IGNORED
  }
  if (equal(model, "models/w_backpack.mdl")) {
    new ClassName[32]
    entity_get_string(entity, EV_SZ_classname, ClassName, 31)
    
    if (equal(ClassName, "weaponbox")) {
      remove_entity(entity)     
      return FMRES_SUPERCEDE
    }
  }
  return FMRES_IGNORED
}

// Override default message saying bomb cannot be planted
public bomb_msg(playerID)
{
  if (cs_get_user_plant(playerID) != 1) {
    client_print(playerID, print_center, "");
  }
}

update_bazooka_hud(playerID)
{
  new AmmoHud[65]
  format(AmmoHud, 64, "Rockets: %i | Mode: %s", g_bazookaAmmo[playerID], BAZOOKA_MODES[g_bazookaMode[playerID]]);

  message_begin(MSG_ONE, get_user_msgid("StatusText"), {0,0,0}, playerID)
  write_byte(0)
  write_string(AmmoHud)
  message_end()
}

/************************************************************
* GIB FUNCTIONS (made by mike_cao)
************************************************************/

public event_respawn(playerID)
{
  gHealthIndex[playerID] = get_user_health(playerID)
  fx_trans(playerID,255)
  return PLUGIN_CONTINUE
}

static fx_trans(player,amount)
{
  set_user_rendering(player,kRenderFxNone,0,0,0,kRenderTransAlpha,amount)
  return PLUGIN_CONTINUE
}

static fx_blood_small(origin[3],num)
{
  // Blood decals
  #if CZERO
  static const blood_small[8] = {202,203,204,205,206,207,208,209}
  #else
  static const blood_small[7] = {190,191,192,193,194,195,197}
  #endif  
  // Small splash
  for (new j = 0; j < num; j++) {
    message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
    write_byte(TE_WORLDDECAL)
    write_coord(origin[0]+random_num(-100,100))
    write_coord(origin[1]+random_num(-100,100))
    write_coord(origin[2]-36)
    write_byte(blood_small[random_num(0,6)]) // index
    message_end()
  }
}

static fx_blood_large(origin[3],num)
{
  // Blood decals
  #if CZERO
  static const blood_large[2] = {216,217}
  #else
  static const blood_large[2] = {204,205}
  #endif
  
  // Large splash
  for (new i = 0; i < num; i++) {
    message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
    write_byte(TE_WORLDDECAL)
    write_coord(origin[0]+random_num(-50,50))
    write_coord(origin[1]+random_num(-50,50))
    write_coord(origin[2]-36)
    write_byte(blood_large[random_num(0,1)]) // index
    message_end()
  }
}

static fx_gib_explode(origin[3],num)
{
  new flesh[3], x, y, z
  flesh[0] = mdl_gib_flesh
  flesh[1] = mdl_gib_meat
  flesh[2] = mdl_gib_legbone
  
  // Gib explosion
  // Head
  message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
  write_byte(TE_MODEL)
  write_coord(origin[0])
  write_coord(origin[1])
  write_coord(origin[2])
  write_coord(random_num(-100,100))
  write_coord(random_num(-100,100))
  write_coord(random_num(100,200))
  write_angle(random_num(0,360))
  write_short(mdl_gib_head)
  write_byte(0) // bounce
  write_byte(500) // life
  message_end()
  
  // Spine
  message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
  write_byte(TE_MODEL)
  write_coord(origin[0])
  write_coord(origin[1])
  write_coord(origin[2])
  write_coord(random_num(-100,100))
  write_coord(random_num(-100,100))
  write_coord(random_num(100,200))
  write_angle(random_num(0,360))
  write_short(mdl_gib_spine)
  write_byte(0) // bounce
  write_byte(500) // life
  message_end()
  
  // Lung
  for(new i = 0; i < random_num(1,2); i++) {
    message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
    write_byte(TE_MODEL)
    write_coord(origin[0])
    write_coord(origin[1])
    write_coord(origin[2])
    write_coord(random_num(-100,100))
    write_coord(random_num(-100,100))
    write_coord(random_num(100,200))
    write_angle(random_num(0,360))
    write_short(mdl_gib_lung)
    write_byte(0) // bounce
    write_byte(500) // life
    message_end()
  }
  
  // Parts, 10 times
  for(new i = 0; i < 10; i++) {
    message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
    write_byte(TE_MODEL)
    write_coord(origin[0])
    write_coord(origin[1])
    write_coord(origin[2])
    write_coord(random_num(-100,100))
    write_coord(random_num(-100,100))
    write_coord(random_num(100,200))
    write_angle(random_num(0,360))
    write_short(flesh[random_num(0,2)])
    write_byte(0) // bounce
    write_byte(500) // life
    message_end()
  }
  
  // Blood
  for(new i = 0; i < num; i++) {
    x = random_num(-100,100)
    y = random_num(-100,100)
    z = random_num(0,100)
    for(new j = 0; j < 3; j++) {
      message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
      write_byte(TE_BLOODSPRITE)
      write_coord(origin[0]+(x*j))
      write_coord(origin[1]+(y*j))
      write_coord(origin[2]+(z*j))
      write_short(spr_blood_spray)
      write_short(spr_blood_drop)
      write_byte(229) // color index
      write_byte(15) // size
      message_end()
    }
  }
}
