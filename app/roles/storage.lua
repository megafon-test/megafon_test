--- модуль проверки аргументов в функциях
local checks = require('checks')
local cartridge = require('cartridge')

--- инициализация спейса
local function init_spaces()
    local call_records = box.schema.space.create(
    --- имя спейса для хранения записей о телефонных звонках
        'call_records',
    --- дополнительные параметры
        {
            --- формат хранимых кортежей
            format = {
                --- идентификатор звонка
                {'call_id', 'unsigned'},
                --- номер звонящего
                {'caller_number', 'string'},
                --- номер принимающего звонок
                {'callee_number', 'string'},
                --- длительность звонка в секундах
                {'duration', 'unsigned'},
            },
            --- создадим спейс, только если его не было
            if_not_exists = true,
        }
    )

    --- создадим индекс по call_id  - идентификатор звонка
    call_records:create_index('call_id', {
        --- компонент кортежа, который будет входить в индекс
        parts = {'call_id'},
        --- создадим индекс, только если его нет
        if_not_exists = true,
    })
    --- создадим индекс по caller_number - номер звонящего
    call_records:create_index('caller_number', {
        --- компонент кортежа, который будет входить в индекс
        parts = {'caller_number'},
        --- создадим индекс, только если его нет
        if_not_exists = true,
    })
end

--- инициализация функции для добавления данных звонка
local function add_call(call)

    --- Проверяем поля внутри ~таблицы call
    assert(type(call.call_id) == 'number', 'call_id must be a number')
    assert(type(call.caller_number) == 'string', 'caller_number must be a string')
    assert(type(call.callee_number) == 'string', 'callee_number must be a string')
    assert(type(call.duration) == 'number', 'duration must be a number per seconds')

    --- открытие транзакции
    box.begin()

    --- вставка кортежа в спейс call_records
    box.space.call_records:insert({
        call.call_id,
        call.caller_number,
        call.callee_number,
        call.duration
    })

    --- коммит транзакции
    box.commit()
    return true
end

--- функция для выборки всех звонков, длительность которых превышает 5 минут
local function find_calls_with_duration_over()

    --- длительность 5 минут
    local duration = 5 * 60
    --- звонки длительностью более 5 минут
    local calls = {}

    --- выбираем звонки длительностью более 5 минут, используя итератор GT
    for _, call in box.space.call_records.index.call_id:pairs(duration, {iterator = 'GT'}) do
        table.insert(calls, call)
    end
    --- вернем результат выборки
    return calls
end

--- функция для удаления звонков по call_id
local function delete_call_by_call_id(call_id)

    --- проверим формат call_id
    checks('number')

    --- Проверка наличия записи по call_id
    local record = box.space.call_records:get(call_id)
    if record then
        --- Удаление записи, если она найдена
        box.space.call_records:delete(call_id)
    end
end

--- функция, которая выбирает все звонки с указанным номером caller_number за последний час
local function select_calls_for_last_hour(caller_number)

    --- время, которое было один час назад от текущего момента
    local one_hour_ago = os.time() - 3600

    --- сюда собираем подходящие записи
    local result = {}

    --- выбираем только те записи, которые точно соотвествуют caller_number, используя итератор EQ
    for _, call in box.space.call_records.index.caller_number:pairs(caller_number, {iterator = 'EQ'}) do
        if call.duration >= one_hour_ago then
            table.insert(result, call)
        end
    end

    return result
end

--- функция для поиска звонка по call_id
local function find_call_by_id(call_id)
    checks('number')

    local call = box.space.call_records:get(call_id)
    if call == nil then
        return nil
    end
    call = {
        call_id = call.call_id;
        caller_number = call.caller_number;
        callee_number = call.callee_number;
        duration = call.duration;
    }

    return call
end

--- функция для вставки тестовых записей
local function add_test_calls()

    box.space.call_records:insert{1, '111111111111', '222222222222', 65}
    box.space.call_records:insert{2, '111111111111', '222222222222', 154}
    box.space.call_records:insert{3, '555555555555', '444444444444', 350}
    box.space.call_records:insert{4, '999999999999', '777777777777', 425}

    return true
end

--- экспорт функций
local exported_functions = {
    add_call = add_call,
    find_calls_with_duration_over = find_calls_with_duration_over,
    delete_call_by_call_id = delete_call_by_call_id,
    select_calls_for_last_hour = select_calls_for_last_hour,
    add_test_calls = add_test_calls,
    find_call_by_id = find_call_by_id
}

--- инициализиурем роль storage
local function init(opts)
    if opts.is_master then
        --- вызываем функцию инициализацию спейсов
        init_spaces()

        for name in pairs(exported_functions) do
            box.schema.func.create(name, {if_not_exists = true})
            box.schema.role.grant('public', 'execute', 'function', name, {if_not_exists = true})
        end
    end

    for name, func in pairs(exported_functions) do
        rawset(_G, name, func)
    end

    --- добавляем тестовые записи
    add_test_calls()

    return true
end

return {
    role_name = 'storage',
    init = init,
    dependencies = {
        'cartridge.roles.vshard-storage',
    },
}

local ok, err = cartridge.cfg({
    roles = {
        'cartridge.roles.vshard-storage',
        'cartridge.roles.vshard-router',
        'cartridge.roles.metrics',
        'app.roles.api',
        'app.roles.storage',
    },
    cluster_cookie = 'getting-started-app-cluster-cookie',
})
