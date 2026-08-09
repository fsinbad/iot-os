#ifndef IOT_ML307N_ERRNO_H
#define IOT_ML307N_ERRNO_H

/* 自定义 errno 定义，解决 SDK 中 errno 宏不生效的问题 */
#ifdef __cplusplus
extern "C" {
#endif

#ifndef errno
extern int errno_var;
#define errno (errno_var)
#endif

#ifdef __cplusplus
}
#endif

/* 常用错误码定义 */
#define EPERM           1
#define ENOENT          2
#define EINTR           4
#define EIO             5
#define EBADF           9
#define EAGAIN          11
#define ENOMEM          12
#define EACCES          13
#define EFAULT          14
#define EBUSY           16
#define EEXIST          17
#define ENOTDIR         20
#define EISDIR          21
#define EINVAL          22
#define ENFILE          23
#define EMFILE          24
#define ENOSPC          28
#define ESPIPE          29
#define EROFS           30
#define EMLINK          31
#define EPIPE           32
#define EDOM            33
#define ERANGE          34
#define EDEADLK         45
#define ENAMETOOLONG    91
#define ENOLCK          46
#define ENOSYS          38
#define ENOTEMPTY       39
#define ELOOP           40
#define EWOULDBLOCK     EAGAIN
#define ENOMSG          42
#define EIDRM           43
#define ENOTSOCK        88
#define EDESTADDRREQ    89
#define EMSGSIZE        90
#define EPROTOTYPE      91
#define ENOPROTOOPT     92
#define EPROTONOSUPPORT 93
#define ESOCKTNOSUPPORT 94
#define EOPNOTSUPP      95
#define EPFNOSUPPORT    96
#define EAFNOSUPPORT    97
#define EADDRINUSE      98
#define EADDRNOTAVAIL   99
#define ENETDOWN        100
#define ENETUNREACH     101
#define ENETRESET       102
#define ECONNABORTED    103
#define ECONNRESET      104
#define ENOBUFS         105
#define EISCONN         106
#define ENOTCONN        107
#define ESHUTDOWN       108
#define ETIMEDOUT       110
#define ECONNREFUSED    111
#define EHOSTDOWN       112
#define EHOSTUNREACH    113
#define EALREADY        114
#define EINPROGRESS     115
#define ENOTSUP         134
#define EOVERFLOW       139

#endif /* IOT_ML307N_ERRNO_H */
