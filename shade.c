/* Read /usr/lib/include/stub.c to know how to interface with prolog */
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <errno.h>
#include <netdb.h>
#include <signal.h>
#include <fcntl.h>
#include <netinet/ip.h>
#include <pthread.h>
#include <stdio.h>
#include <SWI-Prolog.h>


//IRC file descriptor
int irc_fd;

static void debug(const char *error)
{
	fprintf(stderr, "%s\n", error);
}

static int irc_connect(const char *hostname, int port)
{
    struct sockaddr_in dest = {};

	printf("Connecting to %s:%d\n", hostname, port);

	if((irc_fd = socket(AF_INET, SOCK_STREAM, 0)) < 0)
    {
		debug("Error creating socket");
		return 0;
    }

    dest.sin_family = AF_INET;
    dest.sin_port = htons(port);

	if(inet_aton(hostname, &dest.sin_addr.s_addr) == 0)
	{
		debug("Error resolving hostname");
		return 0;
	}
	
	if(connect(irc_fd, (struct sockaddr*)&dest, sizeof(dest)) != 0)
	{
		debug("Error connecting to server");
		return 0;
	}
	return 1;
}

int irc_send_raw(const char *msg)
{
	int len = strlen(msg);
	if( send( irc_fd, msg, len, 0) == len)
	{
		return 1;
	}
	return 0;
}

void irc_disconnect()
{
    close(irc_fd);
}


static foreign_t pl_irc_connect(term_t a0)
{
	char *server;
	if(PL_get_atom_chars(a0, &server))
	{
		//TODO suporta para: "irc.freenode.net:port"
		if(irc_connect(server, 6667))
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


