#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <uj_colorchat>
#include <uj_logs>
#include <uj_menus>
#include <uj_points>

new const PLUGIN_NAME[] = "[UJ] Game - Blackjack";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

new const MENU_NAME[] = "Blackjack";

new const BLACKJACK_BET_MIN[] = "25";
new const BLACKJACK_BET_INCREMENT[] = "25";

// Moved up from original code
new const CFG_DICTIONARY[] = "uj_game_blackjack.txt";
new const CFG_FILENAME[] = "uj_game_blackjack.ini";

new g_entryID
new g_menuGames

// CVars
new g_betMinPCVar;
new g_betIncrementPCVar;

public plugin_init()
{
  register_plugin(PLUGIN_NAME, PLUGIN_VERS, PLUGIN_AUTH);

  // Register a menu entry
  g_entryID = uj_menus_register_entry(MENU_NAME);

  // Find the menus this should display in
  g_menuGames = uj_menus_get_menu_id("Games");

  // From original code
  register_dictionary(CFG_DICTIONARY);
  
  // Cvars
  g_betMinPCVar = register_cvar("uj_game_blackjack_minimum", BLACKJACK_BET_MIN);
  g_betIncrementPCVar = register_cvar("uj_game_blackjack_increment", BLACKJACK_BET_INCREMENT);
}

public uj_fw_menus_select_pre(playerID, menuID, entryID)
{
  // This is not our item - do not block
  if (entryID != g_entryID)
    return UJ_MENU_AVAILABLE;

  // Do not show if it is not in this specific parent menu
  if (menuID != g_menuGames)
    return UJ_MENU_DONT_SHOW;
  
  return UJ_MENU_AVAILABLE;
}

public uj_fw_menus_select_post(playerID, menuid, entryID)
{
  // This is not our item
  if (g_entryID != entryID)
    return;
  
  // Now open up our own menu
  showMenuBlackJack(playerID);
}





/* Adjusted, non-UJ original code */

const CFG_MAX_PARAM_SIZE = 50;
new CFG_SITE_URL[CFG_MAX_PARAM_SIZE];
new CFG_CARD_PATH[CFG_MAX_PARAM_SIZE];
new CFG_IMAGES_PATH[CFG_MAX_PARAM_SIZE];

const N_CARDS_PER_SUIT = 13;
const N_SUITS = 4;

new cardFiguresNames[N_CARDS_PER_SUIT][] = { "Ace" , "Two", "Three", "Four", "Five" , "Six", "Seven", "Eight", "Nine", "Ten", "Jack","Queen","King" } ;
new cardSuitNames[N_SUITS][] = { "Hearts" ,"Diamonds","Clubs","Spades"};

enum CARD
{
	SUIT,
	VALUE,
	CARD_ID
}

const N_IDS = 33;
const N_CARDS = 52;

new decks[N_IDS][N_CARDS][CARD];
new decksCount[N_IDS];

const PER_PLAYER_MAX_CARDS = 6;

new decksCroupier[N_IDS][PER_PLAYER_MAX_CARDS][CARD];
new decksCroupierCount[N_IDS];

new decksPlayers[N_IDS][PER_PLAYER_MAX_CARDS][CARD];
new decksPlayersCount[N_IDS];

new betValues[N_IDS];

new inGame[N_IDS];
new gameOver[N_IDS];

#define OFFSET_CSMONEY 115

public plugin_cfg()
{	
	handleConfigFile();	
}
handleConfigFile()
{
	const configsDirLastIndex = 49;
	new configsDir[configsDirLastIndex+1];
	
	get_configsdir(configsDir,configsDirLastIndex);
	
	const fileNameLastIndex = configsDirLastIndex + 15;
	new fileName[fileNameLastIndex+1];
		
	format(fileName,fileNameLastIndex,"%s/%s",configsDir,CFG_FILENAME);

	new success = 0;		
	
	if(file_exists(fileName))
	{
		new file = fopen(fileName,"r");
		
		if( !feof(file) )
		{
			fgets (file, CFG_SITE_URL, CFG_MAX_PARAM_SIZE-1);
			success = 1;
		}
		
		if( !feof(file) )
			fgets (file, CFG_CARD_PATH, CFG_MAX_PARAM_SIZE-1);
		else
			format(CFG_CARD_PATH,CFG_MAX_PARAM_SIZE-1,"");
		
		if( !feof(file) )
			fgets (file, CFG_IMAGES_PATH, CFG_MAX_PARAM_SIZE-1);
		else
			format(CFG_IMAGES_PATH,CFG_MAX_PARAM_SIZE-1,"");
	}

	if (!success) {
		server_print("[UJ] uj_game_blackjack error during handleConfigFile()");
	}
}
motdShowTable(id)
{
	const motdLast = 1299;
	new motd[motdLast+1];

	const styleLast = 350;
	new style[styleLast+1];	
	
	format(style,styleLast,"<style>body{ font-family:Verdana, Arial, Helvetica, sans-serif;background-image: url('%s%sbackground.png'); text-align:center;	width:60%%;margin:auto;margin-top:2%%;}.pi{padding:2%%;font-size:11px;}.m{padding:3%%;}.c{display:inline;}</style>",CFG_SITE_URL,CFG_IMAGES_PATH);
	
	format(motd,motdLast,"%s",style);
	
	format(motd,motdLast,"%s%s",motd,"<div class='pi'>");
	
	if(!gameOver[id])
		format(motd,motdLast,"%s<i>Croupier</i>",motd);
	else
		format(motd,motdLast,"%s<i>Croupier</i>: %d points",motd,getCroupierCardsSum(decksCroupier[id],decksCroupierCount[id]));
		
	format(motd,motdLast,"%s%s",motd,"</div>");
	
	format(motd,motdLast,"%s%s",motd,"<div>");
	
	if(!gameOver[id])
		format(motd,motdLast,"%s<div class='c'><img src='%s%sback.png'></div>",motd,CFG_SITE_URL,CFG_CARD_PATH);	
	else
		format(motd,motdLast,"%s<div class='c'><img src='%s%s%sOf%s.png'></div>",motd,CFG_SITE_URL,CFG_CARD_PATH,cardFiguresNames[ decksCroupier[id][0][CARD_ID]], cardSuitNames[ decksCroupier[id][0][SUIT] ]);	
	
	for(new i=1; i< decksCroupierCount[id]; i++)
	{	
		format(motd,motdLast,"%s<div class='c'><img src='%s%s%sOf%s.png'></div>",motd,CFG_SITE_URL,CFG_CARD_PATH,cardFiguresNames[ decksCroupier[id][i][CARD_ID]], cardSuitNames[ decksCroupier[id][i][SUIT] ]);	
	}
	
	format(motd,motdLast,"%s%s",motd,"</div>");
	
	format(motd,motdLast,"%s%s",motd,"<div class='m'> ");
	
	const MSG_LAST_INDEX=19;
	new msg[MSG_LAST_INDEX+1];
	
	if(gameOver[id])
	{
		switch(gameResult(id))
		{
			case -1:
			{
				format(msg,MSG_LAST_INDEX,"%L",id,"MSG_MOTD_LOST");
			}
			case 0:
			{
				format(msg,MSG_LAST_INDEX,"%L",id,"MSG_MOTD_DRAW");
			}
			case 1:
			{
				format(msg,MSG_LAST_INDEX,"%L",id,"MSG_MOTD_WIN");
			}
			case 2:
			{
				format(msg,MSG_LAST_INDEX,"%L",id,"MSG_MOTD_BLACKJACK");
			}
		}
	}
	
	format(motd,motdLast,"%s%s",motd,msg);
	
	format(motd,motdLast,"%s%s",motd,"</div>");
	
	format(motd,motdLast,"%s%s",motd,"<div>");
	
	for(new i=0; i< decksPlayersCount[id]; i++)
	{	
		format(motd,motdLast,"%s<div class='c'><img src='%s%s%sOf%s.png'></div>",motd,CFG_SITE_URL,CFG_CARD_PATH,cardFiguresNames[ decksPlayers[id][i][CARD_ID]], cardSuitNames[ decksPlayers[id][i][SUIT] ]);	
	}
		
	format(motd,motdLast,"%s%s",motd,"</div>");
	
	new name[32];
	get_user_name(id,name,31);
	
	format(motd,motdLast,"%s%s",motd,"<div class='pi'>");
	format(motd,motdLast,"%s<i>%s</i>: %d %L",motd,name,getPlayerCardsSum(decksPlayers[id],decksPlayersCount[id]),id,"POINTS");
	format(motd,motdLast,"%s%s",motd,"</div>");
		
	show_motd(id,motd);
}


renewDeck(deck[N_CARDS][CARD],&count)
{
	count = 0;
	
	for(new i=0;i<N_SUITS;i++)
	{
		new j;
		new newCard[CARD];
			
		newCard[SUIT] = i;
		newCard[CARD_ID] = 0;
		newCard[VALUE] = 11;
				
		deck[count++] = newCard;
		

		for(j=1;j<=9;j++)
		{
			new newCard[CARD];
			
			newCard[SUIT] = i;
			newCard[CARD_ID] = j;
			newCard[VALUE] = j+1;
			deck[count++] = newCard;
		}
		
		for(j=10;j<=12;j++)
		{
			new newCard[CARD];
			
			newCard[SUIT] = i;
			newCard[CARD_ID] = j;
			newCard[VALUE] = 10;
			deck[count++] = newCard;
		}
	}
	
}

public showMenuBlackJack(id)
{
	if(!inGame[id]  && !gameOver[id])
	{
		showMenuStart(id);
	}
	else if(gameOver[id])
	{
		showMenuGameOver(id);
	}
	else if(inGame[id])
	{
		showMenuInGame(id);
	}
	return PLUGIN_HANDLED;
}
public showMenuGameOver(id)
{
	new menu = menu_create("","handleMenuGameOver");
	
	const TITLE_LAST_INDEX = 60 + CFG_MAX_PARAM_SIZE;
	new fullTitle[TITLE_LAST_INDEX+1];
	
	format(fullTitle,TITLE_LAST_INDEX,"%L^n^n",id,"TITLE_MENU");
	
	const MSG_LAST_INDEX = 39;
	new msg[MSG_LAST_INDEX+1];
	
	switch (gameResult(id))
	{
		case -1:
		{
			format(msg,MSG_LAST_INDEX,"%L",id,"MSG_MENU_LOST",betValues[id]);
		}
		case 0:
		{
			format(msg,MSG_LAST_INDEX,"%L",id,"MSG_MENU_DRAW");
		}
		case 1:
		{
			format(msg,MSG_LAST_INDEX,"%L",id,"MSG_MENU_WIN",betValues[id]);
		}
		case 2:
		{
			format(msg,MSG_LAST_INDEX,"%L",id,"MSG_MENU_BLACKJACK",betValues[id] * 2);
		}
	}
	
	format(fullTitle,TITLE_LAST_INDEX,"%s%s",fullTitle,msg);
	
	menu_setprop(menu,MPROP_TITLE,fullTitle);	
	
	const EXIT_LAST_INDEX = 10;
	new exitText[EXIT_LAST_INDEX+1];
	format(exitText,EXIT_LAST_INDEX,"%L",id,"MSG_MENU_EXIT");
		
	menu_setprop(menu, MPROP_EXITNAME, exitText);
	
	const SHOW_TABLE_LAST_INDEX = 15;
	new showTable[SHOW_TABLE_LAST_INDEX+1];
	
	format(showTable,SHOW_TABLE_LAST_INDEX,"%L",id,"MSG_MENU_SHOW_TABLE");
	
	const NEW_GAME_LAST_INDEX = 15;
	new newGame[NEW_GAME_LAST_INDEX+1];
	
	format(newGame,NEW_GAME_LAST_INDEX,"%L",id,"MSG_MENU_NEW_GAME");
	
	menu_additem(menu, showTable,"1");
	menu_additem(menu, newGame,"2");
		
	menu_display(id,menu,0);
}
public handleMenuGameOver(id , menu , item)
{
	if( item < 0 ) 
		return PLUGIN_CONTINUE;	
	
	new access, callback; 
	
	new actionString[2];		
	menu_item_getinfo(menu,item,access, actionString ,2,_,_, callback);		
	new action = str_to_num(actionString);	
	
	switch(action)
	{
		case 1:
		{
			showMenuGameOver(id);
			motdShowTable(id);
		}
		case 2:
		{
			doReset(id);
			showMenuStart(id);
		}
	}
	
	return PLUGIN_HANDLED;
}
public showMenuInGame(id)
{	
	new menu = menu_create("","handleMenuInGame");
		
	const TITLE_LAST_INDEX = CFG_MAX_PARAM_SIZE + 1;
	
	new title[TITLE_LAST_INDEX+1];
	
	format(title,TITLE_LAST_INDEX,"%L^n^n",id,"TITLE_MENU");
		
	menu_setprop(menu,MPROP_TITLE,title);	
	
	const EXIT_LAST_INDEX = 10;
	new exitText[EXIT_LAST_INDEX+1];
	format(exitText,EXIT_LAST_INDEX,"%L",id,"MSG_MENU_EXIT");
	
	menu_setprop(menu, MPROP_EXITNAME, exitText);
	
	const SHOW_TABLE_LAST_INDEX = 15;
	new showTable[SHOW_TABLE_LAST_INDEX+1];
	
	format(showTable,SHOW_TABLE_LAST_INDEX,"%L",id,"MSG_MENU_SHOW_TABLE");
	
	const ASKCARD_LAST_INDEX = 20;
	new askCardText[ASKCARD_LAST_INDEX+1];
	
	format(askCardText,ASKCARD_LAST_INDEX,"%L",id,"MSG_MENU_ASK_CARD");
	
	const STOP_LAST_INDEX = 20;
	new stopText[STOP_LAST_INDEX+1];
	
	format(stopText,STOP_LAST_INDEX,"%L",id,"MSG_MENU_STOP");
	
	menu_additem(menu, showTable,"1");
	menu_additem(menu, askCardText,"2");
	menu_additem(menu, stopText,"3");
		
	menu_display(id,menu,0);
	
	
	return PLUGIN_CONTINUE;
}
public handleMenuInGame(id , menu , item)
{
	if( item < 0 ) 
		return PLUGIN_CONTINUE;	
	
	new access, callback; 
	
	new actionString[2];		
	menu_item_getinfo(menu,item,access, actionString ,2,_,_, callback);		
	new action = str_to_num(actionString);	
	
	switch(action)
	{
		case 1:
		{
			showMenuInGame(id);
			motdShowTable(id);
		}
		case 2:
		{
			askCard(id);
			showMenuBlackJack(id);
			motdShowTable(id);
		}
		case 3:
		{
			stop(id);
			showMenuBlackJack(id);
			motdShowTable(id);
		}
	}
	
	return PLUGIN_HANDLED;
}
public showMenuStart(id)
{
	new menu = menu_create("","handleMenuStart");
	
	const TITLE_LAST_INDEX = 30 + CFG_MAX_PARAM_SIZE;
	new titleFull[TITLE_LAST_INDEX+1];
	
	format(titleFull,TITLE_LAST_INDEX,"%L^n^n",id,"TITLE_MENU");
	
	new cvarBetValueMin = get_pcvar_num(g_betMinPCVar);
	
	const EXIT_LAST_INDEX = 10;
	new exitText[EXIT_LAST_INDEX+1];
	format(exitText,EXIT_LAST_INDEX,"%L",id,"MSG_MENU_EXIT");
		
	menu_setprop(menu,MPROP_PERPAGE,7);
		
	if(uj_points_get(id) < cvarBetValueMin)
	{
		format(titleFull,TITLE_LAST_INDEX,"%L",id,"MSG_MENU_WARN_MIN_BET",cvarBetValueMin);
	
		menu_additem(menu,exitText,"0");
		menu_setprop(menu,MPROP_EXIT,MEXIT_NEVER);
	}
	else
	{
		if(betValues[id] < cvarBetValueMin)
			betValues[id] = cvarBetValueMin;
	
		if(betValues[id] > uj_points_get(id))
			betValues[id] = uj_points_get(id);
	
		format(titleFull,TITLE_LAST_INDEX,"%s%L",titleFull,id,"MSG_MENU_BET_VALUE",betValues[id]);
		
		const RAISE_BET_LAST_INDEX = 30;
		const DOWN_BET_LAST_INDEX = 30;
		const BET_ALL_LAST_INDEX = 15;
		const START_GAME_LAST_INDEX = 15;
		
		new raiseBet[RAISE_BET_LAST_INDEX+1];
		new downBet[DOWN_BET_LAST_INDEX+1];
		new betAll[BET_ALL_LAST_INDEX+1];
		new startGameText[START_GAME_LAST_INDEX+1];
		
		format(betAll,BET_ALL_LAST_INDEX,"%L",id,"MSG_MENU_BET_ALL");
		
		format(startGameText,START_GAME_LAST_INDEX,"%L",id,"MSG_MENU_START");
		
		new increment = get_pcvar_num(g_betIncrementPCVar);

		format(raiseBet,RAISE_BET_LAST_INDEX,"%L",id,"MSG_MENU_RAISE_BET",increment);
		format(downBet,DOWN_BET_LAST_INDEX,"%L",id,"MSG_MENU_DOWN_BET",increment);
		
		menu_additem(menu, raiseBet,"1");
		menu_additem(menu, downBet,"2");
		menu_addtext(menu, "",0);
		
		format(raiseBet,RAISE_BET_LAST_INDEX,"%L",id,"MSG_MENU_RAISE_BET",increment*10);
		format(downBet,DOWN_BET_LAST_INDEX,"%L",id,"MSG_MENU_DOWN_BET",increment*10);
		
		menu_additem(menu, raiseBet,"3");
		menu_additem(menu, downBet,"4");
		menu_addtext(menu, "",0);
		menu_additem(menu, betAll,"5");
		menu_addtext(menu, "^n",0);
		menu_additem(menu, startGameText,"6");
		menu_addtext(menu,"",1);
		
	}
	menu_setprop(menu,MPROP_BACKNAME,"");
	menu_setprop(menu,MPROP_NEXTNAME,"");
	
	menu_setprop(menu,MPROP_TITLE,titleFull);	
	
	
	menu_setprop(menu, MPROP_EXITNAME, exitText);
	
	menu_display(id,menu,0);
	
	
	return PLUGIN_CONTINUE;
}
public handleMenuStart(id , menu , item)
{
	if( item < 0 ) 
		return PLUGIN_CONTINUE;	
	
	new access, callback; 
	
	new actionString[2];		
	menu_item_getinfo(menu,item,access, actionString ,2,_,_, callback);		
	new action = str_to_num(actionString);

	new increment = get_pcvar_num(g_betIncrementPCVar);
	
	switch(action)
	{
		case 1:
		{
			betValues[id] += increment;
			showMenuStart(id)
		}		
		case 2:
		{
			betValues[id] -= increment;
			showMenuStart(id)
		}
		case 3:
		{
			betValues[id] += increment*10;
			showMenuStart(id)
		}
		case 4:
		{
			betValues[id] -= increment*10;
			showMenuStart(id)
		}
		case 5:
		{
			betValues[id] = uj_points_get(id);
			showMenuStart(id)
		}
		case 6:
		{
			if(uj_points_get(id) < get_pcvar_num(g_betMinPCVar))
			{
				showMenuStart(id)
			}
			else
			{
				startGame(id);
				showMenuBlackJack(id);
				motdShowTable(id);
			}
		}
	}
	
	return PLUGIN_HANDLED;
}
card:getRandomCard(deck[N_CARDS][CARD],&count)
{	
	if(!count)
		renewDeck(deck,count);	
	
	new randIndex = random(count);
	new newCard[CARD];
	
	newCard = deck[randIndex];
	
	deck[randIndex] = deck[--count];
	
	return card:newCard;	
}

getPlayerCardsSum(deckPlayer[PER_PLAYER_MAX_CARDS][CARD],deckPlayerCount)
{
	new playerSum = 0;
	
	for(new i=0; i<deckPlayerCount;i++)
		playerSum += deckPlayer[i][VALUE];
	
	return playerSum;
}

getCroupierCardsSum(deckCroupier[PER_PLAYER_MAX_CARDS][CARD],deckCroupierCount)
{
	return getPlayerCardsSum(deckCroupier,deckCroupierCount);
}

giveCroupierCard(deck[N_CARDS][CARD],&deckCount,deckCroupier[PER_PLAYER_MAX_CARDS][CARD],&deckCroupierCount)
{
	deckCroupier[deckCroupierCount++] = getRandomCard(deck,deckCount);
}
givePlayerCard(deck[N_CARDS][CARD],&deckCount,deckPlayer[PER_PLAYER_MAX_CARDS][CARD],&deckPlayerCount)
{
	deckPlayer[deckPlayerCount++] = getRandomCard(deck,deckCount);
}

startGame(id)
{
	uj_points_remove(id, betValues[id]);

	new playerName[32];
	get_user_name(id, playerName, charsmax(playerName));
	uj_logs_log("[uj_game_blackjack] %s has started Blackjack for %i points.", playerName, betValues[id]);
	
	inGame[id] = 1;					
	gameOver[id] = 0;
	
	decksCount[id] = 0;
	decksPlayersCount[id] = 0;
	decksCroupierCount[id] = 0;
	
	renewDeck(decks[id],decksCount[id]);
	
	giveCroupierCard(decks[id],decksCount[id],decksCroupier[id],decksCroupierCount[id]);
	giveCroupierCard(decks[id],decksCount[id],decksCroupier[id],decksCroupierCount[id]);

	givePlayerCard(decks[id],decksCount[id],decksPlayers[id],decksPlayersCount[id]);
	givePlayerCard(decks[id],decksCount[id],decksPlayers[id],decksPlayersCount[id]);
	
	new playerSum   = getPlayerCardsSum(decksPlayers[id],decksPlayersCount[id]);
	new croupierSum = getCroupierCardsSum(decksCroupier[id],decksCroupierCount[id]);
	
	if(playerSum == 22)
		decksPlayers[id][0][VALUE] = 1;
	if(croupierSum == 22)
		decksCroupier[id][0][VALUE] = 1;
		
	gameOver[id] = ( (playerSum == 21) || (croupierSum == 21) );
	
	if(gameOver[id])
		doGameOver(id);
	
}

askCard(id)
{
	givePlayerCard(decks[id],decksCount[id],decksPlayers[id],decksPlayersCount[id]);
	new playerSum  = getPlayerCardsSum(decksPlayers[id],decksPlayersCount[id]);
	
	gameOver[id] = (playerSum >= 21)
	
	if(gameOver[id])
		doGameOver(id);
	
}
stop(id)
{

	new playerSum = getPlayerCardsSum(decksPlayers[id],decksPlayersCount[id]);
	new croupierSum = getCroupierCardsSum(decksCroupier[id],decksCroupierCount[id]);
	
	if(playerSum <= 21)
	{
		while(croupierSum<playerSum)
		{
			giveCroupierCard(decks[id],decksCount[id],decksCroupier[id],decksCroupierCount[id]);
			croupierSum = getCroupierCardsSum(decksCroupier[id],decksCroupierCount[id]);
		}
		
		if( (croupierSum == playerSum) && (croupierSum <= 17) )
		{
			giveCroupierCard(decks[id],decksCount[id],decksCroupier[id],decksCroupierCount[id]);
		}
	}
	
	doGameOver(id);
}
gameResult(id)
{
	new playerSum = getPlayerCardsSum(decksPlayers[id],decksPlayersCount[id]);
	new croupierSum = getCroupierCardsSum(decksCroupier[id],decksCroupierCount[id]);
	
	if( (playerSum == croupierSum) || ( (playerSum> 21) && (croupierSum>21)) )
	{
		return 0;
	}
	else if(playerSum == 21 && (decksPlayersCount[id] == 2) )
	{
		return 2;
	}
	else if (playerSum > croupierSum)
	{
		if(playerSum > 21)
			return -1
		else
			return 1;
	}
	else if (croupierSum > playerSum)
	{
		if(croupierSum > 21)
			return 1;
		else
			return -1;
	}
	
	return 0;	
}
doGameOver(id)
{
	gameOver[id] = 1;
	inGame[id]= 0;
	
	new name[32];
	get_user_name(id,name,31);

	switch (gameResult(id))
	{
		case -1:
		{
			uj_colorchat_print(0,UJ_COLORCHAT_RED,"^4%s^1 lost ^4%i^1 points in Blackjack!",name,betValues[id]);
			uj_logs_log("[uj_game_blackjack] %s lost %i points in Blackjack.")
		}
		case 0:
		{
			uj_colorchat_print(0,UJ_COLORCHAT_RED,"^4%s^1 had a draw in Blackjack!",name);
			uj_points_add(id, betValues[id]);
			uj_logs_log("[uj_game_blackjack] %s drew %i points in Blackjack.")
		}
		case 1:
		{
			uj_colorchat_print(0,UJ_COLORCHAT_RED,"^4%s^1 won ^4%i^1 points in Blackjack!",name,betValues[id]);
			uj_points_add(id, 2*betValues[id]);
			uj_logs_log("[uj_game_blackjack] %s won %i points in Blackjack.")
		}
		case 2:
		{
			uj_colorchat_print(0,UJ_COLORCHAT_RED,"^3[Blackjack!]^1 ^4%s^1 won ^4%i^1 points in Blackjack!",name,betValues[id]*2);
			uj_points_add(id, 3*betValues[id]);
			uj_logs_log("[uj_game_blackjack] %s lost %i points in Blackjack with a Blackjack.")
		}
	}
}
doReset(id)
{
	gameOver[id] = 0;
	inGame[id] = 0;
	betValues[id] = get_pcvar_num(g_betMinPCVar);
}
public client_connect(id)
{
	doReset(id)
}
