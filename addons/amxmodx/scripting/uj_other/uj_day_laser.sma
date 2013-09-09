
//Comment this line out for mods other than cstrike
#define CSTRIKE

//Laser damage is determined here.
#define h1_dam 100  // head
#define h2_dam 56   // chest
#define h3_dam 46   // stomach
#define h4_dam 24   // arms
#define h6_dam 31   // legs
#define tkh1_dam 50 // head - half mirror damage for team friendlyfire punsishments
#define tkh2_dam 28 // chest - half mirror damage for team friendlyfire punsishments
#define tkh3_dam 23 // stomach - half mirror damage for team friendlyfire punsishments
#define tkh4_dam 12 // arms - half mirror damage for team friendlyfire punsishments
#define tkh6_dam 15 // legs - half mirror damage for team friendlyfire punsishments

//Language strings, these can be translated
//Special messages for this plugin, most should be tagged with [AMXX]
new stats_cs_only[] = "[AG] Laser Stats are only for Counter-Strike at this point"
new overheat_death[] = "[AG] You died because your Laser Gun overheated and exploded"
new overheat_warn[] = "WARNING: Laser Overheating!"  //Prints in center of screen, no [AMXX] needed
new laser_dead[] = "[AG] No more power, your laser is dead"
new laser_low[] = "[AG] Warning: laser power level low, 10 shots left"
new laser_kill1[] = "[AG] You just got fried by %s's frickin Laser Gun." //%s = killers name
new laser_kill2[] = "[AG] You just killed %s with a frickin Laser Gun." //%s = victims name
new laser_on[] = "[AG] Laser Guns have been enabled by an admin - say /laser for help"
new laser_ona[] = "[AG] Laser Guns Enabled" //Message displayed to admin in console
new laser_off[] = "[AG] Laser Guns have been diabled by an admin"
new laser_offa[] = "[AG] Laser Guns Disabled" //Message displayed to admin in console
new laserbuy_cs[] = "[AG] Laser buying is only for Counter-Strike"
new laserbuy_on[] = "[AG] Admin has enabled laser buying, each shot costs money"
new laserbuy_ona[] = "[AG] Laser Buying Enabled"
new laserbuy_off[] = "[AG] Admin has disabed laser buying, laser shots are free"
new laserbuy_offa[] = "[AG] Laser Buying Disabled"
new laser_on2[] = "[AG] Lasers are ON - For help say /laser" //Printed when somoen says "laser" and stats are off
new laser_on3[] = "[AG] Lasers are ON - For help say /laser - Stats say /laserstats" //Used when stats are on
new laser_off2[] =  "[AG] Lasers are OFF"
new no_stats[] = "[AG] Laser Stats are diasbled"

new Float: g_flLastLaserAttack[33];

//Standardized CS/HL Messages, should not have tags on them
new ta_warn[] = "%s attacked a teammate" //%s = attackers name
new tk_warn[] = "You killed a teammate"

//CS/CZ Only Messages
#if defined CSTRIKE
new nomoney_center[] = "You have insufficient funds!"
new err_money[] = "[AG] Laser shots cost $%d each" // %d = money cost
#endif

#include <amxmodx>
#include <amxmisc>
#include <hamsandwich>
#include <fun>
#include <engine>
#if defined CSTRIKE
#include <cstrike>
#endif
#include <uj_menus>
#include <uj_chargers>
#include <uj_core>
#include <uj_days>
#include <uj_effects>
#include <uj_colorchat>

#define FIRST_PLAYER_ID 1
#define IsPlayer(%1) (FIRST_PLAYER_ID <= %1 <= g_iMaxPlayers)

new const PLUGIN_NAME[] = "[UJ] Day - Laser Gun Day ";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

new const DAY_NAME[] = "Laser Gun Day";
new const DAY_OBJECTIVE[] = "Pew, pew, pew!";
new const DAY_SOUND[] = "";

//new const SPARTA_PRIMARY_AMMO[] = "200";
//new const SPARTA_SECONDARY_AMMO[] = "50";

//new g_iMaxPlayers;
new white
new fire
new smoke
new laser
new l_warning[33][2]
new tdead[33]
new DoOnce = 0
new DoneInit = 0
new writeonce = 0
new laser_heat[33]
new Float:last_laser_time[33]
new Float:SwitchControl[33]
new laser_shots[33]
new laser_stats[450][56]  // 0=kills 1=deaths 2=damage 3=overheat / 4=authid / 24=name
new laser_statst[450][58] // 0=kills 1=deaths 2=damage 3=overheat / 4=authid / 24=name / 56=mapch-connect / 57=lowstat
new laser_statst_c[33][4]
new laser_stats_r1[33][56]
new laser_stats_r2[33][4]
new mlaser_stats[33][56]
new sl_detail[33][8] // 0=shots 1=head 2=chest 3=stomach 4=leftarm 5=rightarm 6=leftleg 7=rightleg
new tauthid[35],tname[32]
new tempstats[4]
new l_rank[33],l_t_ranks
new bool:force_stats = false
new bool:csmod_running
new bool:stats_logging
new bool:roundfreeze
new tkcount[33]
new customdir[64]
new statsfile[128]
new gmsgDeathMsg
new gmsgScoreInfo

#define MAX_CLR 8
new ncolors[MAX_CLR][] = {"!","white","red","green","blue","yellow","magenta","cyan"}
new vcolors[MAX_CLR][3] = {{255,255,255},{255,255,255},{255,0,0},{0,255,0},{0,0,255},{255,255,0},{255,0,255},{0,255,255}}
new adcolors[33][4]
new adscolors[64][43]

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
	white = precache_model("sprites/white.spr")
	fire = precache_model("sprites/fexplo.spr")
	smoke = precache_model("sprites/steam1.spr")
	laser = precache_model("sprites/laserbeam.spr")
	precache_sound("weapons/electro5.wav")
	precache_sound("weapons/xbow_hitbod2.wav")
	return PLUGIN_CONTINUE	
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
				if(iWeapID != CSW_KNIFE)
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

explode(vec1[3]){
	// blast circles
	message_begin( MSG_BROADCAST,SVC_TEMPENTITY,vec1)
	write_byte( 21 )
	write_coord(vec1[0])
	write_coord(vec1[1])
	write_coord(vec1[2] + 16)
	write_coord(vec1[0])
	write_coord(vec1[1])
	write_coord(vec1[2] + 1936)
	write_short( white )
	write_byte( 0 ) // startframe
	write_byte( 0 ) // framerate
	write_byte( 3 ) // life 2
	write_byte( 20 ) // width 16
	write_byte( 0 ) // noise
	write_byte( 188 ) // r
	write_byte( 220 ) // g
	write_byte( 255 ) // b
	write_byte( 255 ) //brightness
	write_byte( 0 ) // speed
	message_end()
	//Explosion2
	message_begin( MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte( 12 )
	write_coord(vec1[0])
	write_coord(vec1[1])
	write_coord(vec1[2])
	write_byte( 188 ) // byte (scale in 0.1's) 188
	write_byte( 10 ) // byte (framerate)
	message_end()
	//TE_Explosion
	message_begin( MSG_BROADCAST,SVC_TEMPENTITY,vec1)
	write_byte( 3 )
	write_coord(vec1[0])
	write_coord(vec1[1])
	write_coord(vec1[2]+20)
	write_short( fire )
	write_byte( 40 ) // byte (scale in 0.1's) 188
	write_byte( 10 ) // byte (framerate)
	write_byte( 0 ) // byte flags
	message_end()
}

public laser_sw_con(vIndex){
	new aIndex = get_user_attacker(vIndex)
	SwitchControl[aIndex] = get_gametime()
	return PLUGIN_CONTINUE
}

//This block is used by BOTS only
public bot_interface(){
	new sid[8],id
	read_argv(1,sid,7)
	id = str_to_num(sid)

	if(!get_cvar_num("amx_luds_lasers") || roundfreeze || !is_user_alive(id))
		return PLUGIN_HANDLED

	if(SwitchControl[id] > get_gametime() - 0.75){
		engclient_cmd(id,"weapon_knife")
		return PLUGIN_HANDLED
	}
	if(get_cvar_num("amx_laser_buy") == 1){
#if defined CSTRIKE
		new umoney = cs_get_user_money(id)
		new l_cost = get_cvar_num("amx_laser_cost")
		if(umoney < l_cost)
			return PLUGIN_HANDLED
		else
			cs_set_user_money(id,umoney-l_cost,1)
#endif
	}
	else {
		if(laser_shots[id] < 1)
			return PLUGIN_HANDLED
		laser_shots[id] -= 1
	}
	engclient_cmd(id,"weapon_knife")
	new tid,tbody,a
	new decal_id
	new aimvec[3]
	new namea[32],namev[32],authida[35],authidv[35],teama[16],teamv[16]
	get_user_name(id,namea,31)
	new iteama = get_user_team(id,teama,15)
	get_user_authid(id,authida,34)
	new Float:curtime = get_gametime()
	if(last_laser_time[id] < curtime - 4.0)
		laser_heat[id] = 0
	else if(last_laser_time[id] < curtime - 2.5)
		laser_heat[id] -=3
	else if(last_laser_time[id] < curtime - 2.0)
		laser_heat[id] -=2
	else if(last_laser_time[id] < curtime - 1.5)
		laser_heat[id] -=1
	else if(last_laser_time[id] > curtime - 0.1)
		laser_heat[id] +=7
	else if(last_laser_time[id] > curtime - 0.3)
		laser_heat[id] +=3
	else if(last_laser_time[id] > curtime - 0.8)
		laser_heat[id] +=2
	else if(last_laser_time[id] > curtime - 1.5)
		laser_heat[id] +=1
	if(laser_heat[id] < 0)
		laser_heat[id] = 0
	else if(laser_heat[id] > (get_cvar_num("amx_laser_maxtemp") - 500) / 147 ){
		new origin[3]
		get_user_origin(id,origin)
		explode(origin)
		set_msg_block(gmsgDeathMsg,BLOCK_ONCE)
		set_msg_block(gmsgScoreInfo,BLOCK_ONCE)
		user_kill(id,1)
		replace_dm(id,id,0)
		log_message("^"%s<%d><%s><%s>^" committed suicide with ^"lasergun^" (overheat)",
		namea,get_user_userid(id),authida,teama)
		laser_stats_r1[id][3] +=1
		laser_stats_r2[id][3] +=1
	}
	last_laser_time[id] = get_gametime()
	emit_sound(id,CHAN_ITEM, "weapons/electro5.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)

	new botaimcvar = get_cvar_num("amx_laser_botaimdiffuse")
	new botaimfactor = random_num(-botaimcvar,botaimcvar)
	get_user_origin(id,aimvec,3)
	aimvec[0] += botaimfactor
	aimvec[1] += botaimfactor
	aimvec[2] += botaimfactor
	get_user_aiming(id,tid,tbody,9999)
	if(tbody){
		if(botaimfactor < 0)
			botaimfactor = botaimfactor * -1
		tbody = tbody + (botaimfactor / 7)
	}

 	new iteamv = get_user_team(tid,teamv,15)
	get_user_name(tid,namev,31)
	get_user_authid(tid,authidv,34)
	new color[11]
	read_argv(2,color,10)
	if(equal(color[0],"!",1)){
		new sred[4],sgreen[4],sblue[4],ired,igreen,iblue
		if( (strlen(color) < 2) && (adcolors[id][3] == 1) ){
			vcolors[0][0] = adcolors[id][0]
			vcolors[0][1] = adcolors[id][1]
			vcolors[0][2] = adcolors[id][2]
		}else{
			copy(sred,3,color[1])
			copy(sgreen,3,color[4])
			copy(sblue,3,color[7])
			ired = str_to_num(sred)
			igreen = str_to_num(sgreen)
			iblue = str_to_num(sblue)
			if(ired < 0 || ired > 255)
				ired = 255
			if(igreen < 0 || igreen > 255)
				igreen = 255
			if(iblue < 0 || iblue > 255)
				iblue = 255
			if( (strlen(sred) == 0) || (strlen(sgreen) == 0) || (strlen(sblue) == 0) )
				ired = 255,igreen=255,iblue=255
			vcolors[0][0] = ired
			vcolors[0][1] = igreen
			vcolors[0][2] = iblue
			adcolors[id][0] = ired
			adcolors[id][1] = igreen
			adcolors[id][2] = iblue
			adcolors[id][3] = 1
		}
	}else{
		switch(iteama){
			case 1: a = 6
			case 2: a = 3
			case 3: a = 2
			case 4: a = 4
		}
		for(new i=1;i<MAX_CLR;++i){
			if (equal(color,ncolors[i])) {
				a = i
				break
			}
		}
	}
	if(!get_cvar_num("amx_laser_allowinvis")){
		if(vcolors[a][0] + vcolors[a][1] + vcolors[a][2] < 100)
			a = 5
	}

	static const burn_decal[5] = {199,200,201,202,203}
	decal_id = burn_decal[random_num(0,4)]

	//BEAMENTPOINT
	message_begin( MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte ( 1 )     //TE_BEAMENTPOINT 1
	write_short (id)     // ent
	write_coord(aimvec[0])
	write_coord(aimvec[1])
	write_coord(aimvec[2])
	write_short( laser )
	write_byte( 1 ) // framestart
	write_byte( 5 ) // framerate
	write_byte( 2 ) // life
	write_byte( 10 ) // width
	write_byte( 0 ) // noise
	write_byte( vcolors[a][0] ) // r, g, b
	write_byte( vcolors[a][1] ) // r, g, b
	write_byte( vcolors[a][2] ) // r, g, b
	write_byte( 200 ) // brightness
	write_byte( 200 ) // speed
	message_end()
	//Sparks
	message_begin( MSG_PVS, SVC_TEMPENTITY)
	write_byte( 9 )
	write_coord( aimvec[0] )
	write_coord( aimvec[1] )
	write_coord( aimvec[2] )
	message_end()
	//Smoke
	message_begin( MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte( 5 ) // 5
	write_coord(aimvec[0])
	write_coord(aimvec[1])
	write_coord(aimvec[2])
	write_short( smoke )
	write_byte( 22 )  // 10
	write_byte( 10 )  // 10
	message_end()
	if(get_cvar_num("amx_laser_burndecals") == 1){
		//TE_GUNSHOTDECAL
		message_begin( MSG_BROADCAST,SVC_TEMPENTITY)
		write_byte( 109 ) // decal and ricochet sound
		write_coord( aimvec[0] ) //pos
		write_coord( aimvec[1] )
		write_coord( aimvec[2] )
		write_short (0) // I have no idea what thats supposed to be
		write_byte (decal_id) //decal
	 	message_end()
	}
	sl_detail[id][0]++
	if((tid > 0) && (tid < 33)){
		if(cvar_exists("mp_friendlyfire")){
			if(!get_cvar_num("mp_friendlyfire") || !get_cvar_num("amx_laser_obeyffcvar")) {
				if(iteama != iteamv)
					do_laserdamage(id,tid,tbody,namea,namev,teama,teamv,authida,authidv,0)
			}
			else {
				if(iteama != iteamv)
					do_laserdamage(id,tid,tbody,namea,namev,teama,teamv,authida,authidv,0)
				else
					do_laserdamage(id,tid,tbody,namea,namev,teama,teamv,authida,authidv,1)
			}
		}
		else {
			do_laserdamage(id,tid,tbody,namea,namev,teama,teamv,authida,authidv,0)
		}
	}
	else {
		server_cmd("lasermissile_chk %d %d",tid,id)
	}
	return PLUGIN_HANDLED
}

//This block is for humans to fire the laser
public fire_laser(id){
	if(!g_dayEnabled || roundfreeze || !is_user_alive(id)) {
		return PLUGIN_HANDLED
	}

	if(SwitchControl[id] > get_gametime() - 0.75){
		engclient_cmd(id,"weapon_knife")
		return PLUGIN_HANDLED
	}

	if(get_cvar_num("amx_laser_buy") == 1){
#if defined CSTRIKE
		new umoney = cs_get_user_money(id)
		new l_cost = get_cvar_num("amx_laser_cost")
		if(umoney < l_cost){
			client_print(id,print_center,nomoney_center)
			client_print(id,print_chat,err_money,l_cost)
			return PLUGIN_HANDLED
		}else{
			cs_set_user_money(id,umoney-l_cost,1)
		}
#endif
	}
	else {

		if(laser_shots[id] <= 0){
			client_print(id,print_chat,laser_dead)
			return PLUGIN_HANDLED
		}
		else if(laser_shots[id] <= 10){
			if(l_warning[id][1] == 0){
				l_warning[id][1] = 1
				client_print(id,print_chat,laser_low)
				client_cmd(id,"spk ^"fvox/alert, power_level_is ten^"")
			}
		}
		laser_shots[id] -= 1
	}
	engclient_cmd(id,"weapon_knife")
	new tid,tbody,found,a
	new decal_id
	new color[10]
	new aimvec[3]
	new namea[32],namev[32],authida[35],authidv[35],teama[16],teamv[16]
	get_user_name(id,namea,31)
	new iteama = get_user_team(id,teama,15)
	get_user_authid(id,authida,34)
	new Float:curtime = get_gametime()
	if(last_laser_time[id] < curtime - 4.0)
		laser_heat[id] = 0
	else if(last_laser_time[id] < curtime - 2.5)
		laser_heat[id] -=3
	else if(last_laser_time[id] < curtime - 2.0)
		laser_heat[id] -=2
	else if(last_laser_time[id] < curtime - 1.5)
		laser_heat[id] -=1
	else if(last_laser_time[id] > curtime - 0.1)
		laser_heat[id] +=7
	else if(last_laser_time[id] > curtime - 0.3)
		laser_heat[id] +=3
	else if(last_laser_time[id] > curtime - 0.8)
		laser_heat[id] +=2
	else if(last_laser_time[id] > curtime - 1.5)
		laser_heat[id] +=1
	if(laser_heat[id] < 0)
		laser_heat[id] = 0

	else if(laser_heat[id] > (get_cvar_num("amx_laser_maxtemp") - 500) / 147 ){
		new origin[3]
		get_user_origin(id,origin)
		explode(origin)
		set_msg_block(gmsgDeathMsg,BLOCK_ONCE)
		set_msg_block(gmsgScoreInfo,BLOCK_ONCE)
		user_kill(id,1)
		replace_dm(id,id,0)
		client_print(id,print_chat,overheat_death)
		log_message("^"%s<%d><%s><%s>^" committed suicide with ^"lasergun^" (overheat)",
		namea,get_user_userid(id),authida,teama)
		laser_stats_r1[id][3] +=1
		laser_stats_r2[id][3] +=1
	}
	else if(laser_heat[id] < ((get_cvar_num("amx_laser_maxtemp") - 500) / 147)-5){
		new lmessage[100]
		if(get_cvar_num("amx_laser_buy") == 1) {
			format(lmessage, 99, "Laser Temperature: %d °F",(laser_heat[id] * 147)+ 500)
		}
		else {
			format(lmessage, 99, "Laser Power Level: %d  <+>  Temperature: %d °F",laser_shots[id],(laser_heat[id] * 147)+ 500)
		}
		//set_hudmessage(250,250,20, -1.0, 0.35, 0, 0.02, 3.0, 0.4, 0.3, 16)
		//show_hudmessage(id,lmessage)
		client_print(id,print_center,lmessage)
	}
	else {
		if(l_warning[id][0] == 0){
			l_warning[id][0] = 1
			client_cmd(id,"spk ^"fvox/warning heat_damage^"")
		}
		client_print(id,print_center,overheat_warn)
	}
	last_laser_time[id] = get_gametime()
	emit_sound(id,CHAN_ITEM, "weapons/electro5.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)

	get_user_origin(id,aimvec,3)
	get_user_aiming(id,tid,tbody,9999)

	new iteamv = get_user_team(tid,teamv,15)
	get_user_name(tid,namev,31)
	get_user_authid(tid,authidv,34)
	read_argv(1,color,10)
	if(equal(color[0],"!",1)){
		found = 1
		new sred[4],sgreen[4],sblue[4],ired,igreen,iblue
		if( (strlen(color) < 2) && (adcolors[id][3] == 1) ){
			vcolors[0][0] = adcolors[id][0]
			vcolors[0][1] = adcolors[id][1]
			vcolors[0][2] = adcolors[id][2]
		}
		else {
			copy(sred,3,color[1])
			copy(sgreen,3,color[4])
			copy(sblue,3,color[7])
			ired = str_to_num(sred)
			igreen = str_to_num(sgreen)
			iblue = str_to_num(sblue)
			if(ired < 0 || ired > 255)
				ired = 255
			if(igreen < 0 || igreen > 255)
				igreen = 255
			if(iblue < 0 || iblue > 255)
				iblue = 255
			if( (strlen(sred) == 0) || (strlen(sgreen) == 0) || (strlen(sblue) == 0) )
				ired = 255,igreen=255,iblue=255
			vcolors[0][0] = ired
			vcolors[0][1] = igreen
			vcolors[0][2] = iblue
			adcolors[id][0] = ired
			adcolors[id][1] = igreen
			adcolors[id][2] = iblue
			adcolors[id][3] = 1
		}
	}
	else {
		new i
		switch(iteama){
			case 1: a = 6
			case 2: a = 3
			case 3: a = 2
			case 4: a = 4
		}

		for(i = 1;i < MAX_CLR; i++){
			if (equal(color,ncolors[i])) {
				a = i
				found = 1
				break
			}
		}
		if((found != 1) && (id !=0)){
			get_user_authid(id,authida,34)
			for( i = 0; i < 64; i++ ){
				if(equal(authida,adscolors[i][3])) {
					vcolors[0][0] = adscolors[i][0]
					vcolors[0][1] = adscolors[i][1]
					vcolors[0][2] = adscolors[i][2]
					a = 0
					break
				}
			}
		}
	}
	if(!get_cvar_num("amx_laser_allowinvis")){
		if(vcolors[a][0] + vcolors[a][1] + vcolors[a][2] < 100)
			a = 5
	}

	static const burn_decal[5] = {199,200,201,202,203}
	decal_id = burn_decal[random_num(0,4)]

	//BEAMENTPOINT
	message_begin( MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte ( 1 )     //TE_BEAMENTPOINT 1
	write_short (id)     // ent
	write_coord(aimvec[0])
	write_coord(aimvec[1])
	write_coord(aimvec[2])
	write_short( laser )
	write_byte( 1 ) // framestart
	write_byte( 5 ) // framerate
	write_byte( 2 ) // life
	write_byte( 10 ) // width
	write_byte( 0 ) // noise
	write_byte( vcolors[a][0] ) // r, g, b
	write_byte( vcolors[a][1] ) // r, g, b
	write_byte( vcolors[a][2] ) // r, g, b
	write_byte( 200 ) // brightness
	write_byte( 200 ) // speed
	message_end()
	//Sparks
	message_begin( MSG_PVS, SVC_TEMPENTITY)
	write_byte( 9 )
	write_coord( aimvec[0] )
	write_coord( aimvec[1] )
	write_coord( aimvec[2] )
	message_end()
	//Smoke
	message_begin( MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte( 5 ) // 5
	write_coord(aimvec[0])
	write_coord(aimvec[1])
	write_coord(aimvec[2])
	write_short( smoke )
	write_byte( 22 )  // 10
	write_byte( 10 )  // 10
	message_end()
	if(get_cvar_num("amx_laser_burndecals") == 1){
		//TE_GUNSHOTDECAL
		message_begin( MSG_BROADCAST,SVC_TEMPENTITY)
		write_byte( 109 ) // decal and ricochet sound
		write_coord( aimvec[0] ) //pos
		write_coord( aimvec[1] )
		write_coord( aimvec[2] )
		write_short (0) // I have no idea what thats supposed to be
		write_byte (decal_id) //decal
	 	message_end()
	}
	sl_detail[id][0]++
	if((tid > 0) && (tid < 33)){
		if(cvar_exists("mp_friendlyfire")){
			if(!get_cvar_num("mp_friendlyfire") || !get_cvar_num("amx_laser_obeyffcvar")) {
				if(iteama != iteamv)
					do_laserdamage(id,tid,tbody,namea,namev,teama,teamv,authida,authidv,0)
			}
			else {
				if(iteama != iteamv)
					do_laserdamage(id,tid,tbody,namea,namev,teama,teamv,authida,authidv,0)
				else
					do_laserdamage(id,tid,tbody,namea,namev,teama,teamv,authida,authidv,1)
			}
		}
		else {
			do_laserdamage(id,tid,tbody,namea,namev,teama,teamv,authida,authidv,0)
		}
	}
	else {
		server_cmd("lasermissile_chk %d %d",tid,id)
	}
	return PLUGIN_HANDLED
}

do_laserdamage(id,tid,tbody,namea[],namev[],teama[],teamv[],authida[],authidv[],tker) {
	new healthv = get_user_health(tid)
	sl_detail[id][tbody]++
	if(tbody == 1){
		if(tker){
			if(healthv <= tkh1_dam){
				tdead[tid] = 1
			}
			else {
				set_user_health(tid,healthv - tkh1_dam)
				if(get_cvar_num("mp_logdetail") == 3){
					log_message("^"%s<%d><%s><%s>^" attacked ^"%s<%d><%s><%s>^" with ^"lasergun^" (hit ^"head^") (damage ^"%d^") (health ^"%d^")",
					namea,get_user_userid(id),authida,teama,namev,get_user_userid(tid),authidv,teamv,tkh1_dam,healthv-tkh1_dam)
				}
			}
		}
		else {
			laser_stats_r1[id][2] += h1_dam
			laser_stats_r2[id][2] += h1_dam
			if(healthv <= h1_dam){
				tdead[tid] = 1
			}
			else{
				set_user_health(tid,healthv - h1_dam)
				if(get_cvar_num("mp_logdetail") == 3){
					log_message("^"%s<%d><%s><%s>^" attacked ^"%s<%d><%s><%s>^" with ^"lasergun^" (hit ^"head^") (damage ^"%d^") (health ^"%d^")",
					namea,get_user_userid(id),authida,teama,namev,get_user_userid(tid),authidv,teamv,h1_dam,healthv-h1_dam)
				}
			}
		}
	}
	else if(tbody == 2){
		if(tker){
			if(healthv <= tkh2_dam){
				tdead[tid] = 1
			}
			else{
				set_user_health(tid,healthv-tkh2_dam)
				if(get_cvar_num("mp_logdetail") == 3){
					log_message("^"%s<%d><%s><%s>^" attacked ^"%s<%d><%s><%s>^" with ^"lasergun^" (hit ^"chest^") (damage ^"%d^") (health ^"%d^")",
					namea,get_user_userid(id),authida,teama,namev,get_user_userid(tid),authidv,teamv,tkh2_dam,healthv-tkh2_dam)
				}
			}
		}else{
			laser_stats_r1[id][2] += h2_dam
			laser_stats_r2[id][2] += h2_dam
			if(healthv <= h2_dam){
				tdead[tid] = 1
			}
			else{
				set_user_health(tid,healthv-h2_dam)
				if(get_cvar_num("mp_logdetail") == 3){
					log_message("^"%s<%d><%s><%s>^" attacked ^"%s<%d><%s><%s>^" with ^"lasergun^" (hit ^"chest^") (damage ^"%d^") (health ^"%d^")",
					namea,get_user_userid(id),authida,teama,namev,get_user_userid(tid),authidv,teamv,h2_dam,healthv-h2_dam)
				}
			}
		}
	}
	else if(tbody == 3){
		if(tker){
			if(healthv <= tkh3_dam){
				tdead[tid] = 1
			}
			else{
				set_user_health(tid,healthv-tkh3_dam)
				if(get_cvar_num("mp_logdetail") == 3){
					log_message("^"%s<%d><%s><%s>^" attacked ^"%s<%d><%s><%s>^" with ^"lasergun^" (hit ^"stomach^") (damage ^"%d^") (health ^"%d^")",
					namea,get_user_userid(id),authida,teama,namev,get_user_userid(tid),authidv,teamv,tkh3_dam,healthv-tkh3_dam)
				}
			}
		}else{
			laser_stats_r1[id][2] += h3_dam
			laser_stats_r2[id][2] += h3_dam
			if(healthv <= h3_dam){
				tdead[tid] = 1
			}
			else{
				set_user_health(tid,healthv-h3_dam)
				if(get_cvar_num("mp_logdetail") == 3){
					log_message("^"%s<%d><%s><%s>^" attacked ^"%s<%d><%s><%s>^" with ^"lasergun^" (hit ^"stomach^") (damage ^"%d^") (health ^"%d^")",
					namea,get_user_userid(id),authida,teama,namev,get_user_userid(tid),authidv,teamv,h3_dam,healthv-h3_dam)
				}
			}
		}
	}
	else if(tbody == 4 || tbody == 5){
		if(tker){
			if(healthv <= tkh4_dam){
				tdead[tid] = 1
			}
			else{
				set_user_health(tid,healthv-tkh4_dam)
				if(get_cvar_num("mp_logdetail") == 3){
					log_message("^"%s<%d><%s><%s>^" attacked ^"%s<%d><%s><%s>^" with ^"lasergun^" (hit ^"arms^") (damage ^"%d^") (health ^"%d^")",
					namea,get_user_userid(id),authida,teama,namev,get_user_userid(tid),authidv,teamv,tkh4_dam,healthv-tkh4_dam)
				}
			}
		}else{
			laser_stats_r1[id][2] += h4_dam
			laser_stats_r2[id][2] += h4_dam
			if(healthv <= h4_dam){
				tdead[tid] = 1
			}
			else{
				set_user_health(tid,healthv-h4_dam)
				if(get_cvar_num("mp_logdetail") == 3){
					log_message("^"%s<%d><%s><%s>^" attacked ^"%s<%d><%s><%s>^" with ^"lasergun^" (hit ^"arms^") (damage ^"%d^") (health ^"%d^")",
					namea,get_user_userid(id),authida,teama,namev,get_user_userid(tid),authidv,teamv,h4_dam,healthv-h4_dam)
				}
			}
		}
	}
	else if(tbody == 6 || tbody == 7){
		if(tker){
			if(healthv <= tkh6_dam){
				tdead[tid] = 1
			}
			else{
				set_user_health(tid,healthv-tkh6_dam)
				if(get_cvar_num("mp_logdetail") == 3){
					log_message("^"%s<%d><%s><%s>^" attacked ^"%s<%d><%s><%s>^" with ^"lasergun^" (hit ^"legs^") (damage ^"%d^") (health ^"%d^")",
					namea,get_user_userid(id),authida,teama,namev,get_user_userid(tid),authidv,teamv,tkh6_dam,healthv-tkh6_dam)
				}
			}
		}else{
			laser_stats_r1[id][2] += h6_dam
			laser_stats_r2[id][2] += h6_dam
			if(healthv <= h6_dam){
				tdead[tid] = 1
			}
			else {
				set_user_health(tid,healthv-h6_dam)
				if(get_cvar_num("mp_logdetail") == 3){
					log_message("^"%s<%d><%s><%s>^" attacked ^"%s<%d><%s><%s>^" with ^"lasergun^" (hit ^"legs^") (damage ^"%d^") (health ^"%d^")",
					namea,get_user_userid(id),authida,teama,namev,get_user_userid(tid),authidv,teamv,h6_dam,healthv-h6_dam)
				}
			}
		}
	}
	emit_sound(tid,CHAN_BODY, "weapons/xbow_hitbod2.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
	if(tdead[tid] == 1){

		new lasguyfrags = get_user_frags(id)
		if(tker){
			new punish2 = get_cvar_num("amx_laser_tkpunish2")
			new punish3 = get_cvar_num("amx_laser_tkpunish3")
			client_print(id,print_center,tk_warn)
			laser_stats_r1[id][0] -= 1
			laser_stats_r2[id][0] -= 1
			laser_stats_r1[tid][1] += 1
			laser_stats_r2[tid][1] += 1
			lasguyfrags -=1
			set_user_frags(id,lasguyfrags)
			tkcount[id] +=1
			if(tkcount[id] >= punish3){
				switch(punish2){
					case 1: client_cmd(id,"echo You were kicked for team killing;disconnect")
					case 2: {
						client_cmd(id,"echo You were banned for team killing")
						if (equal("4294967295",authida)){
							new ipa[32]
							get_user_ip(id,ipa,31,1)
							server_cmd("addip 180.0 %s;writeip",ipa)
						}else{
							server_cmd("banid 180.0 %s kick;writeid",authida)
						}
					}
				}
			}
		}
		else {
			laser_stats_r1[id][0] += 1
			laser_stats_r2[id][0] += 1
			laser_stats_r1[tid][1] += 1
			laser_stats_r2[tid][1] += 1
			lasguyfrags +=1
			set_user_frags(id,lasguyfrags)
		}

		//Kill the victim and block the messages
		set_msg_block(gmsgDeathMsg,BLOCK_ONCE)
		set_msg_block(gmsgScoreInfo,BLOCK_ONCE)
		user_kill(tid,1)

		//Replace the death message and update scoreboards
		replace_dm(id,tid,tbody)

		//Print message to clients
		client_print(tid,print_chat,laser_kill1,namea)
		client_print(id,print_chat,laser_kill2,namev)

		//Log the Kill
		log_message("^"%s<%d><%s><%s>^" killed ^"%s<%d><%s><%s>^" with ^"lasergun^"",
			namea,get_user_userid(id),authida,teama,namev,get_user_userid(tid),authidv,teamv)
	}
	if(tker){
		new punish1 = get_cvar_num("amx_laser_tkpunish1")
		new healtha = get_user_health(id)
		new players[32],pNum
		get_players(players,pNum,"e",teama)
		for(new i=0;i<pNum;i++)
			client_print(players[i],print_chat,ta_warn,namea)

		switch(punish1){
			case 1: {
				switch(tbody){
					case 1: set_user_health(id,healtha - tkh1_dam)
					case 2: set_user_health(id,healtha - tkh2_dam)
					case 3: set_user_health(id,healtha - tkh3_dam)
					case 4: set_user_health(id,healtha - tkh4_dam)
					case 5: set_user_health(id,healtha - tkh4_dam)
					case 6: set_user_health(id,healtha - tkh6_dam)
					case 7: set_user_health(id,healtha - tkh6_dam)
				}
			}
			case 2: {
				switch(tbody){
					case 1: set_user_health(id,healtha - h1_dam)
					case 2: set_user_health(id,healtha - h2_dam)
					case 3: set_user_health(id,healtha - h3_dam)
					case 4: set_user_health(id,healtha - h4_dam)
					case 5: set_user_health(id,healtha - h4_dam)
					case 6: set_user_health(id,healtha - h6_dam)
					case 7: set_user_health(id,healtha - h6_dam)
				}
			}
			case 3: user_kill(id,0)
		}
		if(!is_user_alive(id)){
			set_hudmessage(255,50,50, -1.0, 0.45, 0, 0.02, 10.0, 1.01, 1.1,16)
			show_hudmessage(id,"YOU WERE KILLED^nFOR ATTACKING TEAMMATES.^nSEE THAT IT HAPPENS NO MORE!")
		}
	}
}

public admin_lasers(id,level,cid){
	if (!cmd_access(id,level,cid,1))
		return PLUGIN_HANDLED

	new authid[35],name[32]
	get_user_authid(id,authid,34)
	get_user_name(id,name,31)

	if(get_cvar_num("amx_luds_lasers") == 0){
		set_cvar_num("amx_luds_lasers",1)
		client_print(0,print_chat,laser_on)
		console_print(id,laser_ona)
		log_amx("Admin: ^"%s<%d><%s><>^" enabled lasers",name,get_user_userid(id),authid)
	}
	else {
		set_cvar_num("amx_luds_lasers",0)
		client_print(0,print_chat,laser_off)
		console_print(id,laser_offa)
		log_amx("Admin: ^"%s<%d><%s><>^" disabled lasers",name,get_user_userid(id),authid)
	}
	return PLUGIN_HANDLED
}

public admin_lasersbuy(id,level,cid){
	if (!cmd_access(id,level,cid,1))
		return PLUGIN_HANDLED

	if(!csmod_running){
		client_print(id,print_chat,laserbuy_cs)
		return PLUGIN_HANDLED
	}

	new authid[35],name[32]
	get_user_authid(id,authid,34)
	get_user_name(id,name,31)

	if(get_cvar_num("amx_laser_buy") == 0){
		set_cvar_string("amx_laser_buy","1")
		client_print(0,print_chat,laserbuy_on)
		console_print(id,laserbuy_ona)
		log_amx("Admin: ^"%s<%d><%s><>^" enabled lasers_buying",name,get_user_userid(id),authid)
	}
	else {
		set_cvar_string("amx_laser_buy","0")
		client_print(0,print_chat,laserbuy_off)
		console_print(id,laserbuy_offa)
		log_amx("Admin: ^"%s<%d><%s><>^" diabled lasers_buying",name,get_user_userid(id),authid)
	}
	return PLUGIN_HANDLED
}

public admin_fstats(id,level,cid){
	if (!cmd_access(id,level,cid,1))
		return PLUGIN_HANDLED
	if(!csmod_running){
		client_print(id,print_chat,stats_cs_only)
		return PLUGIN_HANDLED
	}

	new authid[35],name[32]
	get_user_authid(id,authid,34)
	get_user_name(id,name,31)

	if(force_stats == true){
		force_stats = false
		console_print(id,"[AMXX] You have set server NOT to print stats to file on the next mapchange")
		log_amx("Lasers: ^"%s<%d><%s><>^" disabled force_laser_stats",name,get_user_userid(id),authid)
	}
	else {
		force_stats = true
		console_print(id,"[AMXX] You have set server to print stats to file on the next mapchange")
		log_amx("Lasers: ^"%s<%d><%s><>^" enabled force_laser_stats",name,get_user_userid(id),authid)
	}
	return PLUGIN_HANDLED
}

public admin_delstats(id,level,cid){
	if (!cmd_access(id,level,cid,1))
		return PLUGIN_HANDLED
	if(!csmod_running){
		client_print(id,print_chat,stats_cs_only)
		return PLUGIN_HANDLED
	}
	if(file_exists(statsfile))
		delete_file(statsfile)
	if(writeonce == 0){
		force_stats = true
		writeonce = 1
		console_print(id,"[AMXX] Writing Laserstats to file...")
		write_laserstats()
	}else{
		console_print(id,"[AMXX] Laserstats can only be written to file once per map.")
	}
	l_t_ranks = 0
	force_stats = false
	new maxplayers = get_maxplayers()
	for (new i=0; i <= maxplayers; i++) {
		setc(laser_stats_r2[i][0],4,0)
		setc(laser_statst_c[i][0],4,0)
		setc(laser_stats_r1[i][0],48,0)
		setc(mlaser_stats[i][0],48,0)
		l_rank[i] = 0
	}
	for (new i=0; i<449; i++) {
		setc(laser_stats[i][0],56,0)
		setc(laser_statst[i][0],58,0)
	}
	console_print(id,"[AMXX] You have just deleted all laserstats.")
	force_stats = false

	new authid[35],name[32]
	get_user_authid(id,authid,34)
	get_user_name(id,name,31)
	log_amx("Lasers: ^"%s<%d><%s><>^" deleted all laser stats",name,get_user_userid(id),authid)
	return PLUGIN_HANDLED
}

public HandleSay(id) {
	new Speech[192]
	read_args(Speech,192)
	remove_quotes(Speech)
	if((containi(Speech, "vote") == -1) && ((containi(Speech, "laser") != -1) || (containi(Speech, "lazer") != -1))){
		if(get_cvar_num("amx_luds_lasers") == 1){
			if( (get_cvar_num("amx_laserstats_on") == 0) || (!csmod_running) ){
				client_print(id,print_chat,laser_on2)
			}else{
				client_print(id,print_chat,laser_on3)
			}
		}else{
			client_print(id,print_chat,laser_off2)
		}
		return PLUGIN_CONTINUE
	}
	return PLUGIN_CONTINUE
}

public client_connect(id){
	tdead[id] = 0
	last_laser_time[id] = 0.0
	laser_heat[id] = 0
	if(get_cvar_num("amx_laser_buy") == 0)
		laser_shots[id] = get_cvar_num("amx_laser_ammo")
	else
		laser_shots[id] = 0

	laser_stats_r1[id][0] = 0
	laser_stats_r1[id][1] = 0
	laser_stats_r1[id][2] = 0
	laser_stats_r1[id][3] = 0
	laser_stats_r2[id][0] = 0
	laser_stats_r2[id][1] = 0
	laser_stats_r2[id][2] = 0
	laser_stats_r2[id][3] = 0
	tkcount[id] = 0
	for (new x=0; x < 8; x++) {
		sl_detail[id][x] = 0
	}
	return PLUGIN_CONTINUE
}

public client_disconnect(id) {

	if ((stats_logging || get_cvar_num("amx_forcestatslog")) && sl_detail[id][0] > 0) {
		new name[32], authid[35], team[32]
		get_user_name(id,name,31)
		get_user_authid(id,authid,34)
		get_user_team(id,team,31)

		new thits = sl_detail[id][1] + sl_detail[id][2] + sl_detail[id][3] + sl_detail[id][4] + sl_detail[id][5] + sl_detail[id][6] + sl_detail[id][7]

		log_message("^"%s<%d><%s><%s>^" triggered ^"weaponstats^" (weapon ^"lasergun^") (shots ^"%d^") (hits ^"%d^") (kills ^"%d^") (headshots ^"%d^") (tks ^"%d^") (damage ^"%d^") (deaths ^"%d^")",
			name,get_user_userid(id),authid,team,sl_detail[id][0],thits,laser_stats_r2[id][0],sl_detail[id][1],tkcount[id],laser_stats_r2[id][2],laser_stats_r2[id][1])
		log_message("^"%s<%d><%s><%s>^" triggered ^"weaponstats2^" (weapon ^"lasergun^") (head ^"%d^") (chest ^"%d^") (stomach ^"%d^") (leftarm ^"%d^") (rightarm ^"%d^") (leftleg ^"%d^") (rightleg ^"%d^")",
			name,get_user_userid(id),authid,team,sl_detail[id][1],sl_detail[id][2],sl_detail[id][3],sl_detail[id][4],sl_detail[id][5],sl_detail[id][6],sl_detail[id][7])
	}

	tdead[id] = 0
	last_laser_time[id] = 0.0
	laser_heat[id] = 0
	laser_shots[id] = get_cvar_num("amx_laser_ammo")
	laser_stats_r1[id][0] = 0
	laser_stats_r1[id][1] = 0
	laser_stats_r1[id][2] = 0
	laser_stats_r1[id][3] = 0
	laser_stats_r2[id][0] = 0
	laser_stats_r2[id][1] = 0
	laser_stats_r2[id][2] = 0
	laser_stats_r2[id][3] = 0
	tkcount[id] = 0
	for (new x=0; x < 8; x++) {
		sl_detail[id][x] = 0
	}
	return PLUGIN_CONTINUE
}

public round_end(){
	if(get_cvar_num("amx_luds_lasers") == 0)
		return PLUGIN_CONTINUE

	roundfreeze = true

	if(DoOnce == 0){
		DoOnce = 1
		set_task(0.5,"delayed_round_end")
	}
	return PLUGIN_CONTINUE
}

public delayed_round_end(){
	new ipid = get_cvar_num("amx_laser_trackbyip")
	new maxplayers = get_maxplayers()
	for (new i=0; i <= maxplayers; i++) {
		if(is_user_connected(i) == 1){
			if( (is_user_alive(i) == 0) && (get_cvar_num("amx_laser_buy") == 1) )
				laser_shots[i] = 0
			if(ipid)
				get_user_ip(i,laser_stats_r1[i][4],15,1)
			else
				get_user_authid(i,laser_stats_r1[i][4],31)
			get_user_name(i,laser_stats_r1[i][24],31)
			if(get_cvar_num("amx_laserstats_on") == 1){
				stats_helper2(laser_stats_r1[i][4],laser_stats_r1[i][24],laser_stats_r1[i][0],laser_stats_r1[i][1],laser_stats_r1[i][2],laser_stats_r1[i][3])
			}
		}
	}
	return PLUGIN_CONTINUE
}

public round_start(){
	if(get_cvar_num("amx_luds_lasers") == 0)
		return PLUGIN_CONTINUE

	roundfreeze = false

	stats_helper3()
	new authid[35],name[32]
	DoOnce = 0
	new tracked[2]
	new ipid = get_cvar_num("amx_laser_trackbyip")

	new testid[20]
	format(testid,19,laser_stats[0][4])
	if( (ipid) && (testid[0]) && (!equal(testid[3],".",1)) ){
		server_cmd("amx_del_laserstats")
		log_message("[AMXX] Laserstats deleted because of change of tracking method from AUTHID to IP")
	}
	else if( (!ipid) && (testid[0]) && (equal(testid[3],".",1)) ){
		server_cmd("amx_del_laserstats")
		log_message("[AMXX] Laserstats deleted because of change of tracking method from IP to AUTHID")
	}

	new maxplayers = get_maxplayers()
	for (new i=0; i <= maxplayers; i++) {
		tdead[i] = 0
		laser_heat[i] = 0
		if(get_cvar_num("amx_laser_buy") == 0)
			laser_shots[i] = get_cvar_num("amx_laser_ammo")
		last_laser_time[i] = 0.0
		l_warning[i][0] = 0
		l_warning[i][1] = 0
		laser_stats_r1[i][0] = 0
		laser_stats_r1[i][1] = 0
		laser_stats_r1[i][2] = 0
		laser_stats_r1[i][3] = 0
		if(is_user_connected(i) == 1){
			if(get_cvar_num("amx_laserstats_on") == 1){
				if(ipid)
					get_user_ip(i,authid,34,1)
				else
					get_user_authid(i,authid,34)
				if(authid[0]){
					for (new b=0; b<449; b++) {
						if(equal(authid,laser_statst[b][4],34)){
							laser_statst[b][56] = -1
							tracked[0] = 1
						}
						else if( (!laser_statst[b][4]) && (!tracked[0]) ){
							tracked[1] = b
							tracked[0] = 2
						}
					}
					if(tracked[0] == 2){
						get_user_name(i,name,31)
						copy(laser_statst[tracked[1]][4],34,authid)
						copy(laser_statst[tracked[1]][24],31,name)
						laser_statst[tracked[1]][56] = -1
					}
					tracked[0] = 0
					tracked[1] = 0
				}
			}
		}
	}
	if(get_cvar_num("amx_laserstats_on") == 1)
		stats_helper4()

	return PLUGIN_CONTINUE
}

public new_spawn(id){
	if(get_cvar_num("amx_luds_lasers") == 0)
		return PLUGIN_CONTINUE

	if(get_cvar_num("amx_laser_buy") == 1)
		laser_shots[id] = 0
	else
		laser_shots[id] = get_cvar_num("amx_laser_ammo")
	tdead[id] = 0
	laser_heat[id] = 0
	last_laser_time[id] = 0.0
	l_warning[id][0] = 0
	l_warning[id][1] = 0

	return PLUGIN_CONTINUE
}

public plugin_end(){
	if( (get_cvar_num("amx_laserstats_on") == 0) || (!csmod_running) )
		return PLUGIN_CONTINUE

	delete_file(statsfile)
	new wr_stats[100],authid[35],name[32]

	if(force_stats){
		write_laserstats()
	}

	for (new b=0; b<449; b++) {
		if(laser_statst[b][4]){
			if(!(laser_statst[b][0] == 0 && laser_statst[b][1] == 0 && laser_statst[b][2] == 0 && laser_statst[b][3] == 0) ){
				if(laser_statst[b][57] < 150){
					if(laser_statst[b][0] < 3)
						laser_statst[b][57] +=2
					if(laser_statst[b][2] < 600){
						laser_statst[b][57] +=1
					}else{
						laser_statst[b][57] = 0
					}
					if(laser_statst[b][56] < 250){
						format(authid,34,"%s",laser_statst[b][4])
						format(name,31,"%s",laser_statst[b][24])
						format(wr_stats,99,"%s ^"%s^" %d %d %d %d %d %d",authid,name,laser_statst[b][0],laser_statst[b][1],laser_statst[b][2],laser_statst[b][3],laser_statst[b][56],laser_statst[b][57])
						if(!equal(authid,"BOT"))
							write_file(statsfile,wr_stats)
					}
				}
			}
		}
	}
	return PLUGIN_CONTINUE
}

stats_helper(authid[],name[],kills,deaths,damage,oh){
	new NumLoops
	if(DoneInit == 0)
		NumLoops = 450
	else
		NumLoops = 16
	for(new a = 0; a < NumLoops; a++) {
		if(authid[0]){
			if(kills >= laser_stats[a][0]){
				copy(tauthid,31,laser_stats[a][4])
				copy(tname,31,laser_stats[a][24])
				tempstats[0] = laser_stats[a][0]
				tempstats[1] = laser_stats[a][1]
				tempstats[2] = laser_stats[a][2]
				tempstats[3] = laser_stats[a][3]
				copy(laser_stats[a][4],34,authid)
				copy(laser_stats[a][24],31,name)
				laser_stats[a][0] = kills
				laser_stats[a][1] = deaths
				laser_stats[a][2] = damage
				laser_stats[a][3] = oh
				copy(authid,34,tauthid)
				copy(name,31,tname)
				kills = tempstats[0]
				deaths = tempstats[1]
				damage = tempstats[2]
				oh = tempstats[3]
			}
		}
	}
}

stats_helper2(authid[],name[],kills,deaths,damage,oh){
	new ipid = get_cvar_num("amx_laser_trackbyip")
	new sauthid[35]
	new maxplayers = get_maxplayers()
	for (new b=0; b<449; b++) {
		for (new a=0; a <= maxplayers; a++){
			if(is_user_connected(a) == 1){
				if(ipid)
					get_user_ip(a,sauthid,34,1)
				else
					get_user_authid(a,sauthid,34)
				if(equal(sauthid,laser_statst[b][4],34)){
					laser_statst_c[a][0] = laser_statst[b][0]
					laser_statst_c[a][1] = laser_statst[b][1]
					laser_statst_c[a][2] = laser_statst[b][2]
					laser_statst_c[a][3] = laser_statst[b][3]
				}
				if(equal(sauthid,laser_stats[b][4],34)){
					l_rank[a] = b +1
				}
			}
		}
		if(equal(authid,laser_statst[b][4],34)){
			copy(laser_statst[b][24],31,name)
			laser_statst[b][0] += kills
			laser_statst[b][1] += deaths
			laser_statst[b][2] += damage
			laser_statst[b][3] += oh
		}
	}
}

stats_helper3(){
	new authid4[35],name4[32]
	l_t_ranks = 0
	new NumLoops
	if(DoneInit == 0)
		NumLoops = 450
	else
		NumLoops = 16
	for (new a=0; a<NumLoops; a++){
		setc(laser_stats[a][4],19,0)
		setc(laser_stats[a][24],31,0)
		laser_stats[a][0] = 0
		laser_stats[a][1] = 0
		laser_stats[a][2] = 0
		laser_stats[a][3] = 0
	}
	for (new b=0; b<449; b++){
		if(laser_statst[b][4]){
			l_t_ranks += 1
			format(authid4,34,"%s",laser_statst[b][4])
			format(name4,31,"%s",laser_statst[b][24])
			stats_helper(authid4,name4,laser_statst[b][0],laser_statst[b][1],laser_statst[b][2],laser_statst[b][3])
		}
	}
}

stats_helper4(){
	new mname[32],tempname[32]
	new mkills,mdeaths,mdamage,moh
	new maxplayers = get_maxplayers()
	for (new a=0; a <= maxplayers; a++){
		setc(mlaser_stats[a][24],31,0)
		mlaser_stats[a][0] = 0
		mlaser_stats[a][1] = 0
		mlaser_stats[a][2] = 0
		mlaser_stats[a][3] = 0
	}
	for (new a=0; a <= maxplayers; a++) {
		if(is_user_connected(a) == 1){
			copy(mname,31,laser_stats_r1[a][24])
			mkills = laser_stats_r2[a][0]
			mdeaths = laser_stats_r2[a][1]
			mdamage = laser_stats_r2[a][2]
			moh = laser_stats_r2[a][3]
			for (new b=0; b <= maxplayers; b++) {
				if(mkills >= mlaser_stats[b][0]){
					copy(tempname,31,mlaser_stats[b][24])
					tempstats[0] = mlaser_stats[b][0]
					tempstats[1] = mlaser_stats[b][1]
					tempstats[2] = mlaser_stats[b][2]
					tempstats[3] = mlaser_stats[b][3]
					copy(mlaser_stats[b][24],31,mname)
					mlaser_stats[b][0] = mkills
					mlaser_stats[b][1] = mdeaths
					mlaser_stats[b][2] = mdamage
					mlaser_stats[b][3] = moh
					copy(mname,31,tempname)
					mkills = tempstats[0]
					mdeaths = tempstats[1]
					mdamage = tempstats[2]
					moh = tempstats[3]
				}
			}
		}
	}
}

write_laserstats(){
	new showip = get_cvar_num("amx_laser_showip")
	new wr_stats[100],authid[35],name[32]
	new filename[50]
	new len
	new spacer[32],spacer2[10],spacer3[10],spacer4[10],spacer5[10]
	DoneInit = 0
	stats_helper3()
	if(force_stats == false){
		get_time("addons/amx/%Y-%m--laserstats.log",filename,49)
		write_file(filename,filename)
	}else{
		get_time("addons/amx/%m-%d-%Y--%H-%M---laserstats.log",filename,49)
		write_file(filename,filename)
	}
	write_file(filename," ")
	write_file(filename,"Name                             |Kills     |Deaths    |Damage    |Overheats |Identifier",-1)
	write_file(filename," ")
	for (new b=0; b<449; b++) {
		if(laser_stats[b][4]){
			format(authid,34,"%s",laser_stats[b][4])
			format(name,31,"%s",laser_stats[b][24])
			setc(spacer,31,0)
			setc(spacer3,9,0)
			setc(spacer4,9,0)
			setc(spacer5,9,0)
			len = (strlen(name) - 32) * -1
			for(new z = 0; z<len;z++)
				add(spacer,31," ")
			num_to_str(laser_stats[b][0],spacer2,9)
			num_to_str(laser_stats[b][1],spacer3,9)
			num_to_str(laser_stats[b][2],spacer4,9)
			num_to_str(laser_stats[b][3],spacer5,9)
			len = (strlen(spacer2) - 10) * -1
			setc(spacer2,9,0)
			for(new z = 0; z<len;z++)
				add(spacer2,9," ")
			len = (strlen(spacer3) - 10) * -1
			setc(spacer3,9,0)
			for(new z = 0; z<len;z++)
				add(spacer3,9," ")
			len = (strlen(spacer4) - 10) * -1
			setc(spacer4,9,0)
			for(new z = 0; z<len;z++)
				add(spacer4,9," ")
			len = (strlen(spacer5) - 10) * -1
			setc(spacer5,9,0)
			for(new z = 0; z<len;z++)
				add(spacer5,9," ")
			if(showip)
				format(wr_stats,99,"%s%s  %d%s %d%s %d%s %d%s %s",name,spacer,laser_stats[b][0],spacer2,laser_stats[b][1],spacer3,laser_stats[b][2],spacer4,laser_stats[b][3],spacer5,authid)
			else
				format(wr_stats,99,"%s%s  %d%s %d%s %d%s %d%s private",name,spacer,laser_stats[b][0],spacer2,laser_stats[b][1],spacer3,laser_stats[b][2],spacer4,laser_stats[b][3],spacer5)
			write_file(filename,wr_stats)
		}
	}
	DoneInit = 1
}

public replace_dm(id,tid,tbody){

	//Update killers scorboard with new info
	message_begin(MSG_ALL,gmsgScoreInfo)
	write_byte(id)
	write_short(get_user_frags(id))
	write_short(get_user_deaths(id))
	write_short(0)
	write_short(get_user_team(id))
	message_end()

	//Update victims scoreboard with correct info
	message_begin(MSG_ALL,gmsgScoreInfo)
	write_byte(tid)
	write_short(get_user_frags(tid))
	write_short(get_user_deaths(tid))
	write_short(0)
	write_short(get_user_team(tid))
	message_end()

	//Headshot Kill
	if (tbody == 1){
		message_begin( MSG_ALL, gmsgDeathMsg,{0,0,0},0)
		write_byte(id)
		write_byte(tid)
		write_string(" lasergun")
		message_end()
	}
	//Normal Kill
	else{
		message_begin( MSG_ALL, gmsgDeathMsg,{0,0,0},0)
		write_byte(id)
		write_byte(tid)
		write_byte(0)
		write_string("lasergun")
		message_end()
	}
	return PLUGIN_CONTINUE
}

/************************************************************
* MOTD Popups
************************************************************/

public laser_motd(id){

	new len = 1024
	new buffer[1025]
	new n = 0

#if !defined NO_STEAM
	n += copy( buffer[n],len-n,"<html><head><style type=^"text/css^">pre{color:#FFB000;}body{background:#000000;margin-left:8px;margin-top:0px;}</style></head><body><pre>^n")
#endif

	n += copy( buffer[n],len-n,"To use your laser gun have to bind a key to:^n^n")
	n += copy( buffer[n],len-n,"amx_firelasergun^n^n")
	n += copy( buffer[n],len-n,"In order to bind a key you must open your console and use the bind command: ^n^n")
	n += copy( buffer[n],len-n,"bind ^"key^" ^"command^" ^n^n")

	n += copy( buffer[n],len-n,"In this case the command is ^"amx_firelasergun^".  Here are some examples:^n^n")
	n += copy( buffer[n],len-n,"    bind f amx_firelasergun         bind MOUSE3 amx_firelasergun^n^n")
	n += copy( buffer[n],len-n,"Caution: Watch the laser temperature posted above the center^n")
	n += copy( buffer[n],len-n,"of your screen when you fire. If you overheat the laser,^n")
	n += copy( buffer[n],len-n,"it will explode and you will die.^n^n")

	n += copy( buffer[n],len-n,"Laser Color:^n")
	n += copy( buffer[n],len-n,"bind f ^"amx_firelasergun !RRRGGGBBB^"^n")
	n += copy( buffer[n],len-n,"Replace RRR, GGG, and BBB with three digit numbers^n")
	n += copy( buffer[n],len-n,"for Red Green and Blue values. The numbers can be from 0 - 255^n^n")
	n += copy( buffer[n],len-n,"Example for pure red:^n")
	n += copy( buffer[n],len-n,"bind f ^"amx_firelasergun !255000000^"^n^n")

	n += copy( buffer[n],len-n,"You can also do this:^n")
	n += copy( buffer[n],len-n,"bind f ^"amx_firelasergun red^"^n^n")
	n += copy( buffer[n],len-n,"Colors: white, red, green, blue, yellow, magenta, cyan^n^n")

	if(get_cvar_num("amx_laserstats_on") && csmod_running) {
		n += copy( buffer[n],len-n,"say /laserstats     --for top 15 laser fraggers^n")
		n += copy( buffer[n],len-n,"say /laserstats2    --for current map total laser stats^n")
		n += copy( buffer[n],len-n,"say /laserstatsme   --for your total laser stats^n")
	}

#if !defined NO_STEAM
	n += copy( buffer[n],len-n,"</pre></body></html>")
#endif

	show_motd(id,buffer ,"Laser Gun Help:")
	return PLUGIN_CONTINUE
}

public laser_stats_m(id){
	if(get_cvar_num("amx_laserstats_on") == 0){
		client_print(id,print_chat,no_stats)
		return PLUGIN_HANDLED
	}
	if(!csmod_running){
		client_print(id,print_chat,stats_cs_only)
		return PLUGIN_HANDLED
	}

	new len = 2500
	new buffer[2501]
	new n = 0

#if !defined NO_STEAM
	n += copy( buffer[n],len-n,"<html><head><style type=^"text/css^">pre{color:#FFB000;}body{background:#000000;margin-left:8px;margin-top:0px;}</style></head><body><pre>")
#endif

	n += copy( buffer[n],len-n,"say /laserstats     --for top 15 laser fraggers^n")
	n += copy( buffer[n],len-n,"say /laserstats2    --for current map total laser stats^n")
	n += copy( buffer[n],len-n,"say /laserstatsme   --for your total laser stats^n^n")

	n += format( buffer[n],len-n,"%6s | %6s | %6s | %10s | %s^n","Kills","Deaths","Damage","Overheats","Player")
	n += copy( buffer[n],len-n,"------------------------------------------------------------^n")

	new maxpl = get_maxplayers()
	for(new a = 0; a <= maxpl; a++) {
		new names[32]
		copy(names,31,mlaser_stats[a][24])
		if(mlaser_stats[a][24]){
			n += format( buffer[n],len-n,"%6d   %6d   %6d   %10d   %s^n",mlaser_stats[a][0],mlaser_stats[a][1],mlaser_stats[a][2],mlaser_stats[a][3],names)
		}
	}

#if !defined NO_STEAM
	n += copy( buffer[n],len-n,"</pre></body></html>")
#endif

	show_motd(id,buffer,"Laser Stats: Current Map")
	return PLUGIN_CONTINUE
}

public laser_stats_mee(id){
	if(get_cvar_num("amx_laserstats_on") == 0){
		client_print(id,print_chat,no_stats)
		return PLUGIN_HANDLED
	}
	if(!csmod_running){
		client_print(id,print_chat,stats_cs_only)
		return PLUGIN_HANDLED
	}

	new names[32],title[64]
	get_user_name(id,names,31)
	new len = 1300
	new buffer[1301]
	new n = 0

#if !defined NO_STEAM
	n += copy( buffer[n],len-n,"<html><head><style type=^"text/css^">pre{color:#FFB000;}body{background:#000000;margin-left:8px;margin-top:0px;}</style></head><body><pre>")
#endif

	n += copy( buffer[n],len-n,"say /laserstats     --for top 15 laser fraggers^n")
	n += copy( buffer[n],len-n,"say /laserstats2    --for current map total laser stats^n")
	n += copy( buffer[n],len-n,"say /laserstatsme   --for your total laser stats^n^n")

	n += format( buffer[n],len-n,"Laser rank at map start: %d of %d^n^n",l_rank[id],l_t_ranks)

	n += format( buffer[n],len-n,"Your total laser stats:^n%6s | %6s | %6s | %10s^n","Kills","Deaths","Damage","Overheats")
	n += format( buffer[n],len-n,"%6d   %6d   %6d   %10d^n^n",laser_statst_c[id][0],laser_statst_c[id][1],laser_statst_c[id][2],laser_statst_c[id][3])

	n += format( buffer[n],len-n,"Your laser stats for this map:^n%6s | %6s | %6s | %10s^n","Kills","Deaths","Damage","Overheats")
	n += format( buffer[n],len-n,"%6d   %6d   %6d   %10d^n^n",laser_stats_r2[id][0],laser_stats_r2[id][1],laser_stats_r2[id][2],laser_stats_r2[id][3])

	n += format( buffer[n],len-n,"Your laser stats for the round:^n%6s | %6s | %6s | %10s^n","Kills","Deaths","Damage","Overheats")
	n += format( buffer[n],len-n,"%6d   %6d   %6d   %10d^n^n",laser_stats_r1[id][0],laser_stats_r1[id][1],laser_stats_r1[id][2],laser_stats_r1[id][3])

#if !defined NO_STEAM
	n += copy( buffer[n],len-n,"</pre></body></html>")
#endif

	format(title,63,"Laser Stats: %s",names)
	show_motd(id,buffer,title)
	return PLUGIN_CONTINUE
}

public laser_stats_a(id){
	if(get_cvar_num("amx_laserstats_on") == 0) {
		client_print(id,print_chat,no_stats)
		return PLUGIN_HANDLED
	}
	if(!csmod_running){
		client_print(id,print_chat,stats_cs_only)
		return PLUGIN_HANDLED
	}

	new len = 1300
	new buffer[1301]
	new n = 0

#if !defined NO_STEAM
	n += copy( buffer[n],len-n,"<html><head><style type=^"text/css^">pre{color:#FFB000;}body{background:#000000;margin-left:8px;margin-top:0px;}</style></head><body><pre>")
#endif

	n += copy( buffer[n],len-n,"say /laserstats     --for top 15 laser fraggers^n")
	n += copy( buffer[n],len-n,"say /laserstats2    --for current map total laser stats^n")
	n += copy( buffer[n],len-n,"say /laserstatsme   --for your total laser stats^n^n")

	n += format( buffer[n],len-n,"%6s | %6s | %6s | %10s | %s^n","Kills","Deaths","Damage","Overheats","Player")

	n += copy( buffer[n],len-n,"------------------------------------------------------------^n")

	for(new a = 0; a < 15; a++) {
		new names[32]
		copy(names,31,laser_stats[a][24])
		if(laser_stats[a][4]) {
			n += format( buffer[n],len-n,"%6d   %6d   %6d   %10d   %s^n",laser_stats[a][0],laser_stats[a][1],laser_stats[a][2],laser_stats[a][3],names)
		}
	}

#if !defined NO_STEAM
	n += copy( buffer[n],len-n,"</pre></body></html>")
#endif

	show_motd(id,buffer,"Laser Stats: Top 15")
	return PLUGIN_CONTINUE
}

/************************************************************
* CORE PLUGIN FUNCTIONS
************************************************************/

public plugin_init() {
	
	register_plugin(PLUGIN_NAME, PLUGIN_VERS, PLUGIN_AUTH);
	

	g_menuSpecial = uj_menus_get_menu_id("Special Days");
	

	//g_iMaxPlayers   = get_maxplayers();
	register_concmd("amx_lasers","admin_lasers",ADMIN_LEVEL_C,"- toggles laser guns mode on and off")
	register_concmd("amx_laserbuying","admin_lasersbuy",ADMIN_LEVEL_C,"- toggles laser buy requirement mode on and off")
	register_concmd("amx_del_laserstats","admin_delstats",ADMIN_RCON,"- deletes all laserstats after writing them to file")
	register_concmd("amx_write_laserstats","admin_fstats",ADMIN_RCON,"- toggles forcing laserstats to be written to file on map change")
	register_srvcmd("bot_laser","bot_interface")
	register_cvar("amx_luds_lasers","1",FCVAR_SERVER)
	register_cvar("amx_laserstats_on","1")
	register_cvar("amx_laser_buy","0")
	register_cvar("amx_laser_cost","100")
	register_cvar("amx_laser_maxtemp","3440")
	register_cvar("amx_laser_ammo","50")
	register_cvar("amx_laser_burndecals","1")
	register_cvar("amx_laser_allowinvis","1")
	register_cvar("amx_laser_obeyffcvar","1")
	register_cvar("amx_laser_tkpunish1","1")
	register_cvar("amx_laser_tkpunish2","1")
	register_cvar("amx_laser_tkpunish3","3")
	register_cvar("amx_laser_trackbyip","0")
	register_cvar("amx_laser_showip","0")
	register_cvar("amx_laser_botaimdiffuse","16")
	register_cvar("amx_forcestatslog","0")
	register_clcmd("say /laser","laser_motd")
	register_clcmd("say /lazer","laser_motd")
	register_clcmd("say /laserstats","laser_stats_a")
	register_clcmd("say /laserstats2","laser_stats_m")
	register_clcmd("say /laserstatsme","laser_stats_mee")
	register_clcmd("amx_firelasergun","fire_laser",0,"- fires the laser gun if the plugin is enabled")
	register_clcmd("amx_firelazergun","fire_laser")
	//register_clcmd("drop", "fire_laser") 
	register_clcmd("say","HandleSay")
	register_event("Damage", "laser_sw_con", "b", "2!0", "3=0", "4!0")
	register_event("ResetHUD", "new_spawn", "b")
		
#if defined CSTRIKE
	register_logevent("round_start", 2, "1=Round_Start")
	register_logevent("round_end", 2, "1=Round_End")
	RegisterHam(Ham_ObjectCaps, "player", "FwdPlayerObjectCapsPost", 1); //pika
#endif

	/*This should work but it seems to be broken and always returning true
	if (is_plugin_loaded("stats_logging.amx")) {
		stats_logging = true
	}*/
	//So for now we will do this instead

	new nump = get_pluginsnum()
	new filename[64],temp[64]
	for(new i = 0; i < nump; ++i){
		get_plugin(i,filename,63,temp,63,temp,63,temp,63,temp,63)
		if(equali(filename,"stats_logging.amx")){
			stats_logging = true
		}
	}

	get_customdir(customdir, 63)
	format(statsfile,127,"%s/ejl_laser_stats.ini",customdir)
	new hudcfile[128]
	format(hudcfile,127,"%s/ejl_hud_colors.ini",customdir)
	new line, stxtsize
	new data[192]
	new sr[4],sg[4],sb[4]
	if(file_exists(hudcfile)){
		while((line=read_file(hudcfile,line,data,191,stxtsize))!=0){
			parse(data,adscolors[line][3],39,sr,4,sg,4,sb,4)
			adscolors[line][0] = str_to_num(sr)
			adscolors[line][1] = str_to_num(sg)
			adscolors[line][2] = str_to_num(sb)
		}
	}

	new month[4]
	get_time("%m",month,3)
	new laser_month[4]
	get_vaultdata("EJL_LASER_MONTH",laser_month,3)
	if(!equal(laser_month,"") && !equal(laser_month,month)){
		write_laserstats()
		delete_file(statsfile)
	}
	set_vaultdata("EJL_LASER_MONTH",month)

	csmod_running = cstrike_running() ? true : false
	
	if(csmod_running){
		load_laser_stats()
	}
	else if(get_cvar_num("amx_laser_buy") == 1) {
		server_print("[AMXX] Laser buying is only for Counter-Strike, amx_laser_buy is being set to 0")
		set_cvar_num("amx_laser_buy",0)
	}
	if(get_cvar_num("sv_lan"))
		set_cvar_string("amx_laser_trackbyip","1")

	DoneInit = 1

	gmsgDeathMsg = get_user_msgid("DeathMsg")
	gmsgScoreInfo = get_user_msgid("ScoreInfo")
}

public load_laser_stats() {
	new line, stxtsize
	new data[192]
	new sls0[11],sls1[11],sls2[11],sls3[11],sls4[20],sls44[32],sls56[11],sls57[11]
	if(file_exists(statsfile)){
		while((line=read_file(statsfile,line,data,191,stxtsize))!=0){
			if(line < 449 && line > -1){
				parse(data,sls4,19,sls44,31,sls0,10,sls1,10,sls2,10,sls3,10,sls56,10,sls57,10)
				if(!equal(sls4,"BOT")){
					new authid[35],name[32]
					format(laser_statst[line][4],19,"%s",sls4)
					format(laser_statst[line][24],31,"%s",sls44)
					laser_statst[line][0] = str_to_num(sls0)
					laser_statst[line][1] = str_to_num(sls1)
					laser_statst[line][2] = str_to_num(sls2)
					laser_statst[line][3] = str_to_num(sls3)
					laser_statst[line][56] = str_to_num(sls56) + 1
					laser_statst[line][57] = str_to_num(sls57)
					format(authid,34,"%s",laser_statst[line][4])
					format(name,31,"%s",laser_statst[line][24])
					stats_helper(sls4,sls44,str_to_num(sls0),str_to_num(sls1),str_to_num(sls2),str_to_num(sls3))
				}
			}
		}
	}
}

public plugin_modules()
{
	require_module("fun")
	require_module("engine")

	#if defined CSTRIKE
	require_module("Counter-Strike")
	#endif
}
public FwdPlayerObjectCapsPost(id)
{
	if(!g_dayEnabled)
	return PLUGIN_HANDLED;
	if(is_user_alive(id))
	{
		static Float: flGametime;
		flGametime = get_gametime();
		if((g_flLastLaserAttack[id] + 0.5) < flGametime)	
		{
		fire_laser(id);
		emit_sound(0,CHAN_ITEM, "weapons/electro5.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
		g_flLastLaserAttack[id] = flGametime;
		return PLUGIN_HANDLED;
		}
		
		//g_flLastLaserAttack[id] = flGametime;
	}
	
	return PLUGIN_HANDLED;

}
