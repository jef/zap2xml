@echo off
:loop
set DATESTR=%DATE% %TIME%
echo Running zap2xml.exe at %DATESTR%
zap2xml.exe %OPT_ARGS%
echo Last run time: %DATESTR%
echo Will run again in %SLEEPTIME% seconds
REM Default sleep time if not set
if "%SLEEPTIME%"=="" set SLEEPTIME=43200
powershell -Command "Start-Sleep -Seconds %SLEEPTIME%"
goto loop
