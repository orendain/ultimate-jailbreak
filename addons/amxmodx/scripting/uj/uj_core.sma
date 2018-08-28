#include <amxmodx>
#include <cstrike>
#include <engine>
#include <fakemeta>
#include <fun>
#include <hamsandwich>
//#include <cs_player_models_api>
//#include <cs_weap_models_api>
#include <fg_colorchat>
#include <uj_core_const>

new const PLUGIN_NAME[] = "UJ | Core";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

new const OFFSET_PRIMARYWEAPON = 116;

enum _:TOTAL_FORWARDS
{
  FW_CORE_ROUND_NEW = 0,
  FW_CORE_PLAYER_SPAWN,
  FW_CORE_ROUND_START,
  FW_CORE_ROUND_END,
  FW_CORE_MAX_HEALTH,
  FW_CORE_DAMAGE_TAKEN,
};
new g_forwards[TOTAL_FORWARDS];
new g_forwardResult;

// For uj_core_weapon_pickup()
new bool:g_weaponPickupBlocked;
new g_hasPickupBlocked;

// For uj_core_set_friendly_fire()
#define TEAM_T 1
#define TEAM_CT 2
#define XO_PLAYER    5
#define m_iTeam    114
#define cs_get_user_team_index(%1)        get_pdata_int(%1, m_iTeam, XO_PLAYER)
#define cs_set_user_team_index(%1,%2)    set_pdata_int(%1, m_iTeam, %2, XO_PLAYER)

new g_friendlyFire;
new g_iVictimTeam;
new HamHook:g_iHhTakeDamagePost;
new maxPlayers;

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

public plugin_natives()
{
  register_library("uj_core")
  register_native("uj_core_block_weapon_pickup", "native_uj_core_block_w_pickup");
  register_native("uj_core_get_weapon_pickup", "native_uj_core_get_w_pickup");
  register_native("uj_core_set_friendly_fire", "native_uj_core_set_friend_fire");
  register_native("uj_core_strip_weapons", "native_uj_core_strip_weapons")
  register_native("uj_core_determine_max_health", "native_uj_core_d_max_health")
  register_native("uj_core_get_players", "native_uj_core_get_players");
  register_native("uj_core_get_prisoner_count", "native_uj_core_get_p_count")
  register_native("uj_core_get_live_prisoner_count", "native_uj_core_get_l_p_count")
  register_native("uj_core_get_guard_count", "native_uj_core_get_g_count")
  register_native("uj_core_get_live_guard_count", "native_uj_core_get_l_g_count")
}

public plugin_init()
{
  register_plugin(PLUGIN_NAME, PLUGIN_VERS, PLUGIN_AUTH);

  /*// New round
  register_event("HLTV", "event_new_round", "a", "1=0", "2=0");
  // Player spawn
  RegisterHam(Ham_Spawn, "player", "fwHamPlayerSpawnPost", 1);
  // Round start
  register_logevent("LogeventRoundStart", 2, "1=Round_Start");  
  // Round end
  register_logevent("LogeventRoundEnd",   2, "1=Round_End");
  */

  // For blocking pickups
  RegisterHam(Ham_Touch, "armoury_entity", "FwdWeaponTouchPre", 0);
  RegisterHam(Ham_Touch, "weaponbox", "FwdWeaponTouchPre", 0);
  RegisterHam(Ham_Touch, "weapon_shield", "FwdWeaponTouchPre", 0);
  //RegisterHam(Ham_AddPlayerItem, "player", "FwdAddPlayerItemPre", 0);

  // Damage taken (also used to control friendly fire)
  RegisterHam(Ham_TakeDamage, "player", "TakeDamage"); // add ", 1" for post
  g_iHhTakeDamagePost = RegisterHam(Ham_TakeDamage, "player", "TakeDamagePost", 1);
  DisableHamForward(g_iHhTakeDamagePost);

  maxPlayers = get_maxplayers();

  // Forwards
  g_forwards[FW_CORE_ROUND_NEW] = CreateMultiForward("uj_fw_core_round_new", ET_IGNORE);
  g_forwards[FW_CORE_PLAYER_SPAWN] = CreateMultiForward("uj_fw_core_player_spawn", ET_IGNORE, FP_CELL);
  g_forwards[FW_CORE_ROUND_START] = CreateMultiForward("uj_fw_core_round_start", ET_IGNORE);
  g_forwards[FW_CORE_ROUND_END] = CreateMultiForward("uj_fw_core_round_end", ET_IGNORE);
  g_forwards[FW_CORE_MAX_HEALTH] = CreateMultiForward("uj_fw_core_get_max_health", ET_IGNORE, FP_CELL, FP_ARRAY);
  g_forwards[FW_CORE_DAMAGE_TAKEN] = CreateMultiForward("uj_fw_core_get_damage_taken", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL, FP_CELL, FP_CELL, FP_ARRAY);

  // CVars
  g_friendlyFire = get_cvar_pointer("mp_friendlyfire");
}


/*
 * Natives
 */
public native_uj_core_block_w_pickup(pluginID, paramCount)
{
  new playerID = get_param(1);
  new bool:block = (get_param(2) ? true : false);

  // If affecting all users, reset bits and use single bool
  if (playerID == 0) {
    g_weaponPickupBlocked = block;
    g_hasPickupBlocked = 0;
    return;
  }
  if (block) {
    set_bit(g_hasPickupBlocked, playerID);
  }
  else {
    clear_bit(g_hasPickupBlocked, playerID);
  }
}

public native_uj_core_get_w_pickup(pluginID, paramCount)
{
  new playerID = get_param(1);

  if (g_weaponPickupBlocked || playerID == 0) {
    return g_weaponPickupBlocked;
  }
  
  return get_bit(g_hasPickupBlocked, playerID);
}

public native_uj_core_set_friend_fire(pluginID, paramCount)
{
  new enabled = get_param(1);
  set_pcvar_num(g_friendlyFire, enabled);
}

public native_uj_core_strip_weapons(pluginID, paramCount)
{
  new playerID = get_param(1);

  if (!is_user_alive(playerID)) {
    return;
  }

  new bool:give_knife = (get_param(2) ? true : false);
  strip_user_weapons(playerID);
  
  if(give_knife) {
    give_item(playerID, "weapon_knife");
  }
    
  set_pdata_int(playerID, OFFSET_PRIMARYWEAPON, 0);
}

public native_uj_core_d_max_health(pluginID, paramCount)
{
  new playerID = get_param(1);
  new data[1];
  data[0] = 100;
  new arrayArg = PrepareArray(data, 1, 1);
  ExecuteForward(g_forwards[FW_CORE_MAX_HEALTH], g_forwardResult, playerID, arrayArg);

  // Forwards may have changed data[0], which contains a user's max health
  new Float:health = float(data[0]);
  set_pev(playerID, pev_max_health, health);
  set_param_byref(2, data[0]);
  //fg_colorchat_print(playerID, playerID, "CORE - data[0]_int = %i, data[0]_float = %f, currentHealth = %f", data[0], float(data[0]), health);
  //return data[0];
}

// TEAM = CSTEAM, aliveOnly = false
public native_uj_core_get_players(pluginID, paramCount)
{
  new bool:aliveOnly = bool:get_param(2);
  new CsTeams:teamID = CsTeams:get_param(3);

  new players[32];
  new playerCount = fixed_get_players(players, aliveOnly, teamID);

  set_array(1, players, playerCount);

  return playerCount;
}

fixed_get_players(players[], bool:aliveOnly=false, CsTeams:CSTeam)
{
  new playerCount = 0;
  
  for (new id = 1; id <= maxPlayers; ++id) {
    if (is_user_connected(id)) {
      if (!aliveOnly || is_user_alive(id)) {
        if (CSTeam == CS_TEAM_UNASSIGNED || cs_get_user_team(id) == CSTeam) {
          players[playerCount] = id;
          ++playerCount;
        }
      }
    }
  }
  return playerCount;
}

fixed_get_player_count(bool:aliveOnly=false, CsTeams:CSTeam)
{
  new playerCount = 0;
  for (new id = 1; id <= maxPlayers; ++id) {
    if (is_user_connected(id) && (!aliveOnly || is_user_alive(id))) {
      if (CSTeam == CS_TEAM_UNASSIGNED || cs_get_user_team(id) == CSTeam) {
        ++playerCount;
      }
    }
  }
  return playerCount;
}

public native_uj_core_get_p_count()
{
  return fixed_get_player_count(false, CS_TEAM_T);
}

public native_uj_core_get_l_p_count()
{
  return fixed_get_player_count(true, CS_TEAM_T);
}

public native_uj_core_get_g_count()
{
  return fixed_get_player_count(false, CS_TEAM_CT);
}

public native_uj_core_get_l_g_count()
{
  return fixed_get_player_count(true, CS_TEAM_CT);
}

/*
 * Events and forwards
 */
/*public event_new_round()
{
  ExecuteForward(g_forwards[FW_CORE_ROUND_NEW], g_forwardResult);
}

public fwHamPlayerSpawnPost(playerID)
{
  if(is_user_alive(playerID)) {
    ExecuteForward(g_forwards[FW_CORE_PLAYER_SPAWN], g_forwardResult, playerID);
  }
}

public LogeventRoundStart()
{
  ExecuteForward(g_forwards[FW_CORE_ROUND_START], g_forwardResult)
}

public LogeventRoundEnd()
{
  ExecuteForward(g_forwards[FW_CORE_ROUND_END], g_forwardResult)
}*/

public FwdWeaponTouchPre(entityID, playerID)
{
  if (!(1<=playerID<=32)) {
    return HAM_IGNORED;
  }
  if (g_weaponPickupBlocked || get_bit(g_hasPickupBlocked, playerID)) {
    return HAM_SUPERCEDE;
  }
  return HAM_IGNORED;

  //return (g_weaponPickupBlocked || (get_bit(g_hasPickupBlocked, playerID) && is_user_alive(playerID))) ? HAM_SUPERCEDE : HAM_IGNORED;
}

public FwdAddPlayerItemPre(playerID, entityID)
{
  if (!(1<=playerID<=32)) {
    return HAM_IGNORED;
  }
  
  new weaponID=cs_get_weapon_id(entityID);
  if (!weaponID) {
    return HAM_IGNORED;
  }

  if (g_weaponPickupBlocked || get_bit(g_hasPickupBlocked, playerID)) {
    SetHamReturnInteger(1);
    return HAM_SUPERCEDE;
  }

  return HAM_IGNORED;
}

public TakeDamage(victimID, inflictorID, attackerID, Float:originalDamage, damagebits)
{
  if(!(1<= victimID <= 32) || !(1<= attackerID <= 32) || (victimID == attackerID)) {
    return HAM_IGNORED;
  }

  if (get_pcvar_num(g_friendlyFire)) {
    g_iVictimTeam = cs_get_user_team_index(victimID);
    if(g_iVictimTeam == cs_get_user_team_index(attackerID)) {
      cs_set_user_team_index(victimID, g_iVictimTeam == TEAM_T ? TEAM_CT : TEAM_T);
      EnableHamForward(g_iHhTakeDamagePost);
    }
  }
  // Retrieve and store the initial, adjusted damage taken
  // (not the same as the unadjusted orginalDamage)
  new data[1];
  //data[0] = pev(victimID, pev_dmg_take);
  data[0] = floatround(originalDamage);
  new arrayArg = PrepareArray(data, 1, 1);

  // Call forwards, and save the result
  //fg_colorchat_print(attackerID, attackerID, "Original: %f, casted %i", originalDamage, data[0])
  ExecuteForward(g_forwards[FW_CORE_DAMAGE_TAKEN], g_forwardResult, victimID, inflictorID, attackerID, originalDamage, damagebits, arrayArg);
  new Float:result = float(data[0]);
  //set_pev(victimID, pev_dmg_take, result);

  //fg_colorchat_print(attackerID, attackerID, "Retrieved: %i, floated %f", data[0], result);

  // This sets the pre-adjusted damage,
  // which is not what we want.
  // SetHamParamFloat(4, data[0]);

  // However, if this is HAM_TAKEDAMAGE and *not* post, then
  // the dmg will be adjusted for us anyways (correct?)
  SetHamParamFloat(4, result);
  return HAM_HANDLED;
}

public TakeDamagePost(victimID)
{
  cs_set_user_team_index(victimID, g_iVictimTeam);
  DisableHamForward(g_iHhTakeDamagePost);
}


/*
 * Helper functions
 */

stock in_array(needle, data[], size)
{
  for(new i = 0; i < size; i++) {
    if(data[i] == needle) {
      return i
    }
  }
  return -1;
}
