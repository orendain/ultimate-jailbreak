#if defined _uj_gang_skills_included
  #endinput
#endif
#define _uj_gang_skills_included

#include <uj_gang_skills_const>

#if AMXX_VERSION_NUM >= 175 
  #pragma reqlib uj_gang_skills
  #if !defined AMXMODX_NOAUTOLOAD
    #pragma loadlib uj_gang_skills
  #endif
#else
  #pragma library uj_gang_skills
#endif

/*
 * Registers a gang skill to the gang skill system.
 *
 * @param name        Skill name
 * @param costPCVar   A pointer to the cvar that defines the cost of this skill
 * @param maxPCVar    A pointer to the cvar that defines the maximum level of this skill
 *
 * @return            An internal, unique, skill ID
 */
native uj_gang_skills_register(const name[]);

/*
 * Find a skill id by name
 *
 * @param name    Skill name
 *
 * @return        An internal skill ID
 */
native uj_gang_skills_get_id(const name[]);

/*
 * Get the level of a gang's particular skill
 *
 * @param gangID        The gang to look up
 * @param skillID       The skill to look up
 *
 * @return              The current level of the specified skill
 */
native uj_gang_skills_get_level(gangID, skillID);

/*
 * Sets a gang's skill to the specified level
 *
 * @param gangID        The gang to edit
 * @param skillID       The skill to edit
 * @param skillLevel     The level to set
 *
 * @noreturn
 */
native uj_gang_skills_set_level(gangID, skillID, skillLevel);

/*
 * Add a level to a gang's skill.
 *
 * @param gangID        The gang to edit
 * @param skillID       The skill to edit
 *
 * @noreturn
 */
native uj_gang_skills_add_level(gangID, skillID);

/*
 * Removes a level to a gang's skill.
 *
 * @param gangID        The gang to look up
 * @param skillID       The skill to look up
 *
 * @noreturn
 */
native uj_gang_skills_remove_level(gangID, skillID);
