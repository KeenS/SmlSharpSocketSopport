#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <limits.h>

#define SML_AF_INET4 0
#define SML_AF_INET6 1
#define SML_AF_INET_UNKNOWN -1


/* TODO: more checks */
#define smlaf_to_af(af) (af) == SML_AF_INET4 ? AF_INET : AF_INET6


typedef int sml_addr_family;



struct sockaddr *
sml_nhd_addrinfo_get_addr(const struct addrinfo *info)
{
  return info->ai_addr;
}

sml_addr_family
sml_nhd_addrinfo_get_family(const struct addrinfo *info)
{

  switch(info->ai_family) {
  case AF_INET: return SML_AF_INET4;
  case AF_INET6: return SML_AF_INET6;
  default: return SML_AF_INET_UNKNOWN;
  }
}

const char *
sml_nhd_addrinfo_get_canonname(const struct addrinfo *info)
{

  return info->ai_canonname;
}


struct addrinfo *
sml_nhd_addrinfo_get_next(const struct addrinfo *info)
{
  return info->ai_next;
}

void
sml_nhd_addrinfo_free(struct addrinfo *info)
{
  freeaddrinfo(info);
}



struct addrinfo *
sml_nhd_get_by_name(const char* name)
{
  const char *service = NULL;
  struct addrinfo hints, *result;
  int ret;

  memset(&hints, 0, sizeof(struct addrinfo));
  hints.ai_family = AF_UNSPEC;
  hints.ai_flags = AI_ADDRCONFIG | AI_ALL | AI_CANONNAME | AI_V4MAPPED;

  ret = getaddrinfo(name, service, &hints, &result);
  if (ret != 0)
    return NULL;

  return result;
}



const char *
sml_nhd_get_host_name()
{
  char *hostname;
  int ret;

  hostname = malloc(HOST_NAME_MAX+1);

  ret = gethostname(hostname, sizeof(hostname));
  /* ignoring return value and error */

  return hostname;

}


const char *
sml_nhd_inaddr_to_string(struct sockaddr *in)
{
  int ai_family;
  char *ret;
  void *addr;
  size_t strsize;

  ai_family = in->sa_family;

  switch(ai_family) {
  case AF_INET:
    strsize = INET_ADDRSTRLEN;
    addr = &((struct sockaddr_in *)in)->sin_addr;
    break;
  case AF_INET6:
    strsize = INET6_ADDRSTRLEN;
    addr = &((struct sockaddr_in6 *)in)->sin6_addr;
    break;
  default:
    /* FIXME: find appropriate way */
    exit(1);
  }

  ret = malloc(strsize);
  return inet_ntop(ai_family, addr, ret, strsize);
}


struct sockaddr *
sml_nhd_inaddr_from_string(const char *str)
{
  int ret;
  struct sockaddr *result;

  result = malloc(sizeof(struct in_addr));
  ret = inet_pton(AF_INET, str, result);
  if (ret == 1) {
    return result;
  }
  if (ret == -1) {
    return NULL;
  }
  // if ret is 0, str may be inet6 addr

  result = realloc(result, sizeof(struct in6_addr));
  ret = inet_pton(AF_INET6, str, result);

  if (ret == 1) {
    return result;
  }
  return NULL;

}
