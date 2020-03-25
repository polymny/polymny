ifeq ("$(ELM)","")
	ELM=elm
endif

ifeq ("$(ELMLIVE)", "")
	ELMLIVE=elm-live
endif

BUILD_DIR=./server/dist

all: client-dev setup-dev server-dev

client-dev: client/src/**
	@/bin/echo -e "\033[32;1m   Compiling\033[0m client"
	@mkdir -p $(BUILD_DIR)
	@cd client && $(ELM) make src/Main.elm --output ../$(BUILD_DIR)/main.js
	@/bin/echo -e "\033[32;1m    Finished\033[0m client"

setup-dev: client/src/**
	@/bin/echo -e "\033[32;1m   Compiling\033[0m setup"
	@mkdir -p $(BUILD_DIR)
	@cd client && $(ELM) make src/Setup.elm --output ../$(BUILD_DIR)/setup.js
	@/bin/echo -e "\033[32;1m    Finished\033[0m setup"

client-watch:
	@/bin/echo -e "\033[32;1m    Watching\033[0m client"
	@mkdir -p $(BUILD_DIR)
	@cd client && $(ELMLIVE) src/Main.elm -p 7000 -d ../$(BUILD_DIR)/ -- --output ../$(BUILD_DIR)/main.js

setup-watch:
	@/bin/echo -e "\033[32;1m    Watching\033[0m setup"
	@mkdir -p $(BUILD_DIR)
	@cd client && $(ELMLIVE) src/Setup.elm -p 7000 -d ../$(BUILD_DIR)/ -- --output ../$(BUILD_DIR)/setup.js

server-dev:
	@cd server && cargo +nightly build

clean-client:
	@/bin/echo -e "\033[32;1m    Cleaning\033[0m client"
	@rm -rf $(BUILD_DIR)
	@/bin/echo -e "\033[32;1m     Cleaned\033[0m client"

clean-server:
	@/bin/echo -e "\033[32;1m    Cleaning\033[0m server"
	@cd server && cargo clean
	@/bin/echo -e "\033[32;1m     Cleaned\033[0m server"

clean: clean-client clean-server

