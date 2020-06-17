ifeq ("$(ELM)","")
	ELM=elm
endif

ifeq ("$(ELMLIVE)", "")
	ELMLIVE=elm-live
endif

ifeq ("$(UGLIFYJS)", "")
	UGLIFYJS=uglifyjs
endif

BUILD_DIR=./server/dist

all: client-dev setup-dev server-dev

release: client-release setup-release server-release

.NOTPARALLEL: client-dev client-release setup-dev setup-release client-watch setup-watch

client-dev: client/src/**
	@/bin/echo -e "\033[32;1m   Compiling\033[0m client (debug)"
	@cp client/src/Log.elm.debug client/src/Log.elm
	@mkdir -p $(BUILD_DIR)
	@cd client && $(ELM) make src/Main.elm --output ../$(BUILD_DIR)/main.js
	@/bin/echo -e "\033[32;1m    Finished\033[0m client (debug)"

client-release: client/src/**
	@/bin/echo -e "\033[32;1m   Compiling\033[0m client (release)"
	@cp client/src/Log.elm.release client/src/Log.elm
	@mkdir -p $(BUILD_DIR)
	@cd client && $(ELM) make src/Main.elm --optimize --output ../$(BUILD_DIR)/main.tmp.js
	@cd client && $(UGLIFYJS) ../$(BUILD_DIR)/main.tmp.js --compress 'pure_funcs="F2,F3,F4,F5,F6,F7,F8,F9,A2,A3,A4,A5,A6,A7,A8,A9",pure_getters,keep_fargs=false,unsafe_comps,unsafe' | uglifyjs --mangle --output=../$(BUILD_DIR)/main.min.js
	@/bin/echo -e "\033[32;1m    Finished\033[0m client (release)"

setup-dev: client/src/**
	@/bin/echo -e "\033[32;1m   Compiling\033[0m setup (debug)"
	@cp client/src/Log.elm.debug client/src/Log.elm
	@mkdir -p $(BUILD_DIR)
	@cd client && $(ELM) make src/Setup.elm --output ../$(BUILD_DIR)/setup.js
	@/bin/echo -e "\033[32;1m    Finished\033[0m setup (debug)"

setup-release: client/src/**
	@/bin/echo -e "\033[32;1m   Compiling\033[0m setup (release)"
	@cp client/src/Log.elm.release client/src/Log.elm
	@mkdir -p $(BUILD_DIR)
	@cd client && $(ELM) make src/Setup.elm --optimize --output ../$(BUILD_DIR)/setup.tmp.js
	@cd client && $(UGLIFYJS) ../$(BUILD_DIR)/setup.tmp.js --compress 'pure_funcs="F2,F3,F4,F5,F6,F7,F8,F9,A2,A3,A4,A5,A6,A7,A8,A9",pure_getters,keep_fargs=false,unsafe_comps,unsafe' | uglifyjs --mangle --output=../$(BUILD_DIR)/setup.min.js
	@/bin/echo -e "\033[32;1m    Finished\033[0m setup (release)"

client-watch:
	@/bin/echo -e "\033[32;1m    Watching\033[0m client"
	@cp client/src/Log.elm.debug client/src/Log.elm
	@mkdir -p $(BUILD_DIR)
	@cd client && $(ELMLIVE) src/Main.elm -p 7000 -d ../$(BUILD_DIR)/ -- --output ../$(BUILD_DIR)/main.js

setup-watch:
	@/bin/echo -e "\033[32;1m    Watching\033[0m setup"
	@cp client/src/Log.elm.debug client/src/Log.elm
	@mkdir -p $(BUILD_DIR)
	@cd client && $(ELMLIVE) src/Setup.elm -p 7000 -d ../$(BUILD_DIR)/ -- --output ../$(BUILD_DIR)/setup.js

server-dev:
	@cd server && cargo +nightly build

server-release:
	@cd server && cargo +nightly build --release

clean-client:
	@/bin/echo -e "\033[32;1m    Cleaning\033[0m client"
	@rm -rf $(BUILD_DIR)
	@/bin/echo -e "\033[32;1m     Cleaned\033[0m client"

clean-server:
	@/bin/echo -e "\033[32;1m    Cleaning\033[0m server"
	@cd server && cargo clean
	@/bin/echo -e "\033[32;1m     Cleaned\033[0m server"

clean: clean-client clean-server

