#include <amxmodx>
#include <engine>
#include <fg_colorchat>
#include <uj_menus>

new const PLUGIN_NAME[] = "UJ | Activity - Push";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

new const MENU_NAME[] = "Toggle Push";

#define FLAG_ADMIN ADMIN_LEVEL_A
#define PUSH_LEVEL "10"

new bool:g_pushEnabled;
new g_pushLevel;

new g_menuActivities;
new g_entryID;

public plugin_init()
{
	register_plugin(PLUGIN_NAME, PLUGIN_VERS, PLUGIN_AUTH);

	register_touch("player", "player", "players_touched");

	g_entryID = uj_menus_register_entry(MENU_NAME);
	g_pushLevel = register_cvar("uj_activity_push_level", PUSH_LEVEL);

	g_menuActivities = uj_menus_get_menu_id("Activities");
}

public uj_fw_menus_select_pre(playerID, menuID, entryID)
{
  // This is not our item - do not block
  if (entryID != g_entryID)
    return UJ_MENU_AVAILABLE;

  // Do not show if it is not in this specific parent menu
  if (menuID != g_menuActivities)
    return UJ_MENU_DONT_SHOW;
  
  return UJ_MENU_AVAILABLE;
}

public uj_fw_menus_select_post(playerID, menuid, entryID)
{
  // This is not our item
  if (g_entryID != entryID)
    return;
  
  // Toggle push
  g_pushEnabled = !g_pushEnabled;
  new statusString[16];

  // Display notice
  new playerName[32];
  get_user_name(playerID, playerName, charsmax(playerName));
  copy(statusString, charsmax(statusString), g_pushEnabled ? "On" : "Off");
  fg_colorchat_print(0, FG_COLORCHAT_BLUE, "^3%s^1 has toggled ^3pushing^1: ^4%s^1!", playerName, statusString);
}

public players_touched(pusherID, pushedID)
{
  if (g_pushEnabled) {
    if (is_valid_player(pusherID) && is_valid_player(pushedID)) {
      new Float:a[2][3];
      entity_get_vector(pusherID, EV_VEC_origin, a[0]);
      entity_get_vector(pushedID, EV_VEC_origin, a[1]);
      new b, pushLevel = get_pcvar_num(g_pushLevel);
      for (b = 0; b <= 2; b++ ) {
        a[1][b] -= a[0][b];
        a[1][b] *= pushLevel;
      }
      entity_set_vector(pushedID, EV_VEC_velocity, a[1]);
    }
  }
}

public is_valid_player(playerID)
{
  if((1 <= playerID <= 32) && (is_valid_ent(playerID))) {
    new szClassname[32];
    entity_get_string(playerID, EV_SZ_classname, szClassname, 31);
    return (equali(szClassname, "player"));
  }
  return 0;
}
