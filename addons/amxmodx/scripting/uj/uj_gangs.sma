#pragma dynamic 32768

#include <amxmodx>
#include <cstrike>
#include <sqlvault_ex>
#include <uj_core>
#include <uj_gangs_const>

new const PLUGIN_NAME[] = "UJ | Gangs";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

#define MAX_PLAYERS 32
#define AUTH_SIZE 32

enum _:TOTAL_FORWARDS
{
  FW_GANG_CREATED = 0,
  FW_GANG_DESTROYED
}
new g_forwards[TOTAL_FORWARDS];
new g_forwardResult;

// Player data
new g_authIDs[MAX_PLAYERS+1][AUTH_SIZE+1];

// Gang data
enum _:eGang
{
  e_gangName[32],
  e_gangLeader[32], // authID
  Trie:e_gangMembers, // authIDs
  e_gangMemberCount
};
new Array:g_gangs;
new g_gangCount;
new g_playerGang[MAX_PLAYERS+1];

// Vault data
new SQLVault:g_vault;

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

  // Prepare forwards
  g_forwards[FW_GANG_CREATED] = CreateMultiForward("uj_fw_gangs_gang_created", ET_IGNORE, FP_CELL, FP_ARRAY);
  g_forwards[FW_GANG_DESTROYED] = CreateMultiForward("uj_fw_gangs_gang_destroyed", ET_IGNORE, FP_CELL, FP_ARRAY);

  g_vault = sqlv_open_local("uj_gangs", false);
  sqlv_init_ex(g_vault);

  g_gangs = ArrayCreate(eGang);

  // Fill g_playerGang with UJ_GANG_INVALID
  for (new i = 1; i <= MAX_PLAYERS; ++i) {
    g_playerGang[i] = UJ_GANG_INVALID;
  }

  // Load gang data from the database
  load_gangs();
}
 
public plugin_natives()
{
  register_library("uj_gangs");

  register_native("uj_gangs_create_gang", "native_uj_gangs_create_gang");
  register_native("uj_gangs_destroy_gang", "native_uj_gangs_destroy_gang");
  register_native("uj_gangs_get_gang_count", "native_uj_gangs_get_gang_count");
  register_native("uj_gangs_get_name", "native_uj_gangs_get_name");
  register_native("uj_gangs_set_name", "native_uj_gangs_set_name");
  register_native("uj_gangs_get_gang", "native_uj_gangs_get_gang");
  register_native("uj_gangs_get_gang_id", "native_uj_gangs_get_gang_id");
  register_native("uj_gangs_get_member_count", "native_uj_g_get_member_count");
  register_native("uj_gangs_add_member", "native_uj_gangs_add_member");
  register_native("uj_gangs_remove_member", "native_uj_gangs_remove_member");
  register_native("uj_gangs_remove_member_auth", "native_uj_g_remove_member_auth");
  register_native("uj_gangs_get_membership", "native_uj_gangs_get_membership");
  register_native("uj_gangs_get_online_members", "native_uj_gangs_get_online_mem");
  register_native("uj_gangs_add_admin", "native_uj_gangs_add_admin");
  register_native("uj_gangs_remove_admin", "native_uj_gangs_remove_admin");
  register_native("uj_gangs_get_member_rank", "native_uj_gangs_get_member_rank");
  register_native("uj_gangs_set_leader", "native_uj_gangs_set_leader");
}

public native_uj_gangs_create_gang(pluginID, paramCount)
{
  new playerID = get_param(1)
  new gang[eGang];
  get_string(2, gang[e_gangName], charsmax(gang[e_gangName]));

  gang[e_gangMembers] = _:TrieCreate();
  TrieSetCell(gang[e_gangMembers], g_authIDs[playerID], UJ_GANG_RANK_LEADER)
  g_playerGang[playerID] = g_gangCount; // g_gangCount is the gangID, currently
  ++gang[e_gangMemberCount];

  sqlv_set_num_ex(g_vault, g_authIDs[playerID], gang[e_gangName], UJ_GANG_RANK_LEADER);

  ArrayPushArray(g_gangs, gang);
  g_gangCount++;

  new arrayArg = PrepareArray(gang[e_gangName], charsmax(gang[e_gangName]));
  ExecuteForward(g_forwards[FW_GANG_CREATED], g_forwardResult, (g_gangCount-1), arrayArg);

  return (g_gangCount-1);
}

public native_uj_gangs_destroy_gang(pluginID, paramCount)
{
  new gangID = get_param(1);

  if (gangID < 0 || gangID >= g_gangCount) {
    return;
  }
  new gang[eGang], gangName[32];
  ArrayGetArray(g_gangs, gangID, gang);
  copy(gangName, charsmax(gangName), gang[e_gangName]);
  
  /*
  Because gangIDs are supposed to be persistant, we can not delete
  gangs.  otherwise, gangs shift to the left in the array
  and our ID system becomes off.
  // Remove entry from the database and from cache
  sqlv_remove_ex(g_vault, "*", gangName);
  ArrayDeleteItem(g_gangs, gangID);
  g_gangCount--;
  */

  // Remove entry from the database and from cache
  new emptyGang[eGang];
  sqlv_remove_ex(g_vault, "*", gangName);
  ArraySetArray(g_gangs, gangID, emptyGang);
  // Should we initialize emptyGang[g_gangMembers]?
  // Does another part of the code assume it's always
  // initialized?

  // Mark online former-gangmembers as not belonging to any gang
  new players[32], pid;
  new count = get_online_members(gangID, players, sizeof(players));
  for (new i = 0; i < count; ++i) {
    pid = players[i];
    g_playerGang[pid] = UJ_GANG_INVALID;
  }

  new arrayArg = PrepareArray(gangName, charsmax(gangName));
  ExecuteForward(g_forwards[FW_GANG_DESTROYED], g_forwardResult, (g_gangCount-1), arrayArg);
}

public native_uj_gangs_get_gang_count(pluginID, paramCount)
{
  return g_gangCount;
}

public native_uj_gangs_get_name(pluginID, paramCount)
{
  new gangID = get_param(1);
  new gangNameLength = get_param(3);

  new gang[eGang];
  ArrayGetArray(g_gangs, gangID, gang);
  set_array(2, gang[e_gangName], gangNameLength);
}

public native_uj_gangs_set_name(pluginID, paramCount)
{
  new gangID = get_param(1)

  if (gangID < 0 || gangID >= g_gangCount) {
    return UJ_GANG_INVALID;
  }

  new gang[eGang]
  ArrayGetArray(g_gangs, gangID, gang);
  get_string(2, gang[e_gangName], charsmax(gang[e_gangName]));

  // is that a permanent change? ... hmmm ...
  return PLUGIN_HANDLED;
}

public native_uj_gangs_get_gang(pluginID, paramCount)
{
  new playerID = get_param(1)
  if (playerID <= 0 || playerID > MAX_PLAYERS) {
    return UJ_GANG_INVALID;
  }

  return g_playerGang[playerID];
}

public native_uj_gangs_get_gang_id(pluginID, paramCount)
{
  new gangName[32]
  get_string(1, gangName, charsmax(gangName));

  return find_gang_id(gangName);
}

public native_uj_g_get_member_count(pluginID, paramCount)
{
  new gangID = get_param(1);

  if (gangID < 0 || gangID >= g_gangCount) {
    return UJ_GANG_INVALID;
  }

  new gang[eGang];
  ArrayGetArray(g_gangs, gangID, gang);
  return gang[e_gangMemberCount];
}

public native_uj_gangs_add_member(pluginID, paramCount)
{
  new playerID = get_param(1)
  new gangID = get_param(2)

  if (gangID < 0 || gangID >= g_gangCount) {
    return UJ_GANG_INVALID;
  }

  new gang[eGang];
  ArrayGetArray(g_gangs, gangID, gang);

  TrieSetCell(gang[e_gangMembers], g_authIDs[playerID], UJ_GANG_RANK_MEMBER);
  g_playerGang[playerID] = gangID;
  ++gang[e_gangMemberCount];

  sqlv_set_num_ex(g_vault, g_authIDs[playerID], gang[e_gangName], UJ_GANG_RANK_MEMBER);

  return PLUGIN_HANDLED;
}

public native_uj_gangs_remove_member(pluginID, paramCount)
{
  new playerID = get_param(1)
  new gangID = get_param(2)

  if (gangID < 0 || gangID >= g_gangCount) {
    return UJ_GANG_INVALID;
  }

  // Pull gang from cache
  new gang[eGang];
  ArrayGetArray(g_gangs, gangID, gang);

  // Check to see if user is even in the gang
  if (g_playerGang[playerID] != gangID) {
    return UJ_GANG_INVALID;
  }

  // Edit gang and send to cache
  TrieDeleteKey(gang[e_gangMembers], g_authIDs[playerID])
  --gang[e_gangMemberCount];
  ArraySetArray(g_gangs, gangID, gang);

  g_playerGang[playerID] = UJ_GANG_INVALID;
  sqlv_remove_ex(g_vault, g_authIDs[playerID], gang[e_gangName]);

  // Could change later
  return 1;
}

public native_uj_g_remove_member_auth(pluginID, paramCount)
{
  new authID[32]
  get_string(1, authID, charsmax(authID));

  new gangID = get_param(2)

  if (gangID < 0 || gangID >= g_gangCount) {
    return UJ_GANG_INVALID;
  }

  // Pull gang from cache
  new gang[eGang];
  ArrayGetArray(g_gangs, gangID, gang);

  // Check to see if user is even in the gang
  new rank;
  if (!TrieGetCell(gang[e_gangMembers], authID, rank)) {
    return UJ_GANG_INVALID;
  }

  // Edit gang and send to cache
  TrieDeleteKey(gang[e_gangMembers], authID)
  --gang[e_gangMemberCount];
  ArraySetArray(g_gangs, gangID, gang);

  sqlv_remove_ex(g_vault, authID, gang[e_gangName]);

  // Check to see if the kicked player is logged in
  for (new i = 0; i < MAX_PLAYERS; ++i) {
    if (g_playerGang[i] == gangID) {
      if (strcmp(g_authIDs[i], authID) == 0) {
        g_playerGang[i] = UJ_GANG_INVALID;
        break;
      }
    }
  }

  // Could change later
  return 1;
}

public native_uj_gangs_get_membership(pluginID, paramCount)
{
  new gangID = get_param(1);

  if (gangID < 0 || gangID >= g_gangCount) {
    return UJ_GANG_INVALID;
  }

  // Pull gang from cache and construct the correct filter
  new gang[eGang], gangFilter[48];
  ArrayGetArray(g_gangs, gangID, gang);
  formatex(gangFilter, charsmax(gangFilter), "`key2` = '%s'", gang[e_gangName]);

  new Array:aVaultData;
  new eVaultData[SQLVaultEntryEx];
  new iVaultKeys = sqlv_read_all_ex(g_vault, aVaultData, gangFilter);

  new maxMembers = get_param(3);
  maxMembers = (maxMembers < iVaultKeys) ? maxMembers : iVaultKeys;

  //uj_logs_log_dev("[uj_gangs] Attemping to retrive members from gang #%i, name: %s, found: %i members.", gangID, gang[e_gangName], iVaultKeys);
  //uj_logs_log_dev("[uj_gangs] maxMembers: %i", maxMembers);

  //fg_colorchat_print(0, 1, "VaultKeys: %i, maxMembers %i", iVaultKeys, maxMembers);

  // Manually add all authIDs into the 2D array passed into this fake native
  //new const CELL_SIZE = 4;
  //new iArrayPos, initArrayPos = get_param(2);

  //fg_colorchat_print(0, 1, "SStream is firstly: %s", initArrayPos);
  //initArrayPos = get_param_byref(2);
  //fg_colorchat_print(0, 1, "SStream is firstly: %s", initArrayPos);

  /*new test[32];
  get_string(2, test, 31);
  set_string(2, "HOME", 3);
  fg_colorchat_print(0, 1, "Read string is: %s", test);*/

  new allAuthIDs[1024];

  //new authID[32], authIDLength;
  new memberCount = 0;
  for(new i = 0; i < maxMembers; ++i) {
    ArrayGetArray(aVaultData, i, eVaultData);

    //uj_logs_log_dev("[uj_gangs] FoundThisData: %s", eVaultData[SQLVEx_Key1]);

    if (strcmp(eVaultData[SQLVEx_Key1], gang[e_gangLeader]) == 0) {
      //uj_logs_log_dev("[uj_gangs] Skipping, is leader");
      continue;
    }

    formatex(allAuthIDs, sizeof(allAuthIDs)-1, "%s%s,", allAuthIDs, eVaultData[SQLVEx_Key1]);
    //fg_colorchat_print(0, 1, "String so far: %s", allAuthIDs);
    ++memberCount;
  }

  /*new authID[32], authIDLength;
  new memberCount = 0;
  for(new i = 0; i < maxMembers; ++i) {
    ArrayGetArray(aVaultData, i, eVaultData);
    formatex(authID, 31, "%s", eVaultData[SQLVEx_Key1]);
    
    iArrayPos = (initArrayPos + (i * (sizeof(authID[]) * CELL_SIZE)));
    authIDLength = strlen(authID);
    
    for (new iCharPos = 0; iCharPos < authIDLength; ++iCharPos) {
      set_addr_val(iArrayPos + (iCharPos * CELL_SIZE), authID[iCharPos]);
      fg_colorchat_print(0, 1, "Adding character %c", authID[iCharPos]);
    }
            
    set_addr_val(iArrayPos + (authIDLength * CELL_SIZE), EOS);
    fg_colorchat_print(0, 1, "Pointer is at: %i", iArrayPos);

    fg_colorchat_print(0, 1, "Just added %s", authID);
    fg_colorchat_print(0, 1, "Stream is now: %s", iArrayPos);
    
    ++memberCount;
  }*/

  set_param_byref(3, memberCount);
  set_string(2, allAuthIDs, sizeof(allAuthIDs)-1);

  //uj_logs_log_dev("[uj_gangs] TotalMembersReturning: %i", memberCount);
  /*new dudeString[] = "Dude";
  set_string(2, dudeString, 3);*/

  return PLUGIN_HANDLED;
}

public native_uj_gangs_get_online_mem(pluginID, paramCount)
{
  new gangID = get_param(1);

  if (gangID < 0 || gangID >= g_gangCount) {
    return UJ_GANG_INVALID;
  }

  new const playersLength = get_param(3);

  new players[32];
  new count = get_online_members(gangID, players, playersLength);

  // Save online members back into the argument
  set_array(2, players, count);
  return count;
}

public native_uj_gangs_add_admin(pluginID, paramCount)
{
  return PLUGIN_HANDLED;
}

public native_uj_gangs_remove_admin(pluginID, paramCount)
{
  return PLUGIN_HANDLED;
}

public native_uj_gangs_get_member_rank(pluginID, paramCount)
{
  new playerID = get_param(1);
  new gangID = g_playerGang[playerID];
  if (gangID == UJ_GANG_INVALID) {
    return UJ_GANG_RANK_INVALID;
  }

  new gang[eGang];
  ArrayGetArray(g_gangs, gangID, gang);

  new rank;
  new Trie:members = gang[e_gangMembers];

  return (TrieGetCell(members, g_authIDs[playerID], rank)) ? rank : UJ_GANG_RANK_INVALID;
}

public native_uj_gangs_set_leader(pluginID, paramCount)
{
  new playerID = get_param(1)
  new gangID = get_param(2)

  if (gangID < 0 || gangID >= g_gangCount) {
    return UJ_GANG_INVALID;
  }

  // arraygetarray return reference?
  new gang[eGang];
  ArrayGetArray(g_gangs, gangID, gang);

  // Set old leader to regular member
  sqlv_set_num_ex(g_vault, g_authIDs[gang[e_gangLeader]], gang[e_gangName], UJ_GANG_RANK_MEMBER)

  // Promote new leader
  TrieSetCell(gang[e_gangMembers], gang[e_gangLeader], UJ_GANG_RANK_LEADER)
  sqlv_set_num_ex(g_vault, g_authIDs[playerID], gang[e_gangName], UJ_GANG_RANK_LEADER)
  
  // or need to enable this?
  //ArraySetArray(g_gangs, gangID, gang);

  return PLUGIN_HANDLED;
}

public client_disconnect(playerID)
{
  // If player belonged to a gang, remove him/her from our cache
  if (g_playerGang[playerID] != UJ_GANG_INVALID) {
    new gang[eGang];
    ArrayGetArray(g_gangs, g_playerGang[playerID], gang);
    TrieDeleteKey(gang[e_gangMembers], g_authIDs[playerID]);
    g_playerGang[playerID] = UJ_GANG_INVALID;
  }
  g_authIDs[playerID] = "";
}

public client_authorized(playerID)
{
  // Retrieve and save new player's authID
  get_user_authid(playerID, g_authIDs[playerID], AUTH_SIZE);

  new gang[eGang];
  new gangRank;
  for (new gangID = 0; gangID < g_gangCount; ++gangID) {
    ArrayGetArray(g_gangs, gangID, gang);
    gangRank = sqlv_get_num_ex(g_vault, g_authIDs[playerID], gang[e_gangName]);

    if (gangRank != UJ_GANG_RANK_INVALID) {
      TrieSetCell(gang[e_gangMembers], g_authIDs[playerID], gangRank);
      g_playerGang[playerID] = gangID;
      // maybe in the future, we can have multiple gangs.
      // for now, return when we find one
      return;
    }
  }
}

public plugin_end()
{
  sqlv_close(g_vault);
}

load_gangs()
{
  new Array:aVaultData;
  new iVaultKeys = sqlv_read_all_ex(g_vault, aVaultData);

  new eVaultData[SQLVaultEntryEx];
  new authID[32], gangRank, gangID, gangName[32];
  for (new i = 0; i < iVaultKeys; ++i) {
    ArrayGetArray(aVaultData, i, eVaultData);
    copy(gangName, charsmax(gangName), eVaultData[SQLVEx_Key2]);
    gangID = find_gang_id(gangName);

    new gang[eGang];
    // We haven't encountered this gang yet
    if (gangID == UJ_GANG_INVALID) {
      copy(gang[e_gangName], charsmax(gangName), gangName);
      gang[e_gangMembers] = _:TrieCreate();
    }
    else {
      ArrayGetArray(g_gangs, gangID, gang);
    }

    // Extract player authID and gangRank
    copy(authID, charsmax(authID), eVaultData[SQLVEx_Key1]);
    gangRank = eVaultData[SQLVEx_Data];

    // Convert from ASCII to int
    gangRank -= 48;

    // If this is the leader, cache it
    if (gangRank == UJ_GANG_RANK_LEADER) {
      copy(gang[e_gangLeader], charsmax(authID), authID);
    }

    // Save data
    TrieSetCell(gang[e_gangMembers], authID, gangRank);
    ++gang[e_gangMemberCount];
    if (gangID == UJ_GANG_INVALID) {
      ArrayPushArray(g_gangs, gang);
      g_gangCount++;
    }
    else {
      ArraySetArray(g_gangs, gangID, gang);
    }
  }

  // Done with vault data
  ArrayDestroy(aVaultData);
}

find_gang_id(gangName[])
{
  new gang[eGang];
  for (new gangID = 0; gangID < g_gangCount; ++gangID) {
    ArrayGetArray(g_gangs, gangID, gang);
    if (equali(gangName, gang[e_gangName])) {
      return gangID;
    }
  }
  return UJ_GANG_INVALID;
}

get_online_members(gangID, onlineMembers[], onlineSize)
{
  // Find all online, valid gang members
  new players[32], pid, count;
  new playerCount = uj_core_get_players(players, false, CS_TEAM_T);
  for (new i = 0; i < playerCount && (count < onlineSize); ++i) {
    pid = players[i];
    if (g_playerGang[pid] == gangID) {
      onlineMembers[count] = pid;
      count++;
    }
  }

  return count;
}
