#if defined _uj_logs_included
  #endinput
#endif
#define _uj_logs_included

#if AMXX_VERSION_NUM >= 175 
  #pragma reqlib uj_logs
  #if !defined AMXMODX_NOAUTOLOAD
    #pragma loadlib uj_logs
  #endif
#else
  #pragma library uj_logs
#endif

/**
 * This is used to log UJ-specific information/errors into a
 * location where it is separate from other messages.
 *
 * @noreturn
 */
native uj_logs_log(const message_fmt[], any:...);

/**
 * This is used to log dev-related UJ-specific information/errors into a
 * location where it is separate from other messages.
 *
 * @noreturn
 */
native uj_logs_log_dev(const message_fmt[], any:...);
