#include <amxmodx>
#include <uj_core>
#include <uj_effects>
#include <uj_menus>
#include <uj_items>
#include <uj_colorchat>

new const PLUGIN_NAME[] = "[UJ] Item - Invisibility";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

new const ITEM_NAME[] = "Invisibility";
new const ITEM_MESSAGE[] = "Now to decide ... escape ... or surprise attack?";
new const ITEM_COST[] = "60";
new const ITEM_REBEL[] = "true";

new const INVISIBILITY_ALPHA[] = "20";

// Menu variables
new g_shopMenu;
new g_item;

// Common CVars
new g_costCVar;
new g_rebelCVar;

// Item-specific CVars
new g_alphaCVar;

// Keep track of who has invisibility
new g_hasInvisibility;

public plugin_init()
{
  register_plugin(PLUGIN_NAME, PLUGIN_VERS, PLUGIN_AUTH);

  // Register CVars
  g_costCVar = register_cvar("uj_item_invisibility_cost", ITEM_COST);
  g_rebelCVar = register_cvar("uj_item_invisibility_rebel", ITEM_REBEL);
  g_alphaCVar = register_cvar("uj_item_invisibility_alpha", INVISIBILITY_ALPHA);

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
  if (get_bit(g_hasInvisibility, playerID)) {
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

  give_invisibility(playerID);
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

  remove_invisibility(playerID);
}

give_invisibility(playerID)
{
  if (!get_bit(g_hasInvisibility, playerID)) {
    // Find transparency level
    new alpha = get_pcvar_num(g_alphaCVar);

    // Glow user and set bit
    uj_effects_glow_player(playerID, 0, 0, 0, alpha);
    set_bit(g_hasInvisibility, playerID);
  }
  return PLUGIN_HANDLED;
}

remove_invisibility(playerID)
{
  // If the user is glowed, remove glow and clear bit
  if (get_bit(g_hasInvisibility, playerID)) {
    uj_effects_glow_reset(playerID);
    clear_bit(g_hasInvisibility, playerID);
  }
}
