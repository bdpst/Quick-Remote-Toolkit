# Quick Remote Toolkit

Batch-меню для быстрых действий удаленной поддержки в Windows.

## Возможности

- Открыть Windows Remote Assistance (`msra.exe /offerra`).
- Проверить `ping` выбранного клиента.
- Открыть административную шару `\\PC-NAME\c$`.
- Открыть Event Viewer удаленного ПК.
- Запустить `mstsc` для выбранного клиента.
- Запустить `tracert` до клиента.
- Открыть Computer Management удаленного ПК.
- Открыть удаленный `cmd` через WinRS.
- Запустить `gpupdate /force` через WinRS.
- Скопировать имя ПК или IP-адрес в буфер обмена.
- Вести локальный лог действий.
- Вести локальный список избранных клиентов.

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
- `F` — переключить режим “все клиенты / только избранные”.
- `E` — открыть текущий CSV в Блокноте.
- `L` — перечитать CSV.
- `0` — выйти.

После выбора клиента:

- `1` — открыть Remote Assistance.
- `2` — проверить `ping`.
- `3` — открыть `\\PC-NAME\c$`.
- `4` — открыть Event Viewer удаленного ПК.
- `5` — запустить `mstsc`.
- `6` — запустить `tracert`.
- `7` — открыть Computer Management.
- `8` — открыть удаленный `cmd` через WinRS.
- `G` — запустить `gpupdate /force` через WinRS.
- `C` — скопировать имя ПК.
- `I` — скопировать IP-адрес, а если IP не указан, имя ПК.
- `F` — добавить клиента в избранное или убрать из избранного.
- `9` — вернуться к списку клиентов.
- `0` — выйти.

## Удаленный cmd и gpupdate

Действия `8` и `G` используют встроенный Windows-инструмент `winrs`.

Для работы должны выполняться условия:

- на удаленном ПК включен WinRM;
- текущая учетная запись имеет права на удаленное подключение;
- сетевой профиль, firewall и политики домена разрешают WinRM.

Если в вашей среде используется PsExec, его тоже можно запускать вручную из открытого cmd, например:

```bat
psexec \\PC-NAME cmd
psexec \\PC-NAME gpupdate /force
```

## Локальные пользовательские файлы

Эти файлы создаются рядом со скриптом и не попадают в git:

- `QuickRemoteToolkit.clients.csv` — реальный список клиентов.
- `RemoteAssistant.clients.csv` — совместимый список клиентов от Remote Assistant.
- `QuickRemoteToolkit.favorites.txt` — избранные клиенты.
- `QuickRemoteToolkit.actions.log` — лог действий.
