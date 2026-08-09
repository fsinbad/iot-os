/**
 * @file iot_i2c.h
 * @brief ML307N I2C接口定义
 */

#ifndef IOT_PLATFORM_ML307N_I2C_H
#define IOT_PLATFORM_ML307N_I2C_H

#ifdef __cplusplus
extern "C" {
#endif

#include <stdint.h>

/**
 * @brief I2C速度模式
 */
typedef enum {
    IOT_I2C_SPEED_STANDARD = 0,  /**< 标准模式 (100kHz) */
    IOT_I2C_SPEED_FAST,          /**< 快速模式 (400kHz) */
    IOT_I2C_SPEED_HIGH           /**< 高速模式 (1MHz) */
} iot_i2c_speed_e;

/**
 * @brief I2C设备配置
 */
typedef struct {
    uint8_t scl_pin;        /**< SCL引脚 */
    uint8_t sda_pin;        /**< SDA引脚 */
    iot_i2c_speed_e speed;   /**< 速度模式 */
    uint8_t own_addr;       /**< 自身地址 (主机模式下为0) */
} iot_i2c_config_t;

/**
 * @brief 初始化I2C
 * @param cfg 配置参数
 * @return 成功返回 0，失败返回错误码
 */
int iot_i2c_setup(const iot_i2c_config_t *cfg);

/**
 * @brief 关闭I2C
 * @return 成功返回 0，失败返回错误码
 */
int iot_i2c_close(void);

/**
 * @brief 向从设备写入数据
 * @param dev_addr 从设备地址 (7位地址)
 * @param data 数据缓冲区
 * @param len 数据长度
 * @return 成功返回 0，失败返回错误码
 */
int iot_i2c_write(uint8_t dev_addr, const uint8_t *data, uint32_t len);

/**
 * @brief 从从设备读取数据
 * @param dev_addr 从设备地址 (7位地址)
 * @param data 数据缓冲区
 * @param len 数据长度
 * @return 成功返回 0，失败返回错误码
 */
int iot_i2c_read(uint8_t dev_addr, uint8_t *data, uint32_t len);

#ifdef __cplusplus
}
#endif

#endif /* IOT_PLATFORM_ML307N_I2C_H */
