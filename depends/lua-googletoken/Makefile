# include ../../skynet.mk

LUA_VERSION =       5.3
TARGET =            googletoken.so
# PREFIX =            /usr/local
PREFIX =            ../../skynet/3rd/lua
CFLAGS =            -O3 -Wall -pedantic -DNDEBUG -DUSE_MEM_HOOK
CZSET_CFLAGS =      -fpic 
LUA_INCLUDE_DIR =   $(PREFIX)/include
# LUA_INCLUDE_DIR =   $(LUA_INC)
OUT_PATH = ../../$(MY_LUA_CLIB_PATH)

LNX_LDFLAGS = -shared
MAC_LDFLAGS = -bundle -undefined dynamic_lookup

CC = gcc
LDFLAGS = $(MYLDFLAGS)

BUILD_CFLAGS =      -I$(LUA_INCLUDE_DIR) $(CZSET_CFLAGS)
OBJS =              lua-googletoken.o

all:
	@echo "Usage: $(MAKE) <platform>"
	@echo "  * linux"
	@echo "  * macosx"

.c.o:
	$(CC) -c $(CFLAGS) $(CPPFLAGS) $(BUILD_CFLAGS) -o $(OUT_PATH)/$@ $<

linux:
	@$(MAKE) $(TARGET) MYLDFLAGS="$(LNX_LDFLAGS)"

macosx:
	@$(MAKE) $(TARGET) MYLDFLAGS="$(MAC_LDFLAGS)"

$(TARGET): $(OBJS)
	# $(CC) $(LDFLAGS) -o $@ $(OBJS)
	$(CC) $(LDFLAGS) -o $(OUT_PATH)/$@ $(foreach v, $(OBJS), $(OUT_PATH)/$(v)) ;\
	rm -f $(foreach v, $(OBJS), $(OUT_PATH)/$(v))


clean:
	rm -f *.o *.so

