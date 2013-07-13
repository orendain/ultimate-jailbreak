#include <amxmodx> 
#include <amxmisc> 
#include <cstrike>
#include <dhudmessage>
#include <uj_colorchat>
#include <uj_core>
#include <uj_days>
#include <uj_effects>
#include <uj_freedays>
#include <uj_menus>

new const PLUGIN_NAME[] = "[UJ] Day - Red Light Green Light";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

new const DAY_NAME[] = "Red Light Green Light";
new const DAY_OBJECTIVE[] = "Get those quick fingers ready!";
new const DAY_SOUND[] = "";

new const KILL_LIMIT = 2;
new const MINIMUM_PRISONERS = 2;

new g_iMsgId_ScreenFade;

#define MAX_PLAYERS 32

new g_day;
new g_menuActivities;

new g_kills;
new g_playersIncluded;
new g_playersLeft
new bool: g_dayEnabled

// Reaction menus
new g_menuTypes
new g_menuReactions


public plugin_init()
{
register_plugin(PLUGIN_NAME, PLUGIN_VERS, PLUGIN_AUTH);

// Register day
g_day = uj_days_register(DAY_NAME, DAY_OBJECTIVE, DAY_SOUND);

// Find all valid menus to display this under
g_menuActivities = uj_menus_get_menu_id("Activities");

g_iMsgId_ScreenFade   = get_user_msgid("ScreenFade");

//register_forward(FM_PlayerPreThink, "FM_PlayerPreThink_Pre", 0);
//register_forward(FM_CmdStart, "CmdStart");

build_menu();
}

public uj_fw_days_select_pre(playerID, dayID, menuID)
{
// This is not our day - do not block
if (dayID != g_day) {
return UJ_DAY_AVAILABLE;
}

// Only display if in the parent menu we recognize
if (menuID != g_menuActivities) {
return UJ_DAY_DONT_SHOW
}

// Disable if we have reached the kill limit for the round
if (g_kills >= KILL_LIMIT) {
return UJ_DAY_NOT_AVAILABLE;
}

// Disable if there are not enough alive prisoners
if (!are_enough_prisoners()) {
return UJ_DAY_NOT_AVAILABLE;
}

return UJ_DAY_AVAILABLE;
}

public uj_fw_days_select_post(playerID, dayID)
{
// This is not our item
if (dayID != g_day)
return;

display_reaction_type_menu(playerID);
}

public uj_fw_days_end(dayID)
{
// if dayID refers to our day and our day is enabled
if(dayID == g_day && g_dayEnabled) {
end_day();
}
}

public uj_fw_core_round_new()
{
// Reset kill count on each new round
g_kills = 0;
}

are_enough_prisoners()
{
return (uj_core_get_live_prisoner_count() >= MINIMUM_PRISONERS);
}

build_menu()
{
g_menuTypes = menu_create("Select a Light", "menu_type_handle")
//g_menuReactions = menu_create( "Select a Light", "menu_reaction_handle" )

menu_additem(g_menuTypes, "Red", "", 0)
menu_additem(g_menuTypes, "Yellow", "", 0)
menu_additem(g_menuTypes, "Green", "", 0)
menu_additem(g_menuTypes, "Red Light", "", 0)
menu_additem(g_menuTypes, "Yellow Light", "", 0)
menu_additem(g_menuTypes, "Green Light", "", 0)

//menu_additem(g_menuReactions, "Red", "", 0)
//menu_additem(g_menuReactions, "Yellow", "", 0)
}

public menu_type_handle(playerID, menu, item)
{
if (item < 0) {
return PLUGIN_CONTINUE
}

static iPlayers[32], iNum, i, iPlayer;
get_players( iPlayers, iNum, "ae", "TERRORIST"  ); 
for( i=0; i<iNum; i++ )
{
iPlayer = iPlayers[i];      

switch (item) {
case 0: {
set_dhudmessage(255, 0, 0, -1.0, 0.4, 0, 0.75, 3.0, 0.75, 0.75);
show_dhudmessage(0, "Red!");
uj_colorchat_print(0, UJ_COLORCHAT_RED, "RED!")
menu_display(playerID, menu, 0);
show_dhudmessage(0, "");
}
case 1: {
set_dhudmessage(255, 255, 0, -1.0, 0.4, 0, 0.75, 3.0, 0.75, 0.75);
show_dhudmessage(0, "Yellow!");
uj_colorchat_print(0, UJ_COLORCHAT_RED, "Yellow!")
menu_display(playerID, menu, 0);
UTIL_ScreenFade(playerID, 2.0, 2.5);
show_dhudmessage(0, "");
}
case 2: {
set_dhudmessage(0, 255, 0, -1.0, 0.4, 0, 0.75, 3.0, 0.75, 0.75);
show_dhudmessage(0, "Green!");
uj_colorchat_print(0, UJ_COLORCHAT_RED, "Green!")
menu_display(playerID, menu, 0);
UTIL_ScreenFade(playerID, 2.0, 2.5);
show_dhudmessage(0, "");
}
case 3: {
UTIL_ScreenFade1(iPlayer, 2.0, 4.0); //red light
set_dhudmessage(255, 0, 0, -1.0, 0.4, 0, 0.75, 3.0, 0.75, 0.75);
show_dhudmessage(0, "Red Light!");
uj_colorchat_print(0, UJ_COLORCHAT_RED, "RED LIGHT!")
menu_display(playerID, menu, 0);
show_dhudmessage(0, "");
}
case 4: {
UTIL_ScreenFade3(iPlayer, 2.0, 4.0); //yellow light
set_dhudmessage(255, 255, 0, -1.0, 0.4, 0, 0.75, 3.0, 0.75, 0.75);
show_dhudmessage(0, "Yellow Light!");
uj_colorchat_print(0, UJ_COLORCHAT_RED, "YELLOW LIGHT!")
menu_display(playerID, menu, 0);
show_dhudmessage(0, "");
}
case 5: {
UTIL_ScreenFade4(iPlayer, 2.0, 4.0); //green light
set_dhudmessage(0, 255, 0, -1.0, 0.4, 0, 0.75, 3.0, 0.75, 0.75);
show_dhudmessage(0, "Green Light!");
uj_colorchat_print(0, UJ_COLORCHAT_RED, "GREEN LIGHT!")
menu_display(playerID, menu, 0);
show_dhudmessage(0, "");
}
case MENU_EXIT: {
//uj_colorchat_print(0, playerID, "MENU_EXIT ON TYPES");
uj_days_end();
}
}
}

return PLUGIN_HANDLED;
}

display_reaction_type_menu(playerID)
{
menu_display(playerID, g_menuTypes, 0);
}		

display_reaction_action_menu(playerID)
{
menu_display(playerID, g_menuReactions, 0);
}

public start_reactions()
{
g_dayEnabled = true;

// Find and include all terrorists without freedays
new players[32], pid;
new playerCount = uj_core_get_players(players, true, CS_TEAM_T);
for(new i = 0; i < playerCount; i++) {
pid = players[i];
if (!uj_freedays_has_freeday(pid)) {
set_bit(g_playersIncluded, pid);
g_playersLeft++;
}
}

}

end_day()
{
// Reset count and actions

g_dayEnabled = false;
}

#define CLAMP_SHORT(%1) clamp( %1, 0, 0xFFFF )
#define CLAMP_BYTE(%1) clamp( %1, 0, 0xFF )

UTIL_ScreenFade(const id, Float:fDuration, Float:fHoldTime) {
message_begin( MSG_ONE_UNRELIABLE, g_iMsgId_ScreenFade, _, id);
write_short(CLAMP_SHORT(floatround(4096 * fDuration))); // 1 << 12 = 4096
write_short(CLAMP_SHORT(floatround(4096 * fHoldTime)));
write_short(0x0000); // FFADE_IN = 0x0000
write_byte(0);
write_byte(0);
write_byte(0);
write_byte(0);
message_end();
}

UTIL_ScreenFade1(const id, Float:fDuration, Float:fHoldTime) {	//red
message_begin( MSG_ONE_UNRELIABLE, g_iMsgId_ScreenFade, _, id);
write_short(CLAMP_SHORT(floatround(4096 * fDuration))); // 1 << 12 = 4096
write_short(CLAMP_SHORT(floatround(4096 * fHoldTime)));
write_short(0x0000); // FFADE_IN = 0x0000
write_byte(255);
write_byte(0);
write_byte(0);
write_byte(150);
message_end();
}

UTIL_ScreenFade3(const id, Float:fDuration, Float:fHoldTime) {	//yellow
message_begin( MSG_ONE_UNRELIABLE, g_iMsgId_ScreenFade, _, id);
write_short(CLAMP_SHORT(floatround(4096 * fDuration))); // 1 << 12 = 4096
write_short(CLAMP_SHORT(floatround(4096 * fHoldTime)));
write_short(0x0000); // FFADE_IN = 0x0000
write_byte(255);
write_byte(140);
write_byte(0);
write_byte(150);
message_end();
}

UTIL_ScreenFade4(const id, Float:fDuration, Float:fHoldTime) {	//green
message_begin( MSG_ONE_UNRELIABLE, g_iMsgId_ScreenFade, _, id);
write_short(CLAMP_SHORT(floatround(4096 * fDuration))); // 1 << 12 = 4096
write_short(CLAMP_SHORT(floatround(4096 * fHoldTime)));
write_short(0x0000); // FFADE_IN = 0x0000
write_byte(0);
write_byte(255);
write_byte(0);
write_byte(150);
message_end();
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
