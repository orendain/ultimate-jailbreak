#include <amxmodx>
#include <fun>
#include <cstrike>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <uj_chargers>
#include <uj_core>
#include <uj_effects>
#include <uj_menus>
#include <uj_days>

new const PLUGIN_NAME[] = "[UJ] Day - Nightcrawlers";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

new const DAY_NAME[] = "Nightcrawlers";
new const DAY_OBJECTIVE[] = "They're around here ... somwhere ...";
new const DAY_SOUND[] = "ultimate_jailbreak/nightcrawlerday.wav";

new const NIGHTCRAWLERS_KNIFE_MODEL[] = "models/ultimate_jailbreak/v_nightcrawler-sword.mdl";
new const NIGHTCRAWLERS_TELEPORT_SOUND[] = "ultimate_jailbreak/teleport.wav";

new const NIGHTCRAWLERS_PRIMARY_AMMO[] = "200";
new const NIGHTCRAWLERS_SECONDARY_AMMO[] = "50";
new const NIGHTCRAWLERS_SPEED[] = "1.2";

// Day variables
new g_day = UJ_DAY_INVALID;
new bool:g_dayEnabled;

// Menu variables
new g_menuSpecial;

// CVar variables
new g_primaryAmmoPCVar;
new g_secondaryAmmoPCVar;
new g_speedPCVar;

new g_iMsgFog;

new const g_szLaserSprite[ ] = "sprites/ultimate_jailbreak/psybeam.spr";
new g_iLaserSprite;

public plugin_precache()
{
  precache_sound(DAY_SOUND);
  precache_model(NIGHTCRAWLERS_KNIFE_MODEL);

  g_iLaserSprite = precache_model(g_szLaserSprite);
}

public plugin_init()
{
  register_plugin(PLUGIN_NAME, PLUGIN_VERS, PLUGIN_AUTH);

  // CVars
  g_primaryAmmoPCVar = register_cvar("uj_day_nightcrawlers_primary_ammo", NIGHTCRAWLERS_PRIMARY_AMMO);
  g_secondaryAmmoPCVar = register_cvar("uj_day_nightcrawlers_secondary_ammo", NIGHTCRAWLERS_SECONDARY_AMMO);
  g_speedPCVar = register_cvar("uj_day_chicken_speed", NIGHTCRAWLERS_SPEED);

  // Register this day
  g_day = uj_days_register(DAY_NAME, DAY_OBJECTIVE, DAY_SOUND);

  // Find all menus to allow this day to display in
  g_menuSpecial = uj_menus_get_menu_id("Special Days");

  register_forward(FM_PlayerPreThink, "Fwd_PlayerPreThink");
  g_iMsgFog = get_user_msgid("Fog");
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

  // If already enabled, disabled this option
  if (g_dayEnabled) {
    return UJ_DAY_NOT_AVAILABLE;
  }

  return UJ_DAY_AVAILABLE;
}

public uj_fw_days_select_post(playerID, dayID)
{
  // This is not our day - do not continue
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

    // Find ammo counts
    new primaryAmmoCount = get_pcvar_num(g_primaryAmmoPCVar);
    new secondaryAmmoCount = get_pcvar_num(g_secondaryAmmoPCVar);

    // Set models for all players
    new players[32], playerID;
    new playerCount = uj_core_get_players(players, true, CS_TEAM_T);
    for (new i = 0; i < playerCount; ++i) {
      playerID = players[i];

      uj_core_strip_weapons(playerID);
      give_item(playerID, "weapon_m4a1");
      give_item(playerID, "weapon_deagle");
      cs_set_user_bpammo(playerID, CSW_M4A1, primaryAmmoCount);
      cs_set_user_bpammo(playerID, CSW_DEAGLE, secondaryAmmoCount);
    }

    playerCount = uj_core_get_players(players, true, CS_TEAM_CT);
    for (new i = 0; i < playerCount; ++i) {
      playerID = players[i];

      uj_core_strip_weapons(playerID);

      uj_effects_set_visibility(playerID, 0);
      uj_effects_set_view_model(playerID, CSW_KNIFE, NIGHTCRAWLERS_KNIFE_MODEL);
      set_user_footsteps(playerID, 1);
      uj_effects_reset_max_speed(playerID);
    }

    set_lights("d");
    set_fog(true);

    uj_core_block_weapon_pickup(0, true);
    uj_chargers_block_heal(0, true);
    uj_chargers_block_armor(0, true);
  }
}

end_day()
{
  if (g_dayEnabled) {
    // Reset all models
    new players[32];
    new playerCount = uj_core_get_players(players, false, CS_TEAM_CT);
    for (new i = 0; i < playerCount; ++i) {
      uj_effects_reset_view_model(players[i], CSW_KNIFE);
      uj_effects_reset_visibility(players[i]);
      set_user_footsteps(players[i], 0);
    }

    set_lights("m");
    set_fog(false);

    uj_core_block_weapon_pickup(0, false);
    uj_chargers_block_heal(0, false);
    uj_chargers_block_armor(0, false);

    g_dayEnabled = false;
  }
}

public Fwd_PlayerPreThink(playerID)  
{ 
  if(g_dayEnabled && is_user_alive(playerID)) {
    switch(cs_get_user_team(playerID)) {
      case CS_TEAM_CT: {
        new button = get_user_button(playerID);
        if(button & IN_USE || button & IN_RELOAD) {
          // Use button = climb, reload button = teleport
          wallclimb(playerID, button);
        }
      }
      case CS_TEAM_T: {
        set_laser(playerID);
      }
    }
  }
}

public set_fog(bool:fogOn)
{
  if(fogOn) {
    message_begin(MSG_ALL,g_iMsgFog,{0,0,0},0);
    write_byte(50);  // red
    write_byte(50);    // green
    write_byte(50);    // blue
    write_byte(10);   // Start distance
    write_byte(41);   // Start distance
    write_byte(95);   // End distance
    write_byte(59);   // End distance
    message_end();  
  }
  else {
    message_begin(MSG_ALL,g_iMsgFog,{0,0,0},0);
    write_byte(0);    // red
    write_byte(0);    // green
    write_byte(0);    // blue
    write_byte(0);    // Start distance
    write_byte(0);    // Start distance
    write_byte(0);    // End distance
    write_byte(0);    // End distance
    message_end();
  }
}

new Float:g_wallorigin[32][3];

public wallclimb(playerID, button)
{
  static Float:origin[3]; 
  pev(playerID, pev_origin, origin);
  
  /*if(button & IN_RELOAD && !get_bit(g_bTeleport, playerID) && g_bTeleportUsed[playerID] < 3)
  { 
    g_bTeleportUsed[playerID]++;
    uj_colorchat_print(playerID, UJ_COLORCHAT_BLUE, "You have ^4%d^1 teleports left!", (3-g_bTeleportUsed[playerID]));

    emit_sound(playerID, CHAN_AUTO, NIGHTCRAWLERS_TELEPORT_SOUND, 1.0, ATTN_NORM, 0, PITCH_NORM);
    set_bit(g_bTeleport, playerID);
    set_task(5.0, "resetteleport", playerID);
    static Float:start[3], Float:dest[3];
    pev(playerID, pev_origin, start);
    pev(playerID, pev_view_ofs, dest);
    xs_vec_add(start, dest, start);
    
    pev(playerID, pev_v_angle, dest);
    engfunc(EngFunc_MakeVectors, dest);
    global_get(glb_v_forward, dest);
    xs_vec_mul_scalar(dest, 9999.0, dest);
    xs_vec_add(start, dest, dest);
    
    engfunc(EngFunc_TraceLine, start, dest, IGNORE_MONSTERS, playerID, 0);
    get_tr2(0, TR_vecEndPos, start);
    get_tr2(0, TR_vecPlaneNormal, dest);
    
    static const player_hull[] = { HULL_HUMAN, HULL_HEAD };
    engfunc(EngFunc_TraceHull, start, start, DONT_IGNORE_MONSTERS, player_hull[_:!!(pev(playerID, pev_flags) & FL_DUCKING)], playerID, 0);
    if (!get_tr2(0, TR_StartSolid) && !get_tr2(0, TR_AllSolid) && get_tr2(0, TR_InOpen)) {
      engfunc(EngFunc_SetOrigin, playerID, start);
      return FMRES_HANDLED;
    }
    
    static Float:size[3];
    pev(playerID, pev_size, size);
    xs_vec_mul_scalar(dest, (size[0] + size[1]) / 2.0, dest);
    xs_vec_add(start, dest, dest);
    
    engfunc(EngFunc_SetOrigin, playerID, dest);
    if(is_user_stuck(playerID))
      ClientCommand_UnStuck(playerID);
    return FMRES_HANDLED;
  } */
  
  if(get_distance_f(origin, g_wallorigin[playerID]) > 10.0) 
    return FMRES_IGNORED;
  
  if(get_entity_flags(playerID) & FL_ONGROUND) 
    return FMRES_IGNORED; 

  if(button & IN_FORWARD) {
    static Float:velocity[3]; 
    velocity_by_aim(playerID, 275, velocity); 
    set_user_velocity(playerID, velocity); 
  }
  else if(button & IN_BACK) {
    static Float:velocity[3]; 
    velocity_by_aim(playerID, -120, velocity);
    set_user_velocity(playerID, velocity);
  }
  return FMRES_IGNORED; 
}

const WEAPONS_PISTOLS = (1<<CSW_P228)|(1<<CSW_ELITE)|(1<<CSW_FIVESEVEN)|(1<<CSW_USP)|(1<<CSW_GLOCK18)|(1<<CSW_DEAGLE);
const WEAPONS_SHOTGUNS = (1<<CSW_XM1014)|(1<<CSW_M3);
const WEAPONS_SUBMACHINEGUNS = (1<<CSW_MAC10)|(1<<CSW_UMP45)|(1<<CSW_MP5NAVY)|(1<<CSW_TMP)|(1<<CSW_P90);
const WEAPONS_RIFLES = (1<<CSW_SCOUT)|(1<<CSW_AUG)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<CSW_M4A1)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47);
const WEAPONS_MACHINEGUNS = (1<<CSW_M249);

const VALID_WEAPONS = WEAPONS_PISTOLS|WEAPONS_SHOTGUNS|WEAPONS_SUBMACHINEGUNS|WEAPONS_RIFLES|WEAPONS_MACHINEGUNS;

#define PRIMARY_WEAPONS_BIT    (WEAPONS_SHOTGUNS|WEAPONS_SUBMACHINEGUNS|WEAPONS_RIFLES|WEAPONS_MACHINEGUNS)
#define SECONDARY_WEAPONS_BIT    (WEAPONS_PISTOLS)

#define IsPrimaryWeapon(%1) ( (1<<%1) & PRIMARY_WEAPONS_BIT )
#define IsSecondaryWeapon(%1) ( (1<<%1) & WEAPONS_PISTOLS )

public set_laser(id)
{
  //if(g_iRandom == id && g_iRandom != 0)
  //{
    static iTarget, iBody, iRed, iGreen, iBlue, iWeapon;
    get_user_aiming(id, iTarget, iBody);
    iWeapon = get_user_weapon(id);
    if(IsPrimaryWeapon(iWeapon) || IsSecondaryWeapon(iWeapon))
    {
      if( is_user_alive(iTarget) && cs_get_user_team(iTarget) != cs_get_user_team(id))
      {
        iRed = 255;
        iGreen = 0;
        iBlue = 0;
      }
      else {
        iRed = 0;
        iGreen = 255;
        iBlue = 0;
      }
      
      static iOrigin[ 3 ];
      get_user_origin(id, iOrigin, 3);
      
      message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
      write_byte(TE_BEAMENTPOINT);
      write_short(id | 0x1000);
      write_coord(iOrigin[0]);
      write_coord(iOrigin[1]);
      write_coord(iOrigin[2]);
      write_short(g_iLaserSprite);
      write_byte(1);
      write_byte(10);
      write_byte(1);
      write_byte(5);
      write_byte(0);
      write_byte(iRed);
      write_byte(iGreen);
      write_byte(iBlue);
      write_byte(150);
      write_byte(25);
      message_end();
    }
  //}
}


/*
 * Called when determining a player's max speed
 */
public uj_effects_determine_max_speed(playerID, data[])
{
  if (g_dayEnabled && cs_get_user_team(playerID) == CS_TEAM_CT) {
    // Need to first cast as Float
    new Float:value = float(data[0]);
    value *= get_pcvar_float(g_speedPCVar);
    data[0] = floatround(value);
  }
}
