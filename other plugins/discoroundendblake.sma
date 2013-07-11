#include <amxmodx>
#include <amxmisc>
#include <fun>
#include <dhudmessage>
#include <fakemeta>
#include <engine>
#include <uj_colorchat>


public plugin_init() 
{ 
	register_plugin("RoundSound","1.0","PaintLancer")
	register_event("SendAudio", "t_win", "a", "2&%!MRAD_terwin");
	register_event("SendAudio", "ct_win", "a", "2&%!MRAD_ctwin");
	register_logevent( "Event_RoundStart", 2, "1=Round_Start" );
}

public t_win()
{

	switch( random_num( 0, 3 ) )
	{
		case 0: client_cmd(0,"spk misc/roundend/t/riot");
		case 1: client_cmd(0,"spk misc/roundend/t/jerk");
		case 2: client_cmd(0,"spk misc/roundend/t/gangnam");
		case 3: client_cmd(0,"spk misc/roundend/t/levels");		
	}
	
	set_dhudmessage(255, 0, 0, -1.0, 0.20, 2, 6.0, 3.0, 0.1, 1.5);
	show_dhudmessage(0, "Prisoners have taken over!");
	
	uj_colorchat_print(0, 0, "Prisoners Win.");
	set_task(0.5,"DiscoMode",1337,"",0,"b");
	client_cmd(0, "drop");
	return PLUGIN_CONTINUE;
}

public ct_win()
{
	

	switch( random_num( 0, 3 ) )
	{
		case 0: client_cmd(0,"spk misc/roundend/ct/beatit");
		case 1: client_cmd(0,"spk misc/roundend/ct/thrift");
		case 2: client_cmd(0,"spk misc/roundend/ct/boom");
		case 3: client_cmd(0,"spk misc/roundend/ct/victory");	
	}
	
	set_dhudmessage(0, 0, 255, -1.0, 0.20, 1, 6.0, 3.0, 0.1, 1.5);
	show_dhudmessage(0, "Guards have maintained control of the prison!");
	
	uj_colorchat_print(0, 0, "Guards Win.");
	set_task(0.5,"DiscoMode",1337,"",0,"b");
	return PLUGIN_CONTINUE;
}

public plugin_precache() 
{

	precache_sound("misc/roundend/ct/beatit.wav");
	precache_sound("misc/roundend/ct/thrift.wav");
	precache_sound("misc/roundend/ct/boom.wav");
	precache_sound("misc/roundend/ct/victory.wav");
	precache_sound("misc/roundend/t/riot.wav")
	precache_sound("misc/roundend/t/gangnam.wav")
	precache_sound("misc/roundend/t/levels.wav")
	precache_sound("misc/roundend/t/jerk.wav")	
	
	return PLUGIN_CONTINUE
	
}

public DiscoMode()
{
	new players[32], num
	get_players(players,num,"ah")
	for(new i=0;i<num;i++)
	{
		new num1 = random_num(0,255)
		new num2 = random_num(0,255)
		new num3 = random_num(0,255)
		new alpha = random_num(40,65)
		message_begin(MSG_ONE,get_user_msgid("ScreenFade"),{0,0,0},players[i])
		write_short(~0)
		write_short(~0)
		write_short(1<<12)
		write_byte(num1)
		write_byte(num2)
		write_byte(num3)
		write_byte(alpha)
		message_end()
		set_user_rendering(players[i],kRenderFxGlowShell,num1,num2,num3,kRenderNormal,21)
		//set_user_rendering(players[i],kRenderFxGlowShell,num1,num2,num3,kRenderTransAlpha,255)
		
	}
}

public DiscoOff()
{
	new players[32], num
	get_players(players,num,"h")
	for(new i=0;i<num;i++)
	{
		message_begin(MSG_ONE,get_user_msgid("ScreenFade"),{0,0,0},players[i])
		write_short(~0)
		write_short(~0)
		write_short(1<<12)
		write_byte(0)
		write_byte(0)
		write_byte(0)
		write_byte(0)
		message_end()

		set_user_rendering(players[i])
	}
}

public Event_RoundStart()
{
	set_task(0.2,"DiscoOff")
	remove_task(1337)
	client_cmd(0, "stopsound")
	server_cmd( "sv_gravity 800" );
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
