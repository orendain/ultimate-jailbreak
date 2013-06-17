#include <amxmodx>
#include <cstrike>
#include <uj_core>
#include <uj_effects>
#include <uj_menus>
#include <uj_items>
#include <uj_colorchat>

#define EMP_HIDE_FLAGS 		(1<<0)|(1<<1)|(1<<3)|(1<<4)|(1<<5)  // hide in order: CAL + FLASH + RHA + TIMER + MONEY
#define HIDE_NORMAL 	(1<<1)|(1<<4)|(1<<5) // Flashlight, Timer, Money
#define EMP_TIMER 30.0

#define TEAM_T  1
#define TEAM_CT 2

new gEMPEffect[] = "Allied_Gamers/emp_effect.wav";


new gmsgScreenFade, gmsgHideWeapon;

new const PLUGIN_NAME[] = "[UJ] Item - EMP";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

new const ITEM_NAME[] = "EMP";
new const ITEM_MESSAGE[] = "Enemy electronics are offline";
new const ITEM_COST[] = "25";
new const ITEM_REBEL[] = "false";

// Menu variables
new g_shopMenu;
new g_item;

// Common CVars
new g_costCVar;
new g_rebelCVar;

// Item-specific CVars
//none

// emp stuff

new bool:g_isemped[3];
new g_EMPCaller;
new g_hasEMP;

enum (+= 5000)
{

	//UAVTERROR_TASK,
	//UAVCOUNTER_TASK,
	EMPEFFECTS_TASK,
	EMPTEAM_TASK
};

public plugin_init()
{
  register_plugin(PLUGIN_NAME, PLUGIN_VERS, PLUGIN_AUTH);

  // Register CVars
  g_costCVar = register_cvar("uj_item_invisibility_cost", ITEM_COST);
  g_rebelCVar = register_cvar("uj_item_invisibility_rebel", ITEM_REBEL);

  // Register this item
  g_item = uj_items_register(ITEM_NAME, ITEM_MESSAGE, g_costCVar, g_rebelCVar);

  // Find the menu that item should appear in
  g_shopMenu = uj_menus_get_menu_id("Shop Menu");
  
  gmsgScreenFade = get_user_msgid("ScreenFade");

  gmsgHideWeapon = get_user_msgid("HideWeapon");
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
  if (get_bit(g_hasEMP, playerID)) {
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

  //give and call
  cmdCallEMP(playerID);
  client_cmd(0, "spk %s", gEMPEffect);
  set_bit(g_hasEMP, playerID);
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
  
  remove_EMP(playerID);
  
}

remove_EMP(playerID)
{
  // We don't strip the user of his/her nades
  if (get_bit(g_hasEMP, playerID)) {
    remove_task(1+EMPTEAM_TASK);
    remove_task(2+EMPTEAM_TASK);
    clear_bit(g_hasEMP, playerID);
  }
}


public plugin_precache()
{
	
	precache_sound(gEMPEffect);
	
	
}

public plugin_end(){
	
	remove_task(1+EMPTEAM_TASK);
	remove_task(2+EMPTEAM_TASK);
  
}

public cmdCallEMP(id)
{
	switch(cs_get_user_team(id))
	{
		case CS_TEAM_T:
		{
			g_isemped[TEAM_CT] = true;
			
			set_task(EMP_TIMER, "task_RemoveEMP", TEAM_CT+EMPTEAM_TASK);
		}
		case CS_TEAM_CT:
		{
			g_isemped[TEAM_T] = true;
			
			set_task(EMP_TIMER, "task_RemoveEMP", TEAM_T+EMPTEAM_TASK);
		}
	}
	
	g_EMPCaller = get_user_team(id);
	
	set_hudmessage(240, 240, 0, -1.0, 0.40, 0, 0.1, 2.5, 0.02, 0.02, 2);
	show_hudmessage(id, "EMP LAUNCHED");
	
	new idname[35];
	get_user_name(id,idname,34);
	client_print(0, print_chat, "[AG] EMP called in by %s", idname);
	
	client_cmd(0, "spk %s", gEMPEffect);
	
	
	new Players[32];
	new playerCount, i;
	get_players(Players, playerCount, "c");
	for (i=0; i<playerCount; i++)
	{ 
		task_SetEMPEffects(Players[i]);
	}
}

public task_SetEMPEffects(id)
{
	if (g_EMPCaller && get_user_team(id) != g_EMPCaller)
	{
		
		set_hud_flags(id, EMP_HIDE_FLAGS);
		message_begin(MSG_ONE, gmsgHideWeapon, _, id);
		write_byte(72);
		message_end();
		
		new Float:fadetime, Float:holdtime;
		fadetime = EMP_TIMER;
		holdtime = EMP_TIMER;
			
		new fade, hold;
		fade = clamp(floatround(fadetime * float(1<<12)), 0, 0xFFFF);
		hold = clamp(floatround(holdtime * float(1<<12)), 0, 0xFFFF);
			
		message_begin(MSG_ONE,gmsgScreenFade,{0,0,0},id);
		write_short( fade ); 
		write_short( hold );
		write_short( 1<<12 );
		write_byte( 255 ); 
		write_byte( 255 ); 
		write_byte( 255 ); 
		write_byte( 75 ); 
		message_end();
	}
	else
	{
		message_begin(MSG_ONE,gmsgScreenFade,{0,0,0},id); 
		write_short( 1<<12 ); 
		write_short( 1<<10 );
		write_short( 1<<12 );
		write_byte( 255 ); 
		write_byte( 255 ); 
		write_byte( 255 ); 
		write_byte( 195 ); 
		message_end();	
	}
}

public task_RemoveEMP(taskteam)
{
	taskteam-=EMPTEAM_TASK;
	set_hud_flags(taskteam, HIDE_NORMAL);
	
	g_isemped[taskteam] = false;
	g_EMPCaller = 0;
	
	message_begin(MSG_BROADCAST, gmsgHideWeapon);
	write_byte(0);
	message_end();
	
	message_begin(MSG_BROADCAST,gmsgScreenFade); 
	write_short( 1<<12 ); 
	write_short( 1<<10 );
	write_short( 1<<12 );
	write_byte( 255 ); 
	write_byte( 255 );
	write_byte( 255 ); 
	write_byte( 0 ); 
	message_end();	
}

// hide weapon
stock set_hud_flags(id, iFlags)
{
	message_begin(MSG_ONE, gmsgHideWeapon, _, id);
	write_byte(iFlags);
	message_end();
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
