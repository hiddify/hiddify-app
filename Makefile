-include dependencies.properties

ifneq ($(wildcard .core-version),)
	core.version ?= $(strip $(file <.core-version))
endif

CHANNEL ?= dev
FORCE ?= 0

CORE_NAME := hiddify-core

BINDIR := libcore/bin
ANDROID_OUT := android/app/libs
GEO_ASSETS_DIR := assets/core
DL_DIR := .cache/downloads

CURL ?= curl
TAR ?= tar
FLUTTER ?= flutter
DART ?= dart
GO ?= go
PROTOC ?= protoc

CURL_FLAGS := -fL --retry 3 --retry-delay 1 --retry-connrefused

DART_DEFINES := $(if $(SENTRY_DSN),--dart-define sentry_dsn=$(SENTRY_DSN),) --dart-define-from-file=config.json
FLUTTER_OPTIMIZE := --obfuscate --split-debug-info=build/debug-info --tree-shake-icons

GO_LDFLAGS_BASE := -s -w -X main.version=$(core.version)

ifeq ($(CHANNEL),prod)
	CORE_URL := https://github.com/hiddify/hiddify-core/releases/download/v$(core.version)
	TARGET := lib/main_prod.dart
else
	CORE_URL := https://github.com/hiddify/hiddify-core/releases/download/draft
	TARGET := lib/main.dart
endif

GEOIP_TAG ?= latest
GEOSITE_TAG ?= latest

ifeq ($(GEOIP_TAG),latest)
	GEOIP_URL := https://github.com/SagerNet/sing-geoip/releases/latest/download/geoip.db
else
	GEOIP_URL := https://github.com/SagerNet/sing-geoip/releases/download/$(GEOIP_TAG)/geoip.db
endif

ifeq ($(GEOSITE_TAG),latest)
	GEOSITE_URL := https://github.com/SagerNet/sing-geosite/releases/latest/download/geosite.db
else
	GEOSITE_URL := https://github.com/SagerNet/sing-geosite/releases/download/$(GEOSITE_TAG)/geosite.db
endif

.PHONY: all check-env check-version check-config get gen translate prepare windows-prepare android-prepare protos android-release windows-release android-libs windows-libs build-windows-libs get-geo-assets clean

all: check-env prepare

check-version:
	@test -n "$(strip $(core.version))" || (echo "Error: core.version is empty (set it in dependencies.properties or .core-version)"; exit 1)

check-config:
	@test -f config.json || (echo "Error: config.json not found"; exit 1)

check-env: check-version
ifeq ($(OS),Windows_NT)
	@powershell -NoProfile -ExecutionPolicy Bypass -Command "$$ErrorActionPreference='Stop'; Get-Command flutter | Out-Null; Get-Command go | Out-Null; Get-Command tar | Out-Null; Get-Command curl.exe | Out-Null"
else
	@command -v $(FLUTTER) >/dev/null 2>&1 || (echo "Error: Flutter not found"; exit 1)
	@command -v $(GO) >/dev/null 2>&1 || (echo "Error: Go not found"; exit 1)
	@command -v $(CURL) >/dev/null 2>&1 || (echo "Error: curl not found"; exit 1)
	@command -v $(TAR) >/dev/null 2>&1 || (echo "Error: tar not found"; exit 1)
endif

get:
	$(FLUTTER) pub get

gen:
	$(DART) run build_runner build --delete-conflicting-outputs

translate:
	$(DART) run slang

prepare: check-env check-config get gen translate

windows-prepare: prepare windows-libs

android-prepare: get-geo-assets prepare android-libs

protos:
	$(MAKE) -C libcore -f Makefile protos
	$(PROTOC) --dart_out=grpc:lib/singbox/generated --proto_path=libcore/protos libcore/protos/*.proto

android-release:
	$(FLUTTER) build apk --target $(TARGET) $(DART_DEFINES) $(FLUTTER_OPTIMIZE) --target-platform android-arm,android-arm64,android-x64 --split-per-abi

windows-release:
	$(DART) pub global run fastforge:fastforge package --platform windows --targets exe,msix --build-target $(TARGET) $(DART_DEFINES)

android-libs:
ifeq ($(OS),Windows_NT)
	@powershell -NoProfile -ExecutionPolicy Bypass -Command "$$ErrorActionPreference='Stop'; New-Item -ItemType Directory -Force '$(DL_DIR)' | Out-Null; New-Item -ItemType Directory -Force '$(ANDROID_OUT)' | Out-Null; $$archive='$(DL_DIR)/$(CORE_NAME)-android.tar.gz'; if (($(FORCE) -eq 1) -or !(Test-Path $$archive)) { curl.exe $(CURL_FLAGS) '$(CORE_URL)/$(CORE_NAME)-android.tar.gz' -o $$archive }; tar -xzf $$archive -C '$(ANDROID_OUT)'"
else
	@mkdir -p $(DL_DIR) $(ANDROID_OUT)
	@archive="$(DL_DIR)/$(CORE_NAME)-android.tar.gz"; \
	if [ "$(FORCE)" = "1" ] || [ ! -f "$$archive" ]; then \
		$(CURL) $(CURL_FLAGS) "$(CORE_URL)/$(CORE_NAME)-android.tar.gz" -o "$$archive"; \
	fi; \
	$(TAR) -xzf "$$archive" -C "$(ANDROID_OUT)"/
endif

windows-libs:
	@mkdir -p $(BINDIR)
	$(MAKE) build-windows-libs
	@powershell -NoProfile -ExecutionPolicy Bypass -Command "$$ErrorActionPreference='Stop'; if (Test-Path '$(BINDIR)/libcore.dll') { Copy-Item -Force '$(BINDIR)/libcore.dll' 'windows/runner/libcore.dll' } else { Write-Error 'DLL not found'; exit 1 }"

build-windows-libs:
ifeq ($(OS),Windows_NT)
	@powershell -NoProfile -ExecutionPolicy Bypass -Command "$$ErrorActionPreference='Stop'; $$bt=(Get-Date).ToString('yyyy-MM-ddTHH:mm:sszzz'); $$ld='$(GO_LDFLAGS_BASE) -X main.buildTime=' + $$bt; Push-Location libcore; go build -buildmode=c-shared -trimpath -ldflags $$ld -o bin/libcore.dll ./mobile; Pop-Location"
else
	@bt="$$(date +%FT%T%z)"; \
	ld="$(GO_LDFLAGS_BASE) -X main.buildTime=$$bt"; \
	cd libcore && $(GO) build -buildmode=c-shared -trimpath -ldflags "$$ld" -o bin/libcore.dll ./mobile
endif

get-geo-assets:
ifeq ($(OS),Windows_NT)
	@powershell -NoProfile -ExecutionPolicy Bypass -Command "$$ErrorActionPreference='Stop'; New-Item -ItemType Directory -Force '$(GEO_ASSETS_DIR)' | Out-Null; $$geoip='$(GEO_ASSETS_DIR)/geoip.db'; $$geosite='$(GEO_ASSETS_DIR)/geosite.db'; if (($(FORCE) -eq 1) -or !(Test-Path $$geoip)) { curl.exe $(CURL_FLAGS) '$(GEOIP_URL)' -o $$geoip }; if (($(FORCE) -eq 1) -or !(Test-Path $$geosite)) { curl.exe $(CURL_FLAGS) '$(GEOSITE_URL)' -o $$geosite }"
else
	@mkdir -p $(GEO_ASSETS_DIR)
	@geoip="$(GEO_ASSETS_DIR)/geoip.db"; geosite="$(GEO_ASSETS_DIR)/geosite.db"; \
	if [ "$(FORCE)" = "1" ] || [ ! -f "$$geoip" ]; then $(CURL) $(CURL_FLAGS) "$(GEOIP_URL)" -o "$$geoip"; fi; \
	if [ "$(FORCE)" = "1" ] || [ ! -f "$$geosite" ]; then $(CURL) $(CURL_FLAGS) "$(GEOSITE_URL)" -o "$$geosite"; fi
endif

clean:
ifeq ($(OS),Windows_NT)
	@powershell -NoProfile -ExecutionPolicy Bypass -Command "$$ErrorActionPreference='SilentlyContinue'; flutter clean; Remove-Item -Recurse -Force '$(BINDIR)' , 'build' , '$(DL_DIR)'"
else
	@$(FLUTTER) clean
	@rm -rf $(BINDIR) build $(DL_DIR)
endif
