#pragma semicolon 1

// SetEntData(client, g_offsCollisionGroup, 5, 4, true); // CAN NOT PASS THRU ie: Players can jump on each other
// SetEntData(client, g_offsCollisionGroup, 2, 4, true); // Noblock active ie: Players can walk thru each other

#include <sourcemod>
#include <multicolors>
#include <sdktools>
#include <sdkhooks>

#pragma newdecls required

#define PLUGIN_VERSION  "2.2"
#define MESSAGE 		"{green}[NoBlock] {default}%t"

int g_CollisionOffset;

Handle sm_grenplayer_noblock_version = INVALID_HANDLE;
Handle sm_noblock_grenades = INVALID_HANDLE;
Handle sm_noblock_players = INVALID_HANDLE;
Handle sm_noblock_allow_block = INVALID_HANDLE;
Handle sm_noblock_allow_block_time = INVALID_HANDLE;
Handle sm_noblock_notify = INVALID_HANDLE;

public Plugin myinfo =
{
	name = "Noblock players and Nades",
	author = "Originally by Tony G., Fixed by Rogue, Updated by maxime1907",
	description = "Manipulates players and grenades so they can't block each other",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

public void OnPluginStart()
{
	LoadTranslations("noblock.phrases");
	
	char modname[50];
	GetGameFolderName(modname, sizeof(modname));
	if(!StrEqual(modname,"cstrike",false))
		SetFailState("Sorry! This plugin only works on Counter-Strike: Source.");

	g_CollisionOffset = FindSendPropInfo("CBaseEntity", "m_CollisionGroup");   

	HookEvent("player_spawn", Event_PlayerSpawn);
	
	RegConsoleCmd("sm_block", Command_NoBlock);
	
	sm_grenplayer_noblock_version = CreateConVar("sm_grenplayer_noblock_version", PLUGIN_VERSION, "Noblock Version; not changeable", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	sm_noblock_grenades = CreateConVar("sm_noblock_grenades", "1", "Enables/Disables blocking of grenades; 0 - Disabled, 1 - Enabled");
	sm_noblock_players = CreateConVar("sm_noblock_players", "1", "Removes player vs. player collisions");
	sm_noblock_allow_block = CreateConVar("sm_noblock_allow_block", "1", "Allow players to use say !block; 0 - Disabled, 1 - Enabled");
	sm_noblock_allow_block_time = CreateConVar("sm_noblock_allow_block_time", "20.0", "Time limit to say !block command", 0, true, 0.0, true, 600.0);
	sm_noblock_notify = CreateConVar("sm_noblock_notify", "1", "Enables/Disables chat messages; 0 - Disabled, 1 - Enabled");
	
	HookConVarChange(sm_noblock_players, OnConVarChange);
	SetConVarString(sm_grenplayer_noblock_version, PLUGIN_VERSION);
	AutoExecConfig(true);
}

public void OnConVarChange(Handle hCvar, const char[] oldValue, const char[] newValue)
{
	if (hCvar == sm_noblock_players)
	{
		if (GetConVarInt(sm_noblock_players) == 1)
		{
			UnblockClientAll();
		}
		else
		{
			BlockClientAll();

			if (GetConVarInt(sm_noblock_notify) == 1)
				CPrintToChatAll(MESSAGE, "noblock disabled");
		}
	}
}

public void Event_PlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	int userid = GetEventInt(event, "userid");
	int client = GetClientOfUserId(userid);
	
	if (GetConVarInt(sm_noblock_players) == 1)
	{
		EnableNoBlock(client);
	}
}

public Action Command_NoBlock(int client, int args)
{
	if (GetConVarInt(sm_noblock_players) == 1 && (GetConVarInt(sm_noblock_allow_block) == 1))
	{
		float Time;
		char nbBuffer[128] = "";
		Time = GetConVarFloat(sm_noblock_allow_block_time);

		CreateTimer(Time, Timer_UnBlockPlayer, client);

		Format(nbBuffer, sizeof (nbBuffer), "%T", "now solid", LANG_SERVER, Time);

		if (GetConVarInt(sm_noblock_notify) == 1)
			CPrintToChat(client, MESSAGE, "now solid", Time);

		EnableBlock(client);
	}
	return Plugin_Handled;
}

public Action Timer_UnBlockPlayer(Handle timer, any client)
{
	if(!IsClientInGame(client) && !IsPlayerAlive(client))
	{
		return Plugin_Continue;
	}
	EnableNoBlock(client);
	return Plugin_Continue;
}

public void EnableBlock(int client)
{
	SetEntData(client, g_CollisionOffset, 5, 4, true);
}

public void EnableNoBlock(int client)
{
	if (GetConVarInt(sm_noblock_notify) == 1)
		CPrintToChat(client, MESSAGE, "noblock enabled");

	SetEntData(client, g_CollisionOffset, 2, 4, true);

	if (GetConVarInt(sm_noblock_allow_block) == 1 && (GetConVarInt(sm_noblock_notify) == 1))
		CPrintToChat(client, MESSAGE, "block for solid");
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (GetConVarInt(sm_noblock_grenades) == 1)
	{
		if (StrEqual(classname, "hegrenade_projectile"))
		{
			SetEntData(entity, g_CollisionOffset, 2, 1, true);
		}
		
		if (StrEqual(classname, "flashbang_projectile"))
		{
			SetEntData(entity, g_CollisionOffset, 2, 1, true);
		}
		
		if (StrEqual(classname, "smokegrenade_projectile"))
		{
			SetEntData(entity, g_CollisionOffset, 2, 1, true);
		}
	}
}

public void BlockClientAll()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i))
		{
			EnableBlock(i);
		}
	}
}

public void UnblockClientAll()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i))
		{
			EnableNoBlock(i);
		}
	}
}