#if defined _uj_menus_included
  #endinput
#endif
#define _uj_menus_included

#include <uj_menus_const>

#if AMXX_VERSION_NUM >= 175 
  #pragma reqlib uj_menus
  #if !defined AMXMODX_NOAUTOLOAD
    #pragma loadlib uj_menus
  #endif
#else
  #pragma library uj_menus
#endif


/**
 * Registers a custom menu which will be added to the menu of UJ.
 *
 * @param name      Name of the menu
 *
 * @return          An internal, unique, menu ID, or UJ_MENU_INVALID on failure.
 */
native uj_menus_register_menu(const name[]);

/**
 * Registers a custom menu entry which will be added to the items menu of UJ.
 *
 * @param name      Name of the entry
 *
 * @return          An internal, unique, entry ID, or UJ_MENU_INVALID on failure.
 */
native uj_menus_register_entry(const name[]);

/**
 * Append text to the end of the next menu entry that will be processed.
 *
 * @param text        The additional text to append to the end of the menu entry
 */
native uj_menus_add_text(const text[]);

/**
 * Find a menuID given a menu name
 *
 * @param name    Menu name to look for.
 *
 * @return        Internal entry ID, or UJ_MENU_INVALID if not found.
 */
native uj_menus_get_menu_id(const name[]);

/**
 * Returns a menu entry ID given a menu entry name.
 *
 * @param name    Menu entry name to look for.
 *
 * @return        Internal entry ID, or UJ_MENU_INVALID if not found.
 */
native uj_menus_get_entry_id(const name[]);

/**
 * Display a menu to the specified player.
 *
 * @param playerID    Player index.
 * @param menuID      A menu ID
 *
 * @noreturn
 */
native uj_menus_show_menu(playerID, menuID);


/**
 * Forwards
 */

/**
 * Called when determining whether a menu entry should be available to a player.
 *
 * Possible return values are:
 *  - UJ_MENU_AVAILABLE (show in menu, allow selection)
 *  - UJ_MENU_NOT_AVAILABLE (show in menu, don't allow selection)
 *  - UJ_MENU_DONT_SHOW (don't show in menu, don't allow selection)
 *
 * @param playerID    Player index.
 * @param menuID     Internal menu ID of the menu this entry is trying to appear under
 * @param entryID    Internal menu entry ID.
 *
 * @noreturn
 */
forward uj_fw_menus_select_pre(playerID, menuID, entryID);

/**
 * Called after a player selects an entry from a menu.
 *
 * @param playerID    Player index.
 * @param menuID      Internal menu ID of the menu this entry was under
 * @param entryID     Internal menu entry ID.
 *
 * @noreturn
 */
forward uj_fw_menus_select_post(playerID, menuID, entryID);
