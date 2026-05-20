BINARY_NAME = DockStay
PREFIX ?= /usr/local
INSTALL_DIR = $(PREFIX)/bin

.PHONY: build install uninstall clean

build:
	swift build -c release

install: build
	@mkdir -p $(INSTALL_DIR)
	cp .build/release/$(BINARY_NAME) $(INSTALL_DIR)/dockstay
	@echo "Installed to $(INSTALL_DIR)/dockstay"
	@echo "Grant Accessibility access in System Settings if prompted."

uninstall:
	@-kill $$(pgrep -x dockstay) 2>/dev/null || true
	rm -f $(INSTALL_DIR)/dockstay
	@echo "Uninstalled."

clean:
	swift package clean
	rm -rf .build
