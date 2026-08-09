/**
 * @file net_api_module.h
 * @brief ML307N 网络API模块接口定义
 */

#ifndef IOT_PLATFORM_ML307N_NET_API_MODULE_H
#define IOT_PLATFORM_ML307N_NET_API_MODULE_H

#ifdef __cplusplus
extern "C" {
#endif

#include <stdint.h>
#include "lwip/ip_addr.h"

#ifndef ERR_OK
#define ERR_OK 0
#endif

/**
 * @brief CID (Context Identifier) 状态
 */
typedef enum {
    CID_UNDEF_OR_UNREGIST = 0,  /**< 未定义或未注册 */
    CID_ONLY_IPV4_ACT,          /**< 仅IPv4激活 */
    CID_ONLY_IPV6_ACT,          /**< 仅IPv6激活 */
    CID_IPV4V6_ACT              /**< IPv4和IPv6均激活 */
} cm_cid_status_t;

/**
 * @brief 网络接口IP标志
 */
#define NET_API_IF_IP_4  (1 << 0)
#define NET_API_IF_IP_6  (1 << 1)

/**
 * @brief 网络接口信息结构
 */
typedef struct {
    uint32_t ip_flg;            /**< IP标志 (NET_API_IF_IP_4 / NET_API_IF_IP_6) */
    ip_addr_t ifIp4Addr;        /**< IPv4地址 */
    ip6_addr_t ifIp6Addr;       /**< IPv6地址 */
} NET_ApiIfInfo;

/**
 * @brief 获取默认CID编号
 * @return CID编号
 */
uint8_t cm_get_default_cidnum(void);

/**
 * @brief 获取CID状态
 * @param cid CID编号
 * @return CID状态
 */
cm_cid_status_t cm_get_cidstatus(uint8_t cid);

/**
 * @brief 根据CID获取网络接口信息
 * @param cid CID编号
 * @param info 接口信息输出
 * @return 成功返回 ERR_OK，失败返回错误码
 */
int NET_ApiIfInfoGetByCid(uint8_t cid, NET_ApiIfInfo *info);

#ifdef __cplusplus
}
#endif

#endif /* IOT_PLATFORM_ML307N_NET_API_MODULE_H */
