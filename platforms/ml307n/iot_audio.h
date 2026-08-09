/**
 * @file iot_audio.h
 * @brief ML307N 音频接口定义
 */

#ifndef IOT_PLATFORM_ML307N_AUDIO_H
#define IOT_PLATFORM_ML307N_AUDIO_H

#ifdef __cplusplus
extern "C" {
#endif

/**
 * @brief 音频状态
 */
typedef enum {
    IOT_AUDIO_STATE_IDLE = 0,   /**< 空闲 */
    IOT_AUDIO_STATE_PLAYING,    /**< 播放中 */
    IOT_AUDIO_STATE_PAUSED,     /**< 已暂停 */
    IOT_AUDIO_STATE_RECORDING   /**< 录音中 */
} iot_audio_state_e;

/**
 * @brief 音频配置
 */
typedef struct {
    uint32_t sample_rate;       /**< 采样率 (e.g., 8000, 16000, 44100) */
    uint16_t channels;          /**< 声道数 (1=单声道, 2=立体声) */
    uint16_t bits_per_sample;   /**< 位深 (8, 16, 24, 32) */
    uint32_t buffer_size;       /**< 缓冲区大小 */
} iot_audio_config_t;

/**
 * @brief 初始化音频模块
 * @return 成功返回 0，失败返回错误码
 */
int iot_audio_init(void);

/**
 * @brief 反初始化音频模块
 * @return 成功返回 0，失败返回错误码
 */
int iot_audio_deinit(void);

/**
 * @brief 播放PCM数据
 * @param data PCM数据指针
 * @param len 数据长度 (字节)
 * @return 成功返回 0，失败返回错误码
 */
int iot_audio_play_pcm(const uint8_t *data, uint32_t len);

/**
 * @brief 播放音频文件
 * @param path 文件路径
 * @return 成功返回 0，失败返回错误码
 */
int iot_audio_play(const char *path);

/**
 * @brief 暂停播放
 * @return 成功返回 0，失败返回错误码
 */
int iot_audio_pause(void);

/**
 * @brief 恢复播放
 * @return 成功返回 0，失败返回错误码
 */
int iot_audio_resume(void);

/**
 * @brief 停止播放/录音
 * @return 成功返回 0，失败返回错误码
 */
int iot_audio_stop(void);

/**
 * @brief 设置音量
 * @param volume 音量等级 (0-100)
 * @return 成功返回 0，失败返回错误码
 */
int iot_audio_set_volume(uint8_t volume);

/**
 * @brief 获取音量
 * @return 当前音量等级 (0-100)
 */
uint8_t iot_audio_get_volume(void);

/**
 * @brief 开始录音
 * @param path 录音文件保存路径 (可选)
 * @return 成功返回 0，失败返回错误码
 */
int iot_audio_record_start(const char *path);

/**
 * @brief 停止录音
 * @return 成功返回 0，失败返回错误码
 */
int iot_audio_record_stop(void);

/**
 * @brief 获取当前音频状态
 * @return 音频状态
 */
iot_audio_state_e iot_audio_get_state(void);

#ifdef __cplusplus
}
#endif

#endif /* IOT_PLATFORM_ML307N_AUDIO_H */
