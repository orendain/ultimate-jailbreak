#include < amxmodx > 
#include < cstrike >
#include < amxmisc >

#define PLUGIN "Vip Skins Menu" 
#define VERSION "1.0" 
#define AUTHOR "Alicx" 

public plugin_precache() 
{ 
    precache_model("models/player/daftpunk/daftpunk.mdl"); 
    precache_model("models/player/Dante/Dante.mdl"); 
    precache_model("models/player/engineer/engineer.mdl"); 
    precache_model("models/player/femalewow/femalewow.mdl");
    precache_model("models/player/sm3/sm3.mdl");
    precache_model("models/player/50cent/50cent.mdl");
} 

public plugin_init() { 
    register_plugin(PLUGIN, VERSION, AUTHOR) 
    
    register_clcmd( "say /vipskin",  "Skins_Menu" ); 
} 

public Skins_Menu( id )  
{  
    new menu = menu_create("\w[AG] \yVIP \wModels", "skin_menu")
    if(cs_get_user_team(id) & CS_TEAM_T && has_flag( id, "u" ) )
    {
	menu_additem( menu, "Daft Punk", "1", ADMIN_USER );  
	menu_additem( menu, "Dante [DMC]", "2", ADMIN_USER );
	menu_additem( menu, "Engineer [TF2]", "3", ADMIN_USER );  
	menu_additem( menu, "Female", "4", ADMIN_USER );
	menu_additem( menu, "Spiderman [HD]", "5", ADMIN_USER );
	menu_additem( menu, "50 Cent [HD]", "6", ADMIN_USER );
	menu_additem( menu, "Reset Model", "7", ADMIN_USER );
    }
    
    menu_setprop( menu, MPROP_EXIT, MEXIT_ALL );   
    menu_display( id, menu, 0 );  
}  

public skin_menu(id, menu, item) 
{ 
    if (item == MENU_EXIT) 
    { 
        menu_destroy(menu) 
        return PLUGIN_HANDLED; 
    } 
    
    new data[6], szName[64];
    new access, callback;
    menu_item_getinfo(menu, item, access, data,charsmax(data), szName,charsmax(szName), callback);
    new key = str_to_num(data);
    
    if(!is_user_alive(id))
        return PLUGIN_HANDLED
        
    switch(key)
    {
        case 1: 
        { 
            cs_set_user_model(id, "daftpunk") 
        } 
        case 2: 
        { 
            cs_set_user_model(id, "dante") 
        } 
        case 3: 
        { 
            cs_set_user_model(id, "engineer") 
        } 
        case 4: 
        { 
            cs_set_user_model(id, "femalewow") 
        }
	
        case 5: 
        {
	   
            cs_set_user_model(id, "sm3") 
        }
	
        case 6: 
        { 
           cs_set_user_model(id, "50cent") 
        }
	
        case 7: 
        { 
            cs_reset_user_model(id) 
        }	
	
    } 
    return PLUGIN_CONTINUE; 
}  
