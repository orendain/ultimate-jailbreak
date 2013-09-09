#include <amxmodx>
#include <cstrike>
#include <hamsandwich>
#include <uj_colorchat>
#include <uj_core>
#include <uj_effects>
#include <uj_logs>
#include <uj_menus>
#include <uj_playermenu>
#include <uj_requests_const>

new const PLUGIN_NAME[] = "[UJ] Requests";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

// For glow effects
new const GLOW_RED = 255;
new const GLOW_GREEN = 63;
new const GLOW_BLUE = 0;
new const GLOW_ALPHA = 16;

// Plugin variables
new g_pluginID;

// Forward variables
enum _:TOTAL_FORWARDS
{
  FW_REQUEST_SELECT_PRE = 0,
  FW_REQUEST_SELECT_POST,
  FW_REQUEST_REACHED,
  FW_REQUEST_END
};
new g_forwards[TOTAL_FORWARDS];
new g_forwardResult;

// Save menuID for verification
new g_menuIDSave;

// Request variables
enum _:eRequest
{
  eRequestName[32],
  eRequestObjective[192],
  eRequestMenuEntryID
}
new Array:g_requests;
new g_requestCount;
new g_requestCurrent;
new g_proposedRequest;

// Request participants
new g_requestPlayer;
new g_requestTarget;

// Request has been reached this round
new bool:g_requestReached;

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

  // Initialize dynamic arrays
  g_requests = ArrayCreate(eRequest);

  // Set current request to invalid
  g_requestCurrent = UJ_REQUEST_INVALID;
  g_requestReached = false;
}

public plugin_init()
{
  g_pluginID = register_plugin(PLUGIN_NAME, PLUGIN_VERS, PLUGIN_AUTH);

  g_forwards[FW_REQUEST_SELECT_PRE] = CreateMultiForward("uj_fw_requests_select_pre", ET_CONTINUE, FP_CELL, FP_CELL, FP_CELL)
  g_forwards[FW_REQUEST_SELECT_POST] = CreateMultiForward("uj_fw_requests_select_post", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL)
  g_forwards[FW_REQUEST_REACHED] = CreateMultiForward("uj_fw_requests_reached", ET_IGNORE, FP_CELL);
  g_forwards[FW_REQUEST_END] = CreateMultiForward("uj_fw_requests_end", ET_IGNORE, FP_CELL)

  // To capture last requests
  RegisterHam(Ham_Killed, "player", "FwPlayerKilled");
}

public plugin_natives()
{
  register_library("uj_requests")
  register_native("uj_requests_register", "native_uj_requests_register")
  register_native("uj_requests_get_id", "native_uj_requests_get_id")
  register_native("uj_requests_start", "native_uj_requests_start")
  register_native("uj_requests_get_current", "native_uj_requests_get_current")
  register_native("uj_requests_end", "native_uj_requests_end")
}

public native_uj_requests_register(pluginID, paramCount)
{
  new request[eRequest];
  get_string(1, request[eRequestName], charsmax(request[eRequestName]))
  
  if (strlen(request[eRequestName]) < 1)
  {
    log_error(AMX_ERR_NATIVE, "[UJ] Can't register request with an empty name")
    return UJ_REQUEST_INVALID;
  }
  
  new tempRequest[eRequest];
  for (new index = 0; index < g_requestCount; index++)
  {
    ArrayGetArray(g_requests, index, tempRequest);
    if (equali(request[eRequestName], tempRequest[eRequestName]))
    {
      log_error(AMX_ERR_NATIVE, "[UJ] Request already registered (%s)", request[eRequestName])
      return UJ_REQUEST_INVALID;
    }
  }

  new entryID = uj_menus_register_entry(request[eRequestName]);
  if (entryID == UJ_MENU_INVALID)
    return UJ_REQUEST_INVALID;

  get_string(2, request[eRequestObjective], charsmax(request[eRequestObjective]));
  request[eRequestMenuEntryID] = entryID;
  ArrayPushArray(g_requests, request);
  
  g_requestCount++
  return (g_requestCount-1);
}

public native_uj_requests_get_id(pluginID, paramCount)
{
  new name[32];
  get_string(1, name, charsmax(name));

  new request[eRequest];
  for(new i = 0; 0 < g_requestCount; ++i) {
    ArrayGetArray(g_requests, i, request);
    if (equali(name, request[eRequestName])) {
      return i;
    }
  }
  return UJ_REQUEST_INVALID;
}

public native_uj_requests_get_current(pluginID, paramCount)
{
  return (g_requestCurrent >= 0) ? g_requestCurrent : UJ_REQUEST_INVALID;
}

/*
 * While a user selecting a request through a menu
 * does not go through this function.  This may still
 * be used to force a day to start between two players.
 */
public native_uj_requests_start(pluginID, paramCount)
{
  new playerID = get_param(1);
  new targetID = get_param(2);
  new requestID = get_param(3);

  // Check to see if requestID is even a valid request
  if (requestID >= 0 && requestID < g_requestCount) {
    start_request(playerID, targetID, requestID);
  }
}

public native_uj_requests_end(pluginID, paramCount)
{
  end_current_request();
}

end_current_request()
{
  if (g_requestCurrent != UJ_REQUEST_INVALID) {
    new request[eRequest];
    ArrayGetArray(g_requests, g_requestCurrent, request);

    ExecuteForward(g_forwards[FW_REQUEST_END], g_forwardResult, g_requestCurrent);
    uj_colorchat_print(0, UJ_COLORCHAT_RED, "^4%s^1 is now over!", request[eRequestName]);

    // Unglow players
    uj_effects_glow_reset(g_requestPlayer);
    uj_effects_glow_reset(g_requestTarget);

    g_requestPlayer = 0;
    g_requestTarget = 0;
    g_requestCurrent = UJ_REQUEST_INVALID;
    g_requestReached = false;
  }
}

// Player has been killed or has disconnected. Check for last request
public FwPlayerKilled(playerID)
{
  check_for_last_request(playerID);
}
public client_disconnect(playerID)
{
  check_for_last_request(playerID);
}
check_for_last_request(playerID)
{
  // A request is currently active
  if (g_requestCurrent != UJ_REQUEST_INVALID) {

    // The requester has died/disconnected
    if (playerID == g_requestPlayer) {
      end_current_request();
    }
    // The target has died/disconnected
    else if (playerID == g_requestTarget) {
      end_current_request();
      g_requestPlayer = find_survivor();
      ExecuteForward(g_forwards[FW_REQUEST_REACHED], g_forwardResult, g_requestPlayer);
    }
  }
  else if (!g_requestReached) {
    // No request is active, check to see if we should start one
    if (can_start_request()) {
      g_requestReached = true;
      g_requestPlayer = find_survivor();
      ExecuteForward(g_forwards[FW_REQUEST_REACHED], g_forwardResult, g_requestPlayer);
    }
  }
}

can_start_request()
{
  return (uj_core_get_live_prisoner_count() == 1 && uj_core_get_live_guard_count() > 0);
}

find_survivor()
{
  new players[32];
  uj_core_get_players(players, true, CS_TEAM_T);
  return players[0];
}


/*
 * Menu forwards
 */

/*
 * Process all request entries.  After calling each requests' pre-forward,
 * the user will choose which one they want to start, which leads to uj_fw_menus_select_post();
 */
public uj_fw_menus_select_pre(playerID, menuID, entryID)
{
  new requestID = find_requestID(entryID);
  if (requestID < 0) { // not a request, do not block
    return UJ_MENU_AVAILABLE;
  }

  // Execute item forward and store result
  ExecuteForward(g_forwards[FW_REQUEST_SELECT_PRE], g_forwardResult, playerID, requestID, menuID)
  g_menuIDSave = menuID;

  if(g_forwardResult == UJ_REQUEST_NOT_AVAILABLE) {
    return UJ_MENU_NOT_AVAILABLE;
  }
  else if(g_forwardResult == UJ_REQUEST_DONT_SHOW) {
    return UJ_MENU_DONT_SHOW;
  }

  return UJ_MENU_AVAILABLE;
}

/*
 * The user has chosen the request they wish to start.
 * Now display a list of guards to select from.
 * Listen for response in uj_fw_playermenu_player_select()
 */
public uj_fw_menus_select_post(playerID, menuID, entryID)
{
  new requestID = find_requestID(entryID);
  if (requestID < 0) { // not an item, do not forward
    return;
  }

  g_proposedRequest = requestID;

  // Now find the target the player wants to go up against
  // After this call, wait for response (if any) through uj_fw_playermenu_player_select()
  new players[32];
  new playerCount = uj_core_get_players(players, true, CS_TEAM_CT);
  uj_playermenu_show_players(playerID, players, playerCount);
  //uj_playermenu_show_team_players(playerID, "ae", "CT");
}

start_request(playerID, targetID, requestID)
{
  // End current request
  end_current_request();

  g_requestPlayer = playerID;
  g_requestTarget = targetID;

  // Set new request
  g_requestCurrent = requestID;

  // Retrieve request data
  new request[eRequest];
  ArrayGetArray(g_requests, g_requestCurrent, request);

  // Get user names
  new playerName[32], targetName[32];
  get_user_name(g_requestPlayer, playerName, charsmax(playerName));
  get_user_name(g_requestTarget, targetName, charsmax(targetName));

  // Glow players
  uj_effects_glow_player(g_requestPlayer, GLOW_RED, GLOW_GREEN, GLOW_BLUE, GLOW_ALPHA);
  uj_effects_glow_player(g_requestTarget, GLOW_RED, GLOW_GREEN, GLOW_BLUE, GLOW_ALPHA);

  // Display message
  uj_colorchat_print(0, UJ_COLORCHAT_RED, "^3%s^1 vs ^3%s^1!", playerName, targetName);
  uj_colorchat_print(0, UJ_COLORCHAT_RED, "The Last Request is: ^4%s^1! %s", request[eRequestName], request[eRequestObjective]);
  uj_logs_log("[uj_requests] %s chose %s for the LR %s", playerName, targetName, request[eRequestName]);

  // Execute request forward
  ExecuteForward(g_forwards[FW_REQUEST_SELECT_POST], g_forwardResult, playerID, targetID, g_requestCurrent);
}

stock find_requestID(entryID)
{
  new request[eRequest];
  for (new requestID = 0; requestID < g_requestCount; ++requestID)
  {
    ArrayGetArray(g_requests, requestID, request);
    if (entryID == request[eRequestMenuEntryID]) {
      return requestID;
    }
  }
  return UJ_REQUEST_INVALID;
}

/*
 * The player has selected someone to challenge. Begin a request.
 */
public uj_fw_playermenu_player_select(pluginID, playerID, targetID)
{
  // Not intiated by us - don't continue
  if (pluginID != g_pluginID) {
    return;
  }

  // Before starting request, check for validity one more time
  ExecuteForward(g_forwards[FW_REQUEST_SELECT_PRE], g_forwardResult, playerID, g_proposedRequest, g_menuIDSave)
  if (g_forwardResult != UJ_REQUEST_AVAILABLE) {
    return;
  }

  // Before starting the request, check to see if this player still has LR
  if (can_start_request() && playerID == find_survivor()) {
    // Also check to make sure target has not died while waiting for selection
    if (is_user_alive(targetID)) {
      start_request(playerID, targetID, g_proposedRequest);
    }
  }
}

/*
 * When a new round is started, reset LR notifier.
 */
public uj_fw_core_round_new