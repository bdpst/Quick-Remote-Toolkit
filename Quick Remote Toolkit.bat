@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul

set "TOOLKIT_CLIENTS_FILE=%~dp0QuickRemoteToolkit.clients.csv"
set "REMOTE_ASSISTANT_CLIENTS_FILE=%~dp0RemoteAssistant.clients.csv"
set "SYNC_SCRIPT=%~dp0Sync-QuickRemoteToolkitClients.ps1"
set "FAVORITES_FILE=%~dp0QuickRemoteToolkit.favorites.txt"
set "LOG_FILE=%~dp0QuickRemoteToolkit.actions.log"
set "CLIENTS_FILE="
set "LAST_CHOICE="
set "SHOW_FAVORITES=0"

set "COLOR_GREEN=[32m"
set "COLOR_RED=[31m"
set "COLOR_MILK=[97m"
set "COLOR_YELLOW=[33m"
set "COLOR_RESET=[0m"

call :find_clients_file
if not defined CLIENTS_FILE (
    goto missing_clients_menu
)
goto client_list

:missing_clients_menu
cls
echo:
echo:                       %COLOR_GREEN%Quick Remote Toolkit%COLOR_RESET%
echo: _______________________________________________________________________________
echo:
echo %COLOR_RED%Не найден файл со списком клиентов.%COLOR_RESET%
echo:
echo Создайте рядом со скриптом один из файлов:
echo   QuickRemoteToolkit.clients.csv
echo   RemoteAssistant.clients.csv
echo:
echo Можно скопировать QuickRemoteToolkit.clients.example.csv и заполнить его своими данными.
echo:
echo:  %COLOR_YELLOW%S   ^| Собрать список клиентов из Active Directory%COLOR_RESET%
echo:  %COLOR_YELLOW%0   ^| Выйти%COLOR_RESET%
echo:

set "missing_choice="
set /p missing_choice="Введите команду: " || exit /b 1
if /i "%missing_choice%"=="S" (
    call :sync_clients_from_ad
    call :find_clients_file
    if defined CLIENTS_FILE goto client_list
    goto missing_clients_menu
)
if "%missing_choice%"=="0" exit /b 1
goto missing_clients_menu

:client_list
call :find_clients_file
call :load_clients
cls
call :print_header

set "shown=0"
for /f "usebackq skip=1 tokens=1-4 delims=;" %%A in ("%CLIENTS_FILE%") do (
    if not "%%~A"=="" (
        set "can_show=1"
        if "%SHOW_FAVORITES%"=="1" (
            call :is_favorite "%%B"
            if "!IS_FAVORITE!"=="0" set "can_show=0"
        )
        if "!can_show!"=="1" (
            call :print_row "%%A" "%%B" "%%C" "%%D"
            set /a shown+=1
        )
    )
)

if "%shown%"=="0" (
    echo:  %COLOR_RED%В выбранном режиме список пуст.%COLOR_RESET%
)

call :print_client_footer

set "choice="
set /p choice="Введите номер клиента или команду: " || exit /b 0
if not defined choice goto client_list

if /i "%choice%"=="0" exit /b 0
if /i "%choice%"=="Q" exit /b 0

if /i "%choice%"=="E" (
    start "" notepad.exe "%CLIENTS_FILE%"
    goto client_list
)

if /i "%choice%"=="S" (
    call :sync_clients_from_ad
    goto client_list
)

if /i "%choice%"=="F" (
    if "%SHOW_FAVORITES%"=="1" (
        set "SHOW_FAVORITES=0"
    ) else (
        set "SHOW_FAVORITES=1"
    )
    goto client_list
)

if /i "%choice%"=="L" goto client_list

if /i "%choice%"=="R" (
    if defined LAST_CHOICE (
        set "choice=%LAST_CHOICE%"
    ) else (
        echo:
        echo %COLOR_RED%Пока нет последнего выбранного клиента.%COLOR_RESET%
        timeout /t 2 >nul
        goto client_list
    )
)

if not defined CLIENT_%choice% (
    echo:
    echo %COLOR_RED%Клиент с номером "%choice%" не найден.%COLOR_RESET%
    timeout /t 2 >nul
    goto client_list
)

set "LAST_CHOICE=%choice%"
call :set_selected "%choice%"
goto toolkit_menu

:toolkit_menu
cls
call :print_selected
echo:
echo:  %COLOR_YELLOW%1   ^| Открыть Remote Assistance%COLOR_RESET%
echo:  %COLOR_YELLOW%2   ^| Проверить ping клиента%COLOR_RESET%
echo:  %COLOR_YELLOW%3   ^| Открыть \\!computer!\c$%COLOR_RESET%
echo:  %COLOR_YELLOW%4   ^| Открыть Event Viewer удаленного ПК%COLOR_RESET%
echo:  %COLOR_YELLOW%5   ^| Запустить mstsc%COLOR_RESET%
echo:  %COLOR_YELLOW%6   ^| Tracert до клиента%COLOR_RESET%
echo:  %COLOR_YELLOW%7   ^| Открыть Computer Management%COLOR_RESET%
echo:  %COLOR_YELLOW%8   ^| Открыть удаленный cmd через WinRS%COLOR_RESET%
echo:  %COLOR_YELLOW%G   ^| Запустить gpupdate /force через WinRS%COLOR_RESET%
echo:  %COLOR_YELLOW%C   ^| Скопировать имя ПК%COLOR_RESET%
echo:  %COLOR_YELLOW%I   ^| Скопировать IP-адрес%COLOR_RESET%
echo:  %COLOR_YELLOW%F   ^| Добавить/убрать избранное%COLOR_RESET%
echo:
echo:  %COLOR_YELLOW%9   ^| Вернуться к списку клиентов%COLOR_RESET%
echo:  %COLOR_YELLOW%0   ^| Выйти%COLOR_RESET%
echo:

set "action="
set /p action="Выберите действие: " || exit /b 0
if not defined action goto toolkit_menu

if "%action%"=="1" (
    call :open_remote_assistance
    goto after_action
)
if "%action%"=="2" (
    call :ping_client
    goto after_action
)
if "%action%"=="3" (
    call :open_admin_share
    goto after_action
)
if "%action%"=="4" (
    call :open_event_viewer
    goto after_action
)
if "%action%"=="5" (
    call :open_mstsc
    goto after_action
)
if "%action%"=="6" (
    call :run_tracert
    goto after_action
)
if "%action%"=="7" (
    call :open_computer_management
    goto after_action
)
if "%action%"=="8" (
    call :open_remote_cmd_winrs
    goto after_action
)
if /i "%action%"=="G" (
    call :run_gpupdate_winrs
    goto after_action
)
if /i "%action%"=="C" (
    call :copy_computer
    goto after_action
)
if /i "%action%"=="I" (
    call :copy_ip
    goto after_action
)
if /i "%action%"=="F" (
    call :toggle_favorite
    goto after_action
)
if "%action%"=="9" goto client_list
if "%action%"=="0" exit /b 0

echo:
echo %COLOR_RED%Неизвестное действие.%COLOR_RESET%
timeout /t 2 >nul
goto toolkit_menu

:after_action
echo:
echo: _______________________________________________________________________________
echo:
echo:  %COLOR_YELLOW%1   ^| Выполнить другое действие с этим клиентом%COLOR_RESET%
echo:  %COLOR_YELLOW%2   ^| Вернуться к списку клиентов%COLOR_RESET%
echo:  %COLOR_YELLOW%0   ^| Выйти%COLOR_RESET%
echo:

set "next="
set /p next="Выберите действие: " || exit /b 0
if "%next%"=="1" goto toolkit_menu
if "%next%"=="2" goto client_list
if "%next%"=="0" exit /b 0
goto after_action

:find_clients_file
if exist "%TOOLKIT_CLIENTS_FILE%" (
    set "CLIENTS_FILE=%TOOLKIT_CLIENTS_FILE%"
    exit /b 0
)

if exist "%REMOTE_ASSISTANT_CLIENTS_FILE%" (
    set "CLIENTS_FILE=%REMOTE_ASSISTANT_CLIENTS_FILE%"
    exit /b 0
)

set "CLIENTS_FILE="
exit /b 0

:print_header
echo:
echo:                       %COLOR_GREEN%Quick Remote Toolkit%COLOR_RESET%
echo: _______________________________________________________________________________
echo:
if "%SHOW_FAVORITES%"=="1" echo:  Режим: %COLOR_YELLOW%только избранные%COLOR_RESET%
echo:   №  ^| Имя компьютера    ^| IP-адрес        ^| Имя сотрудника
echo:  --- ^| ----------------- ^| --------------- ^| ---------------------
exit /b 0

:print_client_footer
echo:
echo: _______________________________________________________________________________
echo:
echo:  Файл клиентов: %COLOR_MILK%%CLIENTS_FILE%%COLOR_RESET%
echo:
echo:  %COLOR_YELLOW%R   ^| Открыть последнего выбранного клиента%COLOR_RESET%
echo:  %COLOR_YELLOW%S   ^| Обновить список из Active Directory%COLOR_RESET%
echo:  %COLOR_YELLOW%F   ^| Переключить избранное/все клиенты%COLOR_RESET%
echo:  %COLOR_YELLOW%E   ^| Редактировать CSV в Блокноте%COLOR_RESET%
echo:  %COLOR_YELLOW%L   ^| Перечитать CSV%COLOR_RESET%
echo:  %COLOR_YELLOW%0   ^| Выйти%COLOR_RESET%
echo:
exit /b 0

:print_row
set "row_num=%~1"
set "row_computer=%~2"
set "row_ip=%~3"
set "row_person=%~4"

set "row_num=   %row_num%"
set "row_computer=%row_computer%                 "
set "row_ip=%row_ip%               "
set "row_person=%row_person%                     "

echo:  !row_num:~-3! ^| !row_computer:~0,17! ^| !row_ip:~0,15! ^| !row_person:~0,21!
exit /b 0

:print_selected
call :is_favorite "!computer!"
set "favorite_status=нет"
if "!IS_FAVORITE!"=="1" set "favorite_status=да"
echo:
echo:                       %COLOR_GREEN%Quick Remote Toolkit%COLOR_RESET%
echo: _______________________________________________________________________________
echo:
echo:  Клиент:      %COLOR_MILK%!computer!%COLOR_RESET%
echo:  IP-адрес:    %COLOR_MILK%!ip!%COLOR_RESET%
echo:  Сотрудник:   %COLOR_MILK%!person!%COLOR_RESET%
echo:  Избранное:   %COLOR_MILK%!favorite_status!%COLOR_RESET%
echo:
echo: _______________________________________________________________________________
exit /b 0

:load_clients
for /f "usebackq skip=1 tokens=1-4 delims=;" %%A in ("%CLIENTS_FILE%") do (
    if not "%%~A"=="" (
        set "CLIENT_%%A=%%B"
        set "IP_%%A=%%C"
        set "PERSON_%%A=%%D"
    )
)
exit /b 0

:set_selected
set "selected=%~1"
set "computer=!CLIENT_%selected%!"
set "ip=!IP_%selected%!"
set "person=!PERSON_%selected%!"
set "target=!ip!"
if "!target!"=="-" set "target=!computer!"
if not defined target set "target=!computer!"
exit /b 0

:sync_clients_from_ad
echo:
if not exist "%SYNC_SCRIPT%" (
    echo %COLOR_RED%Не найден скрипт синхронизации:%COLOR_RESET%
    echo "%SYNC_SCRIPT%"
    pause
    exit /b 1
)

echo %COLOR_MILK%Запускаю синхронизацию клиентов из Active Directory...%COLOR_RESET%
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SYNC_SCRIPT%" -OutputPath "%TOOLKIT_CLIENTS_FILE%"
if errorlevel 1 (
    echo:
    echo %COLOR_RED%Синхронизация завершилась с ошибкой.%COLOR_RESET%
) else (
    echo:
    echo %COLOR_GREEN%Список клиентов обновлен:%COLOR_RESET% "%TOOLKIT_CLIENTS_FILE%"
)
echo:
pause
exit /b 0

:log_action
set "log_text=%~1"
>> "%LOG_FILE%" echo [%date% %time%] !log_text! ^| !computer! ^| !target! ^| !person!
exit /b 0

:is_favorite
set "favorite_check=%~1"
set "IS_FAVORITE=0"
if not exist "%FAVORITES_FILE%" exit /b 0
for /f "usebackq delims=" %%F in ("%FAVORITES_FILE%") do (
    if /i "%%~F"=="!favorite_check!" set "IS_FAVORITE=1"
)
exit /b 0

:toggle_favorite
call :is_favorite "!computer!"
if "!IS_FAVORITE!"=="1" (
    call :remove_favorite
    echo:
    echo %COLOR_MILK%!computer!%COLOR_RESET% убран из избранного.
    call :log_action "Remove favorite"
) else (
    >> "%FAVORITES_FILE%" echo !computer!
    echo:
    echo %COLOR_MILK%!computer!%COLOR_RESET% добавлен в избранное.
    call :log_action "Add favorite"
)
exit /b 0

:remove_favorite
set "tmp_favorites=%TEMP%\QuickRemoteToolkit.favorites.%RANDOM%.tmp"
if exist "%tmp_favorites%" del "%tmp_favorites%" >nul 2>nul
if exist "%FAVORITES_FILE%" (
    for /f "usebackq delims=" %%F in ("%FAVORITES_FILE%") do (
        if /i not "%%~F"=="!computer!" >> "%tmp_favorites%" echo %%~F
    )
)
if exist "%tmp_favorites%" (
    move /y "%tmp_favorites%" "%FAVORITES_FILE%" >nul
) else (
    if exist "%FAVORITES_FILE%" del "%FAVORITES_FILE%" >nul 2>nul
)
exit /b 0

:copy_text
set "copy_value=%~1"
<nul set /p "=%copy_value%" | clip
exit /b 0

:copy_computer
call :copy_text "!computer!"
echo:
echo Скопировано имя ПК: %COLOR_MILK%!computer!%COLOR_RESET%
call :log_action "Copy computer name"
exit /b 0

:copy_ip
call :copy_text "!target!"
echo:
echo Скопирован IP/адрес: %COLOR_MILK%!target!%COLOR_RESET%
call :log_action "Copy IP"
exit /b 0

:open_remote_assistance
echo:
echo %COLOR_MILK%Запускаю Remote Assistance:%COLOR_RESET% !computer!
start "" msra.exe /offerra "!computer!"
call :log_action "Open Remote Assistance"
exit /b 0

:ping_client
echo:
echo Проверяю доступность: !computer!  !target!  !person!
ping -n 1 -w 1000 "!target!" >nul

if errorlevel 1 (
    echo %COLOR_RED%Не отвечает.%COLOR_RESET%
    call :log_action "Ping failed"
) else (
    echo %COLOR_GREEN%Доступен.%COLOR_RESET%
    call :log_action "Ping ok"
)
exit /b 0

:open_admin_share
echo:
echo %COLOR_MILK%Открываю административную шару:%COLOR_RESET% \\!computer!\c$
start "" "\\!computer!\c$"
call :log_action "Open admin share"
exit /b 0

:open_event_viewer
echo:
echo %COLOR_MILK%Открываю Event Viewer:%COLOR_RESET% !computer!
start "" eventvwr.msc /computer:!computer!
call :log_action "Open Event Viewer"
exit /b 0

:open_mstsc
echo:
echo %COLOR_MILK%Запускаю mstsc:%COLOR_RESET% !computer!
start "" mstsc.exe /v:!computer!
call :log_action "Open mstsc"
exit /b 0

:run_tracert
echo:
echo %COLOR_MILK%Запускаю tracert:%COLOR_RESET% !target!
start "Tracert !computer!" "%ComSpec%" /d /c "tracert !target! & echo. & pause"
call :log_action "Run tracert"
exit /b 0

:open_computer_management
echo:
echo %COLOR_MILK%Открываю Computer Management:%COLOR_RESET% !computer!
start "" compmgmt.msc /computer:\\!computer!
call :log_action "Open Computer Management"
exit /b 0

:open_remote_cmd_winrs
echo:
echo %COLOR_MILK%Открываю удаленный cmd через WinRS:%COLOR_RESET% !computer!
echo Для работы на удаленном ПК должен быть включен WinRM.
start "WinRS !computer!" "%ComSpec%" /d /k "winrs -r:!computer! cmd"
call :log_action "Open remote cmd WinRS"
exit /b 0

:run_gpupdate_winrs
echo:
echo %COLOR_MILK%Запускаю gpupdate /force через WinRS:%COLOR_RESET% !computer!
echo Для работы на удаленном ПК должен быть включен WinRM.
start "gpupdate !computer!" "%ComSpec%" /d /c "winrs -r:!computer! gpupdate /force & echo. & pause"
call :log_action "Run gpupdate WinRS"
exit /b 0
