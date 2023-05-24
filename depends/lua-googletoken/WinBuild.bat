@echo off

call %~dp0..\..\..\WinBuildRules.bat
call %~dp0..\windep_libs\EnvInit.bat

set LIB=%LIB%;%LUA53_PATH%lib
set INCLUDE=%INCLUDE%;%LUA53_PATH%include

del /Q *.obj
%WINBUILD% /Dluaopen_googletoken="__declspec(dllexport) luaopen_googletoken" lua-googletoken.c
%WINLINK% /out:googletoken.dll lua-googletoken.obj lua53.lib

