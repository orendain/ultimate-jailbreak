#include <amxmodx>
#include <sqlvault_ex>
#include <fg_colorchat>

new const PLUGIN_NAME[] = "UJ | Points - Update 1";
new const PLUGIN_AUTH[] = "eDeloa";
new const PLUGIN_VERS[] = "v0.1";

// Vault data
new SQLVault:g_vault;

public plugin_init()
{
  register_plugin(PLUGIN_NAME, PLUGIN_VERS, PLUGIN_AUTH);

  // Set up vault to read from
  g_vault = sqlv_open_local("uj_points", true);
  //server_print("g_vault is %i", g_vault);

  //set_task(5.0, "read_db_new");
  register_concmd("uj_points_fix_1", "fix_1");
}

public plugin_end()
{
  sqlv_close(g_vault);
}

public read_db_new(playerID)
{
  new Array:aVaultData;
  new iVaultKeys = sqlv_read_all(g_vault, aVaultData);

  new eVaultData[SQLVaultEntry];

  new authID[32], points;
  for(new i = 0; i < iVaultKeys; ++i)
  {
    ArrayGetArray(aVaultData, i, eVaultData);
    
    // eVaultData[SQLV_Key] = key
    // eVaultData[SQLV_Data] = data
    // eVaultData[SQLV_TimeStamp] = timestamp

    copy(authID, charsmax(authID), eVaultData[SQLV_Key]);
    points = str_to_num(eVaultData[SQLV_Data]);

    if (points > 3000) {
      server_print("%s, %i", authID, points);
    }
  }
  ArrayDestroy(aVaultData);
  server_print("Done reading all %i points.", iVaultKeys);
}

public fix_1(playerID)
{
  sqlv_set_num(g_vault, "STEAM_0:1:58496912", 5000);
  sqlv_set_num(g_vault, "STEAM_0:1:15582392", 5000);
}
