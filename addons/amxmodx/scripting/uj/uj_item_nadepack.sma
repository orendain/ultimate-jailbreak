#include <amxmodx>
#include <fun>
#include <uj_core>
#include <uj_menus>
#include <uj_items>
#include <fg_colorchat>

new const PLUGIN_NAME[] = "UJ | Item - Nade Pack";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

new const ITEM_NAME[] = "Nade Pack";
new const ITEM_MESSAGE[] = "Nades primed and ready!";
new const ITEM_COST[] = "10";
new const ITEM_REBEL[] = "0";

// Menu variables
new g_menuShop;
new g_item;

// Common CVars
new g_costCVar;
new g_rebelCVar;

// Keep track of who has a nadepack
new g_hasNadePack;

public plugin_init()
{
  register_plugin(PLUGIN_NAME, PLUGIN_VERS, PLUGIN_AUTH);

  // Register CVars
  g_costCVar = register_cvar("uj_item_nadepack_cost", ITEM_COST);
  g_rebelCVar = register_cvar("uj_item_nadepack_rebel", ITEM_REBEL);

  // Register this item
  g_item = uj_items_register(ITEM_NAME, ITEM_MESSAGE, g_costCVar, g_rebelCVar);

  // Find the menu that item should appear in
  g_menuShop = uj_menus_get_menu_id("Shop Menu");
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
  if (menuID != g_menuShop) {
    return UJ_ITEM_DONT_SHOW;
  }
  
  // Disable if player already has this item
  if (get_bit(g_hasNadePack, playerID)) {
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

  give_nadepack(playerID);
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

  remove_nadepack(playerID);
}

give_nadepack(playerID)
{
  if (!get_bit(g_hasNadePack, playerID)) {
    set_bit(g_hasNadePack, playerID);

    // Give the player full nades
    give_item(playerID, "weapon_hegrenade");
    //give_item(playerID, "weapon_smokegrenade");
    give_item(playerID, "weapon_flashbang");
    give_item(playerID, "weapon_flashbang");
  }
  return PLUGIN_HANDLED;
}

remove_nadepack(playerID)
{
  // We don't strip the user of his/her nades
  if (get_bit(g_hasNadePack, playerID)) {
    clear_bit(g_hasNadePack, playerID);
  }
}
