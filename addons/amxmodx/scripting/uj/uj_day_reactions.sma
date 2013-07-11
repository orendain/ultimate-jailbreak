#include <amxmodx>
#include <cstrike>
#include <fakemeta>
#include <fun>
#include <uj_colorchat>
#include <uj_core>
#include <uj_days>
#include <uj_effects>
#include <uj_freedays>
#include <uj_menus>

new const PLUGIN_NAME[] = "[UJ] Day - Reactions";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

new const DAY_NAME[] = "Reactions";
new const DAY_OBJECTIVE[] = "Get those quick fingers ready!";
new const DAY_SOUND[] = "";

new const KILL_LIMIT = 2;
new const MINIMUM_PRISONERS = 2;

#define MAX_PLAYERS 32

new g_day;
new g_menuActivities;

new g_kills;
new g_playersIncluded;
new g_playersActions;
new g_playersLeft
new bool: g_dayEnabled

// Reaction menus
new g_menuTypes
new g_menuReactions

// Reaction variables
enum _:REACTION_TYPE
{
  REACTION_FIRST = 0,
  REACTION_LAST,
}
enum _:REACTION_ACTION
{
  REACTION_JUMP = 0,
  REACTION_CROUCH,
}
new const g_reactionTypeStrings[][] =
{
  "First reaction",
  "Last reaction"
}
new const g_reactionActionStrings[][] =
{
  "Jump",
  "Crouch"
}
new g_reactionType
new g_reactionAction

public plugin_init()
{
  register_plugin(PLUGIN_NAME, PLUGIN_VERS, PLUGIN_AUTH);

  // Register day
  g_day = uj_days_register(DAY_NAME, DAY_OBJECTIVE, DAY_SOUND);

  // Find all valid menus to display this under
  g_menuActivities = uj_menus_get_menu_id("Activities");

  //register_forward(FM_PlayerPreThink, "FM_PlayerPreThink_Pre", 0);
  register_forward(FM_CmdStart, "CmdStart");

  build_menu();
}

public uj_fw_days_select_pre(playerID, dayID, menuID)
{
  // This is not our day - do not block
  if (dayID != g_day) {
    return UJ_DAY_AVAILABLE;
  }

  // Only display if in the parent menu we recognize
  if (menuID != g_menuActivities) {
    return UJ_DAY_DONT_SHOW
  }

  // Disable if we have reached the kill limit for the round
  if (g_kills >= KILL_LIMIT) {
    return UJ_DAY_NOT_AVAILABLE;
  }

  // Disable if there are not enough alive prisoners
  if (!are_enough_prisoners()) {
    return UJ_DAY_NOT_AVAILABLE;
  }

  return UJ_DAY_AVAILABLE;
}

public uj_fw_days_select_post(playerID, dayID)
{
  // This is not our item
  if (dayID != g_day)
    return;

  display_reaction_type_menu(playerID);
}

public uj_fw_days_end(dayID)
{
  // if dayID refers to our day and our day is enabled
  if(dayID == g_day && g_dayEnabled) {
    end_day();
  }
}

public uj_fw_core_round_new()
{
  // Reset kill count on each new round
  g_kills = 0;
}

are_enough_prisoners()
{
  return (uj_core_get_live_prisoner_count() >= MINIMUM_PRISONERS);
}

build_menu()
{
  g_menuTypes = menu_create("Select a reaction type", "menu_type_handle")
  g_menuReactions = menu_create( "Select a reaction", "menu_reaction_handle" )

  menu_additem(g_menuTypes, "First Reaction", "", 0)
  menu_additem(g_menuTypes, "Last Reaction", "", 0)

  menu_additem(g_menuReactions, "Jump", "", 0)
  menu_additem(g_menuReactions, "Crouch", "", 0)
}

public menu_type_handle(playerID, menu, item)
{
  if (item < 0) {
    return PLUGIN_CONTINUE
  }

  switch (item) {
    case 0: {
      g_reactionType = REACTION_FIRST;
      //say(0, "TYPE set to FIRST - case 0")
      display_reaction_action_menu(playerID);
    }
    case 1: {
      g_reactionType = REACTION_LAST;
      //say(0, "TYPE set to LAST - case 1")
      display_reaction_action_menu(playerID);
    }
    case MENU_EXIT: {
      //uj_colorchat_print(0, playerID, "MENU_EXIT ON TYPES");
      uj_days_end();
    }
  }

  return PLUGIN_HANDLED;
}

public menu_reaction_handle(playerID, menu, item) {
  if (item < 0) {
    return PLUGIN_CONTINUE
  }

  switch (item) {
    case 0: {
      g_reactionAction = REACTION_JUMP;
    }
    case 1: {
      g_reactionAction = REACTION_CROUCH;
    }
    case MENU_EXIT: {
      // Back to first menu
      //uj_colorchat_print(0, playerID, "MENU_EXIT ON ACTIONS");
      display_reaction_action_menu(playerID);
      return PLUGIN_HANDLED;
    }
  }

  uj_colorchat_print(0, playerID, "Reactions will begin in 5 seconds!")
  set_task(5.0,"start_reactions")

  return PLUGIN_HANDLED;
}

display_reaction_type_menu(playerID)
{
  menu_display(playerID, g_menuTypes, 0);
}

display_reaction_action_menu(playerID)
{
  menu_display(playerID, g_menuReactions, 0);
}

public start_reactions()
{
  g_dayEnabled = true;
  
  // Find and include all terrorists without freedays
  new players[32], pid;
  new playerCount = uj_core_get_players(players, true, CS_TEAM_T);
  for(new i = 0; i < playerCount; i++) {
    pid = players[i];
    if (!uj_freedays_has_freeday(pid)) {
      set_bit(g_playersIncluded, pid);
      g_playersLeft++;
    }
  }

  uj_colorchat_print(0, UJ_COLORCHAT_RED, "%s: ^3%s^1!", g_reactionTypeStrings[g_reactionType], g_reactionActionStrings[g_reactionAction]);
}

end_day()
{
  // Reset count and actions
  g_playersLeft = 0;
  g_playersIncluded = 0;
  g_playersActions = 0;

  g_dayEnabled = false;
}

kill_player(playerID)
{
  uj_effects_rocket(playerID);
  g_kills++;
  uj_days_end();
}

//public FM_PlayerPreThink_Pre(plr) {}
public CmdStart(playerID, uc_handle)
{
  if (!g_dayEnabled) {
    return PLUGIN_CONTINUE;
  }

  // User has already been processed
  if (get_bit(g_playersActions, playerID)) {
    return PLUGIN_CONTINUE;
  }

  // This player isn't playing
  if (!get_bit(g_playersIncluded, playerID)) {
    return PLUGIN_CONTINUE;
  }

  static button;
  button = get_uc(uc_handle, UC_Buttons);
  if ((g_reactionAction == REACTION_JUMP && button & IN_JUMP) ||
      (g_reactionAction == REACTION_CROUCH && button & IN_DUCK)) {

    set_bit(g_playersActions, playerID);
    
    // if user reacted first, or was the last to react
    if (g_reactionType == REACTION_FIRST) {
      kill_player(playerID);
      //end_reactions();
    } else {
      g_playersLeft--;
    }

    // if one player left, autokill that player
    if (g_playersLeft == 1) {
      // find last player
      for(new i = 1; i <= 32; i++) {
        if (get_bit(g_playersIncluded, i) && !get_bit(g_playersActions, i)) {
          kill_player(i);
        }
      }
    }
  }

  set_uc(uc_handle, UC_Buttons, button);
  return PLUGIN_CONTINUE;
}

stock fm_set_user_maxspeed(index, Float:speed = -1.0)
{
  engfunc(EngFunc_SetClientMaxspeed, index, speed);
  set_pev(index, pev_maxspeed, speed);

  return 1;
}
