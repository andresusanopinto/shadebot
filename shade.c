/* Read /usr/lib/include/stub.c to know how to interface with prolog */
#include <stdio.h>
#include <SWI-Prolog.h>

static foreign_t pl_irc_connect(term_t a0)
{
	char *server;
	printf("%d\n", PL_term_type(a0) );
	if(PL_get_atom_chars(a0, &server))
	{
		printf("Connect: \n", server);
		PL_succeed;
	}
	PL_fail;
} 

static foreign_t pl_irc_raw_send(term_t a0)
{
	char *str;
	int str_len;
	if(PL_get_atom_chars(a0, &str))
	{
		puts(str);
		PL_succeed;
	}
	PL_fail;
}

static const PL_extension predicates[] =
{
/*{ "name",	arity,  function,	PL_FA_<flags> },*/
 	{ "irc_connect",  1, pl_irc_connect,  0 },
 	{ "irc_raw_send", 1, pl_irc_raw_send, 0 },
	{ NULL,	0, 	NULL,		0 }
};

int pl_include_file(const char *file)
{
	predicate_t pred = PL_predicate("include_file", 1, "user");
    term_t h0 = PL_new_term_refs(1);
    PL_put_atom_chars(h0, file);
	return !PL_call_predicate(NULL, TRUE, pred, h0);
}

int main(int argc, char **argv)
{
	PL_register_extensions(predicates);
	if(!PL_initialise(argc, argv))
		PL_halt(1);

	PL_halt( pl_include_file("config/main.pl") );

	return 0;
}


