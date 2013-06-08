#if defined _uj_items_included
  #endinput
#endif
#define _uj_items_included

#include <uj_items_const>
 
#if AMXX_VERSION_NUM >= 175 
  #pragma reqlib uj_items
  #if !defined AMXMODX_NOAUTOLOAD
    #pragma loadlib uj_items
  #endif
#else
  #pragma library uj_itemsa
#endif


/**
 * Registers an item for use.
 *
 * @param name        Item name
 * @param costCVar    CVar: Cost of the item
 * @param rebelCVar   CVar: Whethor or not this item is a rebel item
 *
 * @return            An internal item ID, or UJ_ITEM_INVALID on failure.
 */
native uj_items_register(const name[], costCVar, rebelCVar);

/**
 * Find out if an item is a rebel item or not.
 *
 * @param itemID    An internal item ID.
 *
 * @return          True, false or UJ_ITEM_INVALID if not found.
 */
native uj_items_get_rebel(itemID);

/**
 * Find an item's ID by item name.
 *
 * @param name    Item name to look for.
 *
 * @return        Internal item ID, or UJ_ITEM_INVALID if not found.
 */
native uj_items_get_id(const name[]);

/**
 * Returns an item's name.
 *
 * @param itemID  A valid item ID.
 * @param name    The buffer to store the name in.
 * @param len     Character size of the output buffer.
 *
 * @return        True on success, false otherwise.
 */
native uj_items_get_name(itemID, name[], len);

/**
 * Returns an item's cost.
 *
 * @param itemID    An internal item ID.
 *
 * @return          Item's cost.a
 */
native uj_items_get_cost(itemID);

/**
 * Forces a player to buy an item.
 *
 * @param playerID      Player index
 * @param itemID        An item ID
 * @param ignoreCost    If true, item's cost won't be deducted from player.
 *
 * @return              True on success, false otherwise.
 */
native uj_items_force_buy(playerID, itemID, ignoreCost = false);

/**
 * Remove item from specified player.
 *
 * @param playerID      Player to strip of item(s), 0 for all players
 * @param itemID        Item to strip from player(s), or UJ_ITEM_ALL_ITEMS for all items
 */
native uj_items_strip_item(playerID, itemID);

/**
 * Appends text to an item being displayed on the items menu.
 * Use this on the item select pre forward.
 *
 * @param text    Additional text to display.
 */
native uj_items_menu_text_add(const text[]);


/**
 * Forwards
 */

/**
 * Called when determining whether an item should be available to a player.
 *
 * Possible return values are:
 *  - UJ_ITEM_AVAILABLE (show in menu, allow selection)
 *  - UJ_ITEM_NOT_AVAILABLE (show in menu, don't allow selection)
 *  - UJ_ITEM_DONT_SHOW (don't show in menu, don't allow selection)
 *
 * @param playerID    Player index.
 * @param itemID      The item's ID
 * @param menuID      The menu the item is attempting to be displayed in.
 */
forward uj_fw_items_select_pre(playerID, itemID, menuID);

/**
 * Called after a player selected an item from a menu.
 *a
 * @param playerID    Player index.
 * @param itemID      The item's ID
 * @param menuID      The menu the item was selected in
 */
forward uj_fw_items_select_post(playerID, itemID, menuID);

/**
 * Called when the item should be removed from a player.
 *
 * @param playerID    Player index.
 * @param itemID      The item's ID, or UJ_ITEM_ALL_ITEMS for all items
 */
forward uj_fw_items_strip_item(playerID, itemID);
