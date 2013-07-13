#include <amxmodx>
#include <fakemeta>
#include <cstrike>
#include <fun>
#include <hamsandwich>
#include <dhudmessage>
#include <uj_menus>
#include <uj_chargers>
#include <uj_core>
#include <uj_days>
#include <uj_effects>
#include <uj_colorchat>

#define FIRST_PLAYER_ID 1
#define IsPlayer(%1) (FIRST_PLAYER_ID <= %1 <= g_iMaxPlayers)

new const PLUGIN_NAME[] = "[UJ] Day - Awp Skill Day";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

new const DAY_NAME[] = "Awp Skill Day";
new const DAY_OBJECTIVE[] = "Awps only, reload after everyshot. Make it count";
new const DAY_SOUND[] = "";

//new const SPARTA_PRIMARY_AMMO[] = "200";
//new const SPARTA_SECONDARY_AMMO[] = "50";

//new g_iMaxPlayers;

// Day variables
new g_day;
new bool:g_dayEnabled;

// Menu variables
new g_menuSpecial

// Cvars
new cv_awp_clip, gmsgCurWeapon, weapon[33], awp_clip[33], awp_bpammo[33];

public plugin_precache()
{
	// Register day
	g_day = uj_days_register(DAY_NAME, DAY_OBJECTIVE, DAY_SOUND)
	register_event("CurWeapon","event_curweapon","b");
	register_event("AmmoX","event_ammox","b");
	
	gmsgCurWeapon = get_user_msgid("CurWeapon");
	cv_awp_clip = register_cvar("awp_clip","1");
	
	register_forward(FM_CmdStart,"fw_cmdstart",1);	
}

public plugin_init()
{
	register_plugin(PLUGIN_NAME, PLUGIN_VERS, PLUGIN_AUTH);
	
	// Find all valid menus to display this under
	g_menuSpecial = uj_menus_get_menu_id("Special Days");
	
	// CVars
	//g_iMaxPlayers   = get_maxplayers();
	
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
	
	// If we *can* show the menu, but it's already enabled,
	// then have it be unavailable
	if (g_dayEnabled) {
		return UJ_DAY_NOT_AVAILABLE;
	}
	
	return UJ_DAY_AVAILABLE;
}

public uj_fw_days_select_post(playerID, dayID)
{
	// This is not our item
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
	
	// Find settings
	
	new players[32], playerID;
	new playerCount = uj_core_get_players(players, true, CS_TEAM_T);
	for (new i = 0; i < playerCount; ++i) {
		playerID = players[i];
		
		// Give user items
		uj_core_strip_weapons(playerID);
		//set_tag_player(iPlayer, "Survivor");
		//SaveWeapons(iPlayer);
		cs_set_user_armor( playerID, 100, CS_ARMOR_VESTHELM );
		give_item( playerID, "weapon_awp" );
		cs_set_user_bpammo( playerID, CSW_AWP, 200 );
	}	
	
	
	playerCount = uj_core_get_players(players, true, CS_TEAM_CT);
	for (new i = 0; i < playerCount; ++i) {
		playerID = players[i];
		
		// Give user items
		uj_core_strip_weapons(playerID);
		cs_set_user_armor( playerID, 100, CS_ARMOR_VESTHELM );
		set_user_health(playerID, 200 );
		give_item( playerID, "weapon_awp" );
		cs_set_user_bpammo( playerID, CSW_AWP, 200 );
	}
	
	uj_core_block_weapon_pickup(0, true);
	uj_chargers_block_heal(0, true);
	uj_chargers_block_armor(0, true);
}
}


end_day()
{
new players[32], playerID;
new playerCount = uj_core_get_players(players, true);
for (new i = 0; i < playerCount; ++i) {
playerID = players[i];
uj_core_strip_weapons(playerID);

}

g_dayEnabled = false;
uj_core_block_weapon_pickup(0, false);
uj_chargers_block_heal(0, false);
uj_chargers_block_armor(0, false);
}

public Player_AddPlayerItem(const playerID, const iEntity)  //anti gun glitch
{
new iWeapID = cs_get_weapon_id( iEntity );

if( !iWeapID )
return HAM_IGNORED;

static CsTeams:team;
team = cs_get_user_team(playerID);
if (g_dayEnabled) 
{
switch(team)
{
	case CS_TEAM_T:
		if(iWeapID != CSW_KNIFE && iWeapID != CSW_AWP)
		{
			SetHamReturnInteger( 1 );
			return HAM_SUPERCEDE;
		}
		case CS_TEAM_CT:
			if(iWeapID != CSW_KNIFE && iWeapID != CSW_AWP)
		{
			SetHamReturnInteger( 1 );
			return HAM_SUPERCEDE;
		}
	}
	
return HAM_IGNORED;
}

return HAM_IGNORED;
}


// reset values
public client_putinserver(id)
{
weapon[id] = 0;
awp_clip[id] = 0;
awp_bpammo[id] = 0;
}

// restrict clip ammo
public event_curweapon(id)
{
if (g_dayEnabled)
{
new status = read_data(1);

if(status) weapon[id] = read_data(2);

// using AWP
if(read_data(2) == CSW_AWP)
{
	// current weapon
	if(status)
	{
		// save clip information
		new old_awp_clip = awp_clip[id];
		awp_clip[id] = read_data(3);
		
		new max_clip = get_pcvar_num(cv_awp_clip);
		
		// plugin enabled and must restrict ammo
		if(max_clip && awp_clip[id] > max_clip)
		{
			new wEnt = get_weapon_ent(id,CSW_AWP);
			if(pev_valid(wEnt)) cs_set_weapon_ammo(wEnt,max_clip);
			
			// update HUD
			message_begin(MSG_ONE,gmsgCurWeapon,_,id);
			write_byte(1);
			write_byte(CSW_AWP);
			write_byte(max_clip);
			message_end();
			
			// don't steal ammo from the player
			if(awp_bpammo[id] && awp_clip[id] > old_awp_clip)
				cs_set_user_bpammo(id,CSW_AWP,awp_bpammo[id]-max_clip+old_awp_clip);
			
			awp_clip[id] = max_clip;
		}
	}
	else awp_clip[id] = 999;
}
else if(status) awp_clip[id] = 999;
}
}

// delayed record bpammo information
public event_ammox(id)
{
// awp ammo type is 1
if(read_data(1) == 1)
{
	static parms[2];
	parms[0] = id;
	parms[1] = read_data(2);
	
	set_task(0.1,"record_ammo",id,parms,2);
}
}

// delay, because ammox is called right before curweapon
public record_ammo(parms[])
{
awp_bpammo[parms[0]] = parms[1];
}

// block reload based on new clip size
public fw_cmdstart(player,uc_handle,random_seed)
{
new max_clip = get_pcvar_num(cv_awp_clip);

if(weapon[player] == CSW_AWP && max_clip && awp_clip[player] >= max_clip)
{
	set_uc(uc_handle,UC_Buttons,get_uc(uc_handle,UC_Buttons) & ~IN_RELOAD);
	return FMRES_HANDLED;
}

return FMRES_IGNORED;
}

// find a player's weapon entity
stock get_weapon_ent(id,wpnid=0,wpnName[]="")
{
// who knows what wpnName will be
static newName[32];

// need to find the name
if(wpnid) get_weaponname(wpnid,newName,31);

// go with what we were told
else formatex(newName,31,"%s",wpnName);

// prefix it if we need to
if(!equal(newName,"weapon_",7))
	format(newName,31,"weapon_%s",newName);

new ent;
while((ent = engfunc(EngFunc_FindEntityByString,ent,"classname",newName)) && pev(ent,pev_owner) != id) {}

return ent;
}

/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
