MAKEFLAGS += --warn-undefined-variables

.PHONY: build check-format format release upload Shelly1 Shelly1L Shelly1PM Shelly25 Shelly2 ShellyI3 ShellyPlug ShellyPlugS

MOS ?= mos
# Build locally by default if Docker is available.
LOCAL ?= $(shell which docker> /dev/null && echo -n 1 || echo -n 0)
CLEAN ?= 0
V ?= 0
VERBOSE ?= 0
RELEASE ?= 0
RELEASE_SUFFIX ?=
MOS_BUILD_FLAGS ?=
BUILD_DIR ?= ./build_$*

MOS_BUILD_FLAGS_FINAL = $(MOS_BUILD_FLAGS)
ifeq "$(LOCAL)" "1"
  MOS_BUILD_FLAGS_FINAL += --local
endif
ifeq "$(CLEAN)" "1"
  MOS_BUILD_FLAGS_FINAL += --clean
endif
ifneq "$(VERBOSE)$(V)" "00"
  MOS_BUILD_FLAGS_FINAL += --verbose
endif

build: Shelly1 Shelly1L Shelly1PM Shelly2 Shelly25 ShellyI3 ShellyPlug ShellyPlugS ShellyU ShellyU25

release:
	$(MAKE) build CLEAN=1 RELEASE=1

PLATFORM ?= esp8266

Shelly1: build-Shelly1
	@true

Shelly1L: build-Shelly1L
	@true

Shelly1PM: build-Shelly1PM
	@true

Shelly2: build-Shelly2
	@true

Shelly25: build-Shelly25
	@true

ShellyI3: build-ShellyI3
	@true

ShellyPlug: build-ShellyPlug
	@true

ShellyPlugS: build-ShellyPlugS
	@true

ShellyU: PLATFORM=ubuntu
ShellyU: build-ShellyU
	@true

ShellyU25: PLATFORM=ubuntu
ShellyU25: build-ShellyU25
	@true

fs/index.html.gz: fs_src/index.html fs_src/style.css fs_src/script.js fs_src/logo.svg Makefile
	cat fs_src/index.html | \
	sed "s/.*<link.*rel=\"stylesheet\".*/<style>\n\n<\/style>/g" | sed -e '/<style>/ r fs_src/style.css' | \
	sed "s/.*<script.*src=\"script.js\".*/<script>\n\n<\/script>/g" | sed -e '/<script>/ r fs_src/script.js' | \
	sed -e '/.*<img.*src=".\/logo.svg".*/ {' -e 'r fs_src/logo.svg' -e 'd' -e '}' | \
	gzip -9 -c > fs/index.html.gz

build-%: fs/index.html.gz Makefile
	$(MOS) build --platform=$(PLATFORM) --build-var=MODEL=$* \
	  --build-dir=$(BUILD_DIR) --binary-libs-dir=./binlibs $(MOS_BUILD_FLAGS_FINAL)
ifeq "$(RELEASE)" "1"
	[ $(PLATFORM) = ubuntu ] || \
	  (dir=releases/`jq -r .build_version $(BUILD_DIR)/gen/build_info.json`$(RELEASE_SUFFIX) && \
	    mkdir -p $$dir/elf && \
	    cp -v $(BUILD_DIR)/fw.zip $$dir/shelly-homekit-$*.zip && \
	    cp -v $(BUILD_DIR)/objs/*.elf $$dir/elf/shelly-homekit-$*.elf)
endif

format:
	find src -name \*.cpp -o -name \*.hpp | xargs clang-format -i

check-format: format
	@git diff --exit-code || { printf "\n== Please format your code (run make format) ==\n\n"; exit 1; }

upload:
	rsync -azv releases/* rojer.me:www/files/shelly/
