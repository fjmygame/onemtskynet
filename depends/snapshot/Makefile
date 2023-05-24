LUA_VERSION =       5.3
TARGET =            snapshot.so
# PREFIX =            /usr/local
PREFIX =            ../../skynet/3rd/lua
CFLAGS =            -O3 -Wall -pedantic -DNDEBUG
CZSET_CFLAGS =      -fpic 
LUA_INCLUDE_DIR =   $(PREFIX)/

LNX_LDFLAGS = -shared
MAC_LDFLAGS = -bundle -undefined dynamic_lookup

MY_LUA_CLIB_PATH ?= luaclib
OUT_PATH = ../../$(MY_LUA_CLIB_PATH)

CC = gcc
LDFLAGS = $(MYLDFLAGS)

BUILD_CFLAGS =      -I$(LUA_INCLUDE_DIR) $(CZSET_CFLAGS)
OBJS =              snapshot.o

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
	# $(CC) $(LDFLAGS) -o $@ $(OBJS)
	$(CC) $(LDFLAGS) -o $(OUT_PATH)/$@ $(foreach v, $(OBJS), $(v)) ;\
	rm -f $(foreach v, $(OBJS), $(v))

clean:
	rm -f *.o *.so

