:-use_module(library(lists)).
:- dynamic db_is/2.
:- dynamic db_has/2.
:- dynamic is_admin/1.
:- dynamic is_away/0.
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

irc_mode(Channel,Mode,Nick):- is_channel(Channel),
	irc_send(['MODE',Channel,Mode,Nick]).

irc_action(Dest, Msg):-
	append(Msg,[''],NMsg),
	irc_privmsg(Dest, ['ACTION' | NMsg] ).
	
irc_back:-
	irc_send(['AWAY']).

irc_away(Msg):-
	write('here'),nl,
	irc_send(['AWAY :' | Msg]).

/* called each time we receive a msg */
clean_msg([H|T], [NH|T]):-
	!,concat_atom([':'|[NH]],H);NH=H.

/* predicados auxiliares para determinar que tipo de identificador temos */
is_channel(Name):-concat_atom(['#'|_], Name).
is_channel(Name):-concat_atom(['&'|_], Name).
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

response_context(_Prefix,Target,Target):-is_channel(Target).
response_context(Prefix,_Target,Sender):-prefix(Prefix, Sender).

/* funcao de leitura a nivel de linha */
irc_receive( ['PING', Id] ):- irc_send(['PONG', Id]).

irc_receive( [Prefix, 'PRIVMSG', Channel | [Cmd | Params] ] ):-
	response_context(Prefix,Channel,Out),
	prefix(Prefix, Sender),
	is_admin(Sender),
	concat_atom([':!',Command],Cmd),
	bot_control(Out,[Command | Params])
	.

irc_receive( [_Prefix, 'PRIVMSG' | _] ):-is_away.

irc_receive( [Prefix, 'PRIVMSG', Channel | Msg ] ):-
	response_context(Prefix,Channel,Out),
	prefix(Prefix, Sender),is_admin(Sender),
	clean_msg(Msg, CMsg),	
	irc_admin_response(Pred, CMsg, Response),
	Func =.. [Pred, Out, Response],
	Func
	.

irc_receive( [Prefix, 'PRIVMSG', Channel |  Msg ] ):-
	response_context(Prefix,Channel,Out),
	clean_msg(Msg, CMsg),	
	irc_response(Pred, CMsg, Response),
	Func =.. [Pred, Out, Response],
	Func
	.


/* ignores */
irc_receive( [_Prefix, 'NOTICE', _Channel | _Msg ] ).
irc_receive( ['NOTICE' | _Msg ] ).
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
bot_control(_Context, ['back']):-					!,is_away,irc_back,retract(is_away).
bot_control(_Context, _Args):-						is_away.

bot_control(_Context, ['away']):-					!,irc_away(['this bot is with CHARLOTTE now']),assert(is_away).
bot_control(_Context, ['away' | Msg]):-				!,irc_away(Msg),assert(is_away).

bot_control(_Context, ['quit']):-					!,irc_send(['QUIT :I am seeing the WHITE ROOMS 8D']),irc_disconnect.

bot_control(_Context, ['nick', Nick]):-				!,irc_nick(Nick).
bot_control(_Context, ['nick', Nick, Pass]):-		!,nick_auth(Nick, Pass).
bot_control(_Context, ['join', Channel]):-			is_channel(Channel),!,irc_join(Channel).
bot_control(_Context, ['join', Channel, Pass]):-	is_channel(Channel),!,irc_send(['JOIN',Channel,Pass]).

bot_control(_Context, ['part', Channel]):-			is_channel(Channel),!,irc_send(['PART',Channel,':end of BODY LANGUAGE here :P']).
bot_control( Context, ['part']):-					is_channel(Context),!,irc_send(['PART',Context,':end of BODY LANGUAGE here :P']).

bot_control(_Context, ['invite', Nick, Channel]):-	is_channel(Channel),!,irc_send(['INVITE',Nick,Channel]).
bot_control( Context, ['invite', Nick]):-			is_channel(Context),!,irc_send(['INVITE',Nick,Context]).

bot_control(_Context, ['kick', Nick, Channel]):-		is_channel(Channel),!,irc_send(['KICK',Channel,Nick,':DARKO kicks your ass like no other']).
bot_control(_Context, ['kick', Nick, Channel | Msg]):-	is_channel(Channel),!,clean_msg(NMsg, Msg),append(['KICK',Channel,Nick], NMsg, Final),!,irc_send(Final).
bot_control( Context, ['kick', Nick]):-					is_channel(Context),!,irc_send(['KICK',Context,Nick,':DARKO kicks your ass like no other']).
bot_control( Context, ['kick', Nick | Msg]):-			is_channel(Context),!,clean_msg(NMsg, Msg),append(['KICK',Context,Nick], NMsg, Final),!,irc_send(Final).

bot_control(_Context, ['topic', Channel | Topic]):-		is_channel(Channel),!,clean_msg(NTopic, Topic),!,irc_send(['TOPIC',Channel|NTopic]).
bot_control( Context, ['topic' | Topic]):-				is_channel(Context),!,clean_msg(NTopic, Topic),!,irc_send(['TOPIC',Context|NTopic]).

bot_control( Context, ['op', Nick]):-					irc_mode(Context,'+o',Nick).
bot_control(_Context, ['op', Nick, Channel]):-			irc_mode(Channel,'+o',Nick).
bot_control( Context, ['deop', Nick]):-					irc_mode(Context,'-o',Nick).
bot_control(_Context, ['deop', Nick, Channel]):-		irc_mode(Channel,'-o',Nick).
bot_control( Context, ['voice', Nick]):-				irc_mode(Context,'+v',Nick).
bot_control(_Context, ['voice', Nick, Channel]):-		irc_mode(Channel,'+v',Nick).
bot_control( Context, ['devoice', Nick]):-				irc_mode(Context,'-v',Nick).
bot_control(_Context, ['devoice', Nick, Channel]):-		irc_mode(Channel,'-v',Nick).

bot_control(_Context, ['msg', Dest | Msg]):-			!,clean_msg(NMsg, Msg),irc_privmsg(Dest,NMsg).
bot_control( Context, ['me' | Msg]):-					irc_action(Context,Msg).
bot_control(_Context, ['notice', Dest | Msg]):-			!,clean_msg(NMsg, Msg),irc_notice(Dest, NMsg).
bot_control(_Context, ['admin', Nick]):-				!,asserta( tmp_admin(Nick) ).
bot_control(_Context, ['ignore', Nick]):-				!,retract( tmp_admin(Nick) ).

bot_control(Context, ['help']):-						!,usage(Msg),findall(_, (member(X, Msg),irc_privmsg(Context,X)),_).

usage(
[['Usage: !<msg>'],
['<msg> = <command> [<params>'],
[' '],
['Bot Commands for bot admins:'],
['quit                                     - bot quits irc'],
['nick <nick> [<pass>]                     - change bot nickname'],
['join <channel> [<pass>]                  - bot joins channel'],
['part [<channel>]                         - bot leaves channel (default - current channel)'],
['invite <nick> [<channel>]                - bot invites nick to channel (default - current channel)'],
['kick <nick> [<channel> <Msg>]            - bot kicks nick from channel with customizable message (default - current channel)'],
['topic [<channel>] <topic>                - bot changes channel topic (default - current channel)'],
['op/deop/voice/devoice <nick> [<channel>] - bot gives or takes respective access level from channel (default - current channel)'],
['msg <dest> <msg>                         - bot writes msg as private message to dest'],
['me <msg>                                 - bot writes msg as action me to current channel'],
['notice <dest> <msg>                      - bot writes notice to dest'],
['admin <nick>                             - gives temporary bot admin access to nick'],
['ignore <nick>                            - removes temporary bot admin access of nick']]
).


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
