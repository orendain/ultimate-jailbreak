#include <amxmodx>
#include <cstrike>
#include <fun>
#include <uj_core>
#include <uj_menus>
#include <uj_colorchat>



new const PLUGIN_NAME[] = "[UJ] Menu Entry - Toggle Cells";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

new const MENU_NAME[] = "Toggle Cell Doors";

new g_menuEntry
new g_mainMain

new gTimeLeft;

enum ( += 100 )
{

	TASK_FREE
}

public plugin_init()
{
  register_plugin(PLUGIN_NAME, PLUGIN_VERS, PLUGIN_AUTH);

  // Register the menu entry
  g_menuEntry = uj_menus_register_entry(MENU_NAME)

  // Find the menu this should appear under
  g_mainMain = uj_menus_get_menu_id("Main Menu")
}

public uj_fw_menus_select_pre(playerID, menuID, entryID)
{
  // This is not our entry - do not block
  if (entryID != g_menuEntry)
    return UJ_MENU_AVAILABLE;
  
  // Only display to alive Counter Terrorists
  if (!is_user_alive(playerID) || cs_get_user_team(playerID) != CS_TEAM_CT)
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
  
  // Open up cells
  uj_core_open_cell_doors(playerID);
  set_task( 45.0, "TASK_Glow", TASK_FREE );
  set_task( 1.0, "AFKCHECK", playerID + 255, _, _, "b", gTimeLeft + 1 );
  gTimeLeft = 45;
}

public TASK_Glow()
{
	
	new players[ 32 ], num, playerID;
	get_players( players, num, "ae", "TERRORIST" );
	
	for( new i = 0; i < num; i++ )
	{
		playerID = players[ i ];
		
		if( !is_user_alive( playerID ) )
			continue;
		
		//set_user_rendering( playerID, kRenderFxGlowShell, 255, 140, 0, kRenderNormal, 16);
	}
	
	if( task_exists( TASK_FREE ) )
		remove_task( TASK_FREE );
		
	return PLUGIN_HANDLED;
}

public AFKCHECK( playerID )
{
	playerID -= 255;
	
	new players[ 32 ], num;
	get_players( players, num, "ae", "CT" );
	
	
	if( !is_user_alive( playerID ) || num == 0 )
	{
		if( task_exists( playerID + 255 ) )
			remove_task( playerID + 255 );
	}
	
	if( gTimeLeft >= 0 )
	{
		set_hudmessage( 25, 109, 255, -1.0, 0.90, 0, 0.0, 1.0, 0.0, 0.0, -1 );
		show_hudmessage( 0, "%i Seconds Remaining Until AFK CHECKS are no longer required!", gTimeLeft );
		gTimeLeft--;
	}
	
	else
	{		
		
		set_hudmessage( 255, 50, 50, -1.0, 0.90, 0, 0.0, 10.0, 0.0, 0.0, -1 );
		show_hudmessage( 0, "AFK CHECKS are no longer required!", gTimeLeft );
		uj_colorchat_print(0, 0, "AFK CHECKS ARE NO LONGER REQUIRED");
		
		if( task_exists( playerID + 255 ) )
			remove_task( playerID + 255 );
	}
	
	return PLUGIN_HANDLED;
}
