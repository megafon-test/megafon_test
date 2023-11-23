# Основы Tarantool

- [Решение 1, 2 части задания (файл - `storage.lua`)](https://github.com/megafon-test/megafon_test/blob/master/app/roles/api.lua)
- [Решение 3 части задания (файл - `api.lua`)](https://github.com/megafon-test/megafon_test/blob/master/app/roles/storage.lua)

## Часть 1: Установка и Инициализация

### Установка Tarantool

1. Установите Tarantool на свой компьютер.

### Создание пространства данных

2. Создайте пространство (space) данных с именем `call_records` для хранения записей о телефонных звонках. Структура записи должна включать следующие поля:
    - `call_id` (идентификатор звонка)
    - `caller_number` (номер звонящего)
    - `callee_number` (номер принимающего звонок)
    - `duration` (длительность звонка в секундах).

### Операции с данными

3. Добавьте несколько тестовых записей в пространство данных `call_records`, представляющих собой различные телефонные звонки.

### Lua-функции

4. Напишите Lua-функцию для выборки всех звонков, длительность которых превышает 5 минут.

5. Реализуйте Lua-функцию для добавления новой записи о звонке.

6. Реализуйте возможность удаления записей о звонках.

## Часть 2: Оптимизация запросов и Индексы

### Индексы

1. Создайте индексы для ускорения запросов: индекс для поля `call_id` и индекс для поля `caller_number`.

### Оптимизация запросов

2. Напишите Lua-функцию, которая выбирает все звонки с указанным номером `caller_number` за последний час.

## Часть 3: HTTP-сервер

### HTTP-сервер

1. Реализуйте простой HTTP-сервер, используя Tarantool HTTP-фреймворк или другой подходящий инструмент.

2. Создайте эндпоинт для получения информации о звонке по его идентификатору (`call_id`).
