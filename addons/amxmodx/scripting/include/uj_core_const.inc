#if defined _uj_core_const_included
  #endinput
#endif
#define _uj_core_const_included

#define UJ_CORE_VERSION_LONG "0.0.2"

// Bit operations
#define get_bit(%1,%2) (%1 & 1<<(%2&31))
#define set_bit(%1,%2) %1 |= (1<<(%2&31))
#define clear_bit(%1,%2) %1 &= ~(1<<(%2&31))
