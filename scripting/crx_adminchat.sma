#include <amxmodx>
#include <amxmisc>
#include <cstrike>

#tryinclude <cromchat>

#if !defined _cromchat_included
	#error "cromchat.inc" is missing in your "scripting/include" folder. Download it from: "https://amxx-bg.info/inc/"
#endif

#if AMXX_VERSION_NUM < 183 || !defined set_dhudmessage
	#tryinclude <dhudmessage>

	#if !defined _dhudmessage_included
		#error "dhudmessage.inc" is missing in your "scripting/include" folder. Download it from: "https://amxx-bg.info/inc/"
	#endif
#endif

new const PLUGIN_VERSION[] = "4.1.1"

forward cm_on_player_data_updated(id)
forward crxranks_user_level_updated(id, level, bool:levelup)
native crxranks_get_user_rank(id, buffer[], len)
native crxranks_get_user_level(id)
native cm_get_user_prefix(id, buffer[], len)
native cm_get_user_custom_name(id, buffer[], len)
native agroups_get_user_group(id, group[] = "", len = 0)

new const g_szNatives[][] =
{
	"cm_on_player_data_updated",
	"crxranks_user_level_updated",
	"crxranks_get_user_rank",
	"crxranks_get_user_level",
	"cm_get_user_prefix",
	"cm_get_user_custom_name",
	"agroups_get_user_group"
}

#if !defined MAX_PLAYERS
const MAX_PLAYERS = 32
#endif

#if !defined MAX_NAME_LENGTH
const MAX_NAME_LENGTH = 32
#endif

#if !defined MAX_RESOURCE_PATH_LENGTH
const MAX_RESOURCE_PATH_LENGTH = 64
#endif

#if !defined PLATFORM_MAX_PATH
const PLATFORM_MAX_PATH = 256
#endif

#if !defined replace_string
	#define replace_string replace_all
#endif

#define clr(%1) %1 == -1 ? random(256) : %1

const HUD_CHANNEL_AUTO        = -1
const MAX_SYMBOL_LENGTH       = 2
const MAX_COLOR_LENGTH        = 4
const MAX_SHORTCUT_REPEATS    = 4
const MAX_SHORTCUT_LENGTH     = 5
const MAX_SAY_CMD_LENGTH      = 5
const MAX_POSITION_LENGTH     = 8
const MAX_TEAM_NAME_LENGTH    = 10
const MAX_KEY_LENGTH          = 32
const MAX_SERVER_NAME_LENGTH  = 64
const MAX_DESC_LENGTH         = 128
const MAX_VALUE_LENGTH        = 128

new const GET_PLAYERS_FLAGS[] = ""
new const CSTRIKE_MODNAME[]   = "cstrike"

new const ARG_NAME[]          = "$name$"
new const ARG_MESSAGE[]       = "$message$"
new const ARG_ADMRANK[]       = "$admrank$"
new const ARG_TARGET[]        = "$target$"
new const ARG_TEAM[]          = "$team$"
new const ARG_RANK[]          = "$rank$"
new const ARG_LEVEL[]         = "$level$"
new const ARG_PREFIX[]        = "$prefix$"
new const ARG_CUSTOM_NAME[]   = "$customname$"
new const ARG_GROUP[]         = "$group$"
new const ARG_HOSTNAME[]      = "$hostname$"

enum FileSections
{
	Section_None,
	Section_Settings,
	Section_HudColors
}

enum
{
	CRXPosX,
	CRXPosY,
	CRXPosMax
}

enum
{
	CRXClrR,
	CRXClrG,
	CRXClrB,
	CRXClrMax,
}

enum CRXMsgInfo
{
	CRXMsgInfo_Cmd[MAX_KEY_LENGTH],
	CRXMsgInfo_Flag,
	CRXMsgInfo_Desc[MAX_DESC_LENGTH],
	bool:CRXMsgInfo_CstrikeOnly,
	CRXMsgInfo_Args,
	CRXMsgInfo_Id,
	CRXMsgInfo_Flag,
	CRXMsgInfo_MsgFormat[MAX_VALUE_LENGTH],
	CRXMsgInfo_AnonymousFormat[MAX_VALUE_LENGTH],
	CRXMsgInfo_Sound[MAX_RESOURCE_PATH_LENGTH],
	bool:CRXMsgInfo_SoundNoSelf,
	Float:CRXMsgInfo_XPos,
	Float:CRXMsgInfo_YPos,
}

enum CRXMsgTypes
{
	CRXMsgType_Amx_Say,
	CRXMsgType_Amx_Chat,
	CRXMsgType_Amx_AdminSay,
	CRXMsgType_Amx_PrivateSay,
	CRXMsgType_Amx_TeamSay,
	CRXMsgType_Amx_LeftSay,
	CRXMsgType_Amx_TopSay,
	CRXMsgType_Amx_BottomSay,
	CRXMsgType_Amx_RightSay,
	CRXMsgType_Amx_LeftSay2,
	CRXMsgType_Amx_TopSay2,
	CRXMsgType_Amx_BottomSay2,
	CRXMsgType_Amx_RightSay2,
	CRXMsgType_Amx_CenterSay
}

new ADMINCHAT_COMMANDS[CRXMsgTypes][CRXMsgInfo] = 
{
	{ "amx_say",       ADMIN_CHAT, "<message> -- sends a message to all clients"                                              },
	{ "amx_chat",      ADMIN_CHAT, "<message> -- sends a message to all VIPs"                                                 },
	{ "amx_asay",      ADMIN_ALL,  "<message> -- sends a message to all admins"                                               },
	{ "amx_psay",      ADMIN_CHAT, "<player> <message> -- sends a private message to a player"                                },
	{ "amx_teamsay",   ADMIN_CHAT, "<team> <message> -- sends a private message to a specific team", true                     },
	{ "amx_tsay",      ADMIN_CHAT, "<color> <message> -- sends a HUD message to all players on the left side of the screen"   },
	{ "amx_csay",      ADMIN_CHAT, "<color> <message> -- sends a HUD message to all players on the top of the screen"         },
	{ "amx_bsay",      ADMIN_CHAT, "<color> <message> -- sends a HUD message to all players on the bottom of the screen"      },
	{ "amx_rsay",      ADMIN_CHAT, "<color> <message> -- sends a HUD message to all players on the right side of the screen"  },
	{ "amx_tsay2",     ADMIN_BAN,  "<color> <message> -- sends a DHUD message to all players on the left side of the screen"  },
	{ "amx_csay2",     ADMIN_BAN,  "<color> <message> -- sends a DHUD message to all players on the top of the screen"        },
	{ "amx_bsay2",     ADMIN_BAN,  "<color> <message> -- sends a DHUD message to all players on the bottom of the screen"     },
	{ "amx_rsay2",     ADMIN_BAN,  "<color> <message> -- sends a DHUD message to all players on the right side of the screen" },
	{ "amx_centersay", ADMIN_CHAT, "<message> -- sends a chat-style message in the center of the screen"                      }
}

enum Settings
{
	bool:ALLOW_EMPTY_MESSAGES,
	bool:LOG_MESSAGES,
	LOG_FILE[MAX_RESOURCE_PATH_LENGTH],
	bool:ANONYMOUS_MODE,
	ANONYMOUS_SHORTCUT[16],
	ANONYMOUS_FLAG,
	SERVER_NAME[MAX_SERVER_NAME_LENGTH],
	COLORCHAT_FLAG,
	bool:SERVER_NAME_USE_HOSTNAME,
	ADMIN_PREFIX[MAX_KEY_LENGTH],
	VIP_PREFIX[MAX_KEY_LENGTH],
	PLAYER_PREFIX[MAX_KEY_LENGTH],
	AMX_CHAT_FLAG,
	AMX_ASAY_FLAG,
	AMX_PSAY_FLAG,
	AMX_TEAMSAY_FLAG,
	Float:HUD_FXTIME,
	Float:HUD_FADEIN,
	Float:HUD_FADEOUT,
	Float:HUD_HOLDTIME,
	Float:HUD_Y_MOVE,
	HUD_MAX_MOVES,
	HUD_CHANNEL,
	HUD_DEFAULT_COLOR[MAX_SYMBOL_LENGTH],
	HUD_BLINK_SHORTCUT[MAX_KEY_LENGTH],
	HUD_TYPEWRITER_SHORTCUT[MAX_KEY_LENGTH],
	HUD_EFFECT_FLAG
}

enum PlayerData
{
	PlayerData_Flags,
	PlayerData_Level[8],
	PlayerData_Rank[32],
	PlayerData_Group[32],
	PlayerData_Prefix[64],
	PlayerData_CustomName[64],
	PlayerData_AdminRank[MAX_KEY_LENGTH]
}

new TEAM_NAMES[CsTeams][MAX_KEY_LENGTH]

new g_eSettings[Settings]
new g_ePlayerData[MAX_PLAYERS + 1][PlayerData]

new Trie:g_tCommandIds
new Trie:g_tSayShortcuts
new Trie:g_tSayTeamShortcuts
new Trie:g_tHudColors

new bool:g_bIsCstrike
new g_iHudPos[CRXMsgTypes]
new _agroups

public plugin_init()
{
	// Pause the default adminchat plugin in case it is running
	new const OLD_ADMINCHAT[] = "adminchat.amxx"

	if(pause("cd", OLD_ADMINCHAT))
	{
		log_amx("Default %s has been detected and stopped!", OLD_ADMINCHAT)
	}

	register_plugin("OciXCrom's Admin Chat", PLUGIN_VERSION, "OciXCrom")
	register_cvar("CRXAdminChat", PLUGIN_VERSION, FCVAR_SERVER|FCVAR_SPONLY|FCVAR_UNLOGGED)
	register_dictionary("CRXAdminChat.txt")

	register_clcmd("say", "OnSay")
	register_clcmd("say_team", "OnSay")

	register_concmd("ac_reload", "Cmd_Reload", ADMIN_RCON, "-- reloads the Admin Chat configuration file")

	g_tCommandIds = TrieCreate()

	for(new CRXMsgTypes:i, j, iLen; _:i < sizeof(ADMINCHAT_COMMANDS); i++)
	{
		if(!g_bIsCstrike && ADMINCHAT_COMMANDS[i][CRXMsgInfo_CstrikeOnly])
		{
			continue
		}

		TrieSetCell(g_tCommandIds, ADMINCHAT_COMMANDS[i][CRXMsgInfo_Cmd], i)

		ADMINCHAT_COMMANDS[i][CRXMsgInfo_Id] = register_concmd(ADMINCHAT_COMMANDS[i][CRXMsgInfo_Cmd], "OnAdminCmd", ADMINCHAT_COMMANDS[i][CRXMsgInfo_Flag], ADMINCHAT_COMMANDS[i][CRXMsgInfo_Desc])
		get_concmd(ADMINCHAT_COMMANDS[i][CRXMsgInfo_Id], "", 0, ADMINCHAT_COMMANDS[i][CRXMsgInfo_Flag], "", 0, 0)

		iLen = strlen(ADMINCHAT_COMMANDS[i][CRXMsgInfo_Desc])

		for(j = 0; j < iLen; j++)
		{
			if(ADMINCHAT_COMMANDS[i][CRXMsgInfo_Desc][j] == '<')
			{
				ADMINCHAT_COMMANDS[i][CRXMsgInfo_Args]++
			}
		}
	}

	if(LibraryExists("agroups", LibType_Library))
	{
		_agroups = true
	}
}

public plugin_precache()
{
	g_tSayShortcuts = TrieCreate()
	g_tSayTeamShortcuts = TrieCreate()
	g_tHudColors = TrieCreate()

	new szModName[sizeof(CSTRIKE_MODNAME)]
	get_modname(szModName, charsmax(szModName))

	if(equal(szModName, CSTRIKE_MODNAME))
	{
		g_bIsCstrike = true
	}

	ReadFile()
}

public plugin_end()
{
	TrieDestroy(g_tCommandIds)
	TrieDestroy(g_tSayShortcuts)
	TrieDestroy(g_tSayTeamShortcuts)
	TrieDestroy(g_tHudColors)
}

ReadFile(bool:bReload = false)
{
	static szFilename[PLATFORM_MAX_PATH]

	if(bReload)
	{
		TrieClear(g_tSayShortcuts)
		TrieClear(g_tSayTeamShortcuts)
		TrieClear(g_tHudColors)
	}
	else
	{
		get_configsdir(szFilename, charsmax(szFilename))
		add(szFilename, charsmax(szFilename), "/AdminChat.ini")
	}

	new iFilePointer = fopen(szFilename, "rt")

	if(!iFilePointer)
	{
		set_fail_state("Error opening configuration file.")
	}

	if(iFilePointer)
	{
		new szData[MAX_KEY_LENGTH + MAX_VALUE_LENGTH]
		new szKey[MAX_KEY_LENGTH], szValue[MAX_VALUE_LENGTH]

		new CRXMsgTypes:iMsg
		new FileSections:iSection = Section_None, iSize, i
		new szColor[CRXClrMax][MAX_COLOR_LENGTH], iColor[CRXClrMax]

		while(!feof(iFilePointer))
		{
			fgets(iFilePointer, szData, charsmax(szData))
			trim(szData)

			switch(szData[0])
			{
				case EOS, '#', ';': continue
				case '[':
				{
					iSize = strlen(szData)

					if(szData[iSize - 1] == ']')
					{
						szData[iSize - 1] = ' '
					}

					szData[0] = ' '
					trim(szData)

					switch(szData[0])
					{
						case 'S', 's': iSection = Section_Settings
						case 'H', 'h': iSection = Section_HudColors
					}
				}
				default:
				{
					if(iSection == Section_None)
					{
						continue
					}

					strtok(szData, szKey, charsmax(szKey), szValue, charsmax(szValue), '=')
					trim(szKey); trim(szValue)

					switch(iSection)
					{
						case Section_Settings:
						{
							// Check if an older, incompatible version of the .ini file is used (< 4.0)
							if(equal(szKey, "AC_ANONYMOUS"))
							{
								set_fail_state("Your configuration file is outdated. Please download the plugin again and replace the .ini file.")
							}
							else if(equal(szKey, "ALLOW_EMPTY_MESSAGES"))
							{
								g_eSettings[ALLOW_EMPTY_MESSAGES] = _:clamp(str_to_num(szValue), false, true)
							}
							else if(equal(szKey, "LOG_MESSAGES"))
							{
								g_eSettings[LOG_MESSAGES] = _:clamp(str_to_num(szValue), false, true)
							}
							else if(equal(szKey, "LOG_FILE"))
							{
								copy(g_eSettings[LOG_FILE], charsmax(g_eSettings[LOG_FILE]), szValue)
							}
							else if(equal(szKey, "ANONYMOUS_MODE"))
							{
								g_eSettings[ANONYMOUS_MODE] = _:clamp(str_to_num(szValue), false, true)
							}
							else if(equal(szKey, "ANONYMOUS_SHORTCUT"))
							{
								copy(g_eSettings[ANONYMOUS_SHORTCUT], charsmax(g_eSettings[ANONYMOUS_SHORTCUT]), szValue)
							}
							else if(equal(szKey, "ANONYMOUS_FLAG"))
							{
								g_eSettings[ANONYMOUS_FLAG] = read_flags(szValue)
							}
							else if(equal(szKey, "SERVER_NAME"))
							{
								copy(g_eSettings[SERVER_NAME], charsmax(g_eSettings[SERVER_NAME]), szValue)
								g_eSettings[SERVER_NAME_USE_HOSTNAME] = equal(szValue, ARG_HOSTNAME) != 0
							}
							else if(equal(szKey, "COLORCHAT_FLAG"))
							{
								g_eSettings[COLORCHAT_FLAG] = read_flags(szValue)
							}
							else if(equal(szKey, "ADMIN_PREFIX"))
							{
								copy(g_eSettings[ADMIN_PREFIX], charsmax(g_eSettings[ADMIN_PREFIX]), szValue)
							}
							else if(equal(szKey, "VIP_PREFIX"))
							{
								copy(g_eSettings[VIP_PREFIX], charsmax(g_eSettings[VIP_PREFIX]), szValue)
							}
							else if(equal(szKey, "TEAM_NAMES"))
							{
								for(new CsTeams:iTeam = CS_TEAM_T; _:iTeam < sizeof(TEAM_NAMES); iTeam++)
								{
									strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ',')
									trim(szKey); trim(szValue)
									copy(TEAM_NAMES[iTeam], charsmax(TEAM_NAMES[]), szKey)
								}
							}
							else if(equal(szKey, "PLAYER_PREFIX"))
							{
								copy(g_eSettings[PLAYER_PREFIX], charsmax(g_eSettings[PLAYER_PREFIX]), szValue)
							}
							else if(equal(szKey, "AMX_SAY_FORMAT"))
							{
								set_command_format(CRXMsgType_Amx_Say, szValue)
							}
							else if(equal(szKey, "AMX_SAY_FORMAT_AN"))
							{
								set_anonymous_format(CRXMsgType_Amx_Say, szValue)
							}
							else if(equal(szKey, "AMX_SAY_SHORTCUT"))
							{
								set_command_shortcut(CRXMsgType_Amx_Say, szValue)
							}
							else if(equal(szKey, "AMX_SAY_SOUND"))
							{
								set_command_sound(CRXMsgType_Amx_Say, szValue, bReload)
							}
							else if(equal(szKey, "AMX_SAY_SOUND_NOSELF"))
							{
								set_command_sound_self(CRXMsgType_Amx_Say, szValue)
							}
							else if(equal(szKey, "AMX_CHAT_FORMAT"))
							{
								set_command_format(CRXMsgType_Amx_Chat, szValue)
							}
							else if(equal(szKey, "AMX_CHAT_FORMAT_AN"))
							{
								set_anonymous_format(CRXMsgType_Amx_Chat, szValue)
							}
							else if(equal(szKey, "AMX_CHAT_SHORTCUT"))
							{
								set_command_shortcut(CRXMsgType_Amx_Chat, szValue)
							}
							else if(equal(szKey, "AMX_CHAT_FLAG"))
							{
								g_eSettings[AMX_CHAT_FLAG] = read_flags(szValue)
							}
							else if(equal(szKey, "AMX_CHAT_SOUND"))
							{
								set_command_sound(CRXMsgType_Amx_Chat, szValue, bReload)
							}
							else if(equal(szKey, "AMX_CHAT_SOUND_NOSELF"))
							{
								set_command_sound_self(CRXMsgType_Amx_Chat, szValue)
							}
							else if(equal(szKey, "AMX_ASAY_FORMAT"))
							{
								set_command_format(CRXMsgType_Amx_AdminSay, szValue)
							}
							else if(equal(szKey, "AMX_ASAY_FORMAT_AN"))
							{
								set_anonymous_format(CRXMsgType_Amx_AdminSay, szValue)
							}
							else if(equal(szKey, "AMX_ASAY_SHORTCUT"))
							{
								set_command_shortcut(CRXMsgType_Amx_AdminSay, szValue)
							}
							else if(equal(szKey, "AMX_ASAY_FLAG"))
							{
								g_eSettings[AMX_ASAY_FLAG] = read_flags(szValue)
							}
							else if(equal(szKey, "AMX_ASAY_SOUND"))
							{
								set_command_sound(CRXMsgType_Amx_AdminSay, szValue, bReload)
							}
							else if(equal(szKey, "AMX_ASAY_SOUND_NOSELF"))
							{
								set_command_sound_self(CRXMsgType_Amx_AdminSay, szValue)
							}
							else if(equal(szKey, "AMX_PSAY_FORMAT"))
							{
								set_command_format(CRXMsgType_Amx_PrivateSay, szValue)
							}
							else if(equal(szKey, "AMX_PSAY_FORMAT_AN"))
							{
								set_anonymous_format(CRXMsgType_Amx_PrivateSay, szValue)
							}
							else if(equal(szKey, "AMX_PSAY_SHORTCUT"))
							{
								set_command_shortcut(CRXMsgType_Amx_PrivateSay, szValue)
							}
							else if(equal(szKey, "AMX_PSAY_FLAG"))
							{
								g_eSettings[AMX_PSAY_FLAG] = read_flags(szValue)
							}
							else if(equal(szKey, "AMX_PSAY_SOUND"))
							{
								set_command_sound(CRXMsgType_Amx_PrivateSay, szValue, bReload)
							}
							else if(equal(szKey, "AMX_PSAY_SOUND_NOSELF"))
							{
								set_command_sound_self(CRXMsgType_Amx_PrivateSay, szValue)
							}
							else if(equal(szKey, "AMX_TEAMSAY_FORMAT"))
							{
								set_command_format(CRXMsgType_Amx_TeamSay, szValue)
							}
							else if(equal(szKey, "AMX_TEAMSAY_FORMAT_AN"))
							{
								set_anonymous_format(CRXMsgType_Amx_TeamSay, szValue)
							}
							else if(equal(szKey, "AMX_TEAMSAY_SHORTCUT"))
							{
								set_command_shortcut(CRXMsgType_Amx_TeamSay, szValue)
							}
							else if(equal(szKey, "AMX_TEAMSAY_FLAG"))
							{
								g_eSettings[AMX_TEAMSAY_FLAG] = read_flags(szValue)
							}
							else if(equal(szKey, "AMX_TEAMSAY_SOUND"))
							{
								set_command_sound(CRXMsgType_Amx_TeamSay, szValue, bReload)
							}
							else if(equal(szKey, "AMX_TEAMSAY_SOUND_NOSELF"))
							{
								set_command_sound_self(CRXMsgType_Amx_TeamSay, szValue)
							}
							else if(equal(szKey, "AMX_CENTERSAY_FORMAT"))
							{
								set_command_format(CRXMsgType_Amx_CenterSay, szValue)
							}
							else if(equal(szKey, "AMX_CENTERSAY_FORMAT_AN"))
							{
								set_anonymous_format(CRXMsgType_Amx_CenterSay, szValue)
							}
							else if(equal(szKey, "AMX_CENTERSAY_SHORTCUT"))
							{
								set_command_shortcut(CRXMsgType_Amx_CenterSay, szValue)
							}
							else if(equal(szKey, "AMX_CENTERSAY_SOUND"))
							{
								set_command_sound(CRXMsgType_Amx_CenterSay, szValue, bReload)
							}
							else if(equal(szKey, "AMX_CENTERSAY_SOUND_NOSELF"))
							{
								set_command_sound_self(CRXMsgType_Amx_CenterSay, szValue)
							}
							else if(equal(szKey, "AMX_HUDSAY_FORMAT"))
							{
								for(iMsg = CRXMsgType_Amx_LeftSay; iMsg <= CRXMsgType_Amx_RightSay2; iMsg++)
								{
									set_command_format(iMsg, szValue)	
								}
							}
							else if(equal(szKey, "AMX_HUDSAY_FORMAT_AN"))
							{
								for(iMsg = CRXMsgType_Amx_LeftSay; iMsg <= CRXMsgType_Amx_RightSay2; iMsg++)
								{
									set_anonymous_format(iMsg, szValue)	
								}
							}
							else if(equal(szKey, "AMX_HUDSAY_SHORTCUT"))
							{
								set_command_shortcut(CRXMsgType_Amx_LeftSay, szValue)
							}
							else if(equal(szKey, "AMX_DHUDSAY_SHORTCUT"))
							{
								set_command_shortcut(CRXMsgType_Amx_LeftSay2, szValue)
							}
							else if(equal(szKey, "AMX_HUDSAY_SOUND"))
							{
								if(!bReload)
								{
									precache_generic(szValue)
								}

								for(iMsg = CRXMsgType_Amx_LeftSay; iMsg <= CRXMsgType_Amx_RightSay; iMsg++)
								{
									set_command_sound(iMsg, szValue, true)	
								}
							}
							else if(equal(szKey, "AMX_HUDSAY_SOUND_NOSELF"))
							{
								for(iMsg = CRXMsgType_Amx_LeftSay; iMsg <= CRXMsgType_Amx_RightSay; iMsg++)
								{
									set_command_sound_self(iMsg, szValue)	
								}
							}
							else if(equal(szKey, "AMX_DHUDSAY_SOUND"))
							{
								if(!bReload)
								{
									precache_generic(szValue)
								}

								for(iMsg = CRXMsgType_Amx_LeftSay2; iMsg <= CRXMsgType_Amx_RightSay2; iMsg++)
								{
									set_command_sound(iMsg, szValue, true)	
								}
							}
							else if(equal(szKey, "AMX_DHUDSAY_SOUND_NOSELF"))
							{
								for(iMsg = CRXMsgType_Amx_LeftSay2; iMsg <= CRXMsgType_Amx_RightSay2; iMsg++)
								{
									set_command_sound_self(iMsg, szValue)	
								}
							}
							else if(equal(szKey, "HUD_FXTIME"))
							{
								g_eSettings[HUD_FXTIME] = _:str_to_float(szValue)
							}
							else if(equal(szKey, "HUD_FADEIN"))
							{
								g_eSettings[HUD_FADEIN] = _:str_to_float(szValue)
							}
							else if(equal(szKey, "HUD_FADEOUT"))
							{
								g_eSettings[HUD_FADEOUT] = _:str_to_float(szValue)
							}
							else if(equal(szKey, "HUD_HOLDTIME"))
							{
								g_eSettings[HUD_HOLDTIME] = _:str_to_float(szValue)
							}
							else if(equal(szKey, "HUD_Y_MOVE"))
							{
								g_eSettings[HUD_Y_MOVE] = _:str_to_float(szValue)
							}
							else if(equal(szKey, "HUD_MAX_MOVES"))
							{
								g_eSettings[HUD_MAX_MOVES] = str_to_num(szValue)
							}
							else if(equal(szKey, "HUD_CHANNEL"))
							{
								g_eSettings[HUD_CHANNEL] = clamp(str_to_num(szValue), HUD_CHANNEL_AUTO, 4)

								if(!g_eSettings[HUD_CHANNEL])
								{
									g_eSettings[HUD_CHANNEL] = 1
								}
							}
							else if(equal(szKey, "HUD_DEFAULT_COLOR"))
							{
								copy(g_eSettings[HUD_DEFAULT_COLOR], charsmax(g_eSettings[HUD_DEFAULT_COLOR]), szValue)
							}
							else if(equal(szKey, "HUD_POSITION_BSAY"))
							{
								set_command_position(CRXMsgType_Amx_BottomSay, szValue)
								set_command_position(CRXMsgType_Amx_BottomSay2, szValue)
							}
							else if(equal(szKey, "HUD_POSITION_CSAY"))
							{
								set_command_position(CRXMsgType_Amx_TopSay, szValue)
								set_command_position(CRXMsgType_Amx_TopSay2, szValue)
							}
							else if(equal(szKey, "HUD_POSITION_RSAY"))
							{
								set_command_position(CRXMsgType_Amx_RightSay, szValue)
								set_command_position(CRXMsgType_Amx_RightSay2, szValue)
							}
							else if(equal(szKey, "HUD_POSITION_TSAY"))
							{
								set_command_position(CRXMsgType_Amx_LeftSay, szValue)
								set_command_position(CRXMsgType_Amx_LeftSay2, szValue)
							}
							else if(equal(szKey, "HUD_BLINK_SHORTCUT"))
							{
								copy(g_eSettings[HUD_BLINK_SHORTCUT], charsmax(g_eSettings[HUD_BLINK_SHORTCUT]), szValue)
							}
							else if(equal(szKey, "HUD_TYPEWRITER_SHORTCUT"))
							{
								copy(g_eSettings[HUD_TYPEWRITER_SHORTCUT], charsmax(g_eSettings[HUD_TYPEWRITER_SHORTCUT]), szValue)
							}
							else if(equal(szKey, "HUD_EFFECT_FLAG"))
							{
								g_eSettings[HUD_EFFECT_FLAG] = read_flags(szValue)
							}
						}
						case Section_HudColors:
						{
							parse(szValue, szColor[CRXClrR], charsmax(szColor[]), szColor[CRXClrG], charsmax(szColor[]), szColor[CRXClrB], charsmax(szColor[]))

							for(i = CRXClrR; i < CRXClrMax; i++)
							{
								iColor[i] = str_to_num(szColor[i])
							}

							TrieSetArray(g_tHudColors, szKey, iColor, sizeof(iColor))
						}
					}
				}
			}
		}

		fclose(iFilePointer)
	}
}

public cm_on_player_data_updated(id)
{
	cm_get_user_prefix(id, g_ePlayerData[id][PlayerData_Prefix], charsmax(g_ePlayerData[][PlayerData_Prefix]))
	cm_get_user_custom_name(id, g_ePlayerData[id][PlayerData_CustomName], charsmax(g_ePlayerData[][PlayerData_CustomName]))
}

public crxranks_user_level_updated(id, iLevel)
{
	num_to_str(iLevel, g_ePlayerData[id][PlayerData_Level], charsmax(g_ePlayerData[][PlayerData_Level]))
	crxranks_get_user_rank(id, g_ePlayerData[id][PlayerData_Rank], charsmax(g_ePlayerData[][PlayerData_Rank]))
}

public Cmd_Reload(id, iLevel, iCid)
{
	if(!cmd_access(id, iLevel, iCid, 1))
	{
		return PLUGIN_HANDLED
	}

	ReadFile(true)

	new szName[MAX_NAME_LENGTH]
	get_user_name(id, szName, charsmax(szName))

	client_print(id, print_console, "%L", id, "CRXADMINCHAT_RELOAD_SUCCESS")
	log_amx("%L", LANG_SERVER, "CRXADMINCHAT_RELOAD_LOG", szName)

	return PLUGIN_HANDLED
}

public OnSay(id)
{
	new szCmd[MAX_SAY_CMD_LENGTH]
	read_argv(0, szCmd, charsmax(szCmd))

	static szInput[CC_MAX_MESSAGE_SIZE]
	read_args(szInput, charsmax(szInput))
	remove_quotes(szInput)

	new szChar[MAX_SYMBOL_LENGTH], CRXMsgTypes:iMsg
	copy(szChar, charsmax(szChar), szInput)

	if(TrieGetCell(is_team_say(szCmd) ? g_tSayTeamShortcuts : g_tSayShortcuts, szChar, iMsg))
	{
		if(!cmd_access(id, ADMINCHAT_COMMANDS[iMsg][CRXMsgInfo_Flag], ADMINCHAT_COMMANDS[iMsg][CRXMsgInfo_Id], ADMINCHAT_COMMANDS[iMsg][CRXMsgInfo_Args]))
		{
			return PLUGIN_HANDLED
		}

		new szArg[MAX_NAME_LENGTH]

		if(iMsg == CRXMsgType_Amx_LeftSay || iMsg == CRXMsgType_Amx_LeftSay2)
		{
			szInput[0] = ' '

			for(new i = 1; i < MAX_SHORTCUT_REPEATS; i++)
			{
				if(szInput[i] == szChar[0])
				{
					iMsg++
					szInput[i] = ' '
				}
				else
				{
					break
				}
			}

			trim(szInput)
			copy(szChar, charsmax(szChar), szInput)

			if(TrieKeyExists(g_tHudColors, szChar))
			{
				szInput[0] = ' '
				trim(szInput)
				copy(szArg, charsmax(szArg), szChar)
			}
		}
		else
		{
			szInput[0] = ' '
			trim(szInput)

			if(ADMINCHAT_COMMANDS[iMsg][CRXMsgInfo_Args] > 1)
			{
				parse(szInput, szArg, charsmax(szArg))
				replace_string(szInput, charsmax(szInput), szArg, "")
				trim(szInput)
			}
		}

		send_custom_message(id, szArg, szInput, iMsg)
		return PLUGIN_HANDLED
	}

	return PLUGIN_CONTINUE
}

public OnAdminCmd(id, iLevel, iCid)
{
	new szCmd[MAX_KEY_LENGTH]
	read_argv(0, szCmd, charsmax(szCmd))

	new CRXMsgTypes:iMsg
	TrieGetCell(g_tCommandIds, szCmd, iMsg)

	if(!cmd_access(id, iLevel, iCid, ADMINCHAT_COMMANDS[iMsg][CRXMsgInfo_Args] + 1))
	{
		return PLUGIN_HANDLED
	}

	new szInput[CC_MAX_MESSAGE_SIZE], szArg[MAX_NAME_LENGTH]
	read_args(szInput, charsmax(szInput))

	if(ADMINCHAT_COMMANDS[iMsg][CRXMsgInfo_Args] > 1)
	{
		parse(szInput, szArg, charsmax(szArg))
		replace(szInput, charsmax(szInput), szArg, "")
		trim(szInput)

		if(is_hud_msg(iMsg))
		{
			szArg[1] = EOS
		}
	}

	remove_quotes(szInput)

	// Additionally check 'amx_psay' and 'amx_teamsay' for quotes in the beginning due to their different handling.
	if(iMsg == CRXMsgType_Amx_PrivateSay || iMsg == CRXMsgType_Amx_TeamSay)
	{
		new iLen = strlen(szInput)

		for(new i; i < iLen; i++)
		{
			if(szInput[i] == '"')
			{
				szInput[i] = ' '
			}
			else if(szInput[i] != ' ')
			{
				break
			}
		}

		trim(szInput)
	}

	send_custom_message(id, szArg, szInput, iMsg)
	return PLUGIN_HANDLED
}

send_custom_message(id, szArg[MAX_NAME_LENGTH], szInput[CC_MAX_MESSAGE_SIZE], CRXMsgTypes:iMsg)
{
	if(is_msg_empty(id, szInput))
	{
		return
	}

	new iFlags = get_user_flags(id)

	if(g_ePlayerData[id][PlayerData_Flags] != iFlags)
	{
		g_ePlayerData[id][PlayerData_Flags] = iFlags

		if(user_has_flag(id, g_eSettings[AMX_ASAY_FLAG]))
		{
			copy(g_ePlayerData[id][PlayerData_AdminRank], charsmax(g_ePlayerData[][PlayerData_AdminRank]), g_eSettings[ADMIN_PREFIX])
		}
		else if(is_user_admin(id))
		{
			copy(g_ePlayerData[id][PlayerData_AdminRank], charsmax(g_ePlayerData[][PlayerData_AdminRank]), g_eSettings[VIP_PREFIX])
		}
		else
		{
			copy(g_ePlayerData[id][PlayerData_AdminRank], charsmax(g_ePlayerData[][PlayerData_AdminRank]), g_eSettings[PLAYER_PREFIX])
		}

		if(_agroups)
		{
			agroups_get_user_group(id, g_ePlayerData[id][PlayerData_Group], charsmax(g_ePlayerData[][PlayerData_Group]))
		}
	}

	new bool:bAnonymous = g_eSettings[ANONYMOUS_MODE]

	if(has_argument(szInput, g_eSettings[ANONYMOUS_SHORTCUT]))
	{
		if(user_has_flag(id, g_eSettings[ANONYMOUS_FLAG]))
		{
			bAnonymous = true
		}

		replace_string(szInput, charsmax(szInput), g_eSettings[ANONYMOUS_SHORTCUT], "")
	}

	new szMessage[CC_MAX_MESSAGE_SIZE], szCmd[MAX_KEY_LENGTH], szName[MAX_SERVER_NAME_LENGTH]
	copy(szCmd, charsmax(szCmd), ADMINCHAT_COMMANDS[iMsg][CRXMsgInfo_Cmd])
	copy(szMessage, charsmax(szMessage), ADMINCHAT_COMMANDS[iMsg][bAnonymous ? CRXMsgInfo_AnonymousFormat : CRXMsgInfo_MsgFormat])

	new iEffect

	// Check effect before applying replacements in case '#' is a replacement shortcut.
	if(is_hud_msg(iMsg))
	{
		if(user_has_flag(id, g_eSettings[HUD_EFFECT_FLAG]))
		{
			if(has_argument(szInput, g_eSettings[HUD_BLINK_SHORTCUT]))
			{
				iEffect = 1
				replace(szInput, charsmax(szInput), g_eSettings[HUD_BLINK_SHORTCUT], "")
			}
			else if(has_argument(szInput, g_eSettings[HUD_TYPEWRITER_SHORTCUT]))
			{
				iEffect = 2
				replace(szInput, charsmax(szInput), g_eSettings[HUD_TYPEWRITER_SHORTCUT], "")
			}
		}
	}

	apply_replacements(id, szArg, szInput, charsmax(szInput), szMessage, charsmax(szMessage), szName, charsmax(szName))

	if(is_msg_empty(id, szInput))
	{
		return
	}

	switch(iMsg)
	{
		case CRXMsgType_Amx_Say:
		{
			CC__SendMatched(0, id, iMsg, true, szMessage)
		}
		case CRXMsgType_Amx_Chat:
		{
			CC__SendToFlag(id, iMsg, g_eSettings[AMX_CHAT_FLAG], szMessage)
		}
		case CRXMsgType_Amx_AdminSay:
		{
			CC__SendToFlag(id, iMsg, g_eSettings[AMX_ASAY_FLAG], szMessage)
		}
		case CRXMsgType_Amx_PrivateSay:
		{
			new iTarget = cmd_target(id, szArg, CMDTARGET_NO_BOTS)

			if(!iTarget)
			{
				return
			}

			if(has_argument(szMessage, ARG_TARGET))
			{
				new szPlayer[MAX_NAME_LENGTH]
				get_user_name(iTarget, szPlayer, charsmax(szPlayer))
				replace_string(szMessage, charsmax(szMessage), ARG_TARGET, szPlayer)
			}

			new iPlayers[MAX_PLAYERS], iPnum
			get_players(iPlayers, iPnum, GET_PLAYERS_FLAGS)

			for(new bool:bSoundNoSelf = ADMINCHAT_COMMANDS[iMsg][CRXMsgInfo_SoundNoSelf], i, iPlayer; i < iPnum; i++)
			{
				iPlayer = iPlayers[i]

				if(id == iPlayer || iTarget == iPlayer || user_has_flag(iPlayer, g_eSettings[AMX_PSAY_FLAG]))
				{
					CC__SendMatched(iPlayer, id, iMsg, ((iTarget == iPlayer) || (!bSoundNoSelf && id == iPlayer)), szMessage)
				}
			}
		}
		case CRXMsgType_Amx_TeamSay:
		{
			new CsTeams:iTeam
			
			switch(szArg[0])
			{
				case 'T', 't': iTeam = CS_TEAM_T
				case 'C', 'c': iTeam = CS_TEAM_CT
				case 'S', 's': iTeam = CS_TEAM_SPECTATOR
				default:
				{
					client_print(id, print_console, "%L", id, "CRXADMINCHAT_TEAM_NOT_FOUND", szArg)
					return
				}
			}

			new iPlayers[MAX_PLAYERS], iPnum
			get_players(iPlayers, iPnum, GET_PLAYERS_FLAGS)

			for(new i, iPlayer; i < iPnum; i++)
			{
				iPlayer = iPlayers[i]

				if(id == iPlayer || user_has_flag(iPlayer, g_eSettings[AMX_TEAMSAY_FLAG]) || iTeam == cs_get_user_team(iPlayer))
				{
					CC__SendMatched(iPlayers[i], id, iMsg, true, szMessage)
				}
			}
		}
		case CRXMsgType_Amx_CenterSay:
		{
			client_print(0, print_center, szMessage)
			play_msg_sound(0, id, iMsg)
		}
		default:
		{
			new bool:bHud = CRXMsgType_Amx_LeftSay <= iMsg <= CRXMsgType_Amx_RightSay

			if(!bHud || g_eSettings[HUD_CHANNEL] == HUD_CHANNEL_AUTO)
			{
				if(++g_iHudPos[iMsg] > g_eSettings[HUD_MAX_MOVES])
				{
					g_iHudPos[iMsg] = 0
				}
			}

			new iColor[CRXClrMax]

			if(!TrieGetArray(g_tHudColors, szArg, iColor, sizeof(iColor)))
			{
				TrieGetArray(g_tHudColors, g_eSettings[HUD_DEFAULT_COLOR], iColor, sizeof(iColor))
			}

			if(bHud)
			{
				set_hudmessage(clr(iColor[CRXClrR]), clr(iColor[CRXClrG]), clr(iColor[CRXClrB]), ADMINCHAT_COMMANDS[iMsg][CRXMsgInfo_XPos], ADMINCHAT_COMMANDS[iMsg][CRXMsgInfo_YPos] + float(g_iHudPos[iMsg]) / g_eSettings[HUD_Y_MOVE], iEffect, g_eSettings[HUD_FXTIME], g_eSettings[HUD_HOLDTIME], g_eSettings[HUD_FADEIN], g_eSettings[HUD_FADEOUT], g_eSettings[HUD_CHANNEL])
				show_hudmessage(0, szMessage)
			}
			else
			{
				set_dhudmessage(clr(iColor[CRXClrR]), clr(iColor[CRXClrG]), clr(iColor[CRXClrB]), ADMINCHAT_COMMANDS[iMsg][CRXMsgInfo_XPos], ADMINCHAT_COMMANDS[iMsg][CRXMsgInfo_YPos] + float(g_iHudPos[iMsg]) / g_eSettings[HUD_Y_MOVE], iEffect, g_eSettings[HUD_FXTIME], g_eSettings[HUD_HOLDTIME], g_eSettings[HUD_FADEIN], g_eSettings[HUD_FADEOUT])
				show_dhudmessage(0, szMessage)
			}

			play_msg_sound(0, id, iMsg)
			client_print(0, print_console, "[%sHUD] %s", bHud ? "" : "D", szMessage)
		}
	}

	if(g_eSettings[LOG_MESSAGES])
	{
		formatex(szMessage, charsmax(szMessage), "[%s%s] %s: %s%s%s", szCmd, bAnonymous ? " - A" : "", is_user_connected(id) ? szName : "", szArg, szArg[0] ? " " : "", szInput)

		if(g_eSettings[LOG_FILE][0] == '!')
		{
			log_amx(szMessage)
		}
		else
		{
			log_to_file(g_eSettings[LOG_FILE], szMessage)
		}
	}
}

apply_replacements(id, const szArg[], szInput[], iInputLen, szMessage[], iMessageLen, szName[], iNameLen)
{
	if(has_argument(szMessage, ARG_ADMRANK))
	{
		replace_string(szMessage, iMessageLen, ARG_ADMRANK, g_ePlayerData[id][PlayerData_AdminRank])
	}

	if(has_argument(szMessage, ARG_TEAM))
	{
		switch(szArg[0])
		{
			case 'T', 't': replace_string(szMessage, iMessageLen, ARG_TEAM, TEAM_NAMES[CS_TEAM_T])
			case 'C', 'c': replace_string(szMessage, iMessageLen, ARG_TEAM, TEAM_NAMES[CS_TEAM_CT])
			case 'S', 's': replace_string(szMessage, iMessageLen, ARG_TEAM, TEAM_NAMES[CS_TEAM_SPECTATOR])
		}
	}

	if(has_argument(szMessage, ARG_RANK))
	{
		replace_string(szMessage, iMessageLen, ARG_RANK, g_ePlayerData[id][PlayerData_Rank])
	}

	if(has_argument(szMessage, ARG_LEVEL))
	{
		replace_string(szMessage, iMessageLen, ARG_LEVEL, g_ePlayerData[id][PlayerData_Level])
	}

	if(has_argument(szMessage, ARG_PREFIX))
	{
		replace_string(szMessage, iMessageLen, ARG_PREFIX, g_ePlayerData[id][PlayerData_Prefix])
	}

	if(has_argument(szMessage, ARG_GROUP))
	{
		agroups_get_user_group(id, g_ePlayerData[id][PlayerData_Group], charsmax(g_ePlayerData[][PlayerData_Group]))
		replace_string(szMessage, iMessageLen, ARG_GROUP, g_ePlayerData[id][PlayerData_Group])
	}

	if(has_argument(szMessage, ARG_MESSAGE))
	{
		// Prevent chat exploits.
		replace_string(szInput, iInputLen, "%", "％")

		if(!user_has_flag(id, g_eSettings[COLORCHAT_FLAG]))
		{
			CC_RemoveColors(szInput, iInputLen)
		}

		replace_string(szMessage, iMessageLen, ARG_MESSAGE, szInput)
	}

	if(has_argument(szMessage, ARG_CUSTOM_NAME))
	{
		replace_string(szMessage, iMessageLen, ARG_CUSTOM_NAME, g_ePlayerData[id][PlayerData_CustomName])
	}

	if(has_argument(szMessage, ARG_NAME))
	{
		if(is_user_connected(id))
		{
			get_user_name(id, szName, iNameLen)
			replace_string(szMessage, iMessageLen, ARG_NAME, szName)
		}
		else
		{
			if(g_eSettings[SERVER_NAME_USE_HOSTNAME])
			{
				get_user_name(0, szName, iNameLen)
				replace_string(szMessage, iMessageLen, ARG_NAME, szName)
			}
			else
			{
				replace_string(szMessage, iMessageLen, ARG_NAME, g_eSettings[SERVER_NAME])
			}
		}
	}
}

bool:check_cstrike(CRXMsgTypes:iMsg)
{
	return g_bIsCstrike || !ADMINCHAT_COMMANDS[iMsg][CRXMsgInfo_CstrikeOnly]
}

bool:is_team_say(const szCmd[])
{
	return szCmd[3] == '_'
}

bool:is_msg_empty(id, const szMessage[])
{
	if(!szMessage[0] && !g_eSettings[ALLOW_EMPTY_MESSAGES])
	{
		client_print(id, print_console, "%L", id, "CRXADMINCHAT_MSG_EMPTY")
		return true
	}

	return false
}

set_command_format(CRXMsgTypes:iMsg, const szValue[])
{
	if(!check_cstrike(iMsg))
	{
		return
	}

	copy(ADMINCHAT_COMMANDS[iMsg][CRXMsgInfo_MsgFormat], charsmax(ADMINCHAT_COMMANDS[][CRXMsgInfo_MsgFormat]), szValue)
}

set_anonymous_format(CRXMsgTypes:iMsg, const szValue[])
{
	if(!check_cstrike(iMsg))
	{
		return
	}

	copy(ADMINCHAT_COMMANDS[iMsg][CRXMsgInfo_AnonymousFormat], charsmax(ADMINCHAT_COMMANDS[][CRXMsgInfo_AnonymousFormat]), szValue)
}

set_command_shortcut(CRXMsgTypes:iMsg, const szValue[])
{
	if(!check_cstrike(iMsg))
	{
		return
	}

	static szType[MAX_SAY_CMD_LENGTH], szChar[MAX_SYMBOL_LENGTH]
	parse(szValue, szType, charsmax(szType), szChar, charsmax(szChar))
	TrieSetCell(is_team_say(szType) ? g_tSayTeamShortcuts : g_tSayShortcuts, szChar, iMsg)
}

set_command_sound(CRXMsgTypes:iMsg, const szSound[], bool:bReload)
{
	if(bReload || !check_cstrike(iMsg))
	{
		return
	}

	precache_generic(szSound)
	copy(ADMINCHAT_COMMANDS[iMsg][CRXMsgInfo_Sound], charsmax(ADMINCHAT_COMMANDS[][CRXMsgInfo_Sound]), szSound)
}

set_command_sound_self(CRXMsgTypes:iMsg, const szValue[])
{
	if(!check_cstrike(iMsg))
	{
		return
	}

	ADMINCHAT_COMMANDS[iMsg][CRXMsgInfo_SoundNoSelf] = _:clamp(str_to_num(szValue), false, true)
}

set_command_position(CRXMsgTypes:iMsg, const szValue[])
{
	new szPos[CRXPosMax][MAX_POSITION_LENGTH]
	parse(szValue, szPos[CRXPosX], charsmax(szPos[]), szPos[CRXPosY], charsmax(szPos[]))
	ADMINCHAT_COMMANDS[iMsg][CRXMsgInfo_XPos] = _:str_to_float(szPos[CRXPosX])
	ADMINCHAT_COMMANDS[iMsg][CRXMsgInfo_YPos] = _:str_to_float(szPos[CRXPosY])
}

bool:user_has_flag(id, iFlag)
{
	return iFlag == ADMIN_ALL || get_user_flags(id) & iFlag != 0
}

bool:has_argument(const szMessage[], const szArg[])
{
	return contain(szMessage, szArg) != -1
}

bool:is_hud_msg(CRXMsgTypes:iMsg)
{
	return CRXMsgType_Amx_LeftSay <= iMsg <= CRXMsgType_Amx_RightSay2
}

play_msg_sound(id, iSender, CRXMsgTypes:iMsg)
{
	if(!id || !ADMINCHAT_COMMANDS[iMsg][CRXMsgInfo_Sound][0])
	{
		return
	}

	if(id == iSender && ADMINCHAT_COMMANDS[iMsg][CRXMsgInfo_SoundNoSelf])
	{
		return
	}

	client_cmd(id, "spk ^"%s^"", ADMINCHAT_COMMANDS[iMsg][CRXMsgInfo_Sound])
}

CC__SendMatched(id, iSender, CRXMsgTypes:iMsg, bool:bPlaySound, const szMessage[])
{
	if(id)
	{
		CC_SendMatched(id, iSender, szMessage)

		if(bPlaySound)
		{
			play_msg_sound(id, iSender, iMsg)
		}
	}
	else
	{
		new iPlayers[MAX_PLAYERS], iPnum
		get_players(iPlayers, iPnum, GET_PLAYERS_FLAGS)

		for(new i, iPlayer; i < iPnum; i++)
		{
			iPlayer = iPlayers[i]

			CC_SendMatched(iPlayer, id, szMessage)

			if(bPlaySound)
			{
				play_msg_sound(iPlayer, iSender, iMsg)
			}
		}
	}
}

CC__SendToFlag(id, CRXMsgTypes:iMsg, iFlag, const szMessage[])
{
	new iPlayers[MAX_PLAYERS], iPnum
	get_players(iPlayers, iPnum, GET_PLAYERS_FLAGS)

	for(new iPlayer, i; i < iPnum; i++)
	{
		iPlayer = iPlayers[i]

		if(id == iPlayer || user_has_flag(iPlayer, iFlag))
		{
			CC_SendMatched(iPlayer, id, szMessage)
			play_msg_sound(iPlayer, id, iMsg)
		}
	}
}

public plugin_natives()
{
	set_native_filter("native_filter")
	set_module_filter("module_filter")
}

public native_filter(const szNative[], id, iTrap)
{
	if(!iTrap)
	{
		static i

		for(i = 0; i < sizeof(g_szNatives); i++)
		{
			if(equal(szNative, g_szNatives[i]))
			{
				return PLUGIN_HANDLED
			}
		}
	}

	return PLUGIN_CONTINUE
}

public module_filter(const szLibrary[])
{
	return equal(szLibrary, CSTRIKE_MODNAME) ? PLUGIN_HANDLED : PLUGIN_CONTINUE
}