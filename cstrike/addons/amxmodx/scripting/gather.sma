/*	
*	-----------------------------------------------------------
*  	PLUGIN INFO < https://alghtryer.github.io/gather/ >
*	15. Sep 2018.
*
* 	___________________________________________________________
*
*	PLUGIN NAME	: GATHER SYSTEM PUG Mod
*	VERSION		: v1.0-test
*	AUTHOR		: Alghtryer
*	E-MAIL		: alghtryer@gmail.com
*	WEB		: https://alghtryer.github.io/
*	___________________________________________________________
*
*
*	LICENSE 	:
*
*  	Copyright (C) 2018, Alghtryer <alghtryer.github.io> 
*
*  	This program is free software; you can redistribute it and/or
*  	modify it under the terms of the GNU General Public License
*  	as published by the Free Software Foundation; either version 2
*  	of the License, or (at your option) any later version.
*
*  	This program is distributed in the hope that it will be useful,
*  	but WITHOUT ANY WARRANTY; without even the implied warranty of
*  	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*  	GNU General Public License for more details.
*
*  	You should have received a copy of the GNU General Public License
*  	along with this program; if not, write to the Free Software
* 	Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
*
*	DESCRIPTIONS	:
*
*		This is an automatic system. Allows playing mix match without admin.
*		
*		Features:
*		- - - - -
*			- Player after connect ready after 10 second.
*			- Map vote when 10(cvar) players ready.
*			- After the map changes, the captain votes begins.
*			- The captains choose their teams and the match begins.
*			- Team tag a. = CT; b. = TT, and skillpoints on name <skill>. Name look TeamTag.PlayerName<skillpoints> example: a.name<123> or b.name<123>
*			- esl.cfg
*			- Demo record for every player. Demo start when the match start. Demo name is mapname.steamidofplayer.dem example: de_dust2.STEAM_ID.dem
*			- Hostname score. Score update on server name.
*			- Score show on hud in freeze time.
*			- Afk kicker.
*			- Mirror friendly fire damage. When you shoot to your teammate the damage hits on you and not in your teammate.
*			- Match end if three player leave match. (checking three times after end).
*			- Spec don't allowed, kick every on spec(chect time 20 seconds).
*			- Player without team bee kick.
*			- Maps read from maps.ini
*			- Match end when one team get score 16, or 15 - 15 score.
*
*		Commands:
*		- - - - -
*			.score - Show score
*			.kick player reason - kick player
*			.info player cvar - info player cvar value
*			.map mapname - changemap
*			.ready map/cpt - Match start. Map: vote map Cpt captain vote
*			.ff on/off - Enable/disable friednly fire.
*			.stop - End match.
*
*		Cvars:
*		- - - - -
*			gs_prefix "!gGather :" // Prefix in chat message
*			gs_nick "1" // On-Off team tag and skillpoints
*			gs_tag "1" // On-Off Team Tag
* 			gs_skill "1" // On-Off skill points on name
*			gs_amount "10" // Need player for start
*			gs_afktime "90" // Afk Time
*			gs_tag_a "a." // Team A Tag
*			gs_tag_a "b." // Team B Tag
*			gs_style "3" // Style Chat Prefix
*			...other in amxmodx/configs/gathersystem.cfg
*			
*
*		Credits:
*		- - - - -
*			fysiks 	- Skill on Name
*			Diegorkable - Random Captains and Randomizing Teams
*			ConnorMcLeod - Mirror Damage, Say Kick
*			Cheesy Peteza - Afk Kicker
*			xPaw - Hostname Timeleft
*			Map Vote - AMXX Team
*			Exolent - Save Team Score
*	 		Alka - Voteban 
*         		EaGle/Flicker(rewriten) - Private Message
*			guipatinador - SkillPoints
*
*	------------------------------------------------------------
*/
#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>
#include <engine>
#include <skillpoints>


new PLUGIN[]	= "Gather System";
new AUTHOR[]	= "Alghtryer"; 		// <alghtryer.github.io>
new VERSION[]	= "1.0-test";


#pragma semicolon 1

#define TIMER_SECONDS 10 

#define MAX_MAPS 4 
#define MAX 32 

#define UPDATE_TIME	1.0
#define ENTITY_CLASS	"env_host_timeleft"

#define IsPlayer(%1)    ( 1 <= %1 <= g_iMaxPlayers )

#define MIN_AFK_TIME 30 
#define WARNING_TIME 15        
#define CHECK_FREQ 5        

const AdminFlags = ( ADMIN_BAN | ADMIN_KICK );

#define IsUserAdmin(%1)    ((get_user_flags(%1)&AdminFlags)==AdminFlags)
#define cm(%0)    ( sizeof(%0) - 1 )

new g_iScore[2];
new g_ReadySeconds;
new g_szTeamName[2];
new g_iTeam;
new g_iScoreOffset;
new g_iLastTeamScore[2];
new g_iAltScore;

new bool:IsStarted;
new bool:SecondHalf;
new bool:g_bStop;
new bool:g_bStop2;
new bool:g_Demo[33];
new bool:g_bStart; 
new bool:is_plr_connected[33];
new bool:is_plr_ready[33];

new g_iPlayerCount;
new g_iReadyCount; 

new gMsgSyncCaptain;
new gMsgSyncHudScore;
new gMsgSyncAutoReady;
new gMsgSyncOver;
new gMsgSyncCT;
new gMsgSyncLiveud;
new gMsgSyncGet;
new gSyncInfoHud;

new TimesCheckPlayers;
new NumChecked;

new FileName[256];

new Freezetime;	
new RestartRound;
new FriendlyFire;
new MirrorDamage;
new HumansJoinTeam;
new PlayerAmount;
new g_pointerHostname;
new g_cvarEnabled;
new AfkTime;	

new bool:g_timerRunning = false;
new g_MsgServerName;
new g_szHostname[ 64 ];

new szName[32];
new gCptT;
new gCptCT;
new bool:g_bCpt;
new g_PlayersMenu;
new gMsgSyncTT;
static vsChangeName[33];
new vsName[33][32];
new CvarPrefix;
new Prefix[32];
new CvarTag;
new CvarSkill;
new CvarNick;
new CaptainMenu;

new szFilePointer;
new gMaps[MAX][32];
new LineCount;
new g_MapsChosen[4][20];
new g_DoneMaps;
new bool:Voted[ 33 ]; 
new Timer; 
new g_szKind[MAX]; 
new g_maps[MAX][30];

const m_iTeam = 114; 
new g_iMaxPlayers; 

new g_oldangles[33][3];
new g_afktime[33];
new bool:g_spawned[33] = {true, ...};

new g_ClassName[] = "rd_msg";


new CvarTagA;
new CvarTagB;
new TAG_A[32];
new TAG_B[32];
new configsDir[64];
new CvarHudScore;

public plugin_init(){
	
	register_plugin
	(
		PLUGIN,		//: Gather System
		VERSION,	//: 1.0-test
		AUTHOR		//: Alghtryer <alghtryer.github.io>
	);
	
	register_cvar("gs_version", VERSION, FCVAR_SERVER|FCVAR_UNLOGGED);
	
	register_dictionary("gather.txt");
	
	
	HumansJoinTeam 		= get_cvar_pointer("humans_join_team"); 
	Freezetime 		= get_cvar_pointer("mp_freezetime"); 
	FriendlyFire 		= get_cvar_pointer("mp_friendlyfire"); 
	RestartRound 		= get_cvar_pointer("sv_restartround");
	MirrorDamage 		= register_cvar("mp_mirrordamage", "1.0");
	PlayerAmount 		= register_cvar("gs_amount","10");
	TimesCheckPlayers	= register_cvar("gs_checktimes","3");
	g_cvarEnabled 		= register_cvar( "gs_hostname_score", "1" );
	g_pointerHostname	= get_cvar_pointer( "hostname" );
	g_MsgServerName		= get_user_msgid( "ServerName" );
	CvarPrefix 		= register_cvar( "gs_prefix", "!gGather :" );
	CvarNick		= register_cvar("gs_nick","1");
	CvarTag			= register_cvar("gs_tag","1");
	CvarSkill		= register_cvar("gs_skill","1");
	AfkTime			= register_cvar("gs_afktime", "90"); 
	CaptainMenu		= register_cvar("gs_captainmenu", "1");
	CvarTagA		= register_cvar( "gs_tag_a", "a." );
	CvarTagB		= register_cvar( "gs_tag_b", "b." );
	CvarHudScore		= register_cvar( "gs_hudscore", "1" );
	
	get_pcvar_string( CvarPrefix, Prefix, charsmax( Prefix ) );
	get_pcvar_string( CvarTagA, TAG_A, charsmax( TAG_A ) );
	get_pcvar_string( CvarTagB, TAG_B, charsmax( TAG_B ) );
	
	
	register_event("TeamScore", "Event_TeamScore", "a");
	register_event("HLTV", "ShowScoreHud", "a", "1=0", "2=0"); 
	register_logevent("CheckPlayer", 2, "1=Round_End");
	RegisterHam(Ham_Spawn, "player", "fwHamPlayerSpawnPost", 1);
	register_forward(FM_GetGameDescription,"ChangeGameName");
	RegisterHam(Ham_TraceAttack, "player", "OnCBasePlayer_TraceAttack", false); 
	
	g_iMaxPlayers 		= get_maxplayers(); 
	
	gSyncInfoHud 		= CreateHudSyncObj();
	gMsgSyncHudScore 	= CreateHudSyncObj();
	gMsgSyncAutoReady 	= CreateHudSyncObj();
	gMsgSyncOver 		= CreateHudSyncObj();
	gMsgSyncGet 		= CreateHudSyncObj();
	gMsgSyncCT 		= CreateHudSyncObj();
	gMsgSyncLiveud 		= CreateHudSyncObj();
	gMsgSyncTT 		= CreateHudSyncObj();
	gMsgSyncCaptain 	= CreateHudSyncObj();
	
	register_think(g_ClassName,"ForwardThink");
	
	new iEnt = create_entity("info_target");
	entity_set_string(iEnt, EV_SZ_classname, g_ClassName);
	entity_set_float(iEnt, EV_FL_nextthink, get_gametime() + 1.0);
	
	NumChecked = 0;
	
	register_clcmd("say", "Host_Say");
	
	set_task(float(CHECK_FREQ),"checkPlayers",_,_,_,"b");
	register_event("ResetHUD", "playerSpawned", "be");
	
	get_configsdir(FileName,255);
	format(FileName,255,"%s/gs.txt",FileName); 
	
	set_task( 20.0, "SpecKick", _, _, _, "b" );
	set_task( 2.5, "checkTimeleft" );
	
}
public plugin_natives()
{
	register_library("gather");
	
	register_native("IsStarted","_IsStarted");
	register_native("SecondHalf","_SecondHalf");
	register_native("g_bStart","_g_bStart");
}
public bool:_IsStarted(plugin, params)
{
	return IsStarted;
}
public bool:_SecondHalf(plugin, params)
{
	return SecondHalf;
}
public bool:_g_bStart(plugin, params)
{
	return g_bStart;
}
public plugin_cfg() {
	Read();
	MapsFile();
	set_pcvar_string(HumansJoinTeam, "");
	set_pcvar_num(Freezetime, 0);
	set_pcvar_num(FriendlyFire, 0);
	server_cmd("exec prepare.cfg");
	get_configsdir(configsDir, charsmax(configsDir));
	server_cmd("exec %s/gathersystem.cfg", configsDir);
}
public plugin_end() 
{ 
	if( g_timerRunning )
		if( strlen( g_szHostname ) )
		set_pcvar_string( g_pointerHostname, g_szHostname );
} 
public Write(){
	//new writedata[2];
	new anyvalue;
	
	anyvalue = 0;
	
	new filepointer = fopen(FileName,"w+");
	if(filepointer)
	{
		
		//formatex(writedata,1,"%d",anyvalue);
		//fputs(filepointer,writedata);
		fprintf(filepointer,"%d",anyvalue);
		fclose(filepointer);
	}
}
public WriteOne(){
	//new writedata[2];
	new anyvalue;
	
	anyvalue = 1;
	
	new filepointer = fopen(FileName,"w+");
	if(filepointer)
	{
		
		//formatex(writedata,1,"%d",anyvalue);
		//fputs(filepointer,writedata);
		fprintf(filepointer,"%d",anyvalue);
		fclose(filepointer);
	}
}
public Read(){
	new filepointer = fopen(FileName,"r");
	if(filepointer)
	{
		new readdata[2], anyvalue;
		new parsedanyvalue[2];
		
		while(fgets(filepointer,readdata,1))
		{   
			parse(readdata,parsedanyvalue,1);
			
			anyvalue = str_to_num(parsedanyvalue);
			if(anyvalue == 0){
				g_bStart = true;
				}else{
				set_task( 10.0, "setstart"); 
			}
			break;
		}
		fclose(filepointer);
	}
}
public ChangeGameName()
{ 
	new game[32];
	format(game, 31, "[GATHER]");
	forward_return(FMV_STRING, game);
	
	return FMRES_SUPERCEDE;
} 
public Host_Say(id)
{
	
	new szSaid[128];
	read_args(szSaid, cm(szSaid));
	remove_quotes(szSaid);
	
	if( equali(szSaid, ".kick ", 6) )
	{
		if(IsUserAdmin(id))
		{
			new arg[32], reason[64];
			if( parse(szSaid[6], arg, cm(arg), reason, cm(reason)) )
			{
				new player = cmd_target(id, arg, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_ALLOW_SELF);
				if (!player)
				{
					return PLUGIN_HANDLED;
				}
				
				new authid[32], authid2[32], name2[32], name[32], userid2;
				
				get_user_authid(id, authid, charsmax(authid));
				get_user_authid(player, authid2, charsmax(authid2));
				get_user_name(player, name2, charsmax(name2));
				get_user_name(id, name, charsmax(name));
				userid2 = get_user_userid(player);
				
				log_amx("Kick: ^"%s<%d><%s><>^" kick ^"%s<%d><%s><>^" (reason ^"%s^")", name, get_user_userid(id), authid, name2, userid2, authid2, reason);
				
				show_activity_key("ADMIN_KICK_1", "ADMIN_KICK_2", name, name2);
				
				if (is_user_bot(player))
					server_cmd("kick #%d", userid2);
				else
				{
					if (reason[0])
						server_cmd("kick #%d ^"%s^"", userid2, reason);
					else
						server_cmd("kick #%d", userid2);
				}
			}
		}
		else 
			ClientPrintColor(id, "%s %L", Prefix, LANG_PLAYER, "NOT_ADMIN");
	}
	if( equali(szSaid, ".info ", 6) )
	{
		new arg[32], reason[64];
		if( parse(szSaid[6], arg, cm(arg), reason, cm(reason)) )
		{
			new player = cmd_target(id, arg, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_ALLOW_SELF);
			if (!player)
			{
				return PLUGIN_HANDLED;
			}
			
			if (is_user_bot(player))
				ClientPrintColor(id, "%s %L", Prefix, LANG_PLAYER, "INFO_BOT");
			else
			{
				if (!reason[0])
					ClientPrintColor(id, "%s %L", Prefix, LANG_PLAYER, "USE_INFO");
				else
				{
					query_client_cvar(player, reason, "CheckCvar");
					new name[32];
					get_user_name(player, name, 31);
					ClientPrintColor(id, "%s %L", Prefix, LANG_PLAYER, "INFO_CHECK", reason, name); 
				}  
			}
			return PLUGIN_CONTINUE;
		}
	}
	if( equali(szSaid, ".ff ", 4) )
	{
		if(IsUserAdmin(id))
		{
			new arg[32];
			if( parse(szSaid[4], arg, cm(arg))){
				
				if(equal(arg, "on") ) {
					set_pcvar_num(FriendlyFire, 1 );
					ClientPrintColor(id, "%s %L", Prefix, LANG_PLAYER, "FFON_ADMIN");
				}
				else if(equal(arg, "off") ){
					set_pcvar_num(FriendlyFire, 0 );
					ClientPrintColor(id, "%s %L", Prefix, LANG_PLAYER, "FFOFF_ADMIN");
				}
			}
		}
		else 
			ClientPrintColor(id, "%s %L", Prefix, LANG_PLAYER, "NOT_ADMIN");
		
	}
	if( equali(szSaid, ".map ", 5) )
	{
		if(IsUserAdmin(id))
		{
			new arg[32];
			if( parse(szSaid[5], arg, cm(arg))){
				
				if (arg[0])
					server_cmd("changelevel %s", arg );
				
			}
		}
		else 
			ClientPrintColor(id, "%s %L", Prefix, LANG_PLAYER, "NOT_ADMIN");
		
	}
	if( equali(szSaid, ".ready ", 7) )
	{
		if(IsUserAdmin(id))
		{
			new arg[32];
			if( parse(szSaid[7], arg, cm(arg))){
				
				if(equal(arg, "map") || !arg[0] ) 
					ActionSpecial();
				else if(equal(arg, "cpt") )
					setstart();
			}
		}
		else
			ClientPrintColor(id, "%s %L", Prefix, LANG_PLAYER, "NOT_ADMIN");
		
	}
	if( equali(szSaid, ".stop", 5) )
	{
		if(IsUserAdmin(id))
		{
			EndMatch();
		}
		else
			ClientPrintColor(id, "%s %L", Prefix, LANG_PLAYER, "NOT_ADMIN");
		
	}
	if( equali(szSaid, ".score", 6) )
	{
		ShowScore();
	}
	return PLUGIN_CONTINUE;
}  
public CheckCvar(player, cvar_name[], cvar_value[])
{
	new plr_name[32];
	get_user_name(player, plr_name, 31);
	
	ClientPrintColor(0, "%s %s has %s set to %s.", Prefix, plr_name, cvar_name, cvar_value);
}
public setstart(){
	set_task(15.0, "RandomCpt");
	ClientPrintColor( 0, "%s %L", Prefix, LANG_PLAYER,"START_CAPTAINS");
}

public StartMatch(){
	Write();
	IsStarted = true;
	g_bStart = false;
	server_cmd("exec esl.cfg");
	g_ReadySeconds = 6;
	set_task(1.0, "ready_messages", 346,_,_,"b",_);
	set_pcvar_string(HumansJoinTeam, "");
	set_pcvar_num(CaptainMenu, 1);
	g_iScore[0] = 0;
	g_iScore[1] = 0;
	
	new players[32], pnum, tempid;
	
	get_players(players, pnum, "h");
	for (new x ; x<pnum ; x++)
	{
		tempid = players[x];
		
		switch( cs_get_user_team(tempid) ) {
			case CS_TEAM_UNASSIGNED: continue;
				case CS_TEAM_SPECTATOR: server_cmd("kick # %d", get_user_userid(tempid));
				case CS_TEAM_T: ChangeTagB(tempid);
				case CS_TEAM_CT: ChangeTagA(tempid);
			}
	}
	
}
public MoveFromSpec(id) {
	new playersT[ 32 ] , numT , playersCt[ 32 ] , numCt;
	
	get_players( playersT , numT , "he" , "TERRORIST" );
	get_players( playersCt , numCt , "he" , "CT" );
	
	if (SecondHalf)
	{
		if( numT > numCt )
		{
			set_pcvar_string(HumansJoinTeam, "CT");
			client_cmd(id, "slot1");
			ChangeTagB(id);
		}
		
		else
		{
			set_pcvar_string(HumansJoinTeam, "T");
			client_cmd(id, "slot1");
			ChangeTagA(id);
		}
	}
	
	else
	{
		if( numT > numCt )
		{
			set_pcvar_string(HumansJoinTeam, "CT");
			client_cmd(id, "slot1");
			ChangeTagA(id);
			
		}
		
		else
		{
			set_pcvar_string(HumansJoinTeam, "T");
			client_cmd(id, "slot1");
			ChangeTagB(id);
		}	
	}
	if (g_bCpt) {
		user_silentkill(id);
		if(is_user_connected(id))
			cs_set_user_team(id, CS_TEAM_SPECTATOR);
	}
	return PLUGIN_CONTINUE;
	
}

public client_putinserver(id){
	if(is_user_hltv(id))
		return PLUGIN_HANDLED;
	
	g_afktime[id] = 0;
	
	check_server(id);
	
	if (IsStarted)
	{
		MoveFromSpec(id);
		
	}
	
	g_iPlayerCount++;
	is_plr_connected[id] = true;
	
	new params[1] = {TIMER_SECONDS + 1}; 
	set_task(1.0, "TaskCountDown", id, params, sizeof(params)); 
	
	set_task(30.0, "NoTeam", id);
	
	return PLUGIN_HANDLED;
}
public NoTeam(id) {
	if ( !is_user_connected(id) )
		return PLUGIN_HANDLED;
	
	if (cs_get_user_team(id) == CS_TEAM_UNASSIGNED)
	{
		server_cmd("kick #%d ^"No Team^"",get_user_userid(id));
	}
	return PLUGIN_HANDLED;
}
public check_server(id)
{
	new players[32], num;
	get_players(players,num,"h");
	if(num == get_pcvar_num(PlayerAmount))
	{
		new players[32], pnum, tempid;
		get_players(players, pnum, "h");
		for (new full; full<pnum ; full++)
		{
			players[full] = tempid;
			if (is_user_connecting(tempid))
				server_cmd("kick #%d ^"Server is Full^"", get_user_userid(tempid));
		}
	}
	else if (num > get_pcvar_num(PlayerAmount))
	{
		server_cmd("kick #%d ^"Server is Full^"", get_user_userid(id));
	}
	
	return PLUGIN_HANDLED;
}
stock ChangeTagA(id){  
	if(get_pcvar_num(CvarNick)) 
	{
		get_user_info( id, "name", szName, charsmax( szName ) );
		replace_all(szName, charsmax(szName), " " , "");
		replace(szName, charsmax(szName), TAG_A , "");
		replace(szName, charsmax(szName), TAG_B , "");
		
		if(get_pcvar_num(CvarSkill)) 
		{
			szName = points_in_name(id, szName);
		} 
		
		if(get_pcvar_num(CvarTag)) 
		{
			format(szName, charsmax(szName), "%s%s", TAG_A, szName);
			set_user_info( id, "name", szName );
			vsChangeName[id] = true;
			vsName[id] = szName;
		}
		else
		{  
			set_user_info( id, "name", szName );  
			vsChangeName[id] = true;
			vsName[id] = szName;
		}  
	}
}  
stock ChangeTagB(id){  
	if(get_pcvar_num(CvarNick)) 
	{
		get_user_info( id, "name", szName, charsmax( szName ) );
		replace_all(szName, charsmax(szName), " " , "");
		replace(szName, charsmax(szName), TAG_A , "");
		replace(szName, charsmax(szName), TAG_B , "");
		
		if(get_pcvar_num(CvarSkill)) 
		{
			szName = points_in_name(id, szName);
		}

		if(get_pcvar_num(CvarTag)) 
		{
			format(szName, charsmax(szName), "%s%s", TAG_B, szName);
			set_user_info( id, "name", szName ); 
			vsChangeName[id] = true;
			vsName[id] = szName;
		} 
		else
		{  
			set_user_info( id, "name", szName );  
			vsChangeName[id] = true;
			vsName[id] = szName;
		}  
		
	}
} 
stock points_in_name(id, szName[32] ) { 
	new iLen = strlen( szName );
	
	new iPos = iLen - 1;
	
	if( szName[ iPos ] == '>' )
	{    
		new i;
		for( i = 1; i < 7; i++ )
		{    
			if( szName[ iPos - i ] == '<' )
			{    
				iLen = iPos - i;
				szName[ iLen ] = '^0';
				break;
			}
		}
	}
	
	format( szName[ iLen ], charsmax( szName ) - iLen, szName[ iLen-1 ] == ' ' ? "<%d>" : "<%d>", skillpoints(id));
	return szName;
	
}  
public ready_messages()
{
	g_ReadySeconds--;
	switch(g_ReadySeconds)
	{
		case 5: {
			ClientPrintColor(0, "%s %L", Prefix, LANG_PLAYER, SecondHalf ? "HALF" : "MATCH");
			ClientPrintColor(0, "%s %L", Prefix, LANG_PLAYER, "FIVE");
		}
		case 4: {
			ClientPrintColor(0, "%s %L", Prefix, LANG_PLAYER, "FOUR");
			set_pcvar_num(RestartRound, 1);
		}
		case 3: ClientPrintColor(0, "%s %L", Prefix, LANG_PLAYER, "THREE");
			case 2: {
			ClientPrintColor(0, "%s %L", Prefix, LANG_PLAYER, "TWO");
			set_pcvar_num(RestartRound, 1);
		}
		case 1: ClientPrintColor(0, "%s %L", Prefix, LANG_PLAYER, "ONE");
			case 0: {
			ClientPrintColor(0, "%s %L", Prefix, LANG_PLAYER, "GAME"); 
			ClientPrintColor(0, "%s %L", Prefix, LANG_PLAYER, "LIVE");
			ClientPrintColor(0, "%s %L", Prefix, LANG_PLAYER, "GLHF");
			
			set_hudmessage(255, 255, 255, 0.06, 0.34, 0, 6.0, 20.0);
			ShowSyncHudMsg(0, gMsgSyncLiveud, "%L", LANG_PLAYER, SecondHalf ? "LIVEHUDHALF" : "LIVEHUD" );
			
			engclient_print(0, engprint_center, "Don't shoot on your teammate!!!");

			remove_task(346);
		}
	}
}
public Event_TeamScore() {
	if (IsStarted) 
	{
		read_data(1, g_szTeamName, 1);
		
		g_iTeam = (g_szTeamName[0] == 'T') ? 0 : 1;
		g_iAltScore = read_data(2);
		g_iScoreOffset = g_iAltScore - g_iLastTeamScore[g_iTeam];
		
		if(g_iScoreOffset > 0)
		{
			g_iScore[g_iTeam] += g_iScoreOffset;
		}
		
		g_iLastTeamScore[g_iTeam] = g_iAltScore;
		
		
		if (g_iScore[0] + g_iScore[1] == 15)
		{
			if (g_bStop2)
			{
				return PLUGIN_HANDLED;
			}
			g_bStop2 = true;
			set_task(1.5, "SwitchTeams");
			ClientPrintColor(0,  "%s %L", Prefix, LANG_PLAYER, "SWITCH_TEAMS");
			set_task(10.0, "scndhalf");
		}
		else if ((g_iScore[0] == 16) || (g_iScore[1] == 16 || g_iScore[0] == 15 && g_iScore[1] == 15))
		{
			if (g_bStop)
			{
				return PLUGIN_HANDLED;
			}
			g_bStop = true;
			EndMatch();
			return PLUGIN_HANDLED;
		}
		
	}
	
	return PLUGIN_HANDLED;
}
public SwitchTeams() {
	new supportvariable;
	
	supportvariable = g_iScore[0];
	g_iScore[0] = g_iScore[1];
	g_iScore[1] = supportvariable;
	
	new players[32], pnum, tempid;
	get_players(players, pnum, "h");
	
	for( new i; i<pnum; i++ ) {
		tempid = players[i];
		switch( cs_get_user_team(tempid) ) {
			case CS_TEAM_T: cs_set_user_team(tempid, CS_TEAM_CT);
				case CS_TEAM_CT: cs_set_user_team(tempid, CS_TEAM_T);
			}
	}
	
	SecondHalf = true;
	return PLUGIN_HANDLED;
}
public scndhalf() {
	set_pcvar_num(RestartRound, 1);
	g_ReadySeconds = 6;
	set_task(1.0, "ready_messages", 346,_,_,"b",_);
}
public ShowScore() {
	
	if (IsStarted)
	{
		
		if (SecondHalf)
			ClientPrintColor(0,  "%s %L", Prefix, LANG_PLAYER, "SHOW_SCORE_TAG", g_iScore[0], g_iScore[1]);
		else
			ClientPrintColor(0, "%s %L", Prefix, LANG_PLAYER, "SHOW_SCORE_TAG", g_iScore[1], g_iScore[0]);
	}
	
	else
	{
		ClientPrintColor(0,  "%s %L", Prefix, LANG_PLAYER, "MATCH_NOT_STARTED");
	}
	return PLUGIN_CONTINUE;
}
public ShowScoreHud()
{       
	if(get_pcvar_num(CvarHudScore)) 
	{    
		if (IsStarted)
		{
			if (SecondHalf)
			{
				set_hudmessage(0, 212, 255, 0.52, 0.49,0, 6.0, 10.0);
				ShowSyncHudMsg(0, gMsgSyncHudScore, "%L",LANG_PLAYER, "SHOW_SCORE_HUD", g_iScore[0], g_iScore[1]);
			} 
			else
			{
				set_hudmessage(0, 212, 255, 0.52, 0.49,0, 6.0, 10.0);
				ShowSyncHudMsg(0, gMsgSyncHudScore, "%L",LANG_PLAYER, "SHOW_SCORE_HUD", g_iScore[1], g_iScore[0]);
			} 
		}
		return PLUGIN_CONTINUE;
	}
	return PLUGIN_CONTINUE;
}
public CheckPlayer()
{ 
	if (IsStarted)
	{
		new players[32], num;
		get_players(players,num,"h");
		if(num<=get_pcvar_num(PlayerAmount)-3)
		{
			NumChecked++;
			ClientPrintColor(0,"%s %L", Prefix, LANG_PLAYER, "CHECK",NumChecked,get_pcvar_num(TimesCheckPlayers));
			if(NumChecked>=get_pcvar_num(TimesCheckPlayers))
			{
				set_task(5.0,"EndMatch");
				ClientPrintColor(0,"%s %L", Prefix, LANG_PLAYER, "MATCH_OVER_CHECK");
				NumChecked = 0;
			}
		}
		else
			NumChecked = 0;
	}
	return PLUGIN_CONTINUE;
}
public EndMatch() {
	if (IsStarted)
	{
		ClientPrintColor(0,  "%s %L", Prefix, LANG_PLAYER, "MATCH_OVER");
		ClientPrintColor(0,  "%s %L", Prefix, LANG_PLAYER, "PLUGIN_RESTART");
		set_hudmessage(0, 212, 255, 0.06, 0.21, 0, 6.0, 15.0);
		ShowSyncHudMsg(0, gMsgSyncOver, "%L", LANG_PLAYER, "MATCH_OVER_HUD");
		set_task(15.0, "RestartServer");
	}
	else
	{
		ClientPrintColor(0,  "%s %L", Prefix, LANG_PLAYER, "MATCH_NOT_STARTED");
	}
	return PLUGIN_CONTINUE;
}
public RestartServer()
{
	server_cmd("restart");  
}
public fwHamPlayerSpawnPost(id) {
	if (is_user_alive(id)) {
		if(IsStarted)
			if(!g_Demo[id])
			Record(id);
	}
}  
public Record(id) {
	
	new szAuthid_A[32], szMapName[ 32 ];
	get_user_authid(id, szAuthid_A, 31);
	get_mapname( szMapName, charsmax( szMapName ) );
	
	replace_all( szAuthid_A, 31, ":", "_" );
	
	g_Demo[id] = true;
	client_cmd(id, "stop; record ^"%s_-_%s^"", szMapName, szAuthid_A);
	ClientPrintColor( id,"%s %L", Prefix, LANG_PLAYER, "DEMO_RECORD", szMapName, szAuthid_A);
	
} 
public client_connect(id) {
	
	if (is_user_connected(id)){
		vsName[id][0] = EOS; 
		vsChangeName[id] = false;
		g_afktime[id] = 0;
	}
	if (g_bCpt && is_user_connected(id))
	{
		if (cs_get_user_team(id) != CS_TEAM_UNASSIGNED)
		{
			cs_set_user_team(id, CS_TEAM_SPECTATOR);
			return PLUGIN_HANDLED;
		}
		
		else
			set_task(1.0, "client_connect", id);
		return PLUGIN_HANDLED;
	}	
	return PLUGIN_HANDLED;
}

public client_disconnect( id )
{
	if( task_exists( id ) )
	{
		remove_task( id );
	}
	
	vsChangeName[id] = false;
	
	if(g_Demo[id])
		g_Demo[id] = false;
	
	
	g_iPlayerCount--;
	if(is_plr_ready[id])
		g_iReadyCount--;
	is_plr_connected[id] = false;
	is_plr_ready[id] = false;
}

public TaskCountDown(params[], id){
	if(g_bStart){
		new name[32];
		get_user_name(id, name, 31); 
		
		if(--params[0] > 0) { 
			
			set_hudmessage(255, 255, 0, -1.0, 0.30, 0, 6.0, 1.0);
			ShowSyncHudMsg(id, gMsgSyncAutoReady, "%L",LANG_PLAYER, "AUTO_READY",name, params[0]);
			set_task(1.0, "TaskCountDown", id, params, 1); 
			
			} else { 
			cmd_ready(id); 
		} 
	}
}
public cmd_ready(id)
{
	if(g_bStart)
	{
		if(!is_plr_ready[id])
		{
			is_plr_ready[id] = true;
			g_iReadyCount++;
		}
		ClientPrintColor(0,"%s %L", Prefix, LANG_PLAYER, "READY_NUM" ,g_iReadyCount,get_pcvar_num(PlayerAmount));
		
		if(g_iPlayerCount == get_pcvar_num(PlayerAmount) && g_iPlayerCount == g_iReadyCount)
		{
			
			set_hudmessage(0, 130, 0, 0.40, 0.35, 0, 6.0, 1.0);
			ShowSyncHudMsg(0, gMsgSyncGet, "%L",LANG_PLAYER, "GOING_LIVE");
			set_task( 10.0, "ActionSpecial"); 
			ClientPrintColor( 0, "%s %L", Prefix, LANG_PLAYER, "MAP_STARTED");
			ClientPrintColor( 0, "%s %L", Prefix, LANG_PLAYER, "MAP_STARTED");
			ClientPrintColor( 0, "%s %L", Prefix, LANG_PLAYER, "MAP_STARTED");
			ClientPrintColor( 0, "%s %L", Prefix, LANG_PLAYER,"MAP_STARTED");
		}
	}
	
	return PLUGIN_HANDLED;
}
public ReadyHud()
{
	new iHostName[ 64 ];
	get_pcvar_string( g_pointerHostname, iHostName, charsmax( iHostName ) );
	
	new GetTotal = get_pcvar_num(PlayerAmount);
	
	set_hudmessage(0, 212, 255, 0.57, 0.05, _, _, 1.0, _, _, 1);
	ShowSyncHudMsg(0, gSyncInfoHud, "%L",LANG_PLAYER, "INFOHUD",  iHostName, g_iReadyCount, GetTotal);
}  

public ForwardThink(iEnt)
{
	if(g_bStart)
		ReadyHud(); 
	
	entity_set_float(iEnt, EV_FL_nextthink, get_gametime() + 1.0);
}
public SpecKick()
{
	if(IsStarted){
		new players[32], pnum;
		get_players(players, pnum, "h");
		
		for (new x ; x<pnum ; x++) {
			if (is_user_connected(players[x])) {
				if ((cs_get_user_team(players[x]) == CS_TEAM_SPECTATOR)) {
					new userid = get_user_userid(players[x]);
					server_cmd("kick #%d ^"Spectators aren't welcome on this server.^"",userid);
				}
				
			}
		}
		return PLUGIN_CONTINUE;
	}
	return PLUGIN_CONTINUE;
}
public client_infochanged(id)
{ 
	if(!is_user_connected(id))
		return PLUGIN_CONTINUE;
	
	if(vsChangeName[id])
	{ 
		static szNewName[32]; 
		get_user_info(id, "name", szNewName, charsmax(szNewName)); 
		if( !equal(vsName[id], szNewName) ) 
		{ 
			set_user_info(id, "name", vsName[id]) ;
			return PLUGIN_HANDLED;
		} 
		
		return PLUGIN_CONTINUE;
	}
	return PLUGIN_CONTINUE;
}
public MapsFile()
{
	new szWepFile[256], szConfigdir[128];
	
	get_configsdir(szConfigdir, charsmax(szConfigdir)); 
	formatex(szWepFile, charsmax(szWepFile), "%s/maps.ini", szConfigdir);
	
	if(file_exists(szWepFile)){
		ReadMaps(szWepFile);
	}
	
	return 1;
}
stock ReadMaps(szWepFile[])
{
	szFilePointer = fopen(szWepFile, "r"); 
	
	new szData[32];
	
	if(szFilePointer) 
	{
		while(!feof(szFilePointer))
		{
			fgets(szFilePointer, szData, charsmax(szData)); 
			trim(szData);  
			strtolower(szData);
			
			if(szData[0] == ';' || !szData[0])
				continue;
			
			remove_quotes(szData);
			copy(gMaps[LineCount++], 31, szData);
		}
	}
	else
	{
		set_fail_state("Failed to Find maps.ini");
	}
	fclose(szFilePointer); 
}
public ActionSpecial() 
{ 
	
	new rnd; 
	while (g_DoneMaps != MAX_MAPS && LineCount > 0) { 
		rnd = random(LineCount);
		copy(g_MapsChosen[g_DoneMaps++], 19, gMaps[rnd]); 
		gMaps[rnd] = gMaps[--LineCount];
	} 
	
	for(new i = 0; i < g_DoneMaps; i++)  {
		g_szKind[i] = 0;
		format(g_maps[i], 29, "%s", g_MapsChosen[i]);
	}
	
	new players[32], num, id;
	get_players(players, num);
	for( new i = 0; i < num; i++ )
	{
		id = players[i];
		Voted[id] = false;
		ChangeMaps(id);
	}
	
	Timer = 17;
	client_cmd(0, "spk ^"get red(e80) ninety(s45) to check(e20) use bay(s18) mass(e42) cap(s50)^""); 
	set_task( 17.0, "checkvotesd");  
	countdown2();
}
public ChangeMaps(client) { 
	static szMap[128];  
	new st[ 3 ]; 
	formatex(szMap, charsmax(szMap)-1, "\r[GATHER]\w Choose Map:^n\r// \wStatus: %s^n\r// \wTime to choose: \y%d",Voted[client] ? "\yVoted" : "\rNot Voted", Timer);  
	new menu = menu_create(szMap, "handlerdddd"); 
	
	
	for( new k = 0; k < MAX_MAPS; k++ ) { 
		num_to_str( k, st, 2 ); 
		formatex( szMap, charsmax( szMap ), "\w%s \d[\y%i\w Votes\d]", g_maps[k] , g_szKind[k]); 
		menu_additem( menu, szMap, st ); 
	}
	
	menu_setprop( menu, MPROP_EXIT, MEXIT_NEVER ); 
	menu_display(client,menu); 
} 

public checkvotesd() {  
	new Winner = 0; 
	for( new i = 1; i < sizeof g_maps; i++ )  { 
		if( g_szKind[ Winner ] < g_szKind[ i ] ) 
			Winner = i; 
	} 
	
	ClientPrintColor( 0, "%s %L", Prefix, LANG_PLAYER, "WON_MAP", g_maps[ Winner ], g_szKind[ Winner ] ); 
	new map[30]; 
	format(map, 29, "%s", g_maps[Winner]); 
	WriteOne();
	set_task(5.0, "changemap_", _, map, 30); 
} 

public changemap_(param[]) 
	server_cmd("changelevel %s", param); 

public handlerdddd( client, menu, item ) { 
	if( item == MENU_EXIT )
		return PLUGIN_HANDLED;
	if( Voted[ client ] == true ) 
	{ 
		ChangeMaps( client); 
		return PLUGIN_HANDLED ;
	} 
	
	new szName[ 32 ]; 
	get_user_name( client, szName, 31 );  
	
	ClientPrintColor( 0, "%s %L", Prefix, LANG_PLAYER, "MAP_X_VOTE", szName, g_maps[ item ] ); 
	g_szKind[ item ]++; 
	
	Voted[ client ] = true; 
	ChangeMaps(client); 
	return PLUGIN_HANDLED;
	
} 

public countdown2() 
{ 
	if(Timer <= 0) 
		remove_task(2000); 
	else 
	{ 
		Timer--; 
		set_task(1.0,"countdown2"); 
		for( new i = 1; i <= get_maxplayers(); i++ ) 
			if(is_user_connected( i ) ) 
			ChangeMaps(i); 
	} 
} 
public checkTimeleft( ) {
	get_pcvar_string( g_pointerHostname, g_szHostname, 63 );
	
	if( get_pcvar_num( g_cvarEnabled ) != 1 ) {
		g_timerRunning = false;
		
		return;
	} else
	register_think( ENTITY_CLASS, "fwdThink_Updater" );
	
	g_timerRunning = true;
	new iEntityTimer = create_entity( "info_target" );
	entity_set_string( iEntityTimer, EV_SZ_classname, ENTITY_CLASS );
	entity_set_float( iEntityTimer, EV_FL_nextthink, get_gametime() + UPDATE_TIME );
}

public fwdThink_Updater( iEntity ) {
	static szHostname[ 64 ];
	if (IsStarted)
	{
		
		if (SecondHalf)
			formatex( szHostname, 63, "%s (A %d:%d B)",g_szHostname, g_iScore[0], g_iScore[1]);
		else
			formatex( szHostname, 63, "%s (A %d:%d B)",g_szHostname, g_iScore[1], g_iScore[0]);
	}
	else
	{
		formatex( szHostname, 63, "%s (Match Not Started)",g_szHostname);
	}
	set_pcvar_string( g_pointerHostname, szHostname );
	message_begin( MSG_BROADCAST, g_MsgServerName );
	write_string( szHostname );
	message_end( );
	
	entity_set_float( iEntity, EV_FL_nextthink, get_gametime() + UPDATE_TIME );
	
	return PLUGIN_CONTINUE;
}

public RandomCpt() {
	set_pcvar_num(Freezetime , 9999);
	set_pcvar_num(CaptainMenu, 0);
	new players[32], pnum, tempid;
	get_players(players, pnum, "h");
	new specialCount;
	
	for( new i; i<pnum; i++ ) {
		tempid = players[i];
		user_silentkill(tempid);
		
		if ( cs_get_user_team(tempid) != CS_TEAM_UNASSIGNED )
		{
			specialCount++;
			cs_set_user_team(tempid, CS_TEAM_SPECTATOR);
		} 
		
	}
	if (specialCount < 2) {
		
		ClientPrintColor(0, "%s %L", Prefix, LANG_PLAYER, "LESS_PLAYERS_CUSTOM");
		set_task(3.0, "RandomTeams");
		return;
		
	}
	
	new z = random(pnum);
	while (cs_get_user_team(players[z]) == CS_TEAM_UNASSIGNED)
		z = random(pnum);
	cs_set_user_team(players[z], CS_TEAM_T);
	gCptT = players[z];
	
	new q = random(pnum);
	while ( (q == z) || cs_get_user_team(players[q]) == CS_TEAM_UNASSIGNED )
		q = random(pnum);
	

	cs_set_user_team(players[q], CS_TEAM_CT); 
	gCptCT = players[q];
	ClientPrintColor(0, "%s %L", Prefix, LANG_PLAYER, "RANDOM_CAPTAINS_CHOSEN");
	ClientPrintColor(0, "%s %L", Prefix, LANG_PLAYER, "TERROR_CAPTAIN_FIRST");
	g_bCpt = true;

	moveT();
	return;
}

public kickhimout(id) {
	ClientPrintColor(0, "%s %L", Prefix, LANG_PLAYER, "CAPTAINS_AFK");
	set_hudmessage(255, 0, 0, 0.40, 0.32, 0, 6.0, 12.0);
	ShowSyncHudMsg(0, gMsgSyncCaptain, "%L", LANG_PLAYER, "CAPTAINS_AFK");
	show_menu(0, 0, "^n", 1);
	g_bCpt = false;
	set_task(5.0, "RandomTeams");
	return PLUGIN_HANDLED;
}


public moveT() {
	TeamsInfo();
	
	new title[64];
	formatex(title, charsmax(title), "%L", LANG_PLAYER, "CHOOSE_PLAYER");
	g_PlayersMenu = menu_create(title, "moveT_menu"); 
	new players[32], pnum, tempid;
	new Tplayers[32], Tpnum;
	new szName[32], szTempid[10]; 
	new pickisdone, check;
	get_players(players, pnum, "h"); 
	
	if ( !pnum )
		return PLUGIN_HANDLED;
	
	get_players(Tplayers, Tpnum, "he", "TERRORIST");
	
	
	for( new i; i<pnum; i++ ) 
	{ 
		tempid = players[i];
		
		if ((tempid == gCptT) || (tempid == gCptCT))
			check++;
		
		if (cs_get_user_team(tempid) == CS_TEAM_UNASSIGNED)
			continue;
		
		else if (cs_get_user_team(tempid) == CS_TEAM_SPECTATOR) {
			get_user_name(tempid, szName, 31); 
			num_to_str(tempid, szTempid, 9); 
			menu_additem(g_PlayersMenu, szName, szTempid);
			pickisdone++;
		}
	} 
	
	if (check != 2) {
		ClientPrintColor(0, "%s %L", Prefix, LANG_PLAYER, "CAPTAINS_DISCONNECTED");
		g_bCpt = false;
		set_task(3.0, "RandomTeams");
		return PLUGIN_HANDLED;
	}
	
	if (pickisdone == 0) {
		ClientPrintColor(0, "%s %L", Prefix, LANG_PLAYER, "TEAMS_ARE_SET");
		g_bCpt = false;
		set_task(10.0, "StartMatch");
		return PLUGIN_HANDLED;
	}
	
	if (Tpnum >= get_pcvar_num(PlayerAmount)/2 ) {
		ClientPrintColor(0, "%s %L", Prefix, LANG_PLAYER, "TERROR_TEAM_FULL");
		moveCT();
		return PLUGIN_HANDLED;
	}
	
	
	menu_display(gCptT, g_PlayersMenu);
	set_task(25.0, "kickhimout", gCptT);
	return PLUGIN_HANDLED; 
}

public moveT_menu(id, g_PlayersMenu, item) { 
	if( item == MENU_EXIT ) 
	{ 
		menu_display(id, g_PlayersMenu);
		return PLUGIN_HANDLED; 
	} 
	
	remove_task(gCptT);
	new data[6], iName[64]; 
	new access, callback; 
	menu_item_getinfo(g_PlayersMenu, item, access, data,5, iName, 63, callback); 
	new tempid = str_to_num(data);
	new name[32];
	new g_bCptNm[64];
	get_user_name(gCptT, g_bCptNm, 63);
	get_user_name(tempid, name, 31);
	if(is_user_connected(tempid)){
		cs_set_user_team(tempid, CS_TEAM_T);
	}
	ClientPrintColor(0, "%s %L", Prefix, LANG_PLAYER, "CHOSEN_IN_TEAM_TERROR", name, g_bCptNm);
	menu_destroy(g_PlayersMenu);
	remove_task(gCptT);
	moveCT();
	return PLUGIN_HANDLED;
} 


public moveCT() {
	new title[64];
	formatex(title, charsmax(title), "%L", LANG_PLAYER, "CHOOSE_PLAYER");
	g_PlayersMenu = menu_create(title, "moveCT_menu"); 
	new players[32], pnum, tempid; 
	new CTplayers[32], CTpnum;
	new szName[32], szTempid[10]; 
	new pickisdone, check;
	
	get_players(players, pnum, "h"); 
	get_players(CTplayers, CTpnum, "he", "CT");
	
	for( new i; i<pnum; i++ ) 
	{ 
		tempid = players[i];
		
		if ((tempid == gCptT) || (tempid == gCptCT))
			check++;
		
		if (cs_get_user_team(tempid) == CS_TEAM_UNASSIGNED)
			continue;
		
		else if (cs_get_user_team(tempid) == CS_TEAM_SPECTATOR) {
			get_user_name(tempid, szName, 31); 
			num_to_str(tempid, szTempid, 9); 
			menu_additem(g_PlayersMenu, szName, szTempid);
			pickisdone++;
		}
	} 
	
	if (check != 2) {
		ClientPrintColor(0, "%s %L", Prefix, LANG_PLAYER, "CAPTAINS_DISCONNECTED");
		g_bCpt = false;
		set_task(3.0, "RandomTeams");
		return PLUGIN_HANDLED;
	}
	
	if (pickisdone == 0) {
		ClientPrintColor(0, "%s %L", Prefix, LANG_PLAYER, "TEAMS_ARE_SET");
		g_bCpt = false;
		set_task(10.0, "StartMatch");
		return PLUGIN_HANDLED;
	}
	
	if (CTpnum >= get_pcvar_num(PlayerAmount)/2 ) {
		ClientPrintColor(0, "%s %L", Prefix, LANG_PLAYER, "CT_TEAM_FULL");
		moveT();
		return PLUGIN_HANDLED;
	}
	
	menu_display(gCptCT, g_PlayersMenu);
	set_task(20.0, "kickhimout", gCptCT);
	return PLUGIN_HANDLED; 
}

public moveCT_menu(id, g_PlayersMenu, item) { 
	if( item == MENU_EXIT )  { 
		menu_display(id, g_PlayersMenu);
		return PLUGIN_HANDLED; 
	} 
	
	remove_task(gCptCT);
	new data[6], iName[64]; 
	new access, callback; 
	menu_item_getinfo(g_PlayersMenu, item, access, data,5, iName, 63, callback); 
	new tempid = str_to_num(data);
	new name[32];
	new g_bCptNm[64];
	get_user_name(gCptCT, g_bCptNm, 63);
	get_user_name(tempid, name, 31);
	if(is_user_connected(tempid)){
		cs_set_user_team(tempid, CS_TEAM_CT);
	}
	ClientPrintColor(0, "%s %L", Prefix, LANG_PLAYER, "CHOSEN_IN_TEAM_CT", name, g_bCptNm);
	menu_destroy(g_PlayersMenu);
	remove_task(gCptCT);
	moveT();
	return PLUGIN_HANDLED;
} 

public TeamsInfo() {
	if (g_bCpt) {
		new nameCT[70], nameT[70];
		new infoT[500];
		new infoCT[500];
		new players[32], pnum, tempid;
		new toapprove;
		
		get_players(players, pnum, "h");
		get_user_name(gCptT, nameT, 69);
		get_user_name(gCptCT, nameCT, 69);
		formatex(infoT, 499, "%L^n-------------^n%L^n^n", LANG_PLAYER, "TEAM_B", LANG_PLAYER, "TEAM_INFO_CAPTAINS", nameT);
		formatex(infoCT, 499, "%L^n-------------^n%L^n^n", LANG_PLAYER, "TEAM_A", LANG_PLAYER, "TEAM_INFO_CAPTAINS", nameCT);
		
		for (new i ; i < pnum ; i++)
		{
			tempid = players[i];
			
			if ((cs_get_user_team(tempid) == CS_TEAM_T) && (tempid != gCptT))
			{
				new nameofp[70];
				
				get_user_name(tempid, nameofp, 69);
				add(infoT, 499, nameofp);
				add(infoT, 499, "^n");
			}
			
			else if ((cs_get_user_team(tempid) == CS_TEAM_CT) && (tempid != gCptCT))
			{
				new nameofCTp[70];
				
				get_user_name(tempid, nameofCTp, 69);
				add(infoCT, 499, nameofCTp);
				add(infoCT, 499, "^n");
			}
			
			if ((cs_get_user_team(tempid) == CS_TEAM_T) && (tempid == gCptT))
				toapprove++;
			
			else if ((cs_get_user_team(tempid) == CS_TEAM_CT) && (tempid == gCptCT))
			{
				toapprove++;
			}
		}
		
		if (toapprove != 2) {
			set_hudmessage(255, 0, 0, 0.40, 0.32, 0, 6.0, 12.0);
			ShowSyncHudMsg(0, gMsgSyncCaptain, "%L", LANG_PLAYER, "CAPTAINS_DISCONNECTED_HUD");
			set_task(5.0, "RandomTeams");
			return PLUGIN_HANDLED;
		}
		
		set_hudmessage(27, 162, 229, 0.28, 0.32, 0, 6.0, 1.0);
		ShowSyncHudMsg(0, gMsgSyncTT, infoT);
		
		set_hudmessage(27, 162, 229, 0.58, 0.32, 0, 6.0, 1.0);
		ShowSyncHudMsg(0, gMsgSyncCT, infoCT);
		set_task(1.0, "TeamsInfo");
	}
	
	else
	{
		set_hudmessage(0, 255, 0, 0.40, 0.32, 0, 6.0, 12.0);
		ShowSyncHudMsg(0, gMsgSyncCaptain, "%L", LANG_PLAYER, "TEAMS_ARE_SET_HUD");
		return PLUGIN_CONTINUE;
	}
	
	return PLUGIN_CONTINUE;
}


public RandomTeams()
{
	new players[32], pnum, tempid;
	
	get_players(players, pnum, "h");
	
	for( new i; i<pnum; i++ ){
		tempid = players[i];
		
		switch ( cs_get_user_team( tempid ) ){
			
			case CS_TEAM_T, CS_TEAM_CT:{
				if(is_user_alive( tempid)){
					user_silentkill(tempid);
					cs_set_user_team(tempid, CS_TEAM_SPECTATOR);
				}
			}
		}
	}
	
	
	new topick, idop;
	
	while (AnyoneInSpec()) {
		if (cs_get_user_team(players[idop]) == CS_TEAM_UNASSIGNED)
		{
			idop++;
			continue;
		}
		
		topick = random(2);
		
		if (topick == 1)
		{
			cs_set_user_team(players[idop], CS_TEAM_T);
		}
		
		else
		{
			cs_set_user_team(players[idop], CS_TEAM_CT);
		}
		
		
		new pplayers[32], ppnum, tempid;
		new ppplayers[32], pppnum;
		new temppnum;
		
		get_players(players, pnum, "h");
		get_players(pplayers, ppnum, "he", "CT");
		get_players(ppplayers, pppnum, "he", "TERRORIST");
		
		if (ppnum == pnum/2)
		{
			get_players(players, temppnum, "h");
			
			for( new i; i<temppnum; i++ )
			{
				tempid = players[i];
				
				if (cs_get_user_team(tempid) == CS_TEAM_SPECTATOR)
				{
					cs_set_user_team(tempid, CS_TEAM_T);
				}
			}
		}
		
		else if (pppnum == pnum/2)
		{
			get_players(players, temppnum, "h");
			
			for( new i; i<temppnum; i++ )
			{
				tempid = players[i];
				
				if (cs_get_user_team(tempid) == CS_TEAM_SPECTATOR)
				{
					cs_set_user_team(tempid, CS_TEAM_CT);
				}
			}
		}
		
		idop++;
	}
	ClientPrintColor(0, "%s %L", Prefix, LANG_PLAYER, "TEAMS_RANDOMIZED");
	set_task(5.0, "StartMatch");
}

public AnyoneInSpec() {
	new players[32], pnum, tempid;
	get_players(players, pnum, "h");
	
	for( new i; i<pnum; i++ )
	{
		tempid = players[i];
		
		if (cs_get_user_team(tempid) == CS_TEAM_SPECTATOR)
			return true;
	}
	
	return false;
}
public OnCBasePlayer_TraceAttack(id, iAttacker, Float:flDamage, Float:fVecDir[3], ptr, bitsDamageType) { 
	if( IsPlayer(iAttacker) 
	&&  id != iAttacker 
	&&  is_user_alive(iAttacker) 
	&&  get_pdata_int(iAttacker, m_iTeam) == get_pdata_int(id, m_iTeam) 
	&&  get_pcvar_num(FriendlyFire)  ) { 
		new Float:flMirorDamage = get_pcvar_float(MirrorDamage); 
		if( flMirorDamage > 0 ) 
		{ 
			SetHamParamEntity(1, iAttacker); 
			SetHamParamFloat(3, flDamage * flMirorDamage); 
			// SetHamParamVector(4, Float:{0.0,0.0,0.0}) // try this one if you get strange blood directions 
			ClientPrintColor(0, "%s %L", Prefix, LANG_PLAYER, "MIRRORDAMAGE");
			return HAM_HANDLED;
		} 
	} 
	return HAM_IGNORED; 
} 
public checkPlayers() {
	for (new i = 1; i <= get_maxplayers(); i++) {
		if (is_user_alive(i) && is_user_connected(i) &&  !is_user_bot(i) && !is_user_hltv(i) && g_spawned[i] && IsStarted) {
			new newangle[3];
			get_user_origin(i, newangle);
			
			if ( newangle[0] == g_oldangles[i][0] && newangle[1]  == g_oldangles[i][1] && newangle[2] == g_oldangles[i][2] ) {
				g_afktime[i] += CHECK_FREQ;
				check_afktime(i);
				} else {
				g_oldangles[i][0] = newangle[0];
				g_oldangles[i][1] = newangle[1];
				g_oldangles[i][2] = newangle[2];
				g_afktime[i] = 0;
			}
		}
	}
	return PLUGIN_HANDLED;
}

check_afktime(id) {
	new maxafktime = get_pcvar_num(AfkTime);
	if (maxafktime < MIN_AFK_TIME) {
		log_amx("cvar mp_afktime %d is too low. Minimum value is  %i.", maxafktime, MIN_AFK_TIME);
		maxafktime = MIN_AFK_TIME;
		set_pcvar_num(AfkTime, MIN_AFK_TIME);
	}
	
	if ( maxafktime-WARNING_TIME <= g_afktime[id] <  maxafktime) {
		new timeleft = maxafktime - g_afktime[id];
		ClientPrintColor(0, "%s %L", Prefix, LANG_PLAYER, "AFK_MOVE", timeleft);
		} else if (g_afktime[id] > maxafktime) {
		new name[32];
		get_user_name(id, name, 31);
		ClientPrintColor(0, "%s %L", Prefix, LANG_PLAYER, "AFK_KICK",name, maxafktime );
		log_amx("%s was kicked for being AFK longer than %i  seconds", name, maxafktime);
		server_cmd("kick #%d ^"You were kicked for being AFK longer  than %i seconds^"", get_user_userid(id), maxafktime);
	}
}
public playerSpawned(id) {
	g_spawned[id] = false;
	new sid[1];
	sid[0] = id;
	set_task(0.75, "delayedSpawn",_, sid, 1);    // Give the player time  to drop to the floor when spawning
	return PLUGIN_HANDLED;
}

public delayedSpawn(sid[]) {
	get_user_origin(sid[0], g_oldangles[sid[0]]);
	g_spawned[sid[0]] = true;
	return PLUGIN_HANDLED;
}
ClientPrintColor( id, String[ ], any:... ){
	new szMsg[ 190 ];
	vformat( szMsg, charsmax( szMsg ), String, 3 );
	
	replace_all( szMsg, charsmax( szMsg ), "!n", "^1" );
	replace_all( szMsg, charsmax( szMsg ), "!t", "^3" );
	replace_all( szMsg, charsmax( szMsg ), "!g", "^4" );
	
	static msgSayText = 0;
	static fake_user;
	
	if( !msgSayText )
	{
		msgSayText = get_user_msgid( "SayText" );
		fake_user = get_maxplayers( ) + 1;
	}
	
	message_begin( id ? MSG_ONE_UNRELIABLE : MSG_BROADCAST, msgSayText, _, id );
	write_byte( id ? id : fake_user );
	write_string( szMsg );
	message_end( );
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1045\\ f0\\ fs16 \n\\ par }
*/
