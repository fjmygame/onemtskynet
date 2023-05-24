@echo off

call %~dp0..\..\..\WinBuildRules.bat
call %~dp0..\windep_libs\EnvInit.bat

set LIB=%LIB%;%LUA53_PATH%lib;%LIBCURL_PATH%lib
set INCLUDE=%INCLUDE%;%LUA53_PATH%include;%LIBCURL_PATH%include

del /Q *.obj
%WINBUILD% /Dluaopen_luacurl="__declspec(dllexport) luaopen_luacurl" luacurl.c multi.c constants.c
%WINLINK% /out:luacurl.dll luacurl.obj multi.obj constants.obj lua53.lib libcurl.lib ws2_32.lib

