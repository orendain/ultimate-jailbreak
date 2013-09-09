// Voice Manager by Exolent

// This plugin will gag all terrorists and dead cts.
// Admins with menu access are not affected by this.


#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <cstrike>

new const PLUGIN_NAME[] = "[UJ] Misc - VoiceManager";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

#define ADMIN_VOICE ADMIN_LEVEL_E

new bool:g_connected[33];
new g_max_clients;

public plugin_init() {
  register_plugin(PLUGIN_NAME, PLUGIN_VERS, PLUGIN_AUTH);
  register_forward(FM_Voice_SetClientListening, "FwdSetVoice");
  g_max_clients = get_maxplayers();
}

public client_putinserver(client) {
  g_connected[client] = true;
}

public client_disconnect(client) {
  g_connected[client] = false;
}

public FwdSetVoice(receiver, sender, bool:listen) {
  if( !(1 <= receiver <= g_max_clients)
  || !g_connected[receiver]
  || !(1 <= sender <= g_max_clients)
  || !g_connected[sender] ) return FMRES_IGNORED;

  new CsTeams:team = cs_get_user_team(sender);
  if( (team == CS_TEAM_T || team == CS_TEAM_CT && !is_user_alive(sender)) && !access(sender, ADMIN_VOICE) ) {
    engfunc(EngFunc_SetClientListening, receiver, sender, 0);
    return FMRES_SUPERCEDE;
  }

  return FMRES_IGNORED;
}
