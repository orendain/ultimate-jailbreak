#include <amxmisc>
#include <amxmodx>
#include <fakemeta>
#include <fun>
#include <cstrike>
#include <hamsandwich>
#include <engine>
#include <dhudmessage>
#include <uj_menus>
#include <uj_chargers>
#include <uj_core>
#include <uj_days>
#include <uj_effects>
#include <uj_points>
#include <uj_colorchat>


#define FIRST_PLAYER_ID 1
#define IsPlayer(%1) (FIRST_PLAYER_ID <= %1 <= g_iMaxPlayers)

const HAS_SHIELD = 1<<24;
#define HasShield(%0)    ( get_pdata_int(%0, m_iUserPrefs, XO_PLAYER) & HAS_SHIELD )

#define m_iTeam    114
#define XO_PLAYER  5
#define m_iFlashBattery  244
#define m_pActiveItem    373
#define m_iUserPrefs     510

#define TEAM_T  1
#define TEAM_CT 2

#define cs_get_user_team_index(%0)  get_pdata_int(%0, m_iTeam, XO_PLAYER)
#define cs_set_user_team_index(%0,%1) set_pdata_int(%0, m_iTeam, %1, XO_PLAYER)

new const PLUGIN_NAME[] = "[UJ] Day - Gun Game";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

new const DAY_NAME[] = "Gun Game";
new const DAY_OBJECTIVE[] = "Level up and level fast!";
new const DAY_SOUND[] = "";

new g_iMaxPlayers;
new g_bSetFakeGodmode;    // For gun game respawn 3 secs with godmode xd
new g_iVictimTeam;
new HamHook:g_iHhTakeDamagePost;
new g_bIsAlive;     // Are we alive?
new g_bIsConnected;   // Are we connected?
new g_iGetUserWeapon;

new const g_szSound_Bell[] = "buttons/bell1.wav";

//new const GHOSTBUSTERS_AMMO[] = "400";
//new const GHOSTBUSTERS_HEALTH[] = "400";
new const GunGameSounds[][] = { "powerdown.wav", "powerup.wav", "knife_level.wav",    
  "levelup.wav"
};

new const g_iWeaponLevel[] =
{
  CSW_GLOCK18,
  CSW_USP,
  CSW_DEAGLE,
  CSW_FIVESEVEN,
  CSW_ELITE,
  CSW_UMP45,
  CSW_MAC10,
  CSW_TMP,
  CSW_MP5NAVY,
  CSW_XM1014,
  CSW_M3,
  CSW_FAMAS,
  CSW_M4A1,
  CSW_AK47,
  CSW_SCOUT,
  CSW_AWP,
  CSW_KNIFE
};

new const g_szWeaponModels[][] =
{
  "models/w_glock18.mdl",
  "models/w_usp.mdl",
  "models/w_deagle.mdl",
  "models/w_fiveseven.mdl",
  "models/w_elite.mdl",
  "models/w_ump45.mdl",
  "models/w_mac10.mdl",
  "models/w_tmp.mdl",
  "models/w_mp5navy.mdl",
  "models/w_xm1014.mdl",
  "models/w_sg550.mdl",
  "models/w_famas.mdl",
  "models/w_m4a1.mdl",
  "models/w_ak47.mdl",
  "models/w_scout.mdl",
  "models/w_awp.mdl",
  "models/w_knife.mdl"
};

new const g_szGunGameNames[][] =
{
  "Glock18",
  "USP",
  "Deagle",
  "Five-Seven",
  "Elite",
  "UMP45",
  "Mac10",
  "TMP",
  "MP5 Navy",
  "Auto Shotgun",
  "Pump Shotgun",
  "Famas",
  "M4A1",
  "AK47",
  "Scout",
  "AWP",
  "Knife"
};

static const g_szWeaponNames[CSW_P90+1][] = {
  "","weapon_p228","","weapon_scout",
  "weapon_hegrenade","weapon_xm1014",
  "","weapon_mac10","weapon_aug",
  "weapon_smokegrenade","weapon_elite",
  "weapon_fiveseven","weapon_ump45",
  "weapon_sg550","weapon_galil",
  "weapon_famas","weapon_usp",
  "weapon_glock18","weapon_awp",
  "weapon_mp5navy","weapon_m249",
  "weapon_m3","weapon_m4a1","weapon_tmp",
  "weapon_g3sg1","weapon_flashbang","weapon_deagle",
  "weapon_sg552","weapon_ak47","","weapon_p90"
};


new static bpAmmo_default[CSW_P90+1] = {
  0,
  52,
  0,
  90,
  1,
  32,
  1,
  100,
  90,
  1,
  120,
  100,
  100,
  90,
  90,
  90,
  100,
  120,
  30,
  120,
  200,
  32,
  90,
  120,
  90,
  2,
  35,
  90,
  90,
  0,
  100
};

new const g_iWeaponLevelRefillammo[] =
{
  20,
  12,
  7,
  20,
  30,
  25,
  30,
  30,
  30,
  7,
  8,
  25,
  30,
  30,
  10,
  10,
  0
};

new level;
new g_iGunGameLevel[33][17];
new g_iGunGameLevelNext[33];

new const GHOSTBUSTERS_HEALTH[] = "100";

// Day variables
new g_day;
new bool:g_dayEnabled;

// Menu variables
new g_menuSpecial

// Cvars
new g_healthPCVar;

public plugin_precache()
{
  // Register day
  g_day = uj_days_register(DAY_NAME, DAY_OBJECTIVE, DAY_SOUND)
  static i;
  for(i = 0; i < sizeof(GunGameSounds); i++)
  precache_sound(GunGameSounds[i]);
  precache_sound(g_szSound_Bell);
}

public plugin_init()
{
  register_plugin(PLUGIN_NAME, PLUGIN_VERS, PLUGIN_AUTH);

  // Find all valid menus to display this under
  g_menuSpecial = uj_menus_get_menu_id("Special Days");
  g_healthPCVar = register_cvar("uj_day_ghostbusters_health", GHOSTBUSTERS_HEALTH);

  // CVars
  RegisterHam(Ham_TraceAttack, "func_door", "Fwd_DoorAttack");
  RegisterHam(Ham_Touch, "weaponbox", "Fwd_PlayerWeaponTouch"); 
  RegisterHam(Ham_Touch, "armoury_entity", "Fwd_PlayerWeaponTouch");
  RegisterHam(Ham_AddPlayerItem, "player", "Player_AddPlayerItem", 0);
  RegisterHam(Ham_Spawn, "player", "Fwd_PlayerSpawn_Post", 1);
  RegisterHam(Ham_TakeDamage, "player", "Fwd_PlayerDamage", 0);
  RegisterHam(Ham_Killed, "player", "Fwd_PlayerKilled_Pre", 0);
  register_logevent( "EventJoinTeam", 3, "1=joined team" ); //gungame respawn on connect
  g_iHhTakeDamagePost = RegisterHam(Ham_TakeDamage, "player", "Player_TakeDamage_Post", 1);
  DisableHamForward(g_iHhTakeDamagePost);
  
  g_iMaxPlayers   = get_maxplayers();
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

    new players[32], playerID;
    new playerCount = uj_core_get_players(players, true, CS_TEAM_T);
    for (new i = 0; i < playerCount; ++i) {
      playerID = players[i];
      
      // Give user items
      uj_core_strip_weapons(playerID);
      clear_bit(g_bSetFakeGodmode, playerID);
      g_iGunGameLevel[playerID][level] = 0;
      g_iGunGameLevelNext[playerID] = 0;
      //StripPlayerWeapons(playerID);
      cs_set_user_armor(playerID, 100, CS_ARMOR_VESTHELM);
      GiveItem2(playerID, g_iWeaponLevel[g_iGunGameLevel[playerID][level]]);
      //set_user_health(playerID, health);
    }

    new health = get_pcvar_num(g_healthPCVar);

    playerCount = uj_core_get_players(players, true, CS_TEAM_CT);
    for (new i = 0; i < playerCount; ++i) {
      playerID = players[i];
      
      // Set user up with noclip
      uj_core_strip_weapons(playerID);
      clear_bit(g_bSetFakeGodmode, playerID);
      g_iGunGameLevel[playerID][level] = 0;
      g_iGunGameLevelNext[playerID] = 0;
      //StripPlayerWeapons(playerID);
      cs_set_user_armor(playerID, 100, CS_ARMOR_VESTHELM);
      GiveItem2(playerID, g_iWeaponLevel[g_iGunGameLevel[playerID][level]]);
      set_user_health(playerID, health);
    }

    uj_core_block_weapon_pickup(0, true);
    uj_chargers_block_heal(0, true);
    uj_chargers_block_armor(0, true);
    //uj_core_set_friendly_fire(true);
  }
}

end_day()
{
  new players[32], playerID;
  new playerCount = uj_core_get_players(players, true, CS_TEAM_T);
  for (new i = 0; i < playerCount; ++i) {
    playerID = players[i];
    uj_core_strip_weapons(playerID);
  }

  playerCount = uj_core_get_players(players, true, CS_TEAM_CT);
  for (new i = 0; i < playerCount; ++i) {
    playerID = players[i];
    set_user_noclip(playerID, 0);
    set_user_godmode(playerID, 0);
  }

  uj_core_block_weapon_pickup(0, false);
  uj_chargers_block_heal(0, false);
  uj_chargers_block_armor(0, false);
  g_dayEnabled = false;
}


public Fwd_DoorAttack(const door, const playerID, Float:damage, Float:direction[3], const tracehandle, const damagebits)
{ 
  if(is_valid_ent(door))
  {
    if (g_dayEnabled)
    {
      ExecuteHamB(Ham_Use, door, playerID, 0, 1, 1.0);
      entity_set_float(door, EV_FL_frame, 0.0);
    }
  }
  return HAM_IGNORED;
}

public Fwd_PlayerWeaponTouch(const iEntity, const playerID)
{
  if(!IsPlayer(playerID))
    return HAM_IGNORED;

  new Model[32];
  pev(iEntity, pev_model, Model, 31);  
        
  if (g_dayEnabled)
    if (!equal(Model, g_szWeaponModels[ g_iGunGameLevel[playerID][level] ]))
      return HAM_SUPERCEDE;
  
  
  return HAM_IGNORED;
}

public Player_AddPlayerItem(const playerID, const iEntity)  //anti gun glitch
{
  new iWeapID = cs_get_weapon_id( iEntity );

  if( !iWeapID )
    return HAM_IGNORED;
    
  if (g_dayEnabled)
    if (iWeapID != CSW_KNIFE && iWeapID != g_iWeaponLevel[g_iGunGameLevel[playerID][level]])
    {
      SetHamReturnInteger( 1 );
      GiveItem2(playerID, g_iWeaponLevel[g_iGunGameLevel[playerID][level]]);
      return HAM_SUPERCEDE;
    }

  
  return HAM_IGNORED;
}

stock GiveItem2(const playerID, const szItem, iAmmo = -1, bpAmmo = -1) {
  give_item(playerID, g_szWeaponNames[szItem]);
  
  if(iAmmo >= 0) {
    new wepID = find_ent_by_owner(-1, g_szWeaponNames[szItem], playerID);
    if(wepID)
    {
      cs_set_weapon_ammo(wepID, iAmmo);
    }
  }
  
  if(bpAmmo >= 0) 
    cs_set_user_bpammo(playerID, szItem, bpAmmo);
  else cs_set_user_bpammo(playerID, szItem, bpAmmo_default[szItem]);

}

public Fwd_PlayerSpawn_Post(const playerID)
{
		
	if (!is_user_alive(playerID))
	    return HAM_HANDLED;
    
	set_bit(g_bIsAlive, playerID);
  
	//UTIL_ScreenFade(id, 2.0, 4.0);
    
	if(g_dayEnabled)
	{
	cs_set_user_armor(playerID, 100, CS_ARMOR_VESTHELM);
	GiveItem2(playerID, g_iWeaponLevel[g_iGunGameLevel[playerID][level]]);
    
	}
  
	return HAM_HANDLED;
}

public client_putinserver(playerID) {
	
	clear_bit(g_bIsAlive, playerID);
	if(bool:!is_user_hltv(playerID))
		set_bit(g_bIsConnected, playerID);	
	
}

public client_disconnect(playerID)
{

	clear_bit(g_bIsAlive, playerID);

}


public Fwd_PlayerDamage(const victim, const inflictor, const attacker, Float:damage, const iDamageType)
{

	if(!IsPlayer( attacker ) || victim == attacker)
		return HAM_IGNORED;
		

	if(g_dayEnabled)
	{	
		if(get_bit(g_bSetFakeGodmode, victim))
		{
			SetHamReturnInteger(0);
			return HAM_SUPERCEDE;
		}
		g_iVictimTeam = cs_get_user_team_index(victim);
		if( g_iVictimTeam == cs_get_user_team_index(attacker) )
		{
			cs_set_user_team_index(victim, g_iVictimTeam == TEAM_T ? TEAM_CT : TEAM_T);
			EnableHamForward(g_iHhTakeDamagePost);
			return HAM_HANDLED;
		}
		
		if( cs_get_user_team(attacker) == CS_TEAM_CT && cs_get_user_team(victim) == CS_TEAM_T)
		{
		return HAM_SUPERCEDE;
		}
		
		if( cs_get_user_team(attacker) == CS_TEAM_T && cs_get_user_team(victim) == CS_TEAM_CT)
		{
		return HAM_SUPERCEDE;
		}		
		
	}

	return HAM_IGNORED;
}

public Player_TakeDamage_Post(victim)
{
	/*if( g_iDay[ TOTAL_DAYS ] == DAY_DEATHMATCH 
	|| g_iDay[ TOTAL_DAYS ] == DAY_GANG 
	|| g_iDay[ TOTAL_DAYS ] == DAY_GRENADE 
	|| g_bBoxMatch 
	|| g_bSnowballWar 
	|| g_bGunGame)
	{
		cs_set_user_team_index(victim, g_iVictimTeam);
		DisableHamForward( g_iHhTakeDamagePost );
		
		cs_set_user_team(victim, set_user_team);
		//new sName[32]; get_user_name(victim, sName, charsmax(sName));	
		//fnColorPrint(0, "%s Your team is %d", sName,g_iVictimTeam);
	}*/
	cs_set_user_team_index(victim, g_iVictimTeam);
	DisableHamForward( g_iHhTakeDamagePost );
	
	//cs_set_user_team(victim, set_user_team);
}



public gungamerespawn(playerID)
{
  if(g_dayEnabled && get_bit(g_bIsConnected, playerID))
  {
    ExecuteHamB(Ham_CS_RoundRespawn, playerID);
    set_bit(g_bSetFakeGodmode, playerID);
    set_task(3.0, "removefakegodmode", playerID);
    //UTIL_ScreenFade(playerID, 1.0, 1.0);
  }
}

public removefakegodmode(playerID)
{
  if(g_dayEnabled && get_bit(g_bIsConnected, playerID))
  {
    clear_bit(g_bSetFakeGodmode, playerID);
  }
}

public Fwd_PlayerKilled_Pre(victim, attacker, shouldgib)
{
  if (!IsPlayer(victim))
    return HAM_IGNORED;
    
  if(g_dayEnabled)
  {
    new aName[32]; get_user_name(attacker, aName, charsmax(aName));
    new sName[32]; get_user_name(victim, sName, charsmax(sName)); 
    if(get_bit(g_bIsAlive, attacker))
    {
      if(get_user_weapon(attacker) != CSW_KNIFE)
      {
        emit_sound(attacker, CHAN_AUTO, GunGameSounds[3], 1.0, ATTN_NORM, 0, PITCH_NORM);
        g_iGunGameLevelNext[attacker]++;
        uj_points_add(attacker, 1)
        set_user_health(attacker, 100);
  
        if(g_iGunGameLevelNext[attacker] == 3)
        {
          g_iGunGameLevelNext[attacker] = 0;
          g_iGunGameLevel[attacker][level]++;
          StripPlayerWeapons(attacker);
          if(g_iGunGameLevel[attacker][level] <= 15)
            GiveItem2(attacker, g_iWeaponLevel[g_iGunGameLevel[attacker][level]]);
          
          if(g_iGunGameLevel[attacker][level] <= 16)
	  uj_colorchat_print(0, 0, "Gun-Game^3 %s^1 is on level^3 %s", aName, g_szGunGameNames[g_iGunGameLevel[attacker][level]]);
            //fnColorPrint(0, "Gun-Game^3 %s^1 is on level^3 %s", aName, g_szGunGameNames[g_iGunGameLevel[attacker][level]]);
          if(g_iGunGameLevel[attacker][level] == 16)  
            emit_sound(0, CHAN_AUTO, GunGameSounds[2], 1.0, ATTN_NORM, 0, PITCH_NORM);
        }
        if(g_iGunGameLevelNext[attacker] < 3)
        {
          uj_colorchat_print(attacker, attacker, "Gun-Game You need^3 %d^1 kills to advance.^3 %d / 3", 3-g_iGunGameLevelNext[attacker], g_iGunGameLevelNext[attacker]);
	 //fnColorPrint(attacker, "Gun-Game You need^3 %d^1 kills to advance.^3 %d / 3", 3-g_iGunGameLevelNext[attacker], g_iGunGameLevelNext[attacker]);
          new wepID = find_ent_by_owner(-1, g_szWeaponNames[g_iWeaponLevel[g_iGunGameLevel[attacker][level]]], attacker);
          if(wepID)
            cs_set_weapon_ammo(wepID, g_iWeaponLevelRefillammo[g_iGunGameLevel[attacker][level]]);  
        }
      }
      if(g_iGunGameLevel[attacker][level] < 16 && get_user_weapon(attacker) == CSW_KNIFE)
      {
        emit_sound(attacker, CHAN_AUTO, GunGameSounds[3], 1.0, ATTN_NORM, 0, PITCH_NORM);
        g_iGunGameLevelNext[attacker]++;
  
        if(g_iGunGameLevelNext[attacker] == 3)
        {
          g_iGunGameLevelNext[attacker] = 0;
          g_iGunGameLevel[attacker][level]++;
          StripPlayerWeapons(attacker);
          if(g_iGunGameLevel[attacker][level] <= 15)
            GiveItem2(attacker, g_iWeaponLevel[g_iGunGameLevel[attacker][level]]);
          
          if(g_iGunGameLevel[attacker][level] <= 16)
	  uj_colorchat_print(0, 0, "Gun-Game^3 %s^1 is on level^3 %s", aName, g_szGunGameNames[g_iGunGameLevel[attacker][level]]);
            //fnColorPrint(0, "Gun-Game^3 %s^1 is on level^3 %s", aName, g_szGunGameNames[g_iGunGameLevel[attacker][level]]);
          if(g_iGunGameLevel[attacker][level] == 16)  
            emit_sound(0, CHAN_AUTO, GunGameSounds[2], 1.0, ATTN_NORM, 0, PITCH_NORM);
        }
        if(g_iGunGameLevelNext[attacker] < 3)
        {
	  uj_colorchat_print(attacker, attacker, "Gun-Game You need^3 %d^1 kills to advance.^3 %d / 3", 3-g_iGunGameLevelNext[attacker], g_iGunGameLevelNext[attacker]);
          //fnColorPrint(attacker, "Gun-Game You need^3 %d^1 kills to advance.^3 %d / 3", 3-g_iGunGameLevelNext[attacker], g_iGunGameLevelNext[attacker]);
          new wepID = find_ent_by_owner(-1, g_szWeaponNames[g_iWeaponLevel[g_iGunGameLevel[attacker][level]]], attacker);
          if(wepID)
            cs_set_weapon_ammo(wepID, g_iWeaponLevelRefillammo[g_iGunGameLevel[attacker][level]]);  
        }
      }
      if(g_iGunGameLevel[victim][level] > 0 && g_iGunGameLevel[attacker][level] < 16 && get_user_weapon(attacker) == CSW_KNIFE)
      {
        g_iGunGameLevel[victim][level]--;
        g_iGunGameLevel[attacker][level]++;
        g_iGunGameLevelNext[attacker] = 0;
        StripPlayerWeapons(attacker);
        GiveItem2(attacker, g_iWeaponLevel[g_iGunGameLevel[victim][level]]);
        GiveItem2(attacker, g_iWeaponLevel[g_iGunGameLevel[attacker][level]]);
        emit_sound(victim, CHAN_AUTO, GunGameSounds[0], 1.0, ATTN_NORM, 0, PITCH_NORM);
        emit_sound(attacker, CHAN_AUTO, GunGameSounds[1], 1.0, ATTN_NORM, 0, PITCH_NORM);
        set_user_health(attacker, 110);
        uj_colorchat_print(0, 0, "Gun-Game^4 %s^1 has stolen a^3 level^1 from^4 %s", aName, sName);	
        //fnColorPrint(0, "Gun-Game^4 %s^1 has stolen a^3 level^1 from^4 %s", aName, sName);
      }
      if(g_iGunGameLevel[attacker][level] == 16 && get_user_weapon(attacker) == CSW_KNIFE && cs_get_user_team(attacker) == CS_TEAM_T)
      {
        uj_colorchat_print(0, 0, "Gun-Game^3 %s^1 has won the game!", aName);
        static iPlayers[32], iNum, i, iPlayer;
        get_players( iPlayers, iNum, "ae", "TERRORIST"  ); 
        for( i=0; i<iNum; i++ )
        {
          iPlayer = iPlayers[i];
          if(attacker == iPlayer)
            continue;
          if(g_iGunGameLevel[attacker][level] >= g_iGunGameLevel[iPlayer][level])
          {
            user_silentkill(iPlayer);
          }
          
          if(g_iGunGameLevel[attacker][level] >= g_iGunGameLevel[iPlayer][level])
          {
            //g_iPoints[ attacker ] += ( 25 );
	    uj_points_add(attacker, 25)
            uj_colorchat_print( attacker, attacker, "You have been awarded^x03 25^x01 Points for winning gungame!");
            set_hudmessage(0, 255, 0, -1.0, 0.20, 1, 0.0, 5.0, 1.0, 1.0, -1);
            show_hudmessage(0, "%s has won the gungame!", aName);
          }
          
          
          
        }
        emit_sound(0, CHAN_AUTO, g_szSound_Bell, 1.0, ATTN_NORM, 0, PITCH_NORM);
      }
      if(g_iGunGameLevel[attacker][level] == 16 && get_user_weapon(attacker) == CSW_KNIFE && cs_get_user_team(attacker) == CS_TEAM_CT)
      {
        uj_colorchat_print(attacker, attacker, "Gun-Game^3 You^1 have made it to the final^4 level!");
        emit_sound(0, CHAN_AUTO, g_szSound_Bell, 1.0, ATTN_NORM, 0, PITCH_NORM);
      }
    }
    StripPlayerWeapons(victim);
    set_task(3.0, "gungamerespawn", victim);
  }
    
  clear_bit(g_bIsAlive, victim);    
  return HAM_IGNORED;
}

stock StripPlayerWeapons(playerID)
{
    
	for(new i=CSW_P228; i<=CSW_P90; i++)
	{

	if(g_iGetUserWeapon == get_user_weapon(playerID))
		continue;
	ham_strip_user_weapon(playerID, i);
	}
	if(HasShield(playerID))
	{
	strip_user_weapons(playerID); 
    
	}
	give_item(playerID, "weapon_knife");
	//for(new i=CSW_P228; i<=CSW_P90; i++)
	//ham_strip_user_weapon(id, i);
}

stock ham_strip_user_weapon(playerID, iCswId, iSlot = 0, bool:bSwitchIfActive = true) 
{ 
  new iWeapon;
  if( !iSlot ) 
  { 
    static const iWeaponsSlots[] = { 
      -1, 
      2, //CSW_P228 
      -1, 
      1, //CSW_SCOUT 
      4, //CSW_HEGRENADE 
      1, //CSW_XM1014 
      5, //CSW_C4 
      1, //CSW_MAC10 
      1, //CSW_AUG 
      4, //CSW_SMOKEGRENADE 
      2, //CSW_ELITE 
      2, //CSW_FIVESEVEN 
      1, //CSW_UMP45 
      1, //CSW_SG550 
      1, //CSW_GALIL 
      1, //CSW_FAMAS 
      2, //CSW_USP 
      2, //CSW_GLOCK18 
      1, //CSW_AWP 
      1, //CSW_MP5NAVY 
      1, //CSW_M249 
      1, //CSW_M3 
      1, //CSW_M4A1 
      1, //CSW_TMP 
      1, //CSW_G3SG1 
      4, //CSW_FLASHBANG 
      2, //CSW_DEAGLE 
      1, //CSW_SG552 
      1, //CSW_AK47 
      3, //CSW_KNIFE 
      1 //CSW_P90 
    };
    iSlot = iWeaponsSlots[iCswId];
  } 
  
  const m_rgpPlayerItems_Slot0 = 367;
  
  iWeapon = get_pdata_cbase(playerID, m_rgpPlayerItems_Slot0 + iSlot, XO_PLAYER); 
  
  const XTRA_OFS_WEAPON = 4; 
  const m_pNext = 42; 
  const m_iId = 43; 
  
  while( iWeapon > 0 ) 
  { 
    if( get_pdata_int(iWeapon, m_iId, XTRA_OFS_WEAPON) == iCswId ) 
    { 
      break; 
    } 
    iWeapon = get_pdata_cbase(iWeapon, m_pNext, XTRA_OFS_WEAPON); 
  } 
  
  if( iWeapon > 0 ) 
  { 
    if( bSwitchIfActive && get_pdata_cbase(playerID, m_pActiveItem, XO_PLAYER) == iWeapon ) 
    { 
      ExecuteHamB(Ham_Weapon_RetireWeapon, iWeapon); 
    } 
  
    if( ExecuteHamB(Ham_RemovePlayerItem, playerID, iWeapon) ) 
    { 
      user_has_weapon(playerID, iCswId, 0); 
      ExecuteHamB(Ham_Item_Kill, iWeapon); 
      return 1; 
    } 
  } 
  
  return 0;
}

public EventJoinTeam()
{
	new iPlayer = GetLoguserIndex();
	
	if(g_dayEnabled)
	{
		set_task(3.0, "gungamerespawn", iPlayer);
	}
}

GetLoguserIndex()
{
    new szArg[61];
    read_logargv(0,szArg, charsmax(szArg));
    
    new szName[32];
    parse_loguser(szArg, szName, charsmax(szName));
    
    return get_user_index(szName);
}