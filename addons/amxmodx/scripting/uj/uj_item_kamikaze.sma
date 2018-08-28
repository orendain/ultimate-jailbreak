#include <amxmodx>
#include <cstrike>
#include <fakemeta>
#include <fun>
#include <uj_effects>
#include <uj_core>
#include <uj_menus>
#include <uj_items>
#include <fg_colorchat>

new const PLUGIN_NAME[] = "UJ | Item - Kamikaze";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

new const ITEM_NAME[] = "Kamikaze Vest";
new const ITEM_MESSAGE[] = "HAHAHA, death to all!";
new const ITEM_COST[] = "175";
new const ITEM_REBEL[] = "1";
new const ITEM_DAMAGE[] = "150";
new const ITEM_RADIUS[] = "300";

new const ITEM_SOUND[] = "ultimate_jailbreak/misc/holyshit.wav";

// Kamikaze-related variables
new explosion_sprite;
new g_iMsgDeath;
new g_iMsgScoreInfo;

// Menu variables
new g_menuShop;
new g_item;

// Common PCVars
new g_costPCVar;
new g_rebelPCVar;
new g_damagePCVar;
new g_radiusPCVar;

// Keep track of who this item
new g_hasItem;

public plugin_init()
{
  register_plugin(PLUGIN_NAME, PLUGIN_VERS, PLUGIN_AUTH);

  // Register PCVars
  g_costPCVar = register_cvar("uj_item_kamikaze_cost", ITEM_COST);
  g_rebelPCVar = register_cvar("uj_item_kamikaze_rebel", ITEM_REBEL);
  g_damagePCVar = register_cvar("uj_item_kamikaze_damage", ITEM_DAMAGE);
  g_radiusPCVar = register_cvar("uj_item_kamikaze_radius", ITEM_RADIUS);

  // Register this item
  g_item = uj_items_register(ITEM_NAME, ITEM_MESSAGE, g_costPCVar, g_rebelPCVar);

  // Find the menu that item should appear in
  g_menuShop = uj_menus_get_menu_id("Shop Menu");

  g_iMsgDeath = get_user_msgid("DeathMsg");
  g_iMsgScoreInfo = get_user_msgid("ScoreInfo");
}

public plugin_precache()
{
  explosion_sprite = precache_model("sprites/zerogxplode.spr");
  precache_sound(ITEM_SOUND);
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
    set_bit(g_hasItem, playerID);
    new playerName[32];
    get_user_name(playerID, playerName, charsmax(playerName));
    
    fg_colorchat_print(0, FG_COLORCHAT_RED, "^3%s^1 is going ^3KAMIKAZE^1 in^3 3 seconds^1!", playerName)
    uj_effects_glow_player(playerID, 255, 0, 0, 16);
    set_task(3.0, "explode_me", playerID);
  }
  return PLUGIN_HANDLED;
}

remove_uj_item(playerID)
{
  // We don't strip the user of his/her armor
  if (get_bit(g_hasItem, playerID)) {
    clear_bit(g_hasItem, playerID);
  }
}

public explode_me(id)
{
  // get my origin
  new Float:explosion[3];
  pev(id, pev_origin, explosion);

  user_kill(id);
  
  // create explosion
  message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
  write_byte(TE_EXPLOSION);
  write_coord(floatround(explosion[0]));
  write_coord(floatround(explosion[1]));
  write_coord(floatround(explosion[2]));
  write_short(explosion_sprite);
  write_byte(30);
  write_byte(30);
  write_byte(0);
  message_end();

  emit_sound(id, CHAN_WEAPON, ITEM_SOUND, 1.0, ATTN_NORM, 0, PITCH_NORM);
  fm_radius_damage(id, explosion, "kamikaze");
}

stock fm_radius_damage(id, Float:orig[3], wpnName[] = "")
{
  new Float:dmg = float(get_pcvar_num(g_damagePCVar));
  new Float:rad = float(get_pcvar_num(g_radiusPCVar));

  new szClassname[33], Float:health;
  static Ent;
  Ent = -1;
  while((Ent = engfunc(EngFunc_FindEntityInSphere, Ent, orig, rad))) {
    pev(Ent,pev_classname,szClassname,32);
    if(equali(szClassname, "player") 
    && is_user_connected(Ent)
    && is_user_alive(Ent)) {
      pev(Ent, pev_health, health);
      health -= dmg;
      
      new szName[32], szName1[32];
      get_user_name(Ent, szName, charsmax(szName));
      get_user_name(id, szName1, charsmax(szName1));
      
      if(health <= 0.0)  {
        createKill(Ent, id, wpnName);
      }
      else {
        set_pev(Ent, pev_health, health);
      }
    }
  }             
}

// stock for create kill
stock createKill(id, attacker, weaponDescription[])
{
  new szFrags, szFrags2;
  
  if(id != attacker) {
    szFrags = get_user_frags(attacker);
    set_user_frags(attacker, szFrags + 1);
    logKill(attacker, id, weaponDescription);
       
    //Kill the victim and block the messages
    set_msg_block(g_iMsgDeath,BLOCK_ONCE);
    set_msg_block(g_iMsgScoreInfo,BLOCK_ONCE);
    user_kill(id);
      
    //user_kill removes a frag, this gives it back
    szFrags2 = get_user_frags(id);
    set_user_frags(id, szFrags2 + 1);
      
    //Replaced HUD death message
    message_begin(MSG_ALL, g_iMsgDeath,{0,0,0},0);
    write_byte(attacker);
    write_byte(id);
    write_byte(0);
    write_string(weaponDescription);
    message_end();
      
    //Update killers scorboard with new info
    message_begin(MSG_ALL, g_iMsgScoreInfo);
    write_byte(attacker);
    write_short(szFrags);
    write_short(get_user_deaths(attacker));
    write_short(0);
    write_short(get_user_team(attacker));
    message_end();
      
    //Update victims scoreboard with correct info
    message_begin(MSG_ALL, g_iMsgScoreInfo);
    write_byte(id);
    write_short(szFrags2);
    write_short(get_user_deaths(id));
    write_short(0);
    write_short(get_user_team(id));
    message_end();
    
    new szName[32], szName1[32];
    get_user_name(id, szName, charsmax(szName));
    get_user_name(attacker, szName1, charsmax(szName1));
  }
}

// stock for log kill
stock logKill(id, victim, weaponDescription[])
{
  new namea[32],namev[32],authida[35],authidv[35],teama[16],teamv[16];
   
  //Info On Attacker
  get_user_name(id,namea,charsmax(namea));
  get_user_team(id,teama,15);
  get_user_authid(id,authida,34);
   
  //Info On Victim
  get_user_name(victim,namev,charsmax(namev));
  get_user_team(victim,teamv,15);
  get_user_authid(victim,authidv,34);
   
  //Log This Kill
  if(id != victim)
    log_message("^"%s<%d><%s><%s>^" killed ^"%s<%d><%s><%s>^" with ^"%s^"",
    namea,get_user_userid(id),authida,teama,namev,get_user_userid(victim),authidv,teamv, weaponDescription );
  else
    log_message("^"%s<%d><%s><%s>^" committed suicide with ^"%s^"",
    namea,get_user_userid(id),authida,teama, weaponDescription );
}
