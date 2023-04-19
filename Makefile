ifeq ("$(ELM)","")
	ELM=elm
endif

ifeq ("$(ELMLIVE)", "")
	ELMLIVE=elm-live
endif

ifeq ("$(UGLIFYJS)", "")
	UGLIFYJS=uglifyjs
endif

BUILD_DIR=server/dist/js/

all: client-dev server-dev

release: client-release unlogged-release server-release

.NOTPARALLEL: client-dev client-release client-watch

client-dev: client/src/** server/dist/js/ports.js client/src/Strings.elm
	@/bin/echo -e "\033[32;1m   Compiling\033[0m client (debug)"
	@mkdir -p $(BUILD_DIR)
	@cd client && $(ELM) make src/Main.elm --output ../$(BUILD_DIR)/main.js
	@/bin/echo -e "\033[32;1m    Finished\033[0m client (debug)"

client-release: client/src/** client/src/Strings.elm
	@/bin/echo -e "\033[32;1m   Compiling\033[0m client (release)"
	@mkdir -p $(BUILD_DIR)
	@cd client && $(ELM) make src/Main.elm --optimize --output ../$(BUILD_DIR)/main.tmp.js
	@cd client && $(UGLIFYJS) ../$(BUILD_DIR)/main.tmp.js --compress 'pure_funcs="F2,F3,F4,F5,F6,F7,F8,F9,A2,A3,A4,A5,A6,A7,A8,A9",pure_getters,keep_fargs=false,unsafe_comps,unsafe' | uglifyjs --mangle > ../$(BUILD_DIR)/main.min.js
	@/bin/echo -e "\033[32;1m    Finished\033[0m client (release)"

client-watch:
	@/bin/echo -e "\033[32;1m    Watching\033[0m client"
	@mkdir -p $(BUILD_DIR)
	@cd client && $(ELMLIVE) src/Main.elm -p 7000 -d ../$(BUILD_DIR)/ -- --output ../$(BUILD_DIR)/main.js

unlogged-dev: client/src/**
	@/bin/echo -e "\033[32;1m   Compiling\033[0m unlogged (debug)"
	@mkdir -p $(BUILD_DIR)
	@cd client && $(ELM) make src/Unlogged.elm --output ../$(BUILD_DIR)/unlogged.js
	@/bin/echo -e "\033[32;1m    Finished\033[0m unlogged (debug)"

unlogged-release: client/src/**
	@/bin/echo -e "\033[32;1m   Compiling\033[0m unlogged (release)"
	@mkdir -p $(BUILD_DIR)
	@cd client && $(ELM) make src/Unlogged.elm --optimize --output ../$(BUILD_DIR)/unlogged.tmp.js
	@cd client && $(UGLIFYJS) ../$(BUILD_DIR)/unlogged.tmp.js --compress 'pure_funcs="F2,F3,F4,F5,F6,F7,F8,F9,A2,A3,A4,A5,A6,A7,A8,A9",pure_getters,keep_fargs=false,unsafe_comps,unsafe' | uglifyjs --mangle > ../$(BUILD_DIR)/unlogged.min.js
	@/bin/echo -e "\033[32;1m    Finished\033[0m unlogged (release)"

unlogged-watch:
	@/bin/echo -e "\033[32;1m    Watching\033[0m unlogged"
	@mkdir -p $(BUILD_DIR)
	@cd client && $(ELMLIVE) src/Unlogged.elm -p 7001 -d ../$(BUILD_DIR)/ -- --output ../$(BUILD_DIR)/unlogged.js

server-dev:
	@cd server && cargo build

server-release:
	@cd server && cargo build --release

clean-client:
	@/bin/echo -e "\033[32;1m    Cleaning\033[0m client"
	@rm -rf $(BUILD_DIR)
	@/bin/echo -e "\033[32;1m     Cleaned\033[0m client"

clean-server:
	@/bin/echo -e "\033[32;1m    Cleaning\033[0m server"
	@cd server && cargo clean
	@/bin/echo -e "\033[32;1m     Cleaned\033[0m server"

client/src/Strings.elm: client/strings/*po
	@potoelm client/strings/ > client/src/Strings.elm

clean: clean-client clean-server

server/dist/js/ports.js: client/ports.js
	@cp client/ports.js server/dist/js/ports.js

multiview:
	@rm -rf $$HOME/.npmbin/lib/node_modules/multiview/cli/multiview_main.sock && multiview [ sh -c "cd server && unbuffer cargo run" ] [ unbuffer make client-watch ]


old-client-dev: old-client/src/**
	@/bin/echo -e "\033[32;1m   Compiling\033[0m old-client (debug)"
	@cp old-client/src/Log.elm.debug old-client/src/Log.elm
	@mkdir -p $(BUILD_DIR)
	@cd old-client && $(ELM) make src/OldMain.elm --output ../$(BUILD_DIR)/old-main.js
	@/bin/echo -e "\033[32;1m    Finished\033[0m old-client (debug)"

old-client-release: old-client/src/**
	@/bin/echo -e "\033[32;1m   Compiling\033[0m old-client (release)"
	@cp old-client/src/Log.elm.release old-client/src/Log.elm
	@mkdir -p $(BUILD_DIR)
	@cd old-client && $(ELM) make src/OldMain.elm --optimize --output ../$(BUILD_DIR)/old-main.tmp.js
	@cd old-client && $(UGLIFYJS) ../$(BUILD_DIR)/old-main.tmp.js --compress 'pure_funcs="F2,F3,F4,F5,F6,F7,F8,F9,A2,A3,A4,A5,A6,A7,A8,A9",pure_getters,keep_fargs=false,unsafe_comps,unsafe' | uglifyjs --mangle > ../$(BUILD_DIR)/old-main.min.js
	@/bin/echo -e "\033[32;1m    Finished\033[0m old-client (release)"

old-client-watch:
	@/bin/echo -e "\033[32;1m    Watching\033[0m old-client"
	@cp old-client/src/Log.elm.debug old-client/src/Log.elm
	@mkdir -p $(BUILD_DIR)
	@cd old-client && $(ELMLIVE) src/OldMain.elm -p 7001 -d ../$(BUILD_DIR)/ -- --output ../$(BUILD_DIR)/old-main.js

