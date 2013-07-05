#include <amxmodx>
#include <uj_core>
#include <uj_effects>
#include <uj_menus>
#include <uj_items>
#include <uj_colorchat>
#include <engine>

new const PLUGIN_NAME[] = "[UJ] Item - Cut Power";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

new const ITEM_NAME[] = "Cut-off Power";
new const ITEM_MESSAGE[] = "Now they see you, now they don't.";
new const ITEM_COST[] = "30";
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
new g_hasCutPower;

public plugin_init()
{
  register_plugin(PLUGIN_NAME, PLUGIN_VERS, PLUGIN_AUTH);

  // Register CVars
  g_costCVar = register_cvar("uj_item_cutpower_cost", ITEM_COST);
  g_rebelCVar = register_cvar("uj_item_cutpower_rebel", ITEM_REBEL);

  // Register this item
  g_item = uj_items_register(ITEM_NAME, ITEM_MESSAGE, g_costCVar, g_rebelCVar);

  // Find the menu that item should appear in
  g_shopMenu = uj_menus_get_menu_id("Shop Menu");
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
  if (get_bit(g_hasCutPower, playerID)) {
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

  give_cutpower(playerID);
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

  remove_cutpower(playerID);
}

give_cutpower(playerID)
{
	if (!get_bit(g_hasCutPower, playerID)) {
    // Find transparency level

    // Glow user and set bit
	set_bit(g_hasCutPower, playerID);
	set_hudmessage(255, 20, 20, -1.0, 0.20, 1, 0.0, 5.0, 1.0, 1.0, -1);
	show_hudmessage(0, "The main power has been cut. We are trying to repair it..!");
	set_lights("a");
	remove_task(4567);
	set_task(7.0, "light_reset", 4567);
  }
	return PLUGIN_HANDLED;
}

remove_cutpower(playerID)
{
  // If the user is glowed, remove glow and clear bit
  if (get_bit(g_hasCutPower, playerID)) {
    clear_bit(g_hasCutPower, playerID);
  }
}

public light_reset(){
	set_lights("#OFF");
	set_hudmessage(255, 255, 255, -1.0, 0.20, 1, 0.0, 5.0, 1.0, 1.0, -1);
	show_hudmessage(0, "The power has been restored!");
}
