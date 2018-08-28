#include <amxmisc>
#include <amxmodx>
#include <fakemeta>
#include <fun>
#include <cstrike>
#include <hamsandwich>
#include <engine>
#include <uj_colorchat>
#include <uj_core>
#include <uj_menus>
#include <uj_requests>

#define FIRST_PLAYER_ID 1
#define IsPlayer(%1) (FIRST_PLAYER_ID <= %1 <= g_iMaxPlayers)

const HAS_SHIELD = 1<<24;
#define HasShield(%0)    ( get_pdata_int(%0, m_iUserPrefs, XO_PLAYER) & HAS_SHIELD )

#define m_iTeam    114
#define XO_PLAYER  5
#define m_iFlashBattery  244
#define m_pActiveItem    373
#define m_iUserPrefs     510

#define TEAM_T  1
#define TEAM_CT 2

#define cs_get_user_team_index(%0)  get_pdata_int(%0, m_iTeam, XO_PLAYER)
#define cs_set_user_team_index(%0,%1) set_pdata_int(%0, m_iTeam, %1, XO_PLAYER)

new const PLUGIN_NAME[] = "[UJ] Request - Global War";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

new const REQUEST_NAME[] = "Global War";
new const REQUEST_OBJECTIVE[] = "Free for all homeboy";

new gCount = 5;

new HamHook:g_iHhTakeDamagePost;
new g_iMaxPlayers;
new g_iVictimTeam;

enum ( += 100 )
{
TASK_GLOBAL_WAR
};

//new const SCOUTDUEL_GRAVITY[] = "0.25";
//new const SCOUTDUEL_AMMO[] = "50";

// Request variables
new g_request;
new bool:g_requestEnabled;

// Menu variables
new g_menuLastRequests;

// Player variables
new g_playerID;
new g_targetID;

// CVar variables
//new g_gravityPCVar;
//new g_ammoPCVar;

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

//g_gravityPCVar = register_cvar("uj_request_scoutduel_gravity", SCOUTDUEL_GRAVITY);

//g_ammoPCVar = register_cvar("uj_request_scoutduel_ammo", SCOUTDUEL_AMMO);
RegisterHam(Ham_TakeDamage, "player", "Fwd_PlayerDamage", 0);
g_iHhTakeDamagePost = RegisterHam(Ham_TakeDamage, "player", "Player_TakeDamage_Post", 1);
DisableHamForward(g_iHhTakeDamagePost);
g_iMaxPlayers   = get_maxplayers();
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
	gCount = 5;
	set_task( 1.0, "giveGlobalWarWeapons", TASK_GLOBAL_WAR, _, _, "a", gCount + 1 );
	
	//new ammoCount = get_pcvar_num(g_ammoPCVar);
	
	// Strip users of weapons, and give out scourts and knives
	uj_core_strip_weapons(playerID);
	uj_core_strip_weapons(targetID);
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
	
	
	if( task_exists( TASK_GLOBAL_WAR ) )
		remove_task( TASK_GLOBAL_WAR );
	}
}


//////////////////////////////////////
//----- Give Global War Weapons-----//
//////////////////////////////////////
public giveGlobalWarWeapons()
{
	if( gCount )
	{
		set_hudmessage( 255, 255, 255, -1.0, 0.35, 0, 0.1, 1.0, 0.1, 0.1, 4 );
		show_hudmessage( 0, "You will be equipped in %i seconds.", gCount );
		
		gCount--;
		
		return PLUGIN_HANDLED;
	}
	
	new players[ 32 ], num, id;
	get_players( players, num );
	
	for( new i = 0; i < num; i++ )
	{
		id = players[i];
		if( is_user_alive( id ) )
		{
			give_item(id, "weapon_m4a1");
			cs_set_user_bpammo(id, CSW_M4A1, 30);
			
			give_item(id, "weapon_deagle");
			cs_set_user_bpammo(id, CSW_DEAGLE, 7);
			
			cs_set_user_bpammo( id, CSW_M4A1, 500 );
			cs_set_user_bpammo( id, CSW_DEAGLE, 200 );
			
			set_user_health( id, 100 );
			cs_set_user_armor( id, 100, CS_ARMOR_VESTHELM );
		}
	}
	
	if( task_exists( TASK_GLOBAL_WAR ) )
		remove_task( TASK_GLOBAL_WAR );
	
	return PLUGIN_HANDLED;
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
