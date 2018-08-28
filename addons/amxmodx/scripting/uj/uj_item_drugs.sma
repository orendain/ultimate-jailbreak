#include <amxmodx>
#include <cstrike>
#include <uj_core>
#include <uj_effects>
#include <uj_menus>
#include <uj_items>
#include <fg_colorchat>

new const PLUGIN_NAME[] = "UJ | Item - Drugs";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

new const ITEM_NAME[] = "Grand Daddy's Drugs";
new const ITEM_MESSAGE[] = "Turnt Up!";
new const ITEM_COST[] = "50";
new const ITEM_REBEL[] = "0";

new const ITEM_MAXSPEED[] = "1.3";

// Menu variables
new g_menuShop;
new g_item;

// Common CVars
new g_costCVar;
new g_rebelCVar;

// Keep track of who this item
new g_hasItem;
new g_maxSpeed;
new gmsg_SetFOV;

public plugin_init()
{
  register_plugin(PLUGIN_NAME, PLUGIN_VERS, PLUGIN_AUTH);

  // Register CVars
  g_costCVar = register_cvar("uj_item_drugs_cost", ITEM_COST);
  g_rebelCVar = register_cvar("uj_item_drugs_rebel", ITEM_REBEL);
  g_maxSpeed = register_cvar("uj_item_drugs_speed", ITEM_MAXSPEED);

  // Register this item
  g_item = uj_items_register(ITEM_NAME, ITEM_MESSAGE, g_costCVar, g_rebelCVar);

  // Find the menu that item should appear in
  g_menuShop = uj_menus_get_menu_id("Shop Menu");

  gmsg_SetFOV = get_user_msgid("SetFOV");
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

  give_item(playerID);
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

give_item(playerID)
{
  if (!get_bit(g_hasItem, playerID)) {
    set_bit(g_hasItem, playerID);

    message_begin(MSG_ONE, gmsg_SetFOV, { 0, 0, 0 }, playerID);
    write_byte(180);
    message_end();
    uj_effects_reset_max_speed(playerID);
  }
  return PLUGIN_HANDLED;
}

remove_item(playerID)
{
  // We don't strip the user of his/her armor
  if (get_bit(g_hasItem, playerID)) {
    clear_bit(g_hasItem, playerID);
    uj_effects_reset_max_speed(playerID);
  }
}


/*
 * Called when determining a player's max speed
 */
public uj_effects_determine_max_speed(playerID, data[])
{
  if (get_bit(g_hasItem, playerID)) {
    // Need to first cast data[0] as a Float
    new Float:result = float(data[0]);
    result *= get_pcvar_float(g_maxSpeed);
    data[0] = floatround(result);
  }
}
