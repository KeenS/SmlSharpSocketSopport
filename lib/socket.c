#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <limits.h>
#include <fcntl.h>
#include <errno.h>
#include "net_host_db.h"


static void
set_fl(int fd, int flags)
{
  int val;

  if ((val = fcntl(fd, F_GETFL, 0)) < 0) {
    exit(1);
  }

  val |= flags;  /* turn on flags */

  if (fcntl(fd, F_SETFL, val) < 0) {
    exit(1);
  }
}

int
socket_af_inet()
{
  return AF_INET;
}

int
socket_af_inet6()
{
  return AF_INET6;
}

int
socket_af_unix()
{
  return AF_UNIX;
}


int
socket_family_of_addr(struct sockaddr *sock)
{
  return sock->sa_family;
}

int
socket_bind(int sockfd, struct sockaddr *addr)
{
  socklen_t len;

  switch (addr->sa_family) {
  case AF_INET:
    len = sizeof(struct sockaddr_in);
    break;
  case AF_INET6:
    len = sizeof(struct sockaddr_in6);
    break;
  case AF_UNIX:
    len = sizeof(struct sockaddr_un);
    break;
  default:
    return -1;
  }

  return bind(sockfd, addr, len);
}

int
socket_listen(int sockfd, int backlog)
{
  if (SOMAXCONN < backlog)
    backlog = SOMAXCONN;

  return listen(sockfd, backlog);
}


int
socket_accept(int sockfd, struct sockaddr **addr)
{
  socklen_t len;

  len = sizeof(struct sockaddr);

  return accept(sockfd, *addr, &len);
}

int
socket_accept_nb(int sockfd, struct sockaddr **addr)
{
  int ret;

  set_fl(sockfd, O_NONBLOCK);
  errno = 0;
  ret = socket_accept(sockfd, addr);
  if (ret == -1) {
    switch(errno) {
    case EWOULDBLOCK:
      return -2;
    }
  }
  return ret;
}
