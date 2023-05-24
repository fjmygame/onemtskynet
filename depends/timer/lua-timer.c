#include <stdio.h>
#include <stdlib.h>

#include "lua.h"
#include "lauxlib.h"
#include "timer.c"

static int
traceback(lua_State *L) {
	const char *msg = lua_tostring(L, 1);
	if (msg)
		luaL_traceback(L, L, msg, 1);
	else {
		lua_pushliteral(L, "(no error message)");
	}
	return 1;
}

static inline struct timer*
_to_timer(lua_State *L) {
    struct timer **TI = lua_touserdata(L, 1);
    if(TI==NULL) {
        luaL_error(L, "must be timer object");
    }
    return *TI;
}

static int
_new(lua_State *L) {
    struct timer *pTI = timer_init();
    struct timer **TI = (struct timer**)lua_newuserdata(L, sizeof(struct timer*));
    *TI = pTI;
    lua_pushvalue(L, lua_upvalueindex(1));
    lua_setmetatable(L, -2);
    return 1;
}

static int
_release(lua_State *L) {
    struct timer* TI = _to_timer(L);
    printf("collect timer:%p\n", TI);
    timer_free(TI);
    return 0;
}



static int
_add(lua_State *L) {
    struct timer* TI = _to_timer(L);
    int handle = luaL_checkinteger(L, -2);
    int ti = luaL_checkinteger(L, -1);
    timeout(TI, handle, ti);
    return 0;
}


static void cb(void * pL, const char* flag, int handle) {
    lua_State * L = (lua_State *)pL;
    lua_pushcfunction(L, traceback);
    lua_rawgetp(L, LUA_REGISTRYINDEX, flag);//get lua function
    lua_pushinteger(L, handle);
    int r = lua_pcall(L, 1, 0, -3);
    if (r == LUA_OK) {
        return;
    }
    else
    {
        printf("timer on timer cb error:%s\n", lua_tostring(L, -1));
    }
    lua_pop(L, 1);
    return;
}

static int
_set_on_timer_cb(lua_State *L)
{
	struct timer* TI = _to_timer(L);
	static const char* flag = "_set_on_timer_cb";
	luaL_checktype(L, -1, LUA_TFUNCTION);
	lua_rawsetp(L, LUA_REGISTRYINDEX, flag);// LUA_REGISTRYINDEX table[cb]=function

    set_on_timer(TI, &cb, (void *)L, flag);
    
	return 0;
}

static int 
_update(lua_State *L){
    struct timer* TI = _to_timer(L);
    updatetime(TI);
    return 0;
}

int luaopen_timer_c(lua_State *L) {
    luaL_checkversion(L);

    luaL_Reg l[] = {
        {"add", _add},
        {"set_on_timer_cb", _set_on_timer_cb},
        {"update", _update},
        {NULL, NULL}
    };

    lua_createtable(L, 0, 2);

    luaL_newlib(L, l);
    lua_setfield(L, -2, "__index");
    lua_pushcfunction(L, _release);
    lua_setfield(L, -2, "__gc");

    lua_pushcclosure(L, _new, 1);
    return 1;
}
