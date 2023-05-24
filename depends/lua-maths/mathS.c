#include "lua.h"
#include "lauxlib.h"
long long abs_s(long long x)
{
	return x > 0 ? x : -x;
}

long long mins(long long x, long long y)
{
	return x < y ? x : y;
}

//默认十倍
//int normalizeV2(lua_State* l)
//{
//    lua_pushstring(l, "x");
//    lua_gettable(l, 1);
//    int x1 = atoi(lua_tostring(l, -1));
//    lua_pop(l, 1);
//    lua_pushstring(l, "y");
//    lua_gettable(l, 1);
//    int y1 = atoi(lua_tostring(l, -1));
//    lua_pushstring(l, "x");
//    lua_gettable(l, 2);
//    int x2 = atoi(lua_tostring(l, -1));
//    lua_pop(l, 1);
//    lua_pushstring(l, "y");
//    lua_gettable(l, 2);
//    int y2 = atoi(lua_tostring(l, -1));
//    lua_pop(l, 1);
//    int distance = pointDis(x2 - x1, y2 - y1);
//    lua_pushnumber(l, (x2 - x1) * 10 / distance);
//    lua_pushnumber(l, (y2 - y1) * 10 / distance);
//    return 2;
//}

long long pointDis(long long x, long long y)
{
	long long m;
	x = abs_s(x);
	y = abs_s(y);
	m = mins(x, y);
	return x + y - (m >> 1) - (m >> 2) + (m >> 4);
}

//默认十倍
int nNormalizeV2(lua_State *l)
{
	long long x = (long long)(luaL_checknumber(l, 1));
	long long y = (long long)(luaL_checknumber(l, 2));
	long long distance = pointDis(x, y);
	if(distance==0)
		distance = 1;
	lua_pushnumber(l, (x * 1000L) / distance);
	lua_pushnumber(l, (y * 1000L) / distance);
	return 2;
}

const unsigned int maxShort = 65536u;
const unsigned int multiper = 1194211693u;
const unsigned int addValue = 12345u;
int nRandom(lua_State *l)
{
	unsigned int seed = (int)(luaL_checknumber(l, 1));
	unsigned int max = (int)(luaL_checknumber(l, 2));
	unsigned int rs;
	seed = seed*multiper + addValue;
	rs = seed >> 16;
	rs = rs%max;
	lua_pushnumber(l, seed >> 2);
	lua_pushnumber(l, rs);
	return 2;
}

int nRotateV2(lua_State *l)
{
	long long x = (long long)(luaL_checknumber(l, 1));
	long long y = (long long)(luaL_checknumber(l, 2));
	long long s = (long long)(luaL_checknumber(l, 3));
	long long c = (long long)(luaL_checknumber(l, 4));
	lua_pushnumber(l, (x*c + y*s) / 100000);
	lua_pushnumber(l, (y*c - x*s) / 100000);
	return 2;
}

int nDistanceV2(lua_State *l)
{
	long long x = (long long)(luaL_checknumber(l, 1));
	long long y = (long long)(luaL_checknumber(l, 2));
	lua_pushnumber(l, pointDis(x, y));
	return 1;
}

int nMultiply(lua_State *l)
{
	long long x = (long long)(luaL_checknumber(l, 1));
	long long y = (long long)(luaL_checknumber(l, 2));
	lua_pushnumber(l, x*y);
	return 1;
}

int nDivided(lua_State *l)
{
	long long x = (long long)(luaL_checknumber(l, 1));
	long long y = (long long)(luaL_checknumber(l, 2));
	if(y==0)
		y = 1;
	long long result = x / y;
	lua_pushnumber(l, result);
	return 1;
}

int nMd(lua_State *l)
{
	long long x = (long long)(luaL_checknumber(l, 1));
	long long y = (long long)(luaL_checknumber(l, 2));
	long long z = (long long)(luaL_checknumber(l, 3));
	if(z==0)
		z = 1;
	long long result = x*y / z;
	lua_pushnumber(l, result);
	return 1;
}

LUALIB_API int luaopen_mathS ( lua_State *L )
{
    luaL_checkversion(L);
	    luaL_Reg l[] = {
		{ "nRotateV2", nRotateV2 },
		{ "nDistanceV2", nDistanceV2 },
		{ "nNormalizeV2", nNormalizeV2 },
		{ "nRandom", nRandom },
		{ "nMultiply", nMultiply },
		{ "nDivided", nDivided },
		{ "nMd", nMd },
        { NULL, NULL },
    };
    luaL_newlib(L,l);
    return 1;
}
