#include <amxmodx>
#include <cstrike>
#include <fg_colorchat>
#include <uj_gangs>
#include <uj_gang_skill_db>
#include <uj_logs>
#include <uj_menus>

new const PLUGIN_NAME[] = "UJ | Menu - Gang List";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

new const MENU_NAME[] = "Top 15 gangs";

new const TOP_DISPLAY_COUNT = 15;

// Menu variables
new g_menuEntry
new g_menuMain

public plugin_init()
{
  register_plugin(PLUGIN_NAME, PLUGIN_VERS, PLUGIN_AUTH);

  // Register a menu entry
  g_menuEntry = uj_menus_register_entry(MENU_NAME)

  // The menu we will display in
  g_menuMain = uj_menus_get_menu_id("Gang Menu")
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

  return UJ_MENU_AVAILABLE;
}

public uj_fw_menus_select_post(playerID, menuID, entryID)
{
  // This is not our menu entry
  if (g_menuEntry != entryID)
    return;
  
  list_gangs(playerID);
}

public list_gangs(playerID)
{
  new szMessage[2048];
  formatex(szMessage, charsmax(szMessage), "<body bgcolor=#000000><font color=#FFB000><pre>");
  format(szMessage, charsmax(szMessage), "%s%2s %25s", szMessage, "#", "Name");

  new const gangCount = uj_gangs_get_gang_count();
  new const skillCount = uj_gang_skill_db_get_count();

  new skillName[32], skillID, gangName[32], skillLevel, skillSum, gangID;
  //new gOrder[gangCount][skillCount+1];
  new gOrder[100][10];
  // Top gangs defined by most upgrades purchased
  for (gangID = 0; gangID < gangCount; ++gangID) {
    gOrder[gangID][0] = gangID;

    skillSum = 0;
    for (skillID = 0; skillID < skillCount; ++skillID) {
      skillLevel = uj_gang_skill_db_get_level(gangID, skillID);
      gOrder[gangID][2+skillID] = skillLevel;
      skillSum += skillLevel;
    }

    gOrder[gangID][1] = skillSum;
  }

  SortCustom2D(gOrder, gangCount, "SkillSort");
  
  new Array:skillNames = ArrayCreate(32, skillCount);
  for (skillID = 0; skillID < skillCount; ++skillID) {
    uj_gang_skill_db_get_name(skillID, skillName, charsmax(skillName));
    ArrayPushArray(skillNames, skillName);
    format(szMessage, charsmax(szMessage), "%s %-10s", szMessage, skillName);
  }

  
  for (new i = 0; i < TOP_DISPLAY_COUNT; ++i) {
    gangID = gOrder[i][0];
    uj_gangs_get_name(gangID, gangName, charsmax(gangName));

    format(szMessage, charsmax(szMessage), "%s^n%-2d %25s", szMessage, (i+1), gangName);
    for (skillID = 0; skillID < skillCount; ++skillID) {
      format(szMessage, charsmax(szMessage), "%s %-10d", szMessage, gOrder[i][2+skillID]);
    }
  }

  show_motd(playerID, szMessage, "Top 15 Gangs");
}

public SkillSort(const iElement1[], const iElement2[], const iArray[], szData[], iSize) 
{
  if(iElement1[1] > iElement2[1])
    return -1;
  
  else if(iElement1[1] < iElement2[1])
    return 1;
  
  return 0;
}
