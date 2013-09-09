#if defined _uj_gang_skill_db_included
  #endinput
#endif
#define _uj_gang_skill_db_included

#include <uj_gang_skill_db_const>

#if AMXX_VERSION_NUM >= 175 
  #pragma reqlib uj_gang_skill_db
  #if !defined AMXMODX_NOAUTOLOAD
    #pragma loadlib uj_gang_skill_db
  #endif
#else
  #pragma library uj_gang_skill_db
#endif

/*
 * Registers a gang skill to the gang skill system.
 *
 * @param name        Skill name
 *
 * @return            An internal, unique, skill ID
 */
native uj_gang_skill_db_register(const name[]);

/*
 * Total number of skills that have been registered
 *
 * @return        Skill count
 */
native uj_gang_skill_db_get_count();

/*
 * Find a skill id by name
 *
 * @param name    Skill name
 *
 * @return        An internal skill ID
 */
native uj_gang_skill_db_get_id(const name[]);

/*
 * Find a skill name
 *
 * @param sillID       The skillID
 * @param skillName    An array to fill with the skill's name
 * @param maxLength    The maximum number of characters to store inside skillName[]
 *
 * @noreturn
 */
native uj_gang_skill_db_get_name(skillID, skillName[], maxLength);

/*
 * Get the level of a gang's particular skill
 *
 * @param gangID        The gang to look up
 * @param skillID       The skill to look up
 *
 * @return              The current level of the specified skill
 */
native uj_gang_skill_db_get_level(gangID, skillID);

/*
 * Sets a gang's skill to the specified level
 *
 * @param gangID        The gang to edit
 * @param skillID       The skill to edit
 * @param skillLevel     The level to set
 *
 * @return              The new skill level, or UJ_GANG_SKILL_INVALID on fail
 */
native uj_gang_skill_db_set_level(gangID, skillID, skillLevel);

/*
 * Add a level to a gang's skill.
 *
 * @param gangID        The gang to edit
 * @param skillID       The skill to edit
 *
 * @return              The new skill level, or UJ_GANG_SKILL_INVALID on fail
 */
native uj_gang_skill_db_add_level(gangID, skillID);

/*
 * Removes a level to a gang's skill.
 *
 * @param gangID        The gang to look up
 * @param skillID       The skill to look up
 *
 * @return              The new skill level, or UJ_GANG_SKILL_INVALID on fail
 */
native uj_gang_skill_db_remove_level(gangID, skillID);
