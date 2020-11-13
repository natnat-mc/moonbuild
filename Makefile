.PHONY: all clean mrproper bin lib

MOONC = moonc
AMALG = amalg.lua
RM = rm -f --
LUA = lua5.3

LIB_SRC = $(wildcard moonbuild/*.moon) $(wildcard moonbuild/*/*.moon) $(wildcard moonbuild/*/*/*.moon)
BIN_SRC = $(wildcard bin/*.moon)

LIB_LUA = $(foreach moon, $(LIB_SRC), $(patsubst %.moon, %.lua, $(moon)))
BIN_LUA = $(foreach moon, $(BIN_SRC), $(patsubst %.moon, %.lua, $(moon)))
BIN = $(foreach lua, $(BIN_LUA), $(patsubst bin/%.lua, out/%, $(lua)))

MODULES = $(shell echo $(foreach lib, $(LIB_LUA), $(patsubst %.lua, %, $(lib))) | sed 's|/|.|g')

all: bin lib

clean:
	$(RM) $(LIB_LUA)
	$(RM) $(BIN_LUA)

mrproper: clean
	$(RM) $(BIN) out/moonbuild.lua

bin: $(BIN)

lib: $(LIB_LUA) out/moonbuild.lua

out/%: bin/%.lua $(LIB_LUA)
	@mkdir -p `dirname $@`
	@printf '#!/usr/bin/env %s\n' $(LUA) > $@.headline
	@cat $@.headline $< > $@
	@rm $@.headline
	chmod +x $@

out/moonbuild.lua: moonbuild/init.lua $(LIB_LUA)
	@mkdir -p `dirname $@`
	$(AMALG) -o $@ -s $< $(MODULES)

%.lua: %.moon
	moonc $^
