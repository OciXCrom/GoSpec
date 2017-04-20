#include <amxmodx>
#include <cstrike>
#include <hamsandwich>

#define PLUGIN_VERSION "1.1"

enum _:Cvars
{
	gospec_spec_flag,
	gospec_change_flag,
	gospec_respawn
}

new g_eCvars[Cvars]

new const g_szPrefix[] = "^1[^3GoSpec^1]"

new CsTeams:g_iOldTeam[33],
	g_iSpecFlag,
	g_iChangeFlag,
	g_iSayText

public plugin_init()
{
	register_plugin("GoSpec", PLUGIN_VERSION, "OciXCrom")
	register_cvar("@CRXGoSpec", PLUGIN_VERSION, FCVAR_SERVER|FCVAR_SPONLY|FCVAR_UNLOGGED)
	
	register_clcmd("say /spec", "GoSpec")
	register_clcmd("say /back", "GoBack")
	register_clcmd("say /change", "SwitchTeam")
	
	g_eCvars[gospec_spec_flag] = register_cvar("gospec_spec_flag", "e")
	g_eCvars[gospec_change_flag] = register_cvar("gospec_change_flag", "e")
	g_eCvars[gospec_respawn] = register_cvar("gospec_respawn", "0")
	g_iSayText = get_user_msgid("SayText")
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
		ColorChat(id, "You are already a spectator!")
	else
	{
		g_iOldTeam[id] = iTeam
		cs_set_user_team(id, CS_TEAM_SPECTATOR)
		ColorChat(id, "You are now a spectator.")
		
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
		ColorChat(id, "You are not a spectator!")
	else
	{
		new iPlayers[32], iCT, iT
		get_players(iPlayers, iCT, "e", "CT")
		get_players(iPlayers, iT, "e", "TERRORIST")
		
		if(iCT == iT)
		{
			cs_set_user_team(id, g_iOldTeam[id])
			ColorChat(id, "You have been transfered back to your previous team.")
		}
		else
		{
			cs_set_user_team(id, iCT > iT ? CS_TEAM_T : CS_TEAM_CT)
			ColorChat(id, "You have been transfered to the team with less players.")
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
		ColorChat(id, "You can't use this command while a spectator.")
	else
	{
		cs_set_user_team(id, cs_get_user_team(id) == CS_TEAM_CT ? CS_TEAM_T : CS_TEAM_CT)
		ColorChat(id, "You have been transfered to the opposite team.")
		
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
		ColorChat(id, "You have no access to this command!")
		return false
	}
}

ColorChat(const id, const szInput[], any:...)
{
	new iPlayers[32], iCount = 1
	static szMessage[191]
	vformat(szMessage, charsmax(szMessage), szInput, 3)
	format(szMessage[0], charsmax(szMessage), "%s %s", g_szPrefix, szMessage)
	
	replace_all(szMessage, charsmax(szMessage), "!g", "^4")
	replace_all(szMessage, charsmax(szMessage), "!n", "^1")
	replace_all(szMessage, charsmax(szMessage), "!t", "^3")
	
	if(id)
		iPlayers[0] = id
	else
		get_players(iPlayers, iCount, "ch")
	
	for(new i; i < iCount; i++)
	{
		if(is_user_connected(iPlayers[i]))
		{
			message_begin(MSG_ONE_UNRELIABLE, g_iSayText, _, iPlayers[i])
			write_byte(iPlayers[i])
			write_string(szMessage)
			message_end()
		}
	}
}