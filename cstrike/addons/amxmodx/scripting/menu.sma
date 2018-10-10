/*
*
*	Thats plugin made for GATHER SYSTEM <https://alghtryer.github.io/Gather/> by Alghtryer <alghtryer.github.io> 
*
*/

#include <amxmodx> 
#include <cstrike> 

new PLUGIN[]  = "Players Menu - Gather System";
new AUTHOR[]  = "Alghtryer";
new VERSION[] = "1.0";

#pragma semicolon 1

#define OWNER_FLAG ADMIN_RCON

const AdminFlags = ( ADMIN_BAN | ADMIN_KICK );

#define IsUserAdmin(%1)    ((get_user_flags(%1)&AdminFlags)==AdminFlags)

/* VOTEBAN */
#define MAX_PLAYERS 33

#define MENU_KEYS (1<<0 | 1<<1 | 1<<2 | 1<<3 | 1<<4 | 1<<5 | 1<<6 | 1<<7 | 1<<8 | 1<<9)
#define MENU_SLOTS 8

new g_iMenuPage[MAX_PLAYERS];
new g_iVotedPlayers[MAX_PLAYERS];
new g_iVotes[MAX_PLAYERS];
new g_szVoteReason[MAX_PLAYERS][64];

new g_iPlayers[MAX_PLAYERS - 1];
new g_iNum;

enum {
	CVAR_PERCENT = 0,
	CVAR_BANTYPE,
	CVAR_BANTIME
};
new g_szCvarName[][] = {
	"voteban_percent",
	"voteban_type",
	"voteban_time"
};
new g_szCvarValue[][] = {
	"60",
	"1",
	"100"
};
new g_iPcvar[3];
new g_szLogFile[64];

/* VOTEBAN */

new g_iTarget[33];
new const UrlFile[ ] = "GatherMotd.txt";

new gAdmin;
new bool:plrRtv[33];
new RtvCount;
new RtvAmount;

new CvarPrefix;
new Prefix[32];
new CaptainMenu;

public plugin_init() { 

	register_plugin
	(
		PLUGIN,		//: Players Menu - Gather System
		VERSION,	//: 1.0
		AUTHOR		//: Alghtryer
	);

	register_clcmd("menu", "player"); 
	register_clcmd("chooseteam", "handled");
	register_clcmd("jointeam", "handled"); 
	
	RtvAmount 		= register_cvar("gs_rtv_amount","7");
	CvarPrefix 		= get_cvar_pointer("gs_prefix"); 
	CaptainMenu		= get_cvar_pointer("gs_captainmenu");
	
	get_pcvar_string( CvarPrefix, Prefix, charsmax( Prefix ) );
	
	register_clcmd("_voteban_reason", "Cmd_VoteBanReason", -1, "");
	register_clcmd("PrivateMessage", "cmd_player");
	
	register_menucmd(register_menuid("\rVOTEBAN \yMenu:"), MENU_KEYS, "Menu_VoteBan");
	
	for(new i = 0 ; i < 3 ; i++)
	{
		g_iPcvar[i] = register_cvar(g_szCvarName[i], g_szCvarValue[i]);
	}
	
	new szLogInfo[] = "amx_logdir";
	get_localinfo(szLogInfo, g_szLogFile, charsmax(g_szLogFile));
	add(g_szLogFile, charsmax(g_szLogFile), "/voteban");
	
	if(!dir_exists(g_szLogFile))
		mkdir(g_szLogFile);
	
	new szTime[32];
	get_time("%d-%m-%Y", szTime, charsmax(szTime));
	format(g_szLogFile, charsmax(g_szLogFile), "%s/%s.log", g_szLogFile, szTime);

} 
public handled(id) { 
	if ( cs_get_user_team(id) == CS_TEAM_UNASSIGNED ) 
		return PLUGIN_CONTINUE;
	
	player(id); 
	return PLUGIN_HANDLED; 
} 
public player( id ) 
{ 
	if(get_pcvar_num(CaptainMenu)) 
	{
		new szText[128];
		formatex( szText, charsmax( szText ), "%L", LANG_PLAYER, "CHOOSE_MENU_NAME" );
		new menu = menu_create( szText, "menu_handler" );
		formatex( szText, charsmax( szText ), "%L", LANG_PLAYER, "CHOOSE_MENU_ITEM_1" );
		menu_additem( menu, szText);
		formatex( szText, charsmax( szText ), "%L", LANG_PLAYER, "CHOOSE_MENU_ITEM_2" );
		menu_additem( menu, szText);
		formatex( szText, charsmax( szText ), "%L", LANG_PLAYER, "CHOOSE_MENU_ITEM_3" );
		menu_additem( menu, szText);
		formatex( szText, charsmax( szText ), "%L", LANG_PLAYER, "CHOOSE_MENU_ITEM_4" );
		menu_additem( menu, szText);
		formatex( szText, charsmax( szText ), "%L", LANG_PLAYER, "CHOOSE_MENU_ITEM_5" );
		menu_additem( menu, szText);
		
		menu_setprop( menu, MPROP_EXIT, MEXIT_ALL ); 
	
		menu_display( id, menu); 
	
	} 
}

public menu_handler(id, menu, item) 
{ 
	switch( item ) 
	{ 
		case 0: 
		{ 
			Motd(id); 
		} 
		case 1: 
		{ 
			cmdPMMenu(id);
		} 
		case 2: 
		{ 
			if(gAdmin == 0){ 
				Rtv(id); 
			}
			else
			{ 
				ClientPrintColor( id,  "%s %L", Prefix, LANG_PLAYER, "VOTE_DISABLE" );
			}
		} 
		case 3: 
		{ 
			if(gAdmin == 0)
			{ 
				Cmd_VoteBan(id); 
			}
			else
			{ 
				ClientPrintColor( id,  "%s %L", Prefix, LANG_PLAYER, "VOTE_DISABLE" );
			}
		} 
		case 4: 
		{ 
			ClientPrintColor( id,  "%s %L", Prefix, LANG_PLAYER, "ADMIN_COMMANDS_1" );
			ClientPrintColor( id,  "%s %L", Prefix, LANG_PLAYER, "ADMIN_COMMANDS_2" );
			ClientPrintColor( id,  "%s %L", Prefix, LANG_PLAYER, "ADMIN_COMMANDS_3" );
			ClientPrintColor( id,  "%s %L", Prefix, LANG_PLAYER, "ADMIN_COMMANDS_4" );
			ClientPrintColor( id,  "%s %L", Prefix, LANG_PLAYER, "ADMIN_COMMANDS_5" );	
		} 
	} 
	menu_destroy( menu ); 
	return PLUGIN_HANDLED;
}  
public Motd(id)
{
	show_motd( id , UrlFile );
	
	return 1;
}
public client_putinserver(id)
{
	if(IsUserAdmin(id))
		gAdmin++;
}
public client_disconnect(id)
{
	if(IsUserAdmin(id))
		gAdmin--;
	
	if(plrRtv[id])
		RtvCount--;
	plrRtv[id] = false;
	
	if(g_iVotedPlayers[id])
	{
		get_players(g_iPlayers, g_iNum, "h");
		
		for(new i = 0 ; i < g_iNum ; i++)
		{
			if(g_iVotedPlayers[id] & (1 << g_iPlayers[i]))
			{
				g_iVotes[g_iPlayers[i]]--;
			}
		}
		g_iVotedPlayers[id] = 0;
	}
}

public Cmd_VoteBan(id)
{
	get_players(g_iPlayers, g_iNum, "h");
	
	if(g_iNum < 3)
	{
		ClientPrintColor(id, "%s %L", Prefix, LANG_PLAYER, "UNAVAILABLE_PLAYER" );
		return PLUGIN_HANDLED;
	}
	ShowBanMenu(id, g_iMenuPage[id] = 0);
	return PLUGIN_CONTINUE;
}

public ShowBanMenu(id, iPos)
{
	static i, iPlayer, szName[32];
	static szMenu[256], iCurrPos; iCurrPos = 0;
	static iStart, iEnd; iStart = iPos * MENU_SLOTS;
	static iKeys;
	
	get_players(g_iPlayers, g_iNum, "h");
	
	if(iStart >= g_iNum)
	{
		iStart = iPos = g_iMenuPage[id] = 0;
	}
	
	static iLen;
	iLen = formatex(szMenu, charsmax(szMenu), "\rVOTEBAN \yMenu:^n^n");
	
	iEnd = iStart + MENU_SLOTS;
	iKeys = MENU_KEY_0;
	
	if(iEnd > g_iNum)
	{
		iEnd = g_iNum;
	}
	
	for(i = iStart ; i < iEnd ; i++)
	{
		iPlayer = g_iPlayers[i];
		get_user_name(iPlayer, szName, charsmax(szName));
		
		iKeys |= (1 << iCurrPos++);
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r%d\w.%s \d(\r%d%%\d)^n", iCurrPos, szName, get_percent(g_iVotes[iPlayer], g_iNum));
	}
	
	if(iEnd != g_iNum)
	{
		formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r9\w.Next ^n\r0\w.%s", iPos ? "Back" : "Exit");
		iKeys |= MENU_KEY_9;
	}
	else
	{
		formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r0\w.%s", iPos ? "Back" : "Exit");
	}
	show_menu(id, iKeys, szMenu, -1, "");
	return PLUGIN_HANDLED;
}

public Menu_VoteBan(id, key)
{
	switch(key)
	{
		case 8:
		{
			ShowBanMenu(id, ++g_iMenuPage[id]);
		}
		case 9:
		{
			if(!g_iMenuPage[id])
				return PLUGIN_HANDLED;
			
			ShowBanMenu(id, --g_iMenuPage[id]);
		}
		default: {
			static iPlayer;
			iPlayer = g_iPlayers[g_iMenuPage[id] * MENU_SLOTS + key];
			
			if(!is_user_connected(iPlayer))
			{
				ShowBanMenu(id, g_iMenuPage[id]);
				return PLUGIN_HANDLED;
			}
			if(iPlayer == id)
			{
				ClientPrintColor(id, "%s %L", Prefix, LANG_PLAYER, "CANNOT_YOURSELF" );
				ShowBanMenu(id, g_iMenuPage[id]);
				
				return PLUGIN_HANDLED;
			}
			if(g_iVotedPlayers[id] & (1 << iPlayer))
			{
				ClientPrintColor(id, "%s %L", Prefix, LANG_PLAYER, "ALREADY_VOTE" );
				ShowBanMenu(id, g_iMenuPage[id]);
				
				return PLUGIN_HANDLED;
			}
			g_iVotes[iPlayer]++;
			g_iVotedPlayers[id] |= (1 << iPlayer);
			
			static szName[2][32];
			get_user_name(id, szName[0], charsmax(szName[]));
			get_user_name(iPlayer, szName[1], charsmax(szName[]));
			
			ClientPrintColor(0, "%s %L", Prefix, LANG_PLAYER, "VOTEBAN" , szName[0], szName[1]);
			
			CheckVotes(iPlayer, id);
			client_cmd(id, "messagemode _voteban_reason");
			
			ShowBanMenu(id, g_iMenuPage[id]);
		}
	}
	return PLUGIN_HANDLED;
}

public Cmd_VoteBanReason(id)
{
	if(!g_iVotedPlayers[id])
		return PLUGIN_HANDLED;
	
	new szArgs[64];
	read_argv(1, szArgs, charsmax(szArgs));
	
	if(szArgs[0])
	{
		formatex(g_szVoteReason[id], charsmax(g_szVoteReason[]), szArgs);
	}
	return PLUGIN_HANDLED;
}

public CheckVotes(id, voter)
{
	get_players(g_iPlayers, g_iNum, "h");
	new iPercent = get_percent(g_iVotes[id], g_iNum);
	
	if(iPercent >= get_pcvar_num(g_iPcvar[CVAR_PERCENT]))
	{
		switch(get_pcvar_num(g_iPcvar[CVAR_BANTYPE]))
		{
			case 1:
			{
				new szAuthid[32];
				get_user_authid(id, szAuthid, charsmax(szAuthid));
				server_cmd("kick #%d;wait;wait;wait;banid %d ^"%s^";wait;wait;wait;writeid", get_user_userid(id), get_pcvar_num(g_iPcvar[CVAR_BANTIME]), szAuthid);
			}
			case 2:
			{
				new szIp[32];
				get_user_ip(id, szIp, charsmax(szIp), 1);
				server_cmd("kick #%d;wait;wait;wait;addip %d ^"%s^";wait;wait;wait;writeip", get_user_userid(id), get_pcvar_num(g_iPcvar[CVAR_BANTIME]), szIp);
			}
		}
		g_iVotes[id] = 0;
		
		new szName[2][32];
		get_user_name(id, szName[0], charsmax(szName[]));
		get_user_name(id, szName[1], charsmax(szName[]));
		ClientPrintColor(0, "%s %L", Prefix, LANG_PLAYER, "BAN_VOTEBAN" , szName[0], get_pcvar_num(g_iPcvar[CVAR_BANTIME]));
		log_to_file(g_szLogFile, "Player '%s' voted for banning '%s' for: %s", szName[1], szName[0], g_szVoteReason[voter]);
	}
}

stock get_percent(value, tvalue)
{     
	return floatround(floatmul(float(value) / float(tvalue) , 100.0));
}
public cmdPMMenu(id)
{
	new menu = menu_create("\yPrivate Message \wMenu", "handlePMMEnu");
	
	new players[32], num;
	new szName[32], szTempid[32];
	
	get_players(players, num, "ch");
	
	for(new i; i < num; i++)
	{
		get_user_name(players[i], szName, charsmax(szName));
		
		num_to_str(get_user_userid(players[i]), szTempid, charsmax(szTempid));
		
		menu_additem(menu, szName, szTempid, 0);
	}
	
	menu_display(id, menu);
}

public handlePMMEnu(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}
	
	new szData[6], szName[64], iAccess, iCallback;
	menu_item_getinfo(menu, item, iAccess, szData, charsmax(szData), szName, charsmax(szName), iCallback);
	
	g_iTarget[id] = find_player("k", str_to_num(szData));
	
	client_cmd(id, "messagemode PrivateMessage");
	
	menu_destroy(menu);
	return PLUGIN_HANDLED;
}

public cmd_player(id)
{
	new say[300];
	read_args(say, charsmax(say));
	remove_quotes(say);
	
	if(!strlen(say))
		return PLUGIN_HANDLED;
	
	new szSenderName[32], szReceiverName[32];
	get_user_name(id, szSenderName, charsmax(szSenderName));
	get_user_name(g_iTarget[id], szReceiverName, charsmax(szReceiverName));
	
	ClientPrintColor(id, "%s PM To %s: %s", Prefix, szReceiverName, say);
	ClientPrintColor(g_iTarget[id], "%s PM From %s: %s", Prefix, szSenderName, say);
	
	/*for(new i = 1; i < get_maxplayers(); i++ )
		if(is_user_connected(i) && IsUserAdmin(i))
	{
		ClientPrintColor(i,"%s PM from %s To %s:", Prefix, szSenderName, szReceiverName);
		ClientPrintColor(i, "%s", say);
	}*/      
	
	return PLUGIN_CONTINUE;
} 
public Rtv(id)
{
	if(!plrRtv[id])
	{
		plrRtv[id] = true;
		RtvCount++;
		ClientPrintColor(id, "%s %L", Prefix, LANG_PLAYER, "RTV" , RtvCount, get_pcvar_num(RtvAmount));
	}
	
	
	if(RtvCount == get_pcvar_num(RtvAmount))
	{
		set_task(10.0,"restart");
		ClientPrintColor(id, "%s %L", Prefix, LANG_PLAYER, "RTV_RESTART" );
	}
	return PLUGIN_HANDLED;
}

public restart()
{
	server_cmd("restart");  
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
