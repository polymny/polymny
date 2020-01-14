ifeq ("$(ELM)","")
	ELM=elm
endif

ifeq ("$(ELMLIVE)", "")
	ELMLIVE=elm-live
endif

STATIC_FILES=client/static/*
BUILD_DIR=./server/dist

all: client-dev client-static server-dev

client-static: client/static/*
	@/bin/echo -e "\033[32;1m     Copying\033[0m client static files"
	@mkdir -p $(BUILD_DIR)
	@cp $(STATIC_FILES) $(BUILD_DIR)
	@/bin/echo -e "\033[32;1m      Copied\033[0m client static files"

client-dev: client/src/** client-static
	@/bin/echo -e "\033[32;1m   Compiling\033[0m client"
	@cd client && $(ELM) make src/Main.elm --output ../$(BUILD_DIR)/main.js
	@/bin/echo -e "\033[32;1m    Finished\033[0m client"

client-watch:
	@/bin/echo -e "\033[32;1m    Watching\033[0m client"
	@cd client && $(ELMLIVE) src/Main.elm -p 7000 -d ../$(BUILD_DIR)/ -- --output ../$(BUILD_DIR)/main.js

server-dev:
	@cd server && cargo build

clean-client:
	@/bin/echo -e "\033[32;1m    Cleaning\033[0m client"
	@rm -rf $(BUILD_DIR)
	@/bin/echo -e "\033[32;1m     Cleaned\033[0m client"

clean-server:
	@/bin/echo -e "\033[32;1m    Cleaning\033[0m server"
	@cd server && cargo clean
	@/bin/echo -e "\033[32;1m     Cleaned\033[0m server"

clean: clean-client clean-server

