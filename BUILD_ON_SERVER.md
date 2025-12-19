# 🚀 Инструкция по сборке на Ubuntu сервере

## 📋 Результаты попытки сборки на текущем сервере

### ✅ Что удалось сделать:
- ✅ Flutter 3.24.3 установлен
- ✅ Нативные библиотеки скачаны (hiddify-core.aar, 107MB)
- ✅ Flutter зависимости установлены (`flutter pub get`)
- ✅ Java 21 доступна

### ❌ Проблема:
- ❌ Сервер имеет сетевые ограничения
- ❌ Android SDK компоненты не могут быть скачаны (блокируется dl.google.com)
- ❌ Flutter не может завершить сборку без Android SDK

---

## 🔧 Решения

### Вариант 1: Сборка на локальной машине (РЕКОМЕНДУЕТСЯ)

Если у вас есть Ubuntu/Linux машина с интернетом:

```bash
# 1. Установить Flutter
wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.3-stable.tar.xz
tar xf flutter_linux_3.24.3-stable.tar.xz
export PATH="$PATH:`pwd`/flutter/bin"

# 2. Клонировать репозиторий
git clone https://github.com/ivanstarwars8/hiddify-work.git
cd hiddify-work
git checkout claude/audit-android-app-MsTY1

# 3. Скачать нативные библиотеки (если еще не скачаны)
make android-libs

# 4. Установить зависимости
flutter pub get

# 5. Собрать APK
flutter build apk --release

# Готово! APK в: build/app/outputs/flutter-apk/app-release.apk
```

---

### Вариант 2: Использование Docker

Создайте `Dockerfile`:

```dockerfile
FROM ubuntu:24.04

# Установка зависимостей
RUN apt-get update && apt-get install -y \\
    curl git wget unzip xz-utils zip libglu1-mesa \\
    openjdk-17-jdk && rm -rf /var/lib/apt/lists/*

# Установка Flutter
ENV FLUTTER_HOME=/opt/flutter
ENV PATH="$FLUTTER_HOME/bin:$PATH"
RUN wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.3-stable.tar.xz \\
    && tar xf flutter_linux_3.24.3-stable.tar.xz -C /opt \\
    && rm flutter_linux_3.24.3-stable.tar.xz \\
    && flutter --version

WORKDIR /app
COPY . /app

# Сборка
RUN make android-libs \\
    && flutter pub get \\
    && flutter build apk --release

# APK будет в /app/build/app/outputs/flutter-apk/
```

Сборка:
```bash
docker build -t go-bull-build .
docker run --rm -v $(pwd)/build:/app/build go-bull-build
```

---

### Вариант 3: GitHub Actions (CI/CD)

Создайте `.github/workflows/build-android.yml`:

```yaml
name: Build Android APK

on:
  push:
    branches: [ main, claude/* ]
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3

      - name: Setup Java
        uses: actions/setup-java@v3
        with:
          distribution: 'zulu'
          java-version: '17'

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.3'
          channel: 'stable'

      - name: Download native libraries
        run: make android-libs

      - name: Get dependencies
        run: flutter pub get

      - name: Build APK
        run: flutter build apk --release

      - name: Upload APK
        uses: actions/upload-artifact@v3
        with:
          name: go-bull-release
          path: build/app/outputs/flutter-apk/app-release.apk
```

---

### Вариант 4: Облачная сборка (Codemagic, Bitrise)

**Codemagic** (бесплатно для open source):
1. Зарегистрироваться на https://codemagic.io
2. Подключить GitHub репозиторий
3. Использовать конфигурацию:

```yaml
# codemagic.yaml
workflows:
  android-build:
    name: Android Build
    max_build_duration: 60
    environment:
      flutter: 3.24.3
      java: 17
    scripts:
      - name: Download libraries
        script: make android-libs
      - name: Build APK
        script: flutter build apk --release
    artifacts:
      - build/app/outputs/**/*.apk
```

---

## 💻 Сборка на Windows

Если у вас Windows:

```powershell
# 1. Установить Flutter
# Скачать с https://docs.flutter.dev/get-started/install/windows

# 2. Установить Android Studio (для Android SDK)
# Скачать с https://developer.android.com/studio

# 3. Клонировать репозиторий
git clone https://github.com/ivanstarwars8/hiddify-work.git
cd hiddify-work

# 4. Скачать библиотеки
make android-libs

# 5. Собрать APK
flutter build apk --release
```

---

## 🍎 Сборка на macOS

```bash
# 1. Установить Flutter
wget https://storage.googleapis.com/flutter_infra_release/releases/stable/macos/flutter_macos_3.24.3-stable.zip
unzip flutter_macos_3.24.3-stable.zip
export PATH="$PATH:`pwd`/flutter/bin"

# 2. Установить Android command line tools
brew install --cask android-commandlinetools

# 3. Клонировать и собрать
git clone https://github.com/ivanstarwars8/hiddify-work.git
cd hiddify-work
make android-libs
flutter pub get
flutter build apk --release
```

---

## 🌐 Использование VPS с нормальным интернетом

Если у вас есть доступ к VPS провайдеру:

**DigitalOcean / Hetzner / AWS / Google Cloud:**

```bash
# SSH на сервер
ssh user@your-vps-ip

# Установить необходимое
sudo apt update
sudo apt install -y git wget curl unzip xz-utils openjdk-17-jdk

# Установить Flutter
wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.3-stable.tar.xz
tar xf flutter_linux_3.24.3-stable.tar.xz
export PATH="$PATH:$HOME/flutter/bin"

# Клонировать и собрать
git clone https://github.com/ivanstarwars8/hiddify-work.git
cd hiddify-work
make android-prepare  # Это скачает SDK и библиотеки
flutter build apk --release

# Скачать готовый APK
scp user@your-vps-ip:~/hiddify-work/build/app/outputs/flutter-apk/app-release.apk ./
```

---

## 📝 Готовая сборка (если не хотите собирать сами)

### Вариант 1: GitHub Releases
После настройки GitHub Actions, APK будет доступен в разделе Actions -> Artifacts

### Вариант 2: Использовать готовые релизы
Если проект уже публикует релизы, проверьте:
https://github.com/hiddify/hiddify-next/releases

---

## 🔍 Диагностика проблем

### Проверка окружения:
```bash
# Flutter
flutter doctor -v

# Android SDK
$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager --list

# Java
java -version

# Библиотеки
ls -lh android/app/libs/
```

### Очистка перед повторной сборкой:
```bash
flutter clean
rm -rf build/
rm -rf ~/.gradle/caches/
flutter pub get
flutter build apk --release
```

---

## 📊 Текущее состояние проекта

**На сервере `/home/user/hiddify-work`:**
```
✅ Код готов к сборке
✅ Flutter 3.24.3 установлен (/home/user/sdk/flutter)
✅ Библиотеки hiddify-core скачаны (android/app/libs/hiddify-core.aar)
✅ Flutter зависимости установлены
❌ Android SDK не установлен (сетевые ограничения)
```

**Что нужно для успешной сборки:**
- Сервер/машина с полным доступом к интернету
- Flutter 3.24.x
- Android SDK (автоматически установится через flutter doctor --android-licenses)
- Java 17+

---

## 🎯 Рекомендация

**Лучший вариант для вас:**

1. **Если есть локальная Linux/Mac машина:** Используйте Вариант 1
2. **Если есть VPS с интернетом:** Используйте облачный сервер
3. **Для автоматизации:** Настройте GitHub Actions (Вариант 3)
4. **Для разовой сборки:** Используйте Codemagic (Вариант 4)

---

## 📞 Дополнительная помощь

Все необходимые файлы готовы:
- ✅ ANDROID_AUDIT_REPORT.md - Полный отчет
- ✅ ANDROID_SETUP.md - Быстрый старт
- ✅ android/BUILD_INSTRUCTIONS.md - Детальные инструкции
- ✅ Этот файл - Варианты сборки на разных платформах

**Приложение полностью готово к сборке на машине с нормальным интернетом!**
