/*
 * Create Date:2023-03-24 17:02:26
 * Author  : Happy Su
 * Version : 1.0
 * Filename: hloggerlib.c
 * Introduce  : 类介绍
 */

#include "lua.h"
#include "lauxlib.h"
#include "../hlogger/hlogger.h"
#include "skynet.h"
#include "skynet_handle.h"
#include "skynet_mq.h"
#include "skynet_server.h"

#include <stdarg.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

void 
send_logger(struct skynet_context * context, int type, const char *msg, size_t len) {
	static uint32_t logger = 0;
	if (logger == 0) {
		logger = skynet_handle_findname("logger");
	}
	if (logger == 0) {
		return;
	}
	
	char * data = skynet_malloc(len);
	memcpy(data, msg, len);

	struct skynet_message smsg;
	if (context == NULL) {
		smsg.source = 0;
	} else {
		smsg.source = skynet_context_handle(context);
	}
	smsg.session = 0;
	smsg.data = data;
	smsg.sz = len | ((size_t)type << MESSAGE_TYPE_SHIFT);
	skynet_context_push(logger, &smsg);
}

int
ljoinargs(lua_State *L) {
	int n = lua_gettop(L);
	if (n <= 1) {
		return 1;
	}
	luaL_Buffer b;
	luaL_buffinit(L, &b);
	int i;
	for (i=1; i<=n; i++) {
		luaL_tolstring(L, i, NULL);
		luaL_addvalue(&b);
		if (i<n) {
			luaL_addchar(&b, ' ');
		}
	}
	luaL_pushresult(&b);
	return 1;
}

int
lerror(lua_State *L) {
	ljoinargs(L);
	size_t len;
	const char* msg = lua_tolstring(L, -1, &len);
	lua_getfield(L, LUA_REGISTRYINDEX, "skynet_context");
	struct skynet_context *context = lua_touserdata(L,-1);
	send_logger(context, PTYPE_LOG_ERROR, msg, len);
	return 0;
}

int
lwarn(lua_State *L) {
	ljoinargs(L);
	size_t len;
	const char* msg = lua_tolstring(L, -1, &len);
	lua_getfield(L, LUA_REGISTRYINDEX, "skynet_context");
	struct skynet_context *context = lua_touserdata(L,-1);
	send_logger(context, PTYPE_LOG_WARN, msg, len);
	return 0;
}

LUAMOD_API int
luaopen_hloggerlib(lua_State *L) {
	luaL_checkversion(L);

	luaL_Reg l[] = {
		{ "joinargs", ljoinargs },
		{ "error", lerror },
		{ "warn", lwarn },
		{ NULL, NULL },
	};
    luaL_newlib(L,l);
    return 1;
}
