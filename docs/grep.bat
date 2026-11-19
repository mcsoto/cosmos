@echo off
rem grep.bat - recursive text search for Windows, built on findstr.
rem
rem   grep.bat <pattern>            search every file under the current directory
rem   grep.bat <pattern> <path>     search every file under <path>
rem   grep.bat -i <pattern> [path]  ignore case
rem
rem This is `grep <pattern> * -r`: it walks the tree, skips binary files and
rem prints path:line:text.  The exit code is grep's - 0 when something matched,
rem 1 when nothing did, 2 on error - so it composes with && and ||.
rem
rem <pattern> is a findstr regular expression.  A pattern containing a space is
rem matched literally instead, because findstr would otherwise split it into
rem separate words and match any one of them.  findstr has no alternation.

setlocal EnableExtensions

set "CASE="
if /i "%~1"=="-i" (
  set "CASE=/i"
  shift
)

if "%~1"=="" goto :usage

set "PATTERN=%~1"
set "ROOT=%~2"
if not defined ROOT set "ROOT=."

rem Bare * keeps the printed paths relative; a named root keeps its prefix.
if "%ROOT%"=="." (
  set "TARGET=*"
) else if exist "%ROOT%\*" (
  set "TARGET=%ROOT%\*"
) else if exist "%ROOT%" (
  set "TARGET=%ROOT%"
) else (
  echo grep.bat: no such file or directory: %ROOT% 1>&2
  endlocal & exit /b 2
)

rem /s recurse  /n line numbers  /p skip binary  /r regex  /c one literal string
if "%PATTERN%"=="%PATTERN: =%" (
  findstr /s /n /p /r %CASE% "%PATTERN%" "%TARGET%"
) else (
  findstr /s /n /p /r %CASE% /c:"%PATTERN%" "%TARGET%"
)
set "CODE=%ERRORLEVEL%"

endlocal & exit /b %CODE%

:usage
echo usage: grep.bat [-i] ^<pattern^> [path] 1>&2
echo. 1>&2
echo   -i        ignore case 1>&2
echo   pattern   findstr regular expression 1>&2
echo   path      file or directory to search (default: .) 1>&2
endlocal & exit /b 2
