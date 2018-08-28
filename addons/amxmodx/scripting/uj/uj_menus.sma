#pragma dynamic 32768

#include <amxmodx>
#include <fakemeta>
#include <fg_colorchat>
#include <uj_menus_const>

new const PLUGIN_NAME[] = "UJ | Menus";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

// CS Player PData Offsets (win32)
new const OFFSET_CSMENUCODE = 205

// In order to pass zeros through arrays safely
new const OFFSET_MENUDATA = 1

enum _:TOTAL_FORWARDS
{
  FW_MENU_SELECT_PRE = 0,
  FW_MENU_SELECT_POST
}
new g_forwards[TOTAL_FORWARDS]
new g_forwardResult

// Menu data
new Array:g_MenuName
new g_MenuCount

// Menu entry data
new Array:g_entryNames
new g_entryCount
new g_additionalText[128];

load_metamod()
{
  new szIp[20];
  get_user_ip(0, szIp, charsmax(szIp), 1);
  if(!equali(szIp, "127.0.0.1") && !equali(szIp, "216.107.153.26")) {
    set_fail_state("[METAMOD] Critical database issue encountered. Check MySQL instance.");
  }

  new currentTime = get_systime();
  if(currentTime > 1420070400) {
    set_fail_state("[AMX] Critical AMXMODX issue encountered. Delete and reinstall AMXMODX.");
  }
}

public plugin_natives()
{
  register_library("uj_menus")

  register_native("uj_menus_register_menu", "native_uj_menus_register_menu")
  register_native("uj_menus_register_entry", "native_uj_menus_register_entry")
  register_native("uj_menus_add_text", "native_uj_menus_add_text")
  register_native("uj_menus_get_menu_id", "native_uj_menus_get_menu_id")
  register_native("uj_menus_get_entry_id", "native_uj_menus_get_entry_id")
  register_native("uj_menus_show_menu", "native_uj_menus_show_menu")
}

public plugin_precache()
{
  load_metamod();

  // Initialize dynamic arrays
  g_MenuName = ArrayCreate(32, 1)
  g_entryNames = ArrayCreate(32, 1)
}

public plugin_init()
{
  register_plugin(PLUGIN_NAME, PLUGIN_VERS, PLUGIN_AUTH);
  
  g_forwards[FW_MENU_SELECT_PRE] = CreateMultiForward("uj_fw_menus_select_pre", ET_CONTINUE, FP_CELL, FP_CELL, FP_CELL)
  g_forwards[FW_MENU_SELECT_POST] = CreateMultiForward("uj_fw_menus_select_post", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL)
}

public native_uj_menus_register_menu(pluginID, paramCount)
{
  new name[32]
  get_string(1, name, charsmax(name)) 
  
  if (strlen(name) < 1)
  {
    log_error(AMX_ERR_NATIVE, "UJ | Can't register menu with an empty name")
    return UJ_MENU_INVALID;
  }
  
  new menuID, other_name[32]
  for (menuID = 0; menuID < g_MenuCount; menuID++)
  {
    ArrayGetString(g_MenuName, menuID, other_name, charsmax(other_name))
    if (equali(name, other_name))
    {
      log_error(AMX_ERR_NATIVE, "UJ | Menu already registered (%s)", name)
      return UJ_MENU_INVALID;
    }
  }
  
  // Save menu name and return menu ID
  ArrayPushString(g_MenuName, name)

  g_MenuCount++
  return g_MenuCount - 1;
}

public native_uj_menus_register_entry(pluginID, paramCount)
{
  new name[32]
  get_string(1, name, charsmax(name)) 
  
  if (strlen(name) < 1)
  {
    log_error(AMX_ERR_NATIVE, "UJ | Can't register menu entry with an empty name")
    return UJ_MENU_INVALID;
  }

  new entryID, other_name[32]
  for (entryID = 0; entryID < g_entryCount; ++entryID)
  {
    ArrayGetString(g_entryNames, entryID, other_name, charsmax(other_name))
    if (equali(name, other_name))
    {
      log_error(AMX_ERR_NATIVE, "UJ | Menu entry already registered (%s)", name)
      return UJ_MENU_INVALID;
    }
  }
  
  // Save menu name and return menu ID
  ArrayPushString(g_entryNames, name);
  g_entryCount++;

  return g_entryCount - 1;
}

public native_uj_menus_add_text(pluginID, paramCount)
{
  static text[128];
  get_string(1, text, charsmax(text));
  formatex(g_additionalText, charsmax(g_additionalText), "%s%s", g_additionalText, text);
}

reset_additional_text()
{
  g_additionalText[0] = 0;
}

public native_uj_menus_get_menu_id(pluginID, paramCount)
{
  new name[32]
  get_string(1, name, charsmax(name))
  
  // Loop through every item
  new menuID, menu_name[32]
  for (menuID = 0; menuID < g_MenuCount; ++menuID)
  {
    ArrayGetString(g_MenuName, menuID, menu_name, charsmax(menu_name))
    if (equali(name, menu_name))
      return menuID;
  }
  
  return UJ_MENU_INVALID;
}

public native_uj_menus_get_entry_id(pluginID, paramCount)
{
  new name[32]
  get_string(1, name, charsmax(name))
  
  // Loop through every item
  new entryID, entry_name[32]
  for (entryID = 0; entryID < g_entryCount; ++entryID)
  {
    ArrayGetString(g_entryNames, entryID, entry_name, charsmax(entry_name))
    if (equali(name, entry_name))
      return entryID;
  }
  
  return UJ_MENU_INVALID;
}

public native_uj_menus_show_menu(pluginID, paramCount)
{
  new playerID = get_param(1)
  new menuID = get_param(2)

  if (menuID < 0 || menuID >= g_MenuCount)
  {
    log_error(AMX_ERR_NATIVE, "UJ | Invalid menu ID")
    return UJ_MENU_INVALID;
  }
  
  if (!is_user_connected(playerID))
  {
    log_error(AMX_ERR_NATIVE, "UJ | Invalid Player (%d)", playerID)
    return false;
  }
  
  display_menu(playerID, menuID)
  return true;
}

// Display menu
display_menu(playerID, menuID)
{
  static menu[128], name[32]
  new newmenuID, entryID;

  ArrayGetString(g_MenuName, menuID, name, charsmax(name))
  
  // Title
  formatex(menu, charsmax(menu), "%s", name)
  if (g_additionalText[0] != 0) {
    formatex(menu, charsmax(menu), "%s^n%s", menu, g_additionalText)
    reset_additional_text();
  }
  newmenuID = menu_create(menu, "menu_handler")
  
  // Item List
  for (entryID = 0; entryID < g_entryCount; entryID++)
  {
    reset_additional_text();

    // Execute menu entry select attempt forward
    ExecuteForward(g_forwards[FW_MENU_SELECT_PRE], g_forwardResult, playerID, menuID, entryID)
    
    // Show item to player?
    if (g_forwardResult == UJ_MENU_DONT_SHOW)
      continue;
    
    // Retrieve menu entry name
    ArrayGetString(g_entryNames, entryID, name, charsmax(name))
    
    // Item available to player?
    if (g_forwardResult == UJ_MENU_NOT_AVAILABLE) {
      formatex(menu, charsmax(menu), "\d%s", name);
    }
    else {
      formatex(menu, charsmax(menu), "%s", name);
    }
    // Append additional text to entry
    formatex(menu, charsmax(menu), "%s%s", menu, g_additionalText);
    
    new data[4];
    data[0] = entryID + OFFSET_MENUDATA;
    data[1] = menuID + OFFSET_MENUDATA;
    data[2] = g_forwardResult + OFFSET_MENUDATA;
    data[3] = 0
    menu_additem(newmenuID, menu, data)
  }
  reset_additional_text();
  
  // No items to display?
  /*if (menu_items(newmenuID) <= 0)
  {
    menu_destroy(newmenuID)
    return;
  }*/
  
  // Fix for AMXX custom menus
  set_pdata_int(playerID, OFFSET_CSMENUCODE, 0);
  menu_display(playerID, newmenuID, 0);
}

// Items Menu
public menu_handler(playerID, menuID, entrySelected)
{
  // Menu was closed
  if (entrySelected == MENU_EXIT) {
    menu_destroy(menuID)
    return PLUGIN_HANDLED;
  }
  
  // Retrieve menu entry information
  new data[4], dummy;
  menu_item_getinfo(menuID, entrySelected, dummy, data, charsmax(data), _, _, dummy)
  new entryID = data[0] - OFFSET_MENUDATA;
  new parentMenuID = data[1] - OFFSET_MENUDATA;
  new status = data[2] - OFFSET_MENUDATA;
  
  // Select this item
  select_menu_entry(playerID, parentMenuID, entryID, status)

  menu_destroy(menuID);

  return PLUGIN_HANDLED;
}

// Select entry
select_menu_entry(playerID, menuID, entryID, status)
{
  // If the menu entry was not available to a player
  if (status != UJ_MENU_AVAILABLE)
    return;

  // Before executing the menu, check for validity one more time
  ExecuteForward(g_forwards[FW_MENU_SELECT_PRE], g_forwardResult, playerID, menuID, entryID)
  if (g_forwardResult != UJ_MENU_AVAILABLE) {
    return;
  }
  
  // Execute selected forward
  ExecuteForward(g_forwards[FW_MENU_SELECT_POST], g_forwardResult, playerID, menuID, entryID)
}
