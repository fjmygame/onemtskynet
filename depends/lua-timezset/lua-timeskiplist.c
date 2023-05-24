/*
 *  author: xjdrew
 *  date: 2014-06-03 20:38
 */

#include <stdio.h>
#include <stdlib.h>

#include "lua.h"
#include "lauxlib.h"
#include "timeskiplist.h"

//add by hsx
#define luaL_checkunsigned(L, a) ((lua_Unsigned)luaL_checkinteger(L, a))
#define lua_pushunsigned(L, n) lua_pushinteger(L, (lua_Integer)(n))

static inline tskiplist *
_to_skiplist(lua_State *L)
{
    tskiplist **sl = lua_touserdata(L, 1);
    if (sl == NULL)
    {
        luaL_error(L, "must be tskiplist object");
    }
    return *sl;
}

static int
_insert(lua_State *L)
{
    tskiplist *sl = _to_skiplist(L);
    double score = luaL_checknumber(L, 2);
    luaL_checktype(L, 3, LUA_TSTRING);
    size_t len;
    const char *ptr = lua_tolstring(L, 3, &len);
    double timestamp = luaL_checknumber(L, 4);
    tslobj *obj = slCreateObj(ptr, len, timestamp);
    slInsert(sl, score, obj);
    return 0;
}

static int
_delete(lua_State *L)
{
    tskiplist *sl = _to_skiplist(L);
    double score = luaL_checknumber(L, 2);
    luaL_checktype(L, 3, LUA_TSTRING);
    tslobj obj;
    obj.ptr = (char *)lua_tolstring(L, 3, &obj.length);
    double timestamp = luaL_checknumber(L, 4);
    obj.timestamp = timestamp;
    lua_pushboolean(L, slDelete(sl, score, &obj));
    return 1;
}

static void
_delete_rank_cb(void *ud, tslobj *obj)
{
    lua_State *L = (lua_State *)ud;
    lua_pushvalue(L, 4);
    lua_pushlstring(L, obj->ptr, obj->length);
    lua_call(L, 1, 0);
}

static int
_delete_by_rank(lua_State *L)
{
    tskiplist *sl = _to_skiplist(L);
    unsigned int start = luaL_checkunsigned(L, 2);
    unsigned int end = luaL_checkunsigned(L, 3);
    luaL_checktype(L, 4, LUA_TFUNCTION);
    if (start > end)
    {
        unsigned int tmp = start;
        start = end;
        end = tmp;
    }

    lua_pushunsigned(L, slDeleteByRank(sl, start, end, _delete_rank_cb, L));
    return 1;
}

static int
_get_count(lua_State *L)
{
    tskiplist *sl = _to_skiplist(L);
    lua_pushunsigned(L, sl->length);
    return 1;
}

static int
_get_rank(lua_State *L)
{
    tskiplist *sl = _to_skiplist(L);
    double score = luaL_checknumber(L, 2);
    luaL_checktype(L, 3, LUA_TSTRING);
    tslobj obj;
    obj.ptr = (char *)lua_tolstring(L, 3, &obj.length);
    double timestamp = luaL_checknumber(L, 4);
    obj.timestamp = timestamp;

    unsigned long rank = slGetRank(sl, score, &obj);
    if (rank == 0)
    {
        return 0;
    }

    lua_pushunsigned(L, rank);

    return 1;
}

static int
_get_rank_range(lua_State *L)
{
    tskiplist *sl = _to_skiplist(L);
    unsigned long r1 = luaL_checkunsigned(L, 2);
    unsigned long r2 = luaL_checkunsigned(L, 3);
    int reverse, rangelen;
    if (r1 <= r2)
    {
        reverse = 0;
        rangelen = r2 - r1 + 1;
    }
    else
    {
        reverse = 1;
        rangelen = r1 - r2 + 1;
    }

    tskiplistNode *node = slGetNodeByRank(sl, r1);
    lua_createtable(L, rangelen, 0);
    int n = 0;
    while (node && n < rangelen)
    {
        n++;

        lua_pushlstring(L, node->obj->ptr, node->obj->length);
        lua_rawseti(L, -2, n);
        node = reverse ? node->backward : node->level[0].forward;
    }
    return 1;
}

static int
_get_score_range(lua_State *L)
{
    tskiplist *sl = _to_skiplist(L);
    double s1 = luaL_checknumber(L, 2);
    double s2 = luaL_checknumber(L, 3);
    int reverse;
    tskiplistNode *node;

    if (s1 <= s2)
    {
        reverse = 0;
        node = slFirstInRange(sl, s1, s2);
    }
    else
    {
        reverse = 1;
        node = slLastInRange(sl, s2, s1);
    }

    lua_newtable(L);
    int n = 0;
    while (node)
    {
        if (reverse)
        {
            if (node->score < s2)
                break;
        }
        else
        {
            if (node->score > s2)
                break;
        }
        n++;

        lua_pushlstring(L, node->obj->ptr, node->obj->length);
        lua_rawseti(L, -2, n);

        node = reverse ? node->backward : node->level[0].forward;
    }
    return 1;
}

static int
_dump(lua_State *L)
{
    tskiplist *sl = _to_skiplist(L);
    slDump(sl);
    return 0;
}

static void
_dump_rank_cb(void *ud, int index, double score, tslobj *obj)
{
    lua_State *L = (lua_State *)ud;
    lua_pushvalue(L, 2);
    lua_pushinteger(L, index);
    lua_pushnumber(L, score);
    lua_pushlstring(L, obj->ptr, obj->length);
    lua_pushnumber(L, obj->timestamp);
    lua_call(L, 4, 0);
}

static int
_dump_out(lua_State *L)
{
    tskiplist *sl = _to_skiplist(L);
    luaL_checktype(L, 2, LUA_TFUNCTION);
    slDumpOut(sl, _dump_rank_cb, L);
    return 0;
}

static int
_new(lua_State *L)
{
    tskiplist *psl = slCreate();

    tskiplist **sl = (tskiplist **)lua_newuserdata(L, sizeof(tskiplist *));
    *sl = psl;
    lua_pushvalue(L, lua_upvalueindex(1));
    lua_setmetatable(L, -2);
    return 1;
}

static int
_release(lua_State *L)
{
    tskiplist *sl = _to_skiplist(L);
    // printf("collect sl:%p\n", sl);
    slFree(sl);
    return 0;
}

int luaopen_timeskiplist_c(lua_State *L)
{
    luaL_checkversion(L);

    luaL_Reg l[] = {
        {"insert", _insert},
        {"delete", _delete},
        {"delete_by_rank", _delete_by_rank},

        {"get_count", _get_count},
        {"get_rank", _get_rank},
        {"get_rank_range", _get_rank_range},
        {"get_score_range", _get_score_range},

        {"dump", _dump},
        {"dump_out", _dump_out},
        {NULL, NULL}};

    lua_createtable(L, 0, 2);

    luaL_newlib(L, l);
    lua_setfield(L, -2, "__index");
    lua_pushcfunction(L, _release);
    lua_setfield(L, -2, "__gc");

    lua_pushcclosure(L, _new, 1);
    return 1;
}
