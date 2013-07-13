#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <xs>
#include <dhudmessage>
#include <uj_core>
#include <uj_effects>
#include <uj_menus>
#include <uj_items>
#include <uj_colorchat>

#define MAX_CLIENTS 32

// gametime <-> flashtime coefficient
#define C_FLASHTIME (1<<12)

// flash flags, RGB, alpha
#define FLASH_FLAGS	0
#define FLASH_RED	255
#define FLASH_GREEN	255
#define FLASH_BLUE	255
//#define FLASH_ALPHA	255

new const PLUGIN_NAME[] = "[UJ] Item - Blinding Flashlight";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

new const ITEM_NAME[] = "Blinding Flashlight";
new const ITEM_MESSAGE[] = "Blinding Flashlight";
new const ITEM_COST[] = "30";
new const ITEM_REBEL[] = "1";

// Menu variables
new g_shopMenu;
new g_item;

// Common CVars
new g_costCVar;
new g_rebelCVar;

// Item-specific CVars
new bool:g_flashlight[MAX_CLIENTS + 1]
new Float:g_flash_until[MAX_CLIENTS + 1]

new g_msgid_screen_fade
new 
bool:g_bFF,
bool:g_bUnderCS
new 
g_iHitPlaceFlags,
g_iMaxDist, 
g_iMinDist, 
g_iDeltaDist,
g_iMaxBlend, 
g_iMinBlend, 
g_iDeltaBlend
new 
Float:g_fMaxImpcatTime,
Float:g_fFxFactor
new 
g_pcvar_ff,
g_cvarMaxDist, 
g_cvarMinDist, 
g_cvarMaxImpactTime, 
g_cvarMaxBlend, 
g_cvarMinBlend,
g_cvarHitPlace,
g_cvarFxFactor


// Keep track of who has invisibility
new g_hasItem;

public plugin_init()
{
	register_plugin(PLUGIN_NAME, PLUGIN_VERS, PLUGIN_AUTH);
	
	// Register CVars
	g_costCVar = register_cvar("uj_item_bflashlight_cost", ITEM_COST);
	g_rebelCVar = register_cvar("uj_item_bflashlight_rebel", ITEM_REBEL);
	
	// Register this item
	g_item = uj_items_register(ITEM_NAME, ITEM_MESSAGE, g_costCVar, g_rebelCVar);
	
	// Find the menu that item should appear in
	g_shopMenu = uj_menus_get_menu_id("Shop Menu");
	g_bUnderCS = bool:cstrike_running()
	g_msgid_screen_fade = get_user_msgid("ScreenFade")
		
	// NOTE: actual distance is further but it's already long enough
	g_cvarMaxDist = register_cvar("bf_maxdistance", "1500") 
	// NOTE: this is exact length when strength of light stays constant
	// (used Zoom Info plugin & AWP weapon)
	g_cvarMinDist = register_cvar("bf_mindistance", "500")
	g_cvarMaxImpactTime = register_cvar("bf_maxblindtime", "1.5")
	g_cvarMaxBlend = register_cvar("bf_maxblend", "255")
	g_cvarMinBlend = register_cvar("bf_minblend", "128")
	g_cvarHitPlace = register_cvar("bf_hitplace", "b")
	g_cvarFxFactor = register_cvar("bf_fxfactor", "4.0")
	//g_cvarNotify = register_cvar("bc_notify", "vc")
	
	register_event("Flashlight", "event_flashlight", "be")  // alive
	register_event("Health", "event_notalive", "bd", "1=0") // dead
	if(g_bUnderCS)
		register_event("HLTV", "event_new_round", "a", "1=0", "2=0")
	
	register_forward(FM_PlayerPreThink, "forward_player_prethink")  
	
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
	g_flashlight[playerID] = true;
	
}
return PLUGIN_HANDLED;
}

remove_item(playerID)
{
// If the user is glowed, remove glow and clear bit
if (get_bit(g_hasItem, playerID)) {
clear_bit(g_hasItem, playerID);
g_flashlight[playerID] = false;
g_flash_until[playerID] = 0.0;
}
}

public client_disconnect(playerID)
{

remove_item(playerID);
g_flashlight[playerID] = false
g_flash_until[playerID] = 0.0

}

public client_putinserver(playerID)
{

remove_item(playerID)

}

public plugin_cfg()
{
	g_pcvar_ff = get_cvar_pointer("mp_friendlyfire")
	storeCVars()
}
//-----------------------------------------------------------------------------
public event_flashlight(id)
{
	g_flashlight[id] = bool:read_data(1)
	storeCVars()
}
//-----------------------------------------------------------------------------
public event_notalive(id) {
	g_flashlight[id] = false
	g_flash_until[id] = 0.0
}
//-----------------------------------------------------------------------------
public event_new_round() {
	arrayset(_:g_flashlight, 0, sizeof(g_flashlight))
	arrayset(_:g_flash_until, 0, sizeof(g_flash_until))
}
//-----------------------------------------------------------------------------
public forward_player_prethink(id) {
	if(!g_flashlight[id] || !get_bit(g_hasItem, id))
		return FMRES_IGNORED

	static phit, hitgroup, Float:dist
	dist = get_user_aiming(id, phit, hitgroup)

	if (!phit || !((1<<hitgroup) & g_iHitPlaceFlags) || !is_user_alive(phit))
		return FMRES_IGNORED

	if (!g_bFF && get_user_team(id) == get_user_team(phit))
		return FMRES_IGNORED

	flash_player(id, phit, dist)

	return FMRES_IGNORED
}
//-----------------------------------------------------------------------------
bool:flash_player(attacker, victim, Float:distance)
{
	if(distance >= g_iMaxDist)
		// holdtime will be <= 0
		return false
	if(attacker == victim)
		return false

	static Float:gametime; gametime= get_gametime()
	if(g_flash_until[victim] > gametime)
		// flash is still active
		return false
	
	static iAlpha
	static Float:holdtime, Float:duration

	getScreenFadeParams(distance, holdtime, duration, iAlpha)

	if(holdtime < 0.1) {
		// light is too tiny
		g_flash_until[victim] = gametime + 0.1
		return false
	}
	
	static Float:fOrigin[3]
	pev(attacker, pev_origin, fOrigin)
	if(!fm_is_in_viewcone(victim, fOrigin))
		// victim can't see the light
		return false
	
	static Float:holdtime_sec; holdtime_sec = holdtime / C_FLASHTIME

	g_flash_until[victim] = gametime + holdtime_sec
	//g_flash_until[victim] = gametime + holdtime_sec + EMP_IMPACTTIME_TO_SEC(duration)/2.0

	message_begin(MSG_ONE, g_msgid_screen_fade, _, victim)
	write_short(floatround(duration))
	write_short(floatround(holdtime))
	write_short(FLASH_FLAGS)
	write_byte(FLASH_RED)
	write_byte(FLASH_GREEN)
	write_byte(FLASH_BLUE)
	write_byte(iAlpha)
	message_end()

	// TODO: implement via cvar?
	static name[32]
	get_user_name(victim, name, sizeof(name)-1)
	client_print(victim, print_center, "You're blinded for %.1f sec!", holdtime_sec)
	client_print(attacker, print_center, "%s is blinded!", name)

	return true
}
//-----------------------------------------------------------------------------
stock bool:fm_is_in_viewcone(index, const Float:point[3])
{
	static Float:angles[3]
	//pev(index, pev_angles, angles)
	pev(index, pev_v_angle, angles)
	engfunc(EngFunc_MakeVectors, angles)
	global_get(glb_v_forward, angles)
	angles[2] = 0.0

	static Float:origin[3], Float:diff[3], Float:norm[3]
	pev(index, pev_origin, origin)
	xs_vec_sub(point, origin, diff)
	diff[2] = 0.0
	xs_vec_normalize(diff, norm)

	static Float:dot, Float:fov
	dot = xs_vec_dot(norm, angles)
	pev(index, pev_fov, fov)
	if (dot >= floatcos(fov * M_PI / 360.0))
		return true

	return false
}
//-----------------------------------------------------------------------------
stock getScreenFadeParams(const Float:distance, &Float:holdtime, &Float:duration, &alpha)
{
	if(distance <= g_iMinDist)
	{
		holdtime = g_fMaxImpcatTime
		alpha = g_iMaxBlend
	}
	else
	{
		static Float:fPercent; fPercent = (g_iMaxDist - distance) / g_iDeltaDist
		holdtime = fPercent * g_fMaxImpcatTime
		normFlashtimeVal(holdtime)
		
		if(holdtime)
		{
			alpha = floatround(g_iMinBlend + g_iDeltaBlend * fPercent)
			normBlendVal(alpha)
		}
		else
			alpha = 0
	}
	
	if(holdtime)
	{	
		duration = g_fFxFactor * holdtime
		normFlashtimeVal(duration)
	}
	else
		duration = 0.0
}
//-----------------------------------------------------------------------------
stock storeCVars()
{
	if(g_pcvar_ff)
		g_bFF = bool:get_pcvar_num(g_pcvar_ff)
	
	g_iHitPlaceFlags = getPCvarAsFlags(g_cvarHitPlace)
	g_iMinDist = get_pcvar_num(g_cvarMinDist)
	g_iMaxDist = get_pcvar_num(g_cvarMaxDist)
	if(g_iMaxDist < 0)
		g_iMaxDist = 0
	if(g_iMinDist > g_iMaxDist)
		g_iMinDist = g_iMaxDist
	
	g_iDeltaDist = g_iMaxDist - g_iMinDist

	g_fMaxImpcatTime = get_pcvar_float(g_cvarMaxImpactTime) * C_FLASHTIME
	normFlashtimeVal(g_fMaxImpcatTime)
	
	g_iMaxBlend = get_pcvar_num(g_cvarMaxBlend)
	normBlendVal(g_iMaxBlend)
	g_iMinBlend = get_pcvar_num(g_cvarMinBlend)
	if(g_iMinBlend > g_iMaxBlend)
		g_iMinBlend = g_iMaxBlend
	else	
	    normBlendVal(g_iMinBlend)
	
	g_iDeltaBlend = g_iMaxBlend - g_iMinBlend

	g_fFxFactor = get_pcvar_float(g_cvarFxFactor)
	if(g_fFxFactor < 0.0)
		g_fFxFactor = 0.0
}
//-----------------------------------------------------------------------------
stock normBlendVal(&val)
{
	if(val < 0)
		val = 0
	else if(val > 255)
		val = 255
}
//-----------------------------------------------------------------------------
stock normFlashtimeVal(&Float:val)
{
	if(val < 0.1)
		val = 0.0
	else if(val > 65535.0)
		val = 65535.0
}
//-----------------------------------------------------------------------------
stock getPCvarAsFlags(pcvar)
{
    static sValue[27]
    
    get_pcvar_string(pcvar, sValue, sizeof(sValue) - 1)
    
    return read_flags(sValue)
}
//-----------------------------------------------------------------------------

public client_impulse(id, impulse)
{
	if(impulse != 100)
		return PLUGIN_HANDLED_MAIN
	if(!g_flashlight[id] || !get_bit(g_hasItem, id))
	{
		//client_print(id, print_chat, "%L", id, "BUY_LIGHT")
		return PLUGIN_HANDLED_MAIN
	}
	return PLUGIN_CONTINUE
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
