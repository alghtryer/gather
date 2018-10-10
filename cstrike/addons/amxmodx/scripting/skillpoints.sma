/*
*
*	Thats version edited by Alghtryer <alghtryer.github.io> for GATHER SYSTEM <alghtryer.github.io/gather>
*
*/

#include < amxmodx >
#include < amxmisc >
#include < cstrike >
#include < csx >
#include < hamsandwich >
#include < fvault >
#include < gather >

#define PLUGIN		"Basic SkillPoints Special Edition (FVault)"
#define VERSION		"2.0.2-GS"
#define AUTHOR		"guipatinador"

#define g_VaultSkillPoints	"skillpoints_v2"
#define g_VaultNames		"skillpoints_names"

#define MAX_PLAYERS	32
#define ADMIN		ADMIN_RCON

#define EXPIREDAYS	30
#define MAX_CLASSES	18
#define MAX_LEVELS	18
#define MAX_PONTUATION	10000 // max skillpoints per player

#define IsPlayer(%1)		( 1 <= %1 <= g_iMaxPlayers )

new const CLASSES[ MAX_CLASSES ][ ] = {
	"Silver I",
	"Silver II",
	"Silver III",
	"Silver IV",
	"Silver Elite",
	"Silver Elite Master",
	"Gold Nova I",
	"Gold Nova II",
	"Gold Nova III",
	"Gold Nova Master",
	"Master Guardian I ",
	"Master Guardian II",
	"Master Guardian Elite",
	"Distinguished Master Guardian",
	"Legendary Eagle",
	"Legendary Eagle Master",
	"Supreme Master First Class",
	"The Global Elite"
}

new const LEVELS[ MAX_LEVELS ] = {
	200, // https://pastebin.com/9QYuMzsN
	400,
	600,
	800,
	1000,
	1200, // SILVER
	1600,
	2000,
	2400,
	2800, //GNM
	3300,
	3800,
	4300, // MGE
	5000,
	6000,
	7500,
	10000,
	100000 /* high value (not reachable) */
}

enum _:FvaultData {
	szSteamID[ 35 ],
	szSkillP_Data[ 128 ]
}


new g_iMaxPlayers
new g_szAuthID[ MAX_PLAYERS + 1 ][ 35 ]
new g_szName[ MAX_PLAYERS + 1 ][ 32 ]
new g_iCurrentKills[ MAX_PLAYERS + 1 ]
new g_szMotd[ 1536 ]

new g_iPoints[ MAX_PLAYERS + 1 ]
new g_iLevels[ MAX_PLAYERS + 1 ]
new g_iClasses[ MAX_PLAYERS + 1 ]

new g_iKills[ MAX_PLAYERS + 1 ]
new g_iDeaths[ MAX_PLAYERS + 1 ]
new g_iHeadShots[ MAX_PLAYERS + 1 ]
new g_iKnifeKills[ MAX_PLAYERS + 1 ]
new g_iKnifeDeaths[ MAX_PLAYERS + 1 ]
new g_iGrenadeKills[ MAX_PLAYERS + 1 ]
new g_iGrenadeDeaths[ MAX_PLAYERS + 1 ]
new g_iBombExplosions[ MAX_PLAYERS + 1 ]
new g_iDefusedBombs[ MAX_PLAYERS + 1 ]
new g_iWonRounds[ MAX_PLAYERS + 1 ]


new bool:g_bRoundEnded

new g_iEnableAnnounceOnChat
new g_iHideChangeNickNotification
new g_iEnableSkillPointsCmd
new g_iEnableSkillPointsRestart
new g_iEnableSkillPointsCmdRank
new g_iEnableSkillPointsTop15
new g_iHideCmds
new g_iLostPointsTK
new g_iLostPointsSuicide
new g_iWonPointsKill
new g_iLostPointsDeath
new g_iWonPointsHeadshot
new g_iLostPointsHeadshot
new g_iWonPointsKnife
new g_iLostPointsKnife
new g_iWonPointsGrenade
new g_iLostPointsGrenade
new g_iWonPointsTerrorists
new g_iWonPointsCounterTerrorists
new g_iLostPointsTerrorists
new g_iLostPointsCounterTerrorists
new g_iWonPointsPlanter
new g_iWonPointsPlanterExplode
new g_iWonPointsDefuser
new g_iWonPoints4k
new g_iWonPoints5k
new g_iNegativePoints

new CvarPrefix;
new Prefix[32];
new CvarStyle

public plugin_init( )
{
	register_plugin( PLUGIN, VERSION, AUTHOR )
	
	register_clcmd( "say", "ClCmd_Say" )
	register_clcmd( "say_team", "ClCmd_Say" )
	
	register_concmd("bps_give", "CmdGivePoints", ADMIN, "<target> <skillpoints to give>" )
	register_concmd("bps_take", "CmdTakePoints", ADMIN, "<target> <skillpoints to take>" )
	
	RegisterHam( Ham_Spawn, "player", "FwdPlayerSpawnPost", 1 )
	
	register_message( get_user_msgid( "SayText" ), "MessageSayText" )
	
	register_event( "SendAudio", "TerroristsWin", "a", "2&%!MRAD_terwin" )
	register_event( "SendAudio", "CounterTerroristsWin", "a", "2&%!MRAD_ctwin" )
	
	register_event( "HLTV", "EventNewRound", "a", "1=0", "2=0" )
	register_logevent( "RoundEnd", 2, "1=Round_End" )
	
	g_iMaxPlayers = get_maxplayers( )
	
	CvarPrefix 		= get_cvar_pointer("gs_prefix"); 
	
	get_pcvar_string( CvarPrefix, Prefix, charsmax( Prefix ) );
	
	RegisterCvars( )
	
	register_message(get_user_msgid("SayText"),"handleSayText");
	CvarStyle		= register_cvar( "gs_style", "3" );
}

public plugin_natives( )
{
	register_library( "skillpoints" )
	
	register_native( "skillpoints", "_skillpoints" )
}

public _skillpoints( plugin, params )
{
	if( params != 1 )
	{
		return 0
	}
	
	new id = get_param( 1 )
	if( !id )
	{
		return 0
	}
	
	return g_iPoints[ id ]
}

public RegisterCvars( )
{
	g_iEnableAnnounceOnChat = register_cvar( "bps_announce_on_chat", "1" )
	g_iHideChangeNickNotification = register_cvar( "bps_hide_change_nick_notification", "1" )
	g_iEnableSkillPointsCmd = register_cvar( "bps_skillpoints_cmd", "1" )
	g_iEnableSkillPointsRestart = register_cvar( "bps_skillpoints_cmd_restart", "0" )
	g_iEnableSkillPointsCmdRank = register_cvar( "bps_skillpoints_cmd_rank", "1" )
	g_iEnableSkillPointsTop15 = register_cvar( "bps_skillpoints_cmd_top15", "1" )
	g_iHideCmds = register_cvar( "bps_hide_cmd", "1" )
	g_iLostPointsTK = register_cvar( "bps_lost_points_tk", "5" )
	g_iLostPointsSuicide = register_cvar( "bps_lost_points_suicide", "1" )
	g_iWonPointsKill = register_cvar( "bps_won_points_kill", "1" )
	g_iLostPointsDeath = register_cvar( "bps_lost_points_kill", "1" )
	g_iWonPointsHeadshot = register_cvar( "bps_won_points_headshot", "2" )
	g_iLostPointsHeadshot = register_cvar( "bps_lost_points_headshot", "2" )
	g_iWonPointsKnife = register_cvar( "bps_won_points_knife", "3" )
	g_iLostPointsKnife = register_cvar( "bps_lost_points_knife", "3" )
	g_iWonPointsGrenade = register_cvar( "bps_won_points_grenade", "3" )
	g_iLostPointsGrenade = register_cvar( "bps_lost_points_grenade", "3" )
	g_iWonPointsTerrorists = register_cvar( "bps_won_points_ts", "1" )
	g_iWonPointsCounterTerrorists = register_cvar( "bps_won_points_cts", "1" )
	g_iLostPointsTerrorists = register_cvar( "bps_lost_points_ts", "1" )
	g_iLostPointsCounterTerrorists = register_cvar( "bps_lost_points_cts", "1" )
	g_iWonPointsPlanter = register_cvar( "bps_won_points_planter", "1" )
	g_iWonPointsPlanterExplode = register_cvar( "bps_won_points_planter_explode", "2" ) 
	g_iWonPointsDefuser = register_cvar( "bps_won_points_defuser", "3" )
	g_iWonPoints4k = register_cvar( "bps_won_points_4k", "4" )
	g_iWonPoints5k = register_cvar( "bps_won_points_5k", "5" )
	g_iNegativePoints = register_cvar( "bps_negative_points", "0" )
	
	
	fvault_prune( g_VaultSkillPoints, _, get_systime( ) - ( 86400 * EXPIREDAYS ) )
	
	MakeTop15( )
}

public client_authorized( id )
{
	get_user_authid( id , g_szAuthID[ id ], charsmax( g_szAuthID[ ] ) )
	get_user_info( id, "name", g_szName[ id ], charsmax( g_szName[ ] ) )
	
	fvault_set_data( g_VaultNames, g_szAuthID[ id ], g_szName[ id ] )
	
	g_iPoints[ id ] = 0
	g_iLevels[ id ] = 0
	g_iClasses[ id ] = 0
	
	g_iKills[ id ] = 0
	g_iDeaths[ id ] = 0
	g_iHeadShots[ id ] = 0
	g_iKnifeKills[ id ] = 0
	g_iKnifeDeaths[ id ] = 0
	g_iGrenadeKills[ id ] = 0
	g_iGrenadeDeaths[ id ] = 0
	g_iBombExplosions[ id ] = 0
	g_iDefusedBombs[ id ] = 0
	g_iWonRounds[ id ] = 0
	
	g_iCurrentKills[ id ] = 0
	
	LoadPoints( id )
}

public client_infochanged( id )
{
	if( is_user_connected( id ) )
	{
		new szNewName[ 32 ]
		get_user_info( id, "name", szNewName, charsmax( szNewName ) ) 
		
		new iLen = strlen( szNewName )
		
		new iPos = iLen - 1
		
		if( szNewName[ iPos ] == '>' )
		{    
			new i
			for( i = 1; i < 7; i++ )
			{    
				if( szNewName[ iPos - i ] == '<' )
				{    
					iLen = iPos - i
					szNewName[ iLen ] = EOS
					break
				}
			}
		}
		
		trim( szNewName )
		
		if( !equal( g_szName[ id ], szNewName ) )   
		{     
			copy( g_szName[ id ], charsmax( g_szName[ ] ), szNewName )
			
			fvault_set_data( g_VaultNames, g_szAuthID[ id ], g_szName[ id ] )
		}	
	}
}

public client_disconnect( id )
{
	if( task_exists( id ) )
	{
		remove_task( id )
	}
	
	CheckLevelAndSave( id )
}

public ClCmd_Say( id )
{	
	new szCmd[ 12 ]
	read_argv( 1, szCmd, charsmax( szCmd ) )
	
	if( equali( szCmd[ 1 ], "skill" ) )
	{
		GetSkillPoints( id )
	}
	
	else if( equali( szCmd[ 1 ], "restartskill" ) )
	{
		RestartSkillPoints( id )
	}
	
	else if( equali( szCmd[ 1 ], "rankskill" ) )
	{
		SkillRank( id )
	}
	
	else if( equali( szCmd[ 1 ], "topskill" ) )
	{
		TopSkill( id )
	}
}
public client_death( iKiller, iVictim, iWpnIndex, iHitPlace, iTK )
{	
	if( !IsPlayer( iKiller ) || !IsPlayer( iVictim ) || !IsStarted() )
	{
		return PLUGIN_CONTINUE
	}
	
	if( iTK )
	{
		g_iPoints[ iKiller ] -= get_pcvar_num( g_iLostPointsTK )
		
		if( get_pcvar_num( g_iEnableAnnounceOnChat ) && get_pcvar_num( g_iLostPointsTK ) )
		{
			ClientPrintColor( iKiller, "!g%s!n You have lost!t %i!n point%s by killing a teammate", Prefix, get_pcvar_num( g_iLostPointsTK ), get_pcvar_num( g_iLostPointsTK ) > 1 ? "s" : ""  )
		}
		
		return PLUGIN_CONTINUE
	}
	
	if( iKiller == iVictim )
	{
		g_iPoints[ iKiller ] -= get_pcvar_num( g_iLostPointsSuicide )
		
		if( get_pcvar_num( g_iEnableAnnounceOnChat ) && get_pcvar_num( g_iLostPointsSuicide ) )
		{
			ClientPrintColor( iKiller, "!g%s!n You have lost!t %i!n point%s for committing suicide", Prefix, get_pcvar_num( g_iLostPointsSuicide ), get_pcvar_num( g_iLostPointsSuicide ) > 1 ? "s" : ""  )
		}
		
		g_iDeaths[ iKiller ]++
		
		return PLUGIN_CONTINUE
	}
	
	g_iCurrentKills[ iKiller ]++
	g_iKills[ iKiller ]++
	
	g_iDeaths[ iVictim ]++
	
	if( iWpnIndex == CSW_HEGRENADE )
	{
		g_iPoints[ iKiller ] += get_pcvar_num( g_iWonPointsGrenade )
		g_iGrenadeKills[ iKiller]++
		
		if( get_pcvar_num( g_iEnableAnnounceOnChat ) && get_pcvar_num( g_iWonPointsGrenade ) )
		{
			ClientPrintColor( iKiller, "!g%s!n You earned!t %i!n point%s by killing %s with a grenade", Prefix, get_pcvar_num( g_iWonPointsGrenade ), get_pcvar_num( g_iWonPointsGrenade ) > 1 ? "s" : "" ,g_szName[ iVictim ] )
		}
		
		g_iPoints[ iVictim ] -= get_pcvar_num( g_iLostPointsGrenade )
		g_iGrenadeDeaths[ iVictim ]++
		
		if( get_pcvar_num( g_iEnableAnnounceOnChat ) && get_pcvar_num( g_iLostPointsGrenade ) )
		{
			ClientPrintColor( iVictim, "!g%s!n You have lost!t %i!n point%s for dying with a grenade", Prefix, get_pcvar_num( g_iLostPointsGrenade ), get_pcvar_num( g_iLostPointsGrenade ) > 1 ? "s" : "" )
		}
		
		return PLUGIN_CONTINUE
	}
	
	if( iWpnIndex == CSW_KNIFE )
	{
		g_iPoints[ iKiller ] += get_pcvar_num( g_iWonPointsKnife )
		g_iKnifeKills[ iKiller ]++
		
		if( get_pcvar_num( g_iEnableAnnounceOnChat ) && get_pcvar_num( g_iWonPointsKnife ) )
		{
			ClientPrintColor( iKiller, "!g%s!n You earned!t %i!n point%s by killing %s with knife", Prefix, get_pcvar_num( g_iWonPointsKnife ), get_pcvar_num( g_iWonPointsKnife ) > 1 ? "s" : "" ,g_szName[ iVictim ] )
		}
		
		g_iPoints[ iVictim ] -= get_pcvar_num( g_iLostPointsKnife )
		g_iKnifeDeaths[ iVictim ]++
		
		if( get_pcvar_num( g_iEnableAnnounceOnChat ) && get_pcvar_num( g_iLostPointsKnife ) )
		{
			ClientPrintColor( iVictim, "!g%s!n You have lost!t %i!n point%s for dying with knife", Prefix, get_pcvar_num( g_iLostPointsKnife ), get_pcvar_num( g_iLostPointsKnife ) > 1 ? "s" : "" )
		}
		
		return PLUGIN_CONTINUE
	}
	
	if( iHitPlace == HIT_HEAD )
	{
		g_iPoints[ iKiller ] += get_pcvar_num( g_iWonPointsHeadshot )
		g_iHeadShots[ iKiller ]++
		
		if( get_pcvar_num( g_iEnableAnnounceOnChat ) && get_pcvar_num( g_iWonPointsHeadshot ) )
		{
			ClientPrintColor( iKiller, "!g%s!n You earned!t %i!n point%s by killing %s with a headshot", Prefix, get_pcvar_num( g_iWonPointsHeadshot ), get_pcvar_num( g_iWonPointsHeadshot ) > 1 ? "s" : "" ,g_szName[ iVictim ] )
		}
		
		g_iPoints[ iVictim ] -= get_pcvar_num( g_iLostPointsHeadshot )
		
		if( get_pcvar_num( g_iEnableAnnounceOnChat ) && get_pcvar_num( g_iLostPointsHeadshot ) )
		{
			ClientPrintColor( iVictim, "!g%s!n You have lost!t %i!n point%s for dying with a headshot", Prefix, get_pcvar_num( g_iLostPointsHeadshot ), get_pcvar_num( g_iLostPointsHeadshot ) > 1 ? "s" : "" )
		}
		
		return PLUGIN_CONTINUE
	}
	
	g_iPoints[ iKiller ] += get_pcvar_num( g_iWonPointsKill )
	
	if( get_pcvar_num( g_iEnableAnnounceOnChat ) && get_pcvar_num( g_iWonPointsKill ) )
	{
		ClientPrintColor( iKiller, "!g%s!n You earned!t %i!n point%s by killing %s", Prefix, get_pcvar_num( g_iWonPointsKill ), get_pcvar_num( g_iWonPointsKill ) > 1 ? "s" : "", g_szName[ iVictim ] )
	}
	
	g_iPoints[ iVictim ] -= get_pcvar_num( g_iLostPointsDeath )
	
	if( get_pcvar_num( g_iEnableAnnounceOnChat ) && get_pcvar_num( g_iLostPointsDeath ) )
	{
		ClientPrintColor( iVictim, "!g%s!n You have lost!t %i!n point%s for dying", Prefix, get_pcvar_num( g_iLostPointsDeath ), get_pcvar_num( g_iLostPointsDeath ) > 1 ? "s" : "" )
	}
	
	return PLUGIN_CONTINUE	
}

public TerroristsWin( )
{
	if( g_bRoundEnded || !IsStarted() )
	{
		return PLUGIN_CONTINUE
	}
	
	new Players[ MAX_PLAYERS ]
	new iNum
	new i
	
	get_players( Players, iNum, "ch" )
	
	for( --iNum; iNum >= 0; iNum-- )
	{
		i = Players[ iNum ]
		
		switch( cs_get_user_team( i ) )
		{
			case( CS_TEAM_T ):
			{
				if( get_pcvar_num( g_iWonPointsTerrorists ) )
				{
					g_iPoints[ i ] += get_pcvar_num( g_iWonPointsTerrorists )
					g_iWonRounds[ i ]++
					
					if( get_pcvar_num( g_iEnableAnnounceOnChat ) )
					{
						ClientPrintColor( i, "!g%s!n Your team!t (T)!n have won!t %i!n point%s for winning the round", Prefix, get_pcvar_num( g_iWonPointsTerrorists ), get_pcvar_num( g_iWonPointsTerrorists ) > 1 ? "s" : "" )
					}
				}
			}
			
			case( CS_TEAM_CT ):
			{
				if( get_pcvar_num( g_iLostPointsCounterTerrorists ) )
				{
					g_iPoints[ i ] -= get_pcvar_num( g_iLostPointsCounterTerrorists )
					
					if( get_pcvar_num( g_iEnableAnnounceOnChat ) )
					{
						ClientPrintColor( i, "!g%s!n Your team!t (CT)!n have lost!t %i!n point%s for losing the round", Prefix, get_pcvar_num( g_iLostPointsCounterTerrorists ), get_pcvar_num( g_iLostPointsCounterTerrorists ) > 1 ? "s" : "" )
					}
				}
			}
		}
	}
	
	g_bRoundEnded = true
	
	return PLUGIN_CONTINUE
}

public CounterTerroristsWin( )
{
	if( g_bRoundEnded || !IsStarted() )
	{
		return PLUGIN_CONTINUE
	}
	
	new Players[ MAX_PLAYERS ]
	new iNum
	new i
	
	get_players( Players, iNum, "ch" )
	
	for( --iNum; iNum >= 0; iNum-- )
	{
		i = Players[ iNum ]
		
		switch( cs_get_user_team( i ) )
		{
			case( CS_TEAM_T ):
			{
				if( get_pcvar_num( g_iLostPointsTerrorists ) )
				{
					g_iPoints[ i ] -= get_pcvar_num( g_iLostPointsTerrorists )
					
					if( get_pcvar_num( g_iEnableAnnounceOnChat ) )
					{
						ClientPrintColor( i, "!g%s!n Your team!t (T)!n have lost!t %i!n point%s for losing the round", Prefix, get_pcvar_num( g_iLostPointsTerrorists ), get_pcvar_num( g_iLostPointsTerrorists ) > 1 ? "s" : "" )
					}
				}
			}
			
			case( CS_TEAM_CT ):
			{
				if( get_pcvar_num( g_iWonPointsCounterTerrorists ) )
				{
					g_iPoints[ i ] += get_pcvar_num( g_iWonPointsCounterTerrorists )
					g_iWonRounds[ i ]++
					
					if( get_pcvar_num( g_iEnableAnnounceOnChat ) )
					{
						ClientPrintColor( i, "!g%s!n Your team!t (CT)!n have won!t %i!n point%s for winning the round", Prefix, get_pcvar_num( g_iWonPointsCounterTerrorists ), get_pcvar_num( g_iWonPointsCounterTerrorists ) > 1 ? "s" : "" )
					}
				}
			}
		}
	}
	
	g_bRoundEnded = true
	
	return PLUGIN_CONTINUE
}

public bomb_planted( planter )
{

	if(!IsStarted() )
	{
		return PLUGIN_CONTINUE
	}

	if( get_pcvar_num( g_iWonPointsPlanter ) )
	{
		g_iPoints[ planter ] += get_pcvar_num( g_iWonPointsPlanter )
		
		if( get_pcvar_num( g_iEnableAnnounceOnChat ) )
		{
			ClientPrintColor( planter, "!g%s!n You earned!t %i!n point%s for planting the bomb", Prefix, get_pcvar_num( g_iWonPointsPlanter ), get_pcvar_num( g_iWonPointsPlanter ) > 1 ? "s" : "" )
		}
	}
	return PLUGIN_CONTINUE
}

public bomb_explode( planter, defuser )
{
	if(!IsStarted() )
	{
		return PLUGIN_CONTINUE
	}

	if( get_pcvar_num( g_iWonPointsPlanterExplode ) )
	{
		g_iPoints[ planter ] += get_pcvar_num( g_iWonPointsPlanterExplode )
		g_iBombExplosions[ planter ]++
		
		if( get_pcvar_num( g_iEnableAnnounceOnChat ) )
		{
			ClientPrintColor( planter, "!g%s!n You earned!t %i!n point%s with the bomb explosion", Prefix, get_pcvar_num( g_iWonPointsPlanterExplode ), get_pcvar_num( g_iWonPointsPlanterExplode ) > 1 ? "s" : "" )
		}
	}
	return PLUGIN_CONTINUE
}

public bomb_defused( defuser )
{
	if(!IsStarted() )
	{
		return PLUGIN_CONTINUE
	}

	if( get_pcvar_num( g_iWonPointsDefuser ) )
	{
		g_iPoints[ defuser ] += get_pcvar_num( g_iWonPointsDefuser )
		g_iDefusedBombs[ defuser ]++
		
		if( get_pcvar_num( g_iEnableAnnounceOnChat ) )
		{
			ClientPrintColor( defuser, "!g%s!n You earned!t %i!n point%s for disarming the bomb", Prefix, get_pcvar_num( g_iWonPointsDefuser ), get_pcvar_num( g_iWonPointsDefuser ) > 1 ? "s" : "" )
		}
	}
	return PLUGIN_CONTINUE
}

public EventNewRound( )
{
	g_bRoundEnded = false
	
	MakeTop15( )
}


public RoundEnd( )
{
	set_task( 0.5, "SavePointsAtRoundEnd" )
}

public SavePointsAtRoundEnd( )
{
	new Players[ MAX_PLAYERS ]
	new iNum
	new i
	
	get_players( Players, iNum, "ch" )
	
	for( --iNum; iNum >= 0; iNum-- )
	{
		i = Players[ iNum ]
		
		if( g_iCurrentKills[ i ] == 4 && get_pcvar_num( g_iWonPoints4k ) )
		{
			g_iPoints[ i ] += get_pcvar_num( g_iWonPoints4k )
			
			if( get_pcvar_num( g_iEnableAnnounceOnChat ) )
			{
				ClientPrintColor( i, "!g%s!n You earned!t %i!n point%s for killing 4 in a round", Prefix, get_pcvar_num( g_iWonPoints4k ), get_pcvar_num( g_iWonPoints4k ) > 1 ? "s" : "" )
			}
		}
		
		if( g_iCurrentKills[ i ] >= 5 && get_pcvar_num( g_iWonPoints5k ) )
		{
			g_iPoints[ i ] += get_pcvar_num( g_iWonPoints5k )
			
			if( get_pcvar_num( g_iEnableAnnounceOnChat ) )
			{
				ClientPrintColor( i, "!g%s!n You earned!t %i!n point%s for killing 5 in a round", Prefix, get_pcvar_num( g_iWonPoints5k ), get_pcvar_num( g_iWonPoints5k ) > 1 ? "s" : "" )
			}
		}
		
		CheckLevelAndSave( i )
	}
}

public CheckLevelAndSave( id )
{
	if( !get_pcvar_num( g_iNegativePoints) )
	{
		if( g_iPoints[ id ] < 0 )
		{
			g_iPoints[ id ] = 0
		}
		
		if( g_iLevels[ id ] < 0 )
		{
			g_iLevels[ id ] = 0
		}
	}
	
	while( g_iPoints[ id ] >= LEVELS[ g_iLevels[ id ] ] )
	{
		g_iLevels[ id ]++
		g_iClasses[ id ]++
		
		if( get_pcvar_num( g_iEnableAnnounceOnChat ) )
		{			
			ClientPrintColor( 0, "!g%s!n %s increased one level! Level:!t %s!n Total points:!t %d", Prefix, g_szName[ id ], CLASSES[ g_iLevels[ id ] ], g_iPoints[ id ] )
		}
	}
	
	new szFormattedData[ 128 ]
	formatex( szFormattedData, charsmax( szFormattedData ),
	"%i %i %i %i %i %i %i %i %i %i %i %i",
	
	g_iPoints[ id ],
	g_iLevels[ id ],
	
	g_iKills[ id ],
	g_iDeaths[ id ],
	g_iHeadShots[ id ],
	g_iKnifeKills[ id ],
	g_iKnifeDeaths[ id ],
	g_iGrenadeKills[ id ],
	g_iGrenadeDeaths[ id ],
	g_iBombExplosions[ id ],
	g_iDefusedBombs[ id ],
	g_iWonRounds[ id ] )
	
	fvault_set_data( g_VaultSkillPoints, g_szAuthID[ id ], szFormattedData )
	
	if( g_iPoints[ id ] >= MAX_PONTUATION )
	{		
		if( get_pcvar_num( g_iEnableAnnounceOnChat ) )
		{
			ClientPrintColor( id, "!g%s!n You have reached the maximum SkillPoints! Your SkillPoints and level will start again", Prefix )
		}
		
		g_iPoints[ id ] = 0
		g_iLevels[ id ] = 0
		g_iClasses[ id ] = 0
		
		g_iKills[ id ] = 0
		g_iDeaths[ id ] = 0
		g_iHeadShots[ id ] = 0
		g_iKnifeKills[ id ] = 0
		g_iKnifeDeaths[ id ] = 0
		g_iGrenadeKills[ id ] = 0
		g_iGrenadeDeaths[ id ] = 0
		g_iBombExplosions[ id ] = 0
		g_iDefusedBombs[ id ] = 0
		g_iWonRounds[ id ] = 0
		
		CheckLevelAndSave( id )
	}
}

public LoadPoints( id )
{
	new szFormattedData[ 128 ]
	if( fvault_get_data( g_VaultSkillPoints, g_szAuthID[ id ], szFormattedData, charsmax( szFormattedData ) ) )
	{
		new szPlayerPoints[ 7 ]
		new szPlayerLevel[ 7 ]
		
		new szPlayerKills[ 7 ]
		new szPlayerDeahts[ 7 ]
		new szPlayerHeadShots[ 7 ]
		new szPlayerKnifeKills[ 7 ]
		new szPlayerKnifeDeaths[ 7 ]
		new szPlayerGrenadeKills[ 7 ]
		new szPlayerGrenadeDeaths[ 7 ]
		new szPlayerBombExplosions[ 7 ]
		new szPlayerDefusedBombs[ 7 ]
		new szPlayerWonRounds[ 7 ]
		
		parse( szFormattedData,
		szPlayerPoints, charsmax( szPlayerPoints ),
		szPlayerLevel, charsmax( szPlayerLevel ),
		
		szPlayerKills, charsmax( szPlayerKills ),
		szPlayerDeahts, charsmax( szPlayerDeahts ),
		szPlayerHeadShots, charsmax( szPlayerHeadShots ),
		szPlayerKnifeKills, charsmax( szPlayerKnifeKills ),
		szPlayerKnifeDeaths, charsmax( szPlayerKnifeDeaths ),
		szPlayerGrenadeKills, charsmax( szPlayerGrenadeKills ),
		szPlayerGrenadeDeaths, charsmax( szPlayerGrenadeDeaths ),
		szPlayerBombExplosions, charsmax( szPlayerBombExplosions ),
		szPlayerDefusedBombs, charsmax( szPlayerDefusedBombs ),
		szPlayerWonRounds, charsmax( szPlayerWonRounds ) )
		
		g_iPoints[ id ] = str_to_num( szPlayerPoints )
		g_iLevels[ id ] = str_to_num( szPlayerLevel )
		
		g_iKills[ id ] = str_to_num( szPlayerKills )
		g_iDeaths[ id ] = str_to_num( szPlayerDeahts )
		g_iHeadShots[ id ] = str_to_num( szPlayerHeadShots )
		g_iKnifeKills[ id ] = str_to_num( szPlayerKnifeKills )
		g_iKnifeDeaths[ id ] = str_to_num( szPlayerKnifeDeaths )
		g_iGrenadeKills[ id ] = str_to_num( szPlayerGrenadeKills )
		g_iGrenadeDeaths[ id ] = str_to_num( szPlayerGrenadeDeaths )
		g_iBombExplosions[ id ] = str_to_num( szPlayerBombExplosions )
		g_iDefusedBombs[ id ] = str_to_num( szPlayerDefusedBombs )
		g_iWonRounds[ id ] = str_to_num( szPlayerWonRounds )
		
	}
}

public GetSkillPoints( id )
{
	if( !get_pcvar_num( g_iEnableSkillPointsCmd ) )
	{
		ClientPrintColor( id, "!g%s!n Command disabled", Prefix )
	}
	
	else
	{		
		if( g_iLevels[ id ] < ( MAX_LEVELS - 1 ) )
		{
			ClientPrintColor( id, "!g%s!n Total points:!t %d!n Level:!t %s!n Points to the next level:!t %d", Prefix, g_iPoints[ id ], CLASSES[ g_iLevels[ id ] ], ( LEVELS[ g_iLevels[ id ] ] - g_iPoints[ id ] ) )
		}
		
		else
		{
			ClientPrintColor( id, "!g%s!n Total points:!t %d!n Level:!t %s!n (last level)", Prefix, g_iPoints[ id ], CLASSES[ g_iLevels[ id ] ] )
		}
	}
	
	return ( get_pcvar_num( g_iHideCmds ) == 0 ) ? PLUGIN_CONTINUE : PLUGIN_HANDLED_MAIN
}

public CmdGivePoints( id, level, cid )
{
	if ( !cmd_access( id, level, cid, 3 ) )
	{
		return PLUGIN_HANDLED
	}
	
	new Arg1[ 32 ]
	new Arg2[ 6 ]
	
	read_argv( 1, Arg1, charsmax( Arg1 ) )
	read_argv( 2, Arg2, charsmax( Arg2 ) )
	
	new iPlayer = cmd_target( id, Arg1, 1 )
	new iPoints = str_to_num( Arg2 )
	
	if ( !iPlayer )
	{
		console_print( id, "Sorry, player %s could not be found or targetted!", Arg1 )
		return PLUGIN_HANDLED
	}
	
	if( iPoints > 0 )
	{
		g_iPoints[ iPlayer ] += iPoints
		CheckLevelAndSave( iPlayer )
		
		if( get_pcvar_num( g_iEnableAnnounceOnChat ) )
		{
			ClientPrintColor( 0, "!g%s!n %s gave!t %i!n SkillPoint%s to %s", Prefix, g_szName[ id ], iPoints, iPoints > 1 ? "s" : "", g_szName[ iPlayer ] )
		}
	}
	
	return PLUGIN_HANDLED
}

public CmdTakePoints( id, level, cid )
{
	if ( !cmd_access( id, level, cid, 3 ) )
	{
		return PLUGIN_HANDLED
	}
	
	new Arg1[ 32 ]
	new Arg2[ 6 ]
	
	read_argv( 1, Arg1, charsmax( Arg1 ) )
	read_argv( 2, Arg2, charsmax( Arg2 ) )
	
	new iPlayer = cmd_target( id, Arg1, 1 )
	new iPoints = str_to_num( Arg2 )
	
	if ( !iPlayer )
	{
		console_print( id, "Sorry, player %s could not be found or targetted!", Arg1 )
		return PLUGIN_HANDLED
	}
	
	if( iPoints > 0 )
	{
		g_iPoints[ iPlayer ] -= iPoints
		CheckLevelAndSave( iPlayer )
		
		if( get_pcvar_num( g_iEnableAnnounceOnChat ) )
		{
			ClientPrintColor( 0, "!g%s!n %s take!t %i!n SkillPoint%s from %s", Prefix, g_szName[ id ], iPoints, iPoints > 1 ? "s" : "", g_szName[ iPlayer ] )
		}
	}
	
	return PLUGIN_HANDLED
}

public RestartSkillPoints( id )
{
	if( !get_pcvar_num( g_iEnableSkillPointsRestart ) )
	{
		ClientPrintColor( id, "!g%s!n Command disabled", Prefix )
	}
	
	else
	{
		g_iPoints[ id ] = 0
		g_iLevels[ id ] = 0
		g_iClasses[ id ] = 0
		
		g_iKills[ id ] = 0
		g_iDeaths[ id ] = 0
		g_iHeadShots[ id ] = 0
		g_iKnifeKills[ id ] = 0
		g_iKnifeDeaths[ id ] = 0
		g_iGrenadeKills[ id ] = 0
		g_iGrenadeDeaths[ id ] = 0
		g_iBombExplosions[ id ] = 0
		g_iDefusedBombs[ id ] = 0
		g_iWonRounds[ id ] = 0
		
		CheckLevelAndSave( id )
		
		if( get_pcvar_num( g_iEnableAnnounceOnChat ) )
		{
			ClientPrintColor( id, "!g%s!n Your SkillPoints and level will start again", Prefix )
		}
	}
	
	return ( get_pcvar_num( g_iHideCmds ) == 0 ) ? PLUGIN_CONTINUE : PLUGIN_HANDLED_MAIN
}

public SkillRank( id )
{
	if( !get_pcvar_num( g_iEnableSkillPointsCmdRank ) )
	{
		ClientPrintColor( id, "!g%s!n Command disabled", Prefix )
	}
	
	else
	{
		new Array:aKey = ArrayCreate( 35 )
		new Array:aData = ArrayCreate( 128 )
		new Array:aAll = ArrayCreate( FvaultData )
		
		fvault_load( g_VaultSkillPoints, aKey, aData )
		
		new iArraySize = ArraySize( aKey )
		
		new Data[ FvaultData ]
		
		new i
		for( i = 0; i < iArraySize; i++ )
		{
			ArrayGetString( aKey, i, Data[ szSteamID ], sizeof Data[ szSteamID ] - 1 )
			ArrayGetString( aData, i, Data[ szSkillP_Data ], sizeof Data[ szSkillP_Data ] - 1 )
			
			ArrayPushArray( aAll, Data )
		}
		
		ArraySort( aAll, "SortData" )
		
		new szAuthIdFromArray[ 35 ]
		
		new j
		for( j = 0; j < iArraySize; j++ )
		{
			ArrayGetString( aAll, j, szAuthIdFromArray, charsmax( szAuthIdFromArray ) )
			
			if( equal( szAuthIdFromArray, g_szAuthID[ id ] ) )
			{
				break
			}	
		}
		
		ArrayDestroy( aKey )
		ArrayDestroy( aData )
		ArrayDestroy( aAll )
		
		ClientPrintColor( id, "!g%s!n Your rank is!t %i!n of!t %i!n players with!t %i!n points ", Prefix, j + 1, iArraySize, g_iPoints[ id ] )
	}
	
	return ( get_pcvar_num( g_iHideCmds ) == 0 ) ? PLUGIN_CONTINUE : PLUGIN_HANDLED_MAIN
}

public TopSkill( id )
{
	if( !get_pcvar_num( g_iEnableSkillPointsTop15 ) )
	{
		ClientPrintColor( id, "!g%s!n Command disabled", Prefix )
	}
	
	else
	{
		show_motd( id, g_szMotd, "Top SkillPointers" )
	}
	
	return ( get_pcvar_num( g_iHideCmds ) == 0 ) ? PLUGIN_CONTINUE : PLUGIN_HANDLED_MAIN
}

public MakeTop15( )
{
	new iLen
	iLen = formatex( g_szMotd, charsmax( g_szMotd ),
	"<body bgcolor=#A4BED6>\
	<table width=100%% cellpadding=2 cellspacing=0 border=0>\
	<tr align=center bgcolor=#52697B>\
	<th width=4%%>#\
	<th width=30%% align=left>Player\
	<th width=8%%>Kills\
	<th width=8%%>Deaths\
	<th width=8%%>HS\
	<th width=8%%>Knife\
	<th width=8%%>Grenade\
	<th width=8%%>Bombs\
	<th width=8%%>Defuses\
	<th width=10%>SkillPoints" )
	
	new Array:aKey = ArrayCreate( 35 )
	new Array:aData = ArrayCreate( 128 )
	new Array:aAll = ArrayCreate( FvaultData )
	
	fvault_load( g_VaultSkillPoints, aKey, aData )
	
	new iArraySize = ArraySize( aKey )
	
	new Data[ FvaultData ]
	
	new i
	for( i = 0; i < iArraySize; i++ )
	{
		ArrayGetString( aKey, i, Data[ szSteamID ], sizeof Data[ szSteamID ] - 1 )
		ArrayGetString( aData, i, Data[ szSkillP_Data ], sizeof Data[ szSkillP_Data ] - 1 )
		
		ArrayPushArray( aAll, Data )
	}
	
	ArraySort( aAll, "SortData" )
	
	new szPlayerPoints[ 7 ]
	new szPlayerLevel[ 7 ]
	
	new szPlayerKills[ 7 ]
	new szPlayerDeahts[ 7 ]
	new szPlayerHeadShots[ 7 ]
	new szPlayerKnifeKills[ 7 ]
	new szPlayerKnifeDeaths[ 7 ]
	new szPlayerGrenadeKills[ 7 ]
	new szPlayerGrenadeDeaths[ 7 ]
	new szPlayerBombExplosions[ 7 ]
	new szPlayerDefusedBombs[ 7 ]
	new szPlayerWonRounds[ 7 ]
	
	new szName[ 22 ]
	new iSize = clamp( iArraySize, 0, 10 )
	
	new j
	for( j = 0; j < iSize; j++ )
	{
		ArrayGetArray( aAll, j, Data )
		
		fvault_get_data( g_VaultNames, Data[ szSteamID ], szName, charsmax( szName ) )
		
		replace_all( szName, charsmax( szName ), "<", "[" )
		replace_all( szName, charsmax( szName ), ">", "]" )
		
		parse( Data[ szSkillP_Data ],
		szPlayerPoints, charsmax( szPlayerPoints ),
		szPlayerLevel, charsmax( szPlayerLevel ),
		
		szPlayerKills, charsmax( szPlayerKills ),
		szPlayerDeahts, charsmax( szPlayerDeahts ),
		szPlayerHeadShots, charsmax( szPlayerHeadShots ),
		szPlayerKnifeKills, charsmax( szPlayerKnifeKills ),
		szPlayerKnifeDeaths, charsmax( szPlayerKnifeDeaths ),
		szPlayerGrenadeKills, charsmax( szPlayerGrenadeKills ),
		szPlayerGrenadeDeaths, charsmax( szPlayerGrenadeDeaths ),
		szPlayerBombExplosions, charsmax( szPlayerBombExplosions ),
		szPlayerDefusedBombs, charsmax( szPlayerDefusedBombs ),
		szPlayerWonRounds, charsmax( szPlayerWonRounds ) )
		
		iLen += formatex( g_szMotd[ iLen ], charsmax( g_szMotd ) - iLen, "<tr align=center>" )
		iLen += formatex( g_szMotd[ iLen ], charsmax( g_szMotd ) - iLen, "<td>%i", j + 1 )
		iLen += formatex( g_szMotd[ iLen ], charsmax( g_szMotd ) - iLen, "<td align=left>%s", szName )
		iLen += formatex( g_szMotd[ iLen ], charsmax( g_szMotd ) - iLen, "<td>%s", szPlayerKills )
		iLen += formatex( g_szMotd[ iLen ], charsmax( g_szMotd ) - iLen, "<td>%s", szPlayerDeahts )
		iLen += formatex( g_szMotd[ iLen ], charsmax( g_szMotd ) - iLen, "<td>%s", szPlayerHeadShots )
		iLen += formatex( g_szMotd[ iLen ], charsmax( g_szMotd ) - iLen, "<td>%s", szPlayerKnifeKills )
		iLen += formatex( g_szMotd[ iLen ], charsmax( g_szMotd ) - iLen, "<td>%s", szPlayerGrenadeKills )
		iLen += formatex( g_szMotd[ iLen ], charsmax( g_szMotd ) - iLen, "<td>%s", szPlayerBombExplosions )
		iLen += formatex( g_szMotd[ iLen ], charsmax( g_szMotd ) - iLen, "<td>%s", szPlayerDefusedBombs )
		iLen += formatex( g_szMotd[ iLen ], charsmax( g_szMotd ) - iLen, "<td>%s", szPlayerPoints )
	}
	
	iLen += formatex( g_szMotd[ iLen ], charsmax( g_szMotd ) - iLen, "</table></body>" )
	
	ArrayDestroy( aKey )
	ArrayDestroy( aData )
	ArrayDestroy( aAll )
}

public SortData( Array:aArray, iItem1, iItem2, iData[ ], iDataSize )
{
	new Data1[ FvaultData ]
	new Data2[ FvaultData ]
	
	ArrayGetArray( aArray, iItem1, Data1 )
	ArrayGetArray( aArray, iItem2, Data2 )
	
	new szPoints_1[ 7 ]
	parse( Data1[ szSkillP_Data ], szPoints_1, charsmax( szPoints_1 ) )
	
	new szPoints_2[ 7 ]
	parse( Data2[ szSkillP_Data ], szPoints_2, charsmax( szPoints_2 ) )
	
	new iCount1 = str_to_num( szPoints_1 )
	new iCount2 = str_to_num( szPoints_2 )
	
	return ( iCount1 > iCount2 ) ? -1 : ( ( iCount1 < iCount2 ) ? 1 : 0 )
}

public FwdPlayerSpawnPost( id )
{	
	if( is_user_alive( id ) )
	{
		g_iCurrentKills[ id ] = 0
	}
}

public MessageSayText( iMsgID, iDest, iReceiver )
{
	if( get_pcvar_num( g_iHideChangeNickNotification ) )
	{	
		new const Cstrike_Name_Change[ ] = "#Cstrike_Name_Change"
		
		new szMessage[ sizeof( Cstrike_Name_Change ) + 1 ]
		get_msg_arg_string( 2, szMessage, charsmax( szMessage ) )
		
		if( equal( szMessage, Cstrike_Name_Change ) )
		{
			return PLUGIN_HANDLED
		}
	}
	
	return PLUGIN_CONTINUE
}
public handleSayText(msgId, msgDest, msgEnt){
	new id = get_msg_arg_int(1);
	
	if(is_user_connected(id)){
		new szTmp[256],
			szTmp2[256];
			
		get_msg_arg_string(2, szTmp, charsmax(szTmp));
		
		new szPrefix[64]; 
		new Style;
		Style = get_pcvar_num( CvarStyle );
		//formatex(szPrefix,charsmax( szPrefix ),"^x04[%s]{%.2f}", CLASSES[ g_iLevels[ id ]], 1.0*g_iKills[ id ]/g_iDeaths[ id ]);
		
		switch(Style) {
				case 1: formatex(szPrefix,charsmax( szPrefix ),"");
				case 2: formatex(szPrefix,charsmax( szPrefix ),"^x04[%s]", CLASSES[ g_iLevels[ id ]]);
				case 3: formatex(szPrefix,charsmax( szPrefix ),"^x04[%s]{%.2f}", CLASSES[ g_iLevels[ id ]], 1.0*g_iKills[ id ]/g_iDeaths[ id ]);
				case 4: formatex(szPrefix,charsmax( szPrefix ),"^x04{%.2f}", 1.0*g_iKills[ id ]/g_iDeaths[ id ]);
			}
		
		if(!equal(szTmp, "#Cstrike_Chat_All")){
			add(szTmp2, charsmax(szTmp2), szPrefix);
			add(szTmp2, charsmax(szTmp2), " ");
			add(szTmp2, charsmax(szTmp2), szTmp);
		}
		else{
			add(szTmp2, charsmax(szTmp2), szPrefix);
			add(szTmp2, charsmax(szTmp2), "^x03 %s1^x01 :  %s2");
		}
		set_msg_arg_string(2, szTmp2);
	}
	return PLUGIN_CONTINUE;
}
ClientPrintColor( id, String[ ], any:... )
{
	new szMsg[ 190 ]
	vformat( szMsg, charsmax( szMsg ), String, 3 )
	
	replace_all( szMsg, charsmax( szMsg ), "!n", "^1" )
	replace_all( szMsg, charsmax( szMsg ), "!t", "^3" )
	replace_all( szMsg, charsmax( szMsg ), "!g", "^4" )
	
	static msgSayText = 0
	static fake_user
	
	if( !msgSayText )
	{
		msgSayText = get_user_msgid( "SayText" )
		fake_user = get_maxplayers( ) + 1
	}
	
	message_begin( id ? MSG_ONE_UNRELIABLE : MSG_BROADCAST, msgSayText, _, id )
	write_byte( id ? id : fake_user )
	write_string( szMsg )
	message_end( )
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1045\\ f0\\ fs16 \n\\ par }
*/
