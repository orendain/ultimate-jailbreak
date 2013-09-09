#include <amxmodx>
#include <amxmisc>
#include <hamsandwich>
#include <fakemeta_util>
#include <cstrike>
#include <engine>
#include <dhudmessage>
#include <uj_core>
#include <uj_effects>
#include <uj_menus>
#include <uj_items>
#include <uj_colorchat>

//defines

#define WEAPON_ID CSW_FAMAS

#define PRIMARY_WEAPONS_BITSUM ((1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90))


new FIX_SHIELD_HITBOX	= 1
new V_MODEL = 1
new P_MODEL = 1
new W_MODEL = 1

#define V_SHIELD_MODEL	"models/v_RiotShield2.mdl"
#define P_SHIELD_MODEL	"models/p_RiotShield2.mdl"
#define W_SHIELD_MODEL 	"models/w_RiotShield2.mdl"
#define SHIELD_ID	19081994

//			PEV INFO

#define pev_iDeployState	pev_iuser1
#define pev_iShieldId	pev_iuser2

/************************************************************************************/

//			SHIELD CONFIG

#define BEAK_RANGE	50.0	// How far can we do beaking ?
#define BEAK_DAMAGE	70.0	// How much damage can we do to our enemies?
#define BEAK_COOLDOWN	1.0	// How long does it take to do beaking again ?

#define DEATH_MSG	"RiotShield"	// Hud which is shown when we kill an enemy with Riot Shield

/************************************************************************************/
// For CLASSIFY
#define	CLASS_NONE						0
#define CLASS_MACHINE					1

stock Float:VEC_DUCK_HULL_MIN[3]	=	{ -16.0, -16.0, -18.0 }
stock Float:VEC_DUCK_HULL_MAX[3]	=	{ 16.0,  16.0,  32.0 }

#define HIT_SHIELD	8

#define HUD_HL_CROSSHAIR_DRAW (1<<7)
#define HUD_CS_CROSSHAIR_HIDE (1<<6)
	
const WEAPONSTATE_SHIELD_DRAW = (1<<5)
	
/************************************************************************************/

//	Private Offset
#define        m_pActiveItem                                    373
#define        g_szModelIndexPlayer                        491    //    psz
#define		m_flNextAttack						83
#define	m_flNextSecondaryAttack	47	// soonest time ItemPostFrame will call SecondaryAttack
#define        m_bHasShield                                    2043        //    [g/s]et_pdata_bool
#define        m_bUsesShield                                    2042        //    [g/s]et_pdata_bool
#define        m_fHasPrimary                                    116
#define	m_fWeaponState				74
#define        m_iClientHideHUD                                362

#define        m_pClientActiveItem                            374    //    client    version    of    the    active    item
#define        m_iHideHUD                                        361    //    the    players    hud    weapon    info    is    to    be    hidden
#define        m_iAnimationInCaseDie                        118    //    set    according    to    hitplace    and    random    values    //    used    when    dies    to    set    some    properties    (velocity,    that    kind    of    stuff)
/************************************************************************************/
enum
{
	ANIM_IDLE,
	ANIM_RELOAD,
	ANIM_DRAW,
	ANIM_BEAK_1,
	ANIM_BEAK_2,
	ANIM_BEAK_3
}

/************************************************************************************/
#define TASK_RESET_CROSSHAIR	1000
/************************************************************************************/


new const PLUGIN_NAME[] = "[UJ] Item - RiotShield";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

new const ITEM_NAME[] = "Riot Shield";
new const ITEM_MESSAGE[] = "You are impervious, kinda like superman, but not quite.";
new const ITEM_COST[] = "50";
new const ITEM_REBEL[] = "0";

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
	g_costCVar = register_cvar("uj_item_itemname_cost", ITEM_COST);
	g_rebelCVar = register_cvar("uj_item_itemname_rebel", ITEM_REBEL);

	// Register this item
	g_item = uj_items_register(ITEM_NAME, ITEM_MESSAGE, g_costCVar, g_rebelCVar);

	// Find the menu that item should appear in
	g_shopMenu = uj_menus_get_menu_id("Shop Menu");
	//		Event				*/
	register_event("CurWeapon", "Event_CurWeapon", "b", "1=1")
	
	/************************************************/
	
	/*		Message				*/
	
	register_message(get_user_msgid("DeathMsg"), "message_DeathMsg")
	
	/************************************************/
	/*		Fakemeta forwards		*/
	
	register_forward(FM_CmdStart, "fw_CmdStart")
	register_forward(FM_SetModel, "fw_SetModel_Post", 1)
 
	/* 	   Retrive Classname of Weapon Id	*/
	
	new szWeaponClass[32]
	get_weaponname(WEAPON_ID, szWeaponClass, sizeof szWeaponClass - 1)
	
	/************************************************/
	
	
	/*	        Hamsandwich forwards		*/
	
	RegisterHam(Ham_Item_Holster, szWeaponClass, "Forward_Item_Holster_Post")
	
	/************************************************/ 
 
}

public plugin_precache()
{
	//	Precache neccessary resources
	if (V_MODEL)	
		precache_model(V_SHIELD_MODEL)
	if (P_MODEL)	
		precache_model(P_SHIELD_MODEL)
	if (W_MODEL)	
		precache_model(W_SHIELD_MODEL)
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
	
	if (!is_user_connected(playerID) || !is_user_alive(playerID))
		return PLUGIN_HANDLED;
		
	if (!get_bit(g_hasItem, playerID)) {
	// Find transparency level

	// Glow user and set bit
	set_bit(g_hasItem, playerID);
	primary_wpn_drop(playerID)
	new szWeaponName[32]
	get_weaponname(WEAPON_ID, szWeaponName, sizeof szWeaponName - 1)
	
	new iEnt = fm_give_item(playerID, szWeaponName)
	
	if (!iEnt || !pev_valid(iEnt))
		return PLUGIN_HANDLED;
		
	cs_set_weapon_ammo(iEnt, -1)
	cs_set_user_bpammo(playerID, WEAPON_ID, 0)
	set_user_shield(playerID, iEnt, 1)
	
	update_hud_WeaponList(playerID, WEAPON_ID, -1, szWeaponName, -1)
	

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


public Event_CurWeapon(id)
{
	
	if (!is_user_connected(id) || !is_user_alive(id))
		return
	
	new iWeaponId = read_data(2)
	
	if (iWeaponId != WEAPON_ID)
		return
		
	new iEnt = get_pdata_cbase(id, m_pActiveItem, 5)
	
	if (!iEnt || !pev_valid(iEnt))
		return
		
	if (pev(iEnt, pev_iShieldId) != SHIELD_ID)
		return
		
	if (!pev(iEnt, pev_iDeployState))
	{
		set_user_shield(id, iEnt, 1)
		_CS_Crosshair_Toggle(id, 0, 1)
		
		if (FIX_SHIELD_HITBOX)
		{
			new szPlayerModel[32]
			cs_get_user_model(id, szPlayerModel, sizeof szPlayerModel - 1)
			
			new szFullModel[128]
			formatex(szFullModel, sizeof szFullModel - 1, "models/player/%s/%s.mdl", szPlayerModel, szPlayerModel)
			
			new iModelIndex = engfunc(EngFunc_ModelIndex, szFullModel)
			set_pdata_int(id, g_szModelIndexPlayer , iModelIndex, 5)
		}
			
	}
	
	
	
	if (V_MODEL)
		set_pev(id, pev_viewmodel2, V_SHIELD_MODEL)
		
	if (P_MODEL)
		set_pev(id, pev_weaponmodel2, P_SHIELD_MODEL)
	
	//	Player is covered by RIOT SHIELD
	_SetPlayerSequence(id, "shielded")
}

public message_DeathMsg(iMsgId, iMsgDest, iMsgEntity)
{
	new szTruncatedWeapon[33], iAttacker
	get_msg_arg_string(4, szTruncatedWeapon, sizeof szTruncatedWeapon - 1)
	
	// Get Attacker Id
	iAttacker = get_msg_arg_int(1)
	
	// Non-player attacker or self kill
	if(!is_user_connected(iAttacker))
		return
		
	new szWeaponName[32]
	get_weaponname(WEAPON_ID, szWeaponName, sizeof szWeaponName - 1)
	
	replace(szWeaponName, sizeof szWeaponName - 1, "weapon_", "")
	replace(szWeaponName, sizeof szWeaponName - 1, "navy", "")
	
	if (!equal(szTruncatedWeapon, szWeaponName))
		return
		
	new iEnt = get_pdata_cbase(iAttacker, m_pActiveItem, 5)
	
	//	Not valid weapon entity
	if (!iEnt || !pev_valid(iEnt))
		return
		
	//	Weapon is not a Riot Shield
	if (pev(iEnt, pev_iShieldId) != SHIELD_ID)
		return
		
	set_msg_arg_string(4, DEATH_MSG)
			
	return
}

public fw_CmdStart(id, iUcHandle, iSeed)
{
	if (!is_user_alive(id))
		return
		
	new iClip
	new iWeaponId = get_user_weapon(id, iClip)
	
	if (iWeaponId != WEAPON_ID)
		return
		
	new iEnt = get_pdata_cbase(id, m_pActiveItem, 5)
	
	if (!iEnt || !pev_valid(iEnt))
		return
		
	if (pev(iEnt, pev_iShieldId) != SHIELD_ID)
		return
		
		
	new iButtonId = get_uc(iUcHandle, UC_Buttons)
	
	if (iButtonId & IN_ATTACK)
	{
		//	Release Attack Button
		set_uc(iUcHandle, UC_Buttons, iButtonId &~ IN_ATTACK)
		
		new Float:fNextAttack = get_pdata_float(id, m_flNextAttack, 5)
	
		//	We are not ready to attack ?
		if (fNextAttack >= 0.0)
			return
			
			
		//	Play Animation | Do Damage Calculation | Set Beaking Cooldown time
		play_weapon_anim(id, ANIM_BEAK_1)
		UT_KnifeAttack(id, 1, BEAK_DAMAGE, BEAK_RANGE, DMG_SLASH)
		set_pdata_float(id, m_flNextAttack, BEAK_COOLDOWN, 5)
	}
	
	if (iButtonId & IN_ATTACK2)
	{
		//	Release Attack2 Button
		set_uc(iUcHandle, UC_Buttons, iButtonId &~ IN_ATTACK2)
		console_cmd(id, "-attack2")
		
		//	Set Next Secondary Attack Time to 9999.0 to block Secondary Attack
		set_pdata_float(iEnt, m_flNextSecondaryAttack, 9999.0, 4)
		
		
	}
}

public fw_SetModel_Post(iEnt, szModel[])
{
	if (!iEnt || !pev_valid(iEnt))
		return
		
	new id = pev(iEnt, pev_owner)
	
	new szClassName[32]
	pev(iEnt, pev_classname, szClassName, sizeof szClassName - 1)
	
	if (!equal(szClassName, "weaponbox", 9))
		return
	
	//	Instead of being "weaponbox", ClassName now is weapon_....
	get_weaponname(WEAPON_ID, szClassName , sizeof szClassName - 1)
	
	new szWorldModel[128] // Retrieve World Model of the replacing weapon
	
	//	The format of szWorldModel is : weapon_<name>.mdl
	formatex(szWorldModel, sizeof szWorldModel - 1, "models/w_%s.mdl", szClassName)
	
	//	The format of szWorldModel is : <name>.mdl
	replace(szWorldModel, sizeof szWorldModel - 1, "weapon_", "")
	
	//	The format of szWorldModel is : <name>.mdl - in case the replacing weapon is MP5 Navy
	replace(szWorldModel, sizeof szWorldModel - 1, "navy", "")
	
	if (!equal(szModel, szWorldModel))
	{
		client_print(id, print_center, "%s : %s", szModel, szWorldModel)
		return
	}
	
	new iWeaponEnt = fm_find_ent_by_owner(-1, szClassName, iEnt)
	
	if (!iWeaponEnt || !pev_valid(iWeaponEnt))
	{
		client_print(id, print_center, "NOT VALID WEAPON ENT")
		return
	}
	
	engfunc(EngFunc_SetModel, iEnt, W_SHIELD_MODEL)
	set_pev(iEnt, pev_iShieldId, SHIELD_ID)
	
	remove_task(id + TASK_RESET_CROSSHAIR)
	set_task(0.25, "ResetCrosshair_TASK", id + TASK_RESET_CROSSHAIR)
}

public fw_PlayerTouchWeaponBox(iEnt, id)
{
	if (!is_user_alive(id))
		return PLUGIN_CONTINUE
		
	if (pev(iEnt, pev_iShieldId) != SHIELD_ID)
		return PLUGIN_CONTINUE
		
	if (is_primary_wpn(WEAPON_ID) && cs_get_user_hasprim(id))
		return PLUGIN_HANDLED
		
	new szWeaponName[32]
	get_weaponname(WEAPON_ID, szWeaponName, sizeof szWeaponName - 1)
	
	new iWeaponEnt = fm_give_item(id, "weapon_famas")
	
	if (!iWeaponEnt || !pev_valid(iWeaponEnt))
		return PLUGIN_HANDLED
		
	cs_set_weapon_ammo(iWeaponEnt, 0)
	cs_set_user_bpammo(id, WEAPON_ID, -1)
	set_user_shield(id, iWeaponEnt, 1)
	engfunc(EngFunc_RemoveEntity, iEnt)
	return PLUGIN_HANDLED
		
}

public Forward_Item_Holster_Post(iEnt)
{
	if (!iEnt || !pev_valid(iEnt))
		return
		
	new id = pev(iEnt, pev_owner)
	
	if (!is_user_connected(id) || !is_user_alive(id))
		return
		
	set_user_shield(id, iEnt, 0)
	remove_task(id + TASK_RESET_CROSSHAIR)
	set_task(0.25, "ResetCrosshair_TASK", id + TASK_RESET_CROSSHAIR)
}

public ResetCrosshair_TASK(TASKID)
{
	new id = TASKID - TASK_RESET_CROSSHAIR
	
	_CS_Crosshair_Toggle(id, 1, 1)
}

public _SetPlayerSequence(id, szSequence[])
	set_pdata_string(id, 492*4, szSequence, -1, 5)

stock set_user_shield(id, iEnt, iToggle)
{
	if (!iToggle)
	{
		set_pdata_bool(id, m_bHasShield, false)
		set_pdata_bool(id, m_bUsesShield, false)
		set_pev(id, pev_gamestate, 1) 
		set_pev(iEnt, pev_iDeployState, 0)
		return 
	}
	
	set_pdata_int(id, m_fHasPrimary, 1)
	set_pev(id, pev_gamestate, 0)
	
	//	This function makes your weapon not able to FIRE 
	set_pdata_int(iEnt, m_fWeaponState, WEAPONSTATE_SHIELD_DRAW, 4)
	
	set_pev(iEnt, pev_iDeployState, 0)
	set_pev(iEnt, pev_iShieldId, SHIELD_ID)
}


/*				STOCK					*/
stock primary_wpn_drop(index)
{
	new weapons[32], num, Weapon
	
	if (!is_user_connected(index))
		return
		
	get_user_weapons(index, weapons, num)
	
	engclient_cmd(index, "drop", "weapon_shield")
			
	for (new i = 0; i < num; i++) 
	{
		Weapon = weapons[i]
		
		if (PRIMARY_WEAPONS_BITSUM & (1<<Weapon))
		{
			static wname[32]
			get_weaponname(Weapon, wname, sizeof wname - 1)
			engclient_cmd(index, "drop", wname)
		}
		
	}
}

stock is_primary_wpn(iWeaponId)
{
	if (PRIMARY_WEAPONS_BITSUM & (1<<iWeaponId))
		return 1
		
	return 0
}


stock GetGunPosition(const iPlayer, Float: vecResult[3])
{
	new Float: vecViewOfs[3];
	
	pev(iPlayer, pev_origin, vecResult);
	pev(iPlayer, pev_view_ofs, vecViewOfs);
    
	xs_vec_add(vecResult, vecViewOfs, vecResult);
} 
 
stock GetCenter(const iEntity, Float: vecSrc[3])
{
        new Float: vecAbsMax[3];
        new Float: vecAbsMin[3];
       
        pev(iEntity, pev_absmax, vecAbsMax);
        pev(iEntity, pev_absmin, vecAbsMin);
       
        xs_vec_add(vecAbsMax, vecAbsMin, vecSrc);
        xs_vec_mul_scalar(vecSrc, 0.5, vecSrc);
}

stock is_Ent_Breakable(iEnt)
{
	if (!iEnt || !pev_valid(iEnt))
		return 0
	
	if ((entity_get_float(iEnt, EV_FL_health) > 0.0) && (entity_get_float(iEnt, EV_FL_takedamage) > 0.0) && !(entity_get_int(iEnt, EV_INT_spawnflags) & SF_BREAK_TRIGGER_ONLY))
		return 1
	
	if (is_user_alive(iEnt))
		return 1
		
	return 0
}

FindHullIntersection(const Float: vecSrc[3], &iTrace, const Float: vecMins[3], const Float: vecMaxs[3], const iEntity)
{
	new i, j, k;
	new iTempTrace;
	
	new Float: vecEnd[3];
	new Float: flDistance;
	new Float: flFraction;
	new Float: vecEndPos[3];
	new Float: vecHullEnd[3];
	new Float: flThisDistance;
	new Float: vecMinMaxs[2][3];
	
	flDistance = 999999.0;
	
	xs_vec_copy(vecMins, vecMinMaxs[0]);
	xs_vec_copy(vecMaxs, vecMinMaxs[1]);
	
	get_tr2(iTrace, TR_vecEndPos, vecHullEnd);
	
	xs_vec_sub(vecHullEnd, vecSrc, vecHullEnd);
	xs_vec_mul_scalar(vecHullEnd, 2.0, vecHullEnd);
	xs_vec_add(vecHullEnd, vecSrc, vecHullEnd);
	
	engfunc(EngFunc_TraceLine, vecSrc, vecHullEnd, DONT_IGNORE_MONSTERS, iEntity, (iTempTrace = create_tr2()));
	get_tr2(iTempTrace, TR_flFraction, flFraction);
	
	if (flFraction < 1.0)
	{
		free_tr2(iTrace);
		
		iTrace = iTempTrace;
		return;
	}
	
	for (i = 0; i < 2; i++)
	{
		for (j = 0; j < 2; j++)
		{
			for (k = 0; k < 2; k++)
			{
				vecEnd[0] = vecHullEnd[0] + vecMinMaxs[i][0];
				vecEnd[1] = vecHullEnd[1] + vecMinMaxs[j][1];
				vecEnd[2] = vecHullEnd[2] + vecMinMaxs[k][2];
				
				engfunc(EngFunc_TraceLine, vecSrc, vecEnd, DONT_IGNORE_MONSTERS, iEntity, iTempTrace);
				get_tr2(iTempTrace, TR_flFraction, flFraction);
				
				if (flFraction < 1.0)
				{
					get_tr2(iTempTrace, TR_vecEndPos, vecEndPos);
					xs_vec_sub(vecEndPos, vecSrc, vecEndPos);
					
					if ((flThisDistance = xs_vec_len(vecEndPos)) < flDistance)
					{
						free_tr2(iTrace);
						
						iTrace = iTempTrace;
						flDistance = flThisDistance;
					}
				}
			}
		}
	}
}

stock UT_KnifeAttack(iPlayer,  iStab, Float:fDamage, Float:fRange, iDamageBit)
{

		
	#define Instance(%0) ((%0 == -1) ? 0 : %0)
	
	new iTrace;
	
	new iDidHit;
	new iEntity;
	new iHitWorld;
	
	
	new Float: vecSrc[3];
	new Float: vecEnd[3];
	new Float: vecAngle[3];
	new Float: vecRight[3];
	new Float: vecForward[3];
	
	new Float: flFraction;
	
	iTrace = create_tr2();
	
	pev(iPlayer, pev_v_angle, vecAngle);
	engfunc(EngFunc_MakeVectors, vecAngle);
	
	GetGunPosition(iPlayer, vecSrc);
	
	global_get(glb_v_right, vecRight);
	global_get(glb_v_forward, vecForward);
	
	if (!iStab)
	{
		xs_vec_mul_scalar(vecForward, fRange, vecForward);
		xs_vec_add(vecForward, vecSrc, vecEnd);
	}
	else
	{
		xs_vec_mul_scalar(vecRight, 6.0, vecRight);
		xs_vec_mul_scalar(vecForward, fRange, vecForward);
		
		xs_vec_add(vecRight, vecForward, vecForward);
		xs_vec_add(vecForward, vecSrc, vecEnd);
	}
	
	engfunc(EngFunc_TraceLine, vecSrc, vecEnd, DONT_IGNORE_MONSTERS, iPlayer, iTrace);
	get_tr2(iTrace, TR_flFraction, flFraction);
	
	if (flFraction >= 1.0)
	{
		//engfunc(EngFunc_TraceHull, vecSrc, vecEnd, DONT_IGNORE_MONSTERS, HULL_HEAD, iPlayer, iTrace);
		
		new Float:flVectorEnd[3]
		
		pev(iPlayer, pev_v_angle, flVectorEnd)
		angle_vector(flVectorEnd, ANGLEVECTOR_FORWARD, flVectorEnd)
		xs_vec_mul_scalar(flVectorEnd, fRange, flVectorEnd)
		xs_vec_add(vecSrc, flVectorEnd, flVectorEnd)
		engfunc(EngFunc_TraceHull, vecSrc, flVectorEnd, DONT_IGNORE_MONSTERS, HULL_HEAD, iPlayer, iTrace)
		
		get_tr2(iTrace, TR_flFraction, flFraction);
		
		if (flFraction < 1.0)
		{
			new iHit = Instance(get_tr2(iTrace, TR_pHit));
			
			if (!iHit || ExecuteHamB(Ham_IsBSPModel, iHit))
			{
				FindHullIntersection(vecSrc, iTrace, VEC_DUCK_HULL_MIN	, VEC_DUCK_HULL_MAX, iPlayer);
			}
			
			get_tr2(iTrace, TR_vecEndPos, vecEnd);
		}
	}
	
	get_tr2(iTrace, TR_flFraction, flFraction);
	
	if (flFraction >= 1.0)
	{
		
	}
	else
	{
		iHitWorld = 1
		
		iDidHit = true;
		iEntity = Instance(get_tr2(iTrace, TR_pHit));
		
		new iEyeOrigin[3], Float:fEyeOrigin[3]
		
		get_user_origin(iPlayer, iEyeOrigin, 1)
		IVecFVec(iEyeOrigin, fEyeOrigin)
		
		new Float:fVictimOrigin[3]
		
		new iHitgroup = 0
		
		if (pev_valid(iEntity))
		{
				
			pev(iEntity, pev_origin, fVictimOrigin)
			
			GetCenter(iEntity, vecSrc);
			GetCenter(iPlayer, vecEnd);
		       
			xs_vec_sub(vecEnd, vecSrc, vecEnd);
			xs_vec_normalize(vecEnd, vecEnd);
		       
			pev(iEntity, pev_angles, vecAngle);
			engfunc(EngFunc_MakeVectors, vecAngle);
		       
			global_get(glb_v_forward, vecForward);
			xs_vec_mul_scalar(vecEnd, -1.0, vecEnd);
		       
			if (xs_vec_dot(vecForward, vecEnd) > 0.3)
			{
				// flDamage = 10000.0
			}
			
			
			iHitgroup = get_tr2(iTrace, TR_iHitgroup)
			
			if (iHitgroup == HIT_HEAD)
			{
				fDamage *= 1.5;
			}
			else if (iHitgroup == HIT_SHIELD)
				fDamage = 0.0
				
			new iIsPlayer = 0
			
			if (ExecuteHamB(Ham_IsPlayer, iEntity))
			{
				iIsPlayer = 1
				set_pdata_int(iPlayer,  m_iAnimationInCaseDie, iHitgroup, 5)
			}
			
			new Float:fDistance = get_distance_f(fEyeOrigin, fVictimOrigin)
			
			new Float:fVecForward[3]
			
			global_get(glb_v_forward, fVecForward)
			
			new Float:fTmpDmg = (fDamage / fRange) * fDistance
			 
			
			ExecuteHamB(Ham_TraceAttack, iEntity, iPlayer, fTmpDmg, fVecForward, iTrace, iDamageBit)
			
			new iDamageCanBeExecuted = 0
			
			if (iIsPlayer)
			{
				
				if (cs_get_user_team(iPlayer) == cs_get_user_team(iEntity))
				{
					if (get_cvar_num("mp_friendlyfire"))
						iDamageCanBeExecuted = 1
				}
				else	iDamageCanBeExecuted = 1
				iHitWorld = 0
			}
			else
			{
				if (is_Ent_Breakable(iEntity))
					iDamageCanBeExecuted = 1
			}
			if (iDamageCanBeExecuted)
			{
				ExecuteHamB(Ham_TakeDamage, iEntity, iPlayer, iPlayer, fTmpDmg, iDamageBit);
					
			}
				
			
				
			
		}
		
		
		if (iHitWorld)
		{
			new iVecEnd[3]
			get_tr2(iTrace, TR_vecEndPos, vecEnd)
			FVecIVec(vecEnd, iVecEnd)
			emessage_begin(MSG_BROADCAST, SVC_TEMPENTITY)
			ewrite_byte(TE_SPARKS)
			ewrite_coord(iVecEnd[0])
			ewrite_coord(iVecEnd[1])
			ewrite_coord(iVecEnd[2]) 
			emessage_end()
		}
			
			
	}

	free_tr2(iTrace);
	return iDidHit;
}

public play_weapon_anim(id, iAnim)
{
	if (!is_user_alive(id))
		return
		
	set_pev(id, pev_weaponanim, iAnim)
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, _, id)
	write_byte(iAnim)
	write_byte(pev(id, pev_body))
	message_end()
	
	
}

public _CS_Crosshair_Toggle(id, iToggle, iEngineMessage)
{
	if (!is_user_connected(id) || is_user_bot(id))	
		return
		
	new iHudState = get_pdata_int(id, m_iHideHUD, 5)
	
	if (iToggle)
	{
		if (iHudState & HUD_CS_CROSSHAIR_HIDE)
			iHudState &=~ HUD_CS_CROSSHAIR_HIDE
		
		if (iEngineMessage)
		{
			set_pdata_int(id, m_iClientHideHUD, 0)
			set_pdata_int(id, m_iHideHUD , iHudState, 5)
			
			if (is_user_alive(id))
				set_pdata_cbase(id, m_pClientActiveItem, FM_NULLENT)
		}
		else
			set_pdata_int(id, m_iHideHUD, iHudState, 5)
	}
	else
	{
		if (!(iHudState & HUD_CS_CROSSHAIR_HIDE))
			iHudState |= HUD_CS_CROSSHAIR_HIDE
			
		set_pdata_int(id, m_iHideHUD , iHudState, 5)
	}
	
}

public update_hud_WeaponList(id, iCsWpnId, iCsWpnClip, WpnClass[], iMaxBp)
{
	new /*sWeaponName[32],*/ iPriAmmoId, iPriAmmoMax, iSecAmmoId, iSecAmmoMax, iSlotId, iNumberInSlot, iWeaponId, iFlags
	//format(sWeaponName, charsmax(sWeaponName), "%s", WpnClass)    
	iPriAmmoId = -1
	iPriAmmoMax = -1
	iSecAmmoId = -1 //CSWPN_AMMOID[iCsWpnId]
	iSecAmmoMax = iMaxBp
	iNumberInSlot = get_cswpn_position(iCsWpnId)
	iWeaponId = iCsWpnId
	get_cswpn_slotid_flags(iCsWpnId, iSlotId, iFlags)

	send_message_WeaponList(id, WpnClass, iPriAmmoId, iPriAmmoMax, iSecAmmoId, iSecAmmoMax, iSlotId, iNumberInSlot, iWeaponId, iFlags)
	
}

stock get_cswpn_position(cswpn)
{
	new iPosition
    
	switch (cswpn)
	{
		case CSW_P228: iPosition = 3
		case CSW_SCOUT: iPosition = 9
		case CSW_HEGRENADE: iPosition = 1
		case CSW_XM1014: iPosition = 12
		case CSW_C4: iPosition = 3
		case CSW_MAC10: iPosition = 13
		case CSW_AUG: iPosition = 14
		case CSW_SMOKEGRENADE: iPosition = 3
		case CSW_ELITE: iPosition = 5
		case CSW_FIVESEVEN: iPosition = 6
		case CSW_UMP45: iPosition = 15
		case CSW_SG550: iPosition = 16
		case CSW_GALIL: iPosition = 17
		case CSW_FAMAS: iPosition = 18
		case CSW_USP: iPosition = 4
		case CSW_GLOCK18: iPosition = 2
		case CSW_AWP: iPosition = 2
		case CSW_MP5NAVY: iPosition = 7
		case CSW_M249: iPosition = 4
		case CSW_M3: iPosition = 5
		case CSW_M4A1: iPosition = 6
		case CSW_TMP: iPosition = 11
		case CSW_G3SG1: iPosition = 3
		case CSW_FLASHBANG: iPosition = 2
		case CSW_DEAGLE: iPosition = 1
		case CSW_SG552: iPosition = 10
		case CSW_AK47: iPosition = 1
		case CSW_KNIFE: iPosition = 1
		case CSW_P90: iPosition = 8
		default: iPosition = 0
	}
	return iPosition
}

stock get_cswpn_slotid_flags(iCsWpn, &iSlotId, &iFlags)
{
	new iCsWpnType = get_cswpn_type(iCsWpn)
	switch (iCsWpnType)
	{
		case 1:
		{
			iSlotId = 0
			iFlags = 0
		}
		case 2:
		{
			iSlotId = 1
			iFlags = 0
		}
		case 3:
		{
			iSlotId = 2
			iFlags = 0
		}
		case 4:
		{    
			iSlotId = 3
			iFlags = 24
		}
		case 5:
		{    
			iSlotId = 4
			iFlags = 24
		}
	}
}

stock get_cswpn_type(cswpn)
{
	new iType
	switch (cswpn)
	{
		case CSW_M3, CSW_XM1014, CSW_MAC10, CSW_UMP45, CSW_MP5NAVY, CSW_TMP, CSW_P90, CSW_SCOUT, CSW_AUG, CSW_SG550, CSW_GALIL, CSW_FAMAS, CSW_AWP, CSW_M4A1, CSW_G3SG1, CSW_SG552, CSW_AK47, CSW_M249:
		{
			iType = 1
		}
		case CSW_P228, CSW_ELITE, CSW_FIVESEVEN, CSW_USP, CSW_GLOCK18, CSW_DEAGLE:
		{
			iType = 2
		}
		case CSW_KNIFE:
		{
			iType = 3
		}
		case CSW_HEGRENADE,  CSW_FLASHBANG, CSW_SMOKEGRENADE:
		{
			iType = 4
		}
		case CSW_C4:
		{
			iType = 5
		}
		default:
		{
			iType = 0
		}
	}
	return iType
}

stock send_message_WeaponList(id, const sWeaponName[], iPriAmmoID, iPriAmmoMax, iSecAmmoID, iSecAmmoMax, iSlotId, iNumberInSlot, iWeaponId, iFlags)
{
	if (!is_user_connected(id))
		return
		
	if (is_user_bot(id))
		return
		
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("WeaponList") , _, id)
	write_string(sWeaponName)
	write_byte(iPriAmmoID)
	write_byte(iPriAmmoMax)
	write_byte(iSecAmmoID)
	write_byte(iSecAmmoMax)
	write_byte(iSlotId)
	write_byte(iNumberInSlot)
	write_byte(iWeaponId)
	write_byte(iFlags)
	message_end()
}  

stock set_pdata_char(ent, charbased_offset, value, intbase_linuxdiff = 5)
{
	#define SHORT_BYTES	2
	#define INT_BYTES		4
	#define BYTE_BITS		8

	value &= 0xFF
	new int_offset_value = get_pdata_int(ent, charbased_offset / INT_BYTES, intbase_linuxdiff)
	new bit_decal = (charbased_offset % INT_BYTES) * BYTE_BITS
	int_offset_value &= ~(0xFF<<bit_decal) // clear byte
	int_offset_value |= value<<bit_decal
	set_pdata_int(ent, charbased_offset / INT_BYTES, int_offset_value, intbase_linuxdiff)
	return 1
}

stock set_pdata_bool(ent, charbased_offset, bool:value, intbase_linuxdiff = 5)
{
	set_pdata_char(ent, charbased_offset, _:value, intbase_linuxdiff)
}

