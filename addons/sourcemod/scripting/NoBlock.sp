#pragma semicolon 1

// SetEntData(client, g_offsCollisionGroup, 5, 4, true); // CAN NOT PASS THRU ie: Players can jump on each other
// SetEntData(client, g_offsCollisionGroup, 2, 4, true); // Noblock active ie: Players can walk thru each other

#include <sourcemod>
#include <multicolors>
#include <sdktools>
#include <sdkhooks>

#pragma newdecls required

#define MESSAGE 		"{green}[NoBlock] {default}%t"

int g_CollisionOffset;

ConVar g_cvGrenades;
ConVar g_cvPlayers;
ConVar g_cvAllowBlock;
ConVar g_cvAllowBlockTime;
ConVar g_cvNotify;

public Plugin myinfo =
{
	name = "Noblock players and Nades",
	author = "Originally by Tony G., Fixed by Rogue, Updated by maxime1907, .Rushaway",
	description = "Manipulates players and grenades so they can't block each other",
	version = "2.2.3",
	url = "http://www.sourcemod.net/"
};

public void OnPluginStart()
{
	LoadTranslations("noblock.phrases");

	EngineVersion engine = GetEngineVersion();
	if (engine != Engine_CSS && engine != Engine_CSGO)
		SetFailState("Sorry! This plugin only works on Counter-Strike: Source and Counter-Strike: Global Offensive.");

	g_CollisionOffset = FindSendPropInfo("CBaseEntity", "m_CollisionGroup");

	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);

	RegConsoleCmd("sm_block", Command_NoBlock);

	g_cvGrenades = CreateConVar("sm_noblock_grenades", "1", "Enables/Disables blocking of grenades; 0 - Disabled, 1 - Enabled", _, true, 0.0, true, 1.0);
	g_cvPlayers = CreateConVar("sm_noblock_players", "1", "Removes player vs. player collisions", _, true, 0.0, true, 1.0);
	g_cvAllowBlock = CreateConVar("sm_noblock_allow_block", "1", "Allow players to use say !block; 0 - Disabled, 1 - Enabled", _, true, 0.0, true, 1.0);
	g_cvAllowBlockTime = CreateConVar("sm_noblock_allow_block_time", "20.0", "Time limit to say !block command", 0, true, 0.0, true, 600.0);
	g_cvNotify = CreateConVar("sm_noblock_notify", "1", "Enables/Disables chat messages; 0 - Disabled, 1 - Enabled", _, true, 0.0, true, 1.0);

	g_cvPlayers.AddChangeHook(OnConVarChange);

	AutoExecConfig(true);
}

public void OnConVarChange(Handle hCvar, const char[] oldValue, const char[] newValue)
{
	if (g_cvPlayers.BoolValue)
		UnblockClientAll();
	else
	{
		BlockClientAll();

		if (g_cvNotify.BoolValue)
			CPrintToChatAll(MESSAGE, "noblock disabled");
	}
}

public Action Event_PlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	if (g_cvPlayers.BoolValue)
	{
		int userid = GetEventInt(event, "userid");
		int client = GetClientOfUserId(userid);
		if (IsClientInGame(client))
			EnableNoBlock(client);
	}
	return Plugin_Continue;
}

public Action Command_NoBlock(int client, int args)
{
	if (g_cvPlayers.BoolValue && g_cvAllowBlock.BoolValue)
	{
		float Time = g_cvAllowBlockTime.FloatValue;
		CreateTimer(Time, Timer_UnBlockPlayer, client);

		if (g_cvNotify.BoolValue)
		{
			char nbBuffer[128] = "";
			SetGlobalTransTarget(client);
			Format(nbBuffer, sizeof (nbBuffer), "%t", "now solid", client, Time);
			CPrintToChat(client, MESSAGE, "now solid", Time);
		}

		EnableBlock(client);
	}
	return Plugin_Handled;
}

public Action Timer_UnBlockPlayer(Handle timer, any client)
{
	if (!IsClientInGame(client) && !IsPlayerAlive(client))
		return Plugin_Continue;

	EnableNoBlock(client);
	return Plugin_Continue;
}

public void EnableBlock(int client)
{
	SetEntData(client, g_CollisionOffset, 5, 4, true);
}

public void EnableNoBlock(int client)
{
	if (g_cvNotify.BoolValue)
	{
		SetGlobalTransTarget(client);
		CPrintToChat(client, MESSAGE, "noblock enabled");
	}

	SetEntData(client, g_CollisionOffset, 2, 1, true);

	if (g_cvAllowBlock.BoolValue && g_cvNotify.BoolValue)
		CPrintToChat(client, MESSAGE, "block for solid");
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (g_cvGrenades.BoolValue)
	{
		if (StrContains(classname, "_projectile") != -1)
			SetEntData(entity, g_CollisionOffset, 2, 1, true);
	}
}

public void BlockClientAll()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i))
			EnableBlock(i);
	}
}

public void UnblockClientAll()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i))
			EnableNoBlock(i);
	}
}