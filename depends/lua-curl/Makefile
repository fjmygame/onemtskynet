# include ../../skynet.mk

LUA_VERSION =       5.3
TARGET =            luacurl.so
PREFIX =            ../../skynet/3rd/lua
CFLAGS =            -O3 -Wall -pedantic -DNDEBUG -DUSE_MEM_HOOK
CZSET_CFLAGS =      -fpic 
LUA_INCLUDE_DIR =   $(PREFIX)/
# LUA_INCLUDE_DIR =   $(LUA_INC)
MY_LUA_CLIB_PATH ?= game/lib
OUT_PATH = ../../$(MY_LUA_CLIB_PATH)

LNX_LDFLAGS = -shared -lcurl
MAC_LDFLAGS = -bundle -undefined dynamic_lookup -lcurl

CC = gcc
LDFLAGS = $(MYLDFLAGS)

BUILD_CFLAGS =      -I$(LUA_INCLUDE_DIR) $(CZSET_CFLAGS)
OBJS =              constants.o luacurl.o multi.o

all:
	@echo "Usage: $(MAKE) <platform>"
	@echo "  * linux"
	@echo "  * macosx"

.c.o:
	$(CC) -c $(CFLAGS) $(CPPFLAGS) $(BUILD_CFLAGS) -o $@ $<

linux:
	@$(MAKE) $(TARGET) MYLDFLAGS="$(LNX_LDFLAGS)"
	rm -f *.o

macosx:
	@$(MAKE) $(TARGET) MYLDFLAGS="$(MAC_LDFLAGS)"
	rm -f *.o

$(TARGET): $(OBJS)
	$(CC) -o $(OUT_PATH)/$@ $(OBJS) $(LDFLAGS)

clean:
	rm -f *.o *.so

