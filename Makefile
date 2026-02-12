# .ONESHELL:
include dependencies.properties

# --- Log Colors ---
blue   := \033[1;34m
green  := \033[1;92m
yellow := \033[1;33m
reset  := \033[0m
# --- Log helpers ---
# Usage: $(BLUE) <text> $(DONE)
BLUE   := echo -e "$(blue)
GREEN  := echo -e "$(green)
YELLOW := echo -e "$(yellow)
DONE := $(reset)"

MKDIR := mkdir -p
RM  := rm -rf
SEP :=/

ifeq ($(OS),Windows_NT)
    ifeq ($(IS_GITHUB_ACTIONS),)
		# MKDIR := -mkdir
		RM := rmdir /s /q
		# SEP:=\\
	endif
endif


# Define sed command based on the OS
ifeq ($(OS),Windows_NT)
    # Windows (Assume Git Bash or similar sed is available, or standard syntax)
    SED := sed -i
else
	ifeq ($(shell uname),Darwin) # macOS
    	SED :=sed -i ''
	else # Linux
    	SED :=sed -i
	endif
endif


BINDIR=hiddify-core$(SEP)bin
ANDROID_OUT=android$(SEP)app$(SEP)libs
IOS_OUT=ios$(SEP)Frameworks
DESKTOP_OUT=hiddify-core$(SEP)bin
GEO_ASSETS_DIR=assets$(SEP)core

CORE_PRODUCT_NAME=hiddify-core
CORE_NAME=hiddify-lib
LIB_NAME=hiddify-core

ifeq ($(CHANNEL),prod)
	CORE_URL=https://github.com/hiddify/hiddify-next-core/releases/download/v$(core.version)
else
	CORE_URL=https://github.com/hiddify/hiddify-next-core/releases/download/draft
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
	@echo    make linux-prepare 
	@echo    make macos-prepare
	@echo    make ios-prepare

common-prepare:  get gen translate
windows-prepare: common-prepare windows-libs
	
ios-prepare: common-prepare ios-libs 
	cd ios; pod repo update; pod install;echo "done ios prepare"
	
macos-prepare: common-prepare macos-libs
linux-prepare: common-prepare linux-libs


linux-amd64-prepare: common-prepare linux-amd64-libs
linux-arm64-prepare: common-prepare linux-arm64-libs
linux-amd64-musl-prepare: common-prepare linux-amd64-musl-libs
linux-arm64-musl-prepare: common-prepare linux-arm64-musl-libs


linux-appimage-prepare:linux-prepare
linux-rpm-prepare:linux-prepare
linux-deb-prepare:linux-prepare

android-prepare:common-prepare android-libs	
android-apk-prepare:android-prepare
android-aab-prepare:android-prepare

.PHONY: generate_kotlin_protos
generate_kotlin_protos: 
	# Run protoc to generate Kotlin files
	# protoc \
	# 	--proto_path=hiddify-core/ \
	# 	--java_out=./android/app/src/main/java/ \
	# 	--grpc-java_out=./android/app/src/main/java/ \
	# 	$(shell find hiddify-core/v2 hiddify-core/extension -name "*.proto")
	rsync -av --delete \
		--include='*/' \
		--include='*.proto' \
		--exclude='*' \
		hiddify-core/v2 hiddify-core/extension ./android/app/src/main/protos/
	# # Find .proto files and update package declarations
	# find "./android/app/src/main/java/com/hiddify/hiddify/protos" -type f -name "*.java" | while read -r proto_file; do \
	#     if grep -q "^package " "$$proto_file"; then \
	#         $(SED) 's/^package \([\w\.]*\)/package com.hiddify.hiddify.protos.\1/g' "$$proto_file"; \
	#     fi \
	# done

generate_go_protoc:
	make -C hiddify-core -f Makefile protos
	echo "SED: $(SED)"
generate_dart_protoc:
	mkdir -p lib/hiddifycore/generated
	protoc --dart_out=grpc:lib/hiddifycore/generated --proto_path=hiddify-core/  $(shell find hiddify-core/v2 hiddify-core/extension -name "*.proto") 	google/protobuf/timestamp.proto ; \

.PHONY: protos
protos: generate_go_protoc generate_kotlin_protos generate_dart_protoc
	
	
	

macos-install-deps:
	brew install create-dmg tree 
	npm install -g appdmg
	dart pub global activate fastforge

ios-install-deps: 
	if [ "$(flutter)" = "true" ]; then \
		curl -L -o ~/Downloads/flutter_macos_3.19.3-stable.zip https://storage.googleapis.com/flutter_infra_release/releases/stable/macos/flutter_macos_3.22.3-stable.zip; \
		mkdir -p ~/develop; \
		cd ~/develop; \
		unzip ~/Downloads/flutter_macos_3.22.3-stable.zip; \
		export PATH="$$PATH:$$HOME/develop/flutter/bin"; \
		echo 'export PATH="$$PATH:$$HOME/develop/flutter/bin"' >> ~/.zshrc; \
		export PATH="$PATH:$HOME/develop/flutter/bin"; \
		echo 'export PATH="$PATH:$HOME/develop/flutter/bin"' >> ~/.zshrc; \
		curl -sSL https://rvm.io/mpapis.asc | gpg --import -; \
		curl -sSL https://rvm.io/pkuczynski.asc | gpg --import -; \
		curl -sSL https://get.rvm.io | bash -s stable; \
		brew install openssl@1.1; \
		PKG_CONFIG_PATH=$(brew --prefix openssl@1.1)/lib/pkgconfig rvm install 2.7.5; \
		sudo gem install cocoapods -V; \
	fi
	brew install create-dmg tree 
	npm install -g appdmg
	
	dart pub global activate fastforge
	

android-install-deps: 
	dart pub global activate fastforge
android-apk-install-deps: android-install-deps
android-aab-install-deps: android-install-deps
# loads the package list from linux_deps.list
LINUX_DEPS = $(shell grep -vE '^\s*#|^\s*$$' linux_deps.list)
# reads the Flutter version from pubspec.yaml
REQUIRED_VER = $(shell sed -n '/environment:/,/flutter:/ s/.*flutter:[[:space:]]*//p' pubspec.yaml | tr -d " '^\"")

linux-amd64-install-deps:linux-install-deps
linux-amd64-musl-install-deps:linux-install-deps
linux-arm64-install-deps:linux-install-deps
linux-arm64-musl-install-deps:linux-install-deps

linux-install-deps:
	@$(BLUE)Installing Debian/Ubuntu dependencies...$(DONE)
	sudo apt-get update -y
	sudo apt-get install -y $(LINUX_DEPS)
#	loading fuce kernel module
	@$(BLUE)Loading fuce kernel module$(DONE)
	sudo modprobe fuse
# 	tools for appimage
	@$(BLUE)Installing appimagetool$(DONE)
	if [ "$$(uname -m)" = "aarch64" ]; then \
		wget -O /tmp/appimagetool "https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-aarch64.AppImage"; \
	else \
		wget -O /tmp/appimagetool "https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage"; \
	fi
	chmod +x /tmp/appimagetool
	sudo mv /tmp/appimagetool /usr/local/bin/
#   cloning flutter sdk
	@$(BLUE)Cloning Flutter SDK$(DONE); \
	mkdir -p ~/develop; \
	cd ~/develop; \
	\
	if [ ! -d "flutter/.git" ]; then \
		$(BLUE)Flutter not found. cloning stable channel$(DONE); \
		rm -rf flutter; \
		git clone https://github.com/flutter/flutter.git -b stable flutter; \
	fi; \
	\
	git config --global --add safe.directory $$HOME/develop/flutter; \
	\
	export PATH="$$HOME/develop/flutter/bin:$$PATH"; \
	if ! grep -q 'flutter/bin' ~/.bashrc; then \
		echo 'export PATH="$$HOME/develop/flutter/bin:$$PATH"' >> ~/.bashrc; \
	fi
# 	syncing flutter version
	$(MAKE) linux-flutter-sync
# 	installing fastforge https://pub.dev/packages/fastforge
	@$(BLUE)Installing fastforge$(DONE); \
	export PATH="$$HOME/develop/flutter/bin:$$HOME/.pub-cache/bin:$$PATH"; \
	if ! grep -q '.pub-cache/bin' ~/.bashrc; then \
		echo 'export PATH="$$HOME/.pub-cache/bin:$$PATH"' >> ~/.bashrc; \
	fi; \
	dart pub global activate fastforge; \
	dart pub global activate protoc_plugin; \
	echo ""; \
	echo "============================================================"; \
	echo "NOTE: After first setup, use the following command to update the PATH"; \
	echo "source ~/.bashrc"; \
	echo "============================================================"

# 	syncing 'flutter sdk' version with pubspec.yaml flutter version
linux-flutter-sync:
	@$(BLUE)Syncing Flutter version with pubspec.yaml flutter version$(DONE); \
	export PATH="$$HOME/develop/flutter/bin:$$PATH"; \
	$(BLUE)Downloading Flutter SDK components...$(DONE); \
	flutter --version > /dev/null; \
	\
	$(BLUE)Checking Flutter version...$(DONE); \
	CURRENT_VER=$$(flutter --version | head -n 1 | awk '{print $$2}'); \
	$(BLUE)Target: $(REQUIRED_VER) | Current: $$CURRENT_VER$(DONE); \
	\
	if [ "$$CURRENT_VER" != "$(REQUIRED_VER)" ]; then \
		$(BLUE)Version mismatch! switching to $(REQUIRED_VER)...$(DONE); \
		cd ~/develop/flutter; \
		git fetch --tags; \
		git checkout $(REQUIRED_VER); \
		$(BLUE)Switched to $(REQUIRED_VER)$(DONE); \
		flutter doctor; \
	else \
		$(GREEN)Flutter SDK is ready.$(DONE); \
	fi

windows-install-deps:
	dart pub global activate fastforge
# 	choco install innosetup -y
	
gen_translations: #generating missing translations using google translate
	cd .github && bash sync_translate.sh
	make translate

android-release: android-apk-release android-aab-release

android-apk-release:
	fastforge package \
	  --platform android \
	  --targets apk \
	  --skip-clean \
	  --build-target=$(TARGET) \
	  --build-target-platform=android-arm,android-arm64,android-x64 \
	  --build-dart-define=sentry_dsn=$(SENTRY_DSN)
	ls -R build/app/outputs

android-aab-release:
	fastforge package \
	  --platform android \
	  --targets aab \
	  --skip-clean \
	  --build-target=$(TARGET) \
	  --build-dart-define=sentry_dsn=$(SENTRY_DSN) \
	  --build-dart-define=release=google-play

windows-release: windows-zip-release windows-exe-release windows-msix-release

windows-zip-release:
	fastforge package \
	  --platform windows \
	  --targets zip \
	  --skip-clean \
	  --build-target=$(TARGET) \
	  --build-dart-define=sentry_dsn=$(SENTRY_DSN) \
	  --build-dart-define=portable=true
	@FULL_PATH=$$(ls dist/*/*.zip | head -n 1); \
	ZIP_DIR=$$(dirname "$$FULL_PATH"); \
	ZIP_FILE=$$(basename "$$FULL_PATH"); \
	FILE_NAME=$${ZIP_FILE%.*}; \
	$(YELLOW)Post-processing Windows portable$(DONE); \
	cd "$$ZIP_DIR"; \
	$(BLUE)Extracting and Repacking...$(DONE); \
	mkdir -p Hiddify; \
	unzip -q "$$ZIP_FILE" -d Hiddify/; \
	rm "$$ZIP_FILE"; \
	tar -a -cf "$$FILE_NAME.zip" Hiddify; \
	rm -rf Hiddify; \
	$(GREEN)Successful$(DONE)

windows-exe-release:
	fastforge package \
	  --platform windows \
	  --targets exe \
	  --skip-clean \
	  --build-target=$(TARGET) \
	  --build-dart-define=sentry_dsn=$(SENTRY_DSN)

windows-msix-release:
	fastforge package \
	  --platform windows \
	  --targets msix \
	  --skip-clean \
	  --build-target=$(TARGET) \
	  --build-dart-define=sentry_dsn=$(SENTRY_DSN)

linux-release: linux-deb-release linux-appimage-release

linux-amd64-release: linux-release
linux-arm64-release: linux-release
linux-amd64-musl-release: linux-release 
linux-arm64-musl-release: linux-release


linux-deb-release:
	fastforge package \
	--platform linux \
	--targets deb \
	--skip-clean \
	--build-target=$(TARGET) \
	--build-dart-define=sentry_dsn=$(SENTRY_DSN)


# ==============================================================================
# REFERENCE: MANUAL LIBRARY BUNDLING (INJECTION)
# ==============================================================================
# Use this method only if you need to manually force specific shared libraries 
# (e.g., libcurl.so.4) into the AppImage bundle.
#
# IMPLEMENTATION STEPS:
#
# 1. PRE-BUILD SCRIPT (Add to Makefile before build command):
#    Create a temporary directory and copy the target library there.
#    ---------------------------------------------------------------------------
#    mkdir -p linux/bundled_libs
#    cp /usr/lib/x86_64-linux-gnu/libcurl.so.4 linux/bundled_libs/
#    ---------------------------------------------------------------------------
#
# 2. CMAKE CONFIGURATION (Add to linux/CMakeLists.txt):
#    Instruct CMake to include the copied file in the final bundle.
#    ---------------------------------------------------------------------------
#    install(FILES "${CMAKE_CURRENT_SOURCE_DIR}/bundled_libs/libcurl.so.4"
#       DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
#       COMPONENT Runtime)
#    ---------------------------------------------------------------------------
#
# ! WARNING !
# This approach is generally DISCOURAGED. Manually bundling libraries can lead to
# "Dependency Hell," where bundled libs conflict with system libraries or have
# their own unresolved dependencies. It increases maintenance cost and may cause
# runtime instability. Use only for specific edge cases where standard linking fails.
# ==============================================================================
linux-appimage-release:
	fastforge package \
	--platform linux \
	--targets appimage \
	--skip-clean \
	--build-target=$(TARGET) \
	--build-dart-define=sentry_dsn=$(SENTRY_DSN)
	@$(YELLOW)Post-processing AppImage$(DONE); \
	$(BLUE)Extracting AppImage$(DONE); \
	cd dist/* && ./*.AppImage --appimage-extract > /dev/null; \
	$(BLUE)Replacing AppRun$(DONE); \
	cp ../../linux/packaging/appimage/AppRun squashfs-root/AppRun; \
	$(BLUE)Granting permissions$(DONE); \
	chmod +x squashfs-root/AppRun; \
	$(BLUE)Adding StartupWMClass to hiddify.desktop$(DONE); \
	sed -i '/^\[Desktop Entry\]/a StartupWMClass=app.hiddify.com' "squashfs-root/hiddify.desktop"; \
	$(BLUE)Removing old AppImage$(DONE); \
	rm *.AppImage; \
	$(BLUE)Rebuilding AppImage$(DONE); \
	ARCH=x86_64 appimagetool --no-appstream squashfs-root Hiddify.AppImage > /dev/null; \
	$(BLUE)Cleaning up squashfs$(DONE); \
	rm -rf squashfs-root; \
	$(YELLOW)Creating Portable Package$(DONE); \
	PKG_DIR_NAME="hiddify-linux-appimage"; \
	$(BLUE)Creating dir: $$PKG_DIR_NAME$(DONE); \
	mkdir -p "$$PKG_DIR_NAME"; \
	$(BLUE)Moving and Renaming to Hiddify.AppImage$(DONE); \
	mv "Hiddify.AppImage" "$$PKG_DIR_NAME/Hiddify.AppImage"; \
	$(BLUE)Creating Portable Home directory$(DONE); \
	mkdir -p "$$PKG_DIR_NAME/Hiddify.AppImage.home"; \
	$(BLUE)Compressing to .tar.gz$(DONE); \
	tar -czf "$$PKG_DIR_NAME.tar.gz" -C . "$$PKG_DIR_NAME"; \
	$(BLUE)Removing intermediate directory$(DONE); \
	rm -rf "$$PKG_DIR_NAME"; \
	$(GREEN)Successful$(DONE)

DOCKER_IMAGE_NAME := hiddify-linux-builder
DOCKER_FLUTTER_VOL := hiddify-flutter-sdk-cache
DOCKER_PUB_VOL := hiddify-pub-cache

ifeq ($(OS),Windows_NT)
    FIX_OWNERSHIP := echo \"Windows detected: Skipping chown\"
else
    FIX_OWNERSHIP := chown -R $(shell id -u):$(shell id -g) /host/dist_docker
endif

DOCKER_CMD := \
	set -e; \
	echo '** Copying source code to container...'; \
	mkdir -p /app; \
	cp -r /host/. /app/; \
	cd /app; \
	make linux-flutter-sync; \
	make linux-prepare; \
	echo '** Building Release (linux-release)...'; \
	make linux-release; \
	echo '** Copying artifacts to host...'; \
	rm -rf /host/dist_docker; \
	if [ -d \"dist\" ]; then \
		cp -r dist /host/dist_docker; \
		echo '** Fixing permissions for dist_docker...'; \
		$(FIX_OWNERSHIP); \
	else \
		echo 'Error: dist folder not found!'; \
		exit 1; \
	fi;

linux-docker-release:
	@$(BLUE)Cleaning main project to reduce context size$(DONE)
	flutter clean
	
	@$(BLUE)Building docker image (Cached)$(DONE)
	docker build -t $(DOCKER_IMAGE_NAME) -f Dockerfile .
	
	@$(BLUE)Ensuring cache volumes exist$(DONE)
	docker volume create $(DOCKER_FLUTTER_VOL) || true
	docker volume create $(DOCKER_PUB_VOL) || true

	@$(YELLOW)Running build inside container$(DONE)
	@docker run --rm \
		-v "$(CURDIR)://host" \
		-v $(DOCKER_FLUTTER_VOL)://root/develop/flutter \
		-v $(DOCKER_PUB_VOL)://root/.pub-cache \
		-e APPIMAGE_EXTRACT_AND_RUN=1 \
		$(DOCKER_IMAGE_NAME) \
		//bin/bash -c "$(DOCKER_CMD)"

	@$(GREEN)Successful. Output is in 'dist_docker' folder.$(DONE)

macos-release:
	fastforge package --platform macos --targets dmg,pkg $(DISTRIBUTOR_ARGS)

ios-release: #not tested
	fastforge package --platform ios --targets ipa --build-export-options-plist  ios/exportOptions.plist $(DISTRIBUTOR_ARGS)

android-libs:
	$(MKDIR) $(ANDROID_OUT) || echo Folder already exists. Skipping...
	curl -L $(CORE_URL)/$(CORE_NAME)-android.tar.gz | tar xz -C $(ANDROID_OUT)/

android-apk-libs: android-libs
android-aab-libs: android-libs

windows-libs:
	$(MKDIR) $(DESKTOP_OUT) || echo Folder already exists. Skipping...
	curl -L $(CORE_URL)/$(CORE_NAME)-windows-amd64.tar.gz | tar xz -C $(DESKTOP_OUT)/
	ls $(DESKTOP_OUT) || dir $(DESKTOP_OUT)/
	

linux-amd64-libs:
	mkdir -p $(DESKTOP_OUT)
	curl -L $(CORE_URL)/$(CORE_NAME)-linux-amd64.tar.gz | tar xz -C $(DESKTOP_OUT)/

linux-arm64-libs:
	mkdir -p $(DESKTOP_OUT)
	curl -L $(CORE_URL)/$(CORE_NAME)-linux-arm64.tar.gz | tar xz -C $(DESKTOP_OUT)/

linux-amd64-musl-libs:
	mkdir -p $(DESKTOP_OUT)
	curl -L $(CORE_URL)/$(CORE_NAME)-linux-amd64-musl.tar.gz | tar xz -C $(DESKTOP_OUT)/

linux-arm64-musl-libs:
	mkdir -p $(DESKTOP_OUT)
	curl -L $(CORE_URL)/$(CORE_NAME)-linux-arm64-musl.tar.gz | tar xz -C $(DESKTOP_OUT)/


macos-libs:
	mkdir -p  $(DESKTOP_OUT) 
	curl -L $(CORE_URL)/$(CORE_NAME)-macos.tar.gz | tar xz -C $(DESKTOP_OUT)

ios-libs: #not tested
	mkdir -p $(IOS_OUT)
	rm -rf $(IOS_OUT)/HiddifyCore.xcframework
	curl -L $(CORE_URL)/$(CORE_NAME)-ios.tar.gz | tar xz -C "$(IOS_OUT)"

get-geo-assets:
	echo ""
	# curl -L https://github.com/SagerNet/sing-geoip/releases/latest/download/geoip.db -o $(GEO_ASSETS_DIR)/geoip.db
	# curl -L https://github.com/SagerNet/sing-geosite/releases/latest/download/geosite.db -o $(GEO_ASSETS_DIR)/geosite.db

build-headers:
	make -C hiddify-core -f Makefile headers && mv $(BINDIR)/$(CORE_NAME)-headers.h $(BINDIR)/hiddify-core.h

build-android-libs:
	make -C hiddify-core -f Makefile android 
	mv $(BINDIR)/$(LIB_NAME).aar $(ANDROID_OUT)/

build-windows-libs:
	make -C hiddify-core -f Makefile windows-amd64

build-linux-libs:
	make -C hiddify-core -f Makefile linux-amd64 

build-macos-libs:
	make -C hiddify-core -f Makefile macos

build-ios-libs: 
	rm -rf $(IOS_OUT)/HiddifyCore.xcframework 
	make -C hiddify-core -f Makefile ios  
	mv $(BINDIR)/HiddifyCore.xcframework $(IOS_OUT)/HiddifyCore.xcframework

release: # Create a new tag for release.
	@CORE_VERSION=$(core.version) bash -c ".github/change_version.sh "



ios-temp-prepare: 
	make ios-prepare
	flutter build ios-framework
	cd ios
	pod install
	