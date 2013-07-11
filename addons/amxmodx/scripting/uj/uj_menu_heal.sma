#include <amxmodx>
#include <cstrike>
#include <fakemeta>
#include <fun>
#include <uj_core>
#include <uj_colorchat>
#include <uj_menus>
#include <uj_playermenu>

new const PLUGIN_NAME[] = "[UJ] Menu - Heal";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

new const MENU_NAME[] = "Heal prisoners";

new g_pluginID;
new g_menuEntry;
new g_mainMain;

public plugin_init()
{
  g_pluginID = register_plugin(PLUGIN_NAME, PLUGIN_VERS, PLUGIN_AUTH);

  // Now register this menu as an item of the main menu
  g_mainMain = uj_menus_get_menu_id("Main Menu");
  g_menuEntry = uj_menus_register_entry(MENU_NAME);
}

public uj_fw_menus_select_pre(playerID, menuID, entryID)
{
  // This is not our item - do not block
  if (entryID != g_menuEntry)
    return UJ_MENU_AVAILABLE;
  
  // Only display to Counter Terrorists
  if (cs_get_user_team(playerID) != CS_TEAM_CT)
    return UJ_MENU_DONT_SHOW;

  // Do not show if it is not in this specific parent menu
  if (menuID != g_mainMain)
    return UJ_MENU_DONT_SHOW;
  
  return UJ_MENU_AVAILABLE;
}

public uj_fw_menus_select_post(playerID, menuID, entryID)
{
  // This is not our item
  if (g_menuEntry != entryID)
    return;

  // After calling this, wait for a response by listening to uj_fw_playermenu_select_post()
  //uj_playermenu_show_team_players(playerID, "ace", "TERRORIST");

  new players[32];
  new playerCount = uj_core_get_players(players, true, CS_TEAM_T);
  uj_playermenu_show_players(playerID, players, playerCount);
}

// Called after a player has selected a target
public uj_fw_playermenu_player_select(pluginID, playerID, targetID)
{
  // Not intiated by us - don't continue;
  if (pluginID != g_pluginID) {
    return;
  }

  // Heal the target to his/her max health
  new Float:health;
  pev(targetID, pev_max_health, health);
  set_pev(targetID, pev_health, health);

  // Announce the heal
  new playerName[32], targetName[32];
  get_user_name(playerID, playerName, charsmax(playerName));
  get_user_name(targetID, targetName, charsmax(targetName));
  uj_colorchat_print(0, playerID, "^3%s^1 has healed ^3%s^1 to ^4%i^1 HP!", playerName, targetName, floatround(health));
}
