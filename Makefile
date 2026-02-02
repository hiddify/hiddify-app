# .ONESHELL:
include dependencies.properties
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
ifeq ($(shell uname),Darwin) # macOS
    SED :=sed -i ''
else # Linux
    SED :=sed -i
endif


BINDIR=hiddify-core$(SEP)bin
ANDROID_OUT=android$(SEP)app$(SEP)libs
IOS_OUT=ios$(SEP)Frameworks
DESKTOP_OUT=hiddify-core$(SEP)bin
GEO_ASSETS_DIR=assets$(SEP)core

CORE_PRODUCT_NAME=hiddify-core
CORE_NAME=$(CORE_PRODUCT_NAME)
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

windows-prepare: get gen translate windows-libs
	
ios-prepare: get-geo-assets get gen translate ios-libs 
	cd ios; pod repo update; pod install;echo "done ios prepare"
	
macos-prepare: get-geo-assets get gen translate macos-libs
linux-prepare: get-geo-assets get gen translate linux-libs
linux-appimage-prepare:linux-prepare
linux-rpm-prepare:linux-prepare
linux-deb-prepare:linux-prepare

android-prepare: get-geo-assets get gen translate android-libs	
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
		hiddify-core/{v2,extension} ./android/app/src/main/protos/
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
	
	
	

macos-install-dependencies:
	brew install create-dmg tree 
	npm install -g appdmg
	dart pub global activate flutter_distributor

ios-install-dependencies: 
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
	
	dart pub global activate flutter_distributor
	

android-install-dependencies: 
	echo "nothing yet"
android-apk-install-dependencies: android-install-dependencies
android-aab-install-dependencies: android-install-dependencies

linux-install-dependencies:
	if [ "$(flutter)" = "true" ]; then \
		mkdir -p ~/develop; \
		cd ~/develop; \
		wget -O flutter_linux-stable.tar.xz https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.19.4-stable.tar.xz; \
		tar xf flutter_linux-stable.tar.xz; \
		rm flutter_linux-stable.tar.xz;\
		export PATH="$$PATH:$$HOME/develop/flutter/bin"; \
		echo 'export PATH="$$PATH:$$HOME/develop/flutter/bin"' >> ~/.bashrc; \
	fi
	PATH="$$PATH":"$$HOME/.pub-cache/bin"
	echo 'export PATH="$$PATH:$$HOME/.pub-cache/bin"' >>~/.bashrc
	sudo apt-get update
	sudo apt install -y clang ninja-build libcurl4-openssl-dev pkg-config cmake libgtk-3-dev locate ninja-build pkg-config libglib2.0-dev libgio2.0-cil-dev libayatana-appindicator3-dev fuse rpm patchelf file appstream 
	
	
	sudo modprobe fuse
	wget -O appimagetool "https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage"
	chmod +x appimagetool
	sudo mv appimagetool /usr/local/bin/

	dart pub global activate --source git  https://github.com/hiddify/flutter_distributor --git-path packages/flutter_distributor

windows-install-dependencies:
	dart pub global activate flutter_distributor 
	
gen_translations: #generating missing translations using google translate
	cd .github && bash sync_translate.sh
	make translate

android-release: android-apk-release

android-apk-release:
	flutter build apk --target $(TARGET) $(BUILD_ARGS) --target-platform android-arm,android-arm64,android-x64 
	#--verbose  
	ls -R build/app/outputs

android-aab-release:
	flutter build appbundle --target $(TARGET) $(BUILD_ARGS) --dart-define release=google-play
	ls -R build/app/outputs

windows-release:
	flutter_distributor package --flutter-build-args=verbose --platform windows --targets exe,msix $(DISTRIBUTOR_ARGS)

linux-release: 
	flutter_distributor package --flutter-build-args=verbose --platform linux --targets deb,appimage $(DISTRIBUTOR_ARGS)

macos-release:
	flutter_distributor package --platform macos --targets dmg,pkg $(DISTRIBUTOR_ARGS)

ios-release: #not tested
	flutter_distributor package --platform ios --targets ipa --build-export-options-plist  ios/exportOptions.plist $(DISTRIBUTOR_ARGS)

android-libs:
	$(MKDIR) $(ANDROID_OUT) || echo Folder already exists. Skipping...
	curl -L $(CORE_URL)/$(CORE_NAME)-android.tar.gz | tar xz -C $(ANDROID_OUT)/

android-apk-libs: android-libs
android-aab-libs: android-libs

windows-libs:
	$(MKDIR) $(DESKTOP_OUT) || echo Folder already exists. Skipping...
	curl -L $(CORE_URL)/$(CORE_NAME)-windows-amd64.tar.gz | tar xz -C $(DESKTOP_OUT)/
	ls $(DESKTOP_OUT) || dir $(DESKTOP_OUT)/
	

linux-libs:
	mkdir -p $(DESKTOP_OUT)
	curl -L $(CORE_URL)/$(CORE_NAME)-linux-amd64.tar.gz | tar xz -C $(DESKTOP_OUT)/


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
	