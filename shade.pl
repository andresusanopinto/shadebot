include_file(Filename):-[Filename].

/* start predicate */
irc_start:-
	irc_connect('irc.freenode.net'),
	irc_auth,
	irc_join('#booka_shade').

irc_auth:-
	Nick = 'shade_bot',
	irc_send(['USER', Nick, Nick, Nick, Nick]),
	irc_login(Nick, 'pass').


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

/* se o emissor for um administrador, vamos interpretar a sua mensagem */
irc_privmsg( Emissor, _, [S|T]):-
	write('Emissor: '), write(Emissor), nl,
	write('Msg: '), write(S), nl,
	is_admin(Emissor),
	write('E admin'), nl,
	concat_atom(['!'|[Cmd]],S),!,
	write('E enviou um comando de admin: '),write(Cmd),nl,
	bot_control([Cmd|T]).

/* senao apenas repetimos a mensagem */
irc_privmsg( _, ReplyTo, Msg ):-irc_send(['PRIVMSG', ReplyTo | Msg]).


/*
 * bot commands
 */
is_admin('apinto').
bot_control(['quit']):-!,write('quitting'),nl,irc_disconnect.
bot_control(['nick', Nick]):-!,irc_nick(Nick).
bot_control(['nick', Nick, Pass]):-!,nick_auth(Nick, Pass).
bot_control(L):-write('Comando invalido: |'),write(L),write('|'),nl.


/* concatenacao da lista e envio da mensagem resultante */
irc_send(L):-
	concat_atom(L,' ',S),
	write(S),nl,
	irc_raw_send(S).


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
	
prefix( Prefix, Nick):-concat_atom( [':', Nick ], Prefix ).


/* called each time we receive a msg */
clean_msg([H|T], [NH|T]):-
	!,concat_atom([':'|[NH]],H);NH=H.

irc_receive( ['PING', Id] ):- irc_send(['PONG', Id]).

irc_receive( [Prefix, 'PRIVMSG', Dest |  Msg ] ):-
	write('HEY2'),nl,
	is_channel( Dest ),!,
	prefix( Prefix, Nick ),
	write('Msg:'),write(Msg),nl,
	clean_msg( Msg, NMsg ),
	write('NMsg:'),write(NMsg),nl,
	irc_privmsg( Nick, Dest, NMsg ).

irc_receive( [Prefix, 'PRIVMSG', Dest |  Msg ] ):-
	write('HEY3'),nl,
	is_user( Dest ),!,
	prefix( Prefix, Nick ),
	write('Msg:'),write(Msg),nl,
	clean_msg( Msg, NMsg ),
	write('NMsg:'),write(NMsg),nl,
	irc_privmsg( Nick, Nick, NMsg ).

irc_receive(_):- write('Unknown message'),nl.


/* funcao base de leitura */
irc_raw_receive(Msg):-
	write('Receive:'),write(Msg),nl,
	concat_atom(List, ' ', Msg),
	irc_receive(List).
	
/*irc_raw_receive(Msg):-write(Msg),nl.*/
