/*
 * Create Date:2023-03-21 08:52:22
 * Author  : Happy Su
 * Version : 1.0
 * Filename: luacfg.c
 * Introduce  : 一个C库，读取配置文件
 */

#include <stdio.h>
#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>
#include <pthread.h>

static pthread_mutex_t config_lock = PTHREAD_MUTEX_INITIALIZER;
static lua_State* config_L = NULL;
static int initTag = 0;
static const char *config_file = NULL;


int close_lua_state(lua_State* L) {
    if (L) {
        lua_close(L);
    }
    return 0;
}

static int
_init_path_to_global(lua_State *L) {
	lua_pushnil(L);  /* first key */
	while (lua_next(L, -2) != 0) {
		int keyt = lua_type(L, -2);
		if (keyt != LUA_TSTRING) {
			fprintf(stderr, "Invalid config table\n");
			return 0;
		}
		const char * key = lua_tostring(L,-2);
        // const char * value = lua_tostring(L,-1);
        // printf("key:%s value:%s\n", key, value);
        lua_setglobal(L, key);
	}
	lua_pop(L,1);
    return 1;
}

int load_config(const char* file_path) {
    // pthread_mutex_lock(&config_lock);
    printf("load config file: %s\n", file_path);

    lua_State* new_config_L = luaL_newstate();
    if (!new_config_L) {
        fprintf(stderr, "create config_L faild\n");
        // pthread_mutex_unlock(&config_lock);
        return 0;
    }
    luaL_openlibs(new_config_L);

    // 使用io库打开文件并读取内容，这样可以绕过coddecache，否则重载配置还要清理缓存
    lua_pushfstring(new_config_L, "file = io.open(\"%s\", \"r\")\n"
                        "content = file:read(\"*all\")\n"
                        "file:close()\n"
                        "return content\n", file_path);
    if (luaL_dostring(new_config_L, lua_tostring(new_config_L, -1)) != LUA_OK) {
        printf("Error opening file: %s\n", lua_tostring(new_config_L, -1));
        lua_close(new_config_L);
        return 0;
    }

    // 在状态中运行读取的内容
    if (luaL_dostring(new_config_L, lua_tostring(new_config_L, -1)) != LUA_OK) {
        printf("Error running Lua file: %s\n", lua_tostring(new_config_L, -1));
        lua_close(new_config_L);
        return 0;
    }
    
    // if (luaL_loadfile(new_config_L, file_path) || lua_pcall(new_config_L, 0, 1, 0)) {
    //     fprintf(stderr, "loadfile file:%s faild\n", file_path);
    //     lua_close(new_config_L);
    //     new_config_L = NULL;
    //     // pthread_mutex_unlock(&config_lock);
    //     return 0;
    // }

    
    if (!lua_istable(new_config_L, -1)) {
        fprintf(stderr, "file return is not table\n");
        lua_close(new_config_L);
        new_config_L = NULL;
        // pthread_mutex_unlock(&config_lock);
        return 0;
    }

    // table转全局变量
    if (!_init_path_to_global(new_config_L)) {
        fprintf(stderr, "_init_path_to_global faild\n");
        lua_close(new_config_L);
        new_config_L = NULL;
        // pthread_mutex_unlock(&config_lock);
        return 0;
    }
    
    // 先暂存老配置
    lua_State* old_config_L = config_L;
    config_L = new_config_L;
    // 如果有老的，关闭老的
    close_lua_state(old_config_L);

    // pthread_mutex_unlock(&config_lock);

    return 1;
}

static int l_config_init(lua_State *L) {
    const char* service_name = luaL_checkstring(L, 1);
    printf("luacfg init service:%s initTag:%d\n", service_name, initTag);

    int load_ret = 0;
    pthread_mutex_lock(&config_lock);
    if (initTag) {
        printf("luacfg had init service:%s\n", service_name);
        pthread_mutex_unlock(&config_lock);
        return 0;
    }

    const char* file_path = luaL_checkstring(L, 2);
    if (!file_path) {
        fprintf(stderr, "file_path is nil\n");
        pthread_mutex_unlock(&config_lock);
        return 0;
    }

    printf("start load cfg file_path: %s\n", file_path);

    config_file = file_path;    

    if (load_config(file_path)) {
        lua_pushboolean(L, 1);
    } else {
        lua_pushboolean(L, 0);
    }

    initTag = 1;
    printf("luacfg init success service:%s\n", service_name);
    pthread_mutex_unlock(&config_lock);

    return 1;
}

int l_config_reload(lua_State* L) {
    if (!L || !config_file) {
        fprintf(stderr, "Config file not loaded\n");
        return 0;
    }

    pthread_mutex_lock(&config_lock);
    if (load_config(config_file)) {
        lua_pushboolean(L, 1);
    } else {
        lua_pushboolean(L, 0);
    }
    pthread_mutex_unlock(&config_lock);
    
    printf("l_config_init initTag tag2:%d\n", initTag);

    
    return 1;
}

const char* get_config_value(const char* key) {    
    if (!config_L) {
        return 0;
    }

    lua_getglobal(config_L, key);
    const char* value = NULL;
    if (lua_isstring(config_L, -1)) {
        value = lua_tostring(config_L, -1);
    }
    lua_pop(config_L, 1);
    return value;
}

static int l_config_get(lua_State *L) {
    const char *key = luaL_checkstring(L, 1);
    pthread_mutex_lock(&config_lock);
    const char *value = get_config_value(key);
    if (value) {
        lua_pushstring(L, value);
        pthread_mutex_unlock(&config_lock);
        return 1;
    } else {
        pthread_mutex_unlock(&config_lock);
        return 0;
    }
}

int luaopen_luacfg(lua_State* L) {    
    luaL_checkversion(L);
    luaL_Reg config_lib[] = {
        { "init", l_config_init },
        { "reload", l_config_reload },
        { "get", l_config_get },
        { NULL, NULL }
    };
    luaL_newlib(L, config_lib);
    return 1;
}
