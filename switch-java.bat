chcp 65001 >nul
@echo off
chcp 65001 >nul 2>&1
setlocal enabledelayedexpansion

REM Định nghĩa file log
set "LOG_FILE=%~dp0java_switcher_log.txt"
if exist "%LOG_FILE%" del "%LOG_FILE%"

REM Kiểm tra quyền Administrator
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if %errorlevel% NEQ 0 (
    color 0C
    echo Lỗi: Cần quyền Administrator để chạy script này.
    echo Vui lòng chạy lại với quyền Administrator.
    pause
    exit /b 1
)

REM Khởi tạo biến
set "count=0"
for /f "tokens=*" %%D in ('dir /b /ad "C:\Program Files\Java\jdk*"') do (
    set "folder=%%D"
    set "version=!folder:jdk=!"
    set /a "count+=1"
    set "AVAILABLE_VERSIONS[!count!]=!version!"
    set "JAVA_FOLDERS[!count!]=!folder!"
)

if %count% equ 0 (
    color 0C
    echo Không tìm thấy phiên bản Java nào.
    echo Kiểm tra lại thư mục cài đặt Java.
    pause
    exit /b 1
)

:menu
cls
color 0B

REM Sử dụng ký tự khung Unicode
echo ╔══════════════════════════════════════════════╗
echo ║          JAVA VERSION SWITCHER 1.0           ║
echo ╠══════════════════════════════════════════════╣
echo ║ Các phiên bản Java hiện có:                 ║
echo ╠══════════════════════════════════════════════╣

for /L %%i in (1,1,%count%) do (
    set "version=!AVAILABLE_VERSIONS[%%i]!"
    call :PadRight "%%i. Java !version!" 46 paddedText
    echo ║ !paddedText! ║
)

echo ╠══════════════════════════════════════════════╣
echo ║ 0. Thoát                                     ║
echo ╚══════════════════════════════════════════════╝
echo.
set /p choice="Chọn hoặc nhập phiên bản (0-%count%): "

set "selectedVersion="
for /L %%i in (1,1,%count%) do (
    if "!choice!"=="!AVAILABLE_VERSIONS[%%i]!" (
        set "selectedVersion=!AVAILABLE_VERSIONS[%%i]!"
        set "selectedFolder=!JAVA_FOLDERS[%%i]!"
    ) else if "!choice!"=="%%i" (
        set "selectedVersion=!AVAILABLE_VERSIONS[%%i]!"
        set "selectedFolder=!JAVA_FOLDERS[%%i]!"
    )
)

if defined selectedVersion (
    set "FULL_JAVA_PATH=C:\Program Files\Java\!selectedFolder!"

    if not exist "!FULL_JAVA_PATH!\bin\java.exe" (
        color 0C
        echo Lỗi: Không tìm thấy Java tại !FULL_JAVA_PATH!
        echo Vui lòng kiểm tra lại cài đặt Java.
        pause
        goto menu
    )

    REM Cập nhật JAVA_HOME và PATH
    reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v JAVA_HOME /t REG_SZ /d "!FULL_JAVA_PATH!" /f >nul

    REM Loại bỏ đường dẫn Java cũ khỏi PATH
    for /f "tokens=2*" %%A in ('reg query "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v Path') do set "SysPath=%%B"
    set "NewPath="
    for %%P in ("!SysPath:;=";"!") do (
        echo %%~P | find /I "Java" >nul
        if errorlevel 1 (
            set "NewPath=!NewPath!;%%~P"
        )
    )
    set "NewPath=!JAVA_HOME!\bin!NewPath!"
    reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v Path /t REG_EXPAND_SZ /d "!NewPath!" /f >nul

    REM Thêm hiệu ứng chuyển màu
    color 0A
    mode con cols=50 lines=20
    cls
    echo Đang chuyển đổi phiên bản Java...
    timeout /t 1 >nul
    cls

    echo ╔══════════════════════════════════════════════╗
    echo ║       THAY ĐỔI PHIÊN BẢN THÀNH CÔNG         ║
    echo ╠══════════════════════════════════════════════╣
    call :PadRight "Phiên bản Java mới: !selectedVersion!" 46 paddedText
    echo ║ !paddedText! ║
    call :PadRight "Đường dẫn: !FULL_JAVA_PATH!" 46 paddedText
    echo ║ !paddedText! ║
    echo ╚══════════════════════════════════════════════╝

    "!FULL_JAVA_PATH!\bin\java.exe" -version
    echo.
    echo Kiểm tra log tại %LOG_FILE% nếu có lỗi.
    pause
) else if "%choice%"=="0" (
    exit /b 0
) else (
    color 0C
    echo [CẢNH BÁO] Lựa chọn không hợp lệ!
    pause
    goto menu
)
goto menu

REM Hàm căn chỉnh văn bản
:PadRight
setlocal EnableDelayedExpansion
set "str=%~1"
set "len=%~2"
set "padStr=%str%"
for /L %%i in (1,1,%len%) do if "!padStr:~%%i,1!"=="" set "padStr=!padStr! "
endlocal & set "%~3=%padStr%"
goto :eof
