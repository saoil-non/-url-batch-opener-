@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

:: 切换到脚本所在目录
cd /d "%~dp0"

echo 开始批量打开网址...
echo.

if not exist "urls.txt" (
    echo 错误：找不到 urls.txt 文件
    pause
    exit /b 1
)

:: 用 PowerShell 先读文件，批处理再逐行接收
:: 这样可兼容带/不带 BOM 的 UTF-8 文件
set /a total=0
for /f "usebackq delims=" %%u in (`powershell -NoLogo -NoProfile -Command "Get-Content 'urls.txt' -Encoding UTF8"`) do (
    set /a total+=1
    set "url[!total!]=%%u"
)

if %total%==0 (
    echo urls.txt 中没有读取到任何网址
    pause
    exit /b 1
)

:: 计算组数
set /a groups=(total+14)/15

echo 共有 %total% 个网址，分为 %groups% 组（每组15个）
echo.

:getGroup
set /p groupNum=请输入要打开的组号（1-%groups%）：

:: 简单校验
echo %groupNum%|findstr /r "^[1-9][0-9]*$" >nul || (
    echo 请输入有效数字！
    goto :getGroup
)

if %groupNum% lss 1 (
    echo 组号必须大于等于1
    goto :getGroup
)
if %groupNum% gtr %groups% (
    echo 组号不能超过最大组数 %groups%
    goto :getGroup
)

:: 计算起止索引
set /a start=(groupNum-1)*15+1
set /a end=start+14
if %end% gtr %total% set end=%total%

echo 正在打开第 %groupNum% 组（第 %start% 到 %end% 个网址）...
echo.

for /l %%i in (%start%,1,%end%) do (
    powershell -Command "Start-Process '!url[%%i]!' -ErrorAction SilentlyContinue; Start-Sleep -Milliseconds 500"
)

echo.
echo 第 %groupNum% 组网址已打开完成

:askNext
if %groupNum%==%groups% (
    echo 已经是最后一组，按任意键退出...
    pause
    goto :eof
)

set /p "continue=是否继续打开下一组（回车=是，n=否）？ "
if /i "!continue!"=="n" (
    echo 已退出
    pause
    goto :eof
)

:: 更新组号并打开下一组
set /a groupNum+=1
set /a start=(groupNum-1)*15+1
set /a end=start+14
if %end% gtr %total% set end=%total%

echo.
echo 正在打开第 %groupNum% 组（第 %start% 到 %end% 个网址）...
echo.

for /l %%i in (%start%,1,%end%) do (
    powershell -Command "Start-Process '!url[%%i]!' -ErrorAction SilentlyContinue; Start-Sleep -Milliseconds 500"
)

goto :askNext