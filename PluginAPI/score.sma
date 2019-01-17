/*
*
*	Thats version edited by Alghtryer <alghtryer.github.io> for GATHER SYSTEM <alghtryer.github.io/gather>
*
*	Original version: https://forums.alliedmods.net/showpost.php?p=2612753&postcount=4
*
*/

#include <amxmodx>
#include <fakemeta> 
#include <hamsandwich>
#include <gather>

#define PLUGIN "No Score Reset on Half"
#define VERSION "1.0"
#define AUTHOR "EFFx"

enum dData{
	iFrags,
	iDeaths
}

new g_iUserData[33][dData], bool:g_bCanSet[33]

const m_iDeaths =        444

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	RegisterHam(Ham_Spawn, "player", "ham_PlayerSpawn_Post", 1)
	
	register_event("TextMsg","EventRestart","a","2&#Game_w")
}

public ham_PlayerSpawn_Post(id)
{
	if(g_bCanSet[id] && is_user_alive(id))
	{
		updateScore(id)
	}
}

public EventRestart(){
	if(SecondHalf()){
		new iPlayers[32], iNum
		get_players(iPlayers, iNum)
		if(!iNum)
			return
		
		for(new i, id;i < iNum;i++)
		{
			id = iPlayers[i]
			
			g_bCanSet[id] = true
			
			g_iUserData[id][iFrags] = get_user_frags(id)
			g_iUserData[id][iDeaths] = get_user_deaths(id)
		}
	}
}  

updateScore(id){
	g_bCanSet[id] = false
	
	set_pdata_int(id, m_iDeaths, g_iUserData[id][iDeaths]) 
	ExecuteHam(Ham_AddPoints, id, g_iUserData[id][iFrags], true)
}  
