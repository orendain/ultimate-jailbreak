#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta>
#include <dhudmessage>
#include <uj_core>
#include <uj_effects>
#include <uj_menus>
#include <uj_items>
#include <uj_colorchat>

new const PLUGIN_NAME[] = "[UJ] Item - Portable Cameras";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

new const ITEM_NAME[] = "Portable Cameras";
new const ITEM_MESSAGE[] = "Home Security at its finest.";
new const ITEM_COST[] = "20";
new const ITEM_REBEL[] = "0";

// Menu variables
new g_shopMenu;
new g_item;

// Common CVars
new g_costCVar;
new g_rebelCVar;

// Item-specific CVars
new camera[33]
new Float:origin[33][3]
new bool:in_camera[33]
new fire
new health
new delround
new camera_speed

// Keep track of who has invisibility
new g_hasItem;

public plugin_init()
{
	register_plugin(PLUGIN_NAME, PLUGIN_VERS, PLUGIN_AUTH);
	
	// Register CVars
	g_costCVar = register_cvar("uj_item_camera_cost", ITEM_COST);
	g_rebelCVar = register_cvar("uj_item_camera_rebel", ITEM_REBEL);
	
	// Register this item
	g_item = uj_items_register(ITEM_NAME, ITEM_MESSAGE, g_costCVar, g_rebelCVar);
	
	// Find the menu that item should appear in
	g_shopMenu = uj_menus_get_menu_id("Shop Menu");
	
	register_forward(FM_PlayerPreThink, "fw_PlayerPreThink")
	//register_clcmd("drop","addcm")
	register_clcmd("amx_viewcamera","viewcm")
	register_clcmd("amx_deletecamera","deletecm")
	//register_clcmd("drop","cmmenu")
	new keys = MENU_KEY_0|MENU_KEY_1|MENU_KEY_2|MENU_KEY_3
	register_menucmd(register_menuid("Camera Menu"), keys, "menuProc")
	register_event("HLTV","nRound","a","1=0","2=0")
	register_cvars()
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
	cmmenu( playerID )
	uj_colorchat_print(playerID, playerID, "Press ^4[E]-'Use'^1 to open the ^3camera menu^1")
	set_hudmessage(255, 0, 0, -1.0, -1.0, 0, 6.0, 4.0)
	show_hudmessage(playerID, "Press your [USE] key to open the camera menu")	
	
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
delete_camera( playerID )
return PLUGIN_CONTINUE

}

public client_putinserver(playerID)
{

remove_item(playerID)

}

public nRound()
{
	for(new i=0;i<33;i++)
	{
		return_view(i)
		if(get_pcvar_num(delround))
			delete_camera(i)
	}
	
	return PLUGIN_HANDLED
}

public menuProc(playerID,key)
{
	if (key == 0)
	{
		addcm( playerID )
		cmmenu( playerID )
	} else if (key == 1) {
		viewcm( playerID )
		cmmenu( playerID )
	} else if (key == 2) {
		deletecm( playerID )
		cmmenu( playerID )
	}
	return PLUGIN_CONTINUE
}

public cmmenu(playerID)
{
	if(!get_bit(g_hasItem, playerID))
	{
		return PLUGIN_HANDLED
	}
	
	else
	{
		
	new menu[192]
	new keys = MENU_KEY_0|MENU_KEY_1|MENU_KEY_2|MENU_KEY_3
	format(menu, 191, "[AG] Camera Menu^n^n1. Create Camera^n2. View Camera^n3. Delete Camera^n^n0. Exit")
	show_menu(playerID,keys,menu)
	}
	return PLUGIN_HANDLED
}

public addcm( playerID )
{
	create_camera( playerID )
	return PLUGIN_CONTINUE
}

public viewcm( playerID )
{
	if(view_camera( playerID ))
	{
		set_hudmessage(255, 0, 0, -1.0, -1.0, 0, 6.0, 4.0)
		show_hudmessage(playerID, "Press your [USE] key to exit camera view.")
	}
	return PLUGIN_CONTINUE
}

public deletecm( playerID )
{
	delete_camera( playerID )
	return PLUGIN_HANDLED
}

public client_connect( playerID )
{
	delete_camera( playerID )
	return PLUGIN_CONTINUE
}

public plugin_precache()
{
	fire = precache_model("sprites/explode1.spr")
	precache_model("models/ultimate_jailbreak/camera.mdl")
}

public client_PreThink(playerID)
{

	if(camera[playerID] && !is_valid_ent(camera[playerID]))
	{
		camera[playerID]=0
		in_camera[playerID]=false
		create_explosion(floatround(origin[playerID][0]),floatround(origin[playerID][1]),floatround(origin[playerID][2]),5,0)
		//client_print(id,print_chat,"[AG] BOOM! Someone blew up your camera.")
		uj_colorchat_print(playerID, playerID, "Your camera has been destroyed!")
	}
	else if(in_camera[playerID])
	{
		new Float:velocity[3]
		set_user_velocity(playerID,velocity)

		new buttons = get_user_button(playerID)

		if(buttons & IN_USE)
		{
			return_view(playerID)
		}

		else
		{
			new Float:v_angle[3], Float:angles[3]
			entity_get_vector(camera[playerID],EV_VEC_angles,angles)
			entity_get_vector(camera[playerID],EV_VEC_v_angle,v_angle)
			if(buttons & IN_FORWARD)
			{
				v_angle[0] -= get_pcvar_float(camera_speed)
				angles[0] -= get_pcvar_float(camera_speed)
				if(v_angle[0]<-89.0) v_angle[1] = 89.0
				if(angles[0]<-89.0) angles[1] = 89.0
			}
			if(buttons & IN_BACK)
			{
				v_angle[0] += get_pcvar_float(camera_speed)
				angles[0] += get_pcvar_float(camera_speed)
				if(v_angle[0]>89.0) v_angle[1] = -89.0
				if(angles[0]>89.0) angles[1] = -89.0
			}
			if(buttons & IN_MOVELEFT || buttons & IN_LEFT)
			{
				v_angle[1] += get_pcvar_float(camera_speed)
				angles[1] += get_pcvar_float(camera_speed)
				if(v_angle[1]>179.0) v_angle[1] = -179.0
				if(angles[1]>179.0) angles[1] = -179.0
			}
			if(buttons & IN_MOVERIGHT || buttons & IN_RIGHT)
			{
				v_angle[1] -= get_pcvar_float(camera_speed)
				angles[1] -= get_pcvar_float(camera_speed)
				if(v_angle[1]<-179.0) v_angle[1] = 179.0
				if(angles[1]<-179.0) angles[1] = 179.0
			}
			entity_set_vector(camera[playerID],EV_VEC_angles,angles)
			entity_set_vector(camera[playerID],EV_VEC_v_angle,v_angle)

		}
	}
	return PLUGIN_CONTINUE
}


stock register_cvars()
{
	health = register_cvar("camera_health","1")
	camera_speed = register_cvar("camera_speed","3")
	delround = register_cvar("camera_deleteround","1")
}

stock create_camera(playerID)
{
	if(!is_user_alive(playerID))
	{
		//client_print(id,print_chat,"[AG] You can't create a camera while you are dead.")
		uj_colorchat_print(playerID, playerID, "You can't create a camera while you are dead.")
		return 0;
	}
	
	if(delete_camera(playerID))
		//client_print(id,print_chat,"[AG] Your old camera was deleted and new camera spawned.")
		uj_colorchat_print(playerID, playerID, "Your old camera was deleted and new camera spawned.")
	new Float:v_angle[3], Float:angles[3]
	entity_get_vector(playerID,EV_VEC_origin,origin[playerID])
	entity_get_vector(playerID,EV_VEC_v_angle,v_angle)
	entity_get_vector(playerID,EV_VEC_angles,angles)

	new ent = create_entity("info_target")

	entity_set_string(ent,EV_SZ_classname,"JJG75_Camera")

	entity_set_int(ent,EV_INT_solid,SOLID_BBOX)
	entity_set_int(ent,EV_INT_movetype,MOVETYPE_FLY)
	entity_set_edict(ent,EV_ENT_owner,playerID)
	entity_set_model(ent,"models/camera.mdl")
	entity_set_float(ent,EV_FL_health,get_pcvar_float(health))
	if(get_pcvar_num(health) == 1)
		entity_set_float(ent,EV_FL_takedamage,0.0)
	else
		entity_set_float(ent,EV_FL_takedamage,1.0)

	new Float:mins[3]
	mins[0] = -5.0
	mins[1] = -10.0
	mins[2] = -5.0

	new Float:maxs[3]
	maxs[0] = 5.0
	maxs[1] = 10.0
	maxs[2] = 5.0

	entity_set_size(ent,mins,maxs)

	entity_set_origin(ent,origin[playerID])
	entity_set_vector(ent,EV_VEC_v_angle,v_angle)
	entity_set_vector(ent,EV_VEC_angles,angles)

	camera[playerID] = ent

	return 1;
}


stock view_camera(playerID)
{
	if(!is_user_alive(playerID))
	{
		//client_print(id,print_chat,"[AG] You can't view your camera while you're dead.")
		uj_colorchat_print(playerID, playerID, "You can't view your camera while you're dead.")
		return 0;
	}
	
	if(is_valid_ent(camera[playerID]))
	{
		attach_view(playerID,camera[playerID])
		in_camera[playerID]=true
		return 1;
	}
	return 0;
}

stock return_view(playerID)
{
	if(!in_camera[playerID])
	{
		return 0;
	}
	in_camera[playerID]=false
	attach_view(playerID,playerID)
	return 1;
}

stock delete_camera(playerID)
{
	if(is_valid_ent(camera[playerID]))
	{
		if(in_camera[playerID])
		{
			return_view(playerID)
			in_camera[playerID]=false
		}
		create_explosion(floatround(origin[playerID][0]),floatround(origin[playerID][1]),floatround(origin[playerID][2]),5,0)
		remove_entity(camera[playerID])
		return 1;
	}
	camera[playerID] = 0
	return 0;
}

stock create_explosion(origin0,origin1,origin2,size,flags)
{
	new origina[3]
	origina[0]=origin0
	origina[1]=origin1
	origina[2]=origin2
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY,origina) 
	write_byte( 3 ) 
	write_coord(origina[0])	// start position
	write_coord(origina[1])
	write_coord(origina[2])
	write_short( fire )
	write_byte( size ) // byte (scale in 0.1's) 188
	write_byte( 10 ) // byte (framerate)
	write_byte( flags ) // byte flags (4 = no explode sound)
	message_end()
}

public fw_PlayerPreThink(playerID)
{
	if (!is_user_alive(playerID))
	return FMRES_IGNORED
	
	new button = get_user_button(playerID)
	new oldbutton = get_user_oldbutton(playerID)
	//static buttons, oldbuttons;
	//buttons = get_uc(uc_handle, UC_Buttons);
	
	if (get_bit(g_hasItem, playerID))
	{
		//if(g_bind_use[id])
		//{
			if (!(oldbutton & IN_USE) && (button & IN_USE))
				cmmenu( playerID )
			
			//if (!(oldbutton & IN_RELOAD) && (button & IN_RELOAD))
				//cmmenu(id)
		//}
	}
	
	return PLUGIN_CONTINUE
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
