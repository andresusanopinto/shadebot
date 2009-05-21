include_file(Filename):-[Filename].

irc_raw_receive(Msg):-
	write(Msg),nl.

irc_start:-
	irc_connect('irc.freenode.net'),
	irc_auth('shade_bot').

aux_implode([H|[]], _, [H]):-!.
aux_implode([H|T], S, [H,S|A]):-
	aux_implode(T, S, A).

irc_send(L):-
	aux_implode(L, ' ', NL),
	concat_atom(NL, S),
	write(S),nl,
	irc_raw_send(S).

irc_auth(Nick):-
	irc_send(['NICK', Nick]),
	irc_send(['USER', Nick, Nick, Nick, Nick]).
