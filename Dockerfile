
# ==============================================================
#  ⚠️  USAGE: TRIGGERED BY MAKEFILE
#  This file is executed via the 'linux-release-docker' command.
# ==============================================================

FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

COPY linux_deps.list /tmp/linux_deps.list

RUN apt-get update && \
    DEPS=$(cat /tmp/linux_deps.list | tr -d '\r' | sed 's/#.*//g' | xargs) && \
    \
    apt-get install -y --no-install-recommends $DEPS && \
    \
    rm -rf /var/lib/apt/lists/* && \
    echo "root ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# appimagetool for this image's CPU (docker build --platform linux/arm64 builds the arm64 app)
# The AppImage magic (bytes 8-10 of the ELF header) is zeroed: qemu-user binfmt (an arm64 build on
# an x64 host) does not match ELF files with those bytes set and fails with "Exec format error".
# The tool runs the same; AppImages it makes are unaffected.
RUN wget -O /usr/local/bin/appimagetool "https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-$(uname -m).AppImage" && \
    printf '\0\0\0' | dd of=/usr/local/bin/appimagetool bs=1 seek=8 count=3 conv=notrunc 2>/dev/null && \
    chmod +x /usr/local/bin/appimagetool

RUN mkdir -p /root/develop && \
    git clone https://github.com/flutter/flutter.git -b stable /root/develop/flutter

ENV PATH="/root/develop/flutter/bin:/root/.pub-cache/bin:${PATH}"

RUN git config --global --add safe.directory /root/develop/flutter && \
    flutter config --no-analytics && \
    dart pub global activate fastforge

ENV APPIMAGE_EXTRACT_AND_RUN=1
WORKDIR /app