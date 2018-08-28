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


new const PLUGIN_NAME[] = "[UJ] Item - Multi-Jump";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

new const ITEM_NAME[] = "Multi-Jump";
new const ITEM_MESSAGE[] = "Who said white men can't jump?";
new const ITEM_COST[] = "45";
new const ITEM_REBEL[] = "0";

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
new jumpnum[33], bool:dojump[33];

public plugin_init()
{
  register_plugin(PLUGIN_NAME, PLUGIN_VERS, PLUGIN_AUTH);

  // Register CVars
  g_costCVar = register_cvar("uj_item_multijump_cost", ITEM_COST);
  g_rebelCVar = register_cvar("uj_item_multijump_rebel", ITEM_REBEL);

  // Register this item
  g_item = uj_items_register(ITEM_NAME, ITEM_MESSAGE, g_costCVar, g_rebelCVar);

  // Find the menu that item should appear in
  g_shopMenu = uj_menus_get_menu_id("Shop Menu");
  
  register_forward(FM_PlayerPreThink, "FW_PlayerPreThink"); //multi jump
  register_forward(FM_PlayerPostThink, "FW_PlayerPostThink"); //multi jump  
  
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

public FW_PlayerPostThink(playerID)
{
	if(!is_user_alive(playerID) || !get_bit(g_hasItem, playerID)) return;
	if(dojump[playerID])
	{
		new Float:velocity[3];
		pev(playerID,pev_velocity,velocity);
		velocity[2] = random_float(265.0,285.0);
		set_pev(playerID,pev_velocity,velocity);
		dojump[playerID] = false;
		return;
	}
}

multijump_check(playerID)
{
	if(!is_user_alive(playerID) || !get_bit(g_hasItem, playerID)) return;
	new nbut = pev(playerID,pev_button);
	new obut = pev(playerID,pev_oldbuttons);
	if((nbut & IN_JUMP) && !(pev(playerID,pev_flags) & FL_ONGROUND) && !(obut & IN_JUMP))
	{
		if(jumpnum[playerID] < 3)
		{
			dojump[playerID] = true;
			jumpnum[playerID]++;
			return;
		}
	}
	if((nbut & IN_JUMP) && (pev(playerID,pev_flags) & FL_ONGROUND))
	{
		jumpnum[playerID] = 0;
		return;
	}
}

public FW_PlayerPreThink(playerID)
{
  
  if (!is_user_alive(playerID)) return;
  
  // multijump
  multijump_check(playerID);
}

public client_disconnect(playerID)
{

	remove_item(playerID);

}

public client_putinserver(playerID)
{

	remove_item(playerID)

}
