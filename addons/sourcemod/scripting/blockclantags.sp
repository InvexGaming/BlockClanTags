#include <sourcemod> 
#include <cstrike>

#pragma semicolon 1
#pragma newdecls required

//Defines
#define VERSION "1.00"
#define CLAN_TAG_MAX_LENGTH 13 //12 chars + null terminator

//ConVars
ConVar g_Cvar_ReplacementClanTag = null;

//ArrayList
ArrayList g_BannedTags;

public Plugin myinfo =
{
  name = "Block Clan Tags",
  author = "Invex | Byte",
  description = "Blocks banned clan tags from displaying.",
  version = VERSION,
  url = "http://www.invexgaming.com.au"
};

public void OnPluginStart()
{
  g_BannedTags = new ArrayList(CLAN_TAG_MAX_LENGTH);
  
  ParseBannedTags();
  
  //ConVars
  g_Cvar_ReplacementClanTag = CreateConVar("sm_blockclantags_replacementclantag", "", "String to replace banned clan tags with.");
  
  AutoExecConfig(true, "blockclantags");
  
  //Hooks
  HookEvent("player_spawn", Event_PlayerSpawn); 
  
  //Process all players
  for (int i = 1; i <= MaxClients; ++i) {
    OnClientPutInServer(i);
  }
}

public void OnClientPutInServer(int client)
{
  ProcessPlayer(client);
}

public void OnClientSettingsChanged(int client)
{
  ProcessPlayer(client);
}

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast) 
{
  int client = GetClientOfUserId(event.GetInt("userid"));
  ProcessPlayer(client);
}

void ProcessPlayer(int client)
{
  if (!IsClientInGame(client) || IsFakeClient(client))
    return;
    
  char currentClanTag[CLAN_TAG_MAX_LENGTH];
  CS_GetClientClanTag(client, currentClanTag, sizeof(currentClanTag));
  
  if (g_BannedTags.FindString(currentClanTag) != -1) {
    char replacementClanTag[CLAN_TAG_MAX_LENGTH];
    g_Cvar_ReplacementClanTag.GetString(replacementClanTag, sizeof(replacementClanTag));
    CS_SetClientClanTag(client, replacementClanTag);
  }
}

public void ParseBannedTags()
{
  g_BannedTags.Clear();
  
  //Read config file
  char configFilePath[PLATFORM_MAX_PATH];
  Format(configFilePath, sizeof(configFilePath), "configs/blockclantags.txt");
  BuildPath(Path_SM, configFilePath, PLATFORM_MAX_PATH, configFilePath);
  
  if (FileExists(configFilePath)) {
    //Open config file
    File file = OpenFile(configFilePath, "r");
    
    if (file != null) {
      char buffer[PLATFORM_MAX_PATH];
      
      //For each file in the text file
      while (file.ReadLine(buffer, sizeof(buffer))) {
        //Remove final new line
        //buffer length > 0 check needed in case file is completely empty and there is no new line '\n' char after empty string ""
        if (strlen(buffer) > 0 && buffer[strlen(buffer) - 1] == '\n')
          buffer[strlen(buffer) - 1] = '\0';
        
        //Remove any whitespace at either end
        TrimString(buffer);
        
        //Ignore empty lines
        if (strlen(buffer) == 0)
          continue;
          
        //Ignore comment lines or text after a comment
        int commentOffset = StrContains(buffer, "//");
        
        if (commentOffset == 0) //full line comment
          continue;
          
        if (commentOffset != -1) //partial comment
          buffer[commentOffset] = '\0';
        
        //Remove any whitespace at either end
        TrimString(buffer);
        
        //Add banned tag to our list
        g_BannedTags.PushString(buffer);
      }
      
      file.Close();
    } else {
      SetFailState("Failed to open config file.");
    }
  } else {
    SetFailState("Failed to find config file.");
  }
}