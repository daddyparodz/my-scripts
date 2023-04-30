@echo off
setlocal enabledelayedexpansion


set /p source_folder="source folder path: "

for %%a in ("%source_folder%\*.jpg" "%source_folder%\*.mp4" "%source_folder%\*.dng") do (
    for /f "usebackq tokens=1-3 delims=: " %%b in (`exiftool -s -s -s -CreateDate "%%a"`) do (
        set "year=%%b"
        set "month=%%c"
        set "day=%%d"
    )

    if !month!==01 set "month_name=January"
    if !month!==02 set "month_name=February"
    if !month!==03 set "month_name=March"
    if !month!==04 set "month_name=April"
    if !month!==05 set "month_name=May"
    if !month!==06 set "month_name=June"
    if !month!==07 set "month_name=July"
    if !month!==08 set "month_name=August"
    if !month!==09 set "month_name=September"
    if !month!==10 set "month_name=October"
    if !month!==11 set "month_name=November"
    if !month!==12 set "month_name=December"

    set "target_path=!year!\!month! !month_name!\!day!-!month!-!year!"
    if not exist "%source_folder%\!target_path!" md "%source_folder%\!target_path!"
    echo Moving %%~nxa to %source_folder%\!target_path!
    move /y "%%a" "%source_folder%\!target_path!"
)
pause