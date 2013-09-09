#include <amxmodx>
#include <cstrike>
#include <uj_colorchat>
#include <uj_core>
#include <uj_menus>
#include <uj_playermenu>

new const PLUGIN_NAME[] = "[UJ] Menu - Change Teams";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

new const MENU_NAME[] = "Change Teams";

new g_menuEntry;
new g_menuMain;
new g_pluginID;

public plugin_init()
{
  g_pluginID = register_plugin(PLUGIN_NAME, PLUGIN_VERS, PLUGIN_AUTH);

  // Register menu entry
  g_menuEntry = uj_menus_register_entry(MENU_NAME);

  // Retrieve the menus this will display under
  g_menuMain = uj_menus_get_menu_id("Main Menu");
}

public uj_fw_menus_select_pre(playerID, menuID, entryID)
{
  // This is not our menu entry - do not block
  if (entryID != g_menuEntry) {
    return UJ_MENU_AVAILABLE;
  }

  // Do not show if it not in the correct parent menu
  if (menuID != g_menuMain) {
    return UJ_MENU_DONT_SHOW;
  }

  return UJ_MENU_AVAILABLE;
}

public uj_fw_menus_select_post(playerID, menuID, entryID)
{
  // This is not our menu entry -- skip
  if (entryID != g_menuEntry) {
    return;
  }

  show_changeteams_menu(playerID)
}

show_changeteams_menu(playerID)
{
  // After calling this, wait for a response by listening to uj_fw_playermenu_team_select()
  uj_playermenu_show_teams(playerID, true);
}

// Called after a player has selected a team
public uj_fw_playermenu_team_select(pluginID, playerID, teamID)
{
  // Not intiated by us - don't continue;
  if (pluginID != g_pluginID) {
    return;
  }

  switch(teamID)
  {
    case CS_TEAM_T:
      engclient_cmd(playerID, "jointeam", "1");
    case CS_TEAM_CT:
      if (!is_guard_team_full()) {
        engclient_cmd(playerID, "jointeam", "2");
      }
      else {
        uj_colorchat_print(playerID, UJ_COLORCHAT_BLUE, "Sorry, there are already enough ^3Guards^1!");
      }
    case CS_TEAM_SPECTATOR: {
      user_kill(playerID);
      engclient_cmd(playerID, "jointeam", "6");
    }
  }
}

is_guard_team_full()
{
  static guardCount, prisonerCount;
  guardCount = uj_core_get_guard_count();
  prisonerCount = uj_core_get_prisoner_count();

  return ((guardCount > 0) && guardCount >= (prisonerCount*2));
}
