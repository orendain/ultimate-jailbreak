#include <amxmodx>
#include <cstrike>
#include <fun>
#include <fakemeta>
#include <engine>
#include <hamsandwich>
#include <csx>
#include <uj_menus>
#include <uj_chargers>
#include <uj_core>
#include <uj_days>
#include <uj_effects>

#define Task_Dodgeball	481541
#define PlayWavSound(%1,%2)		client_cmd(%1, "spk ^"%s^"", %2)

new const PLUGIN_NAME[] = "[UJ] Day - Dodgeball";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

new const DAY_NAME[] = "Dodgeball";
new const DAY_OBJECTIVE[] = "If you can dodge a wrench, you can dodge a ball";
new const DAY_SOUND[] = "";

new const g_szViewDodgeball[]		= "models/Allied_Gamers/v_dodgeballz.mdl";
new const g_szPlayerDodgeball[]		= "models/Allied_Gamers/p_dodgeballz.mdl";
new const g_szWorldDodgeball[] 		= "models/Allied_Gamers/w_dodgeballz.mdl";


new const g_szSoundBallBounce[]		= "weapons/g_bounce1.wav";
new const g_szSoundBallPickup[]		= "items/gunpickup2.wav";

// Day variables
new g_day;
new bool:g_dayEnabled;

// Menu variables
new g_menuSpecial

// booleans

new	 HamHook: HamTakeDamage

	, g_pCountdown
	
	, g_iCounter

	, g_iMsgTextMsg
;

public plugin_precache()
{
  // Register day
  g_day = uj_days_register(DAY_NAME, DAY_OBJECTIVE, DAY_SOUND)
  
  //precache_sound(g_szDaySound);
  precache_sound(g_szSoundBallBounce);
	
  precache_model(g_szViewDodgeball);
  precache_model(g_szPlayerDodgeball);
  precache_model(g_szWorldDodgeball);  
  
}

public plugin_init()
{
	register_plugin(PLUGIN_NAME, PLUGIN_VERS, PLUGIN_AUTH);

	// Find all valid menus to display this under
	g_menuSpecial = uj_menus_get_menu_id("Special Days");

	// CVars
  
	g_pCountdown = register_cvar("ddm_dodgeball_countdown", "10.0");
  
	//forwards
  
	register_forward(FM_SetModel, "FwdSetModel");
	register_forward(FM_EmitSound, "FwdEmitSound");
  
  	register_touch("player", "grenade", "FwdPlayerNadeTouch");
	
	RegisterHam(Ham_Spawn, "player", "FwdPlayerSpawnPost", 1);
	HamTakeDamage = RegisterHam(Ham_TakeDamage, "player", "FwdPlayerTakeDamagePre", 0);
	DisableHamForward(HamTakeDamage);
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_knife", "FwdKnifeAttackPre", 0);
	RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_knife", "FwdKnifeAttackPre", 0);
	
	register_message(get_user_msgid("SendAudio"), "MsgSendAudio");
	
	register_event("CurWeapon", "EventCurWeapon", "be", "1=1")
	
	g_iMsgTextMsg = get_user_msgid("TextMsg");
  
  
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
  	set_task(1.0, "TaskStartDodgeballDay", Task_Dodgeball, _, _, "a", (g_iCounter = get_pcvar_num(g_pCountdown)) + 1);
	EnableHamForward(HamTakeDamage);
  
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
      give_item(playerID, "weapon_hegrenade");
      cs_set_user_bpammo(playerID, CSW_HEGRENADE, 5);
    }

    playerCount = uj_core_get_players(players, true, CS_TEAM_CT);
    for (new i = 0; i < playerCount; ++i) {
      playerID = players[i];
      
      // Set user up with noclip
      uj_core_strip_weapons(playerID);
      give_item(playerID, "weapon_hegrenade");
      cs_set_user_bpammo(playerID, CSW_HEGRENADE, 5);
    }

    uj_core_block_weapon_pickup(0, true);
    uj_chargers_block_heal(0, true);
    uj_chargers_block_armor(0, true);
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
  }

  uj_core_block_weapon_pickup(0, false);
  uj_chargers_block_heal(0, false);
  uj_chargers_block_armor(0, false);
  DisableHamForward(HamTakeDamage);
  remove_task(Task_Dodgeball);
  g_dayEnabled = false;
}

public TaskStartDodgeballDay()
{
	if(g_iCounter-- > 1)
	{
		set_hudmessage(0, 255, 0, -1.0, 0.1, 0, 0.0, 1.0, 0.1, 0.1, 4);
		show_hudmessage(0, "%i seconds to receive balls!", g_iCounter);
	}

	else
	{
		new players[32], playerID;
		new playerCount = uj_core_get_players(players, true, CS_TEAM_T);
		for (new i = 0; i < playerCount; ++i)
		{
			playerID = players[i];
			{
				playerID = players[i];
			
				uj_core_strip_weapons(playerID);
				give_item(playerID, "weapon_hegrenade");
				cs_set_user_bpammo(playerID, CSW_HEGRENADE, 5);
			
			}
		}
	}
}

public FwdSetModel(iEntity, const szModel[])
{
	if(g_dayEnabled
	&& pev_valid(iEntity) 
	&& equal(szModel, "models/w_hegrenade.mdl"))
	{				
		//new iOwner = pev(iEntity, pev_owner);
		
		entity_set_model(iEntity, g_szWorldDodgeball);
		set_pev(iEntity, pev_dmgtime, 9999.0);
			
		return FMRES_SUPERCEDE;
	}
	
	return FMRES_IGNORED;
}

public FwdEmitSound(id, iChannel, const szSound[], Float: flVolume, Float: iAttn, iFlags, iPitch)
{
	if(g_dayEnabled)
	{
		if(is_user_alive(id)
		&& equal(szSound, "weapons/knife_deploy1.wav"))
			return FMRES_SUPERCEDE;
		
		else if(equal(szSound, "weapons/he_bounce-1.wav"))
		{
			emit_sound(id, CHAN_AUTO, g_szSoundBallBounce, flVolume * 2.5, iAttn, iFlags, PITCH_HIGH);
			return FMRES_SUPERCEDE;
			
		}
	}
		
	return FMRES_IGNORED;
}

public FwdPlayerNadeTouch(id, iNade)
{
	if(g_dayEnabled
	&& is_user_alive(id))
	{
		if(pev(iNade, pev_flags) & FL_ONGROUND)
		{	
			if(user_has_weapon(id, CSW_HEGRENADE))
			{
				PlayWavSound(id, g_szSoundBallPickup);
				cs_set_user_bpammo(id, CSW_HEGRENADE, cs_get_user_bpammo(id, CSW_HEGRENADE) + 1);
			}
			
			else
				give_item(id, "weapon_hegrenade");
				
			remove_entity(iNade);
		}
		
		else 
		{
			new iAttacker = pev(iNade, pev_iuser1);
			
			if(id != iAttacker
			&& is_user_connected(iAttacker))
			{
				if(cs_get_user_team(id) != cs_get_user_team(iAttacker))
				{
					//emit_sound(id, CHAN_AUTO, g_szDeathSounds[random(sizeof(g_szDeathSounds))]
					//	, 1.0, ATTN_NORM, 0, PITCH_NORM);
						
					ExecuteHamB(Ham_Killed, id, iAttacker, 1);	
					
					new players[32], playerID;
					new playerCount = uj_core_get_players(players, true, CS_TEAM_T);
					for (new i = 0; i < playerCount; ++i)
					{
						if(playerID <= 1)
						{
							if(!playerID)
							{
						
							uj_core_strip_weapons(playerID);

						
							}					
					
						}
					}
				}
			}
		}
	}
}

public FwdPlayerSpawnPost(id)
{
	if(g_dayEnabled
	&& is_user_alive(id))
	{
		if(cs_get_user_team(id) == CS_TEAM_T || CS_TEAM_CT)
		{
			give_item(id, "weapon_hegrenade");
			cs_set_user_bpammo(id, CSW_HEGRENADE, 5);
			
		}
		
	}
}

public FwdPlayerTakeDamagePre(iVictim, iInflictor, iAttacker, Float:flDamage, iDmgBits)
	return (g_dayEnabled || (is_user_alive(iAttacker)
		&& cs_get_user_team(iVictim) == cs_get_user_team(iAttacker)))
		? HAM_SUPERCEDE : HAM_IGNORED;

	

public FwdKnifeAttackPre(iKnife)
	return g_dayEnabled ? HAM_SUPERCEDE : HAM_IGNORED;
	
	
public grenade_throw(id, iNade, iWeaponid)
{
	if(g_dayEnabled
	&& iWeaponid == CSW_HEGRENADE)
	{
		set_pev(iNade, pev_iuser1, id);
		entity_set_size(iNade,Float:{-6.0,-6.0,-6.0},Float:{6.0,6.0,6.0});
		
		set_task(0.3, "TaskClearBallOwner", iNade);
		set_task(5.0, "TaskStopRolling", iNade);
	}
}


public MsgSendAudio(iMsgid, iMsgDest, id)
{
	if(id && g_dayEnabled)
	{
		new szSound[20];
		get_msg_arg_string(2, szSound, charsmax(szSound));
		
		if(equal(szSound, "%!MRAD_FIREINHOLE"))
		{
			set_msg_block(g_iMsgTextMsg, BLOCK_ONCE);
			return PLUGIN_HANDLED;
		}
	}
	
	return PLUGIN_CONTINUE;
}


public EventCurWeapon(id)
{
	if(g_dayEnabled)
	{
		new iWeapon = read_data(2);
		if(iWeapon == CSW_HEGRENADE)
		{
			set_pev(id, pev_viewmodel2, g_szViewDodgeball);
			set_pev(id, pev_weaponmodel2, g_szPlayerDodgeball);
		}
		
		else if(iWeapon == CSW_KNIFE)
		{
			set_pev(id, pev_viewmodel2, "");
			set_pev(id, pev_weaponmodel2, "");
		}
	}
}

public TaskClearBallOwner(iNade)
{
	if(pev_valid(iNade))
		set_pev(iNade, pev_owner, 0);
}


public TaskStopRolling(iNade)
{
	if(pev_valid(iNade))
	{
		if(pev(iNade, pev_flags) & FL_ONGROUND)
		{
			set_pev(iNade, pev_velocity, Float: {0.0, 0.0, 0.0});
			set_pev(iNade, pev_gravity, 1.0);
		}
		
		else
			set_task(5.0, "TaskStopRolling", iNade);
	}
}
