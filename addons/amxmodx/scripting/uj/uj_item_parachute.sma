#include <amxmodx>
#include <engine>
#include <fun>
#include <uj_core>
#include <uj_effects>
#include <uj_menus>
#include <uj_items>
#include <fg_colorchat>

new const PLUGIN_NAME[] = "UJ | Item - Parachute";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

new const ITEM_NAME[] = "Parachute";
new const ITEM_MESSAGE[] = "You'll fly like a feather in the breeze...";
new const ITEM_COST[] = "10";
new const ITEM_REBEL[] = "0";

new const PARACHUTE_FALLSPEED[] = "100";
new const PARACHUTE_MODEL[] = "models/ultimate_jailbreak/parachute.mdl";

#define MAX_PLAYERS 32

// Menu variables
new g_menuShop;
new g_item;

// Common CVars
new g_costCVar;
new g_rebelCVar;

// Item-pecific CVars
new g_fallspeed;

// Keep track of who has speed
new g_hasParachute;
new g_paraEntity[MAX_PLAYERS+1];

public plugin_precache()
{
  precache_model(PARACHUTE_MODEL);
}

public plugin_init()
{
  register_plugin(PLUGIN_NAME, PLUGIN_VERS, PLUGIN_AUTH);

  // Register CVars
  g_costCVar = register_cvar("uj_item_parachute_cost", ITEM_COST);
  g_rebelCVar = register_cvar("uj_item_parachute_rebel", ITEM_REBEL);
  g_fallspeed = register_cvar("uj_item_parachute_fallspeed", PARACHUTE_FALLSPEED);

  // Register this item
  g_item = uj_items_register(ITEM_NAME, ITEM_MESSAGE, g_costCVar, g_rebelCVar);

  // Find the menu that item should appear in
  g_menuShop = uj_menus_get_menu_id("Shop Menu");
}

/*
 * This is called when determining if an item should be displayed
 * on a certain menu.
 */
public uj_fw_items_select_pre(playerID, itemID, menuID)
{
  // This is not our item - so do not block from showing
  if (itemID != g_item) {
    return UJ_ITEM_AVAILABLE;
  }

  // Only display if it appears in the menu we retrieved in plugin_init()
  if (menuID != g_menuShop) {
    return UJ_ITEM_DONT_SHOW;
  }
  
  // Disable if player already has this item
  if (get_bit(g_hasParachute, playerID)) {
    return UJ_ITEM_NOT_AVAILABLE;
  }

  return UJ_ITEM_AVAILABLE;
}

/*
 * This is called after an item has been selected from a menu.
 */
public uj_fw_items_select_post(playerID, itemID, menuID)
{
  // This is not our item - do not continue
  if (g_item != itemID)
    return;

  give_parachute(playerID);
}

/*
 * This is called when an item should be removed from a player.
 */
public uj_fw_items_strip_item(playerID, itemID)
{
  // This is not our item - do not continue
  // If itemID is UJ_ITEM_ALL_ITEMS, then all items are affected
  if ((itemID != g_item) &&
      (itemID != UJ_ITEM_ALL_ITEMS)) {
    return;
  }

  remove_parachute(playerID);
}

give_parachute(playerID)
{
  if (!get_bit(g_hasParachute, playerID)) {
    set_bit(g_hasParachute, playerID);
  }
  return PLUGIN_HANDLED;
}

remove_parachute(playerID)
{
  // We don't strip the user of his/her nades
  if (get_bit(g_hasParachute, playerID)) {
    remove_entity(playerID);
    set_user_gravity(playerID, 1.0)

    g_paraEntity[playerID] = 0;
    clear_bit(g_hasParachute, playerID);
  }
}

public client_PreThink(playerID)
{
  //parachute.mdl animation information
  //0 - deploy - 84 frames
  //1 - idle - 39 frames
  //2 - detach - 29 frames

  if (!get_bit(g_hasParachute, playerID) || !is_user_alive(playerID)) return

  new Float:fallspeed = get_pcvar_float(g_fallspeed) * -1.0
  new Float:frame

  new button = get_user_button(playerID)
  new oldbutton = get_user_oldbutton(playerID)
  new flags = get_entity_flags(playerID)

  if (g_paraEntity[playerID] > 0 && (flags & FL_ONGROUND)) {
    if (get_user_gravity(playerID) == 0.1)
      set_user_gravity(playerID, 1.0)

    if (entity_get_int(g_paraEntity[playerID],EV_INT_sequence) != 2) {
      entity_set_int(g_paraEntity[playerID], EV_INT_sequence, 2)
      entity_set_int(g_paraEntity[playerID], EV_INT_gaitsequence, 1)
      entity_set_float(g_paraEntity[playerID], EV_FL_frame, 0.0)
      entity_set_float(g_paraEntity[playerID], EV_FL_fuser1, 0.0)
      entity_set_float(g_paraEntity[playerID], EV_FL_animtime, 0.0)
      entity_set_float(g_paraEntity[playerID], EV_FL_framerate, 0.0)
      return
    }

    frame = entity_get_float(g_paraEntity[playerID],EV_FL_fuser1) + 2.0
    entity_set_float(g_paraEntity[playerID],EV_FL_fuser1,frame)
    entity_set_float(g_paraEntity[playerID],EV_FL_frame,frame)

    if (frame > 254.0) {
      remove_entity(g_paraEntity[playerID])
      g_paraEntity[playerID] = 0
    }
  
    return
  }

  if (button & IN_USE) {
    new Float:velocity[3]
    entity_get_vector(playerID, EV_VEC_velocity, velocity)

    if (velocity[2] < 0.0) {
      if(g_paraEntity[playerID] <= 0) {
        g_paraEntity[playerID] = create_entity("info_target")
        if(g_paraEntity[playerID] > 0) {
          entity_set_string(g_paraEntity[playerID],EV_SZ_classname,"parachute")
          entity_set_edict(g_paraEntity[playerID], EV_ENT_aiment, playerID)
          entity_set_edict(g_paraEntity[playerID], EV_ENT_owner, playerID)
          entity_set_int(g_paraEntity[playerID], EV_INT_movetype, MOVETYPE_FOLLOW)
          entity_set_model(g_paraEntity[playerID], PARACHUTE_MODEL)
          entity_set_int(g_paraEntity[playerID], EV_INT_sequence, 0)
          entity_set_int(g_paraEntity[playerID], EV_INT_gaitsequence, 1)
          entity_set_float(g_paraEntity[playerID], EV_FL_frame, 0.0)
          entity_set_float(g_paraEntity[playerID], EV_FL_fuser1, 0.0)
        }
      }

      if (g_paraEntity[playerID] > 0) {
        entity_set_int(playerID, EV_INT_sequence, 3)
        entity_set_int(playerID, EV_INT_gaitsequence, 1)
        entity_set_float(playerID, EV_FL_frame, 1.0)
        entity_set_float(playerID, EV_FL_framerate, 1.0)
        set_user_gravity(playerID, 0.1)

        velocity[2] = (velocity[2] + 40.0 < fallspeed) ? velocity[2] + 40.0 : fallspeed
        entity_set_vector(playerID, EV_VEC_velocity, velocity)

        if (entity_get_int(g_paraEntity[playerID],EV_INT_sequence) == 0) {
          frame = entity_get_float(g_paraEntity[playerID],EV_FL_fuser1) + 1.0
          entity_set_float(g_paraEntity[playerID],EV_FL_fuser1,frame)
          entity_set_float(g_paraEntity[playerID],EV_FL_frame,frame)

          if (frame > 100.0) {
            entity_set_float(g_paraEntity[playerID], EV_FL_animtime, 0.0)
            entity_set_float(g_paraEntity[playerID], EV_FL_framerate, 0.4)
            entity_set_int(g_paraEntity[playerID], EV_INT_sequence, 1)
            entity_set_int(g_paraEntity[playerID], EV_INT_gaitsequence, 1)
            entity_set_float(g_paraEntity[playerID], EV_FL_frame, 0.0)
            entity_set_float(g_paraEntity[playerID], EV_FL_fuser1, 0.0)
          }
        }
      }
    }
    else if (g_paraEntity[playerID] > 0) {
      remove_entity(g_paraEntity[playerID])
      set_user_gravity(playerID, 1.0)
      g_paraEntity[playerID] = 0
    }
  }
  else if ((oldbutton & IN_USE) && g_paraEntity[playerID] > 0 ) {
    remove_entity(g_paraEntity[playerID])
    set_user_gravity(playerID, 1.0)
    g_paraEntity[playerID] = 0
  }
}
