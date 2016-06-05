#ifndef _NET_HOST_DB_H
#define	_NET_HOST_DB_H	1

#define SML_AF_INET4 0
#define SML_AF_INET6 1
#define SML_AF_INET_UNKNOWN -1

/* TODO: more checks */
#define smlaf_to_af(af) (af) == SML_AF_INET4 ? AF_INET : AF_INET6

#endif
