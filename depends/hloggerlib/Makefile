# include ../../skynet.mk

LUA_VERSION =       5.3
TARGET =            hloggerlib.so
PREFIX =            ../../skynet/3rd/lua
CFLAGS =            -O2 -Wall -pedantic -DNDEBUG
MATHS_CFLAGS =      -fpic 
LUA_INCLUDE_DIR =   $(PREFIX)/
LNX_LDFLAGS = -shared
MAC_LDFLAGS = -bundle -undefined dynamic_lookup

CC = gcc
LDFLAGS = $(MYLDFLAGS)

BUILD_CFLAGS =      -I$(LUA_INCLUDE_DIR) -I../../skynet/skynet-src $(MATHS_CFLAGS)
OBJS =              hloggerlib.o

MY_LUA_CLIB_PATH ?= game/lib
OUT_PATH = ../../$(MY_LUA_CLIB_PATH)

all:
	@echo "Usage: $(MAKE) <platform>"
	@echo "  * linux"
	@echo "  * macosx"

.c.o:
	$(CC) -c $(CFLAGS) $(CPPFLAGS) $(BUILD_CFLAGS) -o $@ $<

linux:
	@$(MAKE) $(TARGET) MYLDFLAGS="$(LNX_LDFLAGS)"

macosx:
	@$(MAKE) $(TARGET) MYLDFLAGS="$(MAC_LDFLAGS)"

$(TARGET): $(OBJS)
	$(CC) $(LDFLAGS) -o $(OUT_PATH)/$@ $(foreach v, $(OBJS), $(v)) ;\
	rm -f $(foreach v, $(OBJS), $(v))


clean:
	rm -f *.o *.so

