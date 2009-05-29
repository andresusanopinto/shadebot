include_file(Filename):-[Filename].

irc_send(L):-
	concat_atom(L,' ',S),
	write(S),nl,
	irc_raw_send(S).


irc_auth(Nick):-
	irc_send(['NICK', Nick]),
	irc_send(['USER', Nick, Nick, Nick, Nick]).
	
irc_pong(Id):-irc_send(['PONG', Id]).	

irc_join(Channel):-
	irc_send(['JOIN', Channel]).
	
irc_privmsg(Dest, Msg):-
	irc_send(['PRIVMSG', Dest | Msg]).
	
is_channel(Name):-concat_atom(['#'|_], Name).
is_user(Name):- not(is_channel(Name)).

prefix( Prefix, Nick):-
	concat_atom( [':', TPrefix], Prefix ),
	(
		concat_atom( [Nick,Rest], '!', TPrefix);
		concat_atom( [Nick,Rest], '@', TPrefix);
		Nick = TPrefix
	),!.
	
prefix( Prefix, Nick):-concat_atom( [':', Nick ], Prefix ).

/* start predicate */
irc_start:-
	irc_connect('irc.freenode.net'),
	irc_auth('shade_bot'),
	irc_join('#booka_shade').

/* called each time we receive a msg */
irc_receive( ['PING', Id] ):- irc_send(['PONG', Id]).

irc_receive( [_Prefix, 'PRIVMSG', Channel |  Msg ] ):-
	is_channel( Channel ),
	irc_privmsg( Channel, Msg ).

irc_receive( [Prefix, 'PRIVMSG', Channel |  Msg ] ):-
	is_user( Channel ),
	prefix(Prefix, Nick),
	irc_privmsg( Nick, Msg ).

irc_raw_receive(Msg):-
	write('Receive:'),write(Msg),nl,
	concat_atom(List, ' ', Msg),
	irc_receive(List).
	
irc_raw_receive(Msg):-write(Msg),nl.
