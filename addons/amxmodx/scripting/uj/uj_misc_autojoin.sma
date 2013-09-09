#include <amxmodx>
#include <uj_colorchat>
#include <uj_core>

new const PLUGIN_NAME[] = "[UJ] Misc - Autojoin";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

#define AUTO_TEAM_JOIN_DELAY 0.1

// New VGUI Menus
#define TEAM_SELECT_VGUI_MENU_ID 2

// Old Style Menus
stock const FIRST_JOIN_MSG[] =    "#Team_Select";
stock const FIRST_JOIN_MSG_SPEC[] = "#Team_Select_Spect";
stock const INGAME_JOIN_MSG[] =   "#IG_Team_Select";
stock const INGAME_JOIN_MSG_SPEC[] =  "#IG_Team_Select_Spect";
const iMaxLen = sizeof(INGAME_JOIN_MSG_SPEC);

enum {
  TEAM_NONE = 0,
  TEAM_T,
  TEAM_CT,
  TEAM_SPEC,
  
  MAX_TEAMS
};

#define CHOOSETEAM_CT 1

new const g_cTeamChars[MAX_TEAMS] = {
  'U',
  'T',
  'C',
  'S'
};

new g_playerTeam[33];

public plugin_init()
{
  register_plugin(PLUGIN_NAME, PLUGIN_VERS, PLUGIN_AUTH)

  register_event("TeamInfo", "event_TeamInfo", "a");
  register_message(get_user_msgid("ShowMenu"), "message_show_menu")
  register_message(get_user_msgid("VGUIMenu"), "message_vgui_menu")

  register_clcmd("jointeam", "join_team");
  register_menucmd(register_menuid("Team_Select",1), (1<<0)|(1<<1)|(1<<4)|(1<<5), "team_select");
}

public event_TeamInfo()
{
  new playerID = read_data(1);
  new sTeam[32];
  read_data(2, sTeam, sizeof(sTeam)-1);
  for(new team = 0; team < MAX_TEAMS; ++team) {
    if(g_cTeamChars[team] == sTeam[0]) {
      g_playerTeam[playerID] = team;
      break;
    }
  }
}

public message_show_menu(msgID, dest, playerID)
{
  static sMenuCode[iMaxLen];
  get_msg_arg_string(4, sMenuCode, sizeof(sMenuCode) - 1);
  if(equal(sMenuCode, FIRST_JOIN_MSG) || equal(sMenuCode, FIRST_JOIN_MSG_SPEC)) {
    if(should_autojoin(playerID)) {
      set_autojoin_task(playerID, msgID);
      return PLUGIN_HANDLED;
    }
  }
  /*else if(equal(sMenuCode, INGAME_JOIN_MSG) || equal(sMenuCode, INGAME_JOIN_MSG_SPEC)) {
    if(get_pcvar_num(tjm_block_change)) {
      return PLUGIN_HANDLED;
    }
  }*/

  return PLUGIN_HANDLED;
}

public message_vgui_menu(msgID, dest, playerID)
{
  if (get_msg_arg_int(1) != TEAM_SELECT_VGUI_MENU_ID) {
    return PLUGIN_CONTINUE;
  }

  if(should_autojoin(playerID)) {
    set_autojoin_task(playerID, msgID);
    return PLUGIN_HANDLED;
  }

  return PLUGIN_CONTINUE;
}

is_guard_team_full()
{
  static guardCount, prisonerCount;
  guardCount = uj_core_get_guard_count();
  prisonerCount = uj_core_get_prisoner_count();

  return ((guardCount > 0) && guardCount >= (prisonerCount*2));
}

set_autojoin_task(playerID, msgID)
{
  static param_menu_msgid[2];
  param_menu_msgid[0] = msgID;
  set_task(AUTO_TEAM_JOIN_DELAY, "task_autojoin", playerID, param_menu_msgid, sizeof param_menu_msgid)
}

public task_autojoin(msgID[], playerID)
{
  if (get_user_team(playerID))
    return
  force_team_join(playerID, msgID[0])
}

stock force_team_join(playerID, msgID, team[] = "1", class[] = "0")
{
  static jointeam[] = "jointeam"
  if (class[0] == '0') {
    engclient_cmd(playerID, jointeam, team)
    return
  }

  static msg_block, joinclass[] = "joinclass";
  msg_block = get_msg_block(msgID);
  set_msg_block(msgID, BLOCK_SET);
  engclient_cmd(playerID, jointeam, team);
  engclient_cmd(playerID, joinclass, class);
  set_msg_block(msgID, msg_block);
}

stock bool:should_autojoin(playerID)
{
  return (is_user_connected(playerID) && !(TEAM_NONE < g_playerTeam[playerID] < TEAM_SPEC) && !task_exists(playerID));
}

public team_select(playerID, teamKey) 
{ 
  if (teamKey == CHOOSETEAM_CT &&
      is_guard_team_full()) {

    engclient_cmd(playerID, "chooseteam");
    return PLUGIN_HANDLED;
  }     
  
  return PLUGIN_CONTINUE;
}

public join_team(playerID) 
{
  new teamKey[2];
  read_argv(1, teamKey, 1);
  if ((str_to_num(teamKey)-1) == CHOOSETEAM_CT &&
      is_guard_team_full()) {

    engclient_cmd(playerID, "chooseteam");
    return PLUGIN_HANDLED;
  }

  return PLUGIN_CONTINUE;
}
