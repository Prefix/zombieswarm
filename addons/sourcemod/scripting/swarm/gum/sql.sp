public void databaseInit()
{
    Database.Connect(databaseConnectionCallback);
}

public void getSaveIdentifier( int client, char[] szKey, int maxlen )
{
    switch( GetConVarInt( cvarSaveType ) )
    {
        case 2:
        {
            GetClientName( client, szKey, maxlen );

            ReplaceString( szKey, maxlen, "'", "\'" );
        }

        case 1:    GetClientIP( client, szKey, maxlen );
        case 0:    GetClientAuthId( client, AuthId_SteamID64, szKey, maxlen );
    }
}

public void SaveClientData(int client) {
    if ( IsClientInGame(client) )
    {
        if (!IsFakeClient(client)) {
            char sQuery[256];
            char sKey[32], oName[32], pName[80];
            getSaveIdentifier( client, sKey, sizeof( sKey ) );
            
            GetClientName(client, oName, sizeof(oName));
            conDatabase.Escape(oName, pName, sizeof(pName));
        
            Format( sQuery, sizeof( sQuery ), "SELECT `purchased` FROM `gum` WHERE ( `player_id` = '%s' )", sKey);
            
            DataPack dp = new DataPack();
            
            dp.WriteCell(playerLevel[client]);
            dp.WriteCell(pUnlocks[client]);
            dp.WriteString(sKey);
            dp.WriteString(pName);
            
            conDatabase.Query( querySelectSavedDataCallback, sQuery, dp);
        }
    }
}

void ExecuteTopTen(int client)
{
    char sQuery[ 256 ]; 
    Format( sQuery, sizeof( sQuery ), "SELECT `player_name`,`player_total_reborns` FROM `prestige_players` ORDER BY `player_total_reborns` DESC LIMIT 10;" );
    conDatabase.Query( queryShowTopTableCallback, sQuery, client);
}

public void saveData(int rowCount, const char[] sKey, const char[] playerName, int level, int unlocks)
{
    char sQuery[256];
    
    int bufferLength = strlen(playerName) * 2 + 1;
    char[] newPlayerName = new char[bufferLength];
    conDatabase.Escape(playerName, newPlayerName, bufferLength);
    
    if (rowCount > 0)
        Format( sQuery, sizeof( sQuery ), "UPDATE `gum` SET `player_name` = '%s', `player_level` = '%d', `player_unlocks` = '%d', `purchased` = '0' WHERE (`player_id` = '%s');", newPlayerName, level, unlocks, sKey );
    else
        Format( sQuery, sizeof( sQuery ), "INSERT INTO `gum` (`player_id`, `player_name`, `player_level`, `player_unlocks`) VALUES ('%s', '%s', '%d', '%d');", sKey, newPlayerName, level, unlocks );
    
    conDatabase.Query( querySetDataCallback, sQuery);
}
public void loadData(int client)
{
    char sQuery[ 256 ]; 
    
    char szKey[64];
    getSaveIdentifier( client, szKey, sizeof( szKey ) );

    Format( sQuery, sizeof( sQuery ), "SELECT `player_unlocks` FROM `gum` WHERE ( `player_id` = '%s' );", szKey );
    
    conDatabase.Query( querySelectDataCallback, sQuery, client);
}
public void databaseConnectionCallback(Database db, const char[] error, any data)
{
    if ( db == null )
    {
        PrintToServer("Failed to connect: %s", error);
        LogError( "%s", error ); 
        
        return;
    }
    
    conDatabase = db;
    conDatabase.SetCharset("utf8mb4");
    
    char sQuery[512], driverName[16];
    conDatabase.Driver.GetIdentifier(driverName, sizeof(driverName));
    
    if ( StrEqual(driverName, "mysql") )
    {
        Format( sQuery, sizeof( sQuery ), "CREATE TABLE IF NOT EXISTS `gum` ( `id` int NOT NULL AUTO_INCREMENT, \
        `player_id` varchar(32) NOT NULL, \
        `player_name` varchar(32) default NULL, \
        `player_level` int default NULL, \
        `player_unlocks` int default NULL, \
        `purchased` int NOT NULL default 0, \
        PRIMARY KEY (`id`), UNIQUE KEY `player_id` (`player_id`) ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;" );
    }
    else
    {
        Format( sQuery, sizeof( sQuery ), "CREATE TABLE IF NOT EXISTS `gum` ( `id` INTEGER PRIMARY KEY AUTOINCREMENT, \
        `player_id` TEXT NOT NULL UNIQUE, \
        `player_name` TEXT DEFAULT NULL, \
        `player_level` INTEGER DEFAULT NULL, \
        `player_unlocks` INTEGER DEFAULT NULL, \
        `purchased` INTEGER NOT NULL DEFAULT 0 \
         );" );
    }
    
    conDatabase.Query( QueryCreateTable, sQuery);
}
public void QueryCreateTable(Database db, DBResultSet results, const char[] error, any data)
{ 
    if ( db == null )
    {
        LogError( "%s", error ); 
        
        return;
    } 
}
public void querySetDataCallback(Database db, DBResultSet results, const char[] error, any data)
{ 
    if ( db == null )
    {
        LogError( "%s", error ); 
        
        return;
    } 
} 
public void querySelectSavedDataCallback(Database db, DBResultSet results, const char[] error, DataPack pack)
{ 
    if ( db != null )
    {
        int resultRows = results.RowCount;
        
        char sKey[32], pName[32];
        
        pack.Reset();
        int level = pack.ReadCell();
        int unlocks = pack.ReadCell();
        pack.ReadString(sKey, sizeof(sKey));
        pack.ReadString(pName, sizeof(pName));
        delete pack;

        if (resultRows > 0) {
            int dbPurchased = 0;
            while ( results.FetchRow() ) 
            {
                int fieldPurchased;
                results.FieldNameToNum("purchased", fieldPurchased);
                
                dbPurchased = results.FetchInt(fieldPurchased);
            }
            saveData(resultRows, sKey, pName, level, unlocks + dbPurchased);
        } else {
            saveData(resultRows, sKey, pName, level, unlocks);
        }
    } 
    else
    {
        LogError( "%s", error ); 
        
        return;
    }
}
public void querySelectDataCallback(Database db, DBResultSet results, const char[] error, any client)
{ 
    if (error[0] != EOS) {
        LogError( "Server misfunctioning come back later: %s", error );
        KickClientEx(client, "Server misfunctioning come back later!");
        return;
    }
    if ( db != null)
    {
        int unlocks = 0;
        if (results.HasResults) {
            while ( results.FetchRow() ) 
            {
                int fieldUnlocks;
                results.FieldNameToNum("player_unlocks", fieldUnlocks);

                unlocks = results.FetchInt(fieldUnlocks);
                LogMessage("[ GUM ] Player %N loaded with unlocks: %d", client, unlocks);
            }
        } else {
            // TODO something
        }
        setPlayerUnlocks(client, unlocks);
    } 
    else
    {
        LogError( "%s", error ); 
        
        return;
    }
}
public void queryShowTopTableCallback(Database db, DBResultSet results, const char[] error, any client)
{ 
    if ( db != null )
    {
        if ( !UTIL_IsValidClient(client) )
            return;
        
        char name[64], szInfo[128];
        int level;
        //unlocks;

        Menu panel = new Menu(top10PanelHandler);
        panel.SetTitle( "%t", "Menu title: Top 10 players" );

        while ( results.FetchRow() )
        {
            int fieldName, fieldLevel;
            //, fieldUnlocks;
            results.FieldNameToNum("player_name", fieldName);
            results.FieldNameToNum("player_total_reborns", fieldLevel);
            
            results.FetchString( fieldName, name, sizeof(name) );
            level = results.FetchInt(fieldLevel);
            
            ReplaceString(name, sizeof(name), "&lt;", "<");
            ReplaceString(name, sizeof(name), "&gt;", ">");
            ReplaceString(name, sizeof(name), "&#37;", "%");
            ReplaceString(name, sizeof(name), "&#61;", "=");
            ReplaceString(name, sizeof(name), "&#42;", "*");
            
            Format( szInfo, sizeof( szInfo ), "%t", "Menu option: Player format", name, level);

            panel.AddItem("panel_info", szInfo);
        }

        panel.ExitButton = true;
        panel.Display( client, GetConVarInt(cvarMenuTime) );
    } 
    else
    {
        LogError( "%s", error ); 
        
        return;
    }
}
public int top10PanelHandler(Menu menu, MenuAction action, int client, int item)
{
    if (action == MenuAction_End)
    {
        delete menu;
    }
}