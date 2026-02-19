
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

RUN wget -O /usr/local/bin/appimagetool "https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage" && \
    chmod +x /usr/local/bin/appimagetool

RUN mkdir -p /root/develop && \
    git clone https://github.com/flutter/flutter.git -b stable /root/develop/flutter

ENV PATH="/root/develop/flutter/bin:/root/.pub-cache/bin:${PATH}"

RUN git config --global --add safe.directory /root/develop/flutter && \
    flutter config --no-analytics && \
    dart pub global activate fastforge

ENV APPIMAGE_EXTRACT_AND_RUN=1
WORKDIR /app