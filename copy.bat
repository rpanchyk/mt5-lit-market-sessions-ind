@echo off
setlocal

@REM The script copies files from MT

@REM Read options file having format:
@REM DATA_DIR=C:\Users\[USER]\AppData\Roaming\MetaQuotes\Terminal\[TERMINAL_ID]
@REM To see the actual path go to main menu "File -> Open Data Folder" in MT.
set OPTIONS_FILE=copy_options.txt
if not exist %OPTIONS_FILE% echo Error: %OPTIONS_FILE% file not found && pause && exit 1
for /f "delims== tokens=1,2" %%G in (%OPTIONS_FILE%) do set %%G=%%H

@REM Settings
::set INCLUDE_DIR=MQL5\Include
::set EXPERTS_DIR=MQL5\Experts
set INDICATORS_DIR=MQL5\Indicators

@REM Create local dirs if absent
::if not exist "%INCLUDE_DIR%" mkdir "%INCLUDE_DIR%"
::if not exist "%EXPERTS_DIR%" mkdir "%EXPERTS_DIR%"
if not exist "%INDICATORS_DIR%" mkdir "%INDICATORS_DIR%"

@REM Copy files to local repository
::if exist "%DATA_DIR%\%INCLUDE_DIR%\My_LIB.mqh" copy /Y "%DATA_DIR%\%INCLUDE_DIR%\My_LIB.mqh" "%INCLUDE_DIR%"
::if exist "%DATA_DIR%\%EXPERTS_DIR%\My_EA.mq4" copy /Y "%DATA_DIR%\%EXPERTS_DIR%\My_EA.mq4" "%EXPERTS_DIR%"
if exist "%DATA_DIR%\%INDICATORS_DIR%\LitMarketSessions.mq5" copy /Y "%DATA_DIR%\%INDICATORS_DIR%\LitMarketSessions.mq5" "%INDICATORS_DIR%"

echo Successfully copied.
timeout /t 5
