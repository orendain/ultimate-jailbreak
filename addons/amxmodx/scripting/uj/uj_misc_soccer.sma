#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <cstrike>
#include <dhudmessage>
#include <fg_colorchat>

#define MAX_NETS 2

#define FLAG_ADMIN_SETTINGS ADMIN_RCON
#define FLAG_ADMIN ADMIN_LEVEL_A

new const PLUGIN_NAME[] = "UJ | Misc - Soccer"
new const PLUGIN_AUTHOR[] = "eDeloa"
new const PLUGIN_VERSION[] = "v0.1"

static const g_szBallBounce[] = "ultimate_jailbreak/bounce.wav"
static const g_szBallModel[] = "models/ultimate_jailbreak/soccerball.mdl"
new BALL_KICKED[][] = { "weapons/xbow_hitbod1.wav", "weapons/xbow_hitbod2.wav" }
static const g_szBallName[] = "ball"

new headshot
new g_Trail
new Float:modFeet = 35.00

enum {
  FIRST_POINT = 0,
  SECOND_POINT
}

new g_szFile[128]
new g_szMapname[32]
new g_buildingstage[33]

new gBall
new g_iTrailSprite
//new ball_speed
//new ball_distance
new countnets = 0

new bool:g_bHighlight[33][2]
new bool:g_buildingNet[33]
new bool:g_bNeedBall
new bool:g_bScored

new Float:g_vOrigin[3]
new Float:g_fOriginBox[33][2][3]
new Float:g_fLastTouch
new g_OwnerOrigin[3]

new g_Owner

new g_iMainMenu
new g_iBallMenu
new g_iNetMenu

public plugin_init()
{
  register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR)
  
  //ball_speed = register_cvar("jb_ball_speed", "250.0")
  //ball_distance = register_cvar("jb_ball_distance", "700")
  
  register_logevent("EventRoundStart", 2, "1=Round_Start")
  //register_event("CurWeapon", "CurWeapon", "be")
  
  register_forward(FM_PlayerPreThink, "PlayerPreThink", 0)
  register_forward(FM_Touch, "FwdTouch", 0)
  
  RegisterHam(Ham_ObjectCaps, "player", "FwdHamObjectCaps", 1)
  
  register_think(g_szBallName, "FwdThinkBall")
  register_touch(g_szBallName, "player", "FwdTouchPlayer")
  //register_touch(g_szBallName, "JailNet",    "touchNet")
  
  remove_entity_name("func_pushable")
  
  new const szEntity[][] = {
    "worldspawn", "func_wall", "func_door",  "func_door_rotating",
    "func_wall_toggle", "func_breakable", "func_pushable", "func_train",
    "func_illusionary", "func_button", "func_rot_button", "func_rotating"
  }
  
  for(new i; i < sizeof(szEntity); i++) {
    register_touch(g_szBallName, szEntity[i], "FwdTouchWorld")
  }
      
  CreateMenus()
  
  register_clcmd("say /ball", "ShowAdminMenu", FLAG_ADMIN_SETTINGS);
  register_clcmd("say /resetball", "UpdateBall");
  
  engfunc( EngFunc_PrecacheSound, BALL_KICKED[0])
  engfunc( EngFunc_PrecacheSound, BALL_KICKED[1])    
}

public CreateMenus()
{
  g_iMainMenu = register_menuid("Soccer Main")
  g_iBallMenu = register_menuid("Soccer Ball")
  g_iNetMenu = register_menuid("Soccer Net")

  register_menucmd(g_iMainMenu, 1023, "HandleMainMenu")
  register_menucmd(g_iBallMenu, 1023, "HandleBallMenu")
  register_menucmd(g_iNetMenu, 1023, "HandleNetMenu")
}

public ShowAdminMenu(id, level, cid)
{
  if(!cmd_access(id, level, cid, 1)) {
    return PLUGIN_HANDLED;
  }

  ShowMainMenu(id);
  return PLUGIN_HANDLED;
}

public ShowMainMenu(id)
{
  new szBuffer[512], iLen
  new col[3], col2[3]
  
  col = cs_get_user_team(id) == CS_TEAM_CT || get_user_flags(id) & ADMIN_RCON ? "\r" : "\d"
  col2 = cs_get_user_team(id) == CS_TEAM_CT || get_user_flags(id) & ADMIN_RCON ? "\w" : "\d"
  
  iLen = formatex(szBuffer, sizeof szBuffer - 1, "\wSoccerBall^n^n")
  
  iLen += formatex(szBuffer[iLen], (sizeof szBuffer - 1) - iLen, "\r1. \wBall Menu^n")
  iLen += formatex(szBuffer[iLen], (sizeof szBuffer - 1) - iLen, "\r2. \wNet Menu^n^n")
  iLen += formatex(szBuffer[iLen], (sizeof szBuffer - 1) - iLen, "%s3. %sLoad All^n", col, col2)
  iLen += formatex(szBuffer[iLen], (sizeof szBuffer - 1) - iLen, "%s4. %sDelete All^n", col, col2)
  iLen += formatex(szBuffer[iLen], (sizeof szBuffer - 1) - iLen, "%s5. %sSave All^n^n^n^n", col, col2)
  iLen += formatex(szBuffer[iLen], (sizeof szBuffer - 1) - iLen, "\r0. \yExit", col, col2)
  
  new iKeys = ( 1<<0 | 1<<1 | 1<<2 | 1<<3 | 1<<4 | 1<<9 )
  show_menu(id, iKeys, szBuffer, -1, "Soccer Main")
}

public ShowBallMenu(id)
{
  new szBuffer[512], iLen
  new col[3], col2[3]
  
  col = cs_get_user_team(id) == CS_TEAM_CT || get_user_flags(id) & ADMIN_RCON ? "\r" : "\d"
  col2 = cs_get_user_team(id) == CS_TEAM_CT || get_user_flags(id) & ADMIN_RCON ? "\w" : "\d"
  
  iLen = formatex(szBuffer, sizeof szBuffer - 1, "\wSoccer Ball^n^n")
  
  iLen += formatex(szBuffer[iLen], (sizeof szBuffer - 1) - iLen, "%s1. %sCreate Ball^n", col, col2)
  iLen += formatex(szBuffer[iLen], (sizeof szBuffer - 1) - iLen, "%s2. %sHighlight Ball^n", col, col2)
  iLen += formatex(szBuffer[iLen], (sizeof szBuffer - 1) - iLen, "%s3. %sDelete Ball^n^n^n^n^n^n^n", col, col2)
  iLen += formatex(szBuffer[iLen], (sizeof szBuffer - 1) - iLen, "\r0. \yBack")
  
  new iKeys = ( 1<<0 | 1<<1 | 1<<2 | 1<<9 )
  show_menu(id, iKeys, szBuffer, -1, "Soccer Ball")
}

public ShowNetMenu(id)
{
  new szBuffer[512], iLen
  new col[3], col2[3]

  col = cs_get_user_team(id) == CS_TEAM_CT || get_user_flags(id) & ADMIN_RCON ? "\r" : "\d"
  col2 = cs_get_user_team(id) == CS_TEAM_CT || get_user_flags(id) & ADMIN_RCON ? "\w" : "\d"
  
  iLen = formatex(szBuffer, sizeof szBuffer - 1, "\wSoccer Net^n^n")
  
  iLen += formatex(szBuffer[iLen], (sizeof szBuffer - 1) - iLen, "%s1. %sCreate Net^n", col, col2)
  iLen += formatex(szBuffer[iLen], (sizeof szBuffer - 1) - iLen, "%s2. %sHighlight Net^n", col, col2)
  iLen += formatex(szBuffer[iLen], (sizeof szBuffer - 1) - iLen, "%s3. %sDelete Net^n^n", col, col2)
  iLen += formatex(szBuffer[iLen], (sizeof szBuffer - 1) - iLen, "%s4. %sNet Move^n^n^n^n^n", col, col2)
  iLen += formatex(szBuffer[iLen], (sizeof szBuffer - 1) - iLen, "\r0. \yBack")
  
  new iKeys = ( 1<<0 | 1<<1 | 1<<2 | 1<<9 )
  show_menu(id, iKeys, szBuffer, -1, "Soccer Net")
}
public PlayerPreThink(id)
{
  if(!is_user_alive(id)) {
    return PLUGIN_CONTINUE
  }
    
  if(pev(id, pev_button) & IN_USE && !(pev(id, pev_oldbuttons) & IN_USE) && g_buildingNet[id]) {
    new Float:fOrigin[3], fOriginn[3]
    get_user_origin(id, fOriginn, 3)

    IVecFVec(fOriginn, fOrigin)
    if(g_buildingstage[id] == FIRST_POINT) {
      g_buildingstage[id] = SECOND_POINT
      
      g_fOriginBox[id][FIRST_POINT] = fOrigin
      
      fg_colorchat_print(id, FG_COLORCHAT_BLUE, "Now set the origin for the bottom left corner of the box.")
    }
    else {
      g_buildingstage[id] = FIRST_POINT
      g_buildingNet[id] = false
      
      g_fOriginBox[id][SECOND_POINT] = fOrigin
      
      CreateNet(g_fOriginBox[id][FIRST_POINT], g_fOriginBox[id][SECOND_POINT])
      
      fg_colorchat_print(id, FG_COLORCHAT_BLUE, "Successfully created net #%d", ++countnets)
    }
  }
              
  return PLUGIN_HANDLED
}

public UpdateBall(id)
{
  if(!id || cs_get_user_team(id) == CS_TEAM_CT || get_user_flags(id) & FLAG_ADMIN) {
    if(is_valid_ent(gBall)) {
      entity_set_vector(gBall, EV_VEC_velocity, Float:{ 0.0, 0.0, 0.0 })
      entity_set_origin(gBall, g_vOrigin)
      
      entity_set_int(gBall, EV_INT_movetype, MOVETYPE_BOUNCE)
      entity_set_size(gBall, Float:{ -15.0, -15.0, 0.0 }, Float:{ 15.0, 15.0, 12.0 })
      entity_set_int(gBall, EV_INT_iuser1, 0)
    }
  
    if (1 <= g_Owner <= 32) {
      remove_sprite(g_Owner);
      remove_beam(g_Owner);
    }

    set_task(0.1, "MoveBall", 1);
  }
  return PLUGIN_HANDLED;
}

public MoveBall(where)
{
  if(!is_valid_ent(gBall)) {
    return PLUGIN_HANDLED
  }
  
  switch(where) {
    case 0: {
      new Float:orig[3]

      for(new x=0;x<3;x++) {
        orig[x] = -9999.9
      }
      entity_set_origin(gBall,orig)
    }
    case 1: {
      if(is_valid_ent(gBall)) {
        new vOrigin[3]
        
        entity_set_vector(gBall, EV_VEC_velocity, Float:{ 0.0, 0.0, 0.0 })
        entity_set_origin(gBall, g_vOrigin )
        
        entity_set_int(gBall, EV_INT_movetype, MOVETYPE_BOUNCE)
        entity_set_size(gBall, Float:{ -15.0, -15.0, 0.0 }, Float:{ 15.0, 15.0, 12.0 })
        entity_set_int(gBall, EV_INT_iuser1, 0)
        g_bScored = false
        
        FVecIVec(g_vOrigin, vOrigin)
        flameWave(vOrigin, 0, 255, 0, 15)
      }
    }
  }
  return PLUGIN_HANDLED
}

public plugin_precache()
{
  precache_model(g_szBallModel)
  precache_sound(g_szBallBounce)
 
  headshot = precache_model("sprites/ultimate_jailbreak/headsprite1.spr");
  g_iTrailSprite = precache_model("sprites/ultimate_jailbreak/aeroblast.spr");
  g_Trail = precache_model("sprites/ultimate_jailbreak/psybeam.spr");
  
  get_mapname(g_szMapname, 31)
  strtolower(g_szMapname )
  
  new szDatadir[64]
  get_localinfo("amxx_datadir", szDatadir, charsmax(szDatadir))
  
  formatex(szDatadir, charsmax( szDatadir ), "%s", szDatadir)
  
  if(!dir_exists( szDatadir)) {
    mkdir(szDatadir)
  }
  
  formatex(g_szFile, charsmax(g_szFile), "%s/uj_misc_soccer.ini", szDatadir)
  
  if(!file_exists(g_szFile)) {
    write_file(g_szFile, "// Soccerjam Ball/Nets Spawn Editor", -1)
    write_file(g_szFile, "// Credits to us ", -1)
    
    return
  }
  
  LoadAll(0)
}

public LoadAll(id)
{
  new szData[512]
  new szMap[32]
  new szOrigin[3][16]
  new szfPoint[2][3][16], szlPoint[2][3][16]
  new iFile = fopen(g_szFile, "rt")
  
  while(!feof(iFile)) {
    fgets(iFile, szData, charsmax(szData))
    
    if(!szData[0] || szData[0] == ';' || szData[0] == ' ' || ( szData[0] == '/' && szData[1] == '/' )) {
      continue
    }

    parse(szData, szMap, 31, szOrigin[0], 15, szOrigin[1], 15, szOrigin[2], 15,\
      szfPoint[0][0], 15, szfPoint[0][1], 15, szfPoint[0][2], 15,\
      szlPoint[0][0], 15, szlPoint[0][1], 15, szlPoint[0][2], 15,\
      szfPoint[1][0], 15, szfPoint[1][1], 15, szfPoint[1][2], 15,\
      szlPoint[1][0], 15, szlPoint[1][1], 15, szlPoint[1][2], 15)
    
    if(equal(szMap, g_szMapname)) {
      new Float:vOrigin[3]
      new Float:fPoint[2][3]
      new Float:lPoint[2][3]
      
      vOrigin[0] = str_to_float(szOrigin[0])
      vOrigin[1] = str_to_float(szOrigin[1])
      vOrigin[2] = str_to_float(szOrigin[2])
      
      for(new i = 0; i < 2; i++) {
        for(new j = 0; j < 3; j++) {
          fPoint[i][j] = str_to_float(szfPoint[i][j])
          lPoint[i][j] = str_to_float(szlPoint[i][j])
        }
      }
      
      CreateBall(0, vOrigin)
      
      CreateNet(fPoint[0], lPoint[0])
      CreateNet(fPoint[1], lPoint[1])
      
      g_vOrigin = vOrigin
      countnets = 2
      
      break
    }
  }
  
  fclose(iFile)
}

public SaveAll(id)
{
  new iBall, iNets[2], ent, i
  new Float:vOrigin[3]
  new Float:fMaxs[3]
  new Float:fOrigin[3]
  new Float:vfPoint[2][3]
  new Float:vlPoint[2][3]
  
  while((ent = find_ent_by_class(ent, g_szBallName)) > 0) {
    iBall = ent
  }
        
  while((ent = find_ent_by_class(ent, "JailNet")) > 0) {
    iNets[i++] = ent
  }
      
  if(iBall > 0 && iNets[0] > 0 && iNets[1] > 0 && countnets == 2){
    entity_get_vector(iBall, EV_VEC_origin, vOrigin)
    
    for(new i = 0; i < 2; i++) {
      entity_get_vector(iNets[i], EV_VEC_origin, fOrigin)
      entity_get_vector(iNets[i], EV_VEC_maxs, fMaxs)
      
      for(new j = 0; j < 3; j++) {
        vfPoint[i][j] = fOrigin[j] + fMaxs[j]
        vlPoint[i][j] = fOrigin[j] - fMaxs[j]
      }
    }
  }
  else {
    return PLUGIN_HANDLED;
  }
      
  new bool:bFound, iPos, szData[32], iFile = fopen(g_szFile, "r+")
          
  if(!iFile) {
    return PLUGIN_HANDLED
  }
          
  while(!feof(iFile)) {
    fgets(iFile, szData, 31)
    parse(szData, szData, 31)
            
    iPos++
            
    if(equal(szData, g_szMapname)) {
      bFound = true
              
      new szString[512]
      formatex(szString, 511, "%s %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f", g_szMapname, vOrigin[0], vOrigin[1], vOrigin[2],\
          vfPoint[0][0], vfPoint[0][1], vfPoint[0][2], vlPoint[0][0], vlPoint[0][1], vlPoint[0][2],\
          vfPoint[1][0], vfPoint[1][1], vfPoint[1][2], vlPoint[1][0], vlPoint[1][1], vlPoint[1][2])
              
      write_file(g_szFile, szString, iPos - 1)
              
      break
    }
  }
          
  if(!bFound) {
    fprintf(iFile, "%s %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f^n", g_szMapname, vOrigin[0], vOrigin[1], vOrigin[2],\
        vfPoint[0][0], vfPoint[0][1], vfPoint[0][2], vlPoint[0][0], vlPoint[0][1], vlPoint[0][2],\
        vfPoint[1][0], vfPoint[1][1], vfPoint[1][2], vlPoint[1][0], vlPoint[1][1], vlPoint[1][2])
  }
  fclose(iFile)
          
  fg_colorchat_print(id, FG_COLORCHAT_BLUE, "Successfully saved ball & nets!")
  
  return PLUGIN_HANDLED
}

public HandleMainMenu(id, key)
{
  if((key == 2 || key == 3 || key == 4) && !(cs_get_user_team(id) == CS_TEAM_CT || get_user_flags(id) & ADMIN_RCON)) {
    ShowMainMenu(id)
    return PLUGIN_HANDLED
  }
  
  switch(key)
  {
    case 0: {
      ShowBallMenu(id)
      return PLUGIN_HANDLED
    }
    case 1: {
      ShowNetMenu(id)
      return PLUGIN_HANDLED
    }
    case 2: {
      if(is_valid_ent(gBall)) {
        entity_set_vector(gBall, EV_VEC_velocity, Float:{ 0.0, 0.0, 0.0 })
        entity_set_origin(gBall, g_vOrigin )
        
        entity_set_int(gBall, EV_INT_movetype, MOVETYPE_BOUNCE)
        entity_set_size(gBall, Float:{ -15.0, -15.0, 0.0 }, Float:{ 15.0, 15.0, 12.0 })
        entity_set_int(gBall, EV_INT_iuser1, 0)
        
        fg_colorchat_print(id, FG_COLORCHAT_BLUE, "Successfully loaded entity!")
      }
    }
    case 3: {
      new ent
      new ball, net
      while((ent = find_ent_by_class(ent, g_szBallName)) > 0) {
        remove_entity(ent)
        ball++
      }
          
      while((ent = find_ent_by_class(ent, "JailNet")) > 0) {
        remove_entity(ent)
        countnets--
        net++
      }
          
      fg_colorchat_print(id, FG_COLORCHAT_BLUE, "Successfully removed^x03 %d^x01 ball and^x03 %d^x01 nets", ball, net)
    }
    case 4: {
      SaveAll(id)
    }
    case 9: {
      return PLUGIN_HANDLED
    }
  }
  
  ShowMainMenu(id)

  return PLUGIN_HANDLED
}

public HandleBallMenu(id, key)
{
  if(key != 9 && !(cs_get_user_team(id) == CS_TEAM_CT || get_user_flags(id) & ADMIN_RCON)) {
      ShowBallMenu(id)
      return PLUGIN_HANDLED
  }
  
  switch(key)
  {
    case 0: {
      if(pev_valid(gBall)) {
        return PLUGIN_CONTINUE
      }
          
      new ball
      ball = CreateBall(id)
      
      if(pev_valid(ball)) {
        fg_colorchat_print(id, FG_COLORCHAT_BLUE, "Successfully created ball!")
      }
      else {
        fg_colorchat_print(id, FG_COLORCHAT_BLUE, "Failled to create ball!")
      }
    }
    case 1: {
      if(!g_bHighlight[id][1]) {
        set_rendering(gBall, kRenderFxGlowShell, 0, 0, 255, kRenderNormal, 255)
        entity_set_float(gBall, EV_FL_renderamt, 1.0)
        
        g_bHighlight[id][1] = true
        
        fg_colorchat_print(id, FG_COLORCHAT_BLUE, "Ball highlight has been^x04 Enabled^x01.")
      }
      else {
        set_rendering(gBall, kRenderFxNone, 0, 0, 255, kRenderNormal, 255)
        entity_set_float(gBall, EV_FL_renderamt, 1.0)
        
        g_bHighlight[id][1] = false
        
        fg_colorchat_print(id, FG_COLORCHAT_BLUE, "Ball highlight has been^x03 Disabled^x01.")
      }
    }
    case 2: {
      new ent
      new bool:bFound
      while((ent = find_ent_by_class(ent, g_szBallName)) > 0) {
        remove_entity(ent)
        bFound = true
      }
      if(bFound) {
        fg_colorchat_print(id, FG_COLORCHAT_BLUE, "Successfully removed ball!")
      }
      else {
        fg_colorchat_print(id, FG_COLORCHAT_BLUE, "No ball was found to remove")
      }
    }
    case 9: {
      ShowMainMenu(id)
      return PLUGIN_HANDLED
    }
  }
  
  ShowBallMenu(id)
  return PLUGIN_HANDLED
}

public HandleNetMenu(id, key)
{
  if(key != 9 && !(cs_get_user_team(id) == CS_TEAM_CT || get_user_flags(id) & ADMIN_RCON)) {
    ShowNetMenu(id)
    return PLUGIN_HANDLED
  }
  
  switch(key)
  {
    case 0: {
      if(g_buildingNet[id]) {
        fg_colorchat_print(id, FG_COLORCHAT_BLUE, "Already in building net mod.")
        ShowNetMenu(id)
        
        return PLUGIN_HANDLED
      }
      if(countnets >= MAX_NETS) {
        fg_colorchat_print(id, FG_COLORCHAT_BLUE, "Sorry, limit of nets reached (%d).", countnets)
        ShowNetMenu(id)
        
        return PLUGIN_HANDLED
      }
      
      g_buildingNet[id] = true
      
      fg_colorchat_print(id, FG_COLORCHAT_BLUE, "Set the origin for the top right corner of the box.")
    }
    case 1: {
      if(!g_bHighlight[id][0]) {
        set_task(1.0, "taskShowNet", 1000 + id, "", 0, "b", 0)
        g_bHighlight[id][0] = true
        
        fg_colorchat_print(id, FG_COLORCHAT_BLUE, "Net highlight has been^x04 Enabled^x01.")
      }
      else {
        remove_task(1000+id)
        g_bHighlight[id][0] = false
        
        fg_colorchat_print(id, FG_COLORCHAT_BLUE, "Net highlight has been^x03 Disabled^x01.")
      }
    }
    case 2: {
      new ent, body
      new bool:bFound
      static classname[32]
  
      get_user_aiming(id, ent, body, 9999)
      entity_get_string(ent, EV_SZ_classname, classname, charsmax(classname))
      
      if(is_valid_ent(ent) && equal(classname, "JailNet")) {
        remove_entity(ent)
        countnets--
            
        bFound = true
      }
      else {
        new Float:fPlrOrigin[3], Float:fNearestDist = 9999.0, iNearestEnt
        new Float:fOrigin[3], Float:fCurDist

        pev(id, pev_origin, fPlrOrigin)

        new ent = -1
        while((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", "JailNet")) != 0) {
          pev(ent, pev_origin, fOrigin)

          fCurDist = vector_distance(fPlrOrigin, fOrigin)

          if(fCurDist < fNearestDist) {
            iNearestEnt = ent
            fNearestDist = fCurDist
          }
        }
        if(iNearestEnt > 0 && is_valid_ent(iNearestEnt)) {
          remove_entity(iNearestEnt)
          countnets--
        }
        
        bFound = true
      }
      if(bFound) {
        fg_colorchat_print(id, FG_COLORCHAT_BLUE, "Successfully removed net!")
      }
      else {
        fg_colorchat_print(id, FG_COLORCHAT_BLUE, "No net was found to remove")
      }
    }
    case 9: {
      ShowMainMenu(id)
      return PLUGIN_HANDLED
    }
  }
  
  ShowNetMenu(id)
  return PLUGIN_HANDLED
}
        
public EventRoundStart()
{
  if(!g_bNeedBall) {
    return
  }
    
  if(!is_valid_ent(gBall)) {
    CreateBall(0, g_vOrigin)
  }
  else {
    entity_set_vector(gBall, EV_VEC_velocity, Float:{ 0.0, 0.0, 0.0 })
    entity_set_origin(gBall, g_vOrigin)
          
    entity_set_int(gBall, EV_INT_solid, SOLID_BBOX)
    entity_set_int(gBall, EV_INT_movetype, MOVETYPE_BOUNCE)
    entity_set_size(gBall, Float:{ -15.0, -15.0, 0.0 }, Float:{ 15.0, 15.0, 12.0 })
    entity_set_int(gBall, EV_INT_iuser1, 0)
  }

  new iPlayers[ 32 ], iNum;
        
  get_players( iPlayers, iNum );
        
  new iPlayer;
        
  for( new i = 0; i < iNum; i++ ){
    iPlayer = iPlayers[ i ];
        
    remove_sprite(iPlayer)
    remove_beam(iPlayer)
  }
}

public FwdHamObjectCaps(id)
{
  // If this player has the ball
  if(pev_valid(gBall) && is_user_alive(id) && pev(gBall, pev_iuser1) == id) {
    KickBall(id);
  }
}

public FwdThinkBall(ent) {
  if(!is_valid_ent(gBall)) {
    return PLUGIN_HANDLED
  }
  
  static Float:vOrigin[3], Float:vBallVelocity[3]
  
  entity_set_float(ent, EV_FL_nextthink, halflife_time() + 0.05)
  entity_get_vector(ent, EV_VEC_origin, vOrigin)
  entity_get_vector(ent, EV_VEC_velocity, vBallVelocity)
  
  static iOwner
  static iSolid
  
  iSolid = pev(ent, pev_solid)
  iOwner = pev(ent, pev_iuser1)
  
  static Float:flGametime, Float:flLastThink
  flGametime = get_gametime()
  
  if(flLastThink < flGametime) {

    if(floatround(vector_length(vBallVelocity)) > 10) {
      message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
      write_byte(TE_KILLBEAM)
      write_short(gBall)
      message_end()
      
      message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
      write_byte(TE_BEAMFOLLOW)
      write_short(gBall)
      write_short(g_iTrailSprite)
      write_byte(25)
      write_byte(7)
      write_byte(0)
      write_byte(0)
      write_byte(255)
      write_byte(255)
      message_end()
    }
      
    flLastThink = flGametime + 3.0
  }
      
  if(iOwner > 0) {
    static Float:vOwnerOrigin[3]
    static const Float:vVelocity[3] = { 1.0, 1.0, 0.0 }
    //new name[32]
    entity_get_vector( iOwner, EV_VEC_origin, vOwnerOrigin )
    //get_user_name(g_Owner, name,31)
    
    if(!is_user_alive(iOwner)) {
      vOwnerOrigin[ 2 ] += 5.0
                
      entity_set_int(ent, EV_INT_iuser1, 0)
      entity_set_origin(ent, vOwnerOrigin)
      entity_set_vector(ent, EV_VEC_velocity, vVelocity)
      remove_beam(iOwner)
      remove_sprite(iOwner)
                
      return PLUGIN_CONTINUE
    }
      
    if(iSolid != SOLID_NOT) {
      set_pev(ent, pev_solid, SOLID_NOT)
      set_dhudmessage(255, 255, 255, -1.0, 0.4, 0, 0.75, 3.0, 0.75, 0.75)
      show_dhudmessage(iOwner, "YOU HAVE THE BALL!")
      //show_hudmessage(0, "%s has the ball!", name)
      show_sprite(iOwner, headshot)
      message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
      write_byte(TE_BEAMFOLLOW);  // TE_BEAMFOLLOW
      write_short(iOwner);    // ball
      write_short(g_Trail);   // laserbeam
      write_byte(25); // life
      write_byte(7);    // width
      write_byte(0);  // red
      write_byte(255);      // green
      write_byte(0);      // blue
      write_byte(200);  // brightness
      message_end();    
    }
   
    static Float:vAngles[3], Float:vReturn[3]
    entity_get_vector( iOwner, EV_VEC_v_angle, vAngles )
    
    vReturn[0] = (floatcos(vAngles[1], degrees) * 55.0) + vOwnerOrigin[0]
    vReturn[1] = (floatsin(vAngles[1], degrees) * 55.0) + vOwnerOrigin[1]
    vReturn[2] = vOwnerOrigin[2]
    vReturn[2] -= (entity_get_int(iOwner, EV_INT_flags) & FL_DUCKING) ? 10 : 30
    
    entity_set_vector(ent, EV_VEC_velocity, vVelocity)
    entity_set_origin(ent, vReturn)
  }
  else {
    if(iSolid != SOLID_BBOX ) {
      set_pev(ent, pev_solid, SOLID_BBOX)
    }
    
    remove_beam(iOwner)
    remove_sprite(iOwner)
    static Float:flLastVerticalOrigin
  
    if(vBallVelocity[2] == 0.0) {
      static iCounts
      
      // My Guess:
      // If there is no owner, this checks to see if the ball has changed (moved vertically?)
      // over 10 times.  If so, reset the ball (update(0)).
      if(flLastVerticalOrigin > vOrigin[2]) {
        iCounts++
        
        if( iCounts > 10 && !g_bScored) {
          iCounts = 0
          UpdateBall(0)
        }
      } else {
        iCounts = 0
        
        if(PointContents(vOrigin) != CONTENTS_EMPTY && !g_bScored) {
          UpdateBall(0)
        }
      }
      
      flLastVerticalOrigin = vOrigin[2]
    }
  }
  
  return PLUGIN_CONTINUE
}

public remove_beam(iOwner)
{
  //new name[32]
  //get_user_name(g_Owner, name,31)       
        
  message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
  write_byte(99)  // TE_KILLBEAM
  write_short(iOwner)
  message_end()
  //show_hudmessage(0, "remove beam")
  
  //set_hudmessage(255, 0, 0, 0.66,0.07, 0, 0.75, 0.75, 0.75, 0.75, 3)
  //show_hudmessage(0, "%s had the ball last!", name)
  //fg_colorchat_print(iOwner, "%s had the ball last!", name)
}

KickBall(id)
{
  // Save kicker and kicking spot
  g_Owner = id;
  get_user_origin(id, g_OwnerOrigin)

  // Remove sprites from kicker, and play sound
  remove_sprite(g_Owner)
  remove_beam(g_Owner)
  emit_sound(g_Owner, CHAN_WEAPON, BALL_KICKED[random_num(0,1)], 1.0, ATTN_NORM, 0, PITCH_NORM)
  
  static Float:vOrigin[3]
  entity_get_vector(gBall, EV_VEC_origin, vOrigin)

  if(PointContents(vOrigin) != CONTENTS_EMPTY) {
    return PLUGIN_HANDLED
  }

  new Float:vVelocity[3]
  new num = random_num(500, 900) 
  velocity_by_aim(id, num, vVelocity)
      
  set_pev(gBall, pev_solid, SOLID_BBOX)
  entity_set_size(gBall, Float:{ -15.0, -15.0, 0.0 }, Float:{ 15.0, 15.0, 12.0 })
  entity_set_int(gBall, EV_INT_iuser1, 0)
  entity_set_vector(gBall, EV_VEC_velocity, vVelocity)
  //fg_colorchat_print(id, FG_COLORCHAT_BLUE, "Kick Velocity: ^x04%i^x01", num)
  
  return PLUGIN_CONTINUE
}

public Goal()
{
  new name[32], fdistance
  new Float:fOrigin[3]
  entity_get_vector(gBall, EV_VEC_origin,fOrigin)
  new Origin[3]
  
  FVecIVec(fOrigin, Origin)
  
  get_user_name(g_Owner, name,31)
  fdistance = get_distance(Origin, g_OwnerOrigin)
  set_dhudmessage(0, 255, 0, -1.0, 0.54, 0, 6.0, 4.0)
  
  if(g_Owner != 0) {
    show_dhudmessage(0, "GOAL! %s scored a goal^nfrom %d feet away!", name, floatround( fdistance/modFeet ))
    fg_colorchat_print(0, FG_COLORCHAT_BLUE, "^x04%s^x01 scored a goal from^x04 %d^x01 feet away!", name, floatround( fdistance/modFeet ))
    remove_beam(g_Owner)
    remove_sprite(g_Owner)
  }
  
  flameWave(Origin, 0, 0, 255, 4)
  
  g_bScored = true
  
  MoveBall(0)
  
  set_task(5.0, "MoveBall", 1)
  fg_colorchat_print(0, FG_COLORCHAT_BLUE, "The ball will respawn in 5 seconds.")
}
   
public FwdTouchPlayer(Ball, id)
{
  if(is_user_bot(id)) {
    return PLUGIN_CONTINUE
  }
  
  static iOwner
  iOwner = pev(Ball, pev_iuser1)
  if( iOwner == 0 ) {
    entity_set_int(Ball, EV_INT_iuser1, id)
    //uj_effects_reset_max_speed(id);
    //entity_set_float(id, EV_FL_maxspeed, get_pcvar_float(ball_speed))
  }
  
  return PLUGIN_CONTINUE
}

public FwdTouchWorld(Ball, World)
{
  static Float:vVelocity[3]
  entity_get_vector(Ball, EV_VEC_velocity, vVelocity)
  
  if(floatround(vector_length(vVelocity)) > 8 ) {
    vVelocity[0] *= 0.85
    vVelocity[1] *= 0.85
    vVelocity[2] *= 0.85
        
    entity_set_vector(Ball, EV_VEC_velocity, vVelocity)
        
    emit_sound(Ball, CHAN_ITEM, g_szBallBounce, 1.0, ATTN_NORM, 0, PITCH_NORM)
  }

  return PLUGIN_CONTINUE
}

public FwdTouch(ent, id)
{
  if(!is_valid_ent(id)) {
    return;
  }

  static szNameEnt[32], szNameId[32]
  pev(ent, pev_classname, szNameEnt, sizeof szNameEnt - 1)
  pev(id, pev_classname, szNameId, sizeof szNameId - 1)
  
  static Float:fGameTime
  fGameTime = get_gametime()
  
  if(equal(szNameEnt, "JailNet") && equal(szNameId, g_szBallName) && (fGameTime - g_fLastTouch) > 0.1) {
    Goal()
    g_fLastTouch = fGameTime
  }
}

CreateBall(id, Float:vOrigin[ 3 ] = { 0.0, 0.0, 0.0 })
{
  if(!id && vOrigin[0] == 0.0 && vOrigin[1] == 0.0 && vOrigin[2] == 0.0) {
    return 0
  }
  
  g_bNeedBall = true
  
  gBall = create_entity("info_target")
  
  if(is_valid_ent(gBall)) {
    entity_set_string(gBall, EV_SZ_classname, g_szBallName)
    entity_set_int(gBall, EV_INT_solid, SOLID_BBOX)
    entity_set_int(gBall, EV_INT_movetype, MOVETYPE_BOUNCE)
    entity_set_model(gBall, g_szBallModel)
    entity_set_size(gBall, Float:{ -15.0, -15.0, 0.0 }, Float:{ 15.0, 15.0, 12.0 })
    
    entity_set_float(gBall, EV_FL_framerate, 0.0)
    entity_set_int(gBall, EV_INT_sequence, 0)
    
    entity_set_float(gBall, EV_FL_nextthink, get_gametime() + 0.05)
    
    if(id > 0) {
      new iOrigin[3]
      get_user_origin(id, iOrigin, 3)
      IVecFVec(iOrigin, vOrigin)
  
      vOrigin[2] += 5.0
      
      entity_set_origin(gBall, vOrigin)
    } else {
      entity_set_origin(gBall, vOrigin)
    }
    
    g_vOrigin = vOrigin
    return gBall
  }
  
  return -1
}

CreateNet(Float:firstPoint[3], Float:lastPoint[3])
{
  new ent
  new Float:fCenter[3], Float:fSize[3]
  new Float:fMins[3], Float:fMaxs[3]
      
  for ( new i = 0; i < 3; i++ ) {
    fCenter[i] = (firstPoint[i] + lastPoint[i]) / 2.0
            
    fSize[i] = get_float_difference(firstPoint[i], lastPoint[i])
            
    fMins[i] = fSize[i] / -2.0
    fMaxs[i] = fSize[i] / 2.0
  }
  
  ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
  
  if (ent) {
    engfunc(EngFunc_SetOrigin, ent, fCenter)
    
    set_pev(ent, pev_classname, "JailNet")

    dllfunc(DLLFunc_Spawn, ent)

    set_pev(ent, pev_movetype, MOVETYPE_FLY)
    set_pev(ent, pev_solid, SOLID_TRIGGER)

    engfunc(EngFunc_SetSize, ent, fMins, fMaxs)
  }
}

public sqrt(num)
{        
  new div = num
  new result = 1
  
  while (div > result) {
    div = (div + result) / 2
    result = num / div
  }
  
  return div
}

stock Float:get_float_difference(Float:num1, Float:num2)
{
  if(num1 > num2) {
    return (num1-num2)
  }
  else if(num2 > num1) {
    return (num2-num1)
  }
  
  return 0.0
}

public taskShowNet(id)
{
  id -= 1000
  
  if(!is_user_connected(id)) {
    remove_task(1000 + id)
    return
  }
  
  new ent
  new Float:fOrigin[3], Float:fMins[3], Float:fMaxs[3]
  new vMaxs[3], vMins[3]
  new iColor[3] = { 255, 0, 0 }
  
  while((ent = find_ent_by_class(ent, "JailNet")) > 0) {
    pev(ent, pev_mins, fMins)
    pev(ent, pev_maxs, fMaxs)
    pev(ent, pev_origin, fOrigin)

    fMins[0] += fOrigin[0]
    fMins[1] += fOrigin[1]
    fMins[2] += fOrigin[2]
    fMaxs[0] += fOrigin[0]
    fMaxs[1] += fOrigin[1]
    fMaxs[2] += fOrigin[2]
    
    FVecIVec(fMins, vMins)
    FVecIVec(fMaxs, vMaxs)

    fm_draw_line(id, vMaxs[0], vMaxs[1], vMaxs[2], vMins[0], vMaxs[1], vMaxs[2], iColor)
    fm_draw_line(id, vMaxs[0], vMaxs[1], vMaxs[2], vMaxs[0], vMins[1], vMaxs[2], iColor)
    fm_draw_line(id, vMaxs[0], vMaxs[1], vMaxs[2], vMaxs[0], vMaxs[1], vMins[2], iColor)
    fm_draw_line(id, vMins[0], vMins[1], vMins[2], vMaxs[0], vMins[1], vMins[2], iColor)
    fm_draw_line(id, vMins[0], vMins[1], vMins[2], vMins[0], vMaxs[1], vMins[2], iColor)
    fm_draw_line(id, vMins[0], vMins[1], vMins[2], vMins[0], vMins[1], vMaxs[2], iColor)
    fm_draw_line(id, vMins[0], vMaxs[1], vMaxs[2], vMins[0], vMaxs[1], vMins[2], iColor)
    fm_draw_line(id, vMins[0], vMaxs[1], vMins[2], vMaxs[0], vMaxs[1], vMins[2], iColor)
    fm_draw_line(id, vMaxs[0], vMaxs[1], vMins[2], vMaxs[0], vMins[1], vMins[2], iColor)
    fm_draw_line(id, vMaxs[0], vMins[1], vMins[2], vMaxs[0], vMins[1], vMaxs[2], iColor)
    fm_draw_line(id, vMaxs[0], vMins[1], vMaxs[2], vMins[0], vMins[1], vMaxs[2], iColor)
    fm_draw_line(id, vMins[0], vMins[1], vMaxs[2], vMins[0], vMaxs[1], vMaxs[2], iColor)
  }
}

public flameWave(Origin[3], r, g, b, speed)
{
  message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
  write_byte(TE_BEAMCYLINDER)
  write_coord(Origin[0])    //position.x
  write_coord(Origin[1])    //position.y
  write_coord(Origin[2]-20)    //position.z
  write_coord(Origin[0])        //axis.x
  write_coord(Origin[1])        //axis.y
  write_coord(Origin[2]+200)    //axis.z
  write_short(g_iTrailSprite)    //sprite index
  write_byte(0)           //starting frame
  write_byte(0)           //frame rate in 0.1's
  write_byte(5)            //life in 0.1's
  write_byte(70)            //line width in 0.1's
  write_byte(10)            //noise amplitude in 0.01's
  write_byte(r)            // r
  write_byte(g)            // g
  write_byte(b)        // b
  write_byte(255)            // brightness
  write_byte(speed/20)        // scroll speed in 0.1's
  message_end()
}
stock fm_draw_line(id, x1, y1, z1, x2, y2, z2, g_iColor[3])
{
  message_begin(id ? MSG_ONE_UNRELIABLE : MSG_BROADCAST, SVC_TEMPENTITY, _, id ? id : 0)
  
  write_byte(TE_BEAMPOINTS)
  
  write_coord(x1)
  write_coord(y1)
  write_coord(z1)
  
  write_coord(x2)
  write_coord(y2)
  write_coord(z2)
  
  write_short(g_iTrailSprite)
  write_byte(1)
  write_byte(1)
  write_byte(10)
  write_byte(5)
  write_byte(0)
  
  write_byte(g_iColor[0])
  write_byte(g_iColor[1])
  write_byte(g_iColor[2])
  
  write_byte(200)
  write_byte(0)
  
  message_end()
}

public show_sprite(iOwner, sprite)
{ 
  if(!is_user_connected(iOwner)) {
    return PLUGIN_CONTINUE;
  }

  static origin[3]
  get_user_origin(iOwner, origin)
  
  message_begin(MSG_ALL,SVC_TEMPENTITY)
  write_byte(124)
  write_byte(iOwner)
  write_coord(65)
  write_short(sprite)
  write_short(4000)
  message_end()

  return PLUGIN_CONTINUE
}

public remove_sprite(iOwner)
{
  message_begin(MSG_ALL,SVC_TEMPENTITY)
  write_byte(125)
  write_byte(iOwner)
  message_end()
}
