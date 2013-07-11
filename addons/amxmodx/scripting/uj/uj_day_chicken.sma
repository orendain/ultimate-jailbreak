#include <amxmodx>
#include <cstrike>
#include <fakemeta>
#include <fun>
#include <uj_menus>
#include <uj_chargers>
#include <uj_core>
#include <uj_days>
#include <uj_effects>

new const PLUGIN_NAME[] = "[UJ] Day - Chicken Day";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

new const DAY_NAME[] = "Chicken Day";
new const DAY_OBJECTIVE[] = "BWAAK BWAAAK, HOMIE! BWAAK BWAAAK!";
new const DAY_SOUND[] = "ultimate_jailbreak/chickenday_once.wav";

new const CHICKEN_MODEL[] = "chicken";
new const CHICKEN_HEALTH[] = "250";
new const CHICKEN_SPEED[] = "1.5";
new const CHICKEN_GRAVITY[] = "0.4";
new const CHICKEN_PRIMARY_AMMO[] = "50";
new const CHICKEN_SOUND_COOLDOWN[] = "1.0";

new const CHICKEN_SOUNDS[][] =
{
  "ultimate_jailbreak/misc/chicken1.wav",
  "ultimate_jailbreak/misc/chicken2.wav",
  "ultimate_jailbreak/misc/chicken3.wav",
  "ultimate_jailbreak/misc/chicken4.wav",
  "ultimate_jailbreak/misc/knife_hit1.wav",
  "ultimate_jailbreak/misc/knife_hit3.wav"
};

// Day variables
new g_day;
new bool:g_dayEnabled;

// Menu variables
new g_menuSpecial

// Cvars
new g_primaryAmmoPCVar;
new g_healthPCVar;
new g_speedPCVar;
new g_gravityPCVar;
new g_soundCooldown;

// Day specific variables
new Float:g_lastChickenSound[33];

public plugin_precache()
{
  // Register day
  g_day = uj_days_register(DAY_NAME, DAY_OBJECTIVE, DAY_SOUND)

  // Precache models and sounds
  new path[64]
  formatex(path, charsmax(path), "models/player/%s/%s.mdl", CHICKEN_MODEL, CHICKEN_MODEL);
  precache_model(path);
  
  precache_sound(DAY_SOUND);
  for (new i = 0; i < sizeof(CHICKEN_SOUNDS); ++i) {
    precache_sound(CHICKEN_SOUNDS[i]);
  }
}

public plugin_init()
{
  register_plugin(PLUGIN_NAME, PLUGIN_VERS, PLUGIN_AUTH);

  // Find all valid menus to display this under
  g_menuSpecial = uj_menus_get_menu_id("Special Days");

  // CVars
  g_primaryAmmoPCVar = register_cvar("uj_day_chicken_ammo", CHICKEN_PRIMARY_AMMO);
  g_healthPCVar = register_cvar("uj_day_chicken_health", CHICKEN_HEALTH);
  g_speedPCVar = register_cvar("uj_day_chicken_speed", CHICKEN_SPEED);
  g_gravityPCVar = register_cvar("uj_day_chicken_gravity", CHICKEN_GRAVITY);
  g_soundCooldown = register_cvar("uj_day_chicken_sound_cooldown", CHICKEN_SOUND_COOLDOWN);

  register_forward(FM_EmitSound, "FwdEmitSound");
}

public uj_fw_days_select_pre(playerID, dayID, menuID)
{
  // This is not our day - do not block
  if (dayID != g_day) {
    return UJ_DAY_AVAILABLE;
  }

  // Only display if in the parent menu we recognize
  if (menuID != g_menuSpecial) {
    return UJ_DAY_DONT_SHOW;
  }

  // If we *can* show the menu, but it's already enabled,
  // then have it be unavailable
  if (g_dayEnabled) {
    return UJ_DAY_NOT_AVAILABLE;
  }

  return UJ_DAY_AVAILABLE;
}

public uj_fw_days_select_post(playerID, dayID)
{
  // This is not our item
  if (dayID != g_day)
    return;

  start_day();
}

public uj_fw_days_end(dayID)
{
  // If dayID refers to our day and our day is enabled
  if(dayID == g_day && g_dayEnabled) {
    end_day();
  }
}

start_day()
{
  if (!g_dayEnabled) {
    g_dayEnabled = true;

    // Find settings
    new primaryAmmoCount = get_pcvar_num(g_primaryAmmoPCVar);
    new health = get_pcvar_num(g_healthPCVar);
    //new Float:speed = get_pcvar_float(g_speedPCVar);
    new Float:gravity = get_pcvar_float(g_gravityPCVar);

    new players[32], playerID;
    new playerCount = uj_core_get_players(players, true, CS_TEAM_T);
    for (new i = 0; i < playerCount; ++i) {
      playerID = players[i];
      uj_core_strip_weapons(playerID);
      uj_effects_set_model(playerID, CHICKEN_MODEL);
      //uj_effects_set_max_speed(playerID, speed);
      uj_effects_reset_max_speed(playerID);
      set_user_health(playerID, health);
      set_user_gravity(playerID, gravity);
    }

    playerCount = uj_core_get_players(players, true, CS_TEAM_CT);
    for (new i = 0; i < playerCount; ++i) {
      playerID = players[i];

      // Give user items
      uj_core_strip_weapons(playerID);
      give_item(playerID, "weapon_m3");
      cs_set_user_bpammo(playerID, CSW_M3, primaryAmmoCount);
    }

    uj_core_block_weapon_pickup(0, true);
    uj_chargers_block_heal(0, true);
    uj_chargers_block_armor(0, true);
  }
}

end_day()
{
  // Typically placed at the bottom, but we need it here
  // to affect uj_effects_reset_max_speed
  g_dayEnabled = false;

  new players[32], playerID;
  new playerCount = uj_core_get_players(players, true, CS_TEAM_CT);
  for (new i = 0; i < playerCount; ++i) {
    playerID = players[i];
    uj_core_strip_weapons(playerID);
  }

  playerCount = uj_core_get_players(players, false, CS_TEAM_T);
  for (new i = 0; i < playerCount; ++i) {
    playerID = players[i];
    uj_effects_reset_model(playerID);
    uj_effects_reset_max_speed(playerID);
    set_user_gravity(playerID, 1.0);
  }

  uj_core_block_weapon_pickup(0, false);
  uj_chargers_block_heal(0, false);
  uj_chargers_block_armor(0, false);
}

/*
 * Called when determining a player's max speed
 */
public uj_effects_determine_max_speed(playerID, data[])
{
  if (g_dayEnabled && cs_get_user_team(playerID) == CS_TEAM_T) {
    // Need to first cast as Floats
    new Float:value = float(data[0]);
    value *= get_pcvar_float(g_speedPCVar);
    data[0] = floatround(value);
  }
}

public FwdEmitSound(id, iChannel, const szSound[], Float: flVolume, Float: iAttn, iFlags, iPitch)
{
  if(g_dayEnabled && is_user_alive(id) && cs_get_user_team(id) == CS_TEAM_T)
  {
    if(szSound[0] == 'w' 
    && szSound[1] == 'e' 
    && szSound[8] == 'k' 
    && szSound[9] == 'n'
    && szSound[14] != 'd')
    {
      new Float: flGametime = get_gametime();
      switch(szSound[15])
      {
        case 'l': //slash
        {
          if(g_lastChickenSound[id] + get_pcvar_float(g_soundCooldown) < flGametime)
          {
            iPitch = random_num(100, 120)
            emit_sound(id, CHAN_VOICE, CHICKEN_SOUNDS[random(3)], 1.0, ATTN_NORM, 0, iPitch);
            g_lastChickenSound[id] = flGametime;
          }
          
          return FMRES_SUPERCEDE;
        }
        
        case 't': //stab
        {
          if(g_lastChickenSound[id] + 5.0 < flGametime)
          {
            emit_sound(id, CHAN_WEAPON, CHICKEN_SOUNDS[4], 1.0, ATTN_NORM, 0, PITCH_NORM);
            g_lastChickenSound[id] = flGametime;
          }
          
          return FMRES_SUPERCEDE;
        }
      }

      switch(szSound[17])
      {
        case '2':
        { 
          if(g_lastChickenSound[id] + 5.0 < flGametime)
          {
            emit_sound(id, CHAN_WEAPON, CHICKEN_SOUNDS[5], 1.0, ATTN_NORM, 0, PITCH_NORM);
            g_lastChickenSound[id] = flGametime;
          }
          
          return FMRES_SUPERCEDE;
        }
        case '4':
        {
          if(g_lastChickenSound[id] + 5.0 < flGametime)
          {
            emit_sound(id, CHAN_WEAPON, CHICKEN_SOUNDS[4], 1.0, ATTN_NORM, 0, PITCH_NORM);
            g_lastChickenSound[id] = flGametime;
          }
          
          return FMRES_SUPERCEDE;
        }
        case 'w':
        {
          return FMRES_SUPERCEDE; //remove wallhit
        }
      }
    }
    
    else if(szSound[0] == 'p' 
    && szSound[3] == 'y' 
    && szSound[5] == 'r'
    && (szSound[7] == 'b'
    || szSound[7] == 'd'))
      return FMRES_SUPERCEDE;
  }
  
  return FMRES_IGNORED;
}
