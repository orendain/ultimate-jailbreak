#include < amxmodx >
#include < engine >
#include < fakemeta >
#include < hamsandwich >
#include < fun >
#include < dhudmessage >

#define	FL_WATERJUMP	(1<<11)	// player jumping out of water
#define	FL_ONGROUND	(1<<9)	// At rest / on the ground
#define RECORDS 3
enum {

	GOAL = 1,
	ASSIST,
	DISTANCE
}

static const BALL_BOUNCE_GROUND[ ] = "kickball/bounce.wav";
static const g_szBallModel[ ]     = "models/kickball/basketball.mdl";
static const g_szBallName[ ]      = "ball2";

new g_iBall, g_szFile[ 128 ], g_szMapname[ 32 ], g_iButtonsMenu, g_iTrailSprite;
new bool:g_bNeedBall, cSpeed, cDistance;
new Float:g_vOrigin[ 3 ];
//new g_iTravelling[33];
new GoalEnt[5];
new ballowner;
new fire;
new smoke;
new g_oldOrigin[33][3];
new bool:g_bOriginSet[33];
new g_OwnerOrigin[3];
new Float:modFeet = 35.00;
new g_Owner;
//new ballholder;
new distorig[2][3]; //distance recorder
new MadeRecord[32][RECORDS+1];
new TopPlayer[2][RECORDS+1];
new TopPlayerName[RECORDS+1][33];

new iassist[4];
new assist[16];

// Travelling
//new user_foul_count[33];
new g_msgScreenFade;
//new bool:is_user_foul[33]

new SCORED_GOAL[] = "kickball/distress.wav"


public plugin_init( ) {
	register_plugin( "NBA Jam", "0.3", "mabaclu" );
	
	for (new stupidid; stupidid <= get_maxplayers(); stupidid++)
		//g_iTravelling[stupidid] = -1;
	
	/* Cvars */
	cSpeed = register_cvar("bball_speed", "200.0");
	cDistance = register_cvar("bball_distance", "850");
	
	register_cvar("sbhopper_version", "1.2", FCVAR_SERVER)
	
	register_cvar("bh_enabled", "1")
	register_cvar("bh_autojump", "1")
	
	/* Register Forward */
	register_forward(FM_PlayerPreThink, "PlayerPreThink", 0)
	
	/* Current Weapon */
	register_event("CurWeapon", "CurWeapon", "be");
	
	RegisterHam( Ham_ObjectCaps, "player", "FwdHamObjectCaps", 1 );
	register_logevent( "EventRoundStart", 2, "1=Round_Start" );
	
	register_think( g_szBallName, "FwdThinkBall" );
	register_touch( g_szBallName, "player", "FwdTouchPlayer" );
	register_touch( "player", "player", "FwdPlayerTouchingPlayer");
	register_touch(g_szBallName, "soccerjam_goalnet",	"touchNet");
	
	new const szEntity[ ][ ] = {
		"worldspawn", "func_wall", "func_door",  "func_door_rotating",
		"func_wall_toggle", "func_breakable", "func_pushable", "func_train",
		"func_illusionary", "func_button", "func_rot_button", "func_rotating"
	}
	
	for( new i; i < sizeof szEntity; i++ )
		register_touch( g_szBallName, szEntity[ i ], "FwdTouchWorld" );
	
	g_iButtonsMenu = menu_create( "\w[AG] BasketballBall Menu", "HandleButtonsMenu" );
	
	menu_additem( g_iButtonsMenu, "\wCreate Ball", "1" );
	menu_additem( g_iButtonsMenu, "\wLoad Ball", "2" );
	menu_additem( g_iButtonsMenu, "\rDelete Ball", "3" );
	menu_additem( g_iButtonsMenu, "\ySave", "4" );
	
	register_clcmd( "say /bball", "CmdButtonsMenu", ADMIN_KICK );
	register_clcmd( "say /reset", "UpdateBall" );
	
	fire = engfunc( EngFunc_PrecacheModel,"sprites/shockwave.spr")
	smoke = engfunc( EngFunc_PrecacheModel,"sprites/steam1.spr")
	
	g_msgScreenFade = get_user_msgid("ScreenFade")
}    

public Paralize(id)
{
	set_user_godmode(id, 1) 
	
	//play_wav(id, SoundDirect[26]);
	
	// add a blue tint to their screen
	message_begin(MSG_ONE, g_msgScreenFade, _, id);
	write_short(~0);	// duration
	write_short(~0);	// hold time
	write_short(0x0004);	// flags: FFADE_STAYOUT
	write_byte(0);		// red
	write_byte(200);		// green
	write_byte(50);	// blue
	write_byte(100);	// alpha
	message_end();
	
	// prevent from jumping
	if (pev(id, pev_flags) & FL_ONGROUND)
		set_pev(id, pev_gravity, 999999.9) // set really high
	else
		set_pev(id, pev_gravity, 0.000001) // no gravity	
}

public touchNet(ball, goalpost)
{
	new aname[64]
	new Float:netOrig[3]
	new netOrig2[3]
	
	entity_get_vector(ball, EV_VEC_origin,netOrig)
	new l
	for(l=0;l<3;l++)
		netOrig2[l] = floatround(netOrig[l])
	flameWave(netOrig2)
	get_user_name(ballowner,aname,63)
	new frags = get_user_frags(ballowner)
	entity_set_float(ballowner, EV_FL_frags, float(frags + 10))
	
	play_wav(0, SCORED_GOAL)
	//server_cmd("sv_restart 4")
	moveBall(0);
	set_task(5.0, "moveBall", 1);
	new team = get_user_team(ballowner)
	
	
	new assisters[4] = { 0, 0, 0, 0 }
	new iassisters = 0
	new ilastplayer = iassist[ team ]
	// We just need the last player to kick the ball
	// 0 means it has passed 15 at least once
	if ( ilastplayer == 0 )
		ilastplayer = 15
	else
		ilastplayer--
	if ( assist[ ilastplayer ] != 0 ) {
		new i, x, bool:canadd, playerid
		for(i=0; i<16; i++) {
			// Stop if we've already found 4 assisters
			if ( iassisters == 3 )
				break
			playerid = assist[ i ]
			// Skip if player is invalid
			if ( playerid == 0 )
				continue
			// Skip if kicker is counted as an assister
			if ( playerid == assist[ ilastplayer ] )
				continue
			canadd = true
			// Loop through each assister value
			for(x=0; x<3; x++)
				// make sure we can add them
				if ( playerid == assisters[ x ] ) {
					canadd = false
					break
				}
				// Skip if they've already been added
			if ( canadd == false )
				continue
			// They didn't kick the ball last, and they haven't been added, add them
			assisters[ iassisters++ ] = playerid
		}
		// This gives each person an assist, xp, and prints that out to them
		new c, pass
		for(c=0; c<iassisters; c++) {
			pass = assisters[ c ]
			Event_Record(pass, ASSIST, -1)
		}
	}
	iassist[ 0 ] = 0
	
	for(l=0; l<3; l++)
		distorig[1][l] = floatround(netOrig[l])
	new distshot = (get_distance(distorig[0],distorig[1])/12)

	client_print(0, print_chat, "%s SCORED from %i feet away!", aname,distshot)

	if(distshot > MadeRecord[ballowner][DISTANCE])
		Event_Record(ballowner, DISTANCE, distshot)// record distance, and make that distance exp

	Event_Record(ballowner, GOAL, -1)	//zero xp for goal cause distance is what gives it.
	
}

Event_Record(id, recordtype, amt) {
	if(amt == -1)
		MadeRecord[id][recordtype]++
	else
		MadeRecord[id][recordtype] = amt

	new playerRecord = MadeRecord[id][recordtype]
	if(playerRecord > TopPlayer[1][recordtype])
	{
		TopPlayer[0][recordtype] = id
		TopPlayer[1][recordtype] = playerRecord
		new name[33+1]
		get_user_name(id,name,33)
		format(TopPlayerName[recordtype],33,"%s",name)
	}
	//give points
}


public Goal()
{
    new name[32], fdistance
    new Float:fOrigin[3]
    entity_get_vector(g_iBall, EV_VEC_origin,fOrigin)
    new Origin[3]
    
    FVecIVec(fOrigin, Origin)
    
    get_user_name(g_Owner, name,31)
    fdistance = get_distance(Origin, g_OwnerOrigin)
    set_dhudmessage(0, 255, 0, -1.0, 0.54, 0, 6.0, 4.0)
    
    if(g_Owner != 0)
    {
	show_dhudmessage(0, "SWOOSH! %s scored a basket^nfrom %d feet away!", name, floatround( fdistance/modFeet ))
	client_print(0, print_chat, "%s scored a basket from %d feet away!", name, floatround( fdistance/modFeet ))
        //remove_beam(g_Owner)
        //remove_sprite(g_Owner)
        
    }
	
    
    //g_bScored = true
    
    //MoveBall(0)
    
    //set_task(5.0, "MoveBall", 1)
    client_print(0, print_chat,  "The ball will respawn in 5 seconds.")
    
    message_begin(MSG_ONE, g_msgScreenFade, _, g_Owner);
    write_short(~0);	// duration
    write_short(~0);	// hold time
    write_short(0x0004);	// flags: FFADE_STAYOUT
    write_byte(0);		// red
    write_byte(200);		// green
    write_byte(50);	// blue
    write_byte(100);	// alpha
    message_end();
    
    
}


public pfn_keyvalue(entid) {
	
	new classname[32], key[32], value[32]
	copy_keyvalue(classname, 31, key, 31, value, 31)
	
	new team;
	
	if(equal(key, "classname") && equal(value, "soccerjam_goalnet"))
		DispatchKeyValue("classname", "func_wall")
	
	if(equal(classname, "func_wall"))
	{
		if(equal(key, "team"))
		{
			team = str_to_num(value)
			if(team == 1 || team == 2) {
				GoalEnt[team] = entid
				set_task(1.0, "FinalizeGoalNet", team)
			}
		}
	}
}

public FinalizeGoalNet(team)
{
	new goalnet = GoalEnt[team]
	entity_set_string(goalnet,EV_SZ_classname,"soccerjam_goalnet")
	entity_set_int(goalnet, EV_INT_team, team)
	set_entity_visibility(goalnet, 0)
}

/*public client_PreThink(id) {
new flags = entity_get_int(id, EV_INT_flags)
if (!get_cvar_num("bh_enabled"))
	return PLUGIN_CONTINUE

entity_set_float(id, EV_FL_fuser2, 0.0)		// Disable slow down after jumping

if (!get_cvar_num("bh_autojump"))
	return PLUGIN_CONTINUE

// Code from CBasePlayer::Jump (player.cpp)		Make a player jump automatically
if (entity_get_int(id, EV_INT_button) & 2) {	// If holding jump
	new flags = entity_get_int(id, EV_INT_flags)
	
	if( is_valid_ent( g_iBall ) )
	{		
		if (flags & FL_WATERJUMP)
			return PLUGIN_CONTINUE
		if ( entity_get_int(id, EV_INT_waterlevel) >= 2 )
			return PLUGIN_CONTINUE
		if ( !(flags & FL_ONGROUND) )
			return PLUGIN_CONTINUE
		
		if( is_valid_ent( g_iBall ) )
		{
			static iOwner; iOwner = pev( g_iBall, pev_iuser1 );
			
			new Float:velocity[3]
			entity_get_vector(id, EV_VEC_velocity, velocity)
			velocity[2] += 250.0
			entity_set_vector(id, EV_VEC_velocity, velocity)
			entity_set_int(id, EV_INT_gaitsequence, 6)	// Play the Jump Animation
			
			
			g_iTravelling[id]++;
			if( is_valid_ent( g_iBall ) ) {
				if(iOwner != id)
				{
					g_iTravelling[id] = 0;
				}
				else
				{
					get_user_origin(id, g_oldOrigin[id]);
				}
			}
			if (g_iTravelling[id] >= 1)
				client_print(id, print_chat, "%i", g_iTravelling[id]);
			if (g_iTravelling[id] >= 3)
			{
				client_print(id, print_chat, "Travelling!!!");
				is_user_foul[id] = true;
				user_foul_count[id] = 2;
				AvisoTravelling(id)	
				Paralize(id)
			}
			g_bOriginSet[id] = true;
		}
	}
}
else
{
	new flags = entity_get_int(id, EV_INT_flags)
	
	if (flags & FL_WATERJUMP)
		return PLUGIN_CONTINUE
	if ( entity_get_int(id, EV_INT_waterlevel) >= 2 )
		return PLUGIN_CONTINUE
	if ( !(flags & FL_ONGROUND) )
		return PLUGIN_CONTINUE
	
	if( is_valid_ent( g_iBall ) )
	{
		static iOwner; iOwner = pev( g_iBall, pev_iuser1 );
		ballowner = iOwner;
		if (iOwner == id)
		{
			if ( flags & FL_ONGROUND )
			{
				if (!task_exists(669532))
				{
					set_task(0.1, "checkMovement", 669532)
				}
			}
		}
	}
	return PLUGIN_CONTINUE
}*/

public PlayerPreThink(id) {
	if(!is_user_alive(id))
		return PLUGIN_CONTINUE;
	
	/*if( is_valid_ent( g_iBall ) ) {
	static iOwner; iOwner = pev( g_iBall, pev_iuser1 );
	//        if( iOwner != id )
	//            set_user_maxspeed(id, 230.0)*/
	
	new flags = entity_get_int(id, EV_INT_flags)
	if (!get_cvar_num("bh_enabled"))
		return PLUGIN_CONTINUE
	
	entity_set_float(id, EV_FL_fuser2, 0.0)		// Disable slow down after jumping
	
	if (!get_cvar_num("bh_autojump"))
		return PLUGIN_CONTINUE
	
	// Code from CBasePlayer::Jump (player.cpp)		Make a player jump automatically
	if (entity_get_int(id, EV_INT_button) & 2)
	{	// If holding jump
		new flags = entity_get_int(id, EV_INT_flags)
		
		if( is_valid_ent( g_iBall ) )
		{		
			if (flags & FL_WATERJUMP)
				return PLUGIN_CONTINUE
			if ( entity_get_int(id, EV_INT_waterlevel) >= 2 )
				return PLUGIN_CONTINUE
			if ( !(flags & FL_ONGROUND) )
				return PLUGIN_CONTINUE
			
			/*if( is_valid_ent( g_iBall ) )
			{
				static iOwner; iOwner = pev( g_iBall, pev_iuser1 );
				
				/*new Float:velocity[3]
				entity_get_vector(id, EV_VEC_velocity, velocity)
				velocity[2] += 250.0
				entity_set_vector(id, EV_VEC_velocity, velocity)
				entity_set_int(id, EV_INT_gaitsequence, 6)	// Play the Jump Animation
				
				
				g_iTravelling[id]++;
				if( is_valid_ent( g_iBall ) ) {
					if(iOwner != id)
					{
						g_iTravelling[id] = 0;
					}
					else
					{
						get_user_origin(id, g_oldOrigin[id]);
					}
				}
				if (g_iTravelling[id] >= 1)
					client_print(id, print_chat, "%i", g_iTravelling[id]);
				if (g_iTravelling[id] >= 3)
				{
					client_print(id, print_chat, "Travelling!!!");
					is_user_foul[id] = true;
					user_foul_count[id] = 2;
					AvisoTravelling(id)	
					Paralize(id)
				}
				g_bOriginSet[id] = true;
			}*/
		}
	}
	else
	{
		new flags = entity_get_int(id, EV_INT_flags)
		
		if (flags & FL_WATERJUMP)
			return PLUGIN_CONTINUE
		if ( entity_get_int(id, EV_INT_waterlevel) >= 2 )
			return PLUGIN_CONTINUE
		if ( !(flags & FL_ONGROUND) )
			return PLUGIN_CONTINUE
		
		if( is_valid_ent( g_iBall ) )
		{
			static iOwner; iOwner = pev( g_iBall, pev_iuser1 );
			ballowner = iOwner;
			if (iOwner == id)
			{
				if ( flags & FL_ONGROUND )
				{
					if (!task_exists(669532))
					{
						set_task(0.1, "checkMovement", 669532)
					}
				}
			}
		}
	}
	
	return PLUGIN_HANDLED;
}
public CurWeapon(id) {
	if(!is_user_alive(id))
		return PLUGIN_CONTINUE;
	if( is_valid_ent( g_iBall ) ) {
		static iOwner; iOwner = pev( g_iBall, pev_iuser1 );
		if( iOwner == id )
			set_user_maxspeed(id, get_pcvar_float(cSpeed))
	}    
	return PLUGIN_HANDLED;
}
public UpdateBall( id ) {
	if( !id || get_user_flags( id ) & ADMIN_KICK ) {
		if( is_valid_ent( g_iBall ) ) {
			entity_set_vector( g_iBall, EV_VEC_velocity, Float:{ 0.0, 0.0, 0.0 } ); // To be sure ?
			entity_set_origin( g_iBall, g_vOrigin );
			
			entity_set_int( g_iBall, EV_INT_movetype, MOVETYPE_BOUNCE );
			entity_set_size( g_iBall, Float:{ -15.0, -15.0, 0.0 }, Float:{ 15.0, 15.0, 12.0 } );
			entity_set_int( g_iBall, EV_INT_iuser1, 0 );
		}
	}
	
	return PLUGIN_HANDLED;
}

public plugin_precache( ) {
	precache_model( g_szBallModel );
	precache_sound( BALL_BOUNCE_GROUND );
	
	g_iTrailSprite = precache_model( "sprites/laserbeam.spr" );
	
	get_mapname( g_szMapname, 31 );
	strtolower( g_szMapname );
	
	// File
	new szDatadir[ 64 ];
	get_localinfo( "amxx_datadir", szDatadir, charsmax( szDatadir ) );
	
	formatex( szDatadir, charsmax( szDatadir ), "%s", szDatadir );
	
	if( !dir_exists( szDatadir ) )
		mkdir( szDatadir );
	
	formatex( g_szFile, charsmax( g_szFile ), "%s/ball.ini", szDatadir );
	
	if( !file_exists( g_szFile ) ) {
		write_file( g_szFile, "// Ball Spawn Editor", -1 );
		write_file( g_szFile, " ", -1 );
		
		return; // We dont need to load file
	}
	
	new szData[ 256 ], szMap[ 32 ], szOrigin[ 3 ][ 16 ];
	new iFile = fopen( g_szFile, "rt" );
	
	while( !feof( iFile ) ) {
		fgets( iFile, szData, charsmax( szData ) );
		
		if( !szData[ 0 ] || szData[ 0 ] == ';' || szData[ 0 ] == ' ' || ( szData[ 0 ] == '/' && szData[ 1 ] == '/' ) )
			continue;
		
		parse( szData, szMap, 31, szOrigin[ 0 ], 15, szOrigin[ 1 ], 15, szOrigin[ 2 ], 15 );
		
		if( equal( szMap, g_szMapname ) ) {
			new Float:vOrigin[ 3 ];
			
			vOrigin[ 0 ] = str_to_float( szOrigin[ 0 ] );
			vOrigin[ 1 ] = str_to_float( szOrigin[ 1 ] );
			vOrigin[ 2 ] = str_to_float( szOrigin[ 2 ] );
			
			CreateBall( 0, vOrigin );
			
			g_vOrigin = vOrigin;
			
			break;
		}
	}
	
	fclose( iFile );
}

public CmdButtonsMenu( id ) {
	if( get_user_flags( id ) & ADMIN_RCON )
		menu_display( id, g_iButtonsMenu, 0 );
	
	return PLUGIN_HANDLED;
}

public HandleButtonsMenu( id, iMenu, iItem ) {
	if( iItem == MENU_EXIT )
		return PLUGIN_HANDLED;
	
	new szKey[ 2 ], _Access, _Callback;
	// Plugin made by mabaclu - mabaclu@gmail.com - www.proportuguesegaming.com
	menu_item_getinfo( iMenu, iItem, _Access, szKey, 1, "", 0, _Callback );
	
	new iKey = str_to_num( szKey );
	
	switch( iKey ) {
		case 1:    {
			if( pev_valid( g_iBall ) )
				return PLUGIN_CONTINUE;
			
			CreateBall( id );
		}
		case 2: {
			if( is_valid_ent( g_iBall ) ) {
				entity_set_vector( g_iBall, EV_VEC_velocity, Float:{ 0.0, 0.0, 0.0 } ); // To be sure ?
				entity_set_origin( g_iBall, g_vOrigin );
				
				entity_set_int( g_iBall, EV_INT_movetype, MOVETYPE_BOUNCE );
				entity_set_size( g_iBall, Float:{ -15.0, -15.0, 0.0 }, Float:{ 15.0, 15.0, 12.0 } );
				entity_set_int( g_iBall, EV_INT_iuser1, 0 );
				client_print( id, print_chat, "[AG] Successfully loaded a basketball!" );
			}
		}
		case 3: {
			new iEntity;
			
			while( ( iEntity = find_ent_by_class( iEntity, g_szBallName ) ) > 0 )
				remove_entity( iEntity );
			client_print( id, print_chat, "[AG] Successfully removed the basketball!" );
		}
		case 4: {
			new iBall, iEntity, Float:vOrigin[ 3 ];
			
			while( ( iEntity = find_ent_by_class( iEntity, g_szBallName ) ) > 0 )
				iBall = iEntity;
			
			if( iBall > 0 )
				entity_get_vector( iBall, EV_VEC_origin, vOrigin );
			else
				return PLUGIN_HANDLED;
			
			new bool:bFound, iPos, szData[ 32 ], iFile = fopen( g_szFile, "r+" );
			
			if( !iFile )
				return PLUGIN_HANDLED;
			
			while( !feof( iFile ) ) {
				fgets( iFile, szData, 31 );
				parse( szData, szData, 31 );
				
				iPos++;
				
				if( equal( szData, g_szMapname ) ) {
					bFound = true;
					
					new szString[ 256 ];
					formatex( szString, 255, "%s %f %f %f", g_szMapname, vOrigin[ 0 ], vOrigin[ 1 ], vOrigin[ 2 ] );
					
					write_file( g_szFile, szString, iPos - 1 );
					
					break;
				}
			}
			
			if( !bFound )
				fprintf( iFile, "%s %f %f %f^n", g_szMapname, vOrigin[ 0 ], vOrigin[ 1 ], vOrigin[ 2 ] );
			
			fclose( iFile );
			
			client_print( id, print_chat, "[AG] Successfully saved the basketball!" );
		}
		default: return PLUGIN_HANDLED;
	}
	
	menu_display( id, g_iButtonsMenu, 0 );
	
	return PLUGIN_HANDLED;
}

public EventRoundStart( ) {
	if( !g_bNeedBall )
		return;
	
	for (new i; i <= get_maxplayers(); i++)
	{
		set_user_godmode(i, 1)
	}
	
	if( !is_valid_ent( g_iBall ) )
		CreateBall( 0, g_vOrigin );
	else {
		entity_set_vector( g_iBall, EV_VEC_velocity, Float:{ 0.0, 0.0, 0.0 } ); // To be sure ?
		entity_set_origin( g_iBall, g_vOrigin );
		
		entity_set_int( g_iBall, EV_INT_solid, SOLID_BBOX );
		entity_set_int( g_iBall, EV_INT_movetype, MOVETYPE_BOUNCE );
		entity_set_size( g_iBall, Float:{ -15.0, -15.0, 0.0 }, Float:{ 15.0, 15.0, 12.0 } );
		entity_set_int( g_iBall, EV_INT_iuser1, 0 );
	}
}

public FwdHamObjectCaps( id ) {
	if( pev_valid( g_iBall ) && is_user_alive( id ) ) {
		static iOwner; iOwner = pev( g_iBall, pev_iuser1 );
		
		if( iOwner == id )
			KickBall( id );
	}
}

// BALL BRAIN :)
////////////////////////////////////////////////////////////
public FwdThinkBall( iEntity ) {
	if( !is_valid_ent( g_iBall ) )
		return PLUGIN_HANDLED;
	
	entity_set_float( iEntity, EV_FL_nextthink, halflife_time( ) + 0.01 ); // o original dizia 0.05
	
	static Float:vOrigin[ 3 ], Float:vBallVelocity[ 3 ];
	entity_get_vector( iEntity, EV_VEC_origin, vOrigin );
	entity_get_vector( iEntity, EV_VEC_velocity, vBallVelocity );
	
	static iOwner; iOwner = pev( iEntity, pev_iuser1 );
	static iSolid; iSolid = pev( iEntity, pev_solid );
	
	// Trail --- >
	static Float:flGametime, Float:flLastThink;
	flGametime = get_gametime( );
	
	if( flLastThink < flGametime ) {
		if( floatround( vector_length( vBallVelocity ) ) > 10 ) {
			message_begin( MSG_BROADCAST, SVC_TEMPENTITY );
			write_byte( TE_KILLBEAM );
			write_short( g_iBall );
			message_end( );
			
			message_begin( MSG_BROADCAST, SVC_TEMPENTITY );
			write_byte( TE_BEAMFOLLOW );
			write_short( g_iBall );
			write_short( g_iTrailSprite );
			write_byte( 10 );
			write_byte( 10 );
			write_byte( 255 ); //r
			write_byte( 106 ); //g
			write_byte( 0 ); //b
			write_byte( 200 );
			message_end( );
		}
		
		flLastThink = flGametime + 3.0;
	}
	// Trail --- <
	
	if( iOwner > 0 ) {
		static Float:vOwnerOrigin[ 3 ];
		entity_get_vector( iOwner, EV_VEC_origin, vOwnerOrigin );
		
		static const Float:vVelocity[ 3 ] = { 1.0, 1.0, 0.0 };
		
		if( !is_user_alive( iOwner ) ) {
			entity_set_int( iEntity, EV_INT_iuser1, 0 );
			
			vOwnerOrigin[ 2 ] += 5.0;
			
			entity_set_origin( iEntity, vOwnerOrigin );
			entity_set_vector( iEntity, EV_VEC_velocity, vVelocity );
			
			return PLUGIN_CONTINUE;
		}
		
		if( iSolid != SOLID_NOT )
			set_pev( iEntity, pev_solid, SOLID_NOT );
		
		static Float:vAngles[ 3 ], Float:vReturn[ 3 ];
		entity_get_vector( iOwner, EV_VEC_v_angle, vAngles );
		
		vReturn[ 0 ] = ( floatcos( vAngles[ 1 ], degrees ) * 55.0 ) + vOwnerOrigin[ 0 ];
		vReturn[ 1 ] = ( floatsin( vAngles[ 1 ], degrees ) * 55.0 ) + vOwnerOrigin[ 1 ];
		vReturn[ 2 ] = vOwnerOrigin[ 2 ];
		vReturn[ 2 ] -= ( entity_get_int( iOwner, EV_INT_flags ) & FL_DUCKING ) ? 10 : 30;
		
		entity_set_vector( iEntity, EV_VEC_velocity, vVelocity );
		entity_set_origin( iEntity, vReturn );
		} else {
		if( iSolid != SOLID_BBOX )
			set_pev( iEntity, pev_solid, SOLID_BBOX );
		
		static Float:flLastVerticalOrigin;
		
		if( vBallVelocity[ 2 ] == 0.0 ) {
			static iCounts;
			
			if( flLastVerticalOrigin > vOrigin[ 2 ] ) {
				iCounts++;
				
				if( iCounts > 10 ) {
					iCounts = 0;
					
					UpdateBall( 0 );
				}
				} else {
				iCounts = 0;
				
				if( PointContents( vOrigin ) != CONTENTS_EMPTY )
					UpdateBall( 0 );
			}
			
			flLastVerticalOrigin = vOrigin[ 2 ];
		}
	}
	
	return PLUGIN_CONTINUE;
}

KickBall( id ) {
	static iOwner; iOwner = pev( g_iBall, pev_iuser1 );
	if (iOwner == id)
	{
		set_user_maxspeed(id, 250.0)
		static Float:vOrigin[ 3 ];
		entity_get_vector( g_iBall, EV_VEC_origin, vOrigin );
		
		if( PointContents( vOrigin ) != CONTENTS_EMPTY )
			return PLUGIN_HANDLED;
		
		new Float:vVelocity[ 3 ];
		velocity_by_aim( id, get_pcvar_num(cDistance), vVelocity );
		
		set_pev( g_iBall, pev_solid, SOLID_BBOX );
		entity_set_size( g_iBall, Float:{ -15.0, -15.0, 0.0 }, Float:{ 15.0, 15.0, 12.0 } );
		entity_set_int( g_iBall, EV_INT_iuser1, 0 );
		entity_set_vector( g_iBall, EV_VEC_velocity, vVelocity );
	}
	
	//g_iTravelling[id] = 0;
	
	ballowner = id;
	
	return PLUGIN_CONTINUE;
}

// BALL TOUCHES
////////////////////////////////////////////////////////////
public FwdTouchPlayer( Ball, id ) {
	if( is_user_bot( id ) )
		return PLUGIN_CONTINUE;
	
	static iOwner; iOwner = pev( Ball, pev_iuser1 );
	
	if( iOwner == 0 ) {
		//g_iTravelling[id]--;
		entity_set_int( Ball, EV_INT_iuser1, id );
		set_user_maxspeed(id, get_pcvar_float(cSpeed))
		if (ballowner == id)
		{
			new neworigin[3];
			//new distance;
			get_user_origin(id, neworigin);
			get_distance(g_oldOrigin[id], neworigin);

		}
		ballowner = id;
		get_user_origin(id, g_oldOrigin[id]);
	}
	
	new flags = entity_get_int(id, EV_INT_flags)
	
	if( is_valid_ent( g_iBall ) )
	{
		if (flags & FL_WATERJUMP)
			return PLUGIN_CONTINUE
		if ( entity_get_int(id, EV_INT_waterlevel) >= 2 )
			return PLUGIN_CONTINUE
		
		if( is_valid_ent( g_iBall ) )
		{
			static iOwner; iOwner = pev( g_iBall, pev_iuser1 );
			
			new Float:velocity[3]
			entity_get_vector(id, EV_VEC_velocity, velocity)
			velocity[2] += 250.0
			entity_set_vector(id, EV_VEC_velocity, velocity)
			entity_set_int(id, EV_INT_gaitsequence, 6)	// Play the Jump Animation
			
			
			//g_iTravelling[id]++;
			if( is_valid_ent( g_iBall ) ) {
				if(iOwner != id)
				{
					//g_iTravelling[id] = 0;
				}
				else
				{
					get_user_origin(id, g_oldOrigin[id]);
				}
			}

			g_bOriginSet[id] = true;
		}
	}
	
	return PLUGIN_CONTINUE;
}

public FwdTouchWorld( Ball, World ) {
	static Float:vVelocity[ 3 ];
	entity_get_vector( Ball, EV_VEC_velocity, vVelocity );
	
	if( floatround( vector_length( vVelocity ) ) > 10 ) {
		vVelocity[ 0 ] *= 0.85;
		vVelocity[ 1 ] *= 0.85;
		vVelocity[ 2 ] *= 0.85;
		
		entity_set_vector( Ball, EV_VEC_velocity, vVelocity );
		
		emit_sound( Ball, CHAN_ITEM, BALL_BOUNCE_GROUND, 1.0, ATTN_NORM, 0, PITCH_NORM );
	}
	
	return PLUGIN_CONTINUE;
}


// ENTITIES CREATING
////////////////////////////////////////////////////////////
CreateBall( id, Float:vOrigin[ 3 ] = { 0.0, 0.0, 0.0 } ) {
	if( !id && vOrigin[ 0 ] == 0.0 && vOrigin[ 1 ] == 0.0 && vOrigin[ 2 ] == 0.0 )
		return 0;
	
	g_bNeedBall = true;
	
	g_iBall = create_entity( "info_target" );
	
	if( is_valid_ent( g_iBall ) ) {
		entity_set_string( g_iBall, EV_SZ_classname, g_szBallName );
		entity_set_int( g_iBall, EV_INT_solid, SOLID_BBOX );
		entity_set_int( g_iBall, EV_INT_movetype, MOVETYPE_BOUNCE );
		entity_set_model( g_iBall, g_szBallModel );
		entity_set_size( g_iBall, Float:{ -15.0, -15.0, 0.0 }, Float:{ 15.0, 15.0, 12.0 } );
		
		entity_set_float( g_iBall, EV_FL_framerate, 0.0 );
		entity_set_int( g_iBall, EV_INT_sequence, 0 );
		
		entity_set_float( g_iBall, EV_FL_nextthink, get_gametime( ) + 0.01 ); //original value: 0.05
		
		client_print( id, print_chat, "[AG] Successfully created a basketball!" );
		
		if( id > 0 ) {
			new iOrigin[ 3 ];
			get_user_origin( id, iOrigin, 3 );
			IVecFVec( iOrigin, vOrigin );
			
			vOrigin[ 2 ] += 1.0; //original value: 5.0
			
			entity_set_origin( g_iBall, vOrigin );
		} else
		entity_set_origin( g_iBall, vOrigin );
		
		g_vOrigin = vOrigin;
		
		return g_iBall;
	}
	
	return -1;
}

play_wav(id, wav[])
client_cmd(id,"spk %s",wav)

flameWave(myorig[3]) {
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY, myorig)
	write_byte( 21 )
	write_coord(myorig[0])
	write_coord(myorig[1])
	write_coord(myorig[2] + 16)
	write_coord(myorig[0])
	write_coord(myorig[1])
	write_coord(myorig[2] + 500)
	write_short( fire )
	write_byte( 0 ) // startframe
	write_byte( 0 ) // framerate
	write_byte( 15 ) // life 2
	write_byte( 50 ) // width 16
	write_byte( 10 ) // noise
	write_byte( 255 ) // r
	write_byte( 0 ) // g
	write_byte( 0 ) // b
	write_byte( 255 ) //brightness
	write_byte( 1 / 10 ) // speed
	message_end()
	
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY,myorig)
	write_byte( 21 )
	write_coord(myorig[0])
	write_coord(myorig[1])
	write_coord(myorig[2] + 16)
	write_coord(myorig[0])
	write_coord(myorig[1])
	write_coord(myorig[2] + 500)
	write_short( fire )
	write_byte( 0 ) // startframe
	write_byte( 0 ) // framerate
	write_byte( 10 ) // life 2
	write_byte( 70 ) // width 16
	write_byte( 10 ) // noise
	write_byte( 255 ) // r
	write_byte( 50 ) // g
	write_byte( 0 ) // b
	write_byte( 200 ) //brightness
	write_byte( 1 / 9 ) // speed
	message_end()
	
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY,myorig)
	write_byte( 21 )
	write_coord(myorig[0])
	write_coord(myorig[1])
	write_coord(myorig[2] + 16)
	write_coord(myorig[0])
	write_coord(myorig[1])
	write_coord(myorig[2] + 500)
	write_short( fire )
	write_byte( 0 ) // startframe
	write_byte( 0 ) // framerate
	write_byte( 10 ) // life 2
	write_byte( 90 ) // width 16
	write_byte( 10 ) // noise
	write_byte( 255 ) // r
	write_byte( 100 ) // g
	write_byte( 0 ) // b
	write_byte( 200 ) //brightness
	write_byte( 1 / 8 ) // speed
	message_end()
	
	//Explosion2
	message_begin( MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte( 12 )
	write_coord(myorig[0])
	write_coord(myorig[1])
	write_coord(myorig[2])
	write_byte( 80 ) // byte (scale in 0.1's) 188
	write_byte( 10 ) // byte (framerate)
	message_end()
	
	//TE_Explosion
	message_begin( MSG_BROADCAST, SVC_TEMPENTITY )
	write_byte( 3 )
	write_coord(myorig[0])
	write_coord(myorig[1])
	write_coord(myorig[2])
	write_short( fire )
	write_byte( 65 ) // byte (scale in 0.1's) 188
	write_byte( 10 ) // byte (framerate)
	write_byte( 0 ) // byte flags
	message_end()
	
	//Smoke
	message_begin( MSG_BROADCAST,SVC_TEMPENTITY,myorig)
	write_byte( 5 ) // 5
	write_coord(myorig[0])
	write_coord(myorig[1])
	write_coord(myorig[2])
	write_short( smoke )
	write_byte( 50 )  // 2
	write_byte( 10 )  // 10
	message_end()
	
	return PLUGIN_HANDLED
}

public checkMovement()
{
	new flags = entity_get_int(ballowner, EV_INT_flags)
	
	if (flags & FL_WATERJUMP)
		return
	if ( entity_get_int(ballowner, EV_INT_waterlevel) >= 2 )
		return
	if ( !(flags & FL_ONGROUND) )
		return
	
	new NewOrigin[33][3]
	get_user_origin(ballowner, NewOrigin[ballowner]);
	//new distance = get_distance(g_oldOrigin[ballowner],NewOrigin[ballowner]);
	//client_print(ballowner, print_chat, "distance: %i", distance);
}
moveBall(where, team=0) {
	if(is_valid_ent(g_iBall))
	{
		switch(where)
		{
			case 0:
			{
				new Float:orig[3], x
				for(x=0;x<3;x++)
					orig[x] = -9999.9
				entity_set_origin(g_iBall,orig)
				//ballholder = -1
			}
		}
	}
}
