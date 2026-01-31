include dependencies.properties

ifneq ($(wildcard .core-version),)
	core.version ?= $(strip $(file <.core-version))
endif

GEOIP_TAG ?= latest
GEOSITE_TAG ?= latest
CHANNEL ?= dev
GO_VERSION := 1.26

CORE_NAME      := hiddify-core
BINDIR         := libcore/bin
ANDROID_OUT    := android/app/libs
GEO_ASSETS_DIR := assets/core
DL_DIR         := .cache/downloads

ifeq ($(CHANNEL),prod)
	CORE_URL := https://github.com/hiddify/hiddify-core/releases/download/v$(core.version)
	TARGET   := lib/main_prod.dart
	FLUTTER_OPTIMIZE := --release --obfuscate --split-debug-info=build/debug-info --tree-shake-icons --extra-front-end-options=--native-assets
else
	CORE_URL := https://github.com/hiddify/hiddify-core/releases/download/draft
	TARGET   := lib/main.dart
	FLUTTER_OPTIMIZE := --debug
endif

DART_DEFINES := $(if $(SENTRY_DSN),--dart-define sentry_dsn=$(SENTRY_DSN),) \
                --dart-define-from-file=config.json \
                --dart-define=build_channel=$(CHANNEL)

ifeq ($(OS),Windows_NT)
	SHELL := powershell.exe
	.SHELLFLAGS := -NoProfile -Command
	MKDIR = if (-not (Test-Path "$1")) { New-Item -ItemType Directory -Force "$1" | Out-Null }
	RM_RF = if (Test-Path "$1") { Remove-Item -Recurse -Force "$1" -ErrorAction SilentlyContinue }
	DOWNLOAD = if (-not (Test-Path "$2")) { curl.exe -fL --retry 5 --retry-connrefused "$1" -o "$2" }
	EXTRACT = tar -xzf "$1" -C "$2"
	CHECK_CMD = if (-not (Get-Command "$1" -ErrorAction SilentlyContinue)) { throw "Error: $1 not found" }
	COPY_DLL = if (Test-Path "$1") { Copy-Item -Force "$1" "$2" } else { throw "Fatal: DLL not found at $1" }
	GO_BUILD_CMD = $$ver="$(core.version)"; $$date=(Get-Date).ToString('yyyy-MM-ddTHH:mm:sszzz'); cd libcore; go build -buildmode=c-shared -pgo=auto -trimpath -ldflags "-s -w -X main.version=$$ver -X main.buildTime=$$date -extldflags=-Wl,--gc-sections" -o bin/libcore.dll ./mobile
else
	SHELL := /bin/bash
	MKDIR = mkdir -p "$1"
	RM_RF = rm -rf "$1"
	DOWNLOAD = if [ ! -f "$2" ]; then curl -fL --retry 5 --retry-all-errors "$1" -o "$2"; fi
	EXTRACT = tar -xzf "$1" -C "$2"
	CHECK_CMD = command -v "$1" >/dev/null 2>&1 || { echo "Error: $1 not found"; exit 1; }
	COPY_DLL = if [ -f "$1" ]; then cp -f "$1" "$2"; else echo "Fatal: DLL not found at $1"; exit 1; fi
	GO_BUILD_CMD = date_val=$$(date +%FT%T%z); cd libcore && go build -buildmode=c-shared -pgo=auto -trimpath -ldflags "-s -w -X main.version=$(core.version) -X main.buildTime=$$date_val -extldflags=-Wl,--gc-sections" -o bin/libcore.dll ./mobile
endif

.PHONY: all check-env get gen translate prepare windows-libs android-libs protos clean

all: check-env prepare

check-env:
	@$(call CHECK_CMD,flutter)
	@$(call CHECK_CMD,go)
	@$(call CHECK_CMD,tar)
	@test -n "$(strip $(core.version))" || (echo "Error: core.version is empty"; exit 1)

get:
	flutter pub get

gen:
	dart run build_runner build --delete-conflicting-outputs

translate:
	dart run slang

prepare: check-env get gen translate

android-prepare: get-geo-assets prepare android-libs

protos:
	$(MAKE) -C libcore -f Makefile protos
	protoc --dart_out=grpc:lib/singbox/generated --proto_path=libcore/protos libcore/protos/*.proto

android-release:
	flutter build apk --target $(TARGET) $(DART_DEFINES) $(FLUTTER_OPTIMIZE) --target-platform android-arm64,android-x64 --split-per-abi

windows-release: windows-libs
	dart pub global run fastforge:fastforge package --platform windows --targets exe,msix --build-target $(TARGET) $(DART_DEFINES)

get-geo-assets:
	@$(call MKDIR,$(GEO_ASSETS_DIR))
	@$(call DOWNLOAD,$(GEOIP_URL),$(GEO_ASSETS_DIR)/geoip.db)
	@$(call DOWNLOAD,$(GEOSITE_URL),$(GEO_ASSETS_DIR)/geosite.db)

android-libs:
	@$(call MKDIR,$(DL_DIR))
	@$(call MKDIR,$(ANDROID_OUT))
	@$(call DOWNLOAD,$(CORE_URL)/$(CORE_NAME)-android.tar.gz,$(DL_DIR)/$(CORE_NAME)-android.tar.gz)
	@$(call EXTRACT,$(DL_DIR)/$(CORE_NAME)-android.tar.gz,$(ANDROID_OUT)/)

windows-libs:
	@$(call MKDIR,$(BINDIR))
	@$(GO_BUILD_CMD)
	@$(call COPY_DLL,$(BINDIR)/libcore.dll,windows/runner/libcore.dll)

clean:
	flutter clean
	@$(call RM_RF,$(BINDIR))
	@$(call RM_RF,$(DL_DIR))
	@$(call RM_RF,build)
