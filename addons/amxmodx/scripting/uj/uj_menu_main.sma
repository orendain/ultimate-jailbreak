#include <amxmodx>
#include <uj_menus>

new const PLUGIN_NAME[] = "[UJ] Menu - Main";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

new const MENU_NAME[] = "Main Menu";

new g_menu

public plugin_precache()
{
  // Register a menu
  g_menu = uj_menus_register_menu(MENU_NAME)
}

public plugin_init()
{
  register_plugin(PLUGIN_NAME, PLUGIN_VERS, PLUGIN_AUTH);

  // Event fired when uesr brings up team menu ('m' button by default)
  register_clcmd("chooseteam", "display_menu");
  //register_clcmd("say /menu", "display_menu");
  //register_clcmd("say menu", "display_menu");
}

public display_menu(id)
{
  uj_menus_show_menu(id, g_menu);
  return PLUGIN_HANDLED;
}

public uj_fw_menus_select_pre(id, menuID, entryID)
{
  // Always allow the main menu to display
  return UJ_MENU_AVAILABLE;
}

public uj_fw_menus_select_post(id, menuID, entryID)
{
  // The main menu is the top level menu and should never be selected
  // and thus we have nothing to do here.
  return;
}
