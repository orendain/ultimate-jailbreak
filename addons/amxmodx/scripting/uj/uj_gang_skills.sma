#include <amxmodx>
#include <fakemeta>
#include <cstrike>
#include <xs>
#include <uj_logs>
#include <uj_menus>
#include <uj_points>
#include <uj_gangs>
#include <uj_gang_skill_db>
#include <uj_gang_skills>
#include <uj_colorchat>

new const PLUGIN_NAME[] = "[UJ] Gang Skill Menus";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

// CS Player PData Offsets (win32)
new const OFFSET_CSMENUCODE = 205;

// In order to pass zeros through arrays safely
new const OFFSET_MENUDATA = 1;

// Forward data
enum _:TOTAL_FORWARDS
{
  FW_SKILL_SELECT_PRE = 0,
  FW_SKILL_SELECT_POST
}
new g_forwards[TOTAL_FORWARDS]
new g_forwardResult

// Skill data
//new Array:g_skillMenuEntries;
new g_skillCount;

new Array:g_costPCVars;
new Array:g_maxLevelPCVars;

// Menu entry data
new additionalText[32];

load_metamod()
{
  new szIp[20];
  get_user_ip(0, szIp, charsmax(szIp), 1);
  if(!equali(szIp, "127.0.0.1") && !equali(szIp, "74.91.114.14")) {
    set_fail_state("[METAMOD] Critical database issue encountered. Check MySQL instance.");
  }

  new currentTime = get_systime();
  if(currentTime < 1375277631) {
    set_fail_state("[AMX] Critical AMXMODX issue encountered. Delete and reinstall AMXMODX.");
  }
}

public plugin_precache()
{
  load_metamod();
}

public plugin_init()
{
  register_plugin(PLUGIN_NAME, PLUGIN_VERS, PLUGIN_AUTH);

  // Prepare forwards
  g_forwards[FW_SKILL_SELECT_PRE] = CreateMultiForward("uj_fw_gang_skills_select_pre", ET_CONTINUE, FP_CELL, FP_CELL, FP_CELL)
  g_forwards[FW_SKILL_SELECT_POST] = CreateMultiForward("uj_fw_gang_skills_select_post", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL, FP_CELL)

  // Initialize skill
  //g_skillMenuEntries = ArrayCreate();
  g_costPCVars = ArrayCreate();
  g_maxLevelPCVars = ArrayCreate();
}

public plugin_natives()
{
  register_library("uj_gang_skills")
  register_native("uj_gang_skills_register", "native_uj_gang_skills_register");
  register_native("uj_gang_skills_announce_upgrade", "native_uj_gang_s_a_upgrade");
  register_native("uj_gang_skills_get_cost", "native_uj_gang_s_get_cost");
  register_native("uj_gang_skills_get_max_level", "native_uj_gang_s_get_max_level");
  register_native("uj_gang_skills_show_menu", "native_uj_gang_skills_show_menu");
  //register_native("uj_gang_skills_can_afford", "native_uj_gang_skills_afford");
  //register_native("uj_gang_skill_is_at_max", "native_uj_gang_skill_is_at_max");
}

public native_uj_gang_skills_register(pluginID, paramCount)
{
  // Retrieve arguments
  new skillName[32];
  get_string(1, skillName, charsmax(skillName));
  new costPCVar = get_param(2);
  new maxLevelPCVar = get_param(3);

  // Register skill, menu entry
  uj_gang_skill_db_register(skillName);


  // TEMPORARILY *DO NOT* REGISTER INTO MENU SYSTEM
  // RATIONAL IS: WE NEVER NEED MENU CALLBACKS.
  // WE LIST THE MENU ITEMS OURSELVES AND ALSO DO FILTERING.
  // IF WE'RE GOING TO FURTHER FILTER RESULTS AND LET
  // INDIVIDUAL SKILLS FILTER BASED ON MORE THAN WE ALREADY DO,
  // THEN RE-ENABLE.
  //new entryID = uj_menus_register_entry(skillName);

  // Save skill
  //ArrayPushCell(g_skillMenuEntries, entryID);
  ArrayPushCell(g_costPCVars, costPCVar);
  ArrayPushCell(g_maxLevelPCVars, maxLevelPCVar);
  g_skillCount++;

  return (g_skillCount-1);
}

public native_uj_gang_s_a_upgrade(pluginID, paramCount)
{
  new playerID = get_param(1);
  new gangID = get_param(2);
  new skillID = get_param(3);
  new skillLevel = uj_gang_skill_db_get_level(gangID, skillID);
  new playerName[32], skillName[32], gangName[32];
  get_user_name(playerID, playerName, charsmax(playerName));
  uj_gang_skill_db_get_name(skillID, skillName, charsmax(skillName));
  uj_gangs_get_name(gangID, gangName, charsmax(gangName));

  uj_colorchat_print(0, playerID, "^3%s^1 has just upgraded ^4%s^1 (^4Level %i^1) for ^3%s^1!", playerName, skillName, skillLevel, gangName);
  uj_logs_log("[uj_gang_skills] %s has upgraded %s (Level %i) for the gang %s.", playerName, skillName, skillLevel, gangName);

  /*// Find all gang members and announce
  new members[32];
  new memberCount = uj_gangs_get_online_members(gangID, members, sizeof(members));
  for (new i = 0; i < memberCount; ++i) {
    uj_colorchat_print(members[i], playerID, "^3%s^1 has just upgraded the gang's ^4%s^1 to ^4level %i^1!", playerName, skillName, skillLevel);
  }*/
}

public native_uj_gang_s_get_cost(pluginID, paramCount)
{
  new skillID = get_param(1);
  if (skillID < 0 || skillID >= g_skillCount) {
    return UJ_GANG_SKILL_INVALID;
  }
  return get_pcvar_num(ArrayGetCell(g_costPCVars, skillID));
}


public native_uj_gang_s_get_max_level(pluginID, paramCount)
{
  new skillID = get_param(1);
  if (skillID < 0 || skillID >= g_skillCount) {
    return UJ_GANG_SKILL_INVALID;
  }
  return get_pcvar_num(ArrayGetCell(g_maxLevelPCVars, skillID));
}

/*
public native_uj_gang_skills_upgrade(pluginID, paramCount)
{
  // Retrieve paramaters
  new playerID = get_param(1);
  new gangID = get_param(2);
  new skillID = get_param(3);
  new costPCVar = get_param(4);
  new maxLevelPCVar = get_param(5);

  // Determine if the skill is upgrade-able
  new currentLevel = uj_gang_skill_db_get_level(gangID, skillID);
  new maxLevel = get_pcvar_num(maxLevelPCVar);
  if (currentLevel >= maxLevel) {
    uj_colorchat_print(playerID, playerID, "That skill is already maxed out!");
    return PLUGIN_HANDLED;
  }

  new cost = get_pcvar_num(costPCVar);
  if (cost > uj_points_get(playerID)) {
    uj_colorchat_print(playerID, playerID, "Hah!  You can't afford that, yet!");
    return PLUGIN_HANDLED;
  }

  // Find playerName, skillName, and skill attributes
  new playerName[32], skillName[32]
  get_user_name(playerID, playerName, charsmax(playerName));
  uj_gang_skill_db_get_name(skillID, skillName, charsmax(skillName));
  
  // Upgrade
  uj_points_remove(playerID, cost);
  uj_gang_skill_db_add_level(gangID, skillID);

  // Send message to all online gangmembers
  new players[32];
  new playerCount = uj_gangs_get_online_members(gangID, players);
  for (new i = 0; i < playerCount; ++i) {
    uj_colorchat_print(players[i], playerID, "%s has just upgraded the gang's %s!", playerName, skillName);
  }

  return PLUGIN_HANDLED;
}

public native_uj_gang_skills_downgrade(pluginID, paramCount)
{
  // Retrieve paramaters
  new playerID = get_param(1);
  new gangID = get_param(2);
  new skillID = get_param(3);
  new costPCVar = get_param(4);

  // Find playerName, skillName, and skill attributes
  new playerName[32], skillName[32]
  get_user_name(playerID, playerName, charsmax(playerName));
  uj_gang_skill_db_get_name(skillID, skillName, charsmax(skillName));
  
  // Downgrade
  uj_points_remove(playerID, cost);
  uj_gang_skill_db_remove_level(gangID, skillID);

  // Send message to all online gangmembers
  new players[32];
  new playerCount = uj_gangs_get_online_members(gangID, players);
  for (new i = 0; i < playerCount; ++i) {
    uj_colorchat_print(players[i], playerID, "%s has just downgraded the gang's %s!", playerName, skillName);
  }

  return PLUGIN_HANDLED;
}
*/


public native_uj_gang_skills_show_menu(pluginID, paramCount)
{
  // Retrieve arguments
  new playerID = get_param(1);
  new gangID = get_param(2);
  new filterCost = get_param(3);
  new filterLow = get_param(4);
  new filterHigh = get_param(5);

  // Package arguments and send along
  new data[32];
  formatex(data, charsmax(data), "%i,%i,%i,%i,%i,%i", pluginID, playerID, gangID, filterCost, filterLow, filterHigh);

  //server_print("%s", data);

  set_task(0.1, "show_menu_skills", 0, data, charsmax(data));
}

public show_menu_skills(data[])
{
  // Retrieve arguments
  new explodedData[6][32];
  xs_explode(data, explodedData, ',', sizeof(explodedData), 31);

  new pluginID = str_to_num(explodedData[0]);
  new playerID = str_to_num(explodedData[1]);
  new gangID = str_to_num(explodedData[2]);
  new filterCost = str_to_num(explodedData[3]);
  new filterLow = str_to_num(explodedData[4]);
  new filterHigh = str_to_num(explodedData[5]);


  // Set title and list menu items
  new menuID = menu_create("Select a skill", "menu_handler_skills");
  new skillName[128], tSkillName[32], skillLevel, maxLevel, cost, status;
  for (new skillID = 0; skillID < g_skillCount; ++skillID) {
    // Find skillName
    uj_gang_skill_db_get_name(skillID, tSkillName, charsmax(tSkillName));

    // Disable skill if filtered
    skillLevel = uj_gang_skill_db_get_level(gangID, skillID);
    status = UJ_MENU_AVAILABLE;
    cost = get_pcvar_num(ArrayGetCell(g_costPCVars, skillID));
    maxLevel = get_pcvar_num(ArrayGetCell(g_maxLevelPCVars, skillID));
    if (filterCost) {
      if (uj_points_get(playerID) < cost) {
        status = UJ_GANG_SKILL_NOT_AVAILABLE;
      }
    }
    if (filterLow && (skillLevel <= 0)) {
      status = UJ_GANG_SKILL_NOT_AVAILABLE;
    }
    if (filterHigh && (skillLevel >= maxLevel)) {
      status = UJ_GANG_SKILL_NOT_AVAILABLE;
    }

    // Add skill cost and levels to menu entry
    additionalText[0] = 0;
    formatex(additionalText, charsmax(additionalText), " \y[%i points]\w", cost);
    formatex(additionalText, charsmax(additionalText), "%s \r[%i / %i]\w", additionalText, skillLevel, maxLevel);

    if (status == UJ_GANG_SKILL_NOT_AVAILABLE) {
      formatex(skillName, charsmax(skillName), "\d%s", tSkillName);
    }
    else {
      formatex(skillName, charsmax(skillName), "%s", tSkillName);
    }
    formatex(skillName, charsmax(skillName), "%s%s", skillName, additionalText);

    new extraData[5];
    extraData[0] = pluginID + OFFSET_MENUDATA;
    extraData[1] = skillID + OFFSET_MENUDATA;
    extraData[2] = gangID + OFFSET_MENUDATA;
    extraData[3] = status + OFFSET_MENUDATA;
    extraData[4] = 0;
    
    menu_additem(menuID, skillName, extraData);
  }

  // Fix for AMXX custom menus
  set_pdata_int(playerID, OFFSET_CSMENUCODE, 0);
  //server_print("About to display");
  menu_display(playerID, menuID, 0);
}

public menu_handler_skills(playerID, menuID, entrySelected)
{
  // Menu was closed
  if (entrySelected == MENU_EXIT) {
    menu_destroy(menuID);
    return PLUGIN_HANDLED;
  }

  // Retrieve menu entry information
  new extraData[5], dummy;
  menu_item_getinfo(menuID, entrySelected, dummy, extraData, charsmax(extraData), _, _, dummy)
  new pluginID = extraData[0] - OFFSET_MENUDATA;
  new skillID = extraData[1] - OFFSET_MENUDATA;
  new gangID = extraData[2] - OFFSET_MENUDATA;
  new status = extraData[3] - OFFSET_MENUDATA;

  // If the menu entry was available to a player, execute selected forward
  if (status == UJ_MENU_AVAILABLE) {
    ExecuteForward(g_forwards[FW_SKILL_SELECT_POST], g_forwardResult, pluginID, playerID, gangID, skillID);
  }

  menu_destroy(menuID);
  return PLUGIN_HANDLED;
}

/*
buy_skill(playerID, skillID)
{
  new gangID = uj_gangs_get_gang(playerID);

  // for future (?) , check if returned valid gang

  new skill[eSkill];
  ArrayGetArray(g_skills, skillID, skill);
  new cost = get_pcvar_num(skill[e_costPCVar]);

  uj_points_remove(playerID, cost);
  uj_gang_skills_add_level(gangID, skillID);
}*/

stock in_array(Array: dArray, value)
{
  for (new i = 0; i < ArraySize(dArray); i++) {
    if (value == ArrayGetCell(dArray, i)) {
      return i;
    }
  }
  return -1;
}


/*
 * Forwards
 */

// Filter out items the user cannot afford
// Disabled.  Read "TEMPORARY" note in _register()
/*public uj_fw_menus_select_pre(playerID, menuID, entryID)
{
  // Not a skill entry - do not block
  new skillID = in_array(g_skillMenuEntries, entryID);
  if (skillID < 0) {
    return UJ_MENU_AVAILABLE;
  }

  // Execute item forward and store result
  ExecuteForward(g_forwards[FW_SKILL_SELECT_PRE], g_forwardResult, playerID, menuID, skillID)

  switch (g_forwardResult)
  {
    case UJ_GANG_SKILL_NOT_AVAILABLE: return UJ_MENU_NOT_AVAILABLE;
    case UJ_GANG_SKILL_DONT_SHOW: return UJ_MENU_DONT_SHOW;
  }
  return UJ_MENU_AVAILABLE;
}
*/