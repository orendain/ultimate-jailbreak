#include <amxmisc>
#include <amxmodx>
#include <fakemeta>
#include <fun>
#include <cstrike>
#include <hamsandwich>
#include <engine>
#include <dhudmessage>
#include <uj_core>
#include <uj_effects>
#include <uj_menus>
#include <uj_items>
#include <uj_colorchat>

#define OFFSET_CAN_LONGJUMP    356 // VEN
#define BUNNYJUMP_MAX_SPEED_FACTOR 1.7

#define PLAYER_JUMP		6

new const PLUGIN_NAME[] = "[UJ] Item - Bunny Hop";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

new const ITEM_NAME[] = "Bunny Hop";
new const ITEM_MESSAGE[] = "Bunny Hop Skills [Enabled]";
new const ITEM_COST[] = "40";
new const ITEM_REBEL[] = "0";

new g_iCdWaterJumpTime[33]
new bool:g_bAlive[33]

new g_pcvarBhopStyle, g_pcvarAutoBhop, g_pcvarFallDamage
new g_pcvarGravity

// Menu variables
new g_shopMenu;
new g_item;

// Common CVars
new g_costCVar;
new g_rebelCVar;

// Item-specific CVars
//none

// Keep track of who has invisibility
new g_hasItem;

public plugin_init()
{
	register_plugin(PLUGIN_NAME, PLUGIN_VERS, PLUGIN_AUTH);
		
	// Register CVars
	g_costCVar = register_cvar("uj_item_bhop_cost", ITEM_COST);
	g_rebelCVar = register_cvar("uj_item_bhop_rebel", ITEM_REBEL);
	
	  // Register this item
	g_item = uj_items_register(ITEM_NAME, ITEM_MESSAGE, g_costCVar, g_rebelCVar);
		
	// Find the menu that item should appear in
	g_shopMenu = uj_menus_get_menu_id("Shop Menu");
	g_pcvarBhopStyle = register_cvar("bhop_style", "0")  // (1 : no slowdown, 2 : no speed limit)
	g_pcvarAutoBhop = register_cvar("bhop_auto", "0")
	g_pcvarFallDamage = register_cvar("mp_falldamage", "1.0")
	
	RegisterHam(Ham_Player_Jump, "player", "Player_Jump")
	register_forward(FM_UpdateClientData, "UpdateClientData")
	register_forward(FM_CmdStart, "CmdStart")
	RegisterHam(Ham_Spawn, "player", "Check_Alive", 1)
	RegisterHam(Ham_Killed, "player", "Check_Alive", 1)
	RegisterHam(Ham_TakeDamage, "player", "Ham_TakeDamage_player")
	
	register_concmd("amx_autobhop", "AdminCmd_Bhop", ADMIN_LEVEL_A, "<nick|#userid> <0|1>")
	
	g_pcvarGravity = get_cvar_pointer("sv_gravity")  
  
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
  if (menuID != g_shopMenu) {
    return UJ_ITEM_DONT_SHOW;
  }

  // If the specified user is already invisible, hide item from menus
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

  give_shopitem(playerID);
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

  remove_item(playerID);
}

give_shopitem(playerID)
{
	if (!get_bit(g_hasItem, playerID)) {
    // Find transparency level

    // Glow user and set bit
	set_bit(g_hasItem, playerID);

  }
	return PLUGIN_HANDLED;
}

remove_item(playerID)
{
  // If the user is glowed, remove glow and clear bit
  if (get_bit(g_hasItem, playerID)) {
    clear_bit(g_hasItem, playerID);
  }
}

public client_disconnect(playerID)
{

	remove_item(playerID);

}

public client_putinserver(playerID)
{

	remove_item(playerID)

}


public Check_Alive(playerID)
{
	g_bAlive[playerID] = bool:is_user_alive(playerID)
}

public Ham_TakeDamage_player(playerID, ent, idattacker, Float:damage, damagebits)
{
	if( damagebits != DMG_FALL )
		return HAM_IGNORED

	damage *= get_pcvar_float(g_pcvarFallDamage)
	SetHamParamFloat(4, damage)

	return HAM_HANDLED
}

public CmdStart(playerID, uc_handle, seed)
{
	if(	g_bAlive[playerID]
	&&	get_pcvar_num(g_pcvarBhopStyle)
	&&	get_uc(uc_handle, UC_Buttons) & IN_USE
	&&	pev(playerID, pev_flags) & FL_ONGROUND	)
	{
		static Float:fVelocity[3]
		pev(playerID, pev_velocity, fVelocity)
		fVelocity[0] *= 0.3
		fVelocity[1] *= 0.3
		fVelocity[2] *= 0.3
		set_pev(playerID, pev_velocity, fVelocity)
	}
}

public Player_Jump(playerID)
{
	if( !g_bAlive[playerID] )
	{
		return
	}
	
	static iBhopStyle ; iBhopStyle = get_pcvar_num(g_pcvarBhopStyle)
	if(!iBhopStyle)
	{
		static iOldButtons ; iOldButtons = pev(playerID, pev_oldbuttons)
		if( (get_pcvar_num(g_pcvarAutoBhop) || get_bit(g_hasItem, playerID)) && iOldButtons & IN_JUMP && pev(playerID, pev_flags) & FL_ONGROUND)
		{
			iOldButtons &= ~IN_JUMP
			set_pev(playerID, pev_oldbuttons, iOldButtons)
			set_pev(playerID, pev_gaitsequence, PLAYER_JUMP)
			set_pev(playerID, pev_frame, 0.0)
			return
		}
		return
	}

	if( g_iCdWaterJumpTime[playerID] )
	{
		//client_print(id, print_center, "Water Jump !!!")
		return
	}

	if( pev(playerID, pev_waterlevel) >= 2 )
	{
		return
	}

	static iFlags ; iFlags = pev(playerID, pev_flags)
	if( !(iFlags & FL_ONGROUND) )
	{
		return
	}

	static iOldButtons ; iOldButtons = pev(playerID, pev_oldbuttons)
	if( !get_pcvar_num(g_pcvarAutoBhop) && !get_bit(g_hasItem, playerID) && iOldButtons & IN_JUMP )
	{
		return
	}

	// prevent the game from making the player jump
	// as supercede this forward just fails
	set_pev(playerID, pev_oldbuttons, iOldButtons | IN_JUMP)

	static Float:fVelocity[3]
	pev(playerID, pev_velocity, fVelocity)

	if(iBhopStyle == 1)
	{
		static Float:fMaxScaledSpeed
		pev(playerID, pev_maxspeed, fMaxScaledSpeed)
		if(fMaxScaledSpeed > 0.0)
		{
			fMaxScaledSpeed *= BUNNYJUMP_MAX_SPEED_FACTOR
			static Float:fSpeed
			fSpeed = floatsqroot(fVelocity[0]*fVelocity[0] + fVelocity[1]*fVelocity[1] + fVelocity[2]*fVelocity[2])
			if(fSpeed > fMaxScaledSpeed)
			{
				static Float:fFraction
				fFraction = ( fMaxScaledSpeed / fSpeed ) * 0.65
				fVelocity[0] *= fFraction
				fVelocity[1] *= fFraction
				fVelocity[2] *= fFraction
			}
		}
	}

	static Float:fFrameTime, Float:fPlayerGravity
	global_get(glb_frametime, fFrameTime)
	pev(playerID, pev_gravity, fPlayerGravity)

	new iLJ
	if(	(pev(playerID, pev_bInDuck) || iFlags & FL_DUCKING)
	&&	get_pdata_int(playerID, OFFSET_CAN_LONGJUMP)
	&&	pev(playerID, pev_button) & IN_DUCK
	&&	pev(playerID, pev_flDuckTime)	)
	{
		static Float:fPunchAngle[3], Float:fForward[3]
		pev(playerID, pev_punchangle, fPunchAngle)
		fPunchAngle[0] = -5.0
		set_pev(playerID, pev_punchangle, fPunchAngle)
		global_get(glb_v_forward, fForward)

		fVelocity[0] = fForward[0] * 560
		fVelocity[1] = fForward[1] * 560
		fVelocity[2] = 299.33259094191531084669989858532
		iLJ = 1
	}
	else
	{
		fVelocity[2] = 268.32815729997476356910084024775
	}

	fVelocity[2] -= fPlayerGravity * fFrameTime * 0.5 * get_pcvar_num(g_pcvarGravity)

	set_pev(playerID, pev_velocity, fVelocity)

	set_pev(playerID, pev_gaitsequence, PLAYER_JUMP+iLJ)
	set_pev(playerID, pev_frame, 0.0)
}

public UpdateClientData(playerID, sendweapons, cd_handle)
{
	g_iCdWaterJumpTime[playerID] = get_cd(cd_handle, CD_WaterJumpTime)
}

public AdminCmd_Bhop(playerID, level, cid)
{
	if(!cmd_access(playerID, level, cid, 2) )
	{
		return PLUGIN_HANDLED
	}

	new szPlayer[32]
	read_argv(1, szPlayer, 31)
	new iPlayer = cmd_target(playerID, szPlayer, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_ALLOW_SELF | CMDTARGET_NO_BOTS)

	if( !iPlayer )
	{
		return PLUGIN_HANDLED
	}
/*
	if( read_argc() < 3 )
	{
		g_bAutoBhop[iPlayer] = !g_bAutoBhop[iPlayer]
	}*/
	else
	{
		new arg2[2]
		read_argv(2, arg2, 1)
		if(arg2[0] == '1' && !get_bit(g_hasItem, playerID))
		{
			give_shopitem(playerID);
		}
		else if(arg2[0] == '0' && get_bit(g_hasItem, playerID))
		{
			remove_item(playerID);
		}
	}

	client_print(playerID, print_console, "Player %s autobhop is currently : %s", szPlayer, get_bit(g_hasItem, playerID) ? "On" : "Off")
	return PLUGIN_HANDLED
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
