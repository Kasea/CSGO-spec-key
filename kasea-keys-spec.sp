#pragma semicolon 1


#define PLUGIN_AUTHOR "Kasea"
#define PLUGIN_VERSION "1.0.0"
#define SPECMODE_FIRSTPERSON 4
#define SPECMODE_3RDPERSON 5
#define MAXSIZEOFBUFFER 256

#include <sourcemod>
#include <sdktools>
#include <security_k>
#include <colors_kasea>
#include <kasea>
#include <clientprefs>
	
public Plugin myinfo = 
{
	name = "Speclist/Showkeys",
	author = PLUGIN_AUTHOR,
	description = "",
	version = PLUGIN_VERSION,
	url = ""
};

bool g_bShowKeys[MAXPLAYERS + 1];
bool g_bShowSpec[MAXPLAYERS + 1];
int g_iButtonsPressed[MAXPLAYERS+1] = {0,...};
bool g_bDisplayJump[MAXPLAYERS+1];
//Handle g_hJumpTimer[MAXPLAYERS+1];
Handle specCookie;
Handle keysCookie;

public void OnPluginStart()
{
	Verification();
	if(licence)
	{
		RegConsoleCmd("sm_spec", Command_spec, "sm_spec <target> - Spectates a player.");
		RegConsoleCmd("sm_spectate", Command_spec, "sm_spectate <target> - Spectates a player.");
		RegConsoleCmd("sm_speclist", Cmd_SpecList);
		RegConsoleCmd("sm_specinfo", Cmd_SpecList);
		RegConsoleCmd("sm_showkeys", Cmd_ShowKeys);
		specCookie = RegClientCookie("kasea-spec", "Should client see spec menu", CookieAccess_Private);
		keysCookie = RegClientCookie("kasea-keys", "Should client see keys menu", CookieAccess_Private);
		LoadTranslations("common.phrases");
	}
}

public OnClientCookiesCached(client)
{
	// Initializations and preferences loading
	if(IsClientInGame(client) && !IsFakeClient(client))
	{
		loadClientCookiesFor(client);
	}
}

loadClientCookiesFor(client)
{
	char buffer[2];

	//Spec menu
	GetClientCookie(client, specCookie, buffer, 2);
	if(StrEqual(buffer, "0", false))
		g_bShowSpec[client] = false;
	else
		g_bShowSpec[client] = true;
	
	//Keys menu
	GetClientCookie(client, keysCookie, buffer, 2);
	if(StrEqual(buffer, "0", false))
		g_bShowKeys[client] = false;
	else
		g_bShowKeys[client] = true;
}

public OnClientPutInServer(client)
{
	// Initializations and preferences loading
	if(!IsFakeClient(client))
	{
		g_bShowKeys[client] = false;
		g_bShowSpec[client] = true;
		if (AreClientCookiesCached(client))
		{
			loadClientCookiesFor(client);
		}
	}
}

public Action Command_spec(int client, int args)
{
	if (args == 0)
	{
		if (IsPlayerAlive(client) && IsClientInGame(client))
		{
			ChangeClientTeam(client, 1);
		}
	}
	if (args == 1)
	{
		if (IsPlayerAlive(client) && IsClientInGame(client))
		{
			ChangeClientTeam(client, 1);
		}
		char arg1[64];
		GetCmdArgString(arg1, sizeof(arg1));

		int target = FindTarget(client, arg1, true, false);
		if (target == -1)
		{
			return Plugin_Handled;
		}
		if (IsClientInGame(target))
		{
			if (!IsPlayerAlive(target))
			{
				ReplyToCommand(client, "[SM] %t", "Target must be alive");
				return Plugin_Handled;
			}
			SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", target);
			SetEntProp(client, Prop_Send, "m_iObserverMode", 4);
		}
		if (!IsClientInGame(target)) ReplyToCommand(client, "[SM] %t", "Target is not in game");
	}
	return Plugin_Handled;
}

/***************

 Game Functions

***************/

public OnMapStart()
{
	CreateTimer(0.1, Timer_UpdateInfo, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
}

public OnClientDisconnect(client)
{
	g_bShowKeys[client] = false;
	g_bShowSpec[client] = false;
	g_iButtonsPressed[client] = 0;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	g_iButtonsPressed[client] = buttons;
	/*if(buttons & IN_JUMP)
	{
		g_bDisplayJump[client] = true;
		if(g_hJumpTimer[client] == INVALID_HANDLE)
			g_hJumpTimer[client] = CreateTimer(0.3, Timer_DisableJump, client);
		else
		{
			KillTimer(g_hJumpTimer[client]);
			g_hJumpTimer[client] = INVALID_HANDLE;
			g_hJumpTimer[client] = CreateTimer(0.3, Timer_DisableJump, client);
		}
	}*/
}


/***************

	 Timers

***************/
/*
public Action Timer_DisableJump(Handle timer, any client)
{
	g_bDisplayJump[client] = false;
	g_hJumpTimer[client] = INVALID_HANDLE;
	return Plugin_Stop;
}
*/

public Action Timer_UpdateInfo(Handle timer)
{
	for (int client = 1; client < Connected(); client++)
	{
		if(IsVoteInProgress() || !IsValidClient_k(client) || (!g_bShowKeys[client] && !g_bShowSpec[client]) || GetClientMenu(client, INVALID_HANDLE) != MenuSource_None)
			continue;
		MakeMenuForClient(client);
	}
	return Plugin_Continue;
}


/***************

	Commands

***************/

public Action Cmd_SpecList(int client, int args)
{
	if(g_bShowSpec[client])
	{
		g_bShowSpec[client] = false;
		SetClientCookie(client, specCookie, "0");
		CPrintToChat(client, "{TEAMCOLOR}Spectator list is {lightred}disabled");
	}else
	{
		g_bShowSpec[client] = true;
		SetClientCookie(client, specCookie, "1");
		if(g_bShowKeys[client])
		{
			CPrintToChat(client, "{TEAMCOLOR}Spectator list and showkeys is now {green}enabled");
		}else
			CPrintToChat(client, "{TEAMCOLOR}Spectator list is {green}enabled");
	}
}

public Action Cmd_ShowKeys(int client, int args)
{
	if(g_bShowKeys[client])
	{
		g_bShowKeys[client] = false;
		SetClientCookie(client, keysCookie, "0");
		CPrintToChat(client, "{TEAMCOLOR}Showkeys is {lightred}disabled");
	}else
	{
		g_bShowKeys[client] = true;
		SetClientCookie(client, keysCookie, "1");
		if(g_bShowKeys[client] && g_bShowSpec[client])
		{
			CPrintToChat(client, "{TEAMCOLOR}Spectator list and showkeys is now {green}enabled");
		}else
			CPrintToChat(client, "{TEAMCOLOR}Showkeys is {green}enabled");
	}
}

/***************

	Get Info

***************/
public int GetSpectatorCount(int client)
{
	int count = 0;

	for(new j = 1; j <= MaxClients; j++)
	{
		if (!IsClientInGame(j) || !IsClientObserver(j))
			continue;

		if (IsClientSourceTV(j))
			continue;

		int iSpecMode = GetEntProp(j, Prop_Send, "m_iObserverMode");

		// The client isn't spectating any one person, so ignore them.
		if (iSpecMode != SPECMODE_FIRSTPERSON && iSpecMode != SPECMODE_3RDPERSON)
			continue;

		// Find out who the client is spectating.
		int iTarget = GetEntPropEnt(j, Prop_Send, "m_hObserverTarget");

		// Are they spectating the same player as User?
		if (iTarget == client && j != client)
		{
			count++;
		}
	}

	return count;
}


/***************

	Print it

***************/
public void MakeMenuForClient(int client)
{
	int mode;
	bool ShouldDisplay = ShouldDisplaySpecList(client);
	if(g_bShowKeys[client] && g_bShowSpec[client] && ShouldDisplay)
	{
		mode = 3;
	}else if(g_bShowSpec[client] && ShouldDisplay)
	{
		mode = 2;
	}else if(g_bShowKeys[client])
	{
		mode = 1;
	}else if(ShouldDisplay)
	{
		//PrintToChatAll("Failed to make a menu for client. The current settings for the client is: Showkeys = %b, Speclist = %b, and Should the speclist be displayed = %b. || Tell Kasea!", g_bShowKeys[client], g_bShowSpec[client], ShouldDisplaySpecList(client));
		return;
	}else if(g_bShowSpec[client] && !ShouldDisplay)
		return;
		
	char buffer[MAXSIZEOFBUFFER];
	CreateTheOutput(UpdateClientInfo(client), buffer, sizeof(buffer), mode);
	Handle menuhandle = CreateMenu(MenuCallBack);
	SetMenuTitle(menuhandle, "%s", buffer);
	AddMenuItem(menuhandle, "but1", "1", ITEMDRAW_NOTEXT);
	AddMenuItem(menuhandle, "but3", "3", ITEMDRAW_RAWLINE);
	SetMenuPagination(menuhandle, MENU_NO_PAGINATION);
	SetMenuExitButton(menuhandle, false);
	if(ShouldDisplayMenu(client))
		DisplayMenu(menuhandle, client, 0.1);
	CloseHandle(menuhandle);
}


public void CreateTheOutput(int client, char[] input, int maxsize, int mode)
{
	char Output[MAXSIZEOFBUFFER];
	switch(mode)
	{
		//Just showkeys
		case 1:
		{
			FormatShowKeys(client, Output, sizeof(Output));
		}
		//Just speclist
		case 2:
		{
			FormatSpecList(client, Output, sizeof(Output));
		}
		//both
		case 3:
		{
			char SpecList[128];
			char ShowKeys[128];
			FormatShowKeys(client, ShowKeys, sizeof(ShowKeys));
			FormatSpecList(client, SpecList, sizeof(SpecList));
			Format(Output, sizeof(Output), "%s\n\n%s", SpecList, ShowKeys);				
		}
	}
	strcopy(input, maxsize, Output);
}

/***************

Custom functions

***************/
public bool ShouldDisplayMenu(int client)
{
	int iSpecMode = GetEntProp(client, Prop_Send, "m_iObserverMode");
	if(!IsPlayerAlive(client) && iSpecMode != SPECMODE_FIRSTPERSON && iSpecMode != SPECMODE_3RDPERSON)
		return false;
	else
		return true;
}

//Check if the client has any spectators, if he does then return true, if not return false. Check if the target is dead, if it is then check the other client
public bool ShouldDisplaySpecList(int iClient)
{
	return (GetSpectatorCount(UpdateClientInfo(iClient)) != 0);
	/*int client = UpdateClientInfo(iClient);
	if(GetSpectatorCount(client) == 0)
		return false;
	else
		return true;*/
}

public void FormatShowKeys(int client, char[] input, int maxsize)
{
	char sOutput[MAXSIZEOFBUFFER];
	int iButtons = g_iButtonsPressed[client];
	
	// Is he pressing "w"?
	if(iButtons & IN_FORWARD)
		Format(sOutput, sizeof(sOutput), "Key presses:\n      W\n");
	else
		Format(sOutput, sizeof(sOutput), "Key presses:\n      -\n");
	
	// Is he pressing "a"?
	if(iButtons & IN_MOVELEFT)
		Format(sOutput, sizeof(sOutput), "%s  A ", sOutput);
	else
		Format(sOutput, sizeof(sOutput), "%s  - ", sOutput);
		
	// Is he pressing "s"?
	if(iButtons & IN_BACK)
		Format(sOutput, sizeof(sOutput), "%s  S ", sOutput);
	else
		Format(sOutput, sizeof(sOutput), "%s  - ", sOutput);
		
	// Is he pressing "d"?
	if(iButtons & IN_MOVERIGHT)
		Format(sOutput, sizeof(sOutput), "%s  D \n", sOutput);
	else
		Format(sOutput, sizeof(sOutput), "%s  - \n", sOutput);
		
	// Is he pressing "ctrl"?
	if(iButtons & IN_DUCK)
		Format(sOutput, sizeof(sOutput), "%s      DUCK", sOutput);
	else
		Format(sOutput, sizeof(sOutput), "%s      -", sOutput);
	
	// Is he pressing "space"?
	//if(g_bDisplayJump[client])
	if(iButtons & IN_JUMP)
		Format(sOutput, sizeof(sOutput), "%s JUMP", sOutput);
	else
		Format(sOutput, sizeof(sOutput), "%s -", sOutput);
		
	strcopy(input, maxsize, sOutput);
}

public void FormatSpecList(int client, char[] input, int maxsize)
{
	char buffer[MAXSIZEOFBUFFER];
	int spec_count = GetSpectatorCount(client);
	int count = 0;
	for(new j = 1; j <= MaxClients; j++)
	{
		if (!IsClientInGame(j) || !IsClientObserver(j))
			continue;

		if (IsClientSourceTV(j))
			continue;

		int iSpecMode = GetEntProp(j, Prop_Send, "m_iObserverMode");

		// The client isn't spectating any one person, so ignore them.
		if (iSpecMode != SPECMODE_FIRSTPERSON && iSpecMode != SPECMODE_3RDPERSON)
			continue;

		// Find out who the client is spectating.
		int iTarget = GetEntPropEnt(j, Prop_Send, "m_hObserverTarget");

		// Are they spectating the same player as User?
		if (iTarget == client && j != client)
		{
			count++;
			if(count>5)
			{
				//More then 5 people speccing
			}else if(spec_count == count)
			{
				//Last page and it's not over 5
				Format(buffer, sizeof(buffer), "%s%N", buffer, j);
			}else
			{
				//Not over 5 spectators yet and not last person
				Format(buffer, sizeof(buffer), "%s%N\n", buffer, j);
			}
			/*Format(buffer, sizeof(buffer), "%s%N \n", buffer, i);
			if(spec_count == count)
			{
				Format(buffer, sizeof(buffer), "%s%N", buffer, j);
			}
			else
			{
				Format(buffer, sizeof(buffer), "%s%N\n", buffer, j);
			}
			*/
		}
	}
	if(spec_count>5)
		Format(buffer, sizeof(buffer), "%s...(+%i)", buffer, spec_count-5);
	Format(buffer, sizeof(buffer), "Spectator list: (%d) \n%s", spec_count, buffer);
	strcopy(input, maxsize, buffer);
}

/***************

  MenuCallBack

***************/
public int MenuCallBack(Menu menu, MenuAction action, int iClient, int position) 
{ 
     
}  