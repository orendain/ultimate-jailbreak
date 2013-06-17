#include <amxmodx>
#include <cstrike>
#include <fakemeta>
#include <fun>
#include <uj_core>
#include <uj_effects>
#include <uj_menus>
#include <uj_items>
#include <uj_colorchat>

new const PLUGIN_NAME[] = "[UJ] Item - Crowbar";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

new const ITEM_NAME[] = "Crowbar";
new const ITEM_MESSAGE[] = "Permanently attached! Smash some faces!";
new const ITEM_COST[] = "50";
new const ITEM_REBEL[] = "false";

new const CROWBAR_DAMAGE[] = "1.15";

new const CROWBAR_MODEL_WEAP[] = "models/p_crowbar.mdl";
new const CROWBAR_MODEL_VIEW[] = "models/v_crowbar.mdl";

// when on the floor? "models/w_crowbar.mdl" };

new const CROWBAR_SOUNDS[][] = {
  "weapons/cbar_hitbod2.wav",
  "weapons/cbar_hit1.wav",
  "weapons/cbar_miss1.wav",
  "weapons/bullet_hit2.wav",

  // These are currently unused
  "weapons/cbar_hitbod1.wav",
  "weapons/bullet_hit1.wav",
  "weapons/knife_slash1.wav",
  "debris/metal2.wav",
  "items/gunpickup2.wav"
};

// Menu variables
new g_menuShop;
new g_item;

// Common CVars
new g_costCVar;
new g_rebelCVar;

// Item-pecific CVars
new g_crowbarDamage;

// Keep track of who has speed
new g_hasCrowbar;

public plugin_precache()
{
  for(new i = 0; i < sizeof(CROWBAR_SOUNDS); i++)
    precache_sound(CROWBAR_SOUNDS[i]);

  precache_model(CROWBAR_MODEL_WEAP);
  precache_model(CROWBAR_MODEL_VIEW);
}

public plugin_init()
{
  register_plugin(PLUGIN_NAME, PLUGIN_VERS, PLUGIN_AUTH);

  // Register CVars
  g_costCVar = register_cvar("uj_item_crowbar_cost", ITEM_COST);
  g_rebelCVar = register_cvar("uj_item_crowbar_rebel", ITEM_REBEL);
  g_crowbarDamage = register_cvar("uj_item_crowbar damage", CROWBAR_DAMAGE);

  // Register this item
  g_item = uj_items_register(ITEM_NAME, ITEM_MESSAGE, g_costCVar, g_rebelCVar);

  // Find the menu that item should appear in
  g_menuShop = uj_menus_get_menu_id("Shop Menu");

  register_forward(FM_EmitSound , "FwdEmitSound");
  //register_touch(g_szClassNameCrowbar, "worldspawn", "CrowbarTouch");
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

  // Only display items to prisoners
  if (cs_get_user_team(playerID) != CS_TEAM_T) {
    return UJ_ITEM_DONT_SHOW;
  }
  
  // Disable if player already has this item
  if (get_bit(g_hasCrowbar, playerID)) {
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

  give_crowbar(playerID);
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

  remove_crowbar(playerID);
}

give_crowbar(playerID)
{
  if (!get_bit(g_hasCrowbar, playerID)) {
    set_bit(g_hasCrowbar, playerID);
    uj_effects_set_view_model(playerID, CSW_KNIFE, CROWBAR_MODEL_VIEW);
    uj_effects_set_weap_model(playerID, CSW_KNIFE, CROWBAR_MODEL_WEAP);
  }
  return PLUGIN_HANDLED;
}

remove_crowbar(playerID)
{
  if (get_bit(g_hasCrowbar, playerID)) {
    uj_effects_reset_view_model(playerID, CSW_KNIFE);
    uj_effects_reset_weap_model(playerID, CSW_KNIFE);
    clear_bit(g_hasCrowbar, playerID);
  }
}

public FwdEmitSound(playerID, iChannel, const szSound[], Float: flVolume, Float: iAttn, iFlags, iPitch)
{
  if(is_user_alive(playerID) && get_bit(g_hasCrowbar, playerID) && equal(szSound, "weapons/knife_", 14)) {
    switch(szSound[17])
    {
      case('b'): emit_sound(playerID, CHAN_WEAPON, CROWBAR_SOUNDS[0], 1.0, ATTN_NORM, 0, PITCH_NORM);
      case('w'): emit_sound(playerID, CHAN_WEAPON,CROWBAR_SOUNDS[1], 1.0, ATTN_NORM, 0, PITCH_LOW);
      case('1', '2'): emit_sound(playerID, CHAN_WEAPON, CROWBAR_SOUNDS[3], random_float(0.5, 1.0), ATTN_NORM, 0, PITCH_NORM);
      case('s'): emit_sound(playerID, CHAN_WEAPON, CROWBAR_SOUNDS[2], 1.0, ATTN_NORM, 0, PITCH_NORM);
    }
    return FMRES_SUPERCEDE;
  }

  return FMRES_IGNORED;
}

// Called when determining the final damage to compute
public uj_fw_core_get_damage_taken(victimID, inflictorID, attackerID, float:originalDamage, damagebits, data[])
{
  if ((1<=attackerID<=32) && get_bit(g_hasCrowbar, attackerID)) {
    data[0] *= get_pcvar_num(g_crowbarDamage);
  }

  // Not sure if needed or not
  return;
}
