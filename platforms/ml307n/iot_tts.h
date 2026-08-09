/**
 * @file iot_tts.h
 * @brief ML307N TTS (文本转语音) 接口定义
 */

#ifndef IOT_PLATFORM_ML307N_TTS_H
#define IOT_PLATFORM_ML307N_TTS_H

#ifdef __cplusplus
extern "C" {
#endif

#include <stdint.h>

/**
 * @brief TTS状态
 */
typedef enum {
    IOT_TTS_STATE_IDLE = 0,     /**< 空闲 */
    IOT_TTS_STATE_SYNTHESIZING, /**< 合成中 */
    IOT_TTS_STATE_PLAYING       /**< 播放中 */
} iot_tts_state_e;

/**
 * @brief TTS配置
 */
typedef struct {
    uint8_t volume;     /**< 音量 (0-100) */
    uint8_t speed;      /**< 语速 (50-200, 100为正常) */
    uint8_t pitch;      /**< 音调 (50-200, 100为正常) */
    char *voice;        /**< 音色 (e.g., "xiaoxiao") */
} iot_tts_config_t;

/**
 * @brief 初始化TTS
 * @return 成功返回 0，失败返回错误码
 */
int iot_tts_init(void);

/**
 * @brief 反初始化TTS
 * @return 成功返回 0，失败返回错误码
 */
int iot_tts_deinit(void);

/**
 * @brief 设置TTS参数
 * @param cfg 配置参数
 * @return 成功返回 0，失败返回错误码
 */
int iot_tts_set_config(const iot_tts_config_t *cfg);

/**
 * @brief 将文本转换为语音并播放
 * @param text 输入文本
 * @return 成功返回 0，失败返回错误码
 */
int iot_tts_speak(const char *text);

/**
 * @brief 停止播放
 * @return 成功返回 0，失败返回错误码
 */
int iot_tts_stop(void);

/**
 * @brief 获取当前TTS状态
 * @return TTS状态
 */
iot_tts_state_e iot_tts_get_state(void);

#ifdef __cplusplus
}
#endif

#endif /* IOT_PLATFORM_ML307N_TTS_H */
