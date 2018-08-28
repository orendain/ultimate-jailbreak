#include <amxmodx>
#include <cstrike>
#include <fakemeta>
#include <fun>
#include <uj_core>
#include <uj_menus>

new const PLUGIN_NAME[] = "UJ | Menu - Weapons v2";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

new const MENU_NAME[] = "Weapons";

#define AMMO_COUNT_PRIMARY 100
#define AMMO_COUNT_SECONDARY 50

#define FLAG_DONOR ADMIN_LEVEL_H
#define ADMIN_WEAPON_INDEX 7

// CS Player PData Offsets (win32)
new const OFFSET_CSMENUCODE = 205;

// Menu variables
new g_menuEntry;
new g_menuMain;

new const g_weaponNames[][] =
{
  "Special Ops (M4A1, USP)",
  "Spetsnaz (AK47, Glock)",
  "SAS (AWP, Deagle)",
  "GSG 9 (UMP, USP)",
  "SWAT Team (M3, P228)",
  "Israeli Police (MAC10, Deagle)",
  "Kommando (Bullpup, P228)",
  "Reinforcements (Shield, USP)", // donor only, ADMIN_WEAPON_INDEX = 7;
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

public plugin_init()
{
  register_plugin(PLUGIN_NAME, PLUGIN_VERS, PLUGIN_AUTH);

  // Now register this menu as an entry and find its parent
  g_menuMain = uj_menus_get_menu_id("Main Menu");
  g_menuEntry = uj_menus_register_entry(MENU_NAME);
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

  if (!is_user_alive(playerID)) {
    return UJ_MENU_NOT_AVAILABLE;
  }

  return UJ_MENU_AVAILABLE;
}

public uj_fw_menus_select_post(playerID, menuID, entryID)
{
  // This is not our menu entry
  if (g_menuEntry != entryID) {
    return;
  }
  
  // Now open up our own menu
  show_weapon_menu(playerID);
}

show_weapon_menu(playerID)
{
  static menuEntry[250];
  new menuID = menu_create(MENU_NAME, "menu_handler");

  for (new i = 0; i < sizeof(g_weaponNames); ++i) {
    
    if (i < ADMIN_WEAPON_INDEX || (get_user_flags(playerID) & FLAG_DONOR)) {
      formatex(menuEntry, charsmax(menuEntry), "%s", g_weaponNames[i]);
    }
    else {
      formatex(menuEntry, charsmax(menuEntry), "\d%s", g_weaponNames[i]);
    }

    menu_additem(menuID, menuEntry);
  }

  // Fix for AMXX custom menus
  set_pdata_int(playerID, OFFSET_CSMENUCODE, 0);
  menu_display(playerID, menuID, 0);
}

// Items Menu
public menu_handler(playerID, menuID, entrySelected)
{
  // Menu was closed
  if (entrySelected == MENU_EXIT) {
    menu_destroy(menuID)
    return PLUGIN_HANDLED;
  }
  
  // Strip the user of current weapons
  uj_core_strip_weapons(playerID);

  // Retrieve the correct internal weapon names and values
  new primaryName[32], secondaryName[32];

  copy(primaryName, charsmax(primaryName), g_primaryWeaponValues[entrySelected][0]);
  copy(secondaryName, charsmax(secondaryName), g_secondaryWeaponValues[entrySelected][0]);
  new primaryID = g_primaryWeaponValues[entrySelected][1][0];
  new secondaryID = g_secondaryWeaponValues[entrySelected][1][0];

  // Give user the selected weapons and ammo
  give_item(playerID, primaryName);
  give_item(playerID, secondaryName);
  cs_set_user_bpammo(playerID, secondaryID, AMMO_COUNT_SECONDARY);

  // Only give primary ammo if the shield wasn't selected
  if (!equali(primaryName, "weapon_shield")) {
    cs_set_user_bpammo(playerID, primaryID, AMMO_COUNT_PRIMARY);
  }

  // Give the user full nades and armor
  give_item(playerID, "weapon_hegrenade");
  give_item(playerID, "weapon_smokegrenade");
  give_item(playerID, "weapon_flashbang");
  give_item(playerID, "weapon_flashbang");
  give_item(playerID, "item_assaultsuit");

  menu_destroy(menuID);
  return PLUGIN_HANDLED;
}
