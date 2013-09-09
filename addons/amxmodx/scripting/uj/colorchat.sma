#include < amxmodx >

#pragma semicolon 1

#define PLUGIN "ColorChat"
#define VERSION "0.3.2"

new g_bitConnectedPlayers;
#define MarkUserConnected(%0)	g_bitConnectedPlayers |= 1<<(%0&31)
#define ClearUserConnected(%0)	g_bitConnectedPlayers &= ~(1<<(%0&31))
#define IsUserConnected(%0)		( g_bitConnectedPlayers & 1<<(%0&31) )

new const g_szTeamName[][] = 
{
	"",
	"TERRORIST",
	"CT"
};

new g_iMaxPlayers;
#define IsPlayer(%0)	( 1 <= (%0) <= g_iMaxPlayers )

new gmsgSayText, gmsgTeamInfo;
new Array:g_aStoreML;

public plugin_init() 
{
	register_plugin( PLUGIN, VERSION, "ConnorMcLeod" );

	gmsgTeamInfo = get_user_msgid("TeamInfo");
	gmsgSayText = get_user_msgid("SayText");
	g_iMaxPlayers = get_maxplayers();
	g_aStoreML = ArrayCreate();

	register_logevent("LogEvent_EnteredTheGame", 2, "1=entered the game");
}

public client_putinserver(id)
{
	if( !is_user_bot(id) )
	{
		MarkUserConnected(id);
	}
}

public LogEvent_EnteredTheGame()
{
	new szLog[80], szName[32];
	read_logargv(0, szLog, charsmax(szLog));
	parse_loguser(szLog, szName, charsmax(szName));
	
	new id = get_user_index(szName);
	if( !is_user_bot(id) && !is_user_hltv(id) )
	{
		for(new team = 1; team<=2; team++)
		{
			Send_TeamInfo(id, 33 + team, g_szTeamName[ team ]);
		}
	}
}

public client_disconnect(id)
{
	ClearUserConnected(id);
}

public plugin_end()
{
	ArrayDestroy(g_aStoreML);
}

public plugin_natives()
{
	register_library("chatcolor");
	register_native("client_print_color", "client_print_color");
	register_native("register_dictionary_colored", "register_dictionary_colored");
}

// client_print_color(id, sender, const szMsg[], any:...)
public client_print_color(iPlugin, iParams)
{
	new id = get_param(1);

	// check if id is different from 0
	if( id )
	{
		// check player range and ingame player
		if( !IsPlayer(id) || !IsUserConnected(id) )
		{
			return 0;
		}
	}

	new sender = get_param(2);

	new szMessage[192];

	// Specific player code
	if(id)
	{
		if( iParams == 3 )
		{
			// if only 3 args are passed, no need to format the string, just retrieve it
			get_string(3, szMessage, charsmax(szMessage));
		}
		else
		{
			// else format the string
			vdformat(szMessage, charsmax(szMessage), 3, 4);
		}

		Send_SayText(id, sender, szMessage);
	} 

	// Send message to all players
	else
	{
		// Figure out if at least 1 player is connected
		// so we don't send useless message if not
		// and we gonna use that player as team reference (aka SayText message sender) for color change
		new iPlayers[32], iNum;
		get_players(iPlayers, iNum, "c");
		if( !iNum )
		{
			return 0;
		}

		new iMlNumber;
		if( iParams >= 5 ) // ML can be used
		{
			new j;

			// Use that array to store LANG_PLAYER args indexes, and szTemp to store ML keys
			new szTemp[64];

			for(j=4; j<iParams; j++)
			{
				// retrieve original param value and check if it's LANG_PLAYER value
				if( get_param_byref(j) == LANG_PLAYER )
				{
					// as LANG_PLAYER == -1, check if next parm string is a registered language translation
					get_string(j+1, szTemp, charsmax(szTemp));
					if( GetLangTransKey(szTemp) != TransKey_Bad )
					{
						// Store that arg as LANG_PLAYER so we can alter it later
						ArrayPushCell(g_aStoreML, j);

						// Update ML array saire so we'll know 1st if ML is used,
						// 2nd how many args we have to alterate
						iMlNumber++;

						j++;
					}
				}
			}
		}

		// If arraysize == 0, ML is not used
		// we can only send 1 MSG_ALL message
		if( !iMlNumber )
		{
			if( iParams == 3 )
			{
				get_string(3, szMessage, charsmax(szMessage));
			}
			else
			{
				vdformat(szMessage, charsmax(szMessage), 3, 4);
			}

			for( new i = 0; i < iNum; i++ )
			{
				Send_SayText(iPlayers[i], sender, szMessage);
			}
		}

		// ML is used, we need to loop through all players,
		// format text and send a MSG_ONE SayText message
		else
		{
			for( new i = 0, j; i < iNum; i++ )
			{
				id = iPlayers[i];

				for(j=0; j<iMlNumber; j++)
				{
					// Set all LANG_PLAYER args to player index ( = id )
					// so we can format the text for that specific player
					set_param_byref(ArrayGetCell(g_aStoreML, j), id);
				}

				// format string for specific player
				vdformat(szMessage, charsmax(szMessage), 3, 4);

				Send_SayText(id, sender, szMessage);
			}
			// clear the array so next ML message we don't need to figure out
			// if should use PushArray or SetArray
			ArrayClear(g_aStoreML);
		}
	}
	return 1;
}

Send_TeamInfo(iReceiver, iPlayerId, szTeam[])
{
	message_begin(MSG_ONE, gmsgTeamInfo, _, iReceiver);
	write_byte(iPlayerId);
	write_string(szTeam);
	message_end();
}

Send_SayText(iReceiver, iPlayerId, szMessage[])
{
	message_begin(MSG_ONE, gmsgSayText, _, iReceiver);
	write_byte(iPlayerId ? iPlayerId : iReceiver);
	write_string(szMessage);
	message_end();
}

public register_dictionary_colored(iPlugin, iParams)
{
	new filename[64];
	get_string(1, filename, charsmax(filename));

	if( !register_dictionary(filename) )
	{
		return 0;
	}

	new szFileName[256];
	get_localinfo("amxx_datadir", szFileName, charsmax(szFileName));
	format(szFileName, charsmax(szFileName), "%s/lang/%s", szFileName, filename);
	new fp = fopen(szFileName, "rt");
	if( !fp )
	{
		log_error(AMX_ERR_NATIVE, "Failed to open %s", szFileName);
		return 0;
	}

	new szBuffer[512], szLang[3], szKey[64], szTranslation[256], TransKey:iKey;

	while( !feof(fp) )
	{
		fgets(fp, szBuffer, charsmax(szBuffer));
		trim(szBuffer);

		if( szBuffer[0] == '[' )
		{
			strtok(szBuffer[1], szLang, charsmax(szLang), szBuffer, 1, ']');
		}
		else if( szBuffer[0] )
		{
			strbreak(szBuffer, szKey, charsmax(szKey), szTranslation, charsmax(szTranslation));
			iKey = GetLangTransKey(szKey);
			if( iKey != TransKey_Bad )
			{
				replace_all( szTranslation, charsmax(szTranslation), "!g", "^4" );
				replace_all( szTranslation, charsmax(szTranslation), "!t", "^3" );
				replace_all( szTranslation, charsmax(szTranslation), "!n", "^1" );
				AddTranslation(szLang, iKey, szTranslation[2]);
			}
		}
	}
	
	fclose(fp);
	return 1;
}