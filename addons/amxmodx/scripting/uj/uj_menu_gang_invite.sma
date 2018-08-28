#include <amxmodx>
#include <cstrike>
#include <fg_colorchat>
#include <uj_core>
#include <uj_gangs>
#include <uj_logs>
#include <uj_menus>
#include <uj_playermenu>
#include <uj_points>

new const PLUGIN_NAME[] = "UJ | Menu - Gang Invite";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

new const MENU_NAME[] = "Invite prisoners";

new const GANG_INVITE_COST[] = "50";
new const GANG_MEMBER_LIMIT[] = "10";

#define MAX_PLAYERS 32

// Plugin variables
new g_pluginID;

// Menu variables
new g_menuEntry
new g_menuMain

// Gang variables
new g_inviteCost;
new g_gangInvites[MAX_PLAYERS+1];

// Gang PCVars
new g_memberLimitPCVar;

public plugin_init()
{
  g_pluginID = register_plugin(PLUGIN_NAME, PLUGIN_VERS, PLUGIN_AUTH);

  // Register a menu entry
  g_menuEntry = uj_menus_register_entry(MENU_NAME)

  // The menu we will crowbardisplay in
  g_menuMain = uj_menus_get_menu_id("Gang Menu")

  // CVars
  g_inviteCost = register_cvar("uj_gang_invite_cost", GANG_INVITE_COST);
  g_memberLimitPCVar = register_cvar("uj_gang_invite_member_limit", GANG_MEMBER_LIMIT);

  register_clcmd("say /acceptGang", "accept_gang_invitation");
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

  // Only display to those who have the power to invite
  new gangRank = uj_gangs_get_member_rank(playerID);
  if (gangRank < UJ_GANG_RANK_ADMIN) {
    return UJ_MENU_DONT_SHOW;
  }
  
  new additionalText[32];

  new gangID = uj_gangs_get_gang(playerID);
  new memberCount = uj_gangs_get_member_count(gangID)
  new memberLimit = get_pcvar_num(g_memberLimitPCVar);
  if (memberCount >= memberLimit) { // hard limit for now
    formatex(additionalText, charsmax(additionalText), " \y[Gang full]\w");
    uj_menus_add_text(additionalText);
    return UJ_MENU_NOT_AVAILABLE;
  }

  new cost = get_pcvar_num(g_inviteCost);
  formatex(additionalText, charsmax(additionalText), " \y[%i points]\w", cost);
  uj_menus_add_text(additionalText);

  // Make sure the user can afford it
  if (cost > uj_points_get(playerID)) {
    return UJ_MENU_NOT_AVAILABLE;
  }

  return UJ_MENU_AVAILABLE;
}

public uj_fw_menus_select_post(playerID, menuID, entryID)
{
  // This is not our menu entry
  if (g_menuEntry != entryID)
    return;
  
  // After calling this, wait for a response by listening to uj_fw_playermenu_select_post()
  //uj_playermenu_show_team_players(playerID, "ce", "TERRORIST");

  new players[32];
  new playerCount = uj_core_get_players(players, false, CS_TEAM_T);
  uj_playermenu_show_players(playerID, players, playerCount);
}

// Called after a player has selected a target
public uj_fw_playermenu_player_select(pluginID, playerID, targetID)
{
  // Not intiated by us - don't continue;
  if (pluginID != g_pluginID) {
    return;
  }

  // Player selected him/herself (stop name from even displaying?)
  if  (targetID == playerID) {
    fg_colorchat_print(targetID, playerID, "Inviting yourself to your own gang?  ^3Like a BOSS!");
    return;
  }

  // Subtract points required to invite a player
  new cost = get_pcvar_num(g_inviteCost);
  uj_points_remove(playerID, cost);

  // Save invitation
  g_gangInvites[targetID] = uj_gangs_get_gang(playerID);

  // Display invite message
  new playerName[32], targetName[32], gangName[32];
  get_user_name(playerID, playerName, charsmax(playerName));
  get_user_name(playerID, targetName, charsmax(targetName));
  uj_gangs_get_name(g_gangInvites[targetID], gangName, charsmax(gangName));
  fg_colorchat_print(playerID, playerID, "Your invite has been sent!  Have ^3%s^1 say ^4/acceptGang^1 to join your ranks!", targetName);
  fg_colorchat_print(targetID, playerID, "^3%s^1 invites you to join the gang: ^3%s^1.  ^4Say /acceptGang^1 to accept!", playerName, gangName);
  uj_logs_log("[uj_menu_gang_invite] %s invited a player to join %s", playerName, gangName);
}

public accept_gang_invitation(playerID)
{
  if (cs_get_user_team(playerID) != CS_TEAM_T) {
    fg_colorchat_print(playerID, playerID, "Wha?! Guards can't join gangs, man!");
    return PLUGIN_HANDLED;
  }
  
  new gangID = g_gangInvites[playerID];
  if (gangID < 0) {
    fg_colorchat_print(playerID, playerID, "Pfft, you don't have an invite, homie!");
    return PLUGIN_HANDLED;
  }

  if (uj_gangs_get_gang(playerID) != UJ_GANG_INVALID) {
    fg_colorchat_print(playerID, playerID, "You're already in a gang!  Leave your current one first!");
    return PLUGIN_HANDLED;
  }

  new gangName[32];
  uj_gangs_add_member(playerID, gangID);
  uj_gangs_get_name(gangID, gangName, charsmax(gangName));
  fg_colorchat_print(playerID, playerID, "Gang joined!  Welcome to ^3%s^1, ese!", gangName);

  // Announce to all users
  new playerName[32];
  get_user_name(playerID, playerName, charsmax(playerName));
  fg_colorchat_print(0, playerID, "Yo, vato locos! ^3%s^1 has just joined ^3%s^1!", playerName, gangName);
  uj_logs_log("[uj_menu_gang_invite] %s has joined gang %s", playerName, gangName);
  
  return PLUGIN_HANDLED;
}

public client_authorized(playerID)
{
  // Clear any past user's gang invitations when a new player takes his/her place
  g_gangInvites[playerID] = UJ_GANG_INVALID;
}
