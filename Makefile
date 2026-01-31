-include dependencies.properties

ifneq ($(wildcard .core-version),)
	core.version ?= $(strip $(file <.core-version))
endif

MKDIR := mkdir -p
RM := rm -rf
SEP := /
SHELL := /bin/bash

ifeq ($(OS),Windows_NT)
  ifeq ($(IS_GITHUB_ACTIONS),)
    MKDIR := powershell -NoProfile -Command "New-Item -ItemType Directory -Force"
    RM := powershell -NoProfile -Command "Remove-Item -Recurse -Force"
    SEP := \\
    SHELL := powershell
  endif
endif

BINDIR := libcore$(SEP)bin
ANDROID_OUT := android$(SEP)app$(SEP)libs
GEO_ASSETS_DIR := assets$(SEP)core
CORE_NAME := hiddify-core

ifeq ($(CHANNEL),prod)
	CORE_URL := https://github.com/hiddify/hiddify-core/releases/download/v$(core.version)
	TARGET := lib/main_prod.dart
	BUILD_MODE := release
else
	CORE_URL := https://github.com/hiddify/hiddify-core/releases/download/draft
	TARGET := lib/main.dart
	BUILD_MODE := debug
endif

DART_DEFINES := --dart-define sentry_dsn=$(SENTRY_DSN) --dart-define-from-file=config.json
FLUTTER_OPTIMIZE := --obfuscate --split-debug-info=build/debug-info --tree-shake-icons
GO_LDFLAGS := -s -w -X 'main.version=$(core.version)' -X 'main.buildTime=$(shell date +%FT%T%z)'

.PHONY: all get gen translate prepare windows-libs android-libs protos clean

all: prepare

get:
	flutter pub get

gen:
	dart run build_runner build --delete-conflicting-outputs

translate:
	dart run slang

prepare: get gen translate
	@echo "Preparation complete for $(OS)"

windows-prepare: prepare windows-libs

android-prepare: get-geo-assets prepare android-libs

protos:
	$(MAKE) -C libcore -f Makefile protos
	protoc --dart_out=grpc:lib/singbox/generated --proto_path=libcore/protos libcore/protos/*.proto

android-release:
	flutter build apk --target $(TARGET) $(DART_DEFINES) $(FLUTTER_OPTIMIZE) --target-platform android-arm,android-arm64,android-x64 --split-per-abi

android-bundle:
	flutter build appbundle --target $(TARGET) $(DART_DEFINES) $(FLUTTER_OPTIMIZE)

windows-release:
	dart pub global run fastforge:fastforge package --platform windows --targets exe,msix --build-target $(TARGET) --build-dart-define sentry_dsn=$(SENTRY_DSN)

android-libs:
	@$(MKDIR) $(ANDROID_OUT)
	curl -L $(CORE_URL)/$(CORE_NAME)-android.tar.gz | tar xz -C $(ANDROID_OUT)/

windows-libs:
	@$(MKDIR) $(BINDIR)
	$(MAKE) build-windows-libs
	@powershell -NoProfile -Command "if (Test-Path '$(BINDIR)$(SEP)libcore.dll') { Copy-Item -Force '$(BINDIR)$(SEP)libcore.dll' 'windows\runner\libcore.dll' }"

build-windows-libs:
	cd libcore && go build -buildmode=c-shared -trimpath -ldflags="$(GO_LDFLAGS)" -o bin/libcore.dll ./mobile

get-geo-assets:
	@$(MKDIR) $(GEO_ASSETS_DIR)
	curl -L https://github.com/SagerNet/sing-geoip/releases/latest/download/geoip.db -o $(GEO_ASSETS_DIR)/geoip.db
	curl -L https://github.com/SagerNet/sing-geosite/releases/latest/download/geosite.db -o $(GEO_ASSETS_DIR)/geosite.db

clean:
	flutter clean
	$(RM) $(BINDIR)
	$(RM) build$(SEP)
