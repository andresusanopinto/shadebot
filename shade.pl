:- dynamic db_is/2.
:- dynamic db_has/2.
:- dynamic is_admin/1.
:- dynamic irc_receive/1.
:- dynamic irc_response/3.
:- dynamic irc_admin_response/3.
:- dynamic irc_send/1.
:- dynamic tmp_admin/1.
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
/*
irc_start:-
	irc_connect('uevora.PTnet.org'),
	irc_auth,
	irc_join('#p@p').
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

irc_notice(Dest, [H|T]):-
	concat_atom([':',H],NH),
	irc_send(['NOTICE', Dest, NH | T]).

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
	Goal =.. [irc_receive, List],
	catch(Goal, E, (print_message(error,E),fail))
	.

/* funcao de leitura a nivel de linha */
irc_receive( ['PING', Id] ):- irc_send(['PONG', Id]).

irc_receive( [Prefix, 'PRIVMSG', _Channel | [Cmd | Params] ] ):-
	prefix(Prefix, Sender),
	is_admin(Sender),
	concat_atom([':!',Command],Cmd),
	bot_control([Command | Params])
	.

irc_receive( [Prefix, 'PRIVMSG', Channel | Msg ] ):-
	prefix(Prefix, Sender),
	is_admin(Sender),
	is_channel( Channel ),
	clean_msg(Msg, CMsg),	
	irc_admin_response(Pred, CMsg, Response),
	Func =.. [Pred, Channel, Response],
	Func
	.

irc_receive( [_Prefix, 'PRIVMSG', Channel |  Msg ] ):-
	is_channel( Channel ),!,
	clean_msg(Msg, CMsg),	
	irc_response(Pred, CMsg, Response),
	Func =.. [Pred, Channel, Response],
	Func
	.

irc_receive( [Prefix, 'PRIVMSG', _Channel |  Msg ] ):-
	prefix(Prefix, Sender),!,
	clean_msg(Msg, CMsg),
	irc_response(Pred, CMsg, Response),
	Func =.. [Pred, Sender, Response],
	Func
	.

/* ignores */
irc_receive( [_Prefix, 'NOTICE', _Channel | _Msg ] ).
irc_receive( [_Prefix, 'JOIN', _Channel | _Msg ] ).
irc_receive( [_Prefix, 'MODE', _Channel | _Msg ] ).
irc_receive( [_Prefix, 'PART', _Channel | _Msg ] ).
irc_receive( [_Prefix, 'NICK', _Channel | _Msg ] ).
irc_receive( [_Prefix, Number, _Channel | _Msg ] ):-
	atom_to_term(Number, N, _),
	number(N).
/*	write('Numeric reply:'),write( [Prefix, Number, Channel | Msg ] ). */

irc_receive(_):- write('Unknown message'),nl.

/*
 * bot commands
 */
is_admin('apinto').
is_admin('jaguarandi').
is_admin(Nick):-tmp_admin(Nick).
bot_control(['quit']):-!,write('quitting'),nl,irc_send(['QUIT :I am seeing the WHITE ROOMS 8D']),irc_disconnect.
bot_control(['nick', Nick]):-!,irc_nick(Nick).
bot_control(['nick', Nick, Pass]):-!,nick_auth(Nick, Pass).
bot_control(['join', Channel]):-!,irc_send(['JOIN',Channel]).
bot_control(['join', Channel, Pass]):-!,irc_send(['JOIN',Channel,Pass]).
bot_control(['part', Channel]):-!,irc_send(['PART',Channel,':end of BODY LANGUAGE here :P']).
bot_control(['invite', Nick, Channel]):-!,irc_send(['INVITE',Nick,Channel]).
bot_control(['kick', Nick, Channel | []]):-!,irc_send(['KICK',Channel,Nick,':DARKO kicks your ass like no other']).
bot_control(['kick', Nick, Channel | Msg]):-!,clean_msg(NMsg, Msg),append(['KICK',Channel,Nick], NMsg, Final),!,irc_send(Final).
bot_control(['topic', Channel | Topic]):-!,clean_msg(NTopic, Topic),!,irc_send(['TOPIC',Channel|NTopic]).
bot_control(['me', Channel, | Msg]):-!,append([':\ACTION'|NMsg],['\'],Final),!,irc_send(['PRIVMSG', Channel | Final).
bot_control(['op', Nick, Channel]):-!,irc_send(['MODE', Channel,'+o',Nick]).
bot_control(['deop', Nick, Channel]):-!,irc_send(['MODE', Channel,'-o',Nick]).
bot_control(['voice', Nick, Channel]):-!,irc_send(['MODE', Channel,'+v',Nick]).
bot_control(['devoice', Nick, Channel]):-!,irc_send(['MODE', Channel,'-v',Nick]).
bot_control(['msg', Dest | Msg]):-!,clean_msg(NMsg, Msg),irc_send(['PRIVMSG', Dest | NMsg]).
bot_control(['notice', Dest | Msg]):-!,clean_msg(NMsg, Msg),irc_send(['NOTICE', Dest | NMsg]).
bot_control(['admin', Nick]):-!,asserta( tmp_admin(Nick) ).
bot_control(['ignore', Nick]):-!,retract( tmp_admin(Nick) ).
/*Request: PRIVMSG #booka_shade :\001ACTION wonders what's the real implementation of me\001*/
/*bot_control(L):-write('Comando invalido: |'),write(L),write('|'),nl. */

/*
 * Defines responses to given inputs
 */
/* CTCP replies */
irc_response( irc_notice, ['VERSION'], ['VERSION Shadebot'] ).
irc_response( irc_notice, ['PING', Id], ['PING', Id] ).


irc_response( irc_privmsg, [Object1, 'is', Object2], ['I', 'learned','that',Object1,'is',Object2] ):- asserta( db_is(Object1,Object2) ).
irc_response( irc_privmsg, [Object1, 'has', Object2], ['I', 'learned','that',Object1,'has',Object2] ):- asserta( db_has(Object1,Object2) ).
irc_response( irc_privmsg, ['whatis', Id], [Id, 'is', What] ):- whatis(Id,What).
/* whatis, is, has */

whatis(Id, Target):-
	db_is(Id, Target);db_is(Target,Id).


irc_admin_response( irc_privmsg, ['!calc', Id], [X] ):-atom_to_term(Id, Term, _), X is Term.
irc_admin_response( irc_privmsg, ['!run', Id], ['Done'] ):-atom_to_term(Id, Term, _), Term.

/* DEBUG */
/*
irc_response( Msg, ['ignored:' | Msg]).
:-irc_raw_receive( 'PING lala').
:-irc_raw_receive( ':andre PRIVMSG booka :andre is alala').
:-irc_raw_receive( ':andre PRIVMSG booka :apinto is LAlala').
:-irc_raw_receive( ':andre PRIVMSG booka :whatis andre').
:-irc_raw_receive( ':freenode-connect!freenode@freenode/bot/connect PRIVMSG shade_bot :VERSION').
*/
