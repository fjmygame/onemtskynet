include platform.mk

.PHONY: all clean

SKYNET_PATH = skynet/
CJSON = depends/json/
ZLIB = depends/lua-zlib/
ZSET = depends/lua-zset/
TIMEZSET = depends/lua-timezset/
LUACURL = depends/lua-curl/
GOOGLETOKEN = depends/lua-googletoken/
KCP = depends/lua-kcp
MATHS = depends/lua-maths/
SNAPSHOT = depends/snapshot/
LFS = depends/luafilesystem-1_8_0/
LUACFG = depends/lua-cfg/
HLOGGER = depends/hlogger/
HLOGGERLIB = depends/hloggerlib/


#模块生成的路径
export MY_LUA_CLIB_PATH ?= game/lib
#需要编译的C模块
LUA_CLIB = cjson zlib skiplist timeskiplist snapshot luacurl lkcp mathS lfs luacfg hlogger hloggerlib

all:\
	skynet/skynet.so \
	$(foreach v, $(LUA_CLIB), $(MY_LUA_CLIB_PATH)/$(v).so) 

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

$(MY_LUA_CLIB_PATH)/snapshot.so :
	@echo "================start make snapshot.so==============="
	$(MAKE) $(PLAT) -C $(SNAPSHOT)
	@echo "================make snapshot.so end==============="

$(MY_LUA_CLIB_PATH)/luacurl.so :
	@echo "================start make luacurl.so==============="
	$(MAKE) $(PLAT) -C $(LUACURL)
	@echo "================make luacurl.so end==============="

$(MY_LUA_CLIB_PATH)/googletoken.so :
	@echo "================start make googletoken.so==============="
	$(MAKE) $(PLAT) -C $(GOOGLETOKEN)
	@echo "================make googletoken.so end==============="

$(MY_LUA_CLIB_PATH)/skiplist.so :
	@echo "================start make zset skiplist.so==============="
	$(MAKE) $(PLAT) -C $(ZSET)
	@echo "================make zset skiplist.so end==============="

$(MY_LUA_CLIB_PATH)/zlib.so :
	@echo "================start make zlib.so==============="
	$(MAKE) $(PLAT) -C $(ZLIB)
	@echo "================make zlib.so end==============="

$(MY_LUA_CLIB_PATH)/mathS.so :
	@echo "================start make mathS.so==============="
	$(MAKE) $(PLAT) -C $(MATHS)
	@echo "================make mathS.so end==============="

$(MY_LUA_CLIB_PATH)/timeskiplist.so :
	@echo "================start make timeskiplist.so==============="
	$(MAKE) $(PLAT) -C $(TIMEZSET)
	@echo "================make timeskiplist.so end==============="

$(MY_LUA_CLIB_PATH)/lkcp.so :
	@echo "================start make lkcp.so==============="
	$(MAKE) $(PLAT) -C $(KCP)
	@echo "================make lkcp.so end==============="

$(MY_LUA_CLIB_PATH)/lfs.so :
	@echo "================start make lfs.so==============="
	$(MAKE) $(PLAT) -C $(LFS)
	@echo "================make lfs.so end==============="

$(MY_LUA_CLIB_PATH)/luacfg.so :
	@echo "================start make luacfg.so==============="
	$(MAKE) $(PLAT) -C $(LUACFG)
	@echo "================make luacfg.so end==============="

$(MY_LUA_CLIB_PATH)/hlogger.so :
	@echo "================start make hlogger.so==============="
	$(MAKE) $(PLAT) -C $(HLOGGER)
	@echo "================make hlogger.so end==============="

$(MY_LUA_CLIB_PATH)/hloggerlib.so :
	@echo "================start make hloggerlib.so==============="
	$(MAKE) $(PLAT) -C $(HLOGGERLIB)
	@echo "================make hloggerlib.so end==============="

clean:
	rm -rf $(MY_LUA_CLIB_PATH)/*;\
	$(MAKE) cleanall -C $(SKYNET_PATH);\
	cd ./onemtsdk;make clean;