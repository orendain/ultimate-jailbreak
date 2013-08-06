#if defined _uj_gang_skills_included
  #endinput
#endif
#define _uj_gang_skills_included

#include <uj_menus>

#if AMXX_VERSION_NUM >= 175 
  #pragma reqlib uj_gang_skills
  #if !defined AMXMODX_NOAUTOLOAD
    #pragma loadlib uj_gang_skills
  #endif
#else
  #pragma library uj_gang_skills
#endif

/*
 * We use the constants defined in uj_gang_skills_const.inc
 */

/*
 * Registers a gang skill to the gang skill system.
 *
 * @param skillName       Skill name
 * @param costPCVar       A CVar pointer to the cost of each skill level
 * @param maxLevelPCVar   A CVar pointer to the maximum level of the skill
 *
 * @return                A unique skilID or UJ_GANG_SKILL_INVALID on failure.
 */
native uj_gang_skills_register(const skillName[], costPCVar, maxLevelPCVar);

/*
 * Display a message to all affected gang members about a skill change.
 *
 * @param playerID    Player performing the change
 * @param gangID      The affected gang
 * @param skillID     The affected skill
 */
native uj_gang_skills_announce_upgrade(playerID, gangID, skillID);

/*
 * Find the cost of a skill.
 *
 * @param skillID     The skill ID to look up
 *
 * @return            The cost of the skill, or UJ_GANG_SKILL_INVALID if fail
 */
native uj_gang_skills_get_cost(skillID);

/*
 * Find the max allowed level of a skill.
 *
 * @param skillID     The skill ID to look up
 *
 * @return            The max allowed level, or UJ_GANG_SKILL_INVALID if fail
 */
native uj_gang_skills_get_max_level(skillID);

/*
 * Display a list of all registered skills.
 * uj_fw_gang_skills_select_post() is called after a selection is made.
 *
 * @param playerID      The player to display the menu to.
 * @param gangID        The gang to filter out skills from.
 * @param filterCost    True to filter out skills the player cannot afford
 * @param filterLow     True to filter out skills at the lowest level
 * @param filterMax     True to filter out skills at the maximum level
 *
 * @noreturn
 */
native uj_gang_skills_show_menu(playerID, gangID, bool:filterCost, bool:filterLow, bool:filterHigh);

/**
 * Forwards
 */

/*
 * Called when determining whether a skill menu entry should be available to a player. 
 *
 * Possible return values are:
 *  - UJ_GANG_SKILL_AVAILABLE (show in menu, allow selection)
 *  - UJ_GANG_SKILL_NOT_AVAILABLE (show in menu, don't allow selection)
 *  - UJ_GANG_SKILL_DONT_SHOW (don't show in menu, don't allow selection)
 *
 * @param playerID        Player index
 * @param menuID          The internal menuID this skill is attemping to display in
 * @param skillEntryID    The internal skillEntryID of the skill entry
 */
forward uj_fw_gang_skills_select_pre(playerID, menuID, skillID);

/*
 * Called after a player selects a skill entry from a menu.
 *
 * @param pluginID        The plugin the process was initiated by.
 * @param playerID        Player index
 * @param gangID          The gang results were based on
 * @param skillEntryID    The internal skillEntryID of the skill entry
 */
forward uj_fw_gang_skills_select_post(pluginID, playerID, gangID, skillID);
