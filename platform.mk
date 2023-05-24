
export PLAT ?= none
PLATS = linux macosx

CC ?= gcc

.PHONY : none $(PLATS) clean all cleanall

.PHONY : default

default :
	$(MAKE) $(PLAT)

none :
	@echo "Please do 'make PLATFORM' where PLATFORM is one of these:"
	@echo "   $(PLATS)"


linux : PLAT = linux
macosx : PLAT = macosx

linux macosx :
	$(MAKE) all PLAT=$@
