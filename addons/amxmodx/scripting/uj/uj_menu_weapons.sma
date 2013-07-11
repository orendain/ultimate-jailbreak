#include <amxmodx>
#include <cstrike>
#include <fun>
#include <uj_colorchat>
#include <uj_core>
#include <uj_days>
#include <uj_items>
#include <uj_menus>

new const PLUGIN_NAME[] = "[UJ] Menu - Weapons";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

new const MENU_NAME[] = "Weapons";

new const WEAPON_MESSAGE[] = "Weapons locked and loaded!";
new const WEAPON_COST[] = "0";
new const WEAPON_REBEL[] = "false";

new const AMMO_COUNT_PRIMARY = 100;
new const AMMO_COUNT_SECONDARY = 50;

new const ADMIN_WEAPON_INDEX = 7;
new const ADMIN_FLAG = ADMIN_LEVEL_A;

// Menu variables
new g_menu
new g_menuEntry
new g_menuMain

// CVars
new g_costCVar;
new g_rebelCVar;

new const g_weaponNames[][] =
{
  "Special Ops (M4A1, USP)",
  "Spetsnaz (AK47, Glock)",
  "SAS (AWP, Deagle)",
  "GSG 9 (UMP, USP)",
  "SWAT Team (M3, P228)",
  "Israeli Police (MAC10, Deagle)",
  "Kommando (Bullpup, P228)",
  "Reinforcements (Shield, USP)", // admin only, ADMIN_WEAPON_INDEX = 7;
  "Heavy Duty (M249, Elites)",
  "Defender (Galil, Deagle)"
}

new const g_primaryWeaponValues[][][] =
{
  {"weapon_m4a1", CSW_M4A1},
  {"weapon_ak47", CSW_AK47},
  {"weapon_awp", CSW_AWP},
  {"weapon_ump45", CSW_UMP45},
  {"weapon_m3", CSW_M3},
  {"weapon_mac10", CSW_MAC10},
  {"weapon_aug", CSW_AUG},
  {"weapon_shield", 0},
  {"weapon_m249", CSW_M249},
  {"weapon_galil", CSW_GALIL}
}

new const g_secondaryWeaponValues[][][] = 
{
  {"weapon_usp", CSW_USP},
  {"weapon_glock18", CSW_GLOCK18},
  {"weapon_deagle", CSW_DEAGLE},
  {"weapon_usp", CSW_USP},
  {"weapon_p228", CSW_P228},
  {"weapon_deagle", CSW_DEAGLE},
  {"weapon_p228", CSW_P228},
  {"weapon_usp", CSW_USP},
  {"weapon_elite", CSW_ELITE},
  {"weapon_deagle", CSW_DEAGLE}
}

new g_itemIDs[sizeof(g_weaponNames)];
new g_adminWeaponIndex;

public plugin_precache()
{
  // Register a main menu
  g_menu = uj_menus_register_menu(MENU_NAME);
}

public plugin_init()
{
  register_plugin(PLUGIN_NAME, PLUGIN_VERS, PLUGIN_AUTH);

  // Now register this menu as an entry and find its parent
  g_menuMain = uj_menus_get_menu_id("Main Menu")
  g_menuEntry = uj_menus_register_entry(MENU_NAME)

  // Register CVars
  g_costCVar = register_cvar("uj_menu_weapons_cost", WEAPON_COST);
  g_rebelCVar = register_cvar("uj_menu_weapos_rebel", WEAPON_REBEL);

  // Register all weapons
  for (new i = 0; i < sizeof(g_weaponNames); i++) {
    g_itemIDs[i] = uj_items_register(g_weaponNames[i], WEAPON_MESSAGE, g_costCVar, g_rebelCVar)
  }

  g_adminWeaponIndex = ADMIN_WEAPON_INDEX;
}

public uj_fw_menus_select_pre(playerID, menuID, entryID)
{
  // This is not our menu entry - do not block
  if (entryID != g_menuEntry) {
    return UJ_MENU_AVAILABLE;
  }

  // Do not show if it is not in this specific parent menu
  if (menuID != g_menuMain) {
    return UJ_MENU_DONT_SHOW;
  }
  
  // Only display menu to Counter Terrorists
  if (cs_get_user_team(playerID) != CS_TEAM_CT) {
    return UJ_MENU_DONT_SHOW;
  }

  // Disable if weapon pickup is blocked
  if (uj_core_get_weapon_pickup(playerID)) {
    return UJ_MENU_NOT_AVAILABLE;
  }

  return UJ_MENU_AVAILABLE;
}

public uj_fw_menus_select_post(playerID, menuID, entryID)
{
  // This is not our menu entry
  if (g_menuEntry != entryID)
    return;
  
  // Now open up our own menu
  uj_menus_show_menu(playerID, g_menu);
}

public uj_fw_items_select_pre(playerID, itemID, menuID)
{
  new weaponID = in_array(g_itemIDs, itemID, sizeof(g_itemIDs));
  // This is not one of our items - do not block
  if (weaponID < 0) {
    return UJ_ITEM_AVAILABLE;
  }

  // Only show this item if on the weapons menu
  if (menuID != g_menu) {
    return UJ_ITEM_DONT_SHOW;
  }

  // Display special items only to admins
  if (weaponID >= g_adminWeaponIndex && !(get_user_flags(playerID) & ADMIN_FLAG)) {
    return UJ_ITEM_NOT_AVAILABLE;
  }
  
  return UJ_ITEM_AVAILABLE;
}

public uj_fw_items_select_post(playerID, itemID, menuID)
{
  // This is not our menu
  if (menuID != g_menu) {
    return;
  }

  new weaponID = in_array(g_itemIDs, itemID, sizeof(g_itemIDs));
  if (weaponID >= 0) {
    // Strip the user of current weapons
    uj_core_strip_weapons(playerID);

    // Retrieve the correct internal weapon names and values
    new primaryName[32], secondaryName[32];

    copy(primaryName, charsmax(primaryName), g_primaryWeaponValues[itemID][0]);
    copy(secondaryName, charsmax(secondaryName), g_secondaryWeaponValues[itemID][0]);
    new primaryID = g_primaryWeaponValues[itemID][1][0];
    new secondaryID = g_secondaryWeaponValues[itemID][1][0];

    // Give user the selected weapons and ammo
    give_item(playerID, primaryName);
    give_item(playerID, secondaryName);
    cs_set_user_bpammo(playerID, secondaryID, AMMO_COUNT_SECONDARY);

    // Only give primary ammo if the shield wasn't selected
    if (!equali(primaryName, "weapon_shield")) {
      cs_set_user_bpammo(playerID, primaryID, AMMO_COUNT_PRIMARY);
    }

    // Give the user full nades
    give_item(playerID, "weapon_hegrenade");
    give_item(playerID, "weapon_smokegrenade");
    give_item(playerID, "weapon_flashbang");
    give_item(playerID, "weapon_flashbang");

    // Give the user armor
    cs_set_user_armor(playerID, 100, CS_ARMOR_VESTHELM)
  }
}

public uj_fw_items_strip_item(playerID, itemID)
{
  if (itemID == UJ_ITEM_ALL_ITEMS || in_array(g_itemIDs, itemID, sizeof(g_itemIDs)) >= 0) {
    uj_core_strip_weapons(playerID);
  }
}

stock in_array(dArray[], value, size)
{
  for (new i = 0; i < size; i++) {
    if (value == dArray[i]) {
      return i;
    }
  }
  return -1;
}
