include platform.mk

.PHONY: all clean

SKYNET_PATH = skynet/
CJSON = depends/json/
# ZLIB = depends/lua-zlib/
# ZSET = depends/lua-zset/
# TIMEZSET = depends/lua-timezset/
# LUACURL = depends/lua-curl/
# GOOGLETOKEN = depends/lua-googletoken/
# KCP = depends/lua-kcp
# MATHS = depends/lua-maths/
# SNAPSHOT = depends/snapshot/
# LFS = depends/luafilesystem-1_8_0/
# LUACFG = depends/lua-cfg/
# HLOGGER = depends/hlogger/
# HLOGGERLIB = depends/hloggerlib/


#模块生成的路径
export MY_LUA_CLIB_PATH ?= game/lib
#需要编译的C模块
LUA_CLIB = cjson zlib skiplist timeskiplist snapshot luacurl lkcp mathS lfs luacfg hlogger hloggerlib

all:\
	skynet/skynet.so \
	$(MY_LUA_CLIB_PATH)/cjson.so

#$(foreach v, $(LUA_CLIB), $(MY_LUA_CLIB_PATH)/$(v).so) 

	@echo "========== make onemtsdk start =========="
	cd ./onemtsdk;make $(PLAT)
	@echo "========== make onemtsdk end =========="

$(MY_LUA_CLIB_PATH) :
	mkdir -p $(MY_LUA_CLIB_PATH)

skynet/skynet.so :
	@echo "================start make skynet.so==============="
	git submodule update --init --recursive;\
	$(MAKE) $(PLAT) -C $(SKYNET_PATH)
	@echo "================make skynet.so end==============="

$(MY_LUA_CLIB_PATH)/cjson.so : $(MY_LUA_CLIB_PATH)
	@echo "================start make cjson.so==============="
	$(MAKE) -C $(CJSON)
	@echo "================make cjson.so end==============="

clean:
	rm -rf $(MY_LUA_CLIB_PATH)/*;\
	$(MAKE) cleanall -C $(SKYNET_PATH);\
	cd ./onemtsdk;make clean;