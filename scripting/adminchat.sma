#include <amxmodx>
#include <amxmisc>

#if AMXX_VERSION_NUM < 183
	#include <dhudmessage>
#endif

#define PLUGIN_NAME 
#define PLUGIN_VERSION "3.1"

#define SAY_ALL '#'											/* The symbol used for executing amx_say through default chat */
#define SAY_HUD '@'											/* The symbol used for sending a HUD message through default chat */
#define SAY_DHUD '&'										/* The symbol used for sending a DHUD message through default chat */
#define TSAY_ADMIN '@'										/* The symbol used for accessing the admin chat through team chat */
#define TSAY_VIPCHAT '!'									/* The symbol used for accessing the VIP chat through team chat */
#define TSAY_PRIVATE '#'									/* The symbol used for sending a private message through team chat */
#define TSAY_TEAMSAY '&'									/* The symbol used for sending a message to a specific team */
#define HUD_BLINK "$"										/* The symbol used for applying a blink effect to a (D)HUD message */
#define HUD_TYPEWRITER "#"									/* The symbol used for applying a typewriter effect to a (D)HUD message */

/* These symbols are used for different colors in chat messages [don't touch the second ones (^4/^3/^1)] */
new const g_szColors[][] = {
	"!g", "^4",
	"!t", "^3",
	"!n", "^1"
}

/* These commands are used when the SAY_HUD symbol is entered X times in normal chat */
new const g_szChatHud[][] = { "amx_tsay", "amx_csay", "amx_bsay", "amx_rsay" }

new g_szHudColors[][] = {"default", "random", "white", "red", "green", "blue", "yellow", "magenta", "cyan", "orange", "ocean", "maroon"}
new g_iHudValues[][] = {{0, 0, 0}, {0, 0, 0}, {255, 255, 255}, {255, 0, 0}, {0, 255, 0}, {0, 0, 255}, {255, 255, 0}, {255, 0, 255}, {0, 255, 255}, {227, 96, 8}, {45, 89, 116}, {103, 44, 38}}
new Float:g_flPositions[][] = {{-1.0, 0.7}, {-1.0, 0.1}, {0.75, 0.55}, {0.05, 0.55}}
new g_msgSayText, g_msgTeamInfo, g_iMaxPlayers
new g_iMessageChannel

enum _:Settings
{
	bool:stgAnonymous,
	Float:stgHudTime,
	stgHudDefault[16],
	stgAdminPrefix[32],
	stgVipPrefix[32],
	stgPlayerPrefix[32],
	stgServerName[32],
	stgSymAnonymous[8],
	stgPsaySound[64],
	stgTeamT[32],
	stgTeamCT[32],
	stgTeamSpec[32]
}

enum _:Messages
{
	msgSay[192],
	msgAsay[192],
	msgChat[192],
	msgPsay[192],
	msgTeamSay[192],
	msgHsay[192]
}

enum _:Colors
{
	clrSay,
	clrAsay,
	clrChat,
	clrPsay,
	clrTeamSay
}

enum _:Flags
{
	flagAdmin[2],
	flagPsay[2],
	flagReadAdmin[2],
	flagReadVip[2],
	flagAnonymous[2]
}

new g_eSettings[Settings]
new g_eMessages[Messages]
new g_eAMessages[Messages]
new g_eColors[Colors]
new g_eFlags[Flags]

#define X 0
#define Y 1
#define R 0
#define G 1
#define B 2

enum
{
	SECTION_SETTINGS = 1,
	SECTION_FLAGS,
	SECTION_MESSAGES
}

enum
{
	CMD_BSAY,
	CMD_CSAY,
	CMD_RSAY,
	CMD_TSAY
}

enum Color
{
	NORMAL = 1, // clients scr_concolor cvar color
	GREEN, // Green Color
	TEAM_COLOR, // Red, grey, blue
	GREY, // grey
	RED, // Red
	BLUE, // Blue
}

new TeamName[][] = 
{
	"",
	"TERRORIST",
	"CT",
	"SPECTATOR"
}

public plugin_init()
{
	register_plugin("OciXCrom's Admin Chat", PLUGIN_VERSION, "OciXCrom")
	register_cvar("CRXAdminChat", PLUGIN_VERSION, FCVAR_SERVER|FCVAR_SPONLY|FCVAR_UNLOGGED)
	
	register_clcmd("say", "hookSay")
	register_clcmd("say_team", "hookSayTeam")
	
	register_concmd("amx_say", "cmdSay", ADMIN_CHAT, "<message> -- Sends a message to all players")
	register_concmd("amx_asay", "cmdAsay", ADMIN_ALL, "<message> -- Sends a message to all admins")
	register_concmd("amx_chat", "cmdChat", ADMIN_CHAT, "<message> -- Sends a message to all VIP users")
	register_concmd("amx_psay", "cmdPsay", ADMIN_CHAT, "<player> <message> -- Sends a private message to a player")
	register_concmd("amx_teamsay", "cmdTeamSay", ADMIN_BAN, "<team> <message> -- Sends a message to a specific team")
	
	register_concmd("amx_bsay", "cmdHsay", ADMIN_CHAT, "<color> <message> -- Sends a bottom HUD message to all players")
	register_concmd("amx_bsay2", "cmdHsay", ADMIN_CHAT, "<color> <message> -- Sends a bottom HUD message to all players")
	register_concmd("amx_csay", "cmdHsay", ADMIN_CHAT, "<color> <message> -- Sends a top HUD message to all players")
	register_concmd("amx_csay2", "cmdHsay", ADMIN_RCON, "<color> <message> -- Sends a top DHUD message to all players")
	register_concmd("amx_rsay", "cmdHsay", ADMIN_CHAT, "<color> <message> -- Sends a right sided HUD message to all players")
	register_concmd("amx_rsay2", "cmdHsay", ADMIN_RCON, "<color> <message> -- Sends a right sided DHUD message to all players")
	register_concmd("amx_tsay", "cmdHsay", ADMIN_CHAT, "<color> <message> -- Sends a left HUD message to all players")
	register_concmd("amx_tsay2", "cmdHsay", ADMIN_RCON, "<color> <message> -- Sends a left DHUD message to all players")
	
	g_msgSayText = get_user_msgid("SayText")
	g_msgTeamInfo = get_user_msgid("TeamInfo")
	g_iMaxPlayers = get_maxplayers()
}

fileRead()
{
	new szFilename[256], szConfigsName[256]
	get_configsdir(szConfigsName, charsmax(szConfigsName))
	formatex(szFilename, charsmax(szFilename), "%s/AdminChat.ini", szConfigsName)
	new iFilePointer = fopen(szFilename, "rt")
	
	if(iFilePointer)
	{
		new szData[163], szOption[32], szSign[3], szValue[128], iSection
		
		while(!feof(iFilePointer))
		{
			fgets(iFilePointer, szData, charsmax(szData))
			trim(szData)
			
			switch(szData[0])
			{
				case EOS, ';': continue
				case '[':
				{
					if(szData[strlen(szData) - 1] == ']')
					{
						if(containi(szData, "settings") != -1)
							iSection = SECTION_SETTINGS
						else if(containi(szData, "flags") != -1)
							iSection = SECTION_FLAGS
						else if(containi(szData, "messages") != -1)
							iSection = SECTION_MESSAGES
					}
					else continue
				}
				default:
				{
					parse(szData, szOption, charsmax(szOption), szSign, charsmax(szSign), szValue, charsmax(szValue))
					
					switch(iSection)
					{
						case SECTION_SETTINGS:
						{
							if(equal(szOption, "AC_ANONYMOUS"))
								g_eSettings[stgAnonymous] = str_to_num(szValue) ? true : false
							else if(equal(szOption, "AC_HUDTIME"))
								g_eSettings[stgHudTime] = _:str_to_float(szValue)
							else if(equal(szOption, "AC_HUDDEFAULT"))
								copy(g_eSettings[stgHudDefault], charsmax(g_eSettings[stgHudDefault]), szValue)
							else if(equal(szOption, "AC_ADMINPREFIX"))
								copy(g_eSettings[stgAdminPrefix], charsmax(g_eSettings[stgVipPrefix]), szValue)
							else if(equal(szOption, "AC_VIPPREFIX"))
								copy(g_eSettings[stgVipPrefix], charsmax(g_eSettings[stgVipPrefix]), szValue)
							else if(equal(szOption, "AC_PLAYERPREFIX"))
								copy(g_eSettings[stgPlayerPrefix], charsmax(g_eSettings[stgPlayerPrefix]), szValue)
							else if(equal(szOption, "AC_SERVERNAME"))
								copy(g_eSettings[stgServerName], charsmax(g_eSettings[stgServerName]), szValue)
							else if(equal(szOption, "AC_SYM_ANONYMOUS"))
								copy(g_eSettings[stgSymAnonymous], charsmax(g_eSettings[stgSymAnonymous]), szValue)
							else if(equal(szOption, "AC_PSAY_SOUND"))
								copy(g_eSettings[stgPsaySound], charsmax(g_eSettings[stgPsaySound]), szValue)
							else if(equal(szOption, "AC_TEAM_TT"))
								copy(g_eSettings[stgTeamT], charsmax(g_eSettings[stgTeamT]), szValue)
							else if(equal(szOption, "AC_TEAM_CT"))
								copy(g_eSettings[stgTeamCT], charsmax(g_eSettings[stgTeamCT]), szValue)
							else if(equal(szOption, "AC_TEAM_SPEC"))
								copy(g_eSettings[stgTeamSpec], charsmax(g_eSettings[stgTeamSpec]), szValue)
						}
						case SECTION_FLAGS:
						{
							if(equal(szOption, "AC_FLAG_ADMIN"))
								copy(g_eFlags[flagAdmin], charsmax(g_eFlags[flagAdmin]), szValue)
							else if(equal(szOption, "AC_FLAG_PSAY"))
								copy(g_eFlags[flagPsay], charsmax(g_eFlags[flagPsay]), szValue)
							else if(equal(szOption, "AC_FLAG_READ_ADMIN"))
								copy(g_eFlags[flagReadAdmin], charsmax(g_eFlags[flagReadAdmin]), szValue)
							else if(equal(szOption, "AC_FLAG_READ_VIP"))
								copy(g_eFlags[flagReadVip], charsmax(g_eFlags[flagReadVip]), szValue)
							else if(equal(szOption, "AC_FLAG_ANONYMOUS"))
								copy(g_eFlags[flagAnonymous], charsmax(g_eFlags[flagAnonymous]), szValue)
						}
						case SECTION_MESSAGES:
						{
							if(equal(szOption, "AC_MSG_SAY"))
								copy(g_eMessages[msgSay], charsmax(g_eMessages[msgSay]), szValue)
							else if(equal(szOption, "AC_AMSG_SAY"))
								copy(g_eAMessages[msgSay], charsmax(g_eAMessages[msgSay]), szValue)
							else if(equal(szOption, "AC_CLR_SAY"))
								g_eColors[clrSay] = str_to_num(szValue)
							else if(equal(szOption, "AC_MSG_ASAY"))
								copy(g_eMessages[msgAsay], charsmax(g_eMessages[msgAsay]), szValue)
							else if(equal(szOption, "AC_AMSG_ASAY"))
								copy(g_eAMessages[msgAsay], charsmax(g_eAMessages[msgAsay]), szValue)
							else if(equal(szOption, "AC_CLR_ASAY"))
								g_eColors[clrAsay] = str_to_num(szValue)
							else if(equal(szOption, "AC_MSG_CHAT"))
								copy(g_eMessages[msgChat], charsmax(g_eMessages[msgChat]), szValue)
							else if(equal(szOption, "AC_AMSG_CHAT"))
								copy(g_eAMessages[msgChat], charsmax(g_eAMessages[msgChat]), szValue)	
							else if(equal(szOption, "AC_CLR_CHAT"))
								g_eColors[clrChat] = str_to_num(szValue)
							else if(equal(szOption, "AC_MSG_PSAY"))
								copy(g_eMessages[msgPsay], charsmax(g_eMessages[msgPsay]), szValue)
							else if(equal(szOption, "AC_AMSG_PSAY"))
								copy(g_eAMessages[msgPsay], charsmax(g_eAMessages[msgPsay]), szValue)
							else if(equal(szOption, "AC_CLR_PSAY"))
								g_eColors[clrPsay] = str_to_num(szValue)
							else if(equal(szOption, "AC_MSG_TEAMSAY"))
								copy(g_eMessages[msgTeamSay], charsmax(g_eMessages[msgTeamSay]), szValue)
							else if(equal(szOption, "AC_AMSG_TEAMSAY"))
								copy(g_eAMessages[msgTeamSay], charsmax(g_eAMessages[msgTeamSay]), szValue)
							else if(equal(szOption, "AC_CLR_TEAMSAY"))
								g_eColors[clrTeamSay] = str_to_num(szValue)
							else if(equal(szOption, "AC_MSG_HSAY"))
								copy(g_eMessages[msgHsay], charsmax(g_eMessages[msgHsay]), szValue)
							else if(equal(szOption, "AC_AMSG_HSAY"))
								copy(g_eAMessages[msgHsay], charsmax(g_eAMessages[msgHsay]), szValue)
						}
						default: continue
					}							
				}
			}
		}
		
		fclose(iFilePointer)
	}
}  

public hookSay(id)
{
	new szMessage[192]
	read_args(szMessage, charsmax(szMessage))
	remove_quotes(szMessage)
	
	switch(szMessage[0])
	{
		case SAY_ALL:
		{
			szMessage[0] = ' '
			trim(szMessage)
			client_cmd(id, "amx_say %s", szMessage)
		}
		case SAY_HUD, SAY_DHUD:
		{
			new szColor[16], iType, iColor, iSymbol = szMessage[0]
			szMessage[0] = ' '
			
			for(new i = 1; i < 4; i++)
			{
				if(szMessage[i] == iSymbol)
				{
					szMessage[i] = ' '
					iType++
				}
				else break
			}
			
			switch(szMessage[iType + 1])
			{
				case 'X': iColor = 1
				case 'W': iColor = 2
				case 'R': iColor = 3
				case 'G': iColor = 4
				case 'B': iColor = 5
				case 'Y': iColor = 6
				case 'M': iColor = 7
				case 'C': iColor = 8
				case 'O': iColor = 9
			}
			
			if(iColor > 0) szMessage[iType + 1] = ' '
			trim(szMessage)
			
			if(iColor)
				copy(szColor, charsmax(szColor), g_szHudColors[iColor])
			else
				copy(szColor, charsmax(szColor), g_eSettings[stgHudDefault])
				
			client_cmd(id, "%s%s %s %s", g_szChatHud[iType], (iSymbol == SAY_DHUD) ? "2" : "", szColor, szMessage)
		}
		default: return PLUGIN_CONTINUE
	}
	
	return PLUGIN_HANDLED
}

public hookSayTeam(id)
{
	new szMessage[192]
	read_args(szMessage, charsmax(szMessage))
	remove_quotes(szMessage)
		
	switch(szMessage[0])
	{
		case TSAY_ADMIN:
		{
			szMessage[0] = ' '
			trim(szMessage)
			client_cmd(id, "amx_asay %s", szMessage)
		}
		case TSAY_VIPCHAT:
		{
			szMessage[0] = ' '
			trim(szMessage)
			client_cmd(id, "amx_chat %s", szMessage)
		}
		case TSAY_PRIVATE:
		{
			szMessage[0] = ' '
			trim(szMessage)
			
			new szArg[32]
			parse(szMessage, szArg, charsmax(szArg))
			
			if(is_blank(szArg))
				return PLUGIN_HANDLED
			
			new iPlayer = cmd_target(id, szArg, 0)
			if(!iPlayer) return PLUGIN_HANDLED
			
			replace(szMessage, charsmax(szMessage), szArg, "")
			client_cmd(id, "amx_psay #%i %s", get_user_userid(iPlayer), szMessage)
		}
		case TSAY_TEAMSAY:
		{
			szMessage[0] = ' '
			trim(szMessage)
			
			new szArg[32]
			parse(szMessage, szArg, charsmax(szArg))
			
			if(is_blank(szArg))
				return PLUGIN_HANDLED
			
			replace(szMessage, charsmax(szMessage), szArg, "")
			client_cmd(id, "amx_teamsay %s %s", szArg, szMessage)
		}
		default: return PLUGIN_CONTINUE
	}
	
	return PLUGIN_HANDLED
}

public cmdSay(id, level, cid)
{
	if(!cmd_access(id, level, cid, 2))
		return PLUGIN_HANDLED
	
	new szArg[192]
	read_args(szArg, charsmax(szArg))
	remove_quotes(szArg)
	trim(szArg)
	
	if(is_blank(szArg))
		return PLUGIN_HANDLED
	
	new szMessage[192], szName[32]
	get_user_name(id, szName, charsmax(szName))
	
	if(is_anonymous(id, szArg))
		get_message(id, 0, g_eAMessages[msgSay], szArg, szMessage)
	else
		get_message(id, 0, g_eMessages[msgSay], szArg, szMessage)
	
	new iPlayers[32], iPnum
	get_players(iPlayers, iPnum)
	
	for(new i; i < iPnum; i++)
		ColorChat(iPlayers[i], Color:g_eColors[clrSay], szMessage)
	
	message_log(szName, szArg, "amx_say")
	return PLUGIN_HANDLED
}

public cmdAsay(id, level, cid)
{
	if(!cmd_access(id, level, cid, 2))
		return PLUGIN_HANDLED
	
	new szArg[192]
	read_args(szArg, charsmax(szArg))
	remove_quotes(szArg)
	trim(szArg)
	
	if(is_blank(szArg))
		return PLUGIN_HANDLED
	
	new szMessage[192], szName[32]
	get_user_name(id, szName, charsmax(szName))
	
	if(is_anonymous(id, szArg))
		get_message(id, 0, g_eAMessages[msgAsay], szArg, szMessage)
	else
		get_message(id, 0, g_eMessages[msgAsay], szArg, szMessage)
		
	new iPlayers[32], iPnum, iReceiver
	get_players(iPlayers, iPnum)
	
	for(new i; i < iPnum; i++)
	{
		iReceiver = iPlayers[i]
		if(get_user_flags(iReceiver) & read_flags(g_eFlags[flagReadAdmin]) || id == iReceiver) ColorChat(iReceiver, Color:g_eColors[clrAsay], szMessage)
	}
	
	message_log(szName, szArg, "amx_asay")
	return PLUGIN_HANDLED
}

public cmdChat(id, level, cid)
{
	if(!cmd_access(id, level, cid, 2))
		return PLUGIN_HANDLED
	
	new szArg[192]
	read_args(szArg, charsmax(szArg))
	remove_quotes(szArg)
	trim(szArg)
	
	if(is_blank(szArg))
		return PLUGIN_HANDLED
	
	new szMessage[192], szName[32]
	get_user_name(id, szName, charsmax(szName))
	
	if(is_anonymous(id, szArg))
		get_message(id, 0, g_eAMessages[msgChat], szArg, szMessage)
	else
		get_message(id, 0, g_eMessages[msgChat], szArg, szMessage)
		
	new iPlayers[32], iPnum, iReceiver
	get_players(iPlayers, iPnum)
	
	for(new i; i < iPnum; i++)
	{
		iReceiver = iPlayers[i]
		if(get_user_flags(iReceiver) & read_flags(g_eFlags[flagReadVip])) ColorChat(iReceiver, Color:g_eColors[clrChat], szMessage)
	}
	
	message_log(szName, szArg, "amx_chat")
	return PLUGIN_HANDLED
}

public cmdPsay(id, level, cid)
{
	if(!cmd_access(id, level, cid, 3))
		return PLUGIN_HANDLED
	
	new szArg[180], szPlayer[32]
	read_args(szArg, charsmax(szArg))
	read_argv(1, szPlayer, charsmax(szPlayer))
	
	new iPlayer = cmd_target(id, szPlayer, 0)
	
	if(!iPlayer)
		return PLUGIN_HANDLED
	
	replace(szArg, charsmax(szArg), szPlayer, "")
	trim(szArg)
	
	if(is_blank(szArg))
		return PLUGIN_HANDLED
	
	new szMessage[192], szName[68], szName2[32]
	get_user_name(id, szName, charsmax(szName))
	get_user_name(iPlayer, szName2, charsmax(szName2))
	
	if(is_anonymous(id, szArg))
		get_message(id, iPlayer, g_eAMessages[msgPsay], szArg, szMessage)
	else
		get_message(id, iPlayer, g_eMessages[msgPsay], szArg, szMessage)
		
	add(szName, charsmax(szName), " > ")
	add(szName, charsmax(szName), szName2)
		
	new iPlayers[32], iPnum, iReceiver
	get_players(iPlayers, iPnum)
	
	for(new i; i < iPnum; i++)
	{
		iReceiver = iPlayers[i]
		if(get_user_flags(iReceiver) & read_flags(g_eFlags[flagPsay]) || iPlayer == iReceiver || id == iReceiver) ColorChat(iReceiver, Color:g_eColors[clrPsay], szMessage)
	}
	
	client_cmd(iPlayer, "spk %s", g_eSettings[stgPsaySound])
	message_log(szName, szArg, "amx_psay")
	return PLUGIN_HANDLED
}

public cmdTeamSay(id, level, cid)
{
	if(!cmd_access(id, level, cid, 3))
		return PLUGIN_HANDLED
	
	new szArg[180], szTeam[32], iTeam
	read_args(szArg, charsmax(szArg))
	read_argv(1, szTeam, charsmax(szTeam))
	
	switch(szTeam[0])
	{
		case 't': iTeam = stgTeamT
		case 'c': iTeam = stgTeamCT
		case 's': iTeam = stgTeamSpec
		default: return PLUGIN_HANDLED
	}
	
	replace(szArg, charsmax(szArg), szTeam, "")
	trim(szArg)
	
	if(is_blank(szArg))
		return PLUGIN_HANDLED
	
	new szMessage[192], szName[68]
	get_user_name(id, szName, charsmax(szName))
	
	if(is_anonymous(id, szArg))
		get_message(id, iTeam, g_eAMessages[msgTeamSay], szArg, szMessage)
	else
		get_message(id, iTeam, g_eMessages[msgTeamSay], szArg, szMessage)
		
	add(szName, charsmax(szName), " > ")
	add(szName, charsmax(szName), g_eSettings[iTeam])
		
	new iPlayers[32], iPnum, iReceiver
	get_players(iPlayers, iPnum)
	
	for(new i; i < iPnum; i++)
	{
		iReceiver = iPlayers[i]
		if(get_user_flags(iReceiver) & read_flags(g_eFlags[flagPsay]) || get_user_team(iReceiver) == iTeam || id == iReceiver) ColorChat(iReceiver, Color:g_eColors[clrTeamSay], szMessage)
	}
	
	message_log(szName, szArg, "amx_teamsay")
	return PLUGIN_HANDLED
}

public cmdHsay(id, level, cid)
{
	if(!cmd_access(id, level, cid, 3))
		return PLUGIN_HANDLED
	
	new szArg[180]
	read_args(szArg, charsmax(szArg))
	trim(szArg)
	
	if(equal(szArg, ""))
		return PLUGIN_HANDLED
		
	new szColor[10], iEffect
	parse(szArg, szColor, charsmax(szColor))
	replace(szArg, charsmax(szArg), szColor, "")
		
	if(contain(szArg, HUD_BLINK) != -1)
	{
		replace(szArg, charsmax(szArg), HUD_BLINK, "")
		iEffect = 1
	}
	else if(contain(szArg, HUD_TYPEWRITER) != -1)
	{
		replace(szArg, charsmax(szArg), HUD_TYPEWRITER, "")
		iEffect = 2
	}
	
	new szMessage[192], szName[32], szCommand[10], iType, iColor
	get_user_name(id, szName, charsmax(szName))
	read_argv(0, szCommand, charsmax(szCommand))
	
	if(is_anonymous(id, szArg))
		get_message(id, 0, g_eAMessages[msgHsay], szArg, szMessage)
	else
		get_message(id, 0, g_eMessages[msgHsay], szArg, szMessage)
	
	if(++g_iMessageChannel > 6 || g_iMessageChannel < 3)
		g_iMessageChannel = 3
	
	switch(szCommand[4])
	{
		case 'b': iType = CMD_BSAY
		case 'c': iType = CMD_CSAY
		case 'r': iType = CMD_RSAY
		case 't': iType = CMD_TSAY
	}
	
	if(equal(szColor, "default"))
		copy(szColor, charsmax(szColor), g_eSettings[stgHudDefault])
	
	for(iColor = 0; iColor < sizeof(g_szHudColors); iColor++)
	{
		if(equal(szColor, g_szHudColors[iColor]))
			break
	}
	
	if(iColor >= sizeof(g_szHudColors))
		iColor = 0
	
	new iHud = (szCommand[8] == '2') ? 1 : 0
	new bool:blRandom = (iColor == 1) ? true : false
	
	blRandom ? send_hudmessage(iHud, random(256), random(256), random(256), iType, szMessage, iEffect) : send_hudmessage(iHud, g_iHudValues[iColor][R], g_iHudValues[iColor][G], g_iHudValues[iColor][B], iType, szMessage, iEffect)
	client_print(0, print_console, "[%sHUD] %s", iHud ? "D" : "", szMessage)
	message_log(szName, szArg, szCommand)
	return PLUGIN_HANDLED
}

public plugin_precache()
{
	fileRead()
	
	if(!is_blank(g_eSettings[stgPsaySound]))
		precache_sound(g_eSettings[stgPsaySound])
}

message_log(szName[], szMessage[], szCommand[])
	log_amx("[%s] %s : %s", szCommand, szName, szMessage)
	
send_hudmessage(iHud, iRed, iGreen, iBlue, iType, szMessage[], iEffect)
{
	new Float:flPosition = g_flPositions[iType][Y] + float(g_iMessageChannel) / 35.0
	
	switch(iHud)
	{
		case 0:
		{
			set_hudmessage(iRed, iGreen, iBlue, g_flPositions[iType][X], flPosition, iEffect, 1.0, g_eSettings[stgHudTime], 0.1, 0.15, -1)
			show_hudmessage(0, szMessage)
		}
		case 1:
		{
			set_dhudmessage(iRed, iGreen, iBlue, g_flPositions[iType][X], flPosition, iEffect, 1.0, g_eSettings[stgHudTime], 0.1, 0.15)
			show_dhudmessage(0, szMessage)
		}
	}
}

get_message(id, iPlayer, szMsg[], szArg[], szMessage[192])
{
	new szInfo[32]
	formatex(szMessage, charsmax(szMessage), "%s", szMsg)
	
	if(contain(szMessage, "%name%") != -1)
	{
		is_user_connected(id) ? get_user_name(id, szInfo, charsmax(szInfo)) : copy(szInfo, charsmax(szInfo), g_eSettings[stgServerName])
		replace_all(szMessage, charsmax(szMessage), "%name%", szInfo)
	}
	
	if(contain(szMessage, "%name2%") != -1)
	{
		get_user_name(iPlayer, szInfo, charsmax(szInfo))
		replace_all(szMessage, charsmax(szMessage), "%name2%", szInfo)
	}
	
	if(contain(szMessage, "%level%") != -1)
	{
		new iPrefix = get_user_flags(id) & read_flags(g_eFlags[flagAdmin]) ? stgAdminPrefix : is_user_admin(id) ? stgVipPrefix : stgPlayerPrefix
		copy(szInfo, charsmax(szInfo), g_eSettings[iPrefix])
		replace_all(szMessage, charsmax(szMessage), "%level%", szInfo)
	}
	
	if(contain(szMessage, "%team%") != -1)
		replace_all(szMessage, charsmax(szMessage), "%team%", g_eSettings[iPlayer])
		
	if(contain(szMessage, "%message%") != -1)
		replace_all(szMessage, charsmax(szMessage), "%message%", szArg)
	
	if(contain(szMessage, "%") != -1)
		replace_all(szMessage, charsmax(szMessage), "%", "")
		
	if(contain(szMessage, g_eSettings[stgSymAnonymous]) != -1)
		if(get_user_flags(id) & read_flags(g_eFlags[flagAnonymous])) replace_all(szMessage, charsmax(szMessage), g_eSettings[stgSymAnonymous], "")
		
	for(new i; i < sizeof(g_szColors) - 1; i += 2)
		replace_all(szMessage, charsmax(szMessage), g_szColors[i], g_szColors[i + 1])
}

bool:is_blank(szMessage[])
	return (szMessage[0] == EOS) ? true : false

bool:is_anonymous(id, szMessage[])
	return (g_eSettings[stgAnonymous] || ((contain(szMessage, g_eSettings[stgSymAnonymous]) != -1) && get_user_flags(id) & read_flags(g_eFlags[flagAnonymous]))) ? true : false

ColorChat(id, Color:type, const msg[], {Float,Sql,Result,_}:...)
{
	static message[256];

	switch(type)
	{
		case NORMAL: // clients scr_concolor cvar color
		{
			message[0] = 0x01;
		}
		case GREEN: // Green
		{
			message[0] = 0x04;
		}
		default: // White, Red, Blue
		{
			message[0] = 0x03;
		}
	}

	vformat(message[1], charsmax(message) - 4, msg, 4);
	
	replace_all(message, charsmax(message), "!n", "^x01");
	replace_all(message, charsmax(message), "!t", "^x03");
	replace_all(message, charsmax(message), "!g", "^x04");

	// Make sure message is not longer than 192 character. Will crash the server.
	message[192] = '^0';

	static team, ColorChange, index, MSG_Type;
	
	if(id)
	{
		MSG_Type = MSG_ONE;
		index = id;
	} else {
		index = FindPlayer();
		MSG_Type = MSG_ALL;
	}
	
	team = get_user_team(index);
	ColorChange = ColorSelection(index, MSG_Type, type);

	ShowColorMessage(index, MSG_Type, message);
		
	if(ColorChange)
	{
		Team_Info(index, MSG_Type, TeamName[team]);
	}
}

ShowColorMessage(id, type, message[])
{
	message_begin(type, g_msgSayText, _, id);
	write_byte(id)		
	write_string(message);
	message_end();	
}

Team_Info(id, type, team[])
{
	message_begin(type, g_msgTeamInfo, _, id);
	write_byte(id);
	write_string(team);
	message_end();

	return 1;
}

ColorSelection(index, type, Color:Type)
{
	switch(Type)
	{
		case RED:
		{
			return Team_Info(index, type, TeamName[1]);
		}
		case BLUE:
		{
			return Team_Info(index, type, TeamName[2]);
		}
		case GREY:
		{
			return Team_Info(index, type, TeamName[0]);
		}
	}

	return 0;
}

FindPlayer()
{
	static i;
	i = -1;

	while(i <= g_iMaxPlayers)
	{
		if(is_user_connected(++i))
		{
			return i;
		}
	}

	return -1;
}