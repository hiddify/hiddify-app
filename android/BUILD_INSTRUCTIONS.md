# 🛠️ Инструкция по сборке Android-приложения Go-bull

## 📋 Требования

- **Flutter:** 3.24.0 - 3.24.3
- **Java:** 17 (рекомендуется) или 21
- **Android SDK:** API 34
- **NDK:** 26.1.10909125
- **Gradle:** 7.6.1 (включен в проект)

---

## 🚀 Быстрый старт

### 1. Проверка окружения

```bash
# Проверить Flutter
flutter doctor

# Проверить Java
java -version

# Проверить Android SDK
flutter doctor --android-licenses
```

### 2. Подготовка проекта

```bash
# Скачать нативные библиотеки (уже выполнено)
make android-libs

# Установить зависимости Flutter
flutter pub get

# Сгенерировать код
flutter pub run build_runner build --delete-conflicting-outputs
```

### 3. Сборка APK

#### Debug версия (для тестирования)
```bash
flutter build apk --debug
```

#### Release версия (подписанная)
```bash
# Сначала настройте keystore (см. раздел ниже)
flutter build apk --release
```

---

## 🔐 Настройка подписи (для production релизов)

### Шаг 1: Создать keystore

```bash
keytool -genkey -v -keystore ~/go-bull-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias go-bull
```

**Важно:** Сохраните пароли в безопасном месте!

### Шаг 2: Настроить key.properties

```bash
# Скопировать шаблон
cp android/key.properties.template android/key.properties

# Отредактировать файл
nano android/key.properties
```

Заполните:
```properties
storePassword=ваш_пароль_от_keystore
keyPassword=ваш_пароль_от_ключа
keyAlias=go-bull
storeFile=/полный/путь/к/go-bull-release.jks
```

### Шаг 3: Проверить .gitignore

Убедитесь, что в `.gitignore` есть:
```
android/key.properties
*.jks
*.keystore
```

---

## 📦 Варианты сборки

### 1. Universal APK (один APK для всех архитектур)
```bash
flutter build apk --release
# Результат: build/app/outputs/flutter-apk/app-release.apk
```

### 2. Split APK (отдельный APK для каждой архитектуры)
```bash
flutter build apk --release --split-per-abi

# Результаты:
# - app-armeabi-v7a-release.apk (~40MB)
# - app-arm64-v8a-release.apk (~45MB)
# - app-x86_64-release.apk (~50MB)
```

### 3. Android App Bundle (для Google Play)
```bash
flutter build appbundle --release
# Результат: build/app/outputs/bundle/release/app-release.aab
```

### 4. Использование Makefile
```bash
# APK через Makefile
make android-apk-release

# AAB через Makefile
make android-aab-release
```

---

## 🐛 Отладка

### Сборка с логами
```bash
flutter build apk --release --verbose
```

### Проверка подписи APK
```bash
keytool -printcert -jarfile build/app/outputs/flutter-apk/app-release.apk
```

### Очистка сборки
```bash
flutter clean
rm -rf android/.gradle
flutter pub get
```

---

## 📱 Установка и тестирование

### Установка на устройство
```bash
# Через ADB
adb install build/app/outputs/flutter-apk/app-release.apk

# Или через Flutter
flutter install
```

### Запуск в debug режиме
```bash
flutter run
```

---

## 🔧 Решение проблем

### Проблема: Flutter не найден
```bash
# Скачать Flutter
wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.3-stable.tar.xz
tar xf flutter_linux_3.24.3-stable.tar.xz
export PATH="$PATH:`pwd`/flutter/bin"
```

### Проблема: Java версия не соответствует
```bash
# Установить Java 17
sudo apt install openjdk-17-jdk

# Переключить версию
sudo update-alternatives --config java
```

### Проблема: Библиотеки не найдены
```bash
# Перескачать библиотеки
rm -rf android/app/libs/hiddify-core.aar
make android-libs
```

### Проблема: Gradle ошибки
```bash
# Очистить кэш Gradle
cd android
./gradlew clean
cd ..
flutter clean
```

---

## 📊 Размеры APK

После сборки с `--split-per-abi`:
- **armeabi-v7a:** ~40MB (32-bit ARM, старые устройства)
- **arm64-v8a:** ~45MB (64-bit ARM, большинство современных устройств)
- **x86_64:** ~50MB (эмуляторы)

Universal APK: ~130MB (все архитектуры)

---

## 🚀 CI/CD (опционально)

Пример GitHub Actions workflow:

```yaml
name: Build Android
on: [push]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: actions/setup-java@v2
        with:
          java-version: '17'
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.3'
      - run: make android-libs
      - run: flutter pub get
      - run: flutter build apk --release
      - uses: actions/upload-artifact@v2
        with:
          name: release-apk
          path: build/app/outputs/flutter-apk/app-release.apk
```

---

## 📞 Поддержка

При возникновении проблем:
1. Проверьте `flutter doctor`
2. Изучите `ANDROID_AUDIT_REPORT.md`
3. Посмотрите логи с `--verbose`
4. Обратитесь в GitHub Issues проекта

---

**Успешной сборки! 🎉**
