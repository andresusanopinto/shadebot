/*
 * Debug stuff:
 */
/*
include_file(Filename):-[Filename].
irc_raw_send(S):-write('<== '),write(S),nl. 
*/

/*
 * main and start
 */
irc_start:-
	irc_connect('irc.freenode.net'),
	irc_auth,
	irc_join('#booka_shade').

irc_auth:-
	Nick = 'shade_bot',
	irc_send(['USER', Nick, Nick, Nick, Nick]),
	irc_login(Nick, 'booka').

irc_send(L):-
	concat_atom(L,' ',S),
	irc_raw_send(S).

/*
 * envio de mensagens
 */
irc_nick(Nick):-irc_send(['NICK', Nick]).

irc_login(Nick):-irc_nick(Nick).
irc_login(Nick, Pass):-irc_nick_auth(Nick, Pass).

irc_nick_auth(Nick, Pass):-
	irc_send(['NICKSERV GHOST', Nick, Pass]),
	irc_nick(Nick),
	irc_send(['NICKSERV IDENTIFY', Pass]).

irc_pong(Id):-irc_send(['PONG', Id]).	

irc_join(Channel):-irc_send(['JOIN', Channel]).

irc_privmsg(Dest, [H|T]):-
	concat_atom([':',H],NH),
	irc_send(['PRIVMSG', Dest, NH | T]).
	
irc_privmsg(Dest, []):-
	irc_send(['PRIVMSG', Dest, ':']).

/* called each time we receive a msg */
clean_msg([H|T], [NH|T]):-
	!,concat_atom([':'|[NH]],H);NH=H.

/* predicados auxiliares para determinar que tipo de identificador temos */
is_channel(Name):-concat_atom(['#'|_], Name).
is_user(Name):- not(is_channel(Name)).

/* predicado para fazer parsing do Nick dado um determinado prefixo */
prefix( Prefix, Nick):-
	concat_atom( [':', TPrefix], Prefix ),
	(
		concat_atom( [Nick,Rest], '!', TPrefix);
		concat_atom( [Nick,Rest], '@', TPrefix);
		Nick = TPrefix
	),!.
	
prefix(Prefix, Nick):-concat_atom( [':', Nick ], Prefix ).

/* funcao base de leitura */
irc_raw_receive(Msg):-
	write('==> '),write(Msg),nl,
	concat_atom(List, ' ', Msg),
	irc_receive(List).

/* funcao de leitura a nivel de linha */
irc_receive( ['PING', Id] ):- irc_send(['PONG', Id]).

irc_receive( [Prefix, 'PRIVMSG', _Channel | [Cmd | Params] ] ):-
	prefix(Prefix, Sender),
	is_admin(Sender),
	concat_atom([':!',Command],Cmd),!,
	bot_control([Command | Params])
	.

irc_receive( [_Prefix, 'PRIVMSG', Channel |  Msg ] ):-
	write('Msg: '), write(Msg),nl,
	is_channel( Channel ),!,
	clean_msg(Msg, CMsg),	
	write('CMsg: '), write(CMsg),nl,
	irc_response(CMsg, Response),
	write('Resposta Canal'),write(Response),nl,
	irc_privmsg(Channel, Response)
	.

irc_receive( [Prefix, 'PRIVMSG', _Channel |  Msg ] ):-
	prefix(Prefix, Sender),
	clean_msg(Msg, CMsg),
	write('CMsg: '), write(CMsg),nl,
	irc_response(CMsg, Response),
	write('Resposta Privada'),write(Response),nl,
	irc_privmsg(Sender, Response)
	.

irc_receive(_):- write('Unknown message'),nl.

/*
 * bot commands
 */
is_admin('apinto').
is_admin('jaguarandi').
bot_control(['quit']):-!,write('quitting'),nl,irc_send(['QUIT :I am seeing the WHITE ROOMS 8D']),irc_disconnect.
bot_control(['nick', Nick]):-!,irc_nick(Nick).
bot_control(['nick', Nick, Pass]):-!,nick_auth(Nick, Pass).
bot_control(['join', Channel]):-!,irc_send(['JOIN',Channel]).
bot_control(['join', Channel, Pass]):-!,irc_send(['JOIN',Channel,Pass]).
bot_control(['part', Channel]):-!,irc_send(['PART',Channel,':end of BODY LANGUAGE here :P']).
bot_control(['invite', Nick, Channel]):-!,irc_send(['INVITE',Nick,Channel]).
bot_control(['kick', Nick, Channel | []]):-!,irc_send(['KICK',Channel,Nick,':DARKO kicks your ass like no other']).
bot_control(['kick', Nick, Channel | Msg]):-!,clean_msg(NMsg, Msg),append(['KICK',Channel,Nick], NMsg, Final),!,irc_send(Final).
bot_control(L):-write('Comando invalido: |'),write(L),write('|'),nl.


/*
 * Defines responses to given inputs
 */
irc_response( ['VERSION'], ['Shadebot'] ).
irc_response( ['PING', Id], ['PONG', Id] ).

/* whatis, is, has */
:- dynamic db_is/2.
:- dynamic db_has/2.
irc_response( [Object1, 'is', Object2], ['I', 'learned','that',Object1,'is',Object2] ):- asserta( db_is(Object1,Object2) ).
irc_response( [Object1, 'has', Object2], ['I', 'learned','that',Object1,'has',Object2] ):- asserta( db_has(Object1,Object2) ).
irc_response( ['whatis', Id], [Id, 'is', What] ):- db_is(Id,What).


/* DEBUG */
/*
irc_response( Msg, ['ignored:' | Msg]).
:-irc_raw_receive( 'PING lala').
:-irc_raw_receive( ':andre PRIVMSG booka andre is alala').
:-irc_raw_receive( ':andre PRIVMSG booka apinto is LAlala').
:-irc_raw_receive( ':andre PRIVMSG booka whatis andre').
 */
