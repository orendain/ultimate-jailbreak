#if defined _uj_cells_included
  #endinput
#endif
#define _uj_cells_included

#if AMXX_VERSION_NUM >= 175 
  #pragma reqlib uj_cells
  #if !defined AMXMODX_NOAUTOLOAD
    #pragma loadlib uj_cells
  #endif
#else
  #pragma library uj_cells
#endif

/**
 * Natives
 */

/**
 * Open all cell doors.
 *
 * @param playerID  The player doing the opening.
 *
 * @noreturn
 */
native uj_cells_open_doors(playerID);


/**
 * Forwards
 */

/*
 * Called when cell doors are opened.
 *
 * @param activateorID       The entity that activated this door (most likely a playerID)
 */
forward uj_fw_cells_doors_opened(activatorID);
