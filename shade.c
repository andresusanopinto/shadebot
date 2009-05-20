/* Read /usr/lib/include/stub.c to know how to interface with prolog */
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <netdb.h>
#include <SWI-Prolog.h>


//IRC file descriptor
static int irc_fd = -1;

static void debug(const char *error)
{
	fprintf(stderr, "%s\n", error);
}

static int irc_connect(const char *hostname, const char * port)
{
	//based on getaddrinfo(3) client example
	struct addrinfo *result, *rp, hints = {};
	int s;

	s = getaddrinfo( hostname, port, &hints, &result);
	if(s != 0)
	{
		printf("Connecting to %s:%d - %s\n", hostname, port, gai_strerror(s));
		return 0;
	}

	for(rp = result; rp != NULL; rp = rp->ai_next)
	{
		irc_fd = socket( rp->ai_family, rp->ai_socktype, rp->ai_protocol );
		if(irc_fd == -1)
			continue;

		if(connect(irc_fd, rp->ai_addr, rp->ai_addrlen) != -1)
			break;

		close(irc_fd);
	}

	if(rp == NULL)
	{
		debug( "Couldn't connect" );
		return 0;
	}
	return 1;
}

/*
 * Sends a msg (it adds a newline after the string)
 */
int irc_raw_send(const char *msg)
{	
	const static char newline = '\n';
	printf("sending msg: %s\n", msg);

	int len = strlen(msg);
	if(write(irc_fd, msg, len) == len
	&& write(irc_fd,&newline,1) == 1)
	{
		return 1;
	}
	return 0;
}

void irc_receive_msg(const char *msg)
{
	printf("received msg: %s\n", msg);
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
		if(irc_connect(server, "6667"))
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

int call_pl_irc_raw_receive(const char *msg)
{
	predicate_t pred = PL_predicate("irc_raw_receive", 1, "user");
	term_t h0 = PL_new_term_refs(1);
	PL_put_atom_chars(h0, msg);
	return !PL_call_predicate(NULL, TRUE, pred, h0);
}

int pl_include_file(const char *file)
{
	predicate_t pred = PL_predicate("include_file", 1, "user");
	term_t h0 = PL_new_term_refs(1);
	PL_put_atom_chars(h0, file);
	return !PL_call_predicate(NULL, TRUE, pred, h0);
}

void irc_read_msg()
{
	char buf[1024], *pos = buf, tmp;
	while(read(irc_fd, &tmp, 1) == 1)
	{
		if(tmp == '\n')
		{
			*pos = 0;
			printf("Receive: %s\n", buf);
			call_pl_irc_raw_receive(buf);
			pos = buf;
		}
		else
		{
			*(pos++) = tmp;
			if(pos == buf+512)
				printf("Receiving msg too long\n");
		}
	}
}

int main(int argc, char **argv)
{
	PL_register_extensions(predicates);
	if(!PL_initialise(argc, argv))
		PL_halt(1);

	if(irc_connect("irc.freenode.net", "6667"))
	{
		irc_raw_send("NICK shade_bot");
		irc_raw_send("USER shade_bot shade_bot shade_bot shade_bot");
		irc_read_msg();
	}

//	PL_halt( pl_include_file("config/main.pl") );

	return 0;
}


