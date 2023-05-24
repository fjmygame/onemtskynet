LUA_VERSION =       5.3
TARGET =            crc32.so
PREFIX =            ../../skynet/3rd/lua
CFLAGS =            -O3 -Wall -pedantic -DNDEBUG
CCRC32_CFLAGS =      -fpic 
# LUA_INCLUDE_DIR =   $(PREFIX)/include
LUA_INCLUDE_DIR =   $(PREFIX)

LNX_LDFLAGS = -shared
MAC_LDFLAGS = -bundle -undefined dynamic_lookup

CC = gcc
LDFLAGS = $(MYLDFLAGS)

BUILD_CFLAGS =      -I$(LUA_INCLUDE_DIR) $(CCRC32_CFLAGS)
OBJS =              ngx_crc32.o lua-crc32.o

MY_LUA_CLIB_PATH ?= luaclib
OUT_PATH = ../../$(MY_LUA_CLIB_PATH)
# OUT_PATH = ./

all:
	@echo "Usage: $(MAKE) <platform>"
	@echo "  * linux"
	@echo "  * macosx"

.c.o:
	$(CC) -c $(CFLAGS) $(CPPFLAGS) $(BUILD_CFLAGS) -o $(OUT_PATH)/$@ $<
	# $(CC) -c $(CFLAGS) $(CPPFLAGS) $(BUILD_CFLAGS) -o $@ $<

linux:
	@$(MAKE) $(TARGET) MYLDFLAGS="$(LNX_LDFLAGS)"

macosx:
	@$(MAKE) $(TARGET) MYLDFLAGS="$(MAC_LDFLAGS)"

$(TARGET): $(OBJS)
	$(CC) $(LDFLAGS) -o $(OUT_PATH)/$@ $(foreach v, $(OBJS), $(OUT_PATH)/$(v)) ;\
	rm -f $(foreach v, $(OBJS), $(OUT_PATH)/$(v))

clean:
	rm -f *.o *.so

