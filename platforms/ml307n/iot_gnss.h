/**
 * @file iot_gnss.h
 * @brief ML307N GNSS接口定义
 */

#ifndef IOT_PLATFORM_ML307N_GNSS_H
#define IOT_PLATFORM_ML307N_GNSS_H

#ifdef __cplusplus
extern "C" {
#endif

#include <stdint.h>

/**
 * @brief NMEA协议类型位掩码
 */
#define IOT_GNSS_NMEA_GGA  (1 << 0)
#define IOT_GNSS_NMEA_GSV  (1 << 1)
#define IOT_GNSS_NMEA_GSA  (1 << 2)
#define IOT_GNSS_NMEA_RMC  (1 << 3)
#define IOT_GNSS_NMEA_VTG  (1 << 4)
#define IOT_GNSS_NMEA_GLL  (1 << 5)

/**
 * @brief GNSS系统类型
 */
typedef enum {
    IOT_GNSS_SYS_BDS = 0,       /**< 北斗系统 */
    IOT_GNSS_SYS_GPS,           /**< GPS系统 */
    IOT_GNSS_SYS_BDS_GPS,       /**< 北斗+GPS */
    IOT_GNSS_SYS_GLONASS,       /**< GLONASS系统 */
    IOT_GNSS_SYS_BDS_GLONASS,   /**< 北斗+GLONASS */
    IOT_GNSS_SYS_GPS_GLONASS    /**< GPS+GLONASS */
} iot_gnss_system_e;

/**
 * @brief 定位信息
 */
typedef struct {
    double latitude;        /**< 纬度 (度) */
    double longitude;       /**< 经度 (度) */
    double altitude;        /**< 海拔 (米) */
    double speed;           /**< 速度 (km/h) */
    uint8_t satellites;     /**< 卫星数量 */
    uint8_t fix;            /**< 定位类型 (0=无定位, 1=单点, 2=差分等) */
    uint16_t year;          /**< 年份 */
    uint8_t month;          /**< 月份 */
    uint8_t day;            /**< 日期 */
    uint8_t hour;           /**< 小时 */
    uint8_t minute;         /**< 分钟 */
    uint8_t second;         /**< 秒 */
} iot_gnss_location_t;

/**
 * @brief 打开GNSS
 * @param system 系统类型
 * @return 成功返回 0，失败返回错误码
 */
int iot_gnss_open(iot_gnss_system_e system);

/**
 * @brief 关闭GNSS
 * @return 成功返回 0，失败返回错误码
 */
int iot_gnss_close(void);

/**
 * @brief 配置NMEA输出
 * @param nmea_mask NMEA类型位掩码
 * @param period 输出周期 (秒)
 * @return 成功返回 0，失败返回错误码
 */
int iot_gnss_config(uint32_t nmea_mask, uint32_t period);

/**
 * @brief 设置定位模式
 * @param mode 0-连续定位, 1-单次定位
 * @return 成功返回 0，失败返回错误码
 */
int iot_gnss_set_mode(uint8_t mode);

/**
 * @brief 获取当前定位信息
 * @param loc 定位信息指针
 * @return 成功返回 0，失败返回错误码
 */
int iot_gnss_get_location(iot_gnss_location_t *loc);

#ifdef __cplusplus
}
#endif

#endif /* IOT_PLATFORM_ML307N_GNSS_H */
