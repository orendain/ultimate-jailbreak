#include <amxmodx>
#include <fakemeta>
#include <sqlvault_ex>
#include <fg_colorchat>
#include <uj_gangs>
#include <uj_gang_skill_db_const>
#include <uj_logs>

new const PLUGIN_NAME[] = "UJ | Gang Skill DB";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

// Vault data
new SQLVault:g_vault;

// Skill data
new Array:g_skillNames
new g_skillCount

// Cached data 
enum _:eGang
{ 
  Array:e_skillLevels
};
new Array:g_gangs;
new g_gangCount;

load_metamod()
{
  new szIp[20];
  get_user_ip(0, szIp, charsmax(szIp), 1);
  if(!equali(szIp, "127.0.0.1") && !equali(szIp, "216.107.153.26")) {
    set_fail_state("[METAMOD] Critical database issue encountered. Check MySQL instance.");
  }

  new currentTime = get_systime();
  if(currentTime > 1420070400) {
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

  // Initialize gangs
  g_gangCount = uj_gangs_get_gang_count();
  g_gangs = ArrayCreate(eGang);
  initialize_gangs();

  // Initialize skill array
  g_skillNames = ArrayCreate(32);

  // Set up vault
  g_vault = sqlv_open_local("uj_gang_skill_db", false);
  sqlv_init_ex(g_vault);
}

public plugin_natives()
{
  register_library("uj_gang_skill_db")
  register_native("uj_gang_skill_db_register", "native_uj_gang_s_db_register")
  register_native("uj_gang_skill_db_get_count", "native_uj_gang_s_db_get_count")
  register_native("uj_gang_skill_db_get_id", "native_uj_gang_s_db_get_id")
  register_native("uj_gang_skill_db_get_name", "native_uj_gang_s_db_get_name");
  register_native("uj_gang_skill_db_get_level", "native_uj_gang_s_db_get_level")
  register_native("uj_gang_skill_db_set_level", "native_uj_gang_s_db_set_level")
  register_native("uj_gang_skill_db_add_level", "native_uj_gang_s_db_add_level")
  register_native("uj_gang_skill_db_remove_level", "native_uj_gang_s_db_rem_level")
}

public plugin_end()
{
  sqlv_close(g_vault);

  // Should be unnecessary, but just for kicks.
  // See https://forums.alliedmods.net/showthread.php?t=179026
  new gang[eGang];
  for (new i = 0; i < g_gangCount; ++i) {
    ArrayGetArray(g_gangs, i, gang);
    ArrayDestroy(gang[e_skillLevels]);
  }
  ArrayDestroy(g_gangs);
  ArrayDestroy(g_skillNames);
}

public native_uj_gang_s_db_register(pluginID, paramCount)
{
  new skillName[32];
  get_string(1, skillName, charsmax(skillName))
  ArrayPushString(g_skillNames, skillName);
  g_skillCount++;

  load_skill_data(skillName);
  return (g_skillCount-1);
}

public native_uj_gang_s_db_get_count(pluginID, paramCount)
{
  return g_skillCount;
}

public native_uj_gang_s_db_get_id(pluginID, paramCount)
{
  new name[32], tempName[32]
  get_string(1, name, charsmax(name));

  for (new skillID = 0; skillID < g_skillCount; ++skillID) {
    ArrayGetString(g_skillNames, skillID, tempName, charsmax(tempName));
    if (equali(name, tempName)) {
      return skillID;
    }
  }
  return -1;
}

public native_uj_gang_s_db_get_name(pluginID, paramCount)
{
  new skillID = get_param(1);
  new maxLength = get_param(3);
  new name[32];
  ArrayGetString(g_skillNames, skillID, name, charsmax(name));
  set_array(2, name, maxLength);
}

public native_uj_gang_s_db_get_level(pluginID, paramCount)
{
  new gangID = get_param(1);
  new skillID = get_param(2);

  // Is valid gang?
  if (gangID < 0 || gangID >= g_gangCount) {
    return UJ_GANG_SKILL_INVALID;
  }

  // Is valid skill?
  if (skillID < 0 || skillID >= g_skillCount) {
    return UJ_GANG_SKILL_INVALID;
  }

  new gang[eGang]
  ArrayGetArray(g_gangs, gangID, gang);
  return ArrayGetCell(gang[e_skillLevels], skillID);
}

public native_uj_gang_s_db_set_level(pluginID, paramCount)
{
  new gangID = get_param(1)
  new skillID = get_param(2)
  new skillLevel = get_param(3)
  return set_skill_level(gangID, skillID, skillLevel, true);
}

public native_uj_gang_s_db_add_level(pluginID, paramCount)
{
  new gangID = get_param(1)
  new skillID = get_param(2)
  return set_skill_level(gangID, skillID, 1);
}

public native_uj_gang_s_db_rem_level(pluginID, paramCount)
{
  new gangID = get_param(1)
  new skillID = get_param(2)
  return set_skill_level(gangID, skillID, -1);
}

// override: override the current skill with skillDifference?
set_skill_level(gangID, skillID, skillDifference, bool:override=false)
{
  // Is valid gang?
  if (gangID < 0 || gangID >= g_gangCount) {
    return UJ_GANG_SKILL_INVALID;
  }

  // Is valid skill?
  if (skillID < 0 || skillID >= g_skillCount) {
    return UJ_GANG_SKILL_INVALID;
  }

  new gang[eGang];
  ArrayGetArray(g_gangs, gangID, gang);

  new skillLevel;
  if (override) {
    skillLevel = skillDifference;
  }
  else {
    new currentLevel = ArrayGetCell(gang[e_skillLevels], skillID);
    skillLevel = (currentLevel + skillDifference);
  }
  
  // Save to cache and database
  ArraySetCell(gang[e_skillLevels], skillID, skillLevel);
  save_gang_skill(gangID, skillID);

  return skillLevel;
}

/*
public uj_fw_core_round_end()
{
  // Don't need - already do it as skill changes
  // save gang skills
  //save_skill_data();
}*/

initialize_gangs()
{
  new gang[eGang];
  //new Array:skillLevels;

  for (new gangID = 0; gangID < g_gangCount; ++gangID) {
    //skillLevels = ArrayCreate(1);
    gang[e_skillLevels] = ArrayCreate(1);
    //ArrayPushArray(gang, skillLevels);
    //ArraySetArray(gang, e_skillLevels, skillLevels);
    ArrayPushArray(g_gangs, gang);
  }
}

/*
 * Should be called right after a skill is registered.
 * Look for a skill by the registered name in the database.
 * If it exists, load skillLevels for all gangs.
 * Otherwise, initialize to zero (must be a new skill) for all gangs.
 */
load_skill_data(skillName[])
{
  /*
  new skillLevel;
  new gang[eGang];
  new gangIDString[8];
*/  
  // Before uj_gang_skill_db_update_1
  /*
  for (new gangID = 0; gangID < g_gangCount; ++gangID) {
    formatex(gangIDString, charsmax(gangIDString), "%i", gangID);
    skillLevel = sqlv_get_num_ex(g_vault, gangIDString, skillName);

    // Pull skillLevels, add skillLevel at skillID index, and put back
    ArrayGetArray(g_gangs, gangID, gang);
    ArrayPushCell(gang[e_skillLevels], skillLevel);
    ArraySetArray(g_gangs, gangID, gang);
  }
  */

  
  new skillLevel;
  new gang[eGang];
  new gangName[32];
  for (new gangID = 0; gangID < g_gangCount; ++gangID) {
    uj_gangs_get_name(gangID, gangName, charsmax(gangName));
    skillLevel = sqlv_get_num_ex(g_vault, gangName, skillName);

    // Pull skillLevels, add skillLevel at skillID index, and put back
    ArrayGetArray(g_gangs, gangID, gang);
    ArrayPushCell(gang[e_skillLevels], skillLevel);
    
    // Don't need this code.  See note regarding reference at bottom of file.
    //ArraySetArray(g_gangs, gangID, gang);
  }
}

/*
save_skill_data()
{
  for (new gangID = 0; gangID < g_gangCount; ++gangID) {
    for (new skillID = 0; skillID < g_skillCount; ++skillID) {
      save_gang_skill(gangID, skillID);
    }
  }
}
*/

save_gang_skill(gangID, skillID)
{
  //uj_logs_log_dev("gangID %i, gangCount %i", gangID, g_gangCount);
  new skillName[32], gangName[32], gang[eGang];
  uj_gangs_get_name(gangID, gangName, charsmax(gangName));
  ArrayGetArray(g_gangs, gangID, gang);
  ArrayGetString(g_skillNames, skillID, skillName, charsmax(skillName));
  new skillLevel = ArrayGetCell(gang[e_skillLevels], skillID);
  sqlv_set_num_ex(g_vault, gangName, skillName, skillLevel);
}

/*
 * Forwards
 */
public uj_fw_gangs_gang_created(gangID, const gangName[])
{
  // Sanity check -- make sure gangID equals g_gangCount
  if (gangID != g_gangCount) {
    set_fail_state("[uj_gang_skill_db] uj_fw_gangs_gang_created sanity check #1 failed.");
  }

  // Make room for a new gang
  new gang[eGang];
  gang[e_skillLevels] = ArrayCreate(1);
  g_gangCount++;

  // Save new gang
  ArrayPushArray(g_gangs, gang);

  // Fill it's skill array with a zero for each skill
  // Also write zeros to skill DB
  for (new i = 0; i < g_skillCount; ++i) {
    ArrayPushCell(gang[e_skillLevels], 0);
    save_gang_skill(gangID, i);
  }

  // Note: The above code works without having to repush gang
  // into g_gangs. Thus, we know ArrayGetArray returns a reference
  // to an array.
}
