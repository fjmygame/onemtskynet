@echo off

call %~dp0..\..\..\WinBuildRules.bat
call %~dp0..\windep_libs\EnvInit.bat

set LIB=%LIB%;%LUA53_PATH%lib
set INCLUDE=%INCLUDE%;%LUA53_PATH%include;%ZLIB_PATH%include

del /Q *.obj
%WINBUILD% /Dluaopen_skiplist_c="__declspec(dllexport) luaopen_skiplist_c" skiplist.c lua-skiplist.c
%WINLINK% /out:skiplist.dll skiplist.obj lua-skiplist.obj lua53.lib

