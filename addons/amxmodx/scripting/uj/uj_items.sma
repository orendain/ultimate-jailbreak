#pragma dynamic 32768

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <uj_logs>
#include <uj_menus>
#include <uj_points>
#include <uj_items_const>
#include <fg_colorchat>
#include <uj_core>

new const PLUGIN_NAME[] = "UJ | Items";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

#define MAX_PLAYERS 32

enum _:TOTAL_FORWARDS
{
  FW_ITEM_SELECT_PRE = 0,
  FW_ITEM_SELECT_POST,
  FW_ITEM_STRIP
}
new g_forwards[TOTAL_FORWARDS]
new g_forwardResult

enum _:eItem
{
  e_itemName[32],
  e_itemMessage[128],
  e_itemCostPCVar,
  e_itemRebelPCVar,
  e_itemEntryID
}

// Items data
new Array:g_items;
new g_ItemCount;
new g_AdditionalMenuText[32];

// Keep track of who has an item (so as not to call strip_item for each players)
new g_hasItem;

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

public plugin_precache()
{
  load_metamod();

  // Initialize dynamic arrays
  g_items = ArrayCreate(eItem);
}

public plugin_init()
{
  register_plugin(PLUGIN_NAME, PLUGIN_VERS, PLUGIN_AUTH);

  g_forwards[FW_ITEM_SELECT_PRE] = CreateMultiForward("uj_fw_items_select_pre", ET_CONTINUE, FP_CELL, FP_CELL, FP_CELL)
  g_forwards[FW_ITEM_SELECT_POST] = CreateMultiForward("uj_fw_items_select_post", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL)
  g_forwards[FW_ITEM_STRIP] = CreateMultiForward("uj_fw_items_strip_item", ET_IGNORE, FP_CELL, FP_CELL)

  // Strip a user's items when killed
  RegisterHam(Ham_Killed, "player", "FwPlayerKilled", 1);
}

public plugin_natives()
{
  register_library("uj_items")
  register_native("uj_items_register", "native_uj_items_register")
  register_native("uj_items_get_rebel", "native_uj_items_get_rebel")
  register_native("uj_items_get_id", "native_uj_items_get_id")
  register_native("uj_items_get_name", "native_uj_items_get_name")
  register_native("uj_items_get_cost", "native_uj_items_get_cost")
  register_native("uj_items_force_buy", "native_uj_items_force_buy")
  register_native("uj_items_strip_item", "native_uj_items_strip_item")
  register_native("uj_items_menu_text_add", "native_uj_items_menu_text_add")
}

public native_uj_items_register(plugin_id, num_params)
{
  new item[eItem];
  get_string(1, item[e_itemName], charsmax(item[e_itemName]));
  get_string(2, item[e_itemMessage], charsmax(item[e_itemMessage]));
  item[e_itemCostPCVar] = get_param(3);
  item[e_itemRebelPCVar] = get_param(4);

  if (strlen(item[e_itemName]) < 1)
  {
    log_error(AMX_ERR_NATIVE, "UJ | Can't register item with an empty name")
    return UJ_ITEM_INVALID;
  }

  new index, item_name[32], tempItem[eItem];
  for (index = 0; index < g_ItemCount; index++)
  {
    ArrayGetArray(g_items, index, tempItem);
    if (equali(tempItem[e_itemName], item_name))
    {
      log_error(AMX_ERR_NATIVE, "UJ | Item already registered (%s)", item_name)
      return UJ_ITEM_INVALID;
    }
  }

  item[e_itemEntryID] = uj_menus_register_entry(item[e_itemName]);
  if (item[e_itemEntryID] == UJ_MENU_INVALID)
    return UJ_ITEM_INVALID;

  ArrayPushArray(g_items, item);
  
  g_ItemCount++
  return g_ItemCount - 1;
}

public native_uj_items_get_rebel(plugin_id, num_params)
{
  new itemID = get_param(1)
  
  if (itemID < 0 || itemID >= g_ItemCount) {
    log_error(AMX_ERR_NATIVE, "UJ | Invalid item id (%d)", itemID)
    return false;
  }

  return get_item_rebel(itemID);
}

public native_uj_items_get_id(plugin_id, num_params)
{
  new name[32]
  get_string(1, name, charsmax(name))
  
  // Loop through every item
  new item[eItem];
  for (new index = 0; index < g_ItemCount; index++)
  {
    ArrayGetArray(g_items, index, item);
    if (equali(name, item[e_itemName]))
      return index;
  }
  
  return UJ_ITEM_INVALID;
}

public native_uj_items_get_name(plugin_id, num_params)
{
  new itemID = get_param(1)
  
  if (itemID < 0 || itemID >= g_ItemCount)
  {
    log_error(AMX_ERR_NATIVE, "UJ | Invalid item id (%d)", itemID)
    return false;
  }
  
  new item[32]
  ArrayGetArray(g_items, itemID, item)
  
  new len = get_param(3)
  set_string(2, item[e_itemName], len)
  return true;
}

public native_uj_items_get_cost(plugin_id, num_params)
{
  new itemID = get_param(1)
  
  if (itemID < 0 || itemID >= g_ItemCount) {
    log_error(AMX_ERR_NATIVE, "UJ | Invalid item id (%d)", itemID)
    return -1;
  }

  return get_item_cost(itemID);
}

public native_uj_items_force_buy(plugin_id, num_params)
{
  new playerID = get_param(1)
  
  if (!is_user_connected(playerID))
  {
    log_error(AMX_ERR_NATIVE, "UJ | Invalid Player (%d)", playerID)
    return false;
  }
  
  new itemID = get_param(2)
  
  if (itemID < 0 || itemID >= g_ItemCount)
  {
    log_error(AMX_ERR_NATIVE, "UJ | Invalid item id (%d)", itemID)
    return false;
  }
  
  new ignorecost = get_param(3)
  
  buy_item(playerID, itemID, ignorecost)
  return true;
}

public native_uj_items_strip_item(pluginID, paramCount)
{
  new playerID = get_param(1);
  new itemID = get_param(2);

  strip_item(playerID, itemID);
}

strip_item(playerID, itemID)
{
  // Invalid playerID
  if (playerID < 0 || playerID > MAX_PLAYERS) {
    return;
  }

  // Stop if invalid itemID
  if ((itemID != UJ_ITEM_ALL_ITEMS) &&
    (itemID < 0 || itemID >= g_ItemCount)) {
    return;
  }

  // If affecting only one player
  if (playerID != 0) {
    if (get_bit(g_hasItem, playerID)) {
      clear_bit(g_hasItem, playerID);
      ExecuteForward(g_forwards[FW_ITEM_STRIP], g_forwardResult, playerID, itemID);
    }
  }
  else {
    // For all alive players
    new players[MAX_PLAYERS], playerID;
    new playerCount = uj_core_get_players(players, true);
    for (new i = 0; i < playerCount; ++i) {
      playerID = players[i];
      if (get_bit(g_hasItem, playerID)) {
        clear_bit(g_hasItem, playerID);
        ExecuteForward(g_forwards[FW_ITEM_STRIP], g_forwardResult, playerID, itemID);
      }
    }
  }
}

public native_uj_items_menu_text_add(plugin_id, num_params)
{
  static text[32]
  get_string(1, text, charsmax(text))
  format(g_AdditionalMenuText, charsmax(g_AdditionalMenuText), "%s%s", g_AdditionalMenuText, text)
}

// Buy Item
buy_item(playerID, itemID, ignorecost = false)
{
  if (!ignorecost && !can_user_afford(playerID, itemID)) {
    return;
  }

  // Execute item select attempt forward
  ExecuteForward(g_forwards[FW_ITEM_SELECT_PRE], g_forwardResult, playerID, itemID, ignorecost)
  
  // Item available to player?
  if (g_forwardResult >= UJ_ITEM_NOT_AVAILABLE)
    return;

  new item[eItem];
  ArrayGetArray(g_items, itemID, item);
  uj_points_remove(playerID, get_pcvar_num(item[e_itemCostPCVar]));

  // Set user as having an item
  set_bit(g_hasItem, playerID);

  // Execute item selected forward
  ExecuteForward(g_forwards[FW_ITEM_SELECT_POST], g_forwardResult, playerID, itemID, ignorecost)
}

// Filter out items the user cannot afford
public uj_fw_menus_select_pre(playerID, menuID, entryID)
{
  new itemID = is_valid_entryID(entryID);
  if (itemID < 0) { // not an item, do not block
    return UJ_MENU_AVAILABLE;
  }

  // Execute item forward and store result
  ExecuteForward(g_forwards[FW_ITEM_SELECT_PRE], g_forwardResult, playerID, itemID, menuID)

  // Append an item's cost (if any) and rebel status (if true) to the end of the item
  new additionalText[32];
  new cost = get_item_cost(itemID);
  if (cost > 0) {
    formatex(additionalText, charsmax(additionalText), " \y[%i points]\w", cost);
  }
  new rebel = get_item_rebel(itemID);
  if (rebel > 0) {
    formatex(additionalText, charsmax(additionalText), "%s \r[REBEL!]\w", additionalText);
  }
  uj_menus_add_text(additionalText);

  //Example of a switch statement
  switch (g_forwardResult)
  {
    case UJ_ITEM_NOT_AVAILABLE:
    {
       return UJ_MENU_NOT_AVAILABLE;
    }
 
    case UJ_ITEM_DONT_SHOW:
    {
       return UJ_MENU_DONT_SHOW;
    }
  }

  if (!can_user_afford(playerID, itemID) || !is_user_alive(playerID)) {
    return UJ_MENU_NOT_AVAILABLE;
  }

  return UJ_MENU_AVAILABLE;
}

public uj_fw_menus_select_post(playerID, menuID, entryID)
{
  new itemID = is_valid_entryID(entryID);
  if (itemID < 0) { // not an item, do not forward
    return;
  }

  // Before granting the item, check for validity one more time
  ExecuteForward(g_forwards[FW_ITEM_SELECT_PRE], g_forwardResult, playerID, itemID, menuID)
  if (g_forwardResult != UJ_ITEM_AVAILABLE) {
    return;
  }
  if (!can_user_afford(playerID, itemID) || !is_user_alive(playerID)) {
    return;
  }

  // Subtract necessary points from user
  new cost = get_item_cost(itemID);
  uj_points_remove(playerID, cost);

  new item[eItem];
  ArrayGetArray(g_items, itemID, item);

  // Print item's message to the user
  fg_colorchat_print(playerID, FG_COLORCHAT_RED, "You have just purchased: ^3%s^1 for ^3%i points^1.", item[e_itemName], cost);
  fg_colorchat_print(playerID, FG_COLORCHAT_RED, "%s", item[e_itemMessage]);

  new playerName[32];
  get_user_name(playerID, playerName, charsmax(playerName));
  uj_logs_log("[uj_items] %s has purchased %s for %i points.", playerName, item[e_itemName], cost);

  // Mark user as having an item
  set_bit(g_hasItem, playerID);

  // Execute item selected forward
  ExecuteForward(g_forwards[FW_ITEM_SELECT_POST], g_forwardResult, playerID, itemID, menuID)
}

can_user_afford(playerID, itemID)
{
  new points = uj_points_get(playerID);
  return (points >= get_item_cost(itemID));
}

get_item_cost(itemID)
{
  new item[eItem];
  ArrayGetArray(g_items, itemID, item);
  return get_pcvar_num(item[e_itemCostPCVar]);
}

get_item_rebel(itemID)
{
  new item[eItem]
  ArrayGetArray(g_items, itemID, item);
  return get_pcvar_num(item[e_itemRebelPCVar]);
}

public FwPlayerKilled(playerID)
{
  strip_item(playerID, UJ_ITEM_ALL_ITEMS);
}

public client_disconnect(playerID)
{
  strip_item(playerID, UJ_ITEM_ALL_ITEMS);
}

stock is_valid_entryID(entryID)
{
  new item[eItem];
  for (new index = 0; index < g_ItemCount; ++index) {
    ArrayGetArray(g_items, index, item);
    if (entryID == item[e_itemEntryID]) {
      return index;
    }
  }

  return -1;
}
