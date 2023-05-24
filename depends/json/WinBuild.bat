@echo off

call %~dp0..\..\..\WinBuildRules.bat
call %~dp0..\windep_libs\EnvInit.bat

set LIB=%LIB%;%LUA53_PATH%lib
set INCLUDE=%INCLUDE%;%LUA53_PATH%include

del /Q *.obj
%WINBUILD% /Dluaopen_cjson="__declspec(dllexport) luaopen_cjson" /Dluaopen_cjson_safe="__declspec(dllexport) luaopen_cjson_safe" *.c
%WINLINK% /out:cjson.dll *.obj lua53.lib

