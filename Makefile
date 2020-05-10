SOURCES_MOON := $(wildcard *.moon)
SOURCES_MOON := $(filter-out Build.moon, $(SOURCES_MOON))
OUT_LUA      := $(foreach source, $(SOURCES_MOON), $(patsubst %.moon, %.lua, $(source)))
BINARY       := moonbuild
MAIN         := $(BINARY).moon
MAIN_LUA     := $(patsubst %.moon, %.lua, $(MAIN))
OUT_C        := $(patsubst %.moon, %.lua.c, $(MAIN))
PREFIX       ?= /usr/local

.PHONY: all install clean mrproper info

all: $(BINARY)

install: moonbuild
	install $^ $(PREFIX)/bin

clean:
	rm -f $(OUT_LUA)
	rm -f $(OUT_C)

mrproper: clean
	rm -f $(BINARY)

info:
	@echo "Moonscript sources:" $(SOURCES_MOON)
	@echo "Compiled lua:" $(OUT_LUA)
	@echo "Binary:" $(BINARY)

$(BINARY): $(OUT_LUA)
	luastatic $(MAIN_LUA) $(OUT_LUA) -I/usr/include/lua5.3 -llua5.3

%.lua: %.moon
	moonc $^
