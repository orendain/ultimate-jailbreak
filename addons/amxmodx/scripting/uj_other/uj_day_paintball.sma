#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <cstrike>
#include <amxmisc>
#include <fakemeta>
#include <fun>
#include <engine>
#include <xs>
#include <dhudmessage>
#include <uj_menus>
#include <uj_chargers>
#include <uj_core>
#include <uj_days>
#include <uj_effects>
#include <uj_colorchat>


#define get_bit(%1,%2)    (%1 & 1<<(%2&31))
#define set_bit(%1,%2)    %1 |= (1<<(%2&31))
#define clear_bit(%1,%2)  %1 &= ~(1<<(%2&31))

#define get_bit2(%1,%2)   (%1 & 0<<(%2&31))
#define set_bit2(%1,%2)   %1 |= (0<<(%2&31))
#define clear_bit2(%1,%2) %1 &= ~(0<<(%2&31))

#define IsWeaponInBits(%1,%2) (((1<<%1) & %2) > 0)
#define FIRST_PLAYER_ID	1
#define IsPlayer(%1) (FIRST_PLAYER_ID <= %1 <= g_iMaxPlayers)

#define MAX_PAINTBALLS	10
#define TASK_PB_RESET	1000
#define TASK_RELOAD	2000

#define print_chat_colored 5

const HAS_SHIELD = 1<<24;
#define HasShield(%0)    ( get_pdata_int(%0, m_iUserPrefs, XO_PLAYER) & HAS_SHIELD )
#define XO_PLAYER  5
#define m_pActiveItem    373
#define m_iUserPrefs     510

new const PLUGIN_NAME[] = "[UJ] Day - Paintball";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

new const DAY_NAME[] = "Paintball";
new const DAY_OBJECTIVE[] = "Paint and balls are a danger dangerous combo";
new const DAY_SOUND[] = "";



const WEAPONS_PISTOLS = (1<<CSW_P228)|(1<<CSW_ELITE)|(1<<CSW_FIVESEVEN)|(1<<CSW_USP)|(1<<CSW_GLOCK18)|(1<<CSW_DEAGLE);
const WEAPONS_SHOTGUNS = (1<<CSW_XM1014)|(1<<CSW_M3);
const WEAPONS_SUBMACHINEGUNS = (1<<CSW_MAC10)|(1<<CSW_UMP45)|(1<<CSW_MP5NAVY)|(1<<CSW_TMP)|(1<<CSW_P90);
const WEAPONS_RIFLES = (1<<CSW_SCOUT)|(1<<CSW_AUG)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<CSW_M4A1)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47);
const WEAPONS_MACHINEGUNS = (1<<CSW_M249);

const VALID_WEAPONS = WEAPONS_PISTOLS|WEAPONS_SHOTGUNS|WEAPONS_SUBMACHINEGUNS|WEAPONS_RIFLES|WEAPONS_MACHINEGUNS;


new g_iMsgSayText;      // SayText (ColorPrint)
//new g_iMaxPlayers;
new g_bIsConnected;   // Are we connected?
new g_bIsAlive;     // Are we alive?
new g_iGetUserWeapon;
new g_iWeaponBits[33];
new g_iWeaponClip[33][CSW_P90+1];
new g_iWeaponAmmo[33][CSW_P90+1];

//sprint

new Float: userSprintLast[33], Float: userSprintLastBat[33], Float: userSprintSound[33] 
new userSprintSpeed[33], userSprintTiredness[33], userSprintAdvised[33]
new userWeapon[33][32]
new pbmoves, verbose, use_batmeter, rechargetime, max_stamina

static const g_szWeaponNames[CSW_P90+1][] = {
	"","weapon_p228","","weapon_scout",
	"weapon_hegrenade","weapon_xm1014",
	"","weapon_mac10","weapon_aug",
	"weapon_smokegrenade","weapon_elite",
	"weapon_fiveseven","weapon_ump45",
	"weapon_sg550","weapon_galil",
	"weapon_famas","weapon_usp",
	"weapon_glock18","weapon_awp",
	"weapon_mp5navy","weapon_m249",
	"weapon_m3","weapon_m4a1","weapon_tmp",
	"weapon_g3sg1","weapon_flashbang","weapon_deagle",
	"weapon_sg552","weapon_ak47","","weapon_p90"
};


new g_paintballs[MAX_PAINTBALLS], g_pbstatus[MAX_PAINTBALLS], g_pbcount, Float:lastshot[33], Float:nextattack[33], freezetime;
new pbgun, color, shots, veloc, speed, blife, sound, bglow, damge, friendlyfire, tgun, ctgun, beamspr;//, paintball;

static const g_shot_anim[4] = {0, 3, 9, 5};
static const g_pbgun_models[11][] = {"models/v_pbgun.mdl", "models/v_pbgun1.mdl", "models/v_pbgun2.mdl", "models/v_pbgun3.mdl", "models/v_pbgun4.mdl", "models/v_pbgun5.mdl", "models/v_pbgun6.mdl", "models/v_pbgun7.mdl", "models/v_pbgun8.mdl", "models/v_pbgun9.mdl", "models/v_pbgun10.mdl"};


// Day variables
new g_day;
new bool:g_dayEnabled;

// Menu variables
new g_menuSpecial

// Cvars
//new g_primaryAmmoPCVar;
//new g_secondaryAmmoPCVar;

public plugin_init()
{
	register_plugin(PLUGIN_NAME, PLUGIN_VERS, PLUGIN_AUTH);
	

	register_forward(FM_CmdStart, "fw_cmdstart");	
	
	// Find all valid menus to display this under
	g_menuSpecial = uj_menus_get_menu_id("Special Days");
	RegisterHam(Ham_AddPlayerItem, "player", "Player_AddPlayerItem", 0);
	register_clcmd("say /ent", "ent_info", ADMIN_SLAY);
	//register_clcmd( "say /paintball", "toggle_paintball" );
	pbgun = register_cvar("amx_pbgun", "1");
	//pbusp = register_cvar("amx_pbusp", "1");
	//pbglock = register_cvar("amx_pbglock", "1");
	register_message(g_iMsgSayText, "MsgSayText");
	g_iMsgSayText   = get_user_msgid("SayText");
	//g_iMaxPlayers   = get_maxplayers();
	
	
	if (get_pcvar_num(pbgun))// || get_pcvar_num(pbusp) || get_pcvar_num(pbglock))
	{
		register_event("CurWeapon", "ev_curweapon", "be");
		register_logevent("ev_roundstart", 2, "0=World triggered", "1=Round_Start");
		if (get_cvar_num("mp_freezetime") > 0)
			register_event("HLTV", "ev_freezetime", "a", "1=0", "2=0");
		
		register_forward(FM_Touch, "fw_touch");
		register_forward(FM_SetModel, "fw_setmodel");
		register_forward(FM_PlayerPreThink, "fw_playerprethink", 1);
		register_forward(FM_UpdateClientData, "fw_updateclientdata", 1);
		
		color = register_cvar("pbgun_color", "2");
		shots = register_cvar("pbgun_shots", "10");
		veloc = register_cvar("pbgun_velocity", "2000");
		speed = register_cvar("pbgun_speed", "0.08");
		blife = register_cvar("pbgun_life", "5");
		sound = register_cvar("pbgun_sound", "1");
		bglow = register_cvar("pbgun_glow", "a");
		damge = register_cvar("pbgun_damage", "99");
		friendlyfire = get_cvar_pointer("mp_friendlyfire");
		
		new a, max_ents_allow = global_get(glb_maxEntities) - 5;
		for (a = 1; a <= get_pcvar_num(shots); a++)
			if (a < MAX_PAINTBALLS)
			if (engfunc(EngFunc_NumberOfEntities) < max_ents_allow)
		{
			g_paintballs[a] = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"));
			if (pev_valid(g_paintballs[a]))
			{
				set_pev(g_paintballs[a], pev_effects, pev(g_paintballs[a], pev_effects) | EF_NODRAW);
				g_pbcount++;
			}
		}
		if (g_pbcount < 1)
			set_fail_state("[AG] Failed to load Paintball Gun (unable to create ents)");
		
		server_print("*** %s by %s Enabled ***", PLUGIN_NAME, PLUGIN_AUTH);
	}	
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
	//new primaryAmmoCount = get_pcvar_num(g_primaryAmmoPCVar);
	
	new players[32], playerID;
	new playerCount = uj_core_get_players(players, true, CS_TEAM_T);
	for (new i = 0; i < playerCount; ++i) {
		playerID = players[i];
		
		// Give user items
		uj_core_strip_weapons(playerID);
	}
	
	//new health = get_pcvar_num(g_healthPCVar);
	
	playerCount = uj_core_get_players(players, true, CS_TEAM_CT);
	for (new i = 0; i < playerCount; ++i) {
		playerID = players[i];
		
		// Set user up with noclip
		uj_core_strip_weapons(playerID);
		//set_user_noclip(playerID, 1);
		//set_user_health(playerID, health);
	}
	
	static iPlayers[32], iNum, i, iPlayer;
	get_players( iPlayers, iNum, "a" );
	
	for ( i=0; i<iNum; i++ ) 
	{
		iPlayer = iPlayers[i];
		SaveWeapons(iPlayer);
		GiveItem2( iPlayer, CSW_MP5NAVY, 10);
		//GiveItem2( iPlayer, CSW_USP, 200);
		//GiveItem2( iPlayer, CSW_KNIFE);
		give_item(iPlayer, "weapon_knife");
	}	
	
	set_pcvar_num(verbose, 1);
	set_pcvar_num(pbmoves, 1);	
	uj_core_block_weapon_pickup(0, true);
	uj_chargers_block_heal(0, true);
	uj_chargers_block_armor(0, true);
}
}

end_day()
{
new players[32], playerID;
new playerCount = uj_core_get_players(players, true, CS_TEAM_T);
for (new i = 0; i < playerCount; ++i) {
playerID = players[i];
uj_core_strip_weapons(playerID);
}

playerCount = uj_core_get_players(players, true, CS_TEAM_CT);
for (new i = 0; i < playerCount; ++i) {
playerID = players[i];
set_user_noclip(playerID, 0);
give_item(playerID, "weapon_deagle");
cs_set_user_bpammo(playerID, CSW_DEAGLE, 300);
give_item(playerID, "weapon_m4a1");
cs_set_user_bpammo(playerID, CSW_M4A1, 300);
give_item(playerID, "weapon_knife");
}

static iPlayers[32], iNum, i, iPlayer;
get_players( iPlayers, iNum, "a" );

for ( i=0; i<iNum; i++ ) 
{

iPlayer = iPlayers[i];
SaveWeapons(iPlayer);
give_item(iPlayer, "weapon_knife");

}
set_pcvar_num(verbose, 0);
set_pcvar_num(pbmoves, 0);
uj_core_block_weapon_pickup(0, false);
uj_chargers_block_heal(0, false);
uj_chargers_block_armor(0, false);
g_dayEnabled = false;
}


public plugin_precache()
{

// Register day
g_day = uj_days_register(DAY_NAME, DAY_OBJECTIVE, DAY_SOUND)	
register_cvar("amx_pbgun", "1");
//register_cvar("amx_pbusp", "1");
//register_cvar("amx_pbglock", "1");
register_cvar("pbgun_tgun", "3");
register_cvar("pbgun_ctgun", "6");
pbmoves = register_cvar("pbmoves_enabled", "1");
verbose = register_cvar("pbmoves_verbose", "1");
use_batmeter = register_cvar("pbmoves_usebatterymeter", "1");
rechargetime = register_cvar("pbmoves_rechargetime", "10.0");
max_stamina = register_cvar("pbmoves_maxstamina", "700");
precache_sound("player/sprint.wav");
precache_sound("player/gasp1.wav");
tgun = get_cvar_num("pbgun_tgun");
ctgun = get_cvar_num("pbgun_ctgun");
if (get_cvar_num("amx_pbgun")) {
precache_model(g_pbgun_models[tgun]);
precache_model(g_pbgun_models[ctgun]);
precache_model((ctgun) ? "models/ultimate_jailbreak/p_pbgun1.mdl" : "models/ultimate_jailbreak/p_pbgun.mdl");
precache_model("models/ultimate_jailbreak/w_pbgun.mdl");
}
if (get_cvar_num("amx_pbusp")) {
precache_model("models/ultimate_jailbreak/v_pbusp.mdl");
precache_model("models/ultimate_jailbreak/p_pbusp.mdl");
}
if (get_cvar_num("amx_pbglock")) {
precache_model("models/ultimate_jailbreak/v_pbglock.mdl");
precache_model("models/ultimate_jailbreak/p_pbglock.mdl");
}
if (get_cvar_num("amx_pbgun") || get_cvar_num("amx_pbusp") || get_cvar_num("amx_pbglock")) {
precache_sound("misc/pb1.wav");
precache_sound("misc/pb2.wav");
precache_sound("misc/pb3.wav");
precache_sound("misc/pb4.wav");
precache_sound("misc/pbg.wav");
precache_model("models/ultimate_jailbreak/w_paintball.mdl");
precache_model("sprites/paintball.spr");
}
beamspr = precache_model("sprites/laserbeam.spr");
}

public fw_cmdstart( id, uc_handle, random_seed )
{
	if ( !is_user_alive( id ) || !get_pcvar_num(pbmoves))
	return FMRES_IGNORED
	
	static buttons; buttons = get_uc( uc_handle, UC_Buttons )

	new Float: gametime = get_gametime()
	
	if ((gametime - userSprintLast[id] > get_pcvar_float(rechargetime) || !userSprintLast[id]))
	{
		userSprintTiredness[id] = 0
		userSprintLast[id] = gametime
		set_hudmessage(255, 255, 255, -1.0, 0.33, 0, 1.0, 1.0);
		if (get_pcvar_num(verbose) && !userSprintAdvised[id])
		{
			userSprintAdvised[id] = true
			show_hudmessage(id, "Energy full. You can sprint with right-click...");
		}
		
		if (get_pcvar_num(use_batmeter))
		{
			userSprintLastBat[id] = gametime
			message_begin(MSG_ONE,get_user_msgid("FlashBat"),{0,0,0},id);
			write_byte(100);
			message_end();
		}
	}
	
	new currentweapon = get_user_weapon(id)
	
	if (buttons & IN_ATTACK2 && currentweapon != CSW_SCOUT)
	{
		set_uc (uc_handle, UC_Buttons, buttons & ~IN_ATTACK2);
	
		if (userSprintTiredness[id] >= get_pcvar_num(max_stamina))
		{
			userSprintAdvised[id] = false
			set_hudmessage(255, 255, 255, -1.0, 0.33, 0, 0.1, 0.1);
			if (get_pcvar_num(verbose))
				show_hudmessage(id, "Too tired to sprint. Please wait...");

			if (gametime - userSprintSound[id] > 1.0)
			{
				emit_sound(id, CHAN_AUTO, "player/gasp1.wav", 1.0, ATTN_NORM , 0, PITCH_NORM);
				userSprintSound[id] = gametime
			}
			
				
			return FMRES_IGNORED;		
		}
	
		userSprintTiredness[id] += 1				
		
		if (!(buttons & IN_DUCK))
		{	
			
			if (currentweapon != CSW_KNIFE){
				get_weaponname(currentweapon,userWeapon[id],30)
				engclient_cmd(id, "weapon_knife")
			}
			userSprintSpeed[id] += 2;

			if (userSprintSpeed[id] < 200)
				userSprintSpeed[id] = 200;

			if (userSprintSpeed[id] > 400)
				userSprintSpeed[id] = 400;

			userSprintLast[id] = gametime
			
			//Some of this was inspired in +Speed 1.17 by Melanie
			new Float:returnV[3], Float:Original[3]
			VelocityByAim ( id, userSprintSpeed[id], returnV )
	
			pev(id,pev_velocity,Original)
			
			//Avoid floating in the air and ultra high jumps
			if (vector_length(Original) < 600.0 || Original[2] < 0.0)
				returnV[2] = Original[2]
			
			set_pev(id,pev_velocity,returnV)
			set_hudmessage(255, 255, 255, -1.0, 0.33, 0, 0.1, 0.1);
			if (get_pcvar_num(verbose))
				show_hudmessage(id, "Sprinting...");
			
			if (userSprintLast[id] - userSprintSound[id] > 1.0)
			{
				emit_sound(id, CHAN_AUTO, "player/sprint.wav", 1.0, ATTN_NORM, 0, PITCH_NORM);
				userSprintSound[id] = userSprintLast[id]				
			}
		
			if (gametime - userSprintLastBat[id] > 0.2 && get_pcvar_num(use_batmeter))
			{
				userSprintLastBat[id] = gametime
				new percentage = 100 - (userSprintTiredness[id] * 100 / get_pcvar_num(max_stamina))
				message_begin(MSG_ONE,get_user_msgid("FlashBat"),{0,0,0},id);
				write_byte(percentage);
				message_end();
			}


		
			return FMRES_IGNORED;
		} else
		{			
			if (userSprintSpeed[id] > 2)
				userSprintSpeed[id] -= 2;
			else
				userSprintSpeed[id] = 0;
				
			userSprintLast[id] = gametime

			new Float:returnV[3], Float:Original[3]
			VelocityByAim ( id, userSprintSpeed[id], returnV )
	
			pev(id,pev_velocity,Original)
			
			//Avoid floating in the air and ultra high jumps
			if (vector_length(Original) < 600.0 || Original[2] < 0.0)
				returnV[2] = Original[2]
			
			set_pev(id,pev_velocity,returnV)
			set_hudmessage(255, 255, 255, -1.0, 0.33, 0, 0.1, 0.1);
			if (get_pcvar_num(verbose))
				show_hudmessage(id, "Sliding...");
			
			return FMRES_IGNORED;
		}

	}

	//restore weapon after sprinting
	if(userWeapon[id][0])
	{
		engclient_cmd(id, userWeapon[id])
		userWeapon[id][0] = 0
	}
	userSprintSpeed[id] = 0;
	
	return FMRES_IGNORED;
}


public ent_info(id)
client_print(id, print_chat, "[AG] [Ent Info (Current/Max)] Paintballs: (%d/%d)   Entities: (%d/%d)", g_pbcount, get_pcvar_num(shots), engfunc(EngFunc_NumberOfEntities), global_get(glb_maxEntities));

public ev_curweapon(id)
{

if(g_dayEnabled)
{
	new model[25];
	pev(id, pev_viewmodel2, model, 24);
	if (equali(model, "models/v_mp5.mdl") && get_pcvar_num(pbgun))
	{
		set_pev(id, pev_viewmodel2, (get_user_team(id) == 1) ? g_pbgun_models[tgun] : g_pbgun_models[ctgun]);
		set_pev(id, pev_weaponmodel2, (ctgun) ? "models/ultimate_jailbreak/p_pbgun1.mdl" : "models/ultimate_jailbreak/p_pbgun.mdl");
	}
	/*else if (equali(model, "models/v_usp.mdl") && get_pcvar_num(pbusp))
	{
		set_pev(id, pev_viewmodel2, "models/ultimate_jailbreak/v_pbusp.mdl");
		set_pev(id, pev_weaponmodel2, "models/ultimate_jailbreak/p_pbusp.mdl");
	}
	else if (equali(model, "models/v_glock18.mdl") && get_pcvar_num(pbglock))
	{
		set_pev(id, pev_viewmodel2, "models/ultimate_jailbreak/v_pbglock.mdl");
		set_pev(id, pev_weaponmodel2, "models/ultimate_jailbreak/p_pbglock.mdl");
	}*/
}
}

public fw_setmodel(ent, model[]) 
{
if (equali(model, "models/w_mp5.mdl") && g_dayEnabled) 
	if (get_pcvar_num(pbgun))
	{
		engfunc(EngFunc_SetModel, ent, "models/ultimate_jailbreak/w_pbgun.mdl");
		return FMRES_SUPERCEDE;
	}
return FMRES_IGNORED;
}

public fw_updateclientdata(id, sw, cd_handle)
{
	if (g_dayEnabled && user_has_pbgun(id) && cd_handle)
	{
		set_cd(cd_handle, CD_ID, 1);
		get_cd(cd_handle, CD_flNextAttack, nextattack[id]);
		//set_cd(cd_handle, CD_flNextAttack, 10.0);
		return FMRES_HANDLED;
	}
	return FMRES_IGNORED;
}

public fw_playerprethink(id)
{
	new my_pbgun = user_has_pbgun(id);
	if (my_pbgun)
	{
		new buttons = pev(id, pev_button);
		if (buttons & IN_ATTACK)
		{
			new ammo, null = get_user_weapon(id, ammo, null);
			if (ammo)
			{
				set_pev(id, pev_button, buttons & ~IN_ATTACK);
				new Float:gametime = get_gametime(), Float:g_speed;
				if (my_pbgun == 1)
					g_speed = get_pcvar_float(speed);
				else
					g_speed = (my_pbgun == 2) ? get_pcvar_float(speed) * 2.0 : get_pcvar_float(speed) * 3.0;
				if (gametime-lastshot[id] > g_speed  && nextattack[id] < 0.0 && !freezetime)
				{
					if (paint_fire(id))
					{
						lastshot[id] = gametime;
						set_user_clip(id, ammo - 1);
						set_pev(id, pev_punchangle, Float:{-0.5, 0.0, 0.0});
						message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, _, id);
						write_byte(g_shot_anim[my_pbgun]);
						write_byte(0);
						message_end();
						if (get_pcvar_num(sound))
							emit_sound(id, CHAN_AUTO, "misc/pbg.wav", 1.0, ATTN_NORM, 0, PITCH_NORM);
					}
				}
			}
		}
	}
	return FMRES_IGNORED;
}

public paint_fire(id)
{
	new a, ent;
	while (a++ < g_pbcount - 1 && !ent)
		if (g_pbstatus[a] == 0)
		ent = g_pbstatus[a] = g_paintballs[a];
	if (!ent)
		while (a-- > 1 && !ent)
		if (g_pbstatus[a] == 2)
		ent = g_pbstatus[a] = g_paintballs[a];
	
	if (pev_valid(ent) && is_user_alive(id))
	{
		new Float:vangles[3], Float:nvelocity[3], Float:voriginf[3], vorigin[3], clr;
		set_pev(ent, pev_classname, "pbBullet");
		set_pev(ent, pev_owner, id);
		engfunc(EngFunc_SetModel, ent, "models/ultimate_jailbreak/w_paintball.mdl");
		engfunc(EngFunc_SetSize, ent, Float:{-1.0, -1.0, -1.0}, Float:{1.0, 1.0, 1.0});
		
		switch (get_pcvar_num(color))
		{
			case 2: clr = (get_user_team(id) == 1) ? 0 : 1;
				case 3: clr = (get_user_team(id) == 1) ? 4 : 3;
				case 4: clr = (get_user_team(id) == 1) ? 2 : 5;
				default: clr = random_num(0, 6);
		}
		set_pev(ent, pev_skin, clr);
		
		get_user_origin(id, vorigin, 1);
		IVecFVec(vorigin, voriginf);
		engfunc(EngFunc_SetOrigin, ent, voriginf);
		
		vangles[0] = random_float(-180.0, 180.0);
		vangles[1] = random_float(-180.0, 180.0);
		set_pev(ent, pev_angles, vangles);
		
		pev(id, pev_v_angle, vangles);
		set_pev(ent, pev_v_angle, vangles);
		pev(id, pev_view_ofs, vangles);
		set_pev(ent, pev_view_ofs, vangles);
		
		set_pev(ent, pev_solid, 2);
		set_pev(ent, pev_movetype, 5);
		
		velocity_by_aim(id, get_pcvar_num(veloc), nvelocity);
		set_pev(ent, pev_velocity, nvelocity);
		set_pev(ent, pev_effects, pev(ent, pev_effects) & ~EF_NODRAW);
		
		set_task(0.1, "paint_glow", ent);
		set_task(15.0 , "paint_reset", ent+TASK_PB_RESET);
	}
	
	return ent;
}

public fw_touch(bullet, ent)
{
	new class[20];
	pev(bullet, pev_classname, class, 19);
	if (!equali(class, "pbBullet"))
		return FMRES_IGNORED;
	
	new Float:origin[3], class2[20], owner = pev(bullet, pev_owner), is_ent_alive = is_user_alive(ent);
	pev(ent, pev_classname, class2, 19);
	pev(bullet, pev_origin, origin);
	
	if (is_ent_alive)
	{
		if (owner == ent || pev(ent, pev_takedamage) == DAMAGE_NO)
			return FMRES_IGNORED;
		if (get_user_team(owner) == get_user_team(ent))
			if (!get_pcvar_num(friendlyfire))
			return FMRES_IGNORED;
		
		ExecuteHam(Ham_TakeDamage, ent, owner, owner, float(get_pcvar_num(damge) + 99), 4098); //4098 8196
		CheckTerrorist( );
	}
	
	if (!equali(class, class2))
	{	
		set_pev(bullet, pev_velocity, Float:{0.0, 0.0, 0.0});
		set_pev(bullet, pev_classname, "pbPaint");
		set_pev(bullet, pev_solid, 0);
		set_pev(bullet, pev_movetype, 0);
		engfunc(EngFunc_SetModel, bullet, "sprites/paintball.spr");
		
		new a, findpb = 0;
		while (a++ < g_pbcount && !findpb)
			if (g_paintballs[a] == bullet)
			findpb = g_pbstatus[a] = 2;
		
		remove_task(bullet);
		remove_task(bullet+TASK_PB_RESET);
		
		if (get_pcvar_num(sound))
		{
			static wav[20];
			formatex(wav, 20, is_ent_alive ? "player/pl_pain%d.wav" : "misc/pb%d.wav", is_ent_alive ? random_num(4,7) : random_num(1,4));
			emit_sound(bullet, CHAN_AUTO, wav, 1.0, ATTN_NORM, 0, PITCH_NORM);
		}
		
		new bool:valid_surface = (is_ent_alive || containi(class2, "door") != -1) ? false : true;
		if (pev(ent, pev_health) && !is_ent_alive)
		{
			ExecuteHam(Ham_TakeDamage, ent, owner, owner, float(pev(ent, pev_health)), 0);
			valid_surface = false;
		}
		if (valid_surface)
		{
			paint_splat(bullet);
			set_task(float(get_pcvar_num(blife)), "paint_reset", bullet+TASK_PB_RESET);
		}
		else
			paint_reset(bullet+TASK_PB_RESET);
		
		return FMRES_HANDLED; 
	}
	
	return FMRES_IGNORED;
}

public paint_splat(ent)
{
	new Float:origin[3], Float:norigin[3], Float:viewofs[3], Float:angles[3], Float:normal[3], Float:aiming[3];
	pev(ent, pev_origin, origin);
	pev(ent, pev_view_ofs, viewofs);
	pev(ent, pev_v_angle, angles);
	
	norigin[0] = origin[0] + viewofs[0];
	norigin[1] = origin[1] + viewofs[1];
	norigin[2] = origin[2] + viewofs[2];
	aiming[0] = norigin[0] + floatcos(angles[1], degrees) * 1000.0;
	aiming[1] = norigin[1] + floatsin(angles[1], degrees) * 1000.0;
	aiming[2] = norigin[2] + floatsin(-angles[0], degrees) * 1000.0;
	
	engfunc(EngFunc_TraceLine, norigin, aiming, 0, ent, 0);
	get_tr2(0, TR_vecPlaneNormal, normal);
	
	vector_to_angle(normal, angles);
	angles[1] += 180.0;
	if (angles[1] >= 360.0) angles[1] -= 360.0;
	set_pev(ent, pev_angles, angles);
	set_pev(ent, pev_v_angle, angles);
	
	origin[0] += (normal[0] * random_float(0.3, 2.7));
	origin[1] += (normal[1] * random_float(0.3, 2.7));
	origin[2] += (normal[2] * random_float(0.3, 2.7));
	engfunc(EngFunc_SetOrigin, ent, origin);
	set_pev(ent, pev_frame, float(random_num( (pev(ent, pev_skin) * 18), (pev(ent, pev_skin) * 18) + 17 ) ));
	if (pev(ent, pev_renderfx) != kRenderFxNone)
		set_rendering(ent);
}

public paint_glow(ent)
{
	if (pev_valid(ent))
	{
		static pbglow[5], clr[3];
		get_pcvar_string(bglow, pbglow, 4);
		switch (get_pcvar_num(color))
		{
			case 2: clr = (get_user_team(pev(ent, pev_owner))==1) ? {255, 0, 0} : {0, 0, 255};
			default: clr = {255, 255, 255};
		}
		if (read_flags(pbglow) & (1 << 0))
			set_rendering(ent, kRenderFxGlowShell, clr[0], clr[1], clr[2], kRenderNormal, 255);
		if (read_flags(pbglow) & (1 << 1))
		{
			message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
			write_byte(TE_BEAMFOLLOW);
			write_short(ent);
			write_short(beamspr);
			write_byte(4);
			write_byte(2);
			write_byte(clr[0]);
			write_byte(clr[1]);
			write_byte(clr[2]);
			write_byte(255);
			message_end();
		}
	}
}

public paint_reset(ent)
{
	remove_task(ent);
	ent -= TASK_PB_RESET;
	new a, findpb = 1;
	while (a++ <= g_pbcount && findpb)
		if (g_paintballs[a] == ent)
		findpb = g_pbstatus[a] = 0;
	
	set_pev(ent, pev_effects, pev(ent, pev_effects) | EF_NODRAW);
	engfunc(EngFunc_SetSize, ent, Float:{0.0, 0.0, 0.0}, Float:{0.0, 0.0, 0.0});
	set_pev(ent, pev_velocity, Float:{0.0, 0.0, 0.0});
	engfunc(EngFunc_SetOrigin, ent, Float:{-2000.0, -2000.0, -2000.0});
	if (pev(ent, pev_renderfx) != kRenderFxNone)
		set_rendering(ent);
}

public ev_roundstart()
{
	for (new a = 1; a <= g_pbcount; a++)
		if (g_pbstatus[a] != 0)
		paint_reset(g_paintballs[a]+TASK_PB_RESET);
	if (freezetime)
		freezetime = 0;
	
	g_dayEnabled = false;
	set_pcvar_num(verbose, 0);
	set_pcvar_num(pbmoves, 0);
	
	static iPlayers[32], iNum, i, iPlayer;
	get_players( iPlayers, iNum, "a" );
	
	for ( i=0; i<iNum; i++ ) 
	{
		
		iPlayer = iPlayers[i];
		give_item(iPlayer, "weapon_knife");
		
	}
	
}

public ev_freezetime()
	freezetime = 1;

stock user_has_pbgun(id)
{
	if (is_user_alive(id))
	{
		new model[25];
		pev(id, pev_viewmodel2, model, 24);
		if (containi(model, "models/v_pbgun") != -1)
			return 1;
		else if (equali(model, "models/ultimate_jailbreak/v_pbusp.mdl"))
			return 2;
		else if (equali(model, "models/ultimate_jailbreak/v_pbglock.mdl"))
			return 3;
	}
	return 0;
}

stock set_user_clip(id, ammo)
{
	new weaponname[32], weaponid = -1, weapon = get_user_weapon(id, _, _);
	get_weaponname(weapon, weaponname, 31);
	while ((weaponid = engfunc(EngFunc_FindEntityByString, weaponid, "classname", weaponname)) != 0)
		if (pev(weaponid, pev_owner) == id) {
		set_pdata_int(weaponid, 51, ammo, 4);
		return weaponid;
	}
	return 0;
}

public SaveWeapons(iPlayer)
{
	if( !get_bit(g_bIsConnected, iPlayer) && !get_bit(g_bIsAlive, iPlayer) )
		return PLUGIN_HANDLED;
	
	new iWeaponBits = g_iWeaponBits[iPlayer] = entity_get_int(iPlayer, EV_INT_weapons) & VALID_WEAPONS;
	//(pev(id,pev_effects) & 8)
	
	for(new i;i<=CSW_P90;i++)
	{
		if(IsWeaponInBits(i, iWeaponBits))
		{
			g_iWeaponClip[iPlayer][i] = cs_get_weapon_ammo(find_ent_by_owner(-1, g_szWeaponNames[i], iPlayer));
			g_iWeaponAmmo[iPlayer][i] = cs_get_user_bpammo(iPlayer, i);
		}
	}
	StripPlayerWeapons(iPlayer);
	
	return PLUGIN_HANDLED;
}

/*
GiveItem(const id, const szItem[], const bpAmmo) {
	give_item(id, szItem);
	cs_set_user_bpammo(id, get_weaponid(szItem), bpAmmo);
}*/

new static bpAmmo_default[CSW_P90+1] = {
	0,
	52,
	0,
	90,
	1,
	32,
	1,
	100,
	90,
	1,
	120,
	100,
	100,
	90,
	90,
	90,
	100,
	120,
	30,
	120,
	200,
	32,
	90,
	120,
	90,
	2,
	35,
	90,
	90,
	0,
	100
};
stock GiveItem2(const id, const szItem, iAmmo = -1, bpAmmo = -1) {
	give_item(id, g_szWeaponNames[szItem]);
	
	if(iAmmo >= 0) {
		new wepID = find_ent_by_owner(-1, g_szWeaponNames[szItem], id);
		if(wepID)
		{
			cs_set_weapon_ammo(wepID, iAmmo);
		}
	}
	
	if(bpAmmo >= 0) 
		cs_set_user_bpammo(id, szItem, bpAmmo);
	else cs_set_user_bpammo(id, szItem, bpAmmo_default[szItem]);
	
}

public client_putinserver(id) {
	
	if(bool:!is_user_hltv(id))
		set_bit(g_bIsConnected, id);
	clear_bit(g_bIsAlive, id);
	
}

CheckTerrorist( )
{
if( fnGetTerrorists() == 1 )
{
	g_dayEnabled = false;
	set_pcvar_num(verbose, 0);
	set_pcvar_num(pbmoves, 0);
	static iPlayers[32], iNum, i, iPlayer;
	get_players( iPlayers, iNum, "a" );
	
	for ( i=0; i<iNum; i++ ) 
	{
		
		iPlayer = iPlayers[i];
		SaveWeapons(iPlayer);
		give_item(iPlayer, "weapon_knife");
		
	}
	
	new players[ 32 ], num, player;
	get_players( players, num, "ae", "CT" );
	
	for( new i = 0; i < num; i++ )
	{
		player = players[ i ];
		
		GiveItem2(player, CSW_M4A1);
		GiveItem2(player, CSW_DEAGLE);
	}	
	//fnColorPrint(0, "Paintball day has ended to due to last request"); 
}
}

fnGetTerrorists() {
// Get's the number of terrorists
static iPlayers[32], iNum;
get_players(iPlayers, iNum, "ae", "TERRORIST"); 
return iNum;
}

stock StripPlayerWeapons(id)
{
//strip_user_weapons(id); 
//give_item(id, "weapon_knife");
//new const DONT_STRIP = ( 1 << 2 ) | ( 1 << CSW_KNIFE );
cs_set_user_nvg( id, 1 );

for(new i=CSW_P228; i<=CSW_P90; i++)
{
	//if( DONT_STRIP & ( 1 << i ) )
	//continue;
if(g_iGetUserWeapon == get_user_weapon(id))
	continue;
ham_strip_user_weapon(id, i);
}
if(HasShield(id))
{
	strip_user_weapons(id); 
		
}
give_item(id, "weapon_knife");
//for(new i=CSW_P228; i<=CSW_P90; i++)
//ham_strip_user_weapon(id, i);
}

stock ham_strip_user_weapon(id, iCswId, iSlot = 0, bool:bSwitchIfActive = true) 
{ 
	new iWeapon;
	if( !iSlot ) 
	{ 
		static const iWeaponsSlots[] = { 
			-1, 
			2, //CSW_P228 
			-1, 
			1, //CSW_SCOUT 
			4, //CSW_HEGRENADE 
			1, //CSW_XM1014 
			5, //CSW_C4 
			1, //CSW_MAC10 
			1, //CSW_AUG 
			4, //CSW_SMOKEGRENADE 
			2, //CSW_ELITE 
			2, //CSW_FIVESEVEN 
			1, //CSW_UMP45 
			1, //CSW_SG550 
			1, //CSW_GALIL 
			1, //CSW_FAMAS 
			2, //CSW_USP 
			2, //CSW_GLOCK18 
			1, //CSW_AWP 
			1, //CSW_MP5NAVY 
			1, //CSW_M249 
			1, //CSW_M3 
			1, //CSW_M4A1 
			1, //CSW_TMP 
			1, //CSW_G3SG1 
			4, //CSW_FLASHBANG 
			2, //CSW_DEAGLE 
			1, //CSW_SG552 
			1, //CSW_AK47 
			3, //CSW_KNIFE 
			1 //CSW_P90 
		};
		iSlot = iWeaponsSlots[iCswId];
	} 
	
	const m_rgpPlayerItems_Slot0 = 367;
	
	iWeapon = get_pdata_cbase(id, m_rgpPlayerItems_Slot0 + iSlot, XO_PLAYER); 
	
	const XTRA_OFS_WEAPON = 4; 
	const m_pNext = 42; 
	const m_iId = 43; 
	
	while( iWeapon > 0 ) 
	{ 
		if( get_pdata_int(iWeapon, m_iId, XTRA_OFS_WEAPON) == iCswId ) 
		{ 
			break; 
		} 
		iWeapon = get_pdata_cbase(iWeapon, m_pNext, XTRA_OFS_WEAPON); 
	} 
	
	if( iWeapon > 0 ) 
	{ 
		if( bSwitchIfActive && get_pdata_cbase(id, m_pActiveItem, XO_PLAYER) == iWeapon ) 
		{ 
			ExecuteHamB(Ham_Weapon_RetireWeapon, iWeapon); 
		} 
		
		if( ExecuteHamB(Ham_RemovePlayerItem, id, iWeapon) ) 
		{ 
			user_has_weapon(id, iCswId, 0); 
			ExecuteHamB(Ham_Item_Kill, iWeapon); 
			return 1; 
		} 
	} 
	
	return 0;
}

public Player_AddPlayerItem(const id, const iEntity)  //anti gun glitch
{
	new iWeapID = cs_get_weapon_id( iEntity );
	
	if( !iWeapID )
		return HAM_IGNORED;
	
	if(g_dayEnabled)	
		if(iWeapID != CSW_KNIFE && iWeapID != CSW_MP5NAVY)
	{
		SetHamReturnInteger( 1 );
		return HAM_SUPERCEDE;
	}
	
	return HAM_IGNORED;
}