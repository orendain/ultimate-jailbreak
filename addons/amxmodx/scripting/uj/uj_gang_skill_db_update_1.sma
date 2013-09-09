#include <amxmodx>
#include <sqlvault_ex>
#include <uj_colorchat>
#include <uj_gangs>
#include <uj_gang_skill_db_const>

new const PLUGIN_NAME[] = "[UJ] Gang Skill DB - Update 1";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

// Vault data
new SQLVault:g_vault;

// Gang data
enum eGang
{
  e_gangName[32],
  Array:e_skillLevels
};
new Array:g_gangs;
new g_gangCount;

// Skill data
new Array:g_skillNames;
new g_skillCount;

public plugin_init()
{
  register_plugin(PLUGIN_NAME, PLUGIN_VERS, PLUGIN_AUTH);

  // Initialize gangs
  g_gangCount = uj_gangs_get_gang_count();
  g_gangs = ArrayCreate(eGang);
  initialize_gangs();

  // Initialize skill array
  g_skillNames = ArrayCreate(32);

  // Set up vault to read from
  g_vault = sqlv_open_local("uj_gang_skill_db", false);
  sqlv_init_ex(g_vault);

  //register_concmd("uj_gang_skill_db_update_1", "update_database");

  //set_task(5.0, "update_database");
  set_task(5.0, "test_database");
}

public plugin_end()
{
  sqlv_close(g_vault);
}

public update_database(playerID)
{
  // Let's update this shiznit!
  read_db2(playerID);
  wipe_db(playerID);
  write_db(playerID);
}

public test_database()
{
  read_db_new();
  print_cached_info();
}

read_db2(playerID)
{
  new Array:aVaultData;
  new iVaultKeys = sqlv_read_all_ex(g_vault, aVaultData);

  new eVaultData[SQLVaultEntryEx];
  new gangIDString[32], skillName[32], gangName[32];
  new skillID, skillLevel, gangID;
  for (new i = 0; i < iVaultKeys; ++i) {
    ArrayGetArray(aVaultData, i, eVaultData);

    // Extract gangID string (key #1), skill string (key #2), and skill level (data)
    copy(gangIDString, charsmax(gangIDString), eVaultData[SQLVEx_Key1]);
    copy(skillName, charsmax(skillName), eVaultData[SQLVEx_Key2]);
    skillLevel = str_to_num(eVaultData[SQLVEx_Data]);

    // Convert skillLevel to int (read as a byte? [zero = 48])
    //skillLevel -= 48;
     
    // Parse keys into a gangID
    gangID = str_to_num(gangIDString);

    // Find gangName
    uj_gangs_get_name(gangID, gangName, charsmax(gangName));


    // Find skillID (not uj_gang_skill_db ID, just internal update-id)
    skillID = find_skill_id(skillName);

    // If we haven't encountered this skill yet, store it
    if (skillID < 0) {
      ArrayPushArray(g_skillNames, skillName);
      skillID = g_skillCount;
      g_skillCount++;
    }

    // Save the skillLevel
    new gang[eGang];
    ArrayGetArray(g_gangs, gangID, gang);
    ArraySetCell(gang[e_skillLevels], skillID, skillLevel);
    ArraySetArray(g_gangs, gangID, gang);
  
    server_print("%i: %s,  %i: %s: %i", gangID, gangName, skillID, skillName, skillLevel);
    //uj_colorchat_print(playerID, playerID, "%i: %s,  %i: %s: %i", gangID, gangName, skillID, skillName, skillLevel);
  }

  // Done with vault data
  ArrayDestroy(aVaultData);
  server_print("Done reading skills.");
  uj_colorchat_print(playerID, playerID, "Done reading skills.");
}

read_db_new()
{
  new Array:aVaultData;
  new iVaultKeys = sqlv_read_all_ex(g_vault, aVaultData);

  new eVaultData[SQLVaultEntryEx];
  new skillName[32], gangName[32];
  new skillID, skillLevel, gangID;
  for (new i = 0; i < iVaultKeys; ++i) {
    ArrayGetArray(aVaultData, i, eVaultData);

    // Extract gangName string (key #1), skill string (key #2), and skill level (data)
    copy(gangName, charsmax(gangName), eVaultData[SQLVEx_Key1]);
    copy(skillName, charsmax(skillName), eVaultData[SQLVEx_Key2]);
    skillLevel = str_to_num(eVaultData[SQLVEx_Data]);


    // Find gangID (not uj_gangs ID, just internal update-id)
    gangID = find_gang_id(gangName);
     
    // Find skillID (not uj_gang_skill_db ID, just internal update-id)
    skillID = find_skill_id(skillName);
    // If we haven't encountered this skill yet, store it
    if (skillID < 0) {
      ArrayPushArray(g_skillNames, skillName);
      skillID = g_skillCount;
      g_skillCount++;
    }

    // If we haven't encountered this gang, it must be deleted?
    if (gangID < 0) {
      server_print("DEL: %s,  %i: %s: %i", gangName, skillID, skillName, skillLevel);
      continue;
      /*
      gang[e_skillLevels] = ArrayCreate(1);
      copy(gang[e_gangName], charsmax(gang[e_gangName]), gangName, charsmax(gangName));
      ArrayPushArray(g_gangs, gang);
      gangID = g_gangCount;
      g_gangCount++;
      */
    }

    // Save the skillLevel
    new gang[eGang];
    ArrayGetArray(g_gangs, gangID, gang);
    ArraySetCell(gang[e_skillLevels], skillID, skillLevel);
    ArraySetArray(g_gangs, gangID, gang);

    //new testSkill = ArrayGetCell(gang[e_skillLevels], skillID);
    //server_print("Should be %i", testSkill);
  
    server_print("%s,  %i: %s: %i", gangName, skillID, skillName, skillLevel);
  }

  // Done with vault data
  ArrayDestroy(aVaultData);
  server_print("Done reading skills from new DB.");
}

print_cached_info()
{
  new gang[eGang], skillName[32], skillID, skillLevel;
  for (new gangID = 0; gangID < g_gangCount; ++gangID) {
    ArrayGetArray(g_gangs, gangID, gang);
    
    for (skillID = 0; skillID < g_skillCount; ++skillID) {
      skillLevel = ArrayGetCell(gang[e_skillLevels], skillID);
      ArrayGetArray(g_skillNames, skillID, skillName);
      server_print("-- %s,  %i: %s: %i", gang[e_gangName], skillID, skillName, skillLevel);
    }
  }
  server_print("Done printing cached info.");
}

/*read_db()
{
  new skillLevel;
  new gang[eGang];
  new gangIDString[8];

  for (new gangID = 0; gangID < g_gangCount; ++gangID) {
    formatex(gangIDString, charsmax(gangIDString), "%i", gangID);
    skillLevel = sqlv_get_num_ex(g_vault, gangIDString, skillName);

    // Pull skillLevels, add skillLevel at skillID index, and put back
    ArrayGetArray(g_gangs, gangID, gang);
    ArrayPushCell(gang[e_skillLevels], skillLevel);
    ArraySetArray(g_gangs, gangID, gang);

    server_print("GangID %i, SkillName %s, SkillLevel %i", gangID, skillName, skillLevel);
  }
  server_print("Done reading skills.");
}*/

wipe_db(playerID)
{
  sqlv_clear_ex(g_vault);
  server_print("Database table wiped.");
  uj_colorchat_print(playerID, playerID, "Database table wiped.");
}

write_db(playerID)
{
  new skillName[32], gangName[32], gang[eGang];
  for (new gangID = 0; gangID < g_gangCount; ++gangID) {
    for (new skillID = 0; skillID < g_skillCount; ++skillID) {
      // Find gangName and skillName
      uj_gangs_get_name(gangID, gangName, charsmax(gangName));
      ArrayGetString(g_skillNames, skillID, skillName, charsmax(skillName));

      // Find skillLevel
      ArrayGetArray(g_gangs, gangID, gang);
      new skillLevel = ArrayGetCell(gang[e_skillLevels], skillID);

      if (skillLevel < 0) {
        skillLevel = 0;
      }
      
      // Save skillLevel with gangName and skillName keys
      sqlv_set_num_ex(g_vault, gangName, skillName, skillLevel);
      server_print("%i: %s,  %i: %s: %i", gangID, gangName, skillID, skillName, skillLevel);
      //uj_colorchat_print(playerID, playerID, "%i: %s,  %i: %s: %i", gangID, gangName, skillID, skillName, skillLevel);
    }
  }
  server_print("Done writing skills.");
  uj_colorchat_print(playerID, playerID, "Done writing skills.");
}

initialize_gangs()
{
  new gang[eGang];
  //new Array:skillLevels;
  new gangName[32];
  for (new gangID = 0; gangID < g_gangCount; ++gangID) {
    //skillLevels = ArrayCreate(1);
    uj_gangs_get_name(gangID, gangName, charsmax(gangName));
    copy(gang[e_gangName], charsmax(gang[e_gangName]), gangName);
    gang[e_skillLevels] = ArrayCreate(1, 100);
    ArrayPushCell(gang[e_skillLevels], -1);
    ArrayPushCell(gang[e_skillLevels], -1);
    ArrayPushCell(gang[e_skillLevels], -1);
    ArrayPushCell(gang[e_skillLevels], -1);
    ArrayPushCell(gang[e_skillLevels], -1);
    ArrayPushCell(gang[e_skillLevels], -1);
    ArrayPushCell(gang[e_skillLevels], -1);
    ArrayPushCell(gang[e_skillLevels], -1);
    ArrayPushCell(gang[e_skillLevels], -1);
    ArrayPushCell(gang[e_skillLevels], -1);
    //ArrayPushArray(gang, skillLevels);
    //ArraySetArray(gang, e_skillLevels, skillLevels);
    ArrayPushArray(g_gangs, gang);

    server_print("%s: Just initialized.", gang[e_gangName]);
  }
}

find_skill_id(skillName[])
{
  new name[32];
  for (new i = 0; i < g_skillCount; ++i) {
    ArrayGetArray(g_skillNames, i, name);
    if (equali(name, skillName)) {
      return i;
    }
  }
  return -1;
}

find_gang_id(gangName[])
{
  new gang[eGang];
  for (new i = 0; i < g_gangCount; ++i) {
    ArrayGetArray(g_gangs, i, gang);
    if (equali(gang[e_gangName], gangName)) {
      return i;
    }
  }
  return -1;
}
