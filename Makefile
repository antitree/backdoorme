PATCH_DIR := patches
BUILD_DIR := build

.DEFAULT_GOAL := help

.PHONY: help patch/% image/%
help:
	@echo "Usage:"
	@echo "  make patch/<name>   - Clone, patch, and build the given repo"
	@echo "  make image/<name>   - Build docker image using patched binary"
	@echo ""
	@echo "  Example: make patch/hashicorp-vault"

# Pattern rule: "patch/NAME"
patch/%:
	@name=$* ; \
	repo=$$(echo $$name | sed 's|-|/|') ; \
	echo "🔧 Building and patching: $$repo" ; \
	rm -rf $(BUILD_DIR)/$$name ; \
	git clone --depth 1 --branch main https://github.com/$$repo $(BUILD_DIR)/$$repo ; \
	cp $(PATCH_DIR)/$$name.patch $(BUILD_DIR)/$$repo && cd $(BUILD_DIR)/$$repo && patch -p1 < $$name.patch ; \
	make

# Pattern rule: "image/NAME"
image/%: patch/%
	@name=$* ; \
	repo=$$(echo $$name | sed 's|-|/|') ; \
	bin=$$(basename $$repo) ; \
	src=$(BUILD_DIR)/$$repo ; \
	dockerfile=$(BUILD_DIR)/Dockerfile.$$name ; \
	echo "🔨 Building docker image for $$repo" ; \
	docker pull $$repo:latest >/dev/null ; \
	echo "FROM $$repo:latest" > $$dockerfile ; \
	echo "COPY $$src/bin/$$bin /usr/local/bin/$$bin" >> $$dockerfile ; \
	docker build -f $$dockerfile -t $$name-patched $$src

