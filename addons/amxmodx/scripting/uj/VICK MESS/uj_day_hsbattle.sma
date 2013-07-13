#include <amxmisc>
#include <amxmodx>
#include <fakemeta>
#include <fun>
#include <cstrike>
#include <hamsandwich>
#include <engine>
#include <xs>
#include <dhudmessage>
#include <uj_menus>
#include <uj_chargers>
#include <uj_core>
#include <uj_days>
#include <uj_effects>
#include <uj_colorchat>

#define FIRST_PLAYER_ID 1
#define IsPlayer(%1) (FIRST_PLAYER_ID <= %1 <= g_iMaxPlayers)

new const PLUGIN_NAME[] = "[UJ] Day - Headshot Battle";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

new const DAY_NAME[] = "Headshot Battle";
new const DAY_OBJECTIVE[] = "Headshots only, aim high, willis, aim high.";
new const DAY_SOUND[] = "";

//new const SPARTA_PRIMARY_AMMO[] = "200";
//new const SPARTA_SECONDARY_AMMO[] = "50";

new g_iMaxPlayers;

// Day variables
new g_day;
new bool:g_dayEnabled;

// Menu variables
new g_menuSpecial

// Cvars
//new g_primaryAmmoPCVar;
//new g_secondaryAmmoPCVar;

public plugin_precache()
{
	// Register day
	g_day = uj_days_register(DAY_NAME, DAY_OBJECTIVE, DAY_SOUND)
}

public plugin_init()
{
	register_plugin(PLUGIN_NAME, PLUGIN_VERS, PLUGIN_AUTH);
	
	// Find all valid menus to display this under
	g_menuSpecial = uj_menus_get_menu_id("Special Days");
	
	// CVars
	//g_primaryAmmoPCVar = register_cvar("uj_day_spartans_primary_ammo", SPARTA_PRIMARY_AMMO);
	//g_secondaryAmmoPCVar = register_cvar("uj_day_spartans_secondary_ammo", SPARTA_SECONDARY_AMMO);
	RegisterHam( Ham_TraceAttack, "player", "HamTraceAttack" );
	g_iMaxPlayers   = get_maxplayers();

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
	new percent = random_num( 0, 23 );
	new playerCount = uj_core_get_players(players, true, CS_TEAM_T);
	for (new i = 0; i < playerCount; ++i) {
		playerID = players[i];
		
		// Give user items
		uj_core_strip_weapons(playerID);
		//set_tag_player(iPlayer, "Survivor");
		//SaveWeapons(iPlayer);
		cs_set_user_armor( playerID, 100, CS_ARMOR_VESTHELM );
		set_user_health(playerID, 200 );
		switch( percent )
		{
			case 0:
			{
				give_item( playerID, "weapon_elite" );
				cs_set_user_bpammo( playerID, CSW_ELITE, 300 );
			}
			
			case 1: 
			{
				give_item( playerID, "weapon_mp5navy" );
				cs_set_user_bpammo( playerID, CSW_MP5NAVY, 500 );
			}
			
			case 2:
			{
				give_item( playerID, "weapon_tmp" );
				cs_set_user_bpammo( playerID, CSW_TMP, 500 );
			}
			
			case 3:
			{
				give_item( playerID, "weapon_p90" );
				cs_set_user_bpammo( playerID, CSW_P90, 500 );
			}
			
			case 4:
			{
				give_item( playerID, "weapon_mac10" );
				cs_set_user_bpammo( playerID, CSW_MAC10, 500 );
			}
			
			case 5:
			{
				give_item( playerID, "weapon_ak47" );
				cs_set_user_bpammo( playerID, CSW_AK47, 500 );
			}
			
			case 6:
			{
				give_item( playerID, "weapon_sg552" );
				cs_set_user_bpammo( playerID, CSW_SG552, 500 );
			}
			
			case 7:
			{
				give_item( playerID, "weapon_m4a1" );
				cs_set_user_bpammo( playerID, CSW_M4A1, 500 );
			}
			
			case 8:
			{
				give_item( playerID, "weapon_aug" );
				cs_set_user_bpammo( playerID, CSW_AUG, 500 );
			}
			
			case 9:
			{
				give_item( playerID, "weapon_scout" );
				cs_set_user_bpammo( playerID, CSW_SCOUT, 200 );
			}
			
			case 10:
			{
				give_item( playerID, "weapon_g3sg1" );
				cs_set_user_bpammo( playerID, CSW_G3SG1, 500 );
			}
			
			case 11:
			{
				give_item( playerID, "weapon_awp" );
				cs_set_user_bpammo( playerID, CSW_AWP, 200 );
			}
			
			case 12:
			{
				give_item( playerID, "weapon_m3" );
				cs_set_user_bpammo( playerID, CSW_M3, 500 );
			}
			
			case 13:
			{
				give_item( playerID, "weapon_xm1014" );
				cs_set_user_bpammo( playerID, CSW_XM1014, 500 );
			}
			
			case 14:
			{
				give_item( playerID, "weapon_m249" );
				cs_set_user_bpammo( playerID, CSW_M249, 500 );
			}
			
			case 15:
			{
				give_item( playerID, "weapon_usp" );
				cs_set_user_bpammo( playerID, CSW_USP, 300 );
			}
			
			case 16:
			{
				give_item( playerID, "weapon_p228" );
				cs_set_user_bpammo( playerID, CSW_P228, 300 );
			}		
			
			case 17:
			{
				give_item( playerID, "weapon_deagle" );
				cs_set_user_bpammo( playerID, CSW_DEAGLE, 300 );
			}
			
			case 18:
			{
				give_item( playerID, "weapon_fiveseven" );
				cs_set_user_bpammo( playerID, CSW_FIVESEVEN, 300 );
			}
			
			case 19:
			{
				give_item( playerID, "weapon_glock18" );
				cs_set_user_bpammo( playerID, CSW_GLOCK18, 300 );
			}
			
			case 20:
			{
				give_item( playerID, "weapon_ump45" );
				cs_set_user_bpammo( playerID, CSW_UMP45, 300 );
			}
			
			case 21:
			{
				give_item( playerID, "weapon_galil" );
				cs_set_user_bpammo( playerID, CSW_GALIL, 300 );
			}
			
			case 22:
			{
				give_item( playerID, "weapon_famas" );
				cs_set_user_bpammo( playerID, CSW_FAMAS, 300 );
			}
			
			case 23:
			{
				give_item( playerID, "weapon_sg550" );
				cs_set_user_bpammo( playerID, CSW_SG550, 500 );
			}
		}
	}
	{
		
		new percent = random_num( 0, 23 );
		playerCount = uj_core_get_players(players, true, CS_TEAM_CT);
		for (new i = 0; i < playerCount; ++i) {
			playerID = players[i];
			
			// Give user items
			uj_core_strip_weapons(playerID);
			cs_set_user_armor( playerID, 100, CS_ARMOR_VESTHELM );
			set_user_health(playerID, 200 );
			
			
			switch( percent )
			{
				case 0:
				{
					give_item( playerID, "weapon_elite" );
					cs_set_user_bpammo( playerID, CSW_ELITE, 300 );
				}
				
				case 1: 
				{
					give_item( playerID, "weapon_mp5navy" );
					cs_set_user_bpammo( playerID, CSW_MP5NAVY, 500 );
				}
				
				case 2:
				{
					give_item( playerID, "weapon_tmp" );
					cs_set_user_bpammo( playerID, CSW_TMP, 500 );
				}
				
				case 3:
				{
					give_item( playerID, "weapon_p90" );
					cs_set_user_bpammo( playerID, CSW_P90, 500 );
				}
				
				case 4:
				{
					give_item( playerID, "weapon_mac10" );
					cs_set_user_bpammo( playerID, CSW_MAC10, 500 );
				}
				
				case 5:
				{
					give_item( playerID, "weapon_ak47" );
					cs_set_user_bpammo( playerID, CSW_AK47, 500 );
				}
				
				case 6:
				{
					give_item( playerID, "weapon_sg552" );
					cs_set_user_bpammo( playerID, CSW_SG552, 500 );
				}
				
				case 7:
				{
					give_item( playerID, "weapon_m4a1" );
					cs_set_user_bpammo( playerID, CSW_M4A1, 500 );
				}
				
				case 8:
				{
					give_item( playerID, "weapon_aug" );
					cs_set_user_bpammo( playerID, CSW_AUG, 500 );
				}
				
				case 9:
				{
					give_item( playerID, "weapon_scout" );
					cs_set_user_bpammo( playerID, CSW_SCOUT, 200 );
				}
				
				case 10:
				{
					give_item( playerID, "weapon_g3sg1" );
					cs_set_user_bpammo( playerID, CSW_G3SG1, 500 );
				}
				
				case 11:
				{
					give_item( playerID, "weapon_awp" );
					cs_set_user_bpammo( playerID, CSW_AWP, 200 );
				}
				
				case 12:
				{
					give_item( playerID, "weapon_m3" );
					cs_set_user_bpammo( playerID, CSW_M3, 500 );
				}
				
				case 13:
				{
					give_item( playerID, "weapon_xm1014" );
					cs_set_user_bpammo( playerID, CSW_XM1014, 500 );
				}
				
				case 14:
				{
					give_item( playerID, "weapon_m249" );
					cs_set_user_bpammo( playerID, CSW_M249, 500 );
				}
				
				case 15:
				{
					give_item( playerID, "weapon_usp" );
					cs_set_user_bpammo( playerID, CSW_USP, 300 );
				}
				
				case 16:
				{
					give_item( playerID, "weapon_p228" );
					cs_set_user_bpammo( playerID, CSW_P228, 300 );
				}		
				
				case 17:
				{
					give_item( playerID, "weapon_deagle" );
					cs_set_user_bpammo( playerID, CSW_DEAGLE, 300 );
				}
				
				case 18:
				{
					give_item( playerID, "weapon_fiveseven" );
					cs_set_user_bpammo( playerID, CSW_FIVESEVEN, 300 );
				}
				
				case 19:
				{
					give_item( playerID, "weapon_glock18" );
					cs_set_user_bpammo( playerID, CSW_GLOCK18, 300 );
				}
				
				case 20:
				{
					give_item( playerID, "weapon_ump45" );
					cs_set_user_bpammo( playerID, CSW_UMP45, 300 );
				}
				
				case 21:
				{
					give_item( playerID, "weapon_galil" );
					cs_set_user_bpammo( playerID, CSW_GALIL, 300 );
				}
				
				case 22:
				{
					give_item( playerID, "weapon_famas" );
					cs_set_user_bpammo( playerID, CSW_FAMAS, 300 );
				}
				
				case 23:
				{
					give_item( playerID, "weapon_sg550" );
					cs_set_user_bpammo( playerID, CSW_SG550, 500 );
				}
			}
		}
		
		uj_core_block_weapon_pickup(0, true);
		uj_chargers_block_heal(0, true);
		uj_chargers_block_armor(0, true);
	}
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
				if(iWeapID != CSW_KNIFE && iWeapID != CSW_M4A1)
			{
				SetHamReturnInteger( 1 );
				return HAM_SUPERCEDE;
			}
			case CS_TEAM_CT:
				if(iWeapID != CSW_KNIFE)
			{
				SetHamReturnInteger( 1 );
				return HAM_SUPERCEDE;
			}
		}
		
		return HAM_IGNORED;
	}
	
	return HAM_IGNORED;
}

/////////////////////////////
//----- HEADSHOT ONLY -----//
/////////////////////////////
public HamTraceAttack( iVictim, iAttacker, Float:dmg, Float:dir[3], Traceresult, iBits )
{
	if( g_dayEnabled)
	{
		if( !( 1 <= iAttacker <= g_iMaxPlayers ) || !( 1 <= iVictim <= g_iMaxPlayers ) || iVictim == iAttacker )
			return HAM_IGNORED;
		
		if( get_tr2( Traceresult, TR_iHitgroup ) != HIT_HEAD )
		{
			return HAM_SUPERCEDE;
		}
	}
	return HAM_IGNORED;
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
