/**
 * @file iot_event.h
 * @brief ML307N 平台事件接口定义
 */

#ifndef IOT_PLATFORM_ML307N_EVENT_H
#define IOT_PLATFORM_ML307N_EVENT_H

#ifdef __cplusplus
extern "C" {
#endif

/* 网络状态事件常量 */
#define IOT_EVENT_IP_READY      "IP_READY"
#define IOT_EVENT_IP_LOSE       "IP_LOSE"

/* SIM状态事件常量 */
#define IOT_EVENT_SIM_READY         "SIM_READY"
#define IOT_EVENT_SIM_PIN_REQUIRED  "SIM_PIN_REQUIRED"
#define IOT_EVENT_SIM_PUK_REQUIRED  "SIM_PUK_REQUIRED"
#define IOT_EVENT_SIM_REMOVED       "SIM_REMOVED"
#define IOT_EVENT_SIM_INSERTED      "SIM_INSERTED"

/* FOTA事件常量 */
#define IOT_EVENT_FOTA_START       "FOTA_START"
#define IOT_EVENT_FOTA_PROGRESS    "FOTA_PROGRESS"
#define IOT_EVENT_FOTA_SUCCESS     "FOTA_SUCCESS"
#define IOT_EVENT_FOTA_FAILED      "FOTA_FAILED"

/**
 * @brief 初始化事件监控（网络、SIM、FOTA等）
 */
void iot_event_init(void);

/**
 * @brief 反初始化事件监控
 */
void iot_event_deinit(void);

#ifdef __cplusplus
}
#endif

#endif /* IOT_PLATFORM_ML307N_EVENT_H */
