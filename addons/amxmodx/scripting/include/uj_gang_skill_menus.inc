#if defined _uj_gang_skill_menus_included
  #endinput
#endif
#define _uj_gang_skill_menus_included

#include <uj_menus>

#if AMXX_VERSION_NUM >= 175 
  #pragma reqlib uj_gang_skill_menus
  #if !defined AMXMODX_NOAUTOLOAD
    #pragma loadlib uj_gang_skill_menus
  #endif
#else
  #pragma library uj_gang_skill_menus
#endif

/*
 * We use the constants defined in uj_gang_skills_const.inc
 */

/*
 * Registers a gang skill to the gang skill system.
 * To obtain a skillID, first register a skill through uj_gang_skills_register()
 *
 * @param skillID     The internal skillID of the skill
 * @param skillName   Skill name
 * @param costPCVar   A pointer to the cvar that defines the cost of this skill
 * @param maxPCVar    A pointer to the cvar that defines the maximum level of this skill
 *
 * @return            An internal, unique, skillEntryID or UJ_GANG_SKILL_INVALID on failure.
 */
native uj_gang_skill_menus_register(skillID, const skillName[], costPCVar, maxPCVar);


/**
 * Forwards
 *
 * These names are short for uj_fw_gang_skill_menus_select_pre/post()
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
forward uj_fw_gang_skill_menus_s_pre(playerID, menuID, skillEntryID);

/*
 * Called after a player selects a skill entry from a menu.
 *
 * @param playerID        Player index
 * @param menuID          The internal menuID this skill is attemping to display in
 * @param skillEntryID    The internal skillEntryID of the skill entry
 */
forward uj_fw_gang_skill_menus_s_post(playerID, menuID, skillEntryID);
