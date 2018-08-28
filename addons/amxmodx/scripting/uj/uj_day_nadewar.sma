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

new const PLUGIN_NAME[] = "UJ | Day - Nade War";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

new const DAY_NAME[] = "Nade War";
new const DAY_OBJECTIVE[] = "Let the nades fly!";
new const DAY_SOUND[] = "";

new const DAY_HEALTH[] = "500";
new const DAY_GRAVITY[] = "500";
new const DAY_PRIMARYAMMO[] = "200";

// Day variables
new g_day = UJ_DAY_INVALID;
new bool:g_dayEnabled;

// Menu variables
new g_menuSpecial;

// CVar variables
new g_healthPCVar;
new g_gravityPCVar;
new g_primaryAmmoPCVar;
new g_serverGravityPCVar;

// Day necessities
new g_iTrailSprite;
new g_iMsgTextMsg;

public plugin_precache()
{
  g_iTrailSprite = precache_model("sprites/ultimate_jailbreak/aeroblast.spr");
}

public plugin_init()
{
  register_plugin(PLUGIN_NAME, PLUGIN_VERS, PLUGIN_AUTH);

  // CVars
  g_healthPCVar = register_cvar("uj_day_nadewar_health", DAY_HEALTH);
  g_gravityPCVar = register_cvar("uj_day_nadewar_gravity", DAY_GRAVITY);
  g_primaryAmmoPCVar = register_cvar("uj_day_nadewar_primaryammo", DAY_PRIMARYAMMO);
  g_serverGravityPCVar = get_cvar_pointer("sv_gravity");

  // Register this day
  g_day = uj_days_register(DAY_NAME, DAY_OBJECTIVE, DAY_SOUND);

  // Find all menus to allow this day to display in
  g_menuSpecial = uj_menus_get_menu_id("Special Days");

  // To glow the thrown nades
  register_message(get_user_msgid("SendAudio"), "MsgSendAudio");
  register_forward(FM_SetModel,"Fwd_Model_Think");
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

    // Find settings
    new Float:health = float(get_pcvar_num(g_healthPCVar));
    new primaryAmmoCount = get_pcvar_num(g_primaryAmmoPCVar);

    new players[32], playerID;
    new playerCount = uj_core_get_players(players, true);
    for (new i = 0; i < playerCount; ++i) {
      playerID = players[i];
      uj_core_strip_weapons(playerID);

      set_pev(playerID, pev_health, health);
      cs_set_user_armor(playerID, 100, CS_ARMOR_VESTHELM);

      give_item(playerID, "weapon_hegrenade");
      cs_set_user_bpammo(playerID, CSW_HEGRENADE, primaryAmmoCount);

      uj_effects_glow_player(playerID, 0, 255, 0, 16);
    }

    set_lights("c");
    set_pcvar_num(g_serverGravityPCVar, get_pcvar_num(g_gravityPCVar));

    uj_core_set_friendly_fire(true);
    uj_core_block_weapon_pickup(0, true);
    uj_chargers_block_heal(0, true);
    uj_chargers_block_armor(0, true);
  }
}

end_day()
{
  if (g_dayEnabled) {
    new players[32];
    new playerCount = uj_core_get_players(players, true);
    for (new i = 0; i < playerCount; ++i) {
      uj_core_strip_weapons(players[i]);
    }

    set_lights("m");
    set_pcvar_num(g_serverGravityPCVar, 800);

    uj_core_set_friendly_fire(false);
    uj_core_block_weapon_pickup(0, false);
    uj_chargers_block_heal(0, false);
    uj_chargers_block_armor(0, false);

    g_dayEnabled = false;
  }
}

public MsgSendAudio(const iMsgId, const iMsgDest, const id)
{
  if(g_dayEnabled) {
    new szRadioKey[19];
    static const MRAD_FIREINHOLE[] = "%!MRAD_FIREINHOLE";
    get_msg_arg_string(2, szRadioKey, charsmax(szRadioKey));
    if(equal(szRadioKey, MRAD_FIREINHOLE)) {
      if(get_msg_block(g_iMsgTextMsg) != BLOCK_SET) {
        set_msg_block(g_iMsgTextMsg, BLOCK_ONCE);
      }
      return PLUGIN_HANDLED;
    }
  }

  return PLUGIN_CONTINUE;
}

public Fwd_Model_Think(ent, const model[])
{
  if(g_dayEnabled) {

    if(!pev_valid(ent)) {
      return FMRES_IGNORED;
    }

    static playerID;
    playerID = pev(ent, pev_owner);

    if(!(1 <= playerID <= 32)) {
      return FMRES_IGNORED;
    }

    static iRandom_1; iRandom_1 = random(256);
    static iRandom_2; iRandom_2 = random(256);
    static iRandom_3; iRandom_3 = random(256);
    set_rendering(ent,kRenderFxGlowShell,iRandom_1,iRandom_2,iRandom_3,kRenderNormal,16);

    message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
    write_byte(TE_BEAMFOLLOW);
    write_short(ent);
    write_short(g_iTrailSprite);
    write_byte(15);
    write_byte(1);
    write_byte(iRandom_1);
    write_byte(iRandom_2);
    write_byte(iRandom_3);
    write_byte(191);
    message_end();
  }

  return FMRES_IGNORED;
}
