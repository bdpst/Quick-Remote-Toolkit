# Quick Remote Toolkit

Batch-меню для быстрых действий удаленной поддержки в Windows.

## Возможности

- Открыть Windows Remote Assistance (`msra.exe /offerra`).
- Проверить `ping` выбранного клиента.
- Открыть административную шару `\\PC-NAME\c$`.
- Открыть Event Viewer удаленного ПК.
- Запустить `mstsc` для выбранного клиента.

## Использование

1. Скопируйте `QuickRemoteToolkit.clients.example.csv` в `QuickRemoteToolkit.clients.csv`.
2. Заполните `QuickRemoteToolkit.clients.csv` своими клиентами.
3. Запустите `Quick Remote Toolkit.bat`.

Формат CSV:

```csv
number;computer;ip;person
1;PC-NAME;192.168.1.10;Иванов Иван
```

`QuickRemoteToolkit.clients.csv` добавлен в `.gitignore`, чтобы реальные IP-адреса и ФИО не попадали в репозиторий.

## Связь с Remote Assistant

Формат CSV совместим с `Remote-Assistant`.

Если рядом со скриптом нет `QuickRemoteToolkit.clients.csv`, но есть `RemoteAssistant.clients.csv`, toolkit автоматически использует его. Так можно держать один общий список клиентов для обеих утилит.

## Команды

На экране списка клиентов:

- `R` — открыть последнего выбранного клиента.
- `E` — открыть текущий CSV в Блокноте.
- `L` — перечитать CSV.
- `0` — выйти.

После выбора клиента:

- `1` — открыть Remote Assistance.
- `2` — проверить `ping`.
- `3` — открыть `\\PC-NAME\c$`.
- `4` — открыть Event Viewer удаленного ПК.
- `5` — запустить `mstsc`.
- `9` — вернуться к списку клиентов.
- `0` — выйти.
