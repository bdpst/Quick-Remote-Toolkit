@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul

set "TOOLKIT_CLIENTS_FILE=%~dp0QuickRemoteToolkit.clients.csv"
set "REMOTE_ASSISTANT_CLIENTS_FILE=%~dp0RemoteAssistant.clients.csv"
set "CLIENTS_FILE="
set "LAST_CHOICE="

set "COLOR_GREEN=[32m"
set "COLOR_RED=[31m"
set "COLOR_MILK=[97m"
set "COLOR_YELLOW=[33m"
set "COLOR_RESET=[0m"

call :find_clients_file
if not defined CLIENTS_FILE (
    echo %COLOR_RED%Не найден файл со списком клиентов.%COLOR_RESET%
    echo:
    echo Создайте рядом со скриптом один из файлов:
    echo   QuickRemoteToolkit.clients.csv
    echo   RemoteAssistant.clients.csv
    echo:
    echo Можно скопировать QuickRemoteToolkit.clients.example.csv и заполнить его своими данными.
    pause
    exit /b 1
)

:client_list
call :find_clients_file
call :load_clients
cls
call :print_header

set "shown=0"
for /f "usebackq skip=1 tokens=1-4 delims=;" %%A in ("%CLIENTS_FILE%") do (
    if not "%%~A"=="" (
        call :print_row "%%A" "%%B" "%%C" "%%D"
        set /a shown+=1
    )
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
echo:
echo:                       %COLOR_GREEN%Quick Remote Toolkit%COLOR_RESET%
echo: _______________________________________________________________________________
echo:
echo:  Клиент:      %COLOR_MILK%!computer!%COLOR_RESET%
echo:  IP-адрес:    %COLOR_MILK%!ip!%COLOR_RESET%
echo:  Сотрудник:   %COLOR_MILK%!person!%COLOR_RESET%
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

:open_remote_assistance
echo:
echo %COLOR_MILK%Запускаю Remote Assistance:%COLOR_RESET% !computer!
start "" msra.exe /offerra "!computer!"
exit /b 0

:ping_client
echo:
echo Проверяю доступность: !computer!  !target!  !person!
ping -n 1 -w 1000 "!target!" >nul

if errorlevel 1 (
    echo %COLOR_RED%Не отвечает.%COLOR_RESET%
) else (
    echo %COLOR_GREEN%Доступен.%COLOR_RESET%
)
exit /b 0

:open_admin_share
echo:
echo %COLOR_MILK%Открываю административную шару:%COLOR_RESET% \\!computer!\c$
start "" "\\!computer!\c$"
exit /b 0

:open_event_viewer
echo:
echo %COLOR_MILK%Открываю Event Viewer:%COLOR_RESET% !computer!
start "" eventvwr.msc /computer:!computer!
exit /b 0

:open_mstsc
echo:
echo %COLOR_MILK%Запускаю mstsc:%COLOR_RESET% !computer!
start "" mstsc.exe /v:!computer!
exit /b 0
