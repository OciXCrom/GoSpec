#include <amxmodx>
#include <cromchat>
#include <cstrike>
#include <hamsandwich>

#define PLUGIN_VERSION "1.2"

enum _:Cvars
{
	gospec_spec_flag,
	gospec_change_flag,
	gospec_respawn
}

new g_eCvars[Cvars]

new CsTeams:g_iOldTeam[33],
	g_iSpecFlag,
	g_iChangeFlag

public plugin_init()
{
	register_plugin("GoSpec", PLUGIN_VERSION, "OciXCrom")
	register_cvar("@CRXGoSpec", PLUGIN_VERSION, FCVAR_SERVER|FCVAR_SPONLY|FCVAR_UNLOGGED)
	register_dictionary("GoSpec.txt")
	
	register_clcmd("say /spec", "GoSpec")
	register_clcmd("say /back", "GoBack")
	register_clcmd("say /change", "SwitchTeam")
	
	g_eCvars[gospec_spec_flag] = register_cvar("gospec_spec_flag", "e")
	g_eCvars[gospec_change_flag] = register_cvar("gospec_change_flag", "e")
	g_eCvars[gospec_respawn] = register_cvar("gospec_respawn", "0")
	CC_SetPrefix("[&x03GoSpec&x01]")
}

public plugin_cfg()
{
	new szFlag[2]
	get_pcvar_string(g_eCvars[gospec_spec_flag], szFlag, charsmax(szFlag))
	g_iSpecFlag = szFlag[0] == EOS ? ADMIN_ALL : read_flags(szFlag)
	get_pcvar_string(g_eCvars[gospec_change_flag], szFlag, charsmax(szFlag))
	g_iChangeFlag = szFlag[0] == EOS ? ADMIN_ALL : read_flags(szFlag)
}

public GoSpec(id)
{
	if(!HasAccess(id, g_iSpecFlag))
		return PLUGIN_HANDLED
	
	new CsTeams:iTeam = cs_get_user_team(id)
		
	if(iTeam == CS_TEAM_SPECTATOR)
		CC_SendMessage(id, "%L", id, "GOSPEC_ALREADY_SPECTATOR")
	else
	{
		g_iOldTeam[id] = iTeam
		cs_set_user_team(id, CS_TEAM_SPECTATOR)
		CC_SendMessage(id, "%L", id, "GOSPEC_NOW_SPECTATOR")
		
		if(is_user_alive(id))
			user_silentkill(id)
	}
	
	return PLUGIN_HANDLED
}

public GoBack(id)
{
	if(!HasAccess(id, g_iSpecFlag))
		return PLUGIN_HANDLED
		
	if(cs_get_user_team(id) != CS_TEAM_SPECTATOR)
		CC_SendMessage(id, "%L", id, "GOSPEC_NOT_SPECTATOR")
	else
	{
		new iPlayers[32], iCT, iT
		get_players(iPlayers, iCT, "e", "CT")
		get_players(iPlayers, iT, "e", "TERRORIST")
		
		if(iCT == iT)
		{
			cs_set_user_team(id, g_iOldTeam[id])
			CC_SendMessage(id, "%L", id, "GOSPEC_TRANSFERED_TO_PREVIOUS")
		}
		else
		{
			cs_set_user_team(id, iCT > iT ? CS_TEAM_T : CS_TEAM_CT)
			CC_SendMessage(id, "%L", id, "GOSPEC_TRANSFERED_TO_LESS")
		}
		
		if(get_pcvar_num(g_eCvars[gospec_respawn]))
			ExecuteHamB(Ham_CS_RoundRespawn, id)
	}		
	
	return PLUGIN_HANDLED
}

public SwitchTeam(id)
{
	if(!HasAccess(id, g_iChangeFlag))
		return PLUGIN_HANDLED
		
	new CsTeams:iTeam = cs_get_user_team(id)
		
		
	if(iTeam == CS_TEAM_SPECTATOR)
		CC_SendMessage(id, "%L", id, "GOSPEC_CANT_USE")
	else
	{
		cs_set_user_team(id, cs_get_user_team(id) == CS_TEAM_CT ? CS_TEAM_T : CS_TEAM_CT)
		CC_SendMessage(id, "%L", id, "GOSPEC_TRANSFERED_TO_OPPOSITE")
		
		if(is_user_alive(id))
		{
			user_silentkill(id)
			
			if(get_pcvar_num(g_eCvars[gospec_respawn]))
				ExecuteHamB(Ham_CS_RoundRespawn, id)
		}			
	}
	
	return PLUGIN_HANDLED
}

bool:HasAccess(id, iFlag)
{
	if(iFlag == ADMIN_ALL || get_user_flags(id) & iFlag)
		return true
	else
	{
		CC_SendMessage(id, "%L", id, "GOSPEC_NO_ACCESS")
		return false
	}
	
	#if AMXX_VERSION_NUM < 183
	return false
	#endif
}