
include_file(Filename):-[Filename].

irc_raw_receive(Msg):-
	write(Msg),nl.

irc_start:-irc_connect('irc.freenode.net').
