#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <sys/ioctl.h>
#include <netinet/in.h>
#include <netinet/tcp.h>
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

static socklen_t
sockaddr_len(const struct sockaddr *sockaddr)
{
  switch (sockaddr->sa_family) {
  case AF_INET:
    return sizeof(struct sockaddr_in);
  case AF_INET6:
    return sizeof(struct sockaddr_in6);
  case AF_UNIX:
    return sizeof(struct sockaddr_un);
  default:
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
socket_sock_stream()
{
  return SOCK_STREAM;
}

int
socket_sock_dgram()
{
  return SOCK_DGRAM;
}



int
socket_ctl_getsockopt(int sock, int opt_name, int *ret)
{
  socklen_t len;

  len = sizeof(int);
  return getsockopt(sock, SOL_SOCKET, opt_name, &ret, &len);

}

int
socket_ctl_setsockopt(int sock, int opt_name, int val)
{
  socklen_t len;

  len = sizeof(int);
  return setsockopt(sock, SOL_SOCKET, opt_name, &val, len);

}

int
socket_ctl_getsockopt_linger(int sock, int *ret)
{
  int r;
  socklen_t len;
  struct linger linger;

  len = sizeof(int);
  r = getsockopt(sock, SOL_SOCKET, SO_LINGER, &linger, &len);

  if (linger.l_onoff) {
    *ret = linger.l_linger;
  }
  else {
    *ret = -1;
  }

  return r;

}

int
socket_ctl_setsockopt_linger(int sock, int val)
{
  socklen_t len;
  struct linger linger;

  len = sizeof(linger);
  linger.l_onoff = 0 <= val;

  return setsockopt(sock, SOL_SOCKET, SO_LINGER, &linger, len);

}


int
socket_ctl_debug()
{
  return SO_DEBUG;
}

int
socket_ctl_reuseaddr()
{
  return SO_REUSEADDR;
}

int
socket_ctl_keepalive()
{
  return SO_KEEPALIVE;
}
int
socket_ctl_dontroute()
{
  return SO_DONTROUTE;
}

int
socket_ctl_linger()
{
  return SO_LINGER;
}

int
socket_ctl_broadcast()
{
  return SO_BROADCAST;
}

int
socket_ctl_oobinline()
{
  return SO_OOBINLINE;
}

int
socket_ctl_sndebug()
{
  return SO_SNDBUF;
}

int
socket_ctl_rcvbuf()
{
  return SO_RCVBUF;
}

int
socket_ctl_type()
{
  return SO_TYPE;
}

int
socket_ctl_error()
{
  return SO_ERROR;
}


int
socket_ctl_getpeername(int sock, struct sockaddr**ret_addr)
{
  struct sockaddr addr;
  socklen_t len;
  int ret;

  ret = getpeername(sock, &addr, &len);

  *ret_addr = malloc(len);
  if (*ret_addr == NULL || ret == -1)
    return -1;

  **ret_addr = addr;
  return 0;
}

int
socket_ctl_getsockname(int sock, struct sockaddr**ret_addr)
{
  struct sockaddr addr;
  socklen_t len;
  int ret;

  ret = getsockname(sock, &addr, &len);

  *ret_addr = malloc(len);
  if (*ret_addr == NULL || ret == -1)
    return -1;

  **ret_addr = addr;
  return 0;
}

unsigned long int
socket_ctl_fionread()
{
  return FIONREAD;
}

unsigned long int
socket_ctl_siocatmark()
{
  return SIOCATMARK;
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

  len = sockaddr_len(addr);

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


int
socket_connect(int sockfd, struct sockaddr *addr)
{
  switch(addr->sa_family) {
  case AF_INET:
    return connect(sockfd, addr, sizeof(struct sockaddr_in));
  case AF_INET6:
    return connect(sockfd, addr, sizeof(struct sockaddr_in6));
  case AF_UNIX:
    return connect(sockfd, addr, sizeof(struct sockaddr_un));
  default:
    return -1;
  }
}

int
socket_connect_nb(int sockfd, struct sockaddr *addr)
{
  int ret;

  set_fl(sockfd, O_NONBLOCK);
  errno = 0;
  ret = socket_connect(sockfd, addr);
  if (ret == -1) {
    switch(errno) {
    case EWOULDBLOCK:
      return -2;
    }
  }
  return ret;
}

int
socket_shutdown(int sockfd, int mode)
{
  int how;

  switch(mode) {
  case 0: how = SHUT_RD; break;
  case 1: how = SHUT_WR; break;
  case 2: how = SHUT_RDWR; break;
  default:
    /* FIXME: better error handling */
    exit(1);
  }

  return shutdown(sockfd, how);
}

ssize_t
socket_send(int sockfd, const char *buff, size_t start, size_t end, int flags)
{

  return send(sockfd, buff + start, end - start, flags);
}

ssize_t
socket_recv(int sockfd, char *buff, size_t start, size_t end, int flags)
{

  return recv(sockfd, buff + start, end - start, flags);
}


ssize_t
socket_recvv(int sockfd, int flags, int n, void(callback)(const char *ptr, size_t len))
{

  char *buf;
  ssize_t ret;

  buf = alloca(n);

  ret = recv(sockfd,buf, n, flags);

  if(0 <= ret)
    callback(buf, ret);

  return ret;
}


int
socket_msg_oob()
{
  return MSG_OOB;
}

int
socket_msg_dontroute()
{
  return MSG_DONTROUTE;
}

int
socket_msg_dontwait()
{
  return MSG_DONTWAIT;
}

int
socket_msg_peek()
{
  return MSG_PEEK;
}

ssize_t
socket_sendto(int sockfd, const char* buf, int start, int end, int flags, struct sockaddr *dest_addr)
{
  return sendto(sockfd, buf + start, end - start, flags, dest_addr, sockaddr_len(dest_addr));
}

ssize_t
socket_recvfrom(int sockfd, char* buf, int start, int end, int flags, struct sockaddr **dest_addr)
{
  socklen_t len;

  *dest_addr = malloc(sizeof(struct sockaddr_storage));

  return recvfrom(sockfd, buf + start, end - start, flags, *dest_addr, &len);
}

ssize_t
socket_recvnfrom(int sockfd, int flags, int n, struct sockaddr **dest_addr, void(callback)(const char *ptr, size_t len))
{
  socklen_t len;
  char *buf;
  ssize_t ret;

  buf = alloca(n);

  *dest_addr = malloc(sizeof(struct sockaddr_storage));


  ret = recvfrom(sockfd, buf, n, flags, *dest_addr, &len);

  if(0 <= ret)
    callback(buf, len);

  return ret;
}
