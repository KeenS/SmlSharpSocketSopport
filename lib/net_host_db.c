#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <limits.h>
#include "net_host_db.h"

typedef int sml_addr_family;



struct sockaddr *
sml_nhd_addrinfo_get_addr(const struct addrinfo *info)
{
  struct sockaddr *ret;

  ret = malloc(info->ai_addrlen);
  memcpy(ret, info->ai_addr, info->ai_addrlen);

  return ret;
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

void
sml_nhd_get_nameinfo(int family, const void *addr, void(callback)(const char *))
{
  char host[NI_MAXHOST];
  int ret;
  struct sockaddr_storage sock;
  socklen_t len;

  memset(&sock, 0, sizeof(struct sockaddr_storage));

  switch(family) {
  case SML_AF_INET4: {
    struct sockaddr_in *in;
    in = (struct sockaddr_in*)&sock;
    len = sizeof(struct sockaddr_in6);
    in->sin_addr = *(struct in_addr *)addr;
    in->sin_family = AF_INET;
    break;

  }
  case SML_AF_INET6: {
    struct sockaddr_in6 *in;
    in = (struct sockaddr_in6*)&sock;
    len = sizeof(struct sockaddr_in6);
    in->sin6_addr = *(struct in6_addr *)addr;
    in->sin6_family = AF_INET6;
    break;

  }
    /* FIXME: handle error */
  default: exit(1);
  }

  ret = getnameinfo((struct sockaddr *)&sock, len, host, NI_MAXHOST, NULL, 0, 0);

  if (ret != 0) {
    callback(NULL);
  }
  else {
    callback(host);
  }

}


void
sml_nhd_get_host_name(void (callback)(const char *))
{
  char hostname[HOST_NAME_MAX+1];
  int ret;


  ret = gethostname(hostname, sizeof(hostname));
  /* ignoring return value and error */
  callback(hostname);
}


void
sml_nhd_inaddr_to_string(int sml_addr_family, void *in, void (callback)(const char *))
{
  const char *ret;
  size_t strsize;

  switch(sml_addr_family) {
  case SML_AF_INET4: {
    char value[INET_ADDRSTRLEN];
    strsize=INET_ADDRSTRLEN;
    ret = inet_ntop(AF_INET, in, value, strsize);
    callback(ret);
    return;
  }
  case SML_AF_INET6: {
    char value[INET6_ADDRSTRLEN];
    strsize=INET6_ADDRSTRLEN;
    ret = inet_ntop(AF_INET6, in, value, strsize);
    callback(ret);
    return;
  }
  default:
    /* FIXME: find appropriate way */
    exit(1);
  }


}


struct sockaddr *
sml_nhd_inaddr_from_string(const char *str, int *family)
{
  int ret;
  struct in_addr result_in;
  struct in6_addr result_in6;
  void *result;


  memset(&result_in, 0, sizeof(struct sockaddr_in));
  ret = inet_pton(AF_INET, str, &result_in);
  if (ret == 1) {
    result = malloc(sizeof(struct in_addr));
    memcpy(result, &result_in, sizeof(struct in_addr));
    *family = SML_AF_INET4;
    return result;
  }
  if (ret == -1) {
    return NULL;
  }
  // if ret is 0, str may be inet6 addr

  memset(&result_in6, 0, sizeof(struct in6_addr));
  ret = inet_pton(AF_INET6, str, &result_in6);
  if (ret == 1) {
    result = malloc(sizeof(struct in6_addr));
    memcpy(result, &result_in6, sizeof(struct in6_addr));
    *family = SML_AF_INET6;
    return result;
  }
  return NULL;

}
