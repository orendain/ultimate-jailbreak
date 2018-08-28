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

new const PLUGIN_NAME[] = "[UJ] Item - Jetpack";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

new const ITEM_NAME[] = "Jetpack";
new const ITEM_MESSAGE[] = "Fly birdie,fly!";
new const ITEM_COST[] = "40";
new const ITEM_REBEL[] = "0";

new gJetSprite;

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
  
  RegisterHam( Ham_Player_Jump, "player", "bacon_playerJumping" );
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
	set_task(2.5, "rocket_effects", playerID);
	set_task(10.0, "resetjetpack", playerID);

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

public rocket_effects(playerID)
{
  if (get_bit(g_hasItem, playerID))
  
  //emit_sound(id, CHAN_ITEM, JETPACKFLIGHT, 1.0, ATTN_NORM, 0, PITCH_NORM);  
  set_task(2.5, "rocket_effects", playerID);
}


public bacon_playerJumping( playerID )
{
  /* --| If plugin is on, and user has jetpack item */
  if (get_bit(g_hasItem, playerID))
  {
    /* --| Get user origins from feet */
    new iOrigin[ 3 ];
    get_user_origin( playerID, iOrigin, 0 );
    
    /* --| Modify origin a bit */
    iOrigin[ 2 ] -= 20;
    
    /* --| Get player velocity */
    new Float:fVelocity[ 3 ];
    pev( playerID, pev_velocity, fVelocity );
    
    /* --| Modify velocity a bit */
    fVelocity[ 2 ] += 13;
    
    /* --| Set the player velocity and add a flame effect, jetpack style */
    set_pev( playerID, pev_velocity, fVelocity );
    create_flame( iOrigin );  
  }
} 

stock create_flame( origin[ 3 ] )
{
  message_begin( MSG_PVS, SVC_TEMPENTITY, origin );
  write_byte( TE_SPRITE );
  write_coord( origin[ 0 ] );
  write_coord( origin[ 1 ] );
  write_coord( origin[ 2 ] );
  write_short( gJetSprite );
  write_byte( 3 );
  write_byte( 99 );
  message_end();
}

public resetjetpack( playerID )
{
  remove_item(playerID)
  uj_colorchat_print(playerID, playerID, "Your^x03 Jetpack^x01 has expired." );
  //emit_sound(0, CHAN_ITEM, JETPACKOFF, 1.0, ATTN_NORM, 0, PITCH_NORM);
}

public plugin_precache()
{
	
	 gJetSprite = precache_model( "sprites/explode1.spr" );
	
}