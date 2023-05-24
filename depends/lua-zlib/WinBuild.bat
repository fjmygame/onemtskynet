@echo off

call %~dp0..\..\..\WinBuildRules.bat
call %~dp0..\windep_libs\EnvInit.bat

set LIB=%LIB%;%LUA53_PATH%lib;%ZLIB_PATH%lib
set INCLUDE=%INCLUDE%;%LUA53_PATH%include;%ZLIB_PATH%include

del /Q *.obj
%WINBUILD% /Dluaopen_zlib="__declspec(dllexport) luaopen_zlib" lua_zlib.c
%WINLINK% /out:zlib.dll lua_zlib.obj libz.lib lua53.lib

