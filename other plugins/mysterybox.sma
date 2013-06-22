#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <fakemeta_util>
#include <cstrike>
#include <engine>
#include <fun>
#include <uj_colorchat>
#include <uj_points>


/*================================================================================
 [Plugin Customization]
=================================================================================*/

//Models and sounds are randomly chosen, add as many, as you want

new g_iMsgId_ScreenFade;
new g_MsgShake;
new g_iMaxPlayers;

new g_iSpray;
new g_iDrop;

new jumpnum[33], bool:dojump[33], bool:has_multijump[33];

new bool:g_NoRecoil[ 33 ];

new g_BunnyHop[33];

new g_Seizure[33];

new const model_present[][] = { "models/box_ammo.mdl" }

new const sound_respawn[][] = { "mysterybox/respawn.wav", "present/respawn2.wav" }

//Customization end here!

//Some offsets 
#if cellbits == 32
const OFFSET_CSMONEY = 115
const OFFSET_AWM_AMMO  = 1 
const OFFSET_SCOUT_AMMO = 1
const OFFSET_PARA_AMMO = 379
const OFFSET_FAMAS_AMMO = 380
const OFFSET_M3_AMMO = 381
const OFFSET_USP_AMMO = 382
const OFFSET_FIVESEVEN_AMMO = 383
const OFFSET_DEAGLE_AMMO = 384
const OFFSET_P228_AMMO = 385
const OFFSET_GLOCK_AMMO = 386
const OFFSET_FLASH_AMMO = 387
const OFFSET_HE_AMMO = 388
const OFFSET_SMOKE_AMMO = 389
#else
const OFFSET_CSMONEY = 140
const OFFSET_AWM_AMMO  = 426
const OFFSET_SCOUT_AMMO = 1
const OFFSET_PARA_AMMO = 428
const OFFSET_FAMAS_AMMO = 429
const OFFSET_M3_AMMO = 430
const OFFSET_USP_AMMO = 431
const OFFSET_FIVESEVEN_AMMO = 432
const OFFSET_DEAGLE_AMMO = 433
const OFFSET_P228_AMMO = 434
const OFFSET_GLOCK_AMMO = 435
const OFFSET_FLASH_AMMO = 46
const OFFSET_HE_AMMO = 437
const OFFSET_SMOKE_AMMO = 438
#endif
const OFFSET_LINUX  = 5

//Primary weapons array (thanks Mercyllez)
new const g_primary_items[][] = { "weapon_galil", "weapon_famas", "weapon_m4a1", "weapon_ak47", "weapon_sg552", "weapon_aug", "weapon_scout",
				"weapon_m3", "weapon_xm1014", "weapon_tmp", "weapon_mac10", "weapon_ump45", "weapon_mp5navy", "weapon_p90",
				"weapon_m249", "weapon_sg550", "weapon_g3sg1"}

//Secondary weapons array (thanks Mercyllez)				
new const g_secondary_items[][] = { "weapon_glock18", "weapon_usp", "weapon_p228", "weapon_deagle", "weapon_fiveseven", "weapon_elite" }

//Max BackPack ammo array (thanks Mercyllez) 
new const MAXBPAMMO[] = { 1 }
//Amount of gived ammo (thanks Mercyllez)
new const GIVEAMMO[] = { 1 }
//Ammo ID array (thanks Mercyllez)
new const AMMOID[] = { 1 }

//Weapon BitSum (thanks Mercyllez)			
const PRIMARY_WEAPONS_BIT_SUM = (1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90)
const SECONDARY_WEAPONS_BIT_SUM = (1<<CSW_P228)|(1<<CSW_ELITE)|(1<<CSW_FIVESEVEN)|(1<<CSW_USP)|(1<<CSW_GLOCK18)|(1<<CSW_DEAGLE)


//Pcvar variables		
new pcvar_on,pcvar_respawn_time,pcvar_blast,pcvar_blast_color

//Rest of variables
new g_explo,g_money,g_ammo

//Task ID enum
enum (+= 100)
{
	TASK_PRIMARY = 100,
	TASK_SECONDARY
}


//Version information
new const VERSION[] = "2.01"

public plugin_init()
{
	register_plugin("Pick up present", VERSION, "FakeNick")
	pcvar_on = register_cvar("mysterybox_on","1")
	
	//Make sure that the plugin is on
	if(!get_pcvar_num(pcvar_on))
		return
	
	//Register dictionary
	register_dictionary("mysterybox.txt")
	
	//Register admin commands
	register_clcmd("say !add","func_add_present")
	register_clcmd("say !remove","func_remove_present")
	register_clcmd("say !removeall","func_remove_present_all")
	register_clcmd("say !save","func_save_origins")
	register_clcmd("say !rotate","func_rotate_present")
		
	//Some forwards
	register_forward(FM_Touch,"forward_touch")
	register_forward(FM_Think,"forward_think")
		
	//Cvars register
	pcvar_respawn_time = register_cvar("mystery_respawn_time","600.0")
	pcvar_blast = register_cvar("mystery_blast","1")
	pcvar_blast_color = register_cvar("mystery_blast_color","255 255 255")
	
	//Only for version recognize
	register_cvar("present_version", VERSION, FCVAR_SERVER|FCVAR_SPONLY)
	register_logevent("EventRoundStart", 2, "1=Round_Start");
	register_forward(FM_PlayerPreThink, "FW_PlayerPreThink"); //multi jump
	register_forward(FM_PlayerPostThink, "FW_PlayerPostThink"); //multi jump
	register_logevent("EventRoundEnd", 2, "1&Restart_Round");
	register_logevent("EventRoundEnd", 2, "1=Game_Commencing");
	register_logevent("EventRoundEnd", 2, "1=Round_End");	
	
	//Other stuff
	g_money = get_user_msgid("Money")
	g_ammo = get_user_msgid("AmmoPickup")
	g_iMsgId_ScreenFade   = get_user_msgid("ScreenFade");
	g_MsgShake = get_user_msgid("ScreenShake");
	g_iMaxPlayers   = get_maxplayers();
}
public plugin_precache()
{
	new i
	
	for(i = 0; i < sizeof model_present; i++)
		engfunc(EngFunc_PrecacheModel,model_present[i])
	
	for (i = 0; i < sizeof sound_respawn; i++)
		engfunc(EngFunc_PrecacheSound, sound_respawn[i])
	
	g_explo = engfunc(EngFunc_PrecacheModel,"sprites/shockwave.spr")
	g_iSpray = precache_model("sprites/bloodspray.spr");
	g_iDrop = precache_model("sprites/blood.spr");
}
public plugin_cfg()
{
	//Create some variables
	static sConfigsDir[64], sFile[128]
	
	//Get config folder directory
	get_configsdir(sConfigsDir, sizeof sConfigsDir - 1)
	
	//Get mapname
	static sMapName[32]
	get_mapname(sMapName, sizeof sMapName - 1)
	
	//Format .cfg file directory
	formatex(sFile, sizeof sFile - 1, "%s/mysterybox/%s_mystery_origins.cfg", sConfigsDir, sMapName)
	
	//If file doesn't exist return
	if(!file_exists(sFile))
		return
	
	//Some variables
	static sFileOrigin[3][32], sFileAngles[3][32], iLine, iLength, sBuffer[256]
	static sTemp1[128], sTemp2[128]
	static Float:fOrigin[3], Float:fAngles[3]
	
	//Read file
	while(read_file(sFile, iLine++, sBuffer, sizeof sBuffer - 1, iLength))
	{
		if((sBuffer[0]==';') || !iLength)
			continue
		
		strtok(sBuffer, sTemp1, sizeof sTemp1 - 1, sTemp2, sizeof sTemp2 - 1, '|', 0)
		
		parse(sTemp1, sFileOrigin[0], sizeof sFileOrigin[] - 1, sFileOrigin[1], sizeof sFileOrigin[] - 1, sFileOrigin[2], sizeof sFileOrigin[] - 1)
		
		fOrigin[0] = str_to_float(sFileOrigin[0])
		fOrigin[1] = str_to_float(sFileOrigin[1])
		fOrigin[2] = str_to_float(sFileOrigin[2])
		
		parse(sTemp2, sFileAngles[0], sizeof sFileAngles[] - 1, sFileAngles[1], sizeof sFileAngles[] - 1, sFileAngles[2], sizeof sFileAngles[] - 1)
		
		fAngles[0] = str_to_float(sFileAngles[0])
		fAngles[1] = str_to_float(sFileAngles[1])
		fAngles[2] = str_to_float(sFileAngles[2])
		
		//Spawn mysterybox on origins saved in .cfg file
		func_spawn(fOrigin)
	}
}

/*================================================================================
 [Tasks]
=================================================================================*/

public task_primary(id)
{
	//Check player id
	id -= TASK_PRIMARY
	
	//Make usre that player is alive
	if(!is_user_alive(id))
		return
	
	//Give him primary weapon
	func_give_item_primary(id, random_num(0, sizeof g_primary_items - 1))
}
public task_secondary(id)
{
	//Check player id
	id -= TASK_SECONDARY
	
	//Make usre that player is alive
	if(!is_user_alive(id))
		return
		
	//Give him secondary weapon	
	func_give_item_secondary(id, random_num(0, sizeof g_secondary_items - 1))
}

/*================================================================================
 [Main functions]
=================================================================================*/
public func_add_present(id)
{	
	//Check command access
	if(!access(id,ADMIN_IMMUNITY))
		return
	
	//Create some variables
	new Float:fOrigin[3],origin[3],name[32],map[32]
	
	//Get player origins
	get_user_origin(id,origin,3)
	
	//Make float origins from integer origins
	IVecFVec(origin,fOrigin)
	
	//Check the player aiming
	if((engfunc(EngFunc_PointContents, fOrigin) != CONTENTS_SKY) && (engfunc(EngFunc_PointContents, fOrigin) != CONTENTS_SOLID))
	{
		//Get his name and map name for log creating
		get_user_name(id,name,sizeof name - 1)
		
		get_mapname(map,sizeof map - 1)
		
		//Create log file or log admin command
		log_to_file("mystery.log","[%s] has created a present on map %s",name,map)
		
		//Finally spawn mysterybox
		func_spawn(fOrigin)
		
		//Print success and save info information
		client_print(id,print_chat,"%L",LANG_PLAYER,"SUCC_ADD",origin[0],origin[1],origin[2])
		client_print(id,print_chat,"%L",LANG_PLAYER,"SAVE_INFO")
	}else{
		//That location is unavaiables, so print information
		client_print(id,print_chat,"%L",LANG_PLAYER,"LOCATION_UN")
	}
	
	
}
public func_remove_present(id)
{
	//Check command access
	if(!access(id,ADMIN_IMMUNITY))
		return
	
	//Create some variables
	static ent, body,name[32],map[32]
	
	//Check player aiming
	get_user_aiming(id, ent, body)
	
	//Check ent validity
	if(pev_valid(ent))
	{
		//Check entity classname
		static classname[32]
		pev(ent, pev_classname, classname, sizeof classname - 1)
		
		//Player is aiming at box
		if(!strcmp(classname, "present", 1))
		{
			//Get user name and map name for log creating
			get_user_name(id,name,sizeof name - 1)
			get_mapname(map,sizeof map - 1)
			
			//Create log file or log admin command
			log_to_file("mystery.log","[%s] has removed mysterybox from map %s",name,map)
			
			//Finalyl remove the entity
			engfunc(EngFunc_RemoveEntity, ent)
			
			//Print success inforamtion
			client_print(id, print_chat, "%L",LANG_PLAYER,"SUCC_REMOVE")
		}else
		{
			//Player must aim at box
			client_print(id, print_chat, "%L",LANG_PLAYER,"PRESENT_AIM")
		}
	}
}
public func_remove_present_all(id)
{
	//Check command access
	if(!access(id, ADMIN_KICK))
		return
	
	//Create some variables
	new ent = -1,count,name[32],map[32]
	count = 0 
	
	//Find boxes
	while((ent = fm_find_ent_by_class(ent,"present")))
	{
		//Increase count
		count++
		//Remove boxess
		engfunc(EngFunc_RemoveEntity,ent)
	}
	//Print information
	client_print(id,print_chat,"%L",LANG_PLAYER,"REMOVE_ALL",count)
	
	//Get player name and map name
	get_user_name(id,name,sizeof name - 1)
	get_mapname(map,sizeof map - 1)
	
	//Log command to file
	log_to_file("mystery.log","[%s] has removed all mysteryboxes from map %s",name,map)
	
	//Print save information
	client_print(id,print_chat,"%L",LANG_PLAYER,"SAVE_INFO")
}
public func_save_origins(id)
{
	//Check command access
	if(!access(id, ADMIN_KICK))
		return
	
	//Create some variables
	static sConfigsDir[64], sFile[128],name[32],map[32]
	
	//Get config folder directory
	get_configsdir(sConfigsDir, sizeof sConfigsDir - 1)
	
	//Get map name
	static sMapName[32]
	get_mapname(sMapName, sizeof sMapName - 1)
	
	//Format .cfg file directory
	formatex(sFile, sizeof sFile - 1, "%s/mysterybox/%s_mystery_origins.cfg", sConfigsDir, sMapName)
	
	//If file already exist, delete file
	if(file_exists(sFile))
		delete_file(sFile)
	
	//Some variables
	new iEnt = -1, Float:fEntOrigin[3], Float:fEntAngles[3], iCount
	static sBuffer[256]
	
	//Find boxes on this map
	while((iEnt = engfunc(EngFunc_FindEntityByString, iEnt, "classname", "present")))
	{
		//Get origins and angles
		pev(iEnt, pev_origin, fEntOrigin)
		pev(iEnt, pev_angles, fEntAngles)
		
		formatex(sBuffer, sizeof sBuffer - 1, "%f %f %f | %f %f %f", fEntOrigin[0], fEntOrigin[1], fEntOrigin[2], fEntAngles[0], fEntAngles[1], fEntAngles[2])
	
		//Create file
		write_file(sFile, sBuffer, -1)
		
		//Increase count variable
		iCount++
	}
	//Get user name and map name
	get_user_name(id,name,sizeof name - 1)
	get_mapname(map,sizeof map - 1)
	
	//Log admin command
	log_to_file("mystery.log","[%s] has saved a mysterybox on map %s",name,map)
	
	//Print success information
	client_print(id, print_chat, "%L",LANG_PLAYER,"SUCC_SAVE", iCount,sMapName)
}
public func_rotate_present(id)
{
	//Check command access
	if(!access(id, ADMIN_KICK))
		return
		
	//Some variables
	static ent, body,name[32],map[32]
	
	//Get user aiming
	get_user_aiming(id, ent, body)
	
	//Check entity validity
	if(pev_valid(ent))
	{
		//Check classname
		static sClassname[32]
		pev(ent, pev_classname, sClassname, sizeof sClassname - 1)
		
		//Player is aiming at box
		if(!strcmp(sClassname, "present", 1))
		{
			//Get angles
			static Float:fAngles[3]
			pev(ent, pev_angles, fAngles)
			
			//Rotate box
			fAngles[1] += 90.0
			set_pev(ent, pev_angles, fAngles)
			
			//Get user name and map name
			get_user_name(id,name,sizeof name - 1)
			get_mapname(map,sizeof map - 1)
			
			//Log admin command
			log_to_file("mystery.log","[%s] has rotated a mysterybox on map %s",name,map)
			
			//Print success information
			client_print(id, print_chat, "%L",LANG_PLAYER,"SUCC_ROTATE")
		}else{
			//Print failure information
			client_print(id, print_chat, "%L",LANG_PLAYER,"PRESENT_AIM")
		}
	}
}
public func_spawn(Float:origin[3])
{
	//Create new entity	
	new ent = engfunc(EngFunc_CreateNamedEntity,engfunc(EngFunc_AllocString,"info_target"))
	
	//Set classname to "present"
	set_pev(ent,pev_classname,"present")
	
	//Set entity origins
	engfunc(EngFunc_SetOrigin,ent,origin)
	
	//Create blast effect
	func_make_blast(origin)
	
	//Emit spawn sound
	engfunc(EngFunc_EmitSound,ent,CHAN_AUTO,sound_respawn[random_num(0, sizeof sound_respawn - 1)],1.0,ATTN_NORM,0,PITCH_NORM)
	emit_sound(0, CHAN_AUTO, sound_respawn[0], 1.0, ATTN_NORM, 0, PITCH_NORM)
	
	//size variables
	static Float:fMaxs[3] = { 2.0, 2.0, 4.0 }
	static Float:fMins[3] = { -2.0, -2.0, -4.0 }
		
	//Set random player model
	engfunc(EngFunc_SetModel,ent,model_present[random_num(0,sizeof model_present - 1)])
	
	//Spawn entity
	dllfunc(DLLFunc_Spawn,ent)
	//Make it solid
	set_pev(ent,pev_solid,SOLID_BBOX)
	//Set entity size
	engfunc(EngFunc_SetSize,ent,fMins,fMaxs)
}
//From forstnades by Avalanche
public func_make_blast(Float:fOrigin[3])
{
	if(!get_pcvar_num(pcvar_blast))
		return
	
	//Create origin variable
	new origin[3]
	
	//Make float origins from integer origins
	FVecIVec(fOrigin,origin)
	
	//Get blast color
	new Float:rgbF[3], rgb[3]
	func_get_rgb(rgbF)
	FVecIVec(rgbF,rgb)
	
	//Finally create blast
	
	//smallest ring
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(TE_BEAMCYLINDER)
	write_coord(origin[0])
	write_coord(origin[1])
	write_coord(origin[2])
	write_coord(origin[0])
	write_coord(origin[1])
	write_coord(origin[2] + 385)
	write_short(g_explo)
	write_byte(0)
	write_byte(0)
	write_byte(4)
	write_byte(60)
	write_byte(0)
	write_byte(rgb[0])
	write_byte(rgb[1])
	write_byte(rgb[2])
	write_byte(100)
	write_byte(0)
	message_end()
	
	// medium ring
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(TE_BEAMCYLINDER)
	write_coord(origin[0])
	write_coord(origin[1])
	write_coord(origin[2])
	write_coord(origin[0])
	write_coord(origin[1])
	write_coord(origin[2] + 470)
	write_short(g_explo)
	write_byte(0)
	write_byte(0)
	write_byte(4)
	write_byte(60)
	write_byte(0)
	write_byte(rgb[0])
	write_byte(rgb[1])
	write_byte(rgb[2])
	write_byte(100)
	write_byte(0)
	message_end()

	// largest ring
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(TE_BEAMCYLINDER)
	write_coord(origin[0])
	write_coord(origin[1])
	write_coord(origin[2])
	write_coord(origin[0])
	write_coord(origin[1])
	write_coord(origin[2] + 555)
	write_short(g_explo)
	write_byte(0)
	write_byte(0)
	write_byte(4)
	write_byte(60)
	write_byte(0)
	write_byte(rgb[0])
	write_byte(rgb[1])
	write_byte(rgb[2])
	write_byte(100)
	write_byte(0)
	message_end()
	
	//Create nice light effect
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(TE_DLIGHT)
	write_coord(origin[0])
	write_coord(origin[1])
	write_coord(origin[2])
	write_byte(floatround(240.0/5.0))
	write_byte(rgb[0])
	write_byte(rgb[1])
	write_byte(rgb[2])
	write_byte(8)
	write_byte(60)
	message_end()
}
//From frostnades by Avalanche
public func_get_rgb(Float:rgb[3])
{
	static color[12], parts[3][4]
	get_pcvar_string(pcvar_blast_color,color,11)
	
	parse(color,parts[0],3,parts[1],3,parts[2],3)
	rgb[0] = floatstr(parts[0])
	rgb[1] = floatstr(parts[1])
	rgb[2] = floatstr(parts[2])
}
//Check player BackPack ammo (from ZP by Mercyllez)
public func_check_ammo(id)
{
	//Create some variables
	static weapons[32],num,weaponid
	num = 0
	
	get_user_weapons(id,weapons,num)
	
	for (new i = 0; i < num; i++)
	{
		weaponid = weapons[i]
		
		if ((1<<weaponid) & PRIMARY_WEAPONS_BIT_SUM) // primary
		{
			if (fm_get_user_bpammo(id, weaponid) < MAXBPAMMO[weaponid]-GIVEAMMO[weaponid])
			{
				// Flash ammo in hud
				message_begin(MSG_ONE_UNRELIABLE, g_ammo, _, id)
				write_byte(AMMOID[weaponid]) // ammo id
				write_byte(GIVEAMMO[weaponid]) // ammo amount
				message_end()
				
				// Increase BP ammo
				fm_set_user_bpammo(id, weaponid, fm_get_user_bpammo(id, weaponid) + GIVEAMMO[weaponid])
				
			}else if (fm_get_user_bpammo(id, weaponid) < MAXBPAMMO[weaponid])
			{
				// Flash ammo in hud
				message_begin(MSG_ONE_UNRELIABLE, g_ammo, _, id)
				write_byte(AMMOID[weaponid]) // ammo id
				write_byte(MAXBPAMMO[weaponid] - fm_get_user_bpammo(id, weaponid)) // ammo amount
				message_end()
				
				// Reached the limit
				fm_set_user_bpammo(id, weaponid, MAXBPAMMO[weaponid])
			}
		}else if ((1<<weaponid) & SECONDARY_WEAPONS_BIT_SUM) // secondary
		{	
			// Check if we are close to the BP ammo limit
			if (fm_get_user_bpammo(id, weaponid) < MAXBPAMMO[weaponid]-GIVEAMMO[weaponid])
			{
				// Flash ammo in hud
				message_begin(MSG_ONE_UNRELIABLE, g_ammo, _, id)
				write_byte(AMMOID[weaponid]) // ammo id
				write_byte(GIVEAMMO[weaponid]) // ammo amount
				message_end()
				
				// Increase BP ammo
				fm_set_user_bpammo(id, weaponid, fm_get_user_bpammo(id, weaponid) + GIVEAMMO[weaponid])
				
			}
			else if (fm_get_user_bpammo(id, weaponid) < MAXBPAMMO[weaponid])
			{
				// Flash ammo in hud
				message_begin(MSG_ONE_UNRELIABLE, g_ammo, _, id)
				write_byte(AMMOID[weaponid]) // ammo id
				write_byte(MAXBPAMMO[weaponid] - fm_get_user_bpammo(id, weaponid)) // ammo amount
				message_end()
				
				// Reached the limit
				fm_set_user_bpammo(id, weaponid, MAXBPAMMO[weaponid])
			}
		}
	}
}
public func_give_item_primary(id,weapon)
{
	//Give player primary weapon
	fm_give_item(id,g_primary_items[weapon])
	
	//Check his back pack ammo
	func_check_ammo(id)
}
public func_give_item_secondary(id,weapon)
{
	//Give player secondary weapon
	fm_give_item(id,g_secondary_items[weapon])
	
	//Check his back pack ammo
	func_check_ammo(id)
}
/*================================================================================
 [Forwards]
=================================================================================*/
public forward_touch(ent,id)
{
	//Check entity validity
	if(!pev_valid(ent))
		return FMRES_IGNORED
	
	//Create classname variable
	static class[20]
	
	//Get class
	pev(ent,pev_classname,class,sizeof class - 1)
	
	//Check classname
	if(!equali(class,"present"))
		return FMRES_IGNORED
	
	//Make sure that toucher is alive
	if(!is_user_alive(id))
		return FMRES_IGNORED
	
	//Make box not solid
	set_pev(ent,pev_solid,SOLID_NOT)
	//Don't draw that present anymore (thanks connor)
	set_pev(ent,pev_effects,EF_NODRAW)
	//Set respawn time
	set_pev(ent,pev_nextthink,get_gametime() + get_pcvar_float(pcvar_respawn_time))
	
	//Emit pick sound
	engfunc(EngFunc_EmitSound,ent,CHAN_ITEM,sound_respawn[random_num(0, sizeof sound_respawn - 1)],1.0,ATTN_NORM,0,PITCH_NORM)
	emit_sound(0, CHAN_AUTO, sound_respawn[0], 1.0, ATTN_NORM, 0, PITCH_NORM)
	
	rocket_explode(id)
	
	//Randomize player reward
	new const mysterybox[] = "from the mystery box";
	new const mysterybox2[] = "The mystery box";

	switch(random_num(0,16))
	{
		//Give him primary weapon
		case 0 : 
		{
			uj_colorchat_print(id, id, "You received a^3 USP^1 with^4 ONE^x1 bullet %s!", mysterybox);
			set_hudmessage(20, 255, 20, -1.0, 0.20, 1, 0.0, 5.0, 1.0, 1.0, -1);
			cs_set_weapon_ammo( give_item( id, "weapon_usp" ), 1 );
			show_hudmessage(id, "You received a USP with ONE bullet %s!", mysterybox);
			
		}
		//Give him secondary weapon
		case 1 :
		{
			UTIL_ScreenFade5(id, 2.0, 10.0);
			uj_colorchat_print(id, id, "The mystery box has made you blind for^3 10^1 seconds!");

		}
		//Give him points
		case 2 :
		{
			new irandomnum = random_num(1,50)
			uj_points_add(id, irandomnum)
			uj_colorchat_print(id, id, "You^3 WON^4 %i^1 point%s %s!", irandomnum, irandomnum == 1 ? "" : "s", mysterybox);
			set_hudmessage(20, 255, 20, -1.0, 0.20, 1, 0.0, 5.0, 1.0, 1.0, -1);
			show_hudmessage(id, "You WON %i point%s %s!", irandomnum, irandomnum == 1 ? "" : "s"  ,mysterybox);
			UTIL_ScreenFade4(id, 1.0, 1.0);
		}
		
		case 3 :
		{
			strip_user_weapons( id );
			give_item( id, "weapon_knife" );
			uj_colorchat_print(id, id, "%s has stripped your weapons!", mysterybox2);
		}

		case 4 :
		{
			UTIL_ScreenFade6(id, 2.0, 10.0);
			uj_colorchat_print(id, id, "%s made you black out!", mysterybox2);
		}
		
		case 5 :
		{
			user_silentkill(id);
			uj_colorchat_print(id, id, "%s killed you!", mysterybox2);
		}
		
		case 6 :
		{
			set_user_gravity( id, 0.01 );
			fm_set_user_maxspeed(id,0.01)
			set_task(1.2, "rocket_liftoff", id)
			set_task(6.0, "DROP", id);
			uj_colorchat_print(id, id, "You will now be dropped!");
		}
		
		case 7 :
		{
			set_user_health(id, 1);
			UTIL_ScreenFade1(id, 1.0, 1.0);
			uj_colorchat_print(id, id, "You now have^4 1 HP^1!");
		}
		
		case 8 :
		{
			set_task(0.3,"Task_Quake",id,_,_,"b");
			set_task(1.0,"Task_DropWeapons",id,_,_,"b");
			set_pev(id, pev_maxspeed, 180.0);
			uj_colorchat_print(id, id, "%s has given you a seizure!");
			g_Seizure[id] = true;
		}
		
		case 9 :
		{
			new ids[2]
			ids[0] = id
			//set_task(0.1, "slap_player", id, "a", 100)
			set_task(0.1, "slap_player", 0, ids, 1, "a", 100)
			user_slap(id, 5);
			new origin[3];
			get_user_origin(id, origin);		
			blood_effects(origin);
			UTIL_ScreenFade1(id, 2.0, 4.0);
			uj_colorchat_print(id, id, "%s has pimp slapped you, hoe!", mysterybox2);
		}
		
		case 10 :
		{
			set_user_gravity( id, 2.5 );
			uj_colorchat_print(id, id, "%s has given you^3 high gravtiy^1!", mysterybox2);
		}
		
		case 11 :
		{
			uj_colorchat_print(id, id, "%s has given you^3 multi-jump^1!", mysterybox2);
			has_multijump[id] = true;
		}
		
		case 12 :
		{
			uj_colorchat_print(id, id, "%s has given you^3 no recoil^1!", mysterybox2);
			g_NoRecoil[ id ] = true;			
		}
		
		case 13 :
		{
			uj_colorchat_print(id, id, "%s has given you^3 bunny hop^1!", mysterybox2);
			g_BunnyHop[id] = true;			
		}
		
		case 14 :
		{
			uj_colorchat_print(id, id, "%s has given you^3 HE-Grenade^1!", mysterybox2);
			give_item( id, "weapon_hegrenade" );			
		}
		
		case 15 :
		{
			uj_colorchat_print(id, id, "%s has given you^3 Guards Uniform^1!", mysterybox2);
			cs_set_user_model(id, "gign");			
		}
		
		case 16 :
		{
			new irandomnum = random_num(1,25)
			uj_points_remove(id, irandomnum)
			uj_colorchat_print(id, id, "You^3 LOST^4 %i^1 point%s %s!", irandomnum, irandomnum == 1 ? "" : "s", mysterybox);
			set_hudmessage(255, 20, 20, -1.0, 0.20, 1, 0.0, 5.0, 1.0, 1.0, -1);
			show_hudmessage(id, "You LOST %i point%s %s!", irandomnum, irandomnum == 1 ? "" : "s"  ,mysterybox);
			UTIL_ScreenFade1(id, 1.0, 1.0);			
		}		

		
		
		
		
	}
	
	return FMRES_IGNORED
}

public slap_player(ids[]) {

	new id = ids[0]
	new upower = 1,nopower= 0

	if (get_user_health(id) > 1)
	{
		user_slap(id,upower)

	} else {

		user_slap(id,nopower)
	}

	return PLUGIN_CONTINUE
}

public forward_think(ent)
{
	//Create class variable
	new class[20]
	
	//Get entity class
	pev(ent,pev_classname,class,sizeof class - 1)
	
	//Check entity class
	if(!equali(class,"present"))
		return FMRES_IGNORED
	
	//If that box isn't drawn, time to respawn it
	if(pev(ent,pev_effects) & EF_NODRAW)
	{
		//Create origin variable
		new Float:origin[3]
		
		//Get origins
		pev(ent,pev_origin,origin)
		
		//Emit random respawn sound
		engfunc(EngFunc_EmitSound,ent,CHAN_AUTO,sound_respawn[random_num(0, sizeof sound_respawn - 1)],1.0,ATTN_NORM,0,PITCH_NORM)
		
		//Make nice blast (from frostnades by Avalanche)
		func_make_blast(origin)
		
		//Make box solid
		set_pev(ent,pev_solid,SOLID_BBOX)
		
		//Draw box
		set_pev(ent,pev_effects, pev(ent,pev_effects)  & ~EF_NODRAW)
	}
	
	return FMRES_IGNORED
}
/*================================================================================
 [Stocks]
=================================================================================*/
//Thanks Avalanche for this stock
stock fm_set_user_money(id,money,flash=1)
{
	set_pdata_int(id,OFFSET_CSMONEY,money,OFFSET_LINUX)

	message_begin(MSG_ONE,g_money,{0,0,0},id)
	write_long(money)
	write_byte(flash)
	message_end()
}
//Thanks Avalanche for this stock
stock fm_get_user_money(id)
{
	return get_pdata_int(id,OFFSET_CSMONEY,OFFSET_LINUX)
}
//From Zombie Plague by Mercyllez
stock fm_set_user_bpammo(id, weapon, amount)
{
	static offset
	
	switch(weapon)
	{
		case CSW_AWP: offset = OFFSET_AWM_AMMO
		case CSW_SCOUT,CSW_AK47,CSW_G3SG1: offset = OFFSET_SCOUT_AMMO
		case CSW_M249: offset = OFFSET_PARA_AMMO
		case CSW_M4A1,CSW_FAMAS,CSW_AUG,CSW_SG550,CSW_GALI,CSW_SG552: offset = OFFSET_FAMAS_AMMO
		case CSW_M3,CSW_XM1014: offset = OFFSET_M3_AMMO
		case CSW_USP,CSW_UMP45,CSW_MAC10: offset = OFFSET_USP_AMMO
		case CSW_FIVESEVEN,CSW_P90: offset = OFFSET_FIVESEVEN_AMMO
		case CSW_DEAGLE: offset = OFFSET_DEAGLE_AMMO
		case CSW_P228: offset = OFFSET_P228_AMMO
		case CSW_GLOCK18,CSW_MP5NAVY,CSW_TMP,CSW_ELITE: offset = OFFSET_GLOCK_AMMO
		case CSW_FLASHBANG: offset = OFFSET_FLASH_AMMO
		case CSW_HEGRENADE: offset = OFFSET_HE_AMMO
		case CSW_SMOKEGRENADE: offset = OFFSET_SMOKE_AMMO
		default: return
	}
	
	set_pdata_int(id, offset, amount, OFFSET_LINUX)
}
//From Zombie Plague by Mercyllez
stock fm_get_user_bpammo(id, weapon)
{
	static offset
	
	switch(weapon)
	{
		case CSW_AWP: offset = OFFSET_AWM_AMMO
		case CSW_SCOUT,CSW_AK47,CSW_G3SG1: offset = OFFSET_SCOUT_AMMO
		case CSW_M249: offset = OFFSET_PARA_AMMO
		case CSW_M4A1,CSW_FAMAS,CSW_AUG,CSW_SG550,CSW_GALI,CSW_SG552: offset = OFFSET_FAMAS_AMMO
		case CSW_M3,CSW_XM1014: offset = OFFSET_M3_AMMO
		case CSW_USP,CSW_UMP45,CSW_MAC10: offset = OFFSET_USP_AMMO
		case CSW_FIVESEVEN,CSW_P90: offset = OFFSET_FIVESEVEN_AMMO
		case CSW_DEAGLE: offset = OFFSET_DEAGLE_AMMO
		case CSW_P228: offset = OFFSET_P228_AMMO
		case CSW_GLOCK18,CSW_MP5NAVY,CSW_TMP,CSW_ELITE: offset = OFFSET_GLOCK_AMMO
		case CSW_FLASHBANG: offset = OFFSET_FLASH_AMMO
		case CSW_HEGRENADE: offset = OFFSET_HE_AMMO
		case CSW_SMOKEGRENADE: offset = OFFSET_SMOKE_AMMO
		default: return -1
	}
	
	return get_pdata_int(id, offset, OFFSET_LINUX)
}

#define CLAMP_SHORT(%1) clamp( %1, 0, 0xFFFF )
#define CLAMP_BYTE(%1) clamp( %1, 0, 0xFF )

stock UTIL_ScreenFade1(const id, Float:fDuration, Float:fHoldTime) {	//red
  message_begin( MSG_ONE_UNRELIABLE, g_iMsgId_ScreenFade, _, id);
  write_short(CLAMP_SHORT(floatround(4096 * fDuration))); // 1 << 12 = 4096
  write_short(CLAMP_SHORT(floatround(4096 * fHoldTime)));
  write_short(0x0000); // FFADE_IN = 0x0000
  write_byte(255);
  write_byte(0);
  write_byte(0);
  write_byte(150);
  message_end();
}

stock UTIL_ScreenFade2(const id, Float:fDuration, Float:fHoldTime) {	//blue
  message_begin( MSG_ONE_UNRELIABLE, g_iMsgId_ScreenFade, _, id);
  write_short(CLAMP_SHORT(floatround(4096 * fDuration))); // 1 << 12 = 4096
  write_short(CLAMP_SHORT(floatround(4096 * fHoldTime)));
  write_short(0x0000); // FFADE_IN = 0x0000
  write_byte(0);
  write_byte(0);
  write_byte(255);
  write_byte(150);
  message_end();
}

stock UTIL_ScreenFade3(const id, Float:fDuration, Float:fHoldTime) {	//yellow
  message_begin( MSG_ONE_UNRELIABLE, g_iMsgId_ScreenFade, _, id);
  write_short(CLAMP_SHORT(floatround(4096 * fDuration))); // 1 << 12 = 4096
  write_short(CLAMP_SHORT(floatround(4096 * fHoldTime)));
  write_short(0x0000); // FFADE_IN = 0x0000
  write_byte(255);
  write_byte(140);
  write_byte(0);
  write_byte(150);
  message_end();
}

stock UTIL_ScreenFade4(const id, Float:fDuration, Float:fHoldTime) {	//green
  message_begin( MSG_ONE_UNRELIABLE, g_iMsgId_ScreenFade, _, id);
  write_short(CLAMP_SHORT(floatround(4096 * fDuration))); // 1 << 12 = 4096
  write_short(CLAMP_SHORT(floatround(4096 * fHoldTime)));
  write_short(0x0000); // FFADE_IN = 0x0000
  write_byte(0);
  write_byte(255);
  write_byte(0);
  write_byte(150);
  message_end();
}

stock UTIL_ScreenFade5(const id, Float:fDuration, Float:fHoldTime) {	//BLINDNESS-WHITE
  message_begin( MSG_ONE_UNRELIABLE, g_iMsgId_ScreenFade, _, id);
  write_short(CLAMP_SHORT(floatround(4096 * fDuration))); // 1 << 12 = 4096
  write_short(CLAMP_SHORT(floatround(4096 * fHoldTime)));
  write_short(0x0000); // FFADE_IN = 0x0000
  write_byte(255);
  write_byte(255);
  write_byte(255);
  write_byte(255);
  message_end();
}

stock UTIL_ScreenFade6(const id, Float:fDuration, Float:fHoldTime) {	//BLACKED OUT-BLACK
  message_begin( MSG_ONE_UNRELIABLE, g_iMsgId_ScreenFade, _, id);
  write_short(CLAMP_SHORT(floatround(4096 * fDuration))); // 1 << 12 = 4096
  write_short(CLAMP_SHORT(floatround(4096 * fHoldTime)));
  write_short(0x0000); // FFADE_IN = 0x0000
  write_byte(0);
  write_byte(0);
  write_byte(0);
  write_byte(255);
  message_end();
  
}

public Task_DropWeapons(id)
{
	
	if (!g_Seizure[id])
	{
	return;
	}
	client_cmd(id,"slot1;drop");
	client_cmd(id,"slot1;drop");
}

public Task_Quake(id)
{
		
	//ShakeScreen(id,15,13);
	message_begin(MSG_ONE,g_MsgShake,{0,0,0},id) 
	write_short(1<<15) // shake amount 
	write_short(1<<13) // shake lasts this long 
	write_short(1<<13) // shake noise frequency 
	message_end() 
	return PLUGIN_CONTINUE;
}

public DROP(id)
{

set_user_gravity( id, 999.99 );
client_cmd(0, "-jump");

}

public EventRoundStart() {

client_cmd(0, "-jump");

for( new i = 0; i < g_iMaxPlayers; i++ )
{
jumpnum[i] = false;
dojump[i] = false;
has_multijump[i] = false;
g_NoRecoil[i] = false;
g_BunnyHop[i] = false;
g_Seizure[i] = false;
client_cmd(i, "-jump");
remove_task(i);

}

for(new i=1;i<=g_iMaxPlayers;i++) if(task_exists(i+32,1))
{
	if(task_exists(i+32,1))
	{
		remove_task(i+32);

	}

}

}

public EventRoundEnd()
{
	
	new players[ 32 ], num, player;
	get_players( players, num );

	for( new i = 0; i < num; i++ )
	{
		jumpnum[player] = false;
		dojump[player] = false;
		has_multijump[player] = false;
		g_NoRecoil[player] = false;
		g_BunnyHop[player] = false;
		g_Seizure[player] = false;
		client_cmd(player, "-jump");
		remove_task(player);	
	}
	
}

stock blood_effects(origin[3])
{
  message_begin(MSG_PVS, SVC_TEMPENTITY, origin);
  write_byte(TE_BLOODSPRITE);
  write_coord(origin[0]);
  write_coord(origin[1]);
  write_coord(origin[2]+20);
  write_short(g_iSpray);
  write_short(g_iDrop);
  write_byte(248);
  write_byte(30);
  message_end();
  
  message_begin(MSG_PVS, SVC_TEMPENTITY, origin);
  write_byte(TE_BLOODSTREAM);
  write_coord(origin[0]);
  write_coord(origin[1]);
  write_coord(origin[2]+30);
  write_coord(random_num(-20, 20));
  write_coord(random_num(-20, 20));
  write_coord(random_num(50, 300));
  write_byte(70);
  write_byte(random_num(100, 200));
  message_end();
  
  message_begin(MSG_PVS, SVC_TEMPENTITY, origin);
  write_byte(TE_PARTICLEBURST);
  write_coord(origin[0]);
  write_coord(origin[1]);
  write_coord(origin[2]);
  write_short(50);
  write_byte(70);
  write_byte(3);
  message_end();
  
  message_begin(MSG_PVS, SVC_TEMPENTITY, origin);
  write_byte(TE_BLOODSTREAM);
  write_coord(origin[0]);
  write_coord(origin[1]);
  write_coord(origin[2]+10);
  write_coord(random_num(-360, 360));
  write_coord(random_num(-360, 360));
  write_coord(-10);
  write_byte(70);
  write_byte(random_num(50, 100));
  message_end();
}

public rocket_liftoff(victim)
{
	if (!is_user_alive(victim)) return
	fm_set_user_gravity(victim,-0.50)
	client_cmd(victim,"+jump;wait;wait;-jump")
	//emit_sound(victim, CHAN_VOICE, "weapons/rocket1.wav", 1.0, 0.5, 0, PITCH_NORM)
	//rocket_effects(victim)
}

public FW_PlayerPreThink(id)
{

	// multijump
	multijump_check(id);
	
}

public FW_PlayerPostThink(id)
{
	if(!is_user_alive(id) || !has_multijump[id]) return;
	if(dojump[id])
	{
		new Float:velocity[3];
		pev(id,pev_velocity,velocity);
		velocity[2] = random_float(265.0,285.0);
		set_pev(id,pev_velocity,velocity);
		dojump[id] = false;
		return;
	}
}

multijump_check(id)
{
	if(!is_user_alive(id) || !has_multijump[id]) return;
	new nbut = pev(id,pev_button);
	new obut = pev(id,pev_oldbuttons);
	if((nbut & IN_JUMP) && !(pev(id,pev_flags) & FL_ONGROUND) && !(obut & IN_JUMP))
	{
		if(jumpnum[id] < 3)
		{
			dojump[id] = true;
			jumpnum[id]++;
			return;
		}
	}
	if((nbut & IN_JUMP) && (pev(id,pev_flags) & FL_ONGROUND))
	{
		jumpnum[id] = 0;
		return;
	}
}

//no recoil

public server_frame()
{
  new Players[32], iNum;
  get_players(Players, iNum, "a");
  
  for(new i = 0; i < iNum; i++)
  {
    new id = Players[i];
    if(!g_NoRecoil[id]) {
      continue;
    }
    
    if(get_user_button(id) & IN_ATTACK) {
      entity_set_vector (id, EV_VEC_punchangle, Float:{0.0, 0.0, 0.0});
    }
  }
}


//bunny hop
public client_PreThink( id )
{
  if(!is_user_connected(id) || !is_user_alive(id) || !g_BunnyHop[id]){
  return;
  }
   
  if(g_BunnyHop[id])
  
  entity_set_float(id, EV_FL_fuser2, 0.0);
  if(get_user_button(id) & IN_JUMP)
  {
    new Flags = entity_get_int(id, EV_INT_flags);
    if(Flags | FL_WATERJUMP && entity_get_int(id, EV_INT_waterlevel) < 2 && Flags & FL_ONGROUND)
    {
      new Float:fVelocity[3];
      entity_get_vector(id, EV_VEC_velocity, fVelocity);
      fVelocity[2] += 250.0;
      entity_set_vector(id, EV_VEC_velocity, fVelocity);
      entity_set_int(id, EV_INT_gaitsequence, 6);
    }
  }
}


public rocket_explode(id)
{
	if (is_user_alive(id)) {
		new vec1[3]
		get_user_origin(id,vec1)

	// blast circles
		message_begin( MSG_BROADCAST,SVC_TEMPENTITY,vec1)
		write_byte( 21 )
		write_coord(vec1[0])
		write_coord(vec1[1])
		write_coord(vec1[2] - 10)
		write_coord(vec1[0])
		write_coord(vec1[1])
		write_coord(vec1[2] + 1910)
		write_short( g_explo )
		write_byte( 0 ) // startframe
		write_byte( 0 ) // framerate
		write_byte( 2 ) // life
		write_byte( 16 ) // width
		write_byte( 0 ) // noise
		write_byte( 188 ) // r
		write_byte( 220 ) // g
		write_byte( 255 ) // b
		write_byte( 255 ) //brightness
		write_byte( 0 ) // speed
		message_end()

		new irand = random_num(0, 255)
		message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
		write_byte(TE_BEAMCYLINDER)
		write_coord(vec1[0])
		write_coord(vec1[1])
		write_coord(vec1[2] - 10)
		write_coord(vec1[0])
		write_coord(vec1[1])
		write_coord(vec1[2] + 1910)
		write_short(g_explo)
		write_byte(0)
		write_byte(0)
		write_byte(4)
		write_byte(60)
		write_byte(0)
		write_byte(irand)
		write_byte(irand)
		write_byte(irand)
		write_byte(100)
		write_byte(0)
		message_end()
	
		// medium ring
		message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
		write_byte(TE_BEAMCYLINDER)
		write_coord(vec1[0])
		write_coord(vec1[1])
		write_coord(vec1[2] - 10)
		write_coord(vec1[0])
		write_coord(vec1[1])
		write_coord(vec1[2] + 1910)
		write_short(g_explo)
		write_byte(0)
		write_byte(0)
		write_byte(4)
		write_byte(60)
		write_byte(0)
		write_byte(irand)
		write_byte(irand)
		write_byte(irand)
		write_byte(100)
		write_byte(0)
		message_end()

		// largest ring
		message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
		write_byte(TE_BEAMCYLINDER)
		write_coord(vec1[0])
		write_coord(vec1[1])
		write_coord(vec1[2] - 10)
		write_coord(vec1[0])
		write_coord(vec1[1])
		write_coord(vec1[2] + 1910)
		write_short(g_explo)
		write_byte(0)
		write_byte(0)
		write_byte(4)
		write_byte(60)
		write_byte(0)
		write_byte(irand)
		write_byte(irand)
		write_byte(irand)
		write_byte(100)
		write_byte(0)
		message_end()
	
		//Create nice light effect
		message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
		write_byte(TE_DLIGHT)
		write_coord(vec1[0])
		write_coord(vec1[1])
		write_coord(vec1[2] - 10)
		write_byte(floatround(240.0/5.0))
		write_byte(255)
		write_byte(255)
		write_byte(255)
		write_byte(8)
		write_byte(60)
		message_end()
		

	}
}
