#include <amxmodx> 
#include <fun> 
#include <amxmisc> 
#include <engine> 
#include <fakemeta_util>
#include <hamsandwich>
#include <cstrike>
#include <dhudmessage>
#include <uj_core>
#include <uj_effects>
#include <uj_menus>
#include <uj_items>
#include <uj_colorchat>

new const PLUGIN_NAME[] = "[UJ] Item - Air Strike";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

new const ITEM_NAME[] = "Air Strike";
new const ITEM_MESSAGE[] = "Just tell us where and we will take out those fat pigs.";
new const ITEM_COST[] = "80";
new const ITEM_REBEL[] = "0";

new ExploSpr, cache_spr_line;

new strike_dam, strike_mode, strike_radius;


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
  register_clcmd("drop", "call_strike") 
  register_concmd("give_airstrike", "give_strike", ADMIN_BAN, "<name/@all> gives an airstrike to the spcified target")
 
  strike_mode = register_cvar("airstrike_mode", "1")
  strike_dam = register_cvar("airstrike_damage", "5000.0")
  strike_radius = register_cvar("airstrike_radius", "500.0") 
  
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

public plugin_precache()
{


 precache_sound("ambience/siren.wav") 
 precache_sound("ambience/jetflyby1.wav")
 precache_sound("weapons/airstrike_explosion.wav")
 precache_model("models/rpgrocket.mdl") 
 ExploSpr = precache_model("sprites/fexplo.spr") 
 cache_spr_line = precache_model("sprites/laserbeam.spr")


}

public give_strike(playerID,level,cid)
{
	if (!cmd_access(playerID,level,cid,1)) 
	{
		console_print(playerID,"You have no access to that command");
		return;
	}
	if (read_argc() > 2) 
	{
		console_print(playerID,"Too many arguments supplied.");
		return;
	}
	
	new arg1[32];
	read_argv(1, arg1, sizeof(arg1) - 1);
	new player = cmd_target(playerID, arg1, 10);
	
	if ( !player ) 
	{
		if ( arg1[0] == '@' ) 
		{
			for ( new i = 1; i <= 32; i++ ) 
			{
				if ( is_user_connected(i) && !get_bit(g_hasItem, playerID)) 
				{
					give_shopitem(playerID)
					emit_sound(playerID, CHAN_WEAPON, "items/gunpickup2.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
					uj_colorchat_print(playerID, playerID, "Air Strike ready. Press [G] while holding your knife to call and set the coordinates!");

				}
			}
		} 
		else 
		{
			client_print(playerID, print_center, "[ZP] No Such Player/Team");
			return;
		}
	} 
	else if ( !get_bit(g_hasItem, playerID)) 
	{
		give_shopitem(playerID);
		emit_sound(playerID, CHAN_WEAPON, "items/gunpickup2.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		uj_colorchat_print(playerID, playerID, "Air Strike ready. Press [G] while holding your knife to call and set the coordinates!");

	}
}

public call_strike(playerID) 
{

       if(!get_bit(g_hasItem, playerID) || get_user_weapon(playerID) != CSW_KNIFE) 
         return;

         
       static Float:origin[3]

       fm_get_aim_origin(playerID, origin)

       new bomb = create_entity("info_target")   

       entity_set_string(bomb, EV_SZ_classname, "Bomb") // set name
       entity_set_edict(bomb, EV_ENT_owner, playerID) // set owner
       entity_set_origin(bomb, origin) // start posistion 
        
       line(origin)

       emit_sound(playerID,CHAN_AUTO, "ambience/siren.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)  

       remove_item(playerID);

       set_task(5.0, "stop_siren")
       set_task(6.0, "jet_sound", playerID)
 
       set_task(6.0, "make_bomb", playerID)
       set_task(7.0, "removebomb", playerID)



}

public make_bomb(playerID)
{
        
       new ent

       ent  = find_ent_by_class(-1,"Bomb")

       static Float:origin[3]
       pev(ent, pev_origin, origin)  

       CRT_explosion(origin)
       emit_sound(ent, CHAN_WEAPON, "weapons/mortarhit.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
       emit_sound(ent, CHAN_VOICE, "weapons/mortarhit.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM); 

       for (new i = 1; i < get_maxplayers(); i++)
       {

         shake_screen(i) 

         if(is_user_alive(i) && entity_range(i, ent) <= get_pcvar_float(strike_radius) && cs_get_user_team(playerID) != cs_get_user_team(i))
           {

             if(get_pcvar_num(strike_mode) == 1)
             {        
               ExecuteHam(Ham_TakeDamage, i, 0, playerID, get_pcvar_float(strike_dam), DMG_BULLET)		
             }

             else

             {
               ExecuteHam(Ham_Killed, i, 0, playerID)                
  
             } 


           }

       }


}
  
public stop_siren()
{


 client_cmd(0,"stopsound") // stops sound on all clients 



}

public jet_sound(playerID)
{


 emit_sound(playerID,CHAN_AUTO, "ambience/jetflyby1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
 


}

public removebomb(playerID)
{

   new ent = find_ent_by_class(-1,"Bomb")
   remove_entity(ent)



}

public line(const Float:origin[3])
{
       engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, origin, 0)
       write_byte(TE_BEAMPOINTS)	// temp entity event
       engfunc(EngFunc_WriteCoord, origin[0]) // x
       engfunc(EngFunc_WriteCoord, origin[1]) // y
       engfunc(EngFunc_WriteCoord, origin[2]) // z
       engfunc(EngFunc_WriteCoord, origin[0]) // x axis
       engfunc(EngFunc_WriteCoord, origin[1]) // y axis
       engfunc(EngFunc_WriteCoord, origin[2]+36.0) // z axis
       write_short(cache_spr_line)	// sprite index
       write_byte(0)			// start frame
       write_byte(0)			// framerate
       write_byte(60)			// life in 0.1's
       write_byte(15)			// line width in 0.1's
       write_byte(0)			// noise amplitude in 0.01's
       write_byte(0)		        // color: red
       write_byte(200)		        // color: green
       write_byte(0)		        // color: blue
       write_byte(200)			// brightness
       write_byte(0)			// scroll speed in 0.1's
       message_end() 
 
}

public CRT_explosion(const Float:origin[3])
{

                new NonFloatEndOrigin[3];
		NonFloatEndOrigin[0] = floatround(origin[0]);
		NonFloatEndOrigin[1] = floatround(origin[1]);
		NonFloatEndOrigin[2] = floatround(origin[2]); 


                message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
		write_byte(17);
		write_coord(NonFloatEndOrigin[0]);
		write_coord(NonFloatEndOrigin[1]);
		write_coord(NonFloatEndOrigin[2] + 100);
		write_short(ExploSpr);
		write_byte(30);
		write_byte(255);
		message_end();

                message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
		write_byte(17);
		write_coord(NonFloatEndOrigin[0] + 120);
		write_coord(NonFloatEndOrigin[1] + 70);
		write_coord(NonFloatEndOrigin[2] + 100);
		write_short(ExploSpr);
		write_byte(30);
		write_byte(255);
		message_end();

                message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
		write_byte(17);
		write_coord(NonFloatEndOrigin[0] + 120);
		write_coord(NonFloatEndOrigin[1] - 70);
		write_coord(NonFloatEndOrigin[2] + 100);
		write_short(ExploSpr);
		write_byte(30);
		write_byte(255);
		message_end();

                message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
		write_byte(17);
		write_coord(NonFloatEndOrigin[0] - 120);
		write_coord(NonFloatEndOrigin[1] - 70);
		write_coord(NonFloatEndOrigin[2] + 100);
		write_short(ExploSpr);
		write_byte(30);
		write_byte(255);
		message_end();

                message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
		write_byte(17);
		write_coord(NonFloatEndOrigin[0] - 120);
		write_coord(NonFloatEndOrigin[1] + 70);
		write_coord(NonFloatEndOrigin[2] + 100);
		write_short(ExploSpr);
		write_byte(30);
		write_byte(255);
		message_end();

                message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
		write_byte(17);
		write_coord(NonFloatEndOrigin[0] + 70);
		write_coord(NonFloatEndOrigin[1] + 120);
		write_coord(NonFloatEndOrigin[2] + 100);
		write_short(ExploSpr);
		write_byte(30);
		write_byte(255);
		message_end();

                message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
		write_byte(17);
		write_coord(NonFloatEndOrigin[0] + 70);
		write_coord(NonFloatEndOrigin[1] - 120);
		write_coord(NonFloatEndOrigin[2] + 100);
		write_short(ExploSpr);
		write_byte(30);
		write_byte(255);
		message_end();

                message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
		write_byte(17);
		write_coord(NonFloatEndOrigin[0] - 70);
		write_coord(NonFloatEndOrigin[1] - 120);
		write_coord(NonFloatEndOrigin[2] + 100);
		write_short(ExploSpr);
		write_byte(30);
		write_byte(255);
		message_end();

                message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
		write_byte(17);
		write_coord(NonFloatEndOrigin[0] - 70);
		write_coord(NonFloatEndOrigin[1] + 120);
		write_coord(NonFloatEndOrigin[2] + 100);
		write_short(ExploSpr);
		write_byte(30);
		write_byte(255);
		message_end();

}

stock shake_screen(playerID)
{
	message_begin(MSG_ONE, get_user_msgid("ScreenShake"),{0,0,0}, playerID)
	write_short(255<< 14 ) //ammount 
        write_short(10 << 14) //lasts this long 
        write_short(255<< 14) //frequency 
	message_end()	
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
