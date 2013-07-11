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

#define REGEN_MAXHP 160.0
#define REGEN_TIMER 2.0
#define REGEN_AMOUNT 3.0		// self heal
#define StartHP 100.0
#define REGEN_AMOUNTOTHERS 2.0
#define REGEN_DISTANCE 200.0

new const PLUGIN_NAME[] = "[UJ] Item - Health Regeneration";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

new const ITEM_NAME[] = "Health Regeneration";
new const ITEM_MESSAGE[] = "You will heal over time whenever you receive damage.";
new const ITEM_COST[] = "25";
new const ITEM_REBEL[] = "0";

new g_iMaxPlayers;

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
  g_costCVar = register_cvar("uj_item_healthregen_cost", ITEM_COST);
  g_rebelCVar = register_cvar("uj_item_healthregen_rebel", ITEM_REBEL);

  // Register this item
  g_item = uj_items_register(ITEM_NAME, ITEM_MESSAGE, g_costCVar, g_rebelCVar);

  // Find the menu that item should appear in
  g_shopMenu = uj_menus_get_menu_id("Shop Menu");
  
  g_iMaxPlayers   = get_maxplayers();
  
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
	set_task(REGEN_TIMER,"Task_HPRegenLoop",playerID,_,_,"b");

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


public Task_HPRegenLoop(playerID)
{
	//new aData[ GangInfo ];
	//ArrayGetArray( g_aGangs, g_iGang[ id ], aData );
	new Float: NewHP;
	//new iHealth = 100 + aData[ GangHP ] * get_pcvar_num( g_pHealthPerLevel );
	new iHealth = 100;
	
	if(entity_get_float(playerID, EV_FL_health) < iHealth) 
	{
		NewHP = entity_get_float(playerID, EV_FL_health) + REGEN_AMOUNT;
	
		if(NewHP >= REGEN_MAXHP) // If user regened to much HP. We set the MAXHP
			NewHP = REGEN_MAXHP;
		entity_set_float(playerID, EV_FL_health,NewHP);
	}
	
	new Team = get_user_team(playerID);

	for(new i=1;i<=g_iMaxPlayers;i++) if(get_user_team(i) == Team && is_user_alive(i) && i != playerID && entity_range(playerID,i) <= REGEN_DISTANCE)
	{
		NewHP = entity_get_float(i, EV_FL_health) + REGEN_AMOUNTOTHERS;
		
		if(NewHP >= StartHP) // If user regened to much HP. We set the MAXHP
			NewHP = StartHP;

		entity_set_float(i, EV_FL_health,NewHP);
	}
	return PLUGIN_CONTINUE;
}
