#include <amxmodx>
#include <cstrike>
#include <engine>
#include <uj_colorchat>

new const PLUGIN_NAME[] = "[UJ] HUD - Hide Kills";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

// HUD variables
//new gMaxPlayers;

public plugin_init()
{
  register_plugin(PLUGIN_NAME, PLUGIN_VERS, PLUGIN_AUTH);

  register_message(get_user_msgid("DeathMsg"), "MessageDeathMsg");
  
  //gMaxPlayers = get_maxplayers();
}

public MessageDeathMsg(msg, dest, receiver)
{
  new killer = get_msg_arg_int(1);
  new victim = get_msg_arg_int(2);
  //new headshot = get_msg_arg_int(3);

  if (1<=killer<=32 && cs_get_user_team(killer) == CS_TEAM_T) {
    //new weaponName[32];
    //get_msg_arg_string(4, weaponName, charsmax(weaponName));

    set_msg_arg_int(1, 0, victim);
    set_msg_arg_string(4, "world");

    //uj_colorchat_print(0,1, "wep: %s", weaponName);
  }/*

  

  for(new i = 1; i <= gMaxPlayers; i++) {
    if(is_user_connected(i) && cs_get_user_team(i) == CS_TEAM_T) {
      message_begin(MSG_ONE, msg, _, i);
      write_byte(killer);
      write_byte(victim);
      write_byte(headshot);
      write_string(weaponName);
      message_end();
    }
  }
*/
  //return PLUGIN_HANDLED;
}
