#! /bin/sh

SMA_EXT=".sma"
AMXX_EXT=".amxx"
SMA_DIR="uj/"

declare -a scripts=(
# Dependencies
"cs_player_models_api"
"cs_weap_models_api"
#"colorchat"

# Core
"uj_base"
"uj_cells"
#"uj_colorchat"
"uj_core"
"uj_effects"
"uj_freedays"
"uj_playermenu"
"uj_chargers"
"uj_logs"
"uj_guardban"
"uj_player_stats"

# Days
"uj_days"
"uj_day_nightcrawlers"
"uj_day_boxing"
"uj_day_chicken"
"uj_day_freeday"
"uj_day_lava"
"uj_day_ghostbusters"
"uj_day_gravity"
"uj_day_reactions"
"uj_day_ratiofreeday"
"uj_day_scoutznknivez"
"uj_day_spartans"
"uj_day_survival"
"uj_day_swat"
"uj_day_timebombs"
"uj_day_nadewar"
"uj_day_oneinthechamber"

# Requests
"uj_requests"
"uj_request_shotforshot"
"uj_request_knifeduel"
"uj_request_scoutduel"
"uj_request_shotgunduel"
"uj_request_spraycontest"
"uj_request_boxingduel"
"uj_request_kamikaze"
"uj_request_guntoss"
"uj_request_rambo"
"uj_request_assassin"

# Gang Core
"uj_gangs"
"uj_gang_skill_db"
"uj_gang_skills"

# Gang Skills
"uj_gang_skill_health"
"uj_gang_skill_gravity"
"uj_gang_skill_damage"
"uj_gang_skill_disarm"
"uj_gang_skill_speed"

# Gang Menu
"uj_menu_gang_create"
"uj_menu_gang_list"
"uj_menu_gang_invite"
"uj_menu_gang_leave"
"uj_menu_gang_onlinemembers"
"uj_menu_gang_skill_upgrade"
"uj_menu_gang_manage"
"uj_menu_gang_manage_disband"
"uj_menu_gang_manage_kick"

# Points
"uj_points"
"uj_points_admin"
"uj_points_base"

# Menus
"uj_menus"
"uj_menu_activities"
"uj_menu_freeday"
"uj_menu_fun"
"uj_menu_gang"
"uj_menu_heal"
"uj_menu_glow"
"uj_menu_lastrequest"
"uj_menu_main"
"uj_menu_shop"
"uj_menu_special"
#"uj_menu_weapons"
"uj_menu_weapons_v2"

# Menu Entries
"uj_menu_celldoors"
"uj_menu_changeteams"
"uj_menu_rules"
"uj_menu_guide_vip"
"uj_menu_guide_admin"

# Items
"uj_items"
"uj_item_armor"
"uj_item_crowbar"
"uj_item_freeday"
"uj_item_invisibility"
"uj_item_nadepack"
"uj_item_parachute"
"uj_item_speed"
"uj_item_silentsteps"
"uj_item_drugs"
"uj_item_bazooka"
"uj_item_emp"
"uj_item_cutpower"
"uj_item_kamikaze"

# Guardban
"uj_guardban_admin"

# Fun
"uj_fun_blackjack"
"uj_fun_hats"
"uj_fun_pointraffle"

# Activities
"uj_activity_push"

# HUD
"uj_hud_overview"
"uj_hud_hidekills"

# Misc
#"uj_misc_autojoin"
#"uj_misc_vips"
"uj_misc_soccer"
"uj_misc_voicemanager"
"uj_misc_control"
#"uj_misc_control_2"
"uj_misc_fists"

# Maps
"uj_map_apocalypse_1"
"uj_map_snow_1"
"uj_map_oasis_1"

# Fixes and Updates
#"uj_gang_skill_db_update_1"
#"uj_gangs_fix_1"
"uj_gangs_fix_2"
#"uj_points_update_1"

# Tools
"uj_tool_entities"
)

# Compile all scripts
for script in ${scripts[@]}
do
  ./amxxpc $SMA_DIR$script$SMA_EXT
done

# Move all scripts to plugin folder AND jailbreak folder
for script in ${scripts[@]}
do
  cp $script$AMXX_EXT /home/steamcmd/steamcmd/cstrike/cstrike/addons/amxmodx/plugins/
  mv -f $script$AMXX_EXT /home/edgar/Projects/factorialgaming/jailbreak/addons/amxmodx/plugins/
done
