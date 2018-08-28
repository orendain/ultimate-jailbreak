#include <amxmisc>
#include <amxmodx>
#include <fakemeta>
#include <fun>
#include <cstrike>
#include <hamsandwich>
#include <engine>
#include <xs>
#include <dhudmessage>
#include <uj_menus>
#include <uj_chargers>
#include <uj_core>
#include <uj_days>
#include <uj_effects>
#include <uj_colorchat>

#define FIRST_PLAYER_ID 1
#define IsPlayer(%1) (FIRST_PLAYER_ID <= %1 <= g_iMaxPlayers)

#define m_pPlayer 41    // Ham_Item_Deploy (Weapon Owner)
#define OFFSET_LINUX 4    // Weapons Linux Offset

#define IsPrimaryWeapon(%1) ( (1<<%1) & PRIMARY_WEAPONS_BIT )
#define IsSecondaryWeapon(%1) ( (1<<%1) & WEAPONS_PISTOLS )

#define IsWeaponInBits(%1,%2) (((1<<%1) & %2) > 0)

#define PRIMARY_WEAPONS_BIT    (WEAPONS_SHOTGUNS|WEAPONS_SUBMACHINEGUNS|WEAPONS_RIFLES|WEAPONS_MACHINEGUNS)
#define SECONDARY_WEAPONS_BIT    (WEAPONS_PISTOLS)

#define GetPlayerHullSize(%1)  ( ( pev ( %1, pev_flags ) & FL_DUCKING ) ? HULL_HEAD : HULL_HUMAN )

#define START_DISTANCE    32   
// --| How many times to search in an area for a free space.
#define MAX_ATTEMPTS      128

// --| Just for readability.
enum Coord_e { Float:x, Float:y, Float:z }

const WEAPONS_PISTOLS = (1<<CSW_P228)|(1<<CSW_ELITE)|(1<<CSW_FIVESEVEN)|(1<<CSW_USP)|(1<<CSW_GLOCK18)|(1<<CSW_DEAGLE);
const WEAPONS_SHOTGUNS = (1<<CSW_XM1014)|(1<<CSW_M3);
const WEAPONS_SUBMACHINEGUNS = (1<<CSW_MAC10)|(1<<CSW_UMP45)|(1<<CSW_MP5NAVY)|(1<<CSW_TMP)|(1<<CSW_P90);
const WEAPONS_RIFLES = (1<<CSW_SCOUT)|(1<<CSW_AUG)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<CSW_M4A1)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47);
const WEAPONS_MACHINEGUNS = (1<<CSW_M249);

const VALID_WEAPONS = WEAPONS_PISTOLS|WEAPONS_SHOTGUNS|WEAPONS_SUBMACHINEGUNS|WEAPONS_RIFLES|WEAPONS_MACHINEGUNS;


new const PLUGIN_NAME[] = "[UJ] Day - Guards vs Night Crawlers";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

new const DAY_NAME[] = "Guards vs Night Crawlers";
new const DAY_OBJECTIVE[] = "Night Crawlers";
new const DAY_SOUND[] = "";

//new const SPARTA_PRIMARY_AMMO[] = "200";
//new const SPARTA_SECONDARY_AMMO[] = "50";

new g_iMaxPlayers;
new g_iRandom;
new g_iMsgFog;

new g_HasBeenHit;
new g_bTeleport;
new g_bTeleportUsed[33];

// Day variables
new g_day;
new bool:g_dayEnabled;
static const g_iNightCrawlerDayLights[] = "b";

new const NightCrawlerModels[][] = { "models/v_nightcrawler-sword.mdl", "models/player/nightcrawler7/nightcrawler7.mdl" };
new const NightCrawlerSounds[][] = {"nightcrawlerday.wav", "teleport.wav", 
  "sword_strike1.wav", "sword_strike2.wav", "sword_strike3.wav",
  "sword_strike4.wav"
};

new const g_szLaserSprite[ ] = "sprites/zbeam4.spr";
new g_iLaserSprite;

// Menu variables
new g_menuSpecial

// Cvars
//new g_primaryAmmoPCVar;
//new g_secondaryAmmoPCVar;

public plugin_precache()
{
  // Register day
  g_day = uj_days_register(DAY_NAME, DAY_OBJECTIVE, DAY_SOUND)
  g_iLaserSprite = precache_model( g_szLaserSprite );
  
  static i;
  for(i = 0; i < sizeof(NightCrawlerModels); i++)
    precache_model(NightCrawlerModels[i]);
 
  for(i = 0; i < sizeof(NightCrawlerSounds); i++)
    precache_sound(NightCrawlerSounds[i]);    
    
}

public plugin_init()
{
  register_plugin(PLUGIN_NAME, PLUGIN_VERS, PLUGIN_AUTH);

  // Find all valid menus to display this under
  g_menuSpecial = uj_menus_get_menu_id("Special Days");

  // CVars
  //g_primaryAmmoPCVar = register_cvar("uj_day_spartans_primary_ammo", SPARTA_PRIMARY_AMMO);
  //g_secondaryAmmoPCVar = register_cvar("uj_day_spartans_secondary_ammo", SPARTA_SECONDARY_AMMO);
  g_iMaxPlayers   = get_maxplayers();
  RegisterHam(Ham_Touch, "weaponbox", "Fwd_PlayerWeaponTouch"); 
  RegisterHam(Ham_Touch, "armoury_entity", "Fwd_PlayerWeaponTouch");
  RegisterHam(Ham_TakeDamage, "player", "Fwd_PlayerDamage", 0);
  RegisterHam(Ham_Killed, "player", "Fwd_PlayerKilled_Pre", 0);
  RegisterHam(Ham_Item_Deploy, "weapon_knife", "Fwd_ItemDeploy2_Post", 1);
  register_forward(FM_AddToFullPack, "Fwd_AddToFullPack", 1);
  register_forward(FM_PlayerPreThink, "Fwd_PlayerPreThink");
  register_forward(FM_Touch, "Fwd_Touch");  
  g_iMsgFog   = get_user_msgid("Fog");
  
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
    //new primaryAmmoCount = get_pcvar_num(g_primaryAmmoPCVar);
    //new secondaryAmmoCount = get_pcvar_num(g_secondaryAmmoPCVar);
    set_lights(g_iNightCrawlerDayLights);
    msg_create_fog( 255, 255, 255, 2 ); //fog

    new players[32], playerID;
    new playerCount = uj_core_get_players(players, true, CS_TEAM_T);
    for (new i = 0; i < playerCount; ++i) {
      playerID = players[i];

      // Give user items
      uj_core_strip_weapons(playerID);
      //set_tag_player(iPlayer, "Survivor");
      //SaveWeapons(iPlayer);
      GiveItem(playerID, "weapon_m4a1", 200);
      GiveItem(playerID, "weapon_deagle", 125);
      cs_reset_user_model(playerID);
      emit_sound(playerID, CHAN_VOICE, NightCrawlerSounds[0], 1.0, ATTN_NORM, 0, PITCH_NORM);
      
      if(playerID == g_iRandom) 
        g_iRandom = fnGetRandomPlayer();
    }

    playerCount = uj_core_get_players(players, true, CS_TEAM_CT);
    for (new i = 0; i < playerCount; ++i) {
      playerID = players[i];
      
      // Give user items
      uj_core_strip_weapons(playerID);
      //give_item(playerID, "weapon_m4a1");
      //set_tag_player(iPlayer, "NightCrawler"); // Had to add a delay
      clear_bit(g_HasBeenHit, playerID);
      clear_bit(g_bTeleport, playerID);
      g_bTeleportUsed[playerID] = 0;
      //cs_set_user_model(playerID, "nightcrawler3");
      new iOrigin[3];
      get_user_origin(playerID, iOrigin);
      message_begin(MSG_PVS, SVC_TEMPENTITY, iOrigin);
      write_byte(TE_TELEPORT);
      write_coord(iOrigin[0]);
      write_coord(iOrigin[1]);
      write_coord(iOrigin[2]);
      message_end();
      set_task(0.2, "tagtask", playerID);
      //SaveWeapons(playerID);
      //cs_set_user_nvg( playerID, 0 );
      set_user_footsteps(playerID, 1);
      set_user_maxspeed(playerID, 265.0);
      if(g_iRandom == playerID)
        g_iRandom = fnGetRandomPlayer();
    }
    
    uj_core_block_weapon_pickup(0, true);
    uj_chargers_block_heal(0, true);
    uj_chargers_block_armor(0, true);
  }
}

end_day()
{
  new players[32], playerID;
  new playerCount = uj_core_get_players(players, true);
  for (new i = 0; i < playerCount; ++i) {
    playerID = players[i];
    uj_core_strip_weapons(playerID);

    //cs_reset_user_model(playerID);
  }

  set_lights("#OFF");
  fog(false);
  client_cmd( 0, "stopsound" );
  uj_core_block_weapon_pickup(0, false);
  uj_chargers_block_heal(0, false);
  uj_chargers_block_armor(0, false);

  g_dayEnabled = false;
}

public Fwd_PlayerWeaponTouch(const iEntity, const playerID)
{
  if(!IsPlayer(playerID))
    return HAM_IGNORED;

  new Model[32];
  pev(iEntity, pev_model, Model, 31);
    
  static CsTeams:team;
  team = cs_get_user_team(playerID);
  
  if (g_dayEnabled) 
  {
      switch(team)
      {
        case CS_TEAM_T: if (!equal(Model, "models/w_m4a1.mdl")) return HAM_SUPERCEDE;
        case CS_TEAM_CT: return HAM_SUPERCEDE;
      }
   }
   
  return HAM_IGNORED;
}

fnGetRandomPlayer() {
  static iPlayers[32], iNum;
  get_players(iPlayers, iNum, "ae", "TERRORIST"); 
  return iNum ? iPlayers[random(iNum)] : 0;
}

public Player_AddPlayerItem(const playerID, const iEntity)  //anti gun glitch
{
  new iWeapID = cs_get_weapon_id( iEntity );

  if( !iWeapID )
    return HAM_IGNORED;
    
  static CsTeams:team;
  team = cs_get_user_team(playerID);
  if (g_dayEnabled) 
  {
  switch(team)
  {
  case CS_TEAM_T:
  if(iWeapID != CSW_KNIFE && iWeapID != CSW_M4A1)
  {
  SetHamReturnInteger( 1 );
  return HAM_SUPERCEDE;
  }
  case CS_TEAM_CT:
  if(iWeapID != CSW_KNIFE)
  {
  SetHamReturnInteger( 1 );
  return HAM_SUPERCEDE;
  }
  }
      
  return HAM_IGNORED;
  }
  
  return HAM_IGNORED;
}

public fog(bool:FogOn) {
  if(FogOn) {
    message_begin(MSG_ALL,g_iMsgFog,{0,0,0},0);
    write_byte(180);  // red
    write_byte(1);    // green
    write_byte(1);    // blue
    write_byte(10);   // Start distance 10
    write_byte(41);   // Start distance 41
    write_byte(95);   // End distance 95
    write_byte(59);   // End distance 59
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

stock msg_create_fog( iRed, iGreen, iBlue, iDensity )
{
  // Fog density offsets [Thnx to DA]
  new const fog_density[ ] = { 0, 0, 0, 0, 111, 18, 3, 58, 111, 18, 125, 58, 66, 96, 27, 59, 90, 101, 60, 59, 90,
  101, 68, 59, 10, 41, 95, 59, 111, 18, 125, 59, 111, 18, 3, 60, 68, 116, 19, 60 };
  
  // Get the amount of density
  new dens;
  dens = ( 4 * iDensity );
  
  // The fog message
  message_begin( MSG_BROADCAST, get_user_msgid( "Fog" ), { 0,0,0 }, 0 );
  write_byte( iRed ); // Red
  write_byte( iGreen ); // Green
  write_byte( iBlue ); // Blue
  write_byte( fog_density[ dens ] ); // SD
  write_byte( fog_density[ dens + 1 ] ); // ED
  write_byte( fog_density[ dens + 2 ] ); // D1
  write_byte( fog_density[ dens + 3 ] ); // D2
  message_end( );
}

GiveItem(const playerID, const szItem[], const bpAmmo) {
  give_item(playerID, szItem);
  cs_set_user_bpammo(playerID, get_weaponid(szItem), bpAmmo);
}

public Fwd_PlayerDamage(const victim, const inflictor, const attacker, Float:damage, const iDamageType)
{
  //set_user_team = cs_get_user_team(victim);
  if(is_user_alive(victim) && iDamageType == DMG_FALL)
  {

  if (g_dayEnabled) 
  {
    if(cs_get_user_team(victim) == CS_TEAM_CT)
    {
      SetHamReturnInteger(0);
      return HAM_SUPERCEDE;
    }
  }
  }
  
  if(!is_user_alive(victim) || victim == attacker)
    return HAM_IGNORED;

    
  if(cs_get_user_team(victim) == CS_TEAM_CT)
  {
    if(!task_exists(victim))
    {
      set_bit(g_HasBeenHit, victim);
      set_task(1.5, "resetmodel", victim);
    }
  }
    
  return HAM_IGNORED;     

}
  

public resetmodel(playerID)
{
  clear_bit(g_HasBeenHit, playerID);
  remove_task(playerID);
}


public Fwd_PlayerKilled_Pre(victim, attacker, shouldgib)
{
  if (!is_user_alive(victim))
    return HAM_IGNORED;
    
  if (g_dayEnabled) 
  {
  cs_reset_user_model(victim);
  emit_sound(victim, CHAN_VOICE, NightCrawlerSounds[0], 0.0, ATTN_NORM, SND_STOP, PITCH_NORM);
  if(g_iRandom == victim)
  g_iRandom = fnGetRandomPlayer();
  }
    
  return HAM_IGNORED;
}

new const oldknife_sounds[][] =
{
  "weapons/knife_deploy1.wav",   
  "weapons/knife_hit1.wav",   
  "weapons/knife_hit2.wav",    
  "weapons/knife_hit3.wav",    
  "weapons/knife_hit4.wav",    
  "weapons/knife_hitwall1.wav",  
  "weapons/knife_slash1.wav",    
  "weapons/knife_slash2.wav",    
  "weapons/knife_stab.wav"    
};

new const newknife_sounds[][] =
{
  "weapons/knife_deploy1.wav",   
  "sword_strike1.wav",   
  "sword_strike2.wav",    
  "sword_strike3.wav",    
  "sword_strike4.wav",    
  "weapons/knife_hitwall1.wav",  
  "weapons/knife_slash1.wav",    
  "weapons/knife_slash2.wav",    
  "weapons/knife_stab.wav"    
};

public sound_emit(const playerID, const channel, const sample[])
{
  if(!is_user_connected(playerID) && is_user_alive(playerID))
  {
  static CsTeams:team;
  team = cs_get_user_team(playerID);

  if (g_dayEnabled) 
  {
  if(team == CS_TEAM_CT)
  {
  for(new i = 2; i < sizeof newknife_sounds; i++)
  {
  if(equal(sample, oldknife_sounds[i]))
  {
  emit_sound(playerID, channel, newknife_sounds[i], 1.0, ATTN_NORM, 0, PITCH_NORM);
  return FMRES_SUPERCEDE;
  }
  }
  }
  }
  }
  
  return FMRES_IGNORED;
}

public Fwd_ItemDeploy2_Post(const weapon)
{
  // Get the owner of the weapon
  new playerID = get_pdata_cbase(weapon, m_pPlayer, OFFSET_LINUX);
  if(is_user_connected(playerID))
  {
  static CsTeams:team;
  team = cs_get_user_team(playerID);
   
  if (g_dayEnabled) 
  {
  if(team == CS_TEAM_CT)
  set_pev(playerID, pev_viewmodel2, NightCrawlerModels[0]);
  }
  }
}


public Fwd_AddToFullPack(es_handle, e, ent, host, hostflags, playerID, pSet)
{
  
  if( playerID && is_user_alive(playerID))
  {

      if (g_dayEnabled) 
      { 
        static CsTeams:team; team = cs_get_user_team(ent);
        static CsTeams:teamhost; teamhost = cs_get_user_team(host);
        
        if(team == CS_TEAM_CT && team != teamhost)
        {
          if(get_bit(g_HasBeenHit, ent))
          {
            set_es(es_handle, ES_RenderFx, kRenderFxDistort);
            set_es(es_handle, ES_RenderColor, {0, 0, 0});
            set_es(es_handle, ES_RenderMode, kRenderTransAdd);
            set_es(es_handle, ES_RenderAmt, 127);
          }
          else {
            set_es(es_handle, ES_RenderMode, kRenderTransAlpha);
            set_es(es_handle, ES_RenderAmt, 0);
          }
        }
        if(team == CS_TEAM_CT && team == teamhost)
        {
          set_es(es_handle, ES_RenderFx, kRenderFxDistort);
          set_es(es_handle, ES_RenderColor, {0, 0, 0});
          set_es(es_handle, ES_RenderMode, kRenderTransAdd);
          set_es(es_handle, ES_RenderAmt, 127);
        }
      }
      
  }
  
  return FMRES_IGNORED;
}

#define STR_T 32
new Float:g_wallorigin[32][3];

public Fwd_Touch(playerID, world)
{
  if(!is_user_connected(playerID) && !is_user_alive(playerID))
    return FMRES_IGNORED;
    
  static classname[STR_T];
  pev(world, pev_classname, classname, (STR_T-1));
  
  static CsTeams:team;
  team = cs_get_user_team(playerID);
  if (g_dayEnabled) 
  {
      if(team == CS_TEAM_CT)
        if(equal(classname, "worldspawn") || equal(classname, "func_wall") || equal(classname, "func_breakable"))
          pev(playerID, pev_origin, g_wallorigin[playerID]);

  }
  return FMRES_IGNORED;
}

public wallclimb(playerID, button) 
{ 
  static Float:origin[3]; 
  pev(playerID, pev_origin, origin);
  
  if(button & IN_RELOAD && !get_bit(g_bTeleport, playerID) && g_bTeleportUsed[playerID] < 3) 
  { 
    g_bTeleportUsed[playerID]++;
    uj_colorchat_print(playerID, playerID, "You have been teleported! You have^4 %d teleports^1 left.", (3-g_bTeleportUsed[playerID]));
    //fnColorPrint(playerID, "You have been teleported! You have^4 %d teleports^1 left.", (3-g_bTeleportUsed[id]));
    emit_sound(playerID, CHAN_AUTO, NightCrawlerSounds[1], 1.0, ATTN_NORM, 0, PITCH_NORM);
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
  } 
  
  if(get_distance_f(origin, g_wallorigin[playerID]) > 10.0) 
    return FMRES_IGNORED;
  
  if(get_entity_flags(playerID) & FL_ONGROUND) 
    return FMRES_IGNORED; 

  if(button & IN_FORWARD) 
  { 
    static Float:velocity[3]; 
    velocity_by_aim(playerID, 275, velocity); 
    set_user_velocity(playerID, velocity); 
  } 
  else if(button & IN_BACK) 
  { 
    static Float:velocity[3]; 
    velocity_by_aim(playerID, -120, velocity); 
    set_user_velocity(playerID, velocity); 
  } 
  return FMRES_IGNORED; 
}    

public resetteleport(playerID)
{
  clear_bit(g_bTeleport, playerID);
}

public Fwd_PlayerPreThink(playerID)  
{ 
  if(is_user_alive( playerID ))
  {
  static CsTeams:team;
  team = cs_get_user_team(playerID);
  if (g_dayEnabled) 
  {
  switch(team)
  {
  case CS_TEAM_CT:
  {
  new button = get_user_button(playerID); 
               
  if(button & IN_USE || button & IN_RELOAD ) //Use button = climb 
  wallclimb(playerID, button);  
  }
  case CS_TEAM_T: set_laser(playerID);
  }
  }
  }
}

public set_laser(playerID)
{
  if(g_iRandom == playerID && g_iRandom != 0)
  {
    static iTarget, iBody, iRed, iGreen, iBlue, iWeapon;
    get_user_aiming(playerID, iTarget, iBody);
    iWeapon = get_user_weapon(playerID);
    if(IsPrimaryWeapon(iWeapon) || IsSecondaryWeapon(iWeapon))
    {
      if( is_user_alive(iTarget) && cs_get_user_team(iTarget) != cs_get_user_team(playerID))
      {
        iRed = 255;
        iGreen = 0;
        iBlue = 0;
      }
      else {
        iRed = 0;
        iGreen = 0;
        iBlue = 255;
      }
      
      static iOrigin[ 3 ];
      get_user_origin(playerID, iOrigin, 3);
      
      message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
      write_byte(TE_BEAMENTPOINT);
      write_short(playerID | 0x1000);
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
  }
}


stock bool:is_user_stuck(playerID) { 
  new Float:g_origin[3]; 
  pev(playerID, pev_origin, g_origin); 
  if ( trace_hull(g_origin, HULL_HUMAN,playerID) != 0 ) 
  { 
    return true; 
  } 
  return false; 
}

public ClientCommand_UnStuck(const playerID)
{
  new i_Value;

  if ((i_Value = UTIL_UnstuckPlayer(playerID, START_DISTANCE, MAX_ATTEMPTS)) != 1)
    switch (i_Value)
    {
      case 0: uj_colorchat_print(playerID, playerID, "Could not find a free spot to move you to.");

      case -1: uj_colorchat_print(playerID, playerID, "You cannot free yourself as dead player");
    }

  return PLUGIN_CONTINUE;
}

UTIL_UnstuckPlayer(const playerID, const i_StartDistance, const i_MaxAttempts)
{
  // Is Not alive, ignore.
  if(is_user_alive( playerID ))  return -1;
  
  static Float:vf_OriginalOrigin[Coord_e], Float:vf_NewOrigin[Coord_e];
  static i_Attempts, i_Distance;
  
  // Get the current player's origin.
  pev (playerID, pev_origin, vf_OriginalOrigin);
  
  i_Distance = i_StartDistance;

  while (i_Distance < 1000)
  {
    i_Attempts = i_MaxAttempts;
  
    while (i_Attempts--)
    {
      vf_NewOrigin[x] = random_float(vf_OriginalOrigin[ x ] - i_Distance, vf_OriginalOrigin[ x ] + i_Distance);
      vf_NewOrigin[y] = random_float(vf_OriginalOrigin[ y ] - i_Distance, vf_OriginalOrigin[ y ] + i_Distance);
      vf_NewOrigin[z] = random_float(vf_OriginalOrigin[ z ] - i_Distance, vf_OriginalOrigin[ z ] + i_Distance);
    
      engfunc (EngFunc_TraceHull, vf_NewOrigin, vf_NewOrigin, DONT_IGNORE_MONSTERS, GetPlayerHullSize (playerID), playerID, 0);
    
      // Free space found.
      if (get_tr2 (0, TR_InOpen) && !get_tr2 (0, TR_AllSolid) && !get_tr2 (0, TR_StartSolid))
      {
        // Set the new origin .
        engfunc (EngFunc_SetOrigin, playerID, vf_NewOrigin);
        return 1;
      }
    }
  
    i_Distance += i_StartDistance;
  }

  // Could not be found.
  return 0;
} 
