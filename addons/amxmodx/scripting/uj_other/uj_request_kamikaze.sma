#include <amxmisc>
#include <amxmodx>
#include <fakemeta>
#include <fun>
#include <cstrike>
#include <hamsandwich>
#include <engine>
#include <dhudmessage>
#include <uj_colorchat>
#include <uj_core>
#include <uj_menus>
#include <uj_requests>

// damage of explode, required for fm_radius_damage
#define EXPLODE_DAMAGE 100.0

// radius of damage (required for fm_radius damage )
#define EXPLODE_RADIUS 300.0

new const PLUGIN_NAME[] = "[UJ] Request - Kamikaze";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

new const REQUEST_NAME[] = "Kamikaze";
new const REQUEST_OBJECTIVE[] = "Boom";

//new g_iMaxPlayers;
new explosion_sprite;     // Suicide bomber sprite
new g_iMsgDeath;
new g_iMsgScoreInfo;


// Request variables
new g_request;
new bool:g_requestEnabled;

// Menu variables
new g_menuLastRequests;

// Player variables
new g_playerID;
new g_targetID;


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

//g_iMaxPlayers   = get_maxplayers();
g_iMsgDeath   = get_user_msgid("DeathMsg");
g_iMsgScoreInfo   = get_user_msgid("ScoreInfo");  
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
if(!g_requestEnabled) {
	g_requestEnabled = true;

	
	
	// Strip users of weapons, and give out scourts and knives
	uj_core_strip_weapons(playerID);
	uj_core_strip_weapons(targetID);
	explode_me(playerID);
	// cs_set_user_bpammo(playerID, CSW_SCOUT, ammoCount);
	// cs_set_user_bpammo(targetID, CSW_SCOUT, ammoCount);
	
	// Do not allow participants to pick up any guns
	uj_core_block_weapon_pickup(playerID, true);
	uj_core_block_weapon_pickup(targetID, true);
	
	// Set health
	set_pev(playerID, pev_health, 100.0);
	set_pev(targetID, pev_health, 100.0);
	
	// Give armor
	cs_set_user_armor(playerID, 100, CS_ARMOR_VESTHELM)
	cs_set_user_armor(targetID, 100, CS_ARMOR_VESTHELM)
	
	// Find gravity setting
	
	// Set low gravity
	
	g_playerID = playerID;
	g_targetID = targetID;
}
}

public uj_fw_requests_end(requestID)
{
// If requestID refers to our request and our request is enabled
if(requestID == g_request && g_requestEnabled) {
	g_requestEnabled = false;
	
	uj_core_strip_weapons(g_playerID);
	uj_core_strip_weapons(g_targetID);
	
	set_user_gravity(g_playerID, 1.0);
	set_user_gravity(g_targetID, 1.0);
	
	uj_core_block_weapon_pickup(g_playerID, false);
	uj_core_block_weapon_pickup(g_targetID, false);
	
	}
}

/*================================================================================
 [Suicide Bomber]
=================================================================================*/

public explode_me(id) {
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

  fm_radius_damage(id, explosion, EXPLODE_DAMAGE, EXPLODE_RADIUS, "grenade");
}

stock fm_radius_damage(id, Float:orig[3], Float:dmg , Float:rad, wpnName[]="") {
  new szClassname[33], Float:Health;
  static Ent;
  Ent = -1;
  while((Ent = engfunc(EngFunc_FindEntityInSphere, Ent, orig, rad))) {
    pev(Ent,pev_classname,szClassname,32);
    if(equali(szClassname, "player") 
    && is_user_connected(Ent)
    && is_user_alive(Ent))
    //&& get_bit(g_bIsConnected, Ent) 
    //&& get_bit(g_bIsAlive, Ent) )
    {
      pev(Ent, pev_health, Health);
      Health -= dmg;
      
      new szName[32], szName1[32];
      get_user_name(Ent, szName, charsmax(szName));
      get_user_name(id, szName1, charsmax(szName1));
      
      if(Health <= 0.0) 
        createKill(Ent, id, wpnName);
      else set_pev(Ent, pev_health, Health);
    }
  }             
}

// stock for create kill
stock createKill(id, attacker, weaponDescription[]) {
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
stock logKill(id, victim, weaponDescription[] ) {
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
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
