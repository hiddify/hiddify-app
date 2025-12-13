# .ONESHELL:
-include dependencies.properties

ifneq ($(wildcard .core-version),)
	core.version ?= $(strip $(file <.core-version))
endif
MKDIR := mkdir -p
RM  := rm -rf
SEP :=/

ifeq ($(OS),Windows_NT)
    ifeq ($(IS_GITHUB_ACTIONS),)
		MKDIR := mkdir
		RM := rmdir /s /q
		SEP:=\\
	endif
endif


BINDIR=libcore$(SEP)bin
ANDROID_OUT=android$(SEP)app$(SEP)libs
IOS_OUT=ios$(SEP)Frameworks
DESKTOP_OUT=libcore$(SEP)bin
GEO_ASSETS_DIR=assets$(SEP)core

CORE_PRODUCT_NAME=hiddify-core
CORE_NAME=$(CORE_PRODUCT_NAME)
LIB_NAME=libcore

ifeq ($(CHANNEL),prod)
	CORE_URL=https://github.com/hiddify/hiddify-core/releases/download/v$(core.version)
else
	CORE_URL=https://github.com/hiddify/hiddify-core/releases/download/draft
endif

ifeq ($(CHANNEL),prod)
	TARGET=lib/main_prod.dart
else
	TARGET=lib/main.dart
endif

BUILD_ARGS=--dart-define sentry_dsn=$(SENTRY_DSN)
DISTRIBUTOR_ARGS=--skip-clean --build-target $(TARGET) --build-dart-define sentry_dsn=$(SENTRY_DSN)



get:	
	flutter pub get

gen:
	dart run build_runner build --delete-conflicting-outputs

translate:
	dart run slang



prepare:
	@echo use the following commands to prepare the library for each platform:
	@echo    make android-prepare
	@echo    make windows-prepare

windows-prepare: get gen translate windows-libs
	
ios-prepare:
	$(error iOS platform is temporarily disabled (moved to disabled_platforms/ios))
	
macos-prepare:
	$(error macOS platform is temporarily disabled (moved to disabled_platforms/macos))
linux-prepare:
	$(error Linux platform is temporarily disabled (moved to disabled_platforms/linux))
linux-appimage-prepare:linux-prepare
linux-rpm-prepare:linux-prepare
linux-deb-prepare:linux-prepare

android-prepare: get-geo-assets get gen translate android-libs	
android-apk-prepare:android-prepare
android-aab-prepare:android-prepare


.PHONY: protos
protos:
	$(MAKE) -C libcore -f Makefile protos
	protoc --dart_out=grpc:lib/singbox/generated --proto_path=libcore/protos libcore/protos/*.proto

macos-install-dependencies:
	$(error macOS platform is temporarily disabled (moved to disabled_platforms/macos))

ios-install-dependencies:
	$(error iOS platform is temporarily disabled (moved to disabled_platforms/ios))
	

android-install-dependencies: 
	echo "nothing yet"
android-apk-install-dependencies: android-install-dependencies
android-aab-install-dependencies: android-install-dependencies

linux-install-dependencies:
	$(error Linux platform is temporarily disabled (moved to disabled_platforms/linux))

windows-install-dependencies:
	dart pub global activate fastforge

gen_translations: #generating missing translations using google translate
	$(if $(wildcard .github/sync_translate.sh),,$(error Missing .github/sync_translate.sh))
	cd .github && bash sync_translate.sh
	$(MAKE) translate

android-release: android-apk-release

android-apk-release:
	echo flutter build apk --target $(TARGET) $(BUILD_ARGS) --target-platform android-arm,android-arm64,android-x64 --split-per-abi --verbose  
	flutter build apk --target $(TARGET) $(BUILD_ARGS) --target-platform android-arm,android-arm64,android-x64 --verbose  
	ls -R build/app/outputs

android-aab-release:
	flutter build appbundle --target $(TARGET) $(BUILD_ARGS) --dart-define release=google-play
	ls -R build/app/outputs

windows-release:
	dart pub global run fastforge:fastforge package --flutter-build-args=verbose --platform windows --targets exe,msix $(DISTRIBUTOR_ARGS)

linux-release:
	$(error Linux platform is temporarily disabled (moved to disabled_platforms/linux))

macos-release:
	$(error macOS platform is temporarily disabled (moved to disabled_platforms/macos))

ios-release: #not tested
	$(error iOS platform is temporarily disabled (moved to disabled_platforms/ios))

android-libs:
	@$(MKDIR) $(ANDROID_OUT) || echo Folder already exists. Skipping...
	curl -L $(CORE_URL)/$(CORE_NAME)-android.tar.gz | tar xz -C $(ANDROID_OUT)/

android-apk-libs: android-libs
android-aab-libs: android-libs

windows-libs:
	$(MKDIR) $(DESKTOP_OUT) || echo Folder already exists. Skipping...
	$(MAKE) build-windows-libs
	copy /Y $(BINDIR)$(SEP)libcore.dll windows$(SEP)runner$(SEP)libcore.dll || cp -f $(BINDIR)/libcore.dll windows/runner/libcore.dll
	ls $(DESKTOP_OUT) || dir $(DESKTOP_OUT)$(SEP)
	

linux-libs:
	$(error Linux platform is temporarily disabled (moved to disabled_platforms/linux))


macos-libs:
	$(error macOS platform is temporarily disabled (moved to disabled_platforms/macos))

ios-libs: #not tested
	$(error iOS platform is temporarily disabled (moved to disabled_platforms/ios))

get-geo-assets:
	echo ""
	# curl -L https://github.com/SagerNet/sing-geoip/releases/latest/download/geoip.db -o $(GEO_ASSETS_DIR)/geoip.db
	# curl -L https://github.com/SagerNet/sing-geosite/releases/latest/download/geosite.db -o $(GEO_ASSETS_DIR)/geosite.db

build-headers:
	$(MAKE) -C libcore -f Makefile headers && mv $(BINDIR)/$(CORE_NAME)-headers.h $(BINDIR)/libcore.h

build-android-libs:
	$(MAKE) -C libcore -f Makefile android 
	mv $(BINDIR)/$(LIB_NAME).aar $(ANDROID_OUT)/

build-windows-libs:
	@$(MKDIR) $(BINDIR) || echo Folder already exists. Skipping...
	go -C libcore build -buildmode=c-shared -o bin/libcore.dll ./mobile
	
build-linux-libs:
	$(error Linux platform is temporarily disabled (moved to disabled_platforms/linux))

build-macos-libs:
	$(error macOS platform is temporarily disabled (moved to disabled_platforms/macos))

build-ios-libs:
	$(error iOS platform is temporarily disabled (moved to disabled_platforms/ios))

release: # Create a new tag for release.
	$(if $(wildcard .github/change_version.sh),,$(error Missing .github/change_version.sh))
	@CORE_VERSION=$(core.version) bash -c ".github/change_version.sh "



ios-temp-prepare: 
	$(error iOS platform is temporarily disabled (moved to disabled_platforms/ios))
	

