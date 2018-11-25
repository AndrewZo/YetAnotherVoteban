/*	Yet Another Voteban AMXX Plugin
		— удобный и симпатичный голосовальщик за бан игроков, для Ваших великолепных серверов Counter-Strike 1.6.
	
	Версия: 1.8
	

 	Авторы: AndrewZ и voed.
	
	
	Команды:
	
	say /voteban 
		— Меню с выбором игроков для голосования.
	
	say_team /voteban
		— Меню с выбором игроков для голосования.
		
	amx_votebanmenu
		— Главное меню голосования.
		

	Переменные:

	yav_time_default <time in minutes>
		— Стандартное время бана в минутах, доступное игрокам.
		— По умолчанию: "5"
	
	yav_time <time in minutes, up to five values>
		— Дополнительное время бана в минутах для игроков с флагом доступа "yav_time_access".
		— От 1 до 5 значений через пробел.
		— По умолчанию: "5 15 30 60 180"

	yav_ban_type <-2|-1|1|2|3|4|5>
		— Тип бана:
		— "-2"	— BANID (STEAMID);
		— "-1"	— ADDIP; 
		— "1"	— AMXBANS; 
		— "2"	— FRESHBANS; 
		— "3"	— ADVANCED BANS; 
		— "4"	— SUPERBAN; 
		— "5"	— MULTIBAN.
		— По умолчанию: "2"

	yav_ban_reason <0|1|2>
		— Выбор причны бана. 
			— Причины добавляются в файл \\data\lang\yet_another_voteban.txt для каждого из языков в неограниченном количестве.
			— Если лень переводить, то можете добавлять только для одного основного языка — это на ваше усмотрение. Но в таком случае удалите ключи причин у остальных языков, чтобы не конфликтовали.
			— Обязательно нумеруйте названия ключей, т.е  VOTEBAN_ADD_REASON_1,  VOTEBAN_ADD_REASON_2 и т.д...
			— Пример: VOTEBAN_ADD_REASON_1 = Читы.
		— "0" = ручной ввод + заранее подготовленные причины; 
		— "1" = только ручной ввод; 
		— "2" = только заранее подготовленные причины. 
		— По умолчанию: "0"

	yav_delay <time in minutes>
		— Задержка между голосованиями для каждого игрока отдельно.
		— По умолчанию: "5"

	yav_duration <time in seconds>
		— Длительность голосования в секундах.
		— По умолчанию: "15"

	yav_percent <percent>
		— Необходимый процент проголосовавших игроков для осуществления бана.
		— По умолчанию: "60"

	yav_min_votes <number>
		— Необходимый минимум голосов за бан для того, чтобы голосование вообще могло состояться.
		— Минимальное значение: "2"
		— По умолчанию: "2"

	yav_spec_admins <1|0>
		— Учитывать ли админов в команде наблюдателей как активных при подборе для оповещения, при установленном значении "yav_admin_access".
		— "1" = учитывать;
		— "0" = пропускать.
		— По умолчанию: "0"

	yav_roundstart_delay <-2|-1|time in seconds>
		— Блокировка вызова голосования в начале раунда, в секундах. Например, чтобы не сбивать меню покупки игрокам.
		— Укажите положительное дробное или целое значение для блокировки на указанное время, либо:
		— "-1" = блокировка до конца mp_buytime; 
		— "-2" = блокировка до конца mp_freezetime; 
		— "0" = отключить, не блокировать.
		— По умолчанию: "-2"
	
	При указани флагов можно назначить несколько: "abc", либо оставить пустым "", чтобы отключить функцию/разрешить использовать всем:

	yav_access <flags>
		— Флаг(и) доступа к меню голосования. 
		— По умолчанию: ""

	yav_time_access <flags>
		— Флаг(и) доступа к выбору времени бана "yav_time" и к голосованию без задржки "yav_delay".
		— По умолчанию: "с"

	yav_admin_access <flags>
		— Флаг(и) админа для блока голосования и включения оповещения админов.
		— По умолчанию: "d"
		
	yav_immunity_access <flags>
		— Флаг(и) иммунитета к вотебану.
		— По умолчанию: "a"
		
	yav_log_to_file <0|1>
		— Логирование банов в файл (\\addons\amxmodx\logs\YAV_ГГГГММДД.log).
		— "0" = выкл;
		— "1" = вкл.
		— По умолчанию: "1"
*/

//#define DEBUG

#include <amxmodx>

#define PLUGIN		"Yet Another Voteban"
#define VERSION		"1.8"
#define AUTHOR		"AndrewZ/voed"

#define MSGS_PREFIX		"YAV"

#define TID_ENDVOTE		5051
#define TID_BLOCKVOTE	5052

enum
{
	MENU_SOUND_SELECT, // 0
	MENU_SOUND_DENY, // 1
	MENU_SOUND_SUCCESS // 2
}

new g_pcvr_DefaultTime,		g_pcvr_Time,			g_pcvr_BanType,		g_pcvr_BanReason,	g_pcvr_Delay,
	g_pcvr_Duration,		g_pcvr_Percent,			g_pcvr_MinVotes,	g_pcvr_SpecAdmins,	g_pcvr_RoundStartDelay, 
	g_pcvr_mpBuyTime,		g_pcvr_mpFreezeTime,	g_pcvr_Access,		g_pcvr_TimeAccess,	g_pcvr_AdminAccess, 
	g_pcvr_ImmunityAccess,	g_pcvr_LogToFile

new g_szMenuSounds[][] =
{
	"buttons/lightswitch2.wav", // 0
	"buttons/button2.wav", // 1
	"buttons/blip1.wav" // 2
}

new g_szUserReason[ MAX_PLAYERS + 1 ][ 64 ],
	g_iUserSelectedID[ MAX_PLAYERS + 1 ],
	g_iUserBanTime[ MAX_PLAYERS + 1 ],
	g_iTotalVotes[ MAX_PLAYERS + 1 ],
	g_iUserGametime[ MAX_PLAYERS + 1 ]

new g_szInitiator[ 3 ][ 35 ],
	g_iBanID,
	g_iBanTime,
	g_szBanReason[ 64 ]
	
new bool:g_bIsVoteStarted, bool:g_bIsVoteBlocked
new g_szParsedCvarTime[ 5 ][ 8 ]

public plugin_precache()
{
	new i
	
	for( i = 0; i < sizeof g_szMenuSounds; i ++ )
		precache_sound( g_szMenuSounds[ i ] )
}

public plugin_init()
{
	register_plugin( PLUGIN, VERSION, AUTHOR )
	
	set_pcvar_string( register_cvar( "yav_version", VERSION, FCVAR_SPONLY | FCVAR_SERVER ), VERSION )

	g_pcvr_DefaultTime =		create_cvar( "yav_time_default", "5", _, "Default ban time for all non-privileged players." )
	g_pcvr_Time =				create_cvar( "yav_time", "5 15 30 60 180", _, "From 1 to 5 additional ban times for 'yav_time_access' cvar." )
	g_pcvr_BanType =			create_cvar( "yav_ban_type", "2", _, "Ban type: -2 = BANID; -1 = ADDIP; 1 = AMXBANS; 2 = FRESHBANS; 3 = ADVANCED BANS; 4 = SUPERBAN; 5 = MULTIBAN", true, -2.0, true, 5.0 )
	g_pcvr_BanReason =			create_cvar( "yav_ban_reason", "0", _, "Ban reason input method: 0 = manual + prepared; 1 = only manual; 2 = only prepared.", true, 0.0, true, 2.0 )
	g_pcvr_Delay =				create_cvar( "yav_delay", "5", _, "Delay before previous vote (in minutes) for each player.", true, 0.0 )
	g_pcvr_Duration =			create_cvar( "yav_duration", "15", _, "Duration of the vote (in seconds).", true, 5.0 )
	g_pcvr_Percent =			create_cvar( "yav_percent", "60", _, "Percent of positive votes of total players that required for ban success.", true, 1.0, true, 100.0 )
	g_pcvr_MinVotes =			create_cvar( "yav_min_votes", "2", _, "Minimal number of positive votes that required for success.", true, 2.0, true, 31.0 )
	g_pcvr_SpecAdmins =			create_cvar( "yav_spec_admins", "0", _, "Will plugin select admins in the Spectators team for Notify feature, or just skip them.", true, 0.0, true, 1.0 )
	g_pcvr_RoundStartDelay =	create_cvar( "yav_roundstart_delay", "-2", _, "Block the vote at round start: -2 = by mp_freezetime; -1 = by mp_buytime; 0 = disable; or any positive value.", true, -2.0 )
	g_pcvr_Access =				create_cvar( "yav_access", "", _, "Flags just for access to voteban feature." )
	g_pcvr_TimeAccess =			create_cvar( "yav_time_access", "c", _, "Access flags for additional ban time 'yav_time'." )
	g_pcvr_AdminAccess =		create_cvar( "yav_admin_access", "d", _, "Access flags for admins with their own ban-menu for Notify feature." )
	g_pcvr_ImmunityAccess =		create_cvar( "yav_immunity_access", "a", _, "Access flags for immunity to the vote for ban." )
	g_pcvr_LogToFile =			create_cvar( "yav_log_to_file", "1", _, "Log all successful bans to file '\\addons\amxmodx\logs\YAV_YYYYMMDD.log'.", true, 0.0, true, 1.0 )
	
	g_pcvr_mpBuyTime =			get_cvar_pointer( "mp_buytime" )
	g_pcvr_mpFreezeTime =		get_cvar_pointer( "mp_freezetime" )
	
	register_event( "HLTV", "event_newround", "a", "1=0", "2=0" )
	
	register_clcmd( "say /voteban", "show_voteban_players_menu", _, "- show players menu for voteban" )
	register_clcmd( "say_team /voteban", "show_voteban_players_menu", _, "- show players menu for voteban" )
	register_clcmd( "amx_votebanmenu", "show_voteban_main_menu", _, "- show voteban menu" )
	
	register_clcmd( "voteban_reason", "cmd_voteban_reason" )

	register_dictionary( "yet_another_voteban.txt" )
}

public plugin_cfg()
{
	new szData[ 44 ]; get_pcvar_string( g_pcvr_Time, szData, charsmax( szData ) )
	
	parse( szData,	g_szParsedCvarTime[ 0 ], 7,
					g_szParsedCvarTime[ 1 ], 7,
					g_szParsedCvarTime[ 2 ], 7,
					g_szParsedCvarTime[ 3 ], 7,
					g_szParsedCvarTime[ 4 ], 7 )
}

public event_newround()
{
	new Float:f_pCvrRSDelay
	f_pCvrRSDelay = get_pcvar_float( g_pcvr_RoundStartDelay )
	
	if( f_pCvrRSDelay == 0.0 )
	{
		g_bIsVoteBlocked = false
		return
	}

	if( task_exists( TID_BLOCKVOTE ) )
		remove_task( TID_BLOCKVOTE )
	
	if( f_pCvrRSDelay == -1.0 )
		f_pCvrRSDelay = get_pcvar_float( g_pcvr_mpBuyTime ) * 60
	else if( f_pCvrRSDelay == -2.0 )
		f_pCvrRSDelay = get_pcvar_float( g_pcvr_mpFreezeTime )
	
	g_bIsVoteBlocked = true
	set_task( f_pCvrRSDelay, "task_unblock_vote", TID_BLOCKVOTE )
}

public task_unblock_vote()
	g_bIsVoteBlocked = false
	
public client_connect( id )
	clear_user_voteban_data( id )

public client_disconnected( id )
{
	clear_user_voteban_data( id )
	
	if( ( g_iBanID == id ) && g_bIsVoteStarted )
	{
		new i
		
		for( i = 1; i <= MAX_PLAYERS; i ++ )
		{
			if( is_user_connected( i ) )
				yet_another_print_color( i, "%L", i, "VOTEBAN_PLAYER_LEFT", id ) // Игрок %n вышел, голосование отменено.
		}
		
		clear_voteban_data()
	}
}

public clear_user_voteban_data( id )
{
	g_iUserSelectedID[ id ] = 0
	g_iUserBanTime[ id ] = get_pcvar_num( g_pcvr_DefaultTime )
	arrayset( g_szUserReason[ id ], 0, sizeof( g_szUserReason ) )
}

public clear_voteban_data()
{
	if( task_exists( TID_ENDVOTE ) )
		remove_task( TID_ENDVOTE )
	
	g_bIsVoteStarted = false
	g_iBanID = 0
	g_iBanTime = 0
	arrayset( g_szBanReason, 0, sizeof( g_szBanReason ) )
	arrayset( g_iTotalVotes, 0, MAX_PLAYERS + 1 )
}

public cmd_voteban_reason( id )
{
	new i, szArgs[ 64 ], szBlock[][] = { "!g", "!y", "!t", "%", "#", "", "", "", "", ";", "\", ^"^^" }
	
	read_args( szArgs, charsmax( szArgs ) )
	remove_quotes( szArgs )
	
	for( i = 0; i < sizeof( szBlock ); i ++ )
		replace_all( szArgs, charsmax( szArgs ), szBlock[ i ], "" )
	
	g_szUserReason[ id ] = szArgs
	
	show_voteban_main_menu( id )
	
	return PLUGIN_HANDLED
}

public show_voteban_players_menu( id )
{
	if( !is_voteban_available( id ) )
		return PLUGIN_HANDLED
	
	new iMenu, i, szTemp[ 64 ], szFlags[ 24 ], szId[ 3 ]
	
	formatex( szTemp, charsmax( szTemp ), "\y%L\R", id, "VOTEBAN_MENU_PLAYERS_TITLE" ) // Выбор игрока
	iMenu = menu_create( szTemp, "handler_voteban_players_menu" )
	
	for( i = 1; i <= MAX_PLAYERS; i ++ )
	{
		if( !get_user_status( i ) || ( i == id ) )
			continue
		
		get_pcvar_string( g_pcvr_ImmunityAccess, szFlags, charsmax( szFlags ) )
		
		if( get_user_flags( i ) & read_flags( szFlags ) )
			formatex( szTemp, charsmax( szTemp ), "\d%n \r*", i )
		else
			formatex( szTemp, charsmax( szTemp ), "\w%n", i )
		
		num_to_str( i, szId, charsmax( szId ) )
		
		menu_additem( iMenu, szTemp, szId, ADMIN_ALL )
	}
	
	if( !menu_items( iMenu ) )
	{
		menu_destroy( iMenu )
		return PLUGIN_HANDLED
	}
	
	formatex( szTemp, charsmax( szTemp ), "%L", id, "VOTEBAN_MENU_BACK" )
	menu_setprop( iMenu, MPROP_BACKNAME, szTemp )
	
	formatex( szTemp, charsmax( szTemp ), "%L", id, "VOTEBAN_MENU_NEXT" )
	menu_setprop( iMenu, MPROP_NEXTNAME, szTemp )
	
	formatex( szTemp, charsmax( szTemp ), "%L", id, "VOTEBAN_MENU_EXIT" )
	menu_setprop( iMenu, MPROP_EXITNAME, szTemp )
	
	menu_setprop( iMenu, MPROP_NUMBER_COLOR, "\w" )
	
	menu_display( id, iMenu, 0 )
	
	return PLUGIN_HANDLED
}

public handler_voteban_players_menu( id, iMenu, iItem )
{
	if( !is_voteban_available( id ) || ( iItem == MENU_EXIT ) )
	{
		menu_destroy( iMenu )
		client_send_audio( id, MENU_SOUND_SELECT )
		
		return PLUGIN_HANDLED
	}
	
	new szData[ 3 ], szItemName[ 32 ], iAccess, iCallback, iSelectedID
	menu_item_getinfo( iMenu, iItem, iAccess, szData, charsmax( szData ), szItemName, charsmax( szItemName ), iCallback )
	
	iSelectedID = str_to_num( szData )
	
	if( get_user_status( iSelectedID ) )
	{
		new szFlags[ 24 ]
		get_pcvar_string( g_pcvr_ImmunityAccess, szFlags, charsmax( szFlags ) )
	
		if( !( get_user_flags( iSelectedID ) & read_flags( szFlags ) ) )
		{
			g_iUserSelectedID[ id ] = iSelectedID
			show_voteban_main_menu( id )
			client_send_audio( id, MENU_SOUND_SELECT )
		}
		else
		{
			show_voteban_players_menu( id )
			yet_another_print_color( id, "%L", id, "VOTEBAN_IMMUNITY" ) // Выбранный игрок имеет иммунитет к бану.
			client_send_audio( id, MENU_SOUND_DENY )
		}
	}
	else
	{
		yet_another_print_color( id, "%L", id, "VOTEBAN_LEAVE" ) // Выбранный игрок недоступен для выбора, возможно он покинул сервер.
		client_send_audio( id, MENU_SOUND_DENY )
	}
	
	client_send_audio( id, MENU_SOUND_SELECT )

	menu_destroy( iMenu )
	
	return PLUGIN_HANDLED
}

public show_voteban_main_menu( id )
{
	if( !is_voteban_available( id ) )
		return PLUGIN_HANDLED
	
	new iMenu, szTemp[ 64 ], iSelectedID
	
	iSelectedID = g_iUserSelectedID[ id ]
	
	formatex( szTemp, charsmax( szTemp ), "\y%L", id, "VOTEBAN_MENU_TITLE" ) // Голосование за бан
	iMenu = menu_create( szTemp, "handler_voteban_main_menu" )

// === 1 ===

	if( get_user_status( iSelectedID ) ) 
		formatex( szTemp, charsmax( szTemp ), "%L \y%n", id, "VOTEBAN_MENU_PLAYER", iSelectedID ) // Игрок:

	else 
		formatex( szTemp, charsmax( szTemp ), "%L \d%L", id, "VOTEBAN_MENU_PLAYER", id, "VOTEBAN_MENU_SELECT_PLAYER" ) // Выбрать игрока

	menu_additem( iMenu, szTemp, "1", ADMIN_ALL )
	
// =========
	

// === 2 ===

	if( g_szUserReason[ id ][ 0 ] )
		formatex( szTemp, charsmax( szTemp ), "%L \y%s^n", id, "VOTEBAN_MENU_REASON", g_szUserReason[ id ] ) // Причина
		
	else formatex( szTemp, charsmax( szTemp ), "%L \d%L^n", id, "VOTEBAN_MENU_REASON", id, "VOTEBAN_MENU_ENTER_REASON"  ) // Причина || Ввести причину бана
	
	menu_additem( iMenu, szTemp, "2", ADMIN_ALL )
	
// =========

// === 3 ===

	new szFlags[ 24 ]
	get_pcvar_string( g_pcvr_TimeAccess, szFlags, charsmax( szFlags ) )
	
	if( get_user_flags( id ) & read_flags( szFlags ) )
	{
		formatex( szTemp, charsmax( szTemp ), "%L \y%i %L^n", id, "VOTEBAN_MENU_TIME", g_iUserBanTime[ id ], id, "VOTEBAN_MENU_MINUTES" ) // Время бана || минут
		menu_additem( iMenu, szTemp, "3", ADMIN_ALL )
	}
	
// =========

// === 4 ===
	
	new iAdmins = get_admins_online()
	
	if( iAdmins )
		formatex( szTemp, charsmax( szTemp ), "%L", id, "VOTEBAN_MENU_NOTIFY", iAdmins ) // Сообщить администратору (\y%d в сети\w)
	else
		formatex( szTemp, charsmax( szTemp ), "%L", id, "VOTEBAN_MENU_START_VOTE" ) // Начать голосование
	
	menu_additem( iMenu, szTemp, "4", ADMIN_ALL )
	
// =========

	
	formatex( szTemp, charsmax( szTemp ), "%L", id, "VOTEBAN_MENU_EXIT" )
	menu_setprop( iMenu, MPROP_EXITNAME, szTemp )
	
	menu_setprop( iMenu, MPROP_NUMBER_COLOR, "\w" )
	
	menu_display( id, iMenu, 0 )
	
	return PLUGIN_HANDLED
}

public handler_voteban_main_menu( id, iMenu, iItem )
{
	if( !is_voteban_available( id ) || ( iItem == MENU_EXIT ) )
	{
		menu_destroy( iMenu )
		clear_user_voteban_data( id )
		client_send_audio( id, MENU_SOUND_SELECT )
		
		return PLUGIN_HANDLED
	}
	
	new szData[ 3 ], szName[ 32 ], iAccess, iCallback, iKey
	menu_item_getinfo( iMenu, iItem, iAccess, szData, charsmax( szData ), szName, charsmax( szName ), iCallback )
	
	iKey = str_to_num( szData )
	
	switch( iKey )
	{
		case 1:
		{
			show_voteban_players_menu( id )
			client_send_audio( id, MENU_SOUND_SELECT )
		}
		
		case 2: 
		{
			if( get_pcvar_num( g_pcvr_BanReason ) != 1 )
				show_voteban_reason_menu( id )
			else
			{
				client_cmd( id, "messagemode voteban_reason" )
				yet_another_print_color( id, "%L",  id, "VOTEBAN_WRITING_REASON" ) // Активирован ручной ввод причины бана.
			}
			
			client_send_audio( id, MENU_SOUND_SELECT )
		}
		
		case 3:
		{
			show_voteban_time_menu( id )
			client_send_audio( id, MENU_SOUND_SELECT )
		}
		
		case 4:
		{
			new iSelectedID = g_iUserSelectedID[ id ]
			
			if( !get_user_status( iSelectedID ) )
			{
				yet_another_print_color( id, "%L",  id, "VOTEBAN_NEED_PLAYER" ) // Вы должны выбрать игрока
				show_voteban_main_menu( id )
				client_send_audio( id, MENU_SOUND_DENY )
			}
			
			else if( !g_szUserReason[ id ][ 0 ] )
			{
				yet_another_print_color( id, "%L",  id, "VOTEBAN_NEED_REASON" ) // Вы должны ввести причину бана
				show_voteban_main_menu( id )
				client_send_audio( id, MENU_SOUND_DENY )
			}
			
			else
			{	
				new szFlags[ 24 ], iAdmins = get_admins_online()
				
				if( iAdmins )
				{
					new i
					
					for( i = 1; i <= MAX_PLAYERS; i ++ )
					{
						get_pcvar_string( g_pcvr_AdminAccess, szFlags, charsmax( szFlags ) )
		
						if( !get_user_status( i ) || !( get_user_flags( i ) & read_flags( szFlags ) ) )
							continue
							
						yet_another_print_color( i, "%L",  i, "VOTEBAN_ADMIN_NOTIFICATION", id, iSelectedID, g_szUserReason[ id ] ) // %n хочет забанить %n за "%s".
						client_send_audio( i, MENU_SOUND_SUCCESS )
					}
					
					yet_another_print_color( id, "%L",  id, "VOTEBAN_ADMIN_NOTIFIED", iAdmins ) // Администраторов уведомлено о вашей жалобе: %d.
					client_send_audio( id, MENU_SOUND_SUCCESS )
					clear_user_voteban_data( id )
					
					return PLUGIN_HANDLED
				}
				
				get_pcvar_string( g_pcvr_TimeAccess, szFlags, charsmax( szFlags ) )
				
				get_user_name( id, g_szInitiator[ 0 ], charsmax( g_szInitiator[] ) )
				get_user_ip( id, g_szInitiator[ 1 ], charsmax( g_szInitiator[] ), 1 )
				get_user_authid( id, g_szInitiator[ 2 ], charsmax( g_szInitiator[] ) )
				
				g_iBanID = iSelectedID
				g_szBanReason = g_szUserReason[ id ]
				
				if( get_user_flags( id ) & read_flags( szFlags ) )
					g_iBanTime = g_iUserBanTime[ id ]
				
				else g_iBanTime = get_pcvar_num( g_pcvr_DefaultTime )
				
				clear_user_voteban_data( id )
				
				g_bIsVoteStarted = true
				
				show_voteban_menu( id )
				
				g_iUserGametime[ id ] = floatround( get_gametime() )
				set_task( get_pcvar_float( g_pcvr_Duration ), "task_end_vote", TID_ENDVOTE )
			}
		}
	}
	
	menu_destroy( iMenu )
	
	return PLUGIN_HANDLED
}

public show_voteban_reason_menu( id )
{
	if( !is_voteban_available( id ) )
		return PLUGIN_HANDLED
	
	new iMenu, szTemp[ 64 ]
	
	formatex( szTemp, charsmax( szTemp ), "\y%L\R", id, "VOTEBAN_MENU_REASON_TITLE" ) // Выбор причины бана
	iMenu = menu_create( szTemp, "handler_voteban_reason_menu" )
	
	if( get_pcvar_num( g_pcvr_BanReason ) == 0 )
	{
		formatex( szTemp, charsmax( szTemp ), "%L^n", id, "VOTEBAN_MENU_ENTER_REASON" ) // Ввести причину бана...
		menu_additem( iMenu, szTemp, "0", ADMIN_ALL )
	}
	
	new i = 1

	while( i )
	{
		formatex( szTemp, charsmax( szTemp ), "%L", id, fmt( "VOTEBAN_ADD_REASON_%d", i ) ) // any
		
		if( contain( szTemp, "ML_NOTFOUND" ) != -1 )
			break
		
		if( szTemp[ 0 ] )
			menu_additem( iMenu, szTemp, szTemp, ADMIN_ALL )
		
		i ++
	}
	
	if( !menu_items( iMenu ) )
	{
		menu_destroy( iMenu )
		client_cmd( id, "messagemode voteban_reason" )
		yet_another_print_color( id, "%L",  id, "VOTEBAN_WRITING_REASON" ) // Активирован ручной ввод причины бана.
		return PLUGIN_HANDLED
	}
	
	formatex( szTemp, charsmax( szTemp ), "%L", id, "VOTEBAN_MENU_BACK" )
	menu_setprop( iMenu, MPROP_BACKNAME, szTemp )
	
	formatex( szTemp, charsmax( szTemp ), "%L", id, "VOTEBAN_MENU_NEXT" )
	menu_setprop( iMenu, MPROP_NEXTNAME, szTemp )
	
	formatex( szTemp, charsmax( szTemp ), "%L", id, "VOTEBAN_MENU_EXIT" )
	menu_setprop( iMenu, MPROP_EXITNAME, szTemp )
	
	menu_setprop( iMenu, MPROP_NUMBER_COLOR, "\w" )
	
	menu_display( id, iMenu, 0 )
	
	return PLUGIN_HANDLED
}

public handler_voteban_reason_menu( id, iMenu, iItem )
{
	if( !is_voteban_available( id ) || ( iItem == MENU_EXIT ) )
	{
		menu_destroy( iMenu )
		client_send_audio( id, MENU_SOUND_SELECT )
		
		return PLUGIN_HANDLED
	}
	
	new szData[ 16 ], szItemName[ 64 ], iAccess, iCallback
	menu_item_getinfo( iMenu, iItem, iAccess, szData, charsmax( szData ), szItemName, charsmax( szItemName ), iCallback )
	
	if( iItem == 0 && szData[ 0 ] == '0' )
	{
		client_cmd( id, "messagemode voteban_reason" )
		yet_another_print_color( id, "%L",  id, "VOTEBAN_WRITING_REASON" ) // Активирован ручной ввод причины бана.
	}
	else
	{
		g_szUserReason[ id ] = szItemName
		show_voteban_main_menu( id )
	}
	
	client_send_audio( id, MENU_SOUND_SELECT )
	
	menu_destroy( iMenu )
	
	return PLUGIN_HANDLED
}

public show_voteban_time_menu( id )
{
	new iMenu, i, szTemp[ 190 ]

	formatex( szTemp, charsmax( szTemp ), "\y%L", id, "VOTEBAN_MENU_TIME_TITLE" ) // Выбор срока бана
	iMenu = menu_create( szTemp, "handler_voteban_time_menu" )

	for( i = 0; i < sizeof( g_szParsedCvarTime ); i ++ )
	{
		if( !g_szParsedCvarTime[ i ][ 0 ] )
			break
		
		formatex( szTemp, charsmax( szTemp ), "%s %L", g_szParsedCvarTime[ i ], id, "VOTEBAN_MENU_MINUTES" ) // минут
		
		menu_additem( iMenu, szTemp, "", ADMIN_ALL )
	}
	
	formatex( szTemp, charsmax( szTemp ), "%L", id, "VOTEBAN_MENU_EXIT" )
	menu_setprop( iMenu, MPROP_EXITNAME, szTemp )
	
	menu_setprop( iMenu, MPROP_NUMBER_COLOR, "\w" )
	
	menu_display( id, iMenu, 0 )
	
	return PLUGIN_HANDLED
}

public handler_voteban_time_menu( id, iMenu, iItem )
{
	if( !is_voteban_available( id ) || ( iItem == MENU_EXIT ) )
	{
		menu_destroy( iMenu )
		clear_user_voteban_data( id )
		client_send_audio( id, MENU_SOUND_SELECT )
		
		return PLUGIN_HANDLED
	}
	
	switch( iItem )
	{
		case 0..4: g_iUserBanTime[ id ] = str_to_num( g_szParsedCvarTime[ iItem ] )
	}
	
	show_voteban_main_menu( id )
	client_send_audio( id, MENU_SOUND_SELECT )
	
	menu_destroy( iMenu )
	
	return PLUGIN_HANDLED
}

public show_voteban_menu( id )
{
	new i
	
	for( i = 1; i <= MAX_PLAYERS; i ++ )
	{
		if( !get_user_status( i ) || i == g_iBanID )
			continue

		client_send_audio( i, MENU_SOUND_SUCCESS )
		yet_another_print_color( i, "%L", i, "VOTEBAN_WHO_START", id, g_iBanID, g_szBanReason ) //%n начал голосование за бан !g%n!n (!g%s!n)!
		
		if( i == id )
		{
			if( add_vote( id ) )
				break
			else
				continue
		}
		
		new iMenu, szTemp[ 64 ]
		
		formatex( szTemp, charsmax( szTemp ), "\y%L", i, "VOTEBAN_MENU_TITLE" ) // Голосование за бан
		iMenu = menu_create( szTemp, "handler_voteban_menu" )
		
		formatex( szTemp, charsmax( szTemp ), "%L", i, "VOTEBAN_MENU_YES" ) // \rЗабанить
		menu_additem( iMenu, szTemp, "", ADMIN_ALL )
		
		formatex( szTemp, charsmax( szTemp ), "%L^n", i, "VOTEBAN_MENU_NO" ) // Не банить
		menu_additem( iMenu, szTemp, "", ADMIN_ALL )
		
		formatex( szTemp, charsmax( szTemp ), "\w%L \y%n", i, "VOTEBAN_MENU_PLAYER", g_iBanID ) // Игрок
		menu_addtext( iMenu, szTemp, 1 )
		
		formatex( szTemp, charsmax( szTemp ), "\w%L \y%s^n", i, "VOTEBAN_MENU_REASON", g_szBanReason ) // Причина
		menu_addtext( iMenu, szTemp, 1 )
		
		formatex( szTemp, charsmax( szTemp ), "\w%L \y%n", i, "VOTEBAN_MENU_INITIATOR", id ) // Инициатор
		menu_addtext( iMenu, szTemp, 1 )
		
		menu_setprop( iMenu, MPROP_EXIT, MEXIT_NEVER )
		
		menu_setprop( iMenu, MPROP_NUMBER_COLOR, "\w" )
		
		menu_display( i, iMenu, 0 )
	}
}

public handler_voteban_menu( id, iMenu, iItem )
{
	if( iItem == 0 )
		add_vote( id )
	else
	{
		menu_destroy( iMenu )
		client_send_audio( id, MENU_SOUND_SELECT )
		
		return PLUGIN_HANDLED
	}
	
	client_send_audio( id, MENU_SOUND_SELECT )
	
	return PLUGIN_HANDLED
}

public add_vote( id )
{
	if( !get_user_status( id ) )
		return false
	
	if( !g_bIsVoteStarted )
	{
		yet_another_print_color( id, "%L",  id, "VOTEBAN_ALREADY_FINISHED" ) // Голосование уже закончено.
		return false
	}

	g_iTotalVotes[ g_iBanID ] ++
	
	new iTotalVotes, iNeedVotes, i_pCvrMinVotes
	iTotalVotes = g_iTotalVotes[ g_iBanID ]
	iNeedVotes = floatround( get_pcvar_float( g_pcvr_Percent ) * get_players_online() / 100 )
	i_pCvrMinVotes = get_pcvar_num( g_pcvr_MinVotes )
	
	if( iNeedVotes < i_pCvrMinVotes )
		iNeedVotes = i_pCvrMinVotes
	
	if( iTotalVotes < iNeedVotes )
	{
		new i
		
		for( i = 1; i <= MAX_PLAYERS; i ++ )
		{
			if( is_user_connected( i ) )
			{
				if( i != g_iBanID )
					client_print( i, print_center, "%L", i, "VOTEBAN_VOTE", g_iBanID, iTotalVotes, iNeedVotes, i_pCvrMinVotes ) // За бан %n проголосовали: %d, нужно: %d, (минимум %d).
			}
		}
	}
	
	else
	{
		ban_player( g_iBanID )
		return true
	}
	
	return false
}

public ban_player( iBanID )
{
	if( task_exists( TID_ENDVOTE ) )
		remove_task( TID_ENDVOTE )
	
	if( !get_user_status( iBanID ) )
	{
		clear_voteban_data()
		return PLUGIN_HANDLED
	}
	
	new i, szIP[ 16 ], szAuthID[ 35 ], iUserID
	
	get_user_ip( iBanID, szIP, charsmax( szIP ), 1 )
	get_user_authid( iBanID, szAuthID, charsmax( szAuthID ) )
	iUserID = get_user_userid( iBanID )

	switch( get_pcvar_num( g_pcvr_BanType ) )
	{
		case -2: server_cmd( "banid %d %s kick", g_iBanTime, szAuthID ) // BAN AUTHID (STEAMID) 
		case -1: server_cmd( "addip %d ^"%s^"", g_iBanTime, szIP ) // BAN IP
		case 1: server_cmd( "amx_ban %d %s ^"[%s] %s^"", g_iBanTime, szAuthID, MSGS_PREFIX, g_szBanReason ) // AMXBANS 
		case 2: server_cmd( "fb_ban %d #%d ^"[%s] %s^"", g_iBanTime, iUserID, MSGS_PREFIX, g_szBanReason ) // FRESH BANS
		case 3: server_cmd( "amx_ban #%d %d ^"[%s] %s^"", iUserID, g_iBanTime, MSGS_PREFIX, g_szBanReason ) // ADVANCED BANS
		case 4: server_cmd( "amx_superban #%d %d ^"[%s] %s^"", iUserID, g_iBanTime, MSGS_PREFIX, g_szBanReason ) // SUPERBAN
		case 5: server_cmd( "amx_multiban #%d %d ^"[%s] %s^"", iUserID, g_iBanTime, MSGS_PREFIX, g_szBanReason ) // MULTIBAN
	}
	
	for( i = 1; i <= MAX_PLAYERS; i ++ )
	{
		if( !get_user_status( i ) || ( i == iBanID ) )
			continue
		
		yet_another_print_color( i, "%L", i, "VOTEBAN_BANNED", iBanID ) // !g%n!n забанен через голосование!
	}
	
	if( get_pcvar_num( g_pcvr_LogToFile ) )
	{
		new y, m, d, szTemp[ 32 ]
		
		date( y, m, d )
		formatex( szTemp, charsmax( szTemp ), "YAV_%d%02d%02d.log", y, m, d )
		log_to_file( szTemp, "Player ^"%n^" banned by initiator ^"%s^" for ^"%s^" (STEAM ID %s) (IP %s)", iBanID, g_szInitiator[ 0 ], g_szBanReason, g_szInitiator[ 2 ], g_szInitiator[ 1 ] )
	}
	
	clear_voteban_data()
	
	return PLUGIN_HANDLED
}

public task_end_vote()
{
	new i
	
	for( i = 1; i <= MAX_PLAYERS; i ++ )
	{
		if( !is_user_connected( i ) || g_iBanID == i )
			continue
			
		yet_another_print_color( i, "%L",  i, "VOTEBAN_ENDED", g_iBanID ) // Голосование за бан !g%n!n провалено.
	}
	
	clear_voteban_data()
	
	g_bIsVoteStarted = false
}

stock bool:is_voteban_available( id )
{
	if( g_bIsVoteBlocked )
	{
		new i_pCvrRSDelay = get_pcvar_num( g_pcvr_RoundStartDelay )
		
		switch( i_pCvrRSDelay )
		{
			case -2 : yet_another_print_color( id, "%L %L",  id, "VOTEBAN_BLOCKED", id, "VOTEBAN_BLOCKED_FREEZETIME" ) // Голосование за бан заблокировано // на время фризтайма.
			case -1 : yet_another_print_color( id, "%L %L",  id, "VOTEBAN_BLOCKED", id, "VOTEBAN_BLOCKED_BUYTIME" ) // Голосование за бан заблокировано // на время покупки оружия.
			case 0 : yet_another_print_color( id, "%L.",  id, "VOTEBAN_BLOCKED" ) // Голосование за бан заблокировано
			default : yet_another_print_color( id, "%L %L",  id, "VOTEBAN_BLOCKED", id, "VOTEBAN_BLOCKED_TIME", i_pCvrRSDelay ) // Голосование за бан заблокировано // на %d сек. в начале раунда.
		}
		
		return false
	}

	if( g_bIsVoteStarted )
	{
		yet_another_print_color( id, "%L",  id, "VOTEBAN_ALREADY_STARTED" ) // В данный момент уже идёт голосование.
		return false
	}
	
	new szFlags, szCvarsFlags[ 3 ][ 24 ]
	
	szFlags = get_user_flags( id )
	get_pcvar_string( g_pcvr_AdminAccess, szCvarsFlags[ 0 ], charsmax( szCvarsFlags ) )
	get_pcvar_string( g_pcvr_TimeAccess, szCvarsFlags[ 1 ], charsmax( szCvarsFlags ) )
	get_pcvar_string( g_pcvr_Access, szCvarsFlags[ 2 ], charsmax( szCvarsFlags ) )
	
	if( szCvarsFlags[ 2 ][ 0 ] && !( szFlags & read_flags( szCvarsFlags[ 2 ] ) ) )
	{
		yet_another_print_color( id, "%L",  id, "VOTEBAN_NO_ACCESS" ) // К сожалению, у вас нет доступа к голосованию за бан.
		
		return false
	}
	
	if( szFlags & read_flags( szCvarsFlags[ 0 ] ) )
	{
		yet_another_print_color( id, "%L",  id, "VOTEBAN_YOU_ADMIN" ) // Используйте своё бан-меню.
		
		return false
	}
	
	if( g_iUserGametime[ id ] )
	{
		new iInterim, iDelayCvar
		
		iInterim = floatround( get_gametime() ) - g_iUserGametime[ id ]
		iDelayCvar = get_pcvar_num( g_pcvr_Delay )
		
		if( szCvarsFlags[ 1 ][ 0 ] && ( szFlags & read_flags( szCvarsFlags[ 1 ] ) ) )
			return true
		
		else if( iInterim < iDelayCvar * 60 )
		{
			yet_another_print_color( id, "%L",  id, "VOTEBAN_DELAY", ( iDelayCvar - ( iInterim / 60 ) ) + 1 ) // Вы должны подождать еще %d мин. после предыдущего голосования.
		
			return false
		}
	}

	return true
}

stock get_admins_online()
{
	new i, iAdmins, iTeam
	
	iAdmins = 0
	
	for( i = 1; i <= MAX_PLAYERS; i ++ )
	{
		new szFlags[ 24 ]; get_pcvar_string( g_pcvr_AdminAccess, szFlags, charsmax( szFlags ) )
		
		if( !get_user_status( i ) )
			continue
		
		if( !( get_user_flags( i ) & read_flags( szFlags ) ) )
			continue
		
		if( get_pcvar_num( g_pcvr_SpecAdmins ) )		
			iAdmins ++
		else
		{
			iTeam = get_user_team( i )
			
			if( !( ( iTeam == 2 ) || ( iTeam == 1 ) ) )
				continue
				
			iAdmins ++
		}
	}
	
	return iAdmins
}

stock get_players_online()
{
	new i, iPlayers
	
	for( i = 1; i <= MAX_PLAYERS; i ++ )
	{
		if( !get_user_status( i ) )
			continue

		iPlayers ++
	}
	
	return iPlayers
}
	
stock get_user_status( id )
{
#if defined DEBUG
	if( !is_user_connected( id ) || is_user_hltv( id ) /*|| is_user_bot( id )*/ )
#else
	if( !is_user_connected( id ) || is_user_hltv( id ) || is_user_bot( id ) )	
#endif
		return 0
	
	return 1
}
	
stock yet_another_print_color( id, szInput[], any:... )
{
	new szMessage[ 192 ]

	vformat( szMessage, charsmax( szMessage ), szInput, 3 )
	format( szMessage, charsmax( szMessage ), "^1[^4%s^1] %s", MSGS_PREFIX, szMessage )
	
	replace_all( szMessage, charsmax( szMessage ), "!g", "^4" ) // Green Color
	replace_all( szMessage, charsmax( szMessage ), "!n", "^1" ) // Default Color
	replace_all( szMessage, charsmax( szMessage ), "!t", "^3" ) // Team Color

	client_print_color( id, print_team_default, szMessage )
	
#if defined DEBUG
	client_print( 0, print_chat, "[ID%d]: %s", id, szMessage )
#endif
	
	return 1
}

// SendAudio
stock client_send_audio( id, iSoundID, iPitch = PITCH_NORM )
{
    static msgSendAudio = 0

    if( !msgSendAudio )
    {
        msgSendAudio = get_user_msgid("SendAudio");
    }

    message_begin( id ? MSG_ONE : MSG_ALL, msgSendAudio, _, id )
    write_byte( id )
    write_string( g_szMenuSounds[ iSoundID ])
    write_short( iPitch )
    message_end();
}