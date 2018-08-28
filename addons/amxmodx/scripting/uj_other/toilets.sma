#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <fakemeta_util>
#include <cstrike>
#include <engine>
#include <fun>
#include <uj_colorchat>
#include <uj_points>
#include <uj_core>
#include <uj_effects>



/*================================================================================
 [Plugin Customization]
=================================================================================*/

//Models and sounds are randomly chosen, add as many, as you want

//new g_iMsgId_ScreenFade;
//new g_MsgShake;
new g_iMaxPlayers;

new bool: toiletnew;
new g_Regen[33];

//new SUITUP[] = "toiletflush.wav";
new REJECT_SOUND[] = "buttons/button2.wav";

//new const model_present[][] = { "models/invisible.mdl" }
new const model_present[][] = { "sprites/null.spr" }


//new const sound_respawn[][] = { "mysterybox/respawn.wav", "present/respawn2.wav" }

//Pcvar variables		
new pcvar_on,pcvar_respawn_time,pcvar_blast,pcvar_blast_color;

//Version information
new const VERSION[] = "2.01"

public plugin_init()
{
	register_plugin("Toilets", VERSION, "Vick")
	pcvar_on = register_cvar("toilets_on","1")
	
	//Make sure that the plugin is on
	if(!get_pcvar_num(pcvar_on))
		return
	
	//Register dictionary
	register_dictionary("toilets.txt")
	
	register_forward(FM_PlayerPreThink, "FW_PlayerPreThink"); //multi jump
	register_forward(FM_PlayerPostThink, "FW_PlayerPostThink"); //multi jump

	
	//Register admin commands
	register_clcmd("say !toilet","func_add_present")
	register_clcmd("say !remtoilet","func_remove_present")
	register_clcmd("say !remalltoilet","func_remove_present_all")
	register_clcmd("say !savetoilet","func_save_origins")
	register_clcmd("say !rotatetoilet","func_rotate_present")
		
	//Some forwards
	register_forward(FM_Touch,"forward_touch")
	register_forward(FM_Think,"forward_think")
	register_forward(FM_CmdStart, "fw_start", 1);
	
	register_logevent("EventRoundStart", 2, "1=Round_Start");
	register_logevent("EventRoundEnd", 2, "1&Restart_Round");
	register_logevent("EventRoundEnd", 2, "1=Game_Commencing");
	register_logevent("EventRoundEnd", 2, "1=Round_End");	
		
	//Cvars register
	pcvar_respawn_time = register_cvar("toilet_respawn_time","5.0")
	pcvar_blast = register_cvar("toilet_blast","1")
	pcvar_blast_color = register_cvar("toilet_blast_color","255 255 255")
		
	//Other stuff
	//g_iMsgId_ScreenFade   = get_user_msgid("ScreenFade");
	//g_MsgShake = get_user_msgid("ScreenShake");
	g_iMaxPlayers   = get_maxplayers();
}
public plugin_precache()
{
	new i
	
	for(i = 0; i < sizeof model_present; i++)
		engfunc(EngFunc_PrecacheModel,model_present[i])
	
	/*for (i = 0; i < sizeof sound_respawn; i++)
		engfunc(EngFunc_PrecacheSound, sound_respawn[i])
	*/
	
	//precache_sound(SUITUP);
	precache_sound(REJECT_SOUND);
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
	formatex(sFile, sizeof sFile - 1, "%s/toilets/%s_toilets_origins.cfg", sConfigsDir, sMapName)
	
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
		log_to_file("toilets.log","[%s] has created a present on map %s",name,map)
		
		//Finally spawn mysterybox
		func_spawn(fOrigin)
		toiletnew = true;
		
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
		if(!strcmp(classname, "toilet", 1))
		{
			//Get user name and map name for log creating
			get_user_name(id,name,sizeof name - 1)
			get_mapname(map,sizeof map - 1)
			
			//Create log file or log admin command
			log_to_file("toilets.log","[%s] has removed a toilet from map %s",name,map)
			
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
	while((ent = fm_find_ent_by_class(ent,"toilet")))
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
	log_to_file("toilets.log","[%s] has removed all toilets from map %s",name,map)
	
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
	formatex(sFile, sizeof sFile - 1, "%s/toilets/%s_toilet_origins.cfg", sConfigsDir, sMapName)
	
	//If file already exist, delete file
	if(file_exists(sFile))
		delete_file(sFile)
	
	//Some variables
	new iEnt = -1, Float:fEntOrigin[3], Float:fEntAngles[3], iCount
	static sBuffer[256]
	
	//Find boxes on this map
	while((iEnt = engfunc(EngFunc_FindEntityByString, iEnt, "classname", "toilet")))
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
	log_to_file("toilets.log","[%s] has saved a toilet on map %s",name,map)
	
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
		if(!strcmp(sClassname, "toilet", 1))
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
			log_to_file("toilets.log","[%s] has rotated a toilet on map %s",name,map)
			
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
	set_pev(ent,pev_classname,"toilet")
	
	//Set entity origins
	engfunc(EngFunc_SetOrigin,ent,origin)
	
	//Create blast effect
	func_make_blast(origin)
	toiletnew = true;
	
	//Emit spawn sound
	//engfunc(EngFunc_EmitSound,ent,CHAN_AUTO,sound_respawn[random_num(0, sizeof sound_respawn - 1)],1.0,ATTN_NORM,0,PITCH_NORM)
	//emit_sound(0, CHAN_AUTO, sound_respawn[0], 1.0, ATTN_NORM, 0, PITCH_NORM)
	
	//size variables
	//static Float:fMaxs[3] = { 2.0, 2.0, 4.0 }
	//static Float:fMins[3] = { -2.0, -2.0, -4.0 }
	//static Float:fMaxs[3] = {16.0,16.0,36.0}
	//static Float:fMins[3] = {-16.0,-16.0,-36.0}	
	
	static Float:fMaxs[3] = {8.0,8.0,8.0}
	static Float:fMins[3] = {-8.0,-8.0,-8.0}
	
	
		
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
	
/*================================================================================
 [Forwards]
=================================================================================
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
	if(!equali(class,"locker"))
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
	//engfunc(EngFunc_EmitSound,ent,CHAN_ITEM,sound_respawn[random_num(0, sizeof sound_respawn - 1)],1.0,ATTN_NORM,0,PITCH_NORM)
	//emit_sound(0, CHAN_AUTO, sound_respawn[0], 1.0, ATTN_NORM, 0, PITCH_NORM)
		
	//Randomize player reward
	if (!lockernew)
	{
		uj_colorchat_print(id, id, "Sorry, this locker is empty");
		emit_sound(id, CHAN_ITEM, REJECT_SOUND, 1.0, ATTN_NORM, 0, PITCH_NORM);
	}
	else

	switch(random_num(0,1))
	{
		//Give him primary weapon
		case 0 : 
		{
			uj_colorchat_print(id, id, "Sorry, this locker is empty");
			lockernew = false;
			
		}
		//Give him secondary weapon
		case 1 :
		{
			new model[32];
			cs_get_user_model(id, model, charsmax(model));
    
			if (equali(model, "gign"))
			{
			uj_colorchat_print(id, id, "Sorry, you already own a^3 Guards Uniform^1!");
			emit_sound(id, CHAN_ITEM, REJECT_SOUND, 1.0, ATTN_NORM, 0, PITCH_NORM);
			}
			else
			{
			uj_colorchat_print(id, id, "You found a^3 Guards Uniform^1");
			emit_sound(id, CHAN_ITEM, SUITUP, 1.0, ATTN_NORM, 0, PITCH_NORM);
			cs_set_user_model(id, "gign");
			lockernew = false;
			}
		}
		
	}
	
	return FMRES_IGNORED
}

*/

public forward_think(ent)
{
	//Create class variable
	new class[20]
	
	//Get entity class
	pev(ent,pev_classname,class,sizeof class - 1)
	
	//Check entity class
	if(!equali(class,"toilet"))
		return FMRES_IGNORED
	
	//If that box isn't drawn, time to respawn it
	if(pev(ent,pev_effects) & EF_NODRAW)
	{
		//Create origin variable
		new Float:origin[3]
		
		//Get origins
		pev(ent,pev_origin,origin)
		
		//Emit random respawn sound
		//engfunc(EngFunc_EmitSound,ent,CHAN_AUTO,sound_respawn[random_num(0, sizeof sound_respawn - 1)],1.0,ATTN_NORM,0,PITCH_NORM)
		
		//Make nice blast (from frostnades by Avalanche)
		func_make_blast(origin)
		
		//Make box solid
		set_pev(ent,pev_solid,SOLID_BBOX)
		
		//Draw box
		set_pev(ent,pev_effects, pev(ent,pev_effects)  & ~EF_NODRAW)
	}
	
	return FMRES_IGNORED
}

public fw_start(const id, const uc_handle)
{
	if (!is_user_alive(id))
		return FMRES_IGNORED;
		
	static ent, body
	get_user_aiming(id, ent, body)

	static buttons, oldbuttons;
	buttons = get_uc(uc_handle, UC_Buttons);
	if (buttons)
	{
		oldbuttons = pev(id, pev_oldbuttons);
			
		if (buttons & IN_USE && ~oldbuttons & IN_USE && (pev_valid(ent)))
		{
			//Check entity classname
			static classname[32]
			pev(ent, pev_classname, classname, sizeof classname - 1)
		
	
			//Player is aiming at box
			if(!strcmp(classname, "toilet", 1))
			{
			
			if (!toiletnew)
			{
				uj_colorchat_print(id, id, "Gross! This toilet is full of feces.");
				emit_sound(id, CHAN_ITEM, REJECT_SOUND, 1.0, ATTN_NORM, 0, PITCH_NORM);
			}
			else
		
			switch(random_num(0,7))
			{
				//
				case 0 : 
				{
					uj_colorchat_print(id, id, "Gross! This toilet is full of feces.");
					emit_sound(id, CHAN_ITEM, REJECT_SOUND, 1.0, ATTN_NORM, 0, PITCH_NORM);
					toiletnew = false;
					
				}
				//
				case 1 :
				{

					cs_set_weapon_ammo( give_item( id, "weapon_usp" ), 11 );
					uj_colorchat_print(id, id, "Aw yeah! You found a dirty^3 usp^1 in the toilet.");
					toiletnew = false;
					set_pev(ent,pev_effects,EF_NODRAW)
					
					//Set respawn time
					set_pev(ent,pev_nextthink,get_gametime() + get_pcvar_float(pcvar_respawn_time))						
				
				}
				
				case 2 : 
				{
					uj_colorchat_print(id, id, "Gross! This toilet is full of feces.");
					emit_sound(id, CHAN_ITEM, REJECT_SOUND, 1.0, ATTN_NORM, 0, PITCH_NORM);
					toiletnew = false;
					
				}
				
				case 3 : 
				{
					uj_colorchat_print(id, id, "Gross! This toilet is full of feces.");
					emit_sound(id, CHAN_ITEM, REJECT_SOUND, 1.0, ATTN_NORM, 0, PITCH_NORM);
					toiletnew = false;
					
				}
				
				case 4 : 
				{
					uj_colorchat_print(id, id, "Gross! This toilet is full of feces.");
					emit_sound(id, CHAN_ITEM, REJECT_SOUND, 1.0, ATTN_NORM, 0, PITCH_NORM);
					toiletnew = false;
					
				}
				
				case 5 :
				{

					give_item(id, "weapon_hegrenade");
					uj_colorchat_print(id, id, "Aw yeah! You found a dirty^3 HE-Grenade^1 in the toilet.");
					toiletnew = false;
					set_pev(ent,pev_effects,EF_NODRAW)
					
					//Set respawn time
					set_pev(ent,pev_nextthink,get_gametime() + get_pcvar_float(pcvar_respawn_time))						
				
				}
				
				case 6 :
				{
					cs_set_weapon_ammo( give_item( id, "weapon_tmp" ), 30 );
					give_item( id, "weapon_tmp" );
					uj_colorchat_print(id, id, "Aw yeah! You found a dirty^3 TMP^1 in the toilet.");
					toiletnew = false;
					set_pev(ent,pev_effects,EF_NODRAW)
					
					//Set respawn time
					set_pev(ent,pev_nextthink,get_gametime() + get_pcvar_float(pcvar_respawn_time))						
				
				}
				
				case 7 :
				{

					uj_colorchat_print(id, id, "Nasty! This toilet has made you sick. You will now die slowly.");
					toiletnew = false;
					g_Regen[id] = true;
					
					set_task(1.0,"Task_HPRegenLoop",id,_,_,"b");
					set_pev(ent,pev_effects,EF_NODRAW)
					
					//Set respawn time
					set_pev(ent,pev_nextthink,get_gametime() + get_pcvar_float(pcvar_respawn_time))						
				
				}				
				
				
			}			
			
			
			
			

			}
		}	
	}
	return FMRES_IGNORED;
}

// health regen

public Task_HPRegenLoop(id)
{

user_slap(id, 5)
	
}

public EventRoundStart() {

for( new i = 0; i < g_iMaxPlayers; i++ )
{

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

		remove_task(player);	
	}
	
	
	for(new i=1;i<=g_iMaxPlayers;i++) if(task_exists(i+32,1))
	{
		if(task_exists(i+32,1))
		{
			remove_task(i+32);
	
		}
	
	}
	
	
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
