--- Master 平台协议模块
--[[
@module master
@summary 物联网设备 MQTT 平台协议实现
@version 2.0
@date    2026.08.11
@usage

-- 创建 master 实例
local m = master.new({
    model_id = "test-model-001",
    model_secret = "test-secret-key",
    device_id = "test-device-001",
    server = "iot.example.com",
    port = 1883,
})

-- 连接平台
m:connect()

-- 属性上报
m:report_property({temperature = 25.5, humidity = 60})

-- 事件上报
m:report_event("alarm", "trigger", {level = "high"})

-- 状态上报
m:report_status({online = true, csq = 23, battery = 85})

-- 监听属性写入
m:on("property_set", function(props)
    print("property set:", props)
    return true
end)

-- 监听远程控制
m:on("service_call", function(cmd, params)
    if cmd == "reboot" then
        pm.reboot()
    end
    return {success = true}
end)

-- 文件管理
m:upload_file("/path/to/file", data)
m:download_file("/path/to/file")
m:delete_file("/path/to/file")
]]

local master = {}

--======================================== 常量定义 ========================================--

local TOPIC_PREFIX = "$thing"

local STATE = {
    IDLE = "idle",
    CONNECTING = "connecting",
    CONNECTED = "connected",
    RECONNECTING = "reconnecting",
    ERROR = "error",
}

local ERR = {
    OK = 0,
    PARAM = -1,
    NOT_CONNECTED = -2,
    TIMEOUT = -3,
    SEND_FAILED = -4,
}

local SERVICE_CMD = {
    REBOOT = "reboot",
    RESET = "reset",
    WATCH = "watch",
}

--======================================== 内部变量 ========================================--

local master_list = {}  -- {id -> master_instance}

--======================================== 工具函数 ========================================--

local function generate_id(prefix)
    return string.format("%s-%d-%04d", prefix, os.time(), math.random(0, 9999))
end

local function build_topic(suffix, device_id)
    return string.format("%s/%s/%s", TOPIC_PREFIX, device_id, suffix)
end

local function safe_json_encode(data)
    local ok, encoded = pcall(json.encode, data)
    if ok then return encoded end
    return nil
end

local function safe_json_decode(str)
    if not str or str == "" then return nil end
    local ok, decoded = pcall(json.decode, str)
    if ok then return decoded end
    return nil
end

--======================================== Master 实例 ========================================--

--- 创建 master 客户端
-- @param config 配置表
-- @return master 实例
function master.new(config)
    if not config or not config.model_id or not config.device_id then
        log.error("master.new: config requires model_id and device_id")
        return nil
    end
    
    local instance = {
        model_id = config.model_id,
        model_secret = config.model_secret or "",
        device_id = config.device_id,
        server = config.server or "iot.example.com",
        port = config.port or 1883,
        use_ssl = config.use_ssl or false,
        keepalive = config.keepalive or 60,
        state = STATE.IDLE,
        mqtt_client = nil,
        callbacks = {
            property_set = nil,
            property_get = nil,
            service_call = nil,
            setting_set = nil,
            setting_get = nil,
            database_sync = nil,
            database_load = nil,
            status_update = nil,
        },
        request_ids = {},  -- 等待响应的请求
    }
    
    -- 设置 metatable，使实例可以通过 : 调用 master 模块的方法
    setmetatable(instance, { __index = master })
    
    -- 注册 MQTT 消息回调
    local topic = build_topic("post/#", config.device_id)
    -- 实际 MQTT 客户端创建会在 connect 时处理
    
    return instance
end

--- 连接到平台
-- @param self master 实例
-- @return boolean 成功/失败
function master.connect(self)
    if self.state == STATE.CONNECTED then
        return true
    end
    
    self.state = STATE.CONNECTING
    log.info("master: connecting to %s:%d", self.server, self.port)
    
    -- 创建 MQTT 客户端
    self.mqtt_client = mqtt.new({
        host = self.server,
        port = self.port,
        client_id = self.device_id,
        username = self.model_id,
        password = self.model_secret,
        use_ssl = self.use_ssl,
        keepalive = self.keepalive,
    })
    
    if not self.mqtt_client then
        self.state = STATE.ERROR
        log.error("master: failed to create MQTT client")
        return false
    end
    
    -- 设置消息回调
    self.mqtt_client:on("message", function(topic, payload)
        self:_on_message(topic, payload)
    end)
    
    self.mqtt_client:on("connected", function()
        self.state = STATE.CONNECTED
        log.info("master: connected successfully")
        self:_subscribe_topics()
        self:_on_connected()
    end)
    
    self.mqtt_client:on("disconnected", function()
        self.state = STATE.RECONNECTING
        log.warn("master: disconnected, will retry...")
        self:_on_disconnected()
    end)
    
    self.mqtt_client:on("error", function(err)
        self.state = STATE.ERROR
        log.error("master: MQTT error: %s", err)
    end)
    
    -- 连接
    local ok = self.mqtt_client:connect()
    if not ok then
        self.state = STATE.ERROR
        log.error("master: connect failed")
        return false
    end
    
    return true
end

--- 断开连接
-- @param self master 实例
function master.disconnect(self)
    if self.mqtt_client then
        self.mqtt_client:disconnect()
        self.state = STATE.IDLE
        log.info("master: disconnected")
    end
end

--- 获取当前状态
-- @param self master 实例
-- @return string 状态
function master.get_state(self)
    return self.state
end

--======================================== 上报接口 ========================================--

--- 属性上报
-- @param self master 实例
-- @param properties 属性键值对表
-- @param timestamp 时间戳（可选）
-- @return boolean, string 成功/失败, 错误信息
function master.report_property(self, properties, timestamp)
    if self.state ~= STATE.CONNECTED then
        return false, "not connected"
    end
    
    timestamp = timestamp or os.time() * 1000
    
    local payload = {
        properties = properties,
        time = timestamp,
    }
    
    local data = safe_json_encode(payload)
    if not data then
        return false, "json encode failed"
    end
    
    local topic = build_topic("post/property/report", self.device_id)
    local ok = self.mqtt_client:publish(topic, data, 0, false)
    
    if ok then
        log.info("master: property reported")
        return true
    end
    
    return false, "send failed"
end

--- 事件上报
-- @param self master 实例
-- @param name 事件名称
-- @param event_type 事件类型 (info/alert/fault)
-- @param params 事件参数表
-- @return boolean, string
function master.report_event(self, name, event_type, params)
    if self.state ~= STATE.CONNECTED then
        return false, "not connected"
    end
    
    local payload = {
        event = {
            name = name,
            type = event_type or "info",
            params = params or {},
        },
        time = os.time() * 1000,
    }
    
    local data = safe_json_encode(payload)
    if not data then
        return false, "json encode failed"
    end
    
    local topic = build_topic("post/event/report", self.device_id)
    local ok = self.mqtt_client:publish(topic, data, 0, false)
    
    if ok then
        log.info("master: event '%s' reported", name)
        return true
    end
    
    return false, "send failed"
end

--- 状态上报
-- @param self master 实例
-- @param status 状态表 {online, csq, battery, uptime, signal}
-- @return boolean, string
function master.report_status(self, status)
    if self.state ~= STATE.CONNECTED then
        return false, "not connected"
    end
    
    status = status or {}
    local payload = {
        status = {
            online = status.online and 1 or 0,
            csq = status.csq or 0,
            battery = status.battery or 0,
            uptime = status.uptime or 0,
            signal = status.signal or "unknown",
        },
        time = os.time() * 1000,
    }
    
    local data = safe_json_encode(payload)
    if not data then
        return false, "json encode failed"
    end
    
    local topic = build_topic("post/status/report", self.device_id)
    local ok = self.mqtt_client:publish(topic, data, 0, true)  -- QoS 1
    
    if ok then
        log.info("master: status reported")
        return true
    end
    
    return false, "send failed"
end

--- 批量属性上报（观察模式）
-- @param self master 实例
-- @param properties 属性数组
-- @return boolean, string
function master.watch_property(self, properties)
    if self.state ~= STATE.CONNECTED then
        return false, "not connected"
    end
    
    local payload = {
        properties = properties,
        watch = true,
        time = os.time() * 1000,
    }
    
    local data = safe_json_encode(payload)
    if not data then
        return false, "json encode failed"
    end
    
    local topic = build_topic("post/property/report", self.device_id)
    local ok = self.mqtt_client:publish(topic, data, 0, false)
    
    if ok then
        return true
    end
    return false, "send failed"
end

--======================================== 响应接口 ========================================--

--- 响应属性写入
-- @param self master 实例
-- @param request_id 请求 ID
-- @param success 是否成功
-- @param message 结果消息
function master.respond_property_set(self, request_id, success, message)
    self:_respond("property/set", request_id, success, message)
end

--- 响应属性读取
-- @param self master 实例
-- @param request_id 请求 ID
-- @param success 是否成功
-- @param message 结果消息
-- @param data 响应数据
function master.respond_property_get(self, request_id, success, message, data)
    self:_respond("property/get", request_id, success, message, data)
end

--- 响应远程控制
-- @param self master 实例
-- @param request_id 请求 ID
-- @param success 是否成功
-- @param message 结果消息
-- @param data 响应数据
function master.respond_service_call(self, request_id, success, message, data)
    self:_respond("service/call", request_id, success, message, data)
end

--- 响应配置下发
-- @param self master 实例
-- @param request_id 请求 ID
-- @param success 是否成功
-- @param message 结果消息
function master.respond_setting_set(self, request_id, success, message)
    self:_respond("setting/set", request_id, success, message)
end

--- 响应配置查询
-- @param self master 实例
-- @param request_id 请求 ID
-- @param success 是否成功
-- @param message 结果消息
-- @param data 响应数据
function master.respond_setting_get(self, request_id, success, message, data)
    self:_respond("setting/get", request_id, success, message, data)
end

--- 响应数据库同步
-- @param self master 实例
-- @param request_id 请求 ID
-- @param success 是否成功
-- @param message 结果消息
-- @param affected_rows 影响行数
function master.respond_database_sync(self, request_id, success, message, affected_rows)
    local extra = nil
    if affected_rows then
        extra = { affected_rows = affected_rows }
    end
    self:_respond("database/sync", request_id, success, message, extra)
end

--- 响应数据库加载
-- @param self master 实例
-- @param request_id 请求 ID
-- @param success 是否成功
-- @param message 结果消息
-- @param data 响应数据
function master.respond_database_load(self, request_id, success, message, data)
    self:_respond("database/load", request_id, success, message, data)
end

--======================================== 内部实现 ========================================--

--- 订阅平台下行主题
function master._subscribe_topics(self)
    local topics = {
        build_topic("post/property/set", self.device_id),
        build_topic("post/property/get", self.device_id),
        build_topic("post/service/call", self.device_id),
        build_topic("post/setting/set", self.device_id),
        build_topic("post/setting/get", self.device_id),
        build_topic("post/database/sync", self.device_id),
        build_topic("post/database/load", self.device_id),
    }
    
    for _, topic in ipairs(topics) do
        self.mqtt_client:subscribe(topic, 1)
    end
    
    log.info("master: subscribed to %d topics", #topics)
end

--- 处理 MQTT 消息
function master._on_message(self, topic, payload)
    log.debug("master: received message on topic: %s", topic)
    
    local data = safe_json_decode(payload)
    if not data then
        log.error("master: failed to decode message")
        return
    end
    
    -- 根据 topic 路由到对应处理函数
    if topic:find("property/set") then
        self:_handle_property_set(data)
    elseif topic:find("property/get") then
        self:_handle_property_get(data)
    elseif topic:find("service/call") then
        self:_handle_service_call(data)
    elseif topic:find("setting/set") then
        self:_handle_setting_set(data)
    elseif topic:find("setting/get") then
        self:_handle_setting_get(data)
    elseif topic:find("database/sync") then
        self:_handle_database_sync(data)
    elseif topic:find("database/load") then
        self:_handle_database_load(data)
    end
end

--- 处理属性写入
function master._handle_property_set(self, data)
    local request_id = data.id or generate_id("req")
    local props = data.params or data.properties or {}
    
    log.info("master: property set request %s", request_id)
    
    if self.callbacks.property_set then
        local ok, result = pcall(self.callbacks.property_set, props)
        if ok and result then
            self:respond_property_set(request_id, true, "success")
        else
            self:respond_property_set(request_id, false, "handler failed")
        end
    else
        self:respond_property_set(request_id, true, "no handler")
    end
end

--- 处理属性读取
function master._handle_property_get(self, data)
    local request_id = data.id or generate_id("req")
    local keys = data.params or data.properties  -- nil 表示全部
    
    log.info("master: property get request %s", request_id)
    
    if self.callbacks.property_get then
        local ok, result = pcall(self.callbacks.property_get, keys)
        if ok and result then
            self:respond_property_get(request_id, true, "success", result)
        else
            self:respond_property_get(request_id, false, "handler failed")
        end
    else
        self:respond_property_get(request_id, true, "no handler")
    end
end

--- 处理远程控制
function master._handle_service_call(self, data)
    local request_id = data.id or generate_id("req")
    local cmd = data.service or data.command or ""
    local params = data.params or {}
    
    log.info("master: service call: %s, cmd=%s", request_id, cmd)
    
    -- 内置命令处理
    if cmd == SERVICE_CMD.REBOOT then
        log.info("master: executing reboot command")
        local delay = params.delay or 0
        local force = params.force or false
        
        if delay > 0 then
            iot.setTimeout(function()
                pm.reboot(force)
            end, delay)
        else
            pm.reboot(force)
        end
        
        self:respond_service_call(request_id, true, "rebooting")
        return
    end
    
    if cmd == SERVICE_CMD.RESET then
        log.info("master: executing reset command")
        local scope = params.scope or "all"
        local keep_network = params.keep_network or false
        
        -- 执行恢复出厂
        self:_do_factory_reset(scope, keep_network)
        
        self:respond_service_call(request_id, true, "resetting")
        return
    end
    
    if cmd == SERVICE_CMD.WATCH then
        log.info("master: entering watch mode")
        local interval = params.interval or 1000
        
        self:_start_watch_mode(interval)
        
        self:respond_service_call(request_id, true, "watch mode started")
        return
    end
    
    -- 自定义命令回调
    if self.callbacks.service_call then
        local ok, result = pcall(self.callbacks.service_call, cmd, params)
        if ok and result then
            self:respond_service_call(request_id, true, "success", result)
        else
            self:respond_service_call(request_id, false, "handler failed")
        end
    else
        self:respond_service_call(request_id, false, "unknown command")
    end
end

--- 处理配置下发
function master._handle_setting_set(self, data)
    local request_id = data.id or generate_id("req")
    local setting = data.setting or data.params or {}
    
    log.info("master: setting set request %s", request_id)
    
    -- 保存到本地
    self:_save_setting(setting)
    
    if self.callbacks.setting_set then
        pcall(self.callbacks.setting_set, setting)
    end
    
    self:respond_setting_set(request_id, true, "success")
end

--- 处理配置查询
function master._handle_setting_get(self, data)
    local request_id = data.id or generate_id("req")
    local keys = data.params or data.keys  -- nil 表示全部
    
    log.info("master: setting get request %s", request_id)
    
    if self.callbacks.setting_get then
        local ok, result = pcall(self.callbacks.setting_get, keys)
        if ok and result then
            self:respond_setting_get(request_id, true, "success", result)
        else
            local saved = self:_load_setting(keys)
            self:respond_setting_get(request_id, true, "success", saved)
        end
    else
        local saved = self:_load_setting(keys)
        self:respond_setting_get(request_id, true, "success", saved)
    end
end

--- 处理数据库同步
function master._handle_database_sync(self, data)
    local request_id = data.id or generate_id("req")
    local table_name = data.table or ""
    local records = data.records or {}
    
    log.info("master: database sync request %s, table=%s", request_id, table_name)
    
    -- 保存到本地数据库
    local affected = self:_save_to_database(table_name, records)
    
    if self.callbacks.database_sync then
        pcall(self.callbacks.database_sync, table_name, records)
    end
    
    self:respond_database_sync(request_id, true, "success", affected)
end

--- 处理数据库加载
function master._handle_database_load(self, data)
    local request_id = data.id or generate_id("req")
    local table_name = data.table or ""
    
    log.info("master: database load request %s, table=%s", request_id, table_name)
    
    -- 从本地数据库读取
    local records = self:_load_from_database(table_name)
    
    if self.callbacks.database_load then
        local ok, result = pcall(self.callbacks.database_load, table_name)
        if ok and result then
            records = result
        end
    end
    
    self:respond_database_load(request_id, true, "success", records)
end

--- 通用响应发送
function master._respond(self, suffix, request_id, success, message, data)
    if self.state ~= STATE.CONNECTED then
        return false
    end
    
    local payload = {
        id = request_id,
        code = success and 200 or 500,
        message = message or (success and "success" or "failed"),
    }
    
    if data ~= nil then
        payload.data = data
    end
    
    local encoded = safe_json_encode(payload)
    if not encoded then
        return false
    end
    
    local topic = build_topic("post/" .. suffix .. "/reply", self.device_id)
    return self.mqtt_client:publish(topic, encoded, 1, false)
end

--- 连接成功回调
function master._on_connected(self)
    -- 上报上线状态
    self:report_status({
        online = true,
        csq = net and net.csq() or 0,
        battery = pm and pm.battery() or 0,
        uptime = os.time(),
        signal = "strong",
    })
    
    -- 触发事件
    if self.callbacks.status_update then
        pcall(self.callbacks.status_update, "online")
    end
end

--- 断开连接回调
function master._on_disconnected(self)
    -- 尝试重连
    iot.setTimeout(function()
        if self.state == STATE.RECONNECTING then
            self:connect()
        end
    end, 3000)
    
    if self.callbacks.status_update then
        pcall(self.callbacks.status_update, "offline")
    end
end

--======================================== 文件管理 ========================================--

--- 上传文件
-- @param self master 实例
-- @param path 文件路径
-- @param data 文件数据（字符串）
-- @return boolean, string
function master.upload_file(self, path, data)
    if not path or not data then
        return false, "path and data are required"
    end
    
    log.info("master: uploading file: %s", path)
    
    -- 使用 MQTT 传输文件（分片上传）
    local chunk_size = 1024
    local total = #data
    local offset = 0
    
    while offset < total do
        local chunk = data:sub(offset + 1, offset + chunk_size)
        local payload = {
            path = path,
            offset = offset,
            data = chunk,
            total = total,
        }
        
        local encoded = safe_json_encode(payload)
        if encoded then
            local topic = build_topic("post/file/upload", self.device_id)
            self.mqtt_client:publish(topic, encoded, 1, false)
        end
        
        offset = offset + chunk_size
    end
    
    return true
end

--- 下载文件
-- @param self master 实例
-- @param path 文件路径
-- @return boolean, string
function master.download_file(self, path)
    if not path then
        return false, "path is required"
    end
    
    local request_id = generate_id("file_req")
    local payload = {
        id = request_id,
        path = path,
    }
    
    local encoded = safe_json_encode(payload)
    local topic = build_topic("post/file/download", self.device_id)
    
    self.mqtt_client:publish(topic, encoded, 1, false)
    
    -- 等待响应需要通过回调处理
    log.info("master: file download requested: %s", path)
    return true
end

--- 删除文件
-- @param self master 实例
-- @param path 文件路径
-- @return boolean, string
function master.delete_file(self, path)
    if not path then
        return false, "path is required"
    end
    
    local payload = {
        path = path,
    }
    
    local encoded = safe_json_encode(payload)
    local topic = build_topic("post/file/delete", self.device_id)
    
    self.mqtt_client:publish(topic, encoded, 1, false)
    
    log.info("master: file delete requested: %s", path)
    return true
end

--======================================== 本地存储 ========================================--

local settings_cache = {}
local database_cache = {}

function master._save_setting(self, setting)
    for k, v in pairs(setting) do
        settings_cache[k] = v
    end
    
    -- 持久化到文件
    local ok, err = pcall(function()
        if not io.open then return end
        local f = io.open("/config/settings.json", "w")
        if f then
            f:write(safe_json_encode(settings_cache))
            f:close()
        end
    end)
end

function master._load_setting(self, keys)
    -- 尝试从文件加载
    local ok, data = pcall(function()
        if not io.open then return nil end
        local f = io.open("/config/settings.json", "r")
        if f then
            local content = f:read("*a")
            f:close()
            return safe_json_decode(content) or {}
        end
        return nil
    end)
    
    if ok and data then
        for k, v in pairs(data) do
            settings_cache[k] = v
        end
    end
    
    -- 如果指定了 keys，返回对应部分
    if keys and type(keys) == "table" then
        local result = {}
        for _, key in ipairs(keys) do
            result[key] = settings_cache[key]
        end
        return result
    end
    
    return settings_cache
end

function master._save_to_database(self, table_name, records)
    if not database_cache[table_name] then
        database_cache[table_name] = {}
    end
    
    local count = 0
    for _, record in ipairs(records) do
        if record.id then
            database_cache[table_name][record.id] = record
            count = count + 1
        end
    end
    
    return count
end

function master._load_from_database(self, table_name)
    if not database_cache[table_name] then
        return {}
    end
    
    local records = {}
    for _, record in pairs(database_cache[table_name]) do
        records[#records + 1] = record
    end
    
    return records
end

--======================================== 恢复出厂 ========================================--

function master._do_factory_reset(self, scope, keep_network)
    log.warn("master: factory reset, scope=%s, keep_network=%s", scope, keep_network)
    
    -- 根据范围执行重置
    if scope == "all" or scope == "setting" then
        -- 清除设置
        settings_cache = {}
        
        if not keep_network then
            -- 清除网络配置
        end
    end
    
    if scope == "all" or scope == "data" then
        -- 清除数据库
        database_cache = {}
    end
    
    -- 重启设备
    iot.setTimeout(function()
        pm.reboot(false)
    end, 500)
end

function master._start_watch_mode(self, interval)
    if self._watch_timer then
        iot.clearInterval(self._watch_timer)
    end
    
    self._watch_timer = iot.setInterval(function()
        if self.callbacks.property_get then
            local ok, props = pcall(self.callbacks.property_get, nil)
            if ok and props then
                self:watch_property(props)
            end
        end
    end, interval)
    
    log.info("master: watch mode started, interval=%dms", interval)
end

--======================================== 事件监听 ========================================--

--- 注册事件回调
-- @param self master 实例
-- @param event 事件名 (property_set, property_get, service_call, etc.)
-- @param callback 回调函数
function master.on(self, event, callback)
    local valid_events = {
        property_set = true,
        property_get = true,
        service_call = true,
        setting_set = true,
        setting_get = true,
        database_sync = true,
        database_load = true,
        status_update = true,
    }
    
    if not valid_events[event] then
        log.error("master.on: invalid event: %s", event)
        return
    end
    
    self.callbacks[event] = callback
    log.info("master.on: registered handler for '%s'", event)
end

--- 取消事件回调
-- @param self master 实例
-- @param event 事件名
function master.off(self, event)
    self.callbacks[event] = nil
    log.info("master.off: unregistered handler for '%s'", event)
end

--======================================== 便捷方法 ========================================--

--- 上报属性（便捷方法）
-- @param self master 实例
-- @param props 属性表
function master.report(self, props)
    return self:report_property(props)
end

--- 发送事件（便捷方法）
-- @param self master 实例
-- @param name 事件名
-- @param params 参数
function master.event(self, name, params)
    return self:report_event(name, "info", params)
end

--- 更新状态（便捷方法）
-- @param self master 实例
function master.status(self)
    local status = {
        online = true,
        csq = net and net.csq() or 0,
        battery = pm and pm.battery() or 0,
        uptime = os.time(),
        signal = "strong",
    }
    return self:report_status(status)
end

return master
