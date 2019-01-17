/*
*	Info: Respawn before match start.
*
*	Thats version edited by Alghtryer <alghtryer.github.io> for GATHER SYSTEM <alghtryer.github.io/gather>
*
*	Original version: https://forums.alliedmods.net/showpost.php?p=2336192&postcount=2
*
*/

#include <amxmodx>
#include <amxmisc>
#include <hamsandwich>
#include <cstrike>
#include <gather>

new PLUGIN[] = "Auto Respawn";
new AUTHOR[] = "Hartmann";
new VERSION[] = "1.0";

#pragma semicolon 1

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	register_cvar( "arw_version", VERSION, FCVAR_SERVER | FCVAR_SPONLY);
	RegisterHam(Ham_Killed, "player", "PlayerKilled", 1);
	register_event( "TeamInfo", "join_team", "a");
}
public PlayerKilled(Victim){
	if(g_bStart()){
		if (!is_user_alive(Victim))
			set_task(1.0, "PlayerRespawn", Victim);
	}
	return PLUGIN_HANDLED;
}
public PlayerRespawn(id){
	if(g_bStart()){
		if (!is_user_alive(id) && CS_TEAM_T <= cs_get_user_team(id) <= CS_TEAM_CT )
		{
			ExecuteHamB(Ham_CS_RoundRespawn, id);
		}
	}
	return PLUGIN_HANDLED;
}
public join_team()
{
	if(g_bStart()){
		new Client = read_data(1); 
		static user_team[32]; 
		
		read_data(2, user_team, 31); 
		
		if(!is_user_connected(Client)) 
			return PLUGIN_HANDLED; 
		
		switch(user_team[0]) 
		{
			case 'C':  
			{
				if(!is_user_alive(Client))
					set_task(1.0,"spawnning",Client);
			}
			
			case 'T':
			{ 
				if(!is_user_alive(Client))
					set_task(1.0,"spawnning",Client); 
			}
			
			case 'S':  
			{
				client_print(Client, print_chat, "You have to join CT or Terrorist to respawn");
			}
		}
		return 0;
	}
	return PLUGIN_HANDLED;
}
public spawnning(Client) {
	ExecuteHamB(Ham_CS_RoundRespawn, Client);
	client_print(Client, print_chat, "You have been respawned");
	remove_task(Client);
}
public client_disconnect(id){
	remove_task(id);
	return PLUGIN_HANDLED;
}
