# This Makefile is based on LuaSec's Makefile. Thanks to the LuaSec developers.
# Inform the location to intall the modules
LUAPATH  ?= /usr/share/lua/5.1
LUACPATH ?= /usr/lib/lua/5.1
# INCDIR   ?= -I/usr/local/include
# LIBDIR   ?= -L/usr/local/lib
INCDIR   ?= -I../../skynet/3rd/lua
LIBDIR   ?= -L../../skynet/3rd/lua

# For Mac OS X: set the system version
MACOSX_VERSION = 10.4

CMOD = zlib.so
OBJS = lua_zlib.o

# modify hsx
# LIBS = -lz -llua -lm
LIBS = -lz -lm
WARN = -Wall -pedantic

BSD_CFLAGS  = -O2 -fPIC $(WARN) $(INCDIR) $(DEFS)
BSD_LDFLAGS = -O -shared -fPIC $(LIBDIR)

LNX_CFLAGS  = -O2 -fPIC $(WARN) $(INCDIR) $(DEFS)
LNX_LDFLAGS = -O -shared -fPIC $(LIBDIR)

MAC_ENV     = env MACOSX_DEPLOYMENT_TARGET='$(MACVER)'
MAC_CFLAGS  = -O2 -fPIC -fno-common $(WARN) $(INCDIR) $(DEFS)
MAC_LDFLAGS = -bundle -undefined dynamic_lookup -fPIC $(LIBDIR)

CC = gcc
LD = $(MYENV) gcc
CFLAGS  = $(MYCFLAGS)
LDFLAGS = $(MYLDFLAGS)


MY_LUA_CLIB_PATH ?= luaclib
OUT_PATH = ../../$(MY_LUA_CLIB_PATH)

.PHONY: all clean install none linux bsd macosx

all:
	@echo "Usage: $(MAKE) <platform>"
	@echo "  * linux"
	@echo "  * bsd"
	@echo "  * macosx"

# install: $(CMOD)
# 	cp $(CMOD) $(LUACPATH)

# uninstall:
# 	rm $(LUACPATH)/zlib.so

linux:
	@$(MAKE) $(CMOD) MYCFLAGS="$(LNX_CFLAGS)" MYLDFLAGS="$(LNX_LDFLAGS)" INCDIR="$(INCDIR)" LIBDIR="$(LIBDIR)" DEFS="$(DEFS)"

bsd:
	@$(MAKE) $(CMOD) MYCFLAGS="$(BSD_CFLAGS)" MYLDFLAGS="$(BSD_LDFLAGS)" INCDIR="$(INCDIR)" LIBDIR="$(LIBDIR)" DEFS="$(DEFS)"

macosx:
	@$(MAKE) $(CMOD) MYCFLAGS="$(MAC_CFLAGS)" MYLDFLAGS="$(MAC_LDFLAGS)" MYENV="$(MAC_ENV)" INCDIR="$(INCDIR)" LIBDIR="$(LIBDIR)" DEFS="$(DEFS)"

clean:
	rm -f $(OBJS) $(CMOD)

.c.o:
	$(CC) -c $(CFLAGS) $(DEFS) $(INCDIR) -o $(OUT_PATH)/$@ $<

$(CMOD): $(OBJS)
	# $(LD) $(LDFLAGS) $(LIBDIR) $(OBJS) $(LIBS) -o $@
	$(LD) $(LDFLAGS) $(LIBDIR) $(foreach v, $(OBJS), $(OUT_PATH)/$(v)) $(LIBS) -o $(OUT_PATH)/$@ ;\
	rm -f $(foreach v, $(OBJS), $(OUT_PATH)/$(v))
