#if defined _crxdays_included
	#endinput
#endif

#define _crxdays_included

#include <crxdays_const>
#include <cstrike>

/**
 * Called after all functions from the .ini file have been read.
 *
 * @note This is the best time to register custom functions
 * @noreturn
 */
forward crxdays_functions_loaded()

/**
 * Called when the client attempts to open the days menu.
 *
 * @param id            Client index
 * @return              PLUGIN_HANDLED to deny access to the menu or PLUGIN_CONTINUE to open normally
 */
forward crxdays_menu_opened(id)

/**
 * Called when the client attempts to start a custom day
 *
 * @param dayid         Day index
 * @param key           Day key
 * @param id            Client index
 * @return              PLUGIN_HANDLED to prevent the day from starting or PLUGIN_CONTINUE to continue normally
 */
forward crxdays_day_started(dayid, key[], id)

/**
 * Called when the client gets frozen or unfrozen during the day timer
 *
 * @param id            Client index
 * @param dayid         Day index
 * @param frozen        True if he got frozen, false otherwise
 * @noreturn
 */
forward crxdays_player_frozen(id, dayid, bool:frozen)

/**
 * Called when the day start counter ends and the day finally started
 *
 * @param dayid         Day index
 * @param key           Day key
 * @param id            Index of the client who started the day
 * @noreturn
 */
forward crxdays_timer_ended(dayid, key[], id)

/**
 * Called when the MVP gets selected
 *
 * @param id            Client index of the chosen MVP
 * @param dayid         Day index
 * @param key           Day key
 * @noreturn
 */
forward crxdays_mvp_selected(id, dayid, key[])

/**
 * Called when the client spawns during a custom day
 *
 * @note This is called before the attributes are loaded
 *
 * @param id            Client index
 * @param dayid         Day index
 * @noreturn
 */
forward crxdays_player_spawned(id, dayid)

/**
 * Called when the attributes are loaded for a player or group of players
 *
 * @note This is also called when the player spawns during a custom day
 * and the "players" array hold only that player in this case
 *
 * @param dayid         Day index
 * @param attribute     Attribute key (e.g. "health")
 * @param options       Attribute options (e.g. "all 100")
 * @param players       Players that match the <team> argument set in the attribute
 * @param pnum          Number of players matched
 * @noreturn
 */
forward crxdays_attribute_loaded(dayid, attribute[], options[], players[MAX_PLAYERS], pnum)

/**
 * Called when the MVP gets removed
 *
 * @param id            MVP client index
 * @param dayid         Day index
 * @param key           Day key
 * @param type          Remove type
 *                          CRXDays_MVP_Died if the MVP was killed
 *                          CRXDays_MVP_Left if the MVP disconnected
 * @param killer        Killer index if type = CRXDays_MVP_Died or 0 if there was no killer
 * @noreturn
 */
forward crxdays_mvp_removed(id, dayid, key[], CRXDays_MVPRemovedTypes:type, killer)

forward crxdays_player_killed(id, dayid)

/**
 * Called when a custom day ends
 *
 * @param dayid         Day index
 * @param key           Day key
 * @param type          Ending reason
 *                          CRXDays_ET_RoundEnd if the round ended
 *                          CRXDays_ET_Duration if the day ended because of the "duration" setting
 *                          CRXDays_ET_Forced if the day was stopped via an admin command or plugin
 * @noreturn
 */
forward crxdays_day_ended(dayid, key[], CRXDays_EndTypes:type)

/**
 * Registers a custom function that can be used in the CustomDays.ini file
 *
 * @param type          Function type
 *                          CRXDays_FT_Setting which can be applied only once and can have a default value for all days
 *                                             these settings are read when the day timer starts
 *                          CRXDays_FT_Attribute which can be applied multiple times and must contain a <team> argument
 *                                             these are read when the day timer ends and when the player spawns during a day
 * @param func          Function key
 * @param args          Function arguments
 * @param desc          Short description
 * @param def           Default value
 * @param ...           Variable number of comments that will be added after the function
 * @noreturn
 */
native crxdays_register_function(CRXDays_FunctionTypes:type, func[], args[] = "", desc[] = "", def[] = "", any:...)

/**
 * Checks if the client matches the <team> argument
 *
 * @note Putting '!' in front of the "team" argument will exclude the MVP from the group
 *       e.g. "!t" will match against all terrorists except the MVP
 *
 * @param id            Client index
 * @param team          Team to match against
 *                          all to match against all players
 *                          ct to match against Counter-Terrorists
 *                          t to match against Terrorists
 * @return              True if the client is in the team, false otherwise
 */
native bool:crxdays_is_in_team(id, team[])

/**
 * Returns the current day timer
 *
 * @param dayid         Day index
 * @return              Amount of seconds left
 */
native crxdays_get_day_timer(&dayid)

/**
 * Forces the current day to end
 * @noreturn
 */
native crxdays_force_end_day()

/**
 * Returns the current day id
 *
 * @return              Day index or CRXDAYS_INVALID_DAY if no day is currently active
 */
native crxdays_get_current_day()

/**
 * Finds a day by its key
 *
 * @param key           Day key
 * @return              Day index or CRXDAYS_INVALID_DAY if no day was found
 */
native crxdays_find_day_id(key[])

/**
 * Reads a day setting set in the CustomDays.ini file
 *
 * @param dayid         Day index
 * @param setting       Setting name
 * @param buffer        Buffer to store the setting in
 * @param len           Maximum buffer length
 * @return              True if the setting was found, false otherwise
 */
native bool:crxdays_get_setting(dayid, setting[], buffer[], len)

/**
 * Reads the arguments from an attribute
 *
 * @param options       Buffer that holds the arguments
 * @param args          Buffer to store the arguments
 * @param len           Maximum buffer length
 * @param argnum        Amount of arguments to read
 * @noreturn
 */
stock crxdays_read_args(options[], args[][], len, argnum)
{
	new iPos, i

	while(i < argnum)
	{
		iPos = argparse(options, iPos, args[i++], len)
	}
}