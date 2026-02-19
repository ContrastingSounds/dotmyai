TOOLS_DIR := $(HOME)/.myai/tools
CMDS := $(patsubst cmd/%/main.go,%,$(wildcard cmd/*/main.go))

.PHONY: all test lint clean $(CMDS)

all: $(CMDS)

$(CMDS):
	go build -o $(TOOLS_DIR)/$@ ./cmd/$@

test:
	go test ./...

lint:
	golangci-lint run ./...

clean:
	@for cmd in $(CMDS); do rm -f $(TOOLS_DIR)/$$cmd; done
