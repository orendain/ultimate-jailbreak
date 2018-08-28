#include <amxmodx>
#include <cstrike>
#include <fg_colorchat>
#include <uj_gangs>
#include <uj_logs>
#include <uj_menus>
#include <uj_points>

new const PLUGIN_NAME[] = "UJ | Menu - Gang Create";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

new const MENU_NAME[] = "Start a gang";

new const GANG_COST[] = "200";

// Menu variables
new g_menuEntry
new g_menuMain

// Gang variables
new g_gangCost;

public plugin_init()
{
  register_plugin(PLUGIN_NAME, PLUGIN_VERS, PLUGIN_AUTH);

  // Register a menu entry
  g_menuEntry = uj_menus_register_entry(MENU_NAME)

  // The menu we will display in
  g_menuMain = uj_menus_get_menu_id("Gang Menu")

  // CVars
  g_gangCost = register_cvar("uj_gang_create_cost", GANG_COST);

  register_clcmd("Enter_Gang_Name", "create_gang");
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
  
  // Only display menu to Terrorists
  if (cs_get_user_team(playerID) != CS_TEAM_T) {
    return UJ_MENU_DONT_SHOW;
  }

  // Only display to players in no gang
  if (uj_gangs_get_gang(playerID) != UJ_GANG_INVALID) {
    return UJ_MENU_DONT_SHOW;
  }

  new cost = get_pcvar_num(g_gangCost);
  new additionalText[32];
  formatex(additionalText, charsmax(additionalText), " \y[%i points]\w", cost);
  uj_menus_add_text(additionalText);

  return UJ_MENU_AVAILABLE;
}

public uj_fw_menus_select_post(playerID, menuID, entryID)
{
  // This is not our menu entry
  if (g_menuEntry != entryID)
    return;
  
  // Now open up our own menu
  client_cmd(playerID, "messagemode Enter_Gang_Name");
}

public create_gang(playerID)
{
  new cost = get_pcvar_num(g_gangCost);

  if (uj_points_get(playerID) < cost) {
    fg_colorchat_print(playerID, playerID, "You can't afford to start a gang! Earn more points, yo!");
    return PLUGIN_HANDLED;
  }
  else if(uj_gangs_get_gang(playerID) != UJ_GANG_INVALID) {
    fg_colorchat_print(playerID, playerID, "Sorry homie, you're already in a gang! Leave it first!");
    return PLUGIN_HANDLED;
  }
  else if(cs_get_user_team(playerID) != CS_TEAM_T) {
    fg_colorchat_print(playerID, playerID, "Only prisoners can create gangs!");
    return PLUGIN_HANDLED;
  }

  new name[32];
  read_args(name, charsmax(name));
  remove_quotes(name);

  if (uj_gangs_get_gang_id(name) != UJ_GANG_INVALID) {
    fg_colorchat_print(playerID, playerID, "Gang name already taken!");
    return PLUGIN_HANDLED;
  }

  new gangID = uj_gangs_create_gang(playerID, name);
  if (gangID != UJ_GANG_INVALID) {
    uj_points_remove(playerID, cost);
    fg_colorchat_print(0, playerID, "A new gang has been created! May ^3%s^1 conquer the world!", name);
    uj_logs_log("[uj_menu_gang_create] Gang %s was created.", name);
  }

  return PLUGIN_HANDLED;
}
