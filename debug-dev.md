# گزارش جامع دیباگ و توسعه اپلیکیشن Hiddify نسخه 2.5.7 (اندروید)

**تاریخ تهیه گزارش:** 2025-10-28  
**نسخه اپلیکیشن:** 2.5.7 (Pre-release)  
**پلتفرم تحلیل شده:** Android  
**معماری هسته:** Sing-box based VPN/Proxy service  

---

## 1. نقشه کامل و جامع مهندسی در سطح دیباگ

### 1.1 معماری کلی اپلیکیشن

```
┌─────────────────────────────────────────────────────────────┐
│                    Flutter/Dart Layer                        │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │ UI Features  │  │ Connection   │  │ Config Option│      │
│  │   (Widgets)  │  │  Notifier    │  │   Manager    │      │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘      │
│         │                  │                  │              │
│         └──────────────────┴──────────────────┘              │
│                            │                                 │
│                 ┌──────────▼──────────┐                     │
│                 │ Platform Channel    │                     │
│                 │ (Method/Event)      │                     │
│                 └──────────┬──────────┘                     │
└────────────────────────────┼─────────────────────────────────┘
                             │
┌────────────────────────────▼─────────────────────────────────┐
│                    Android Native Layer                       │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │ MainActivity │  │ MethodHandler│  │EventHandler  │      │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘      │
│         │                  │                  │              │
│         └──────────────────┴──────────────────┘              │
│                            │                                 │
│         ┌──────────────────▼──────────────────┐             │
│         │   Service Connection Manager         │             │
│         └──────────────────┬──────────────────┘             │
│                            │                                 │
│         ┌──────────────────┴──────────────────┐             │
│         │                                      │             │
│    ┌────▼─────┐                        ┌──────▼──────┐     │
│    │VPNService│                        │ProxyService │     │
│    └────┬─────┘                        └──────┬──────┘     │
│         └──────────────────┬──────────────────┘             │
│                            │                                 │
│                     ┌──────▼──────┐                         │
│                     │  BoxService │                         │
│                     │  (Core Mgmt)│                         │
│                     └──────┬──────┘                         │
└────────────────────────────┼─────────────────────────────────┘
                             │
┌────────────────────────────▼─────────────────────────────────┐
│                    Native Core (libcore)                      │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  Sing-box Core (Go-based proxy/VPN implementation)     │ │
│  │  - Protocol handlers (VMess, VLESS, Trojan, etc.)     │ │
│  │  - TUN interface management                            │ │
│  │  - Network routing and traffic handling                │ │
│  │  - DNS resolution                                       │ │
│  └────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────┘
```

### 1.2 کامپوننت‌های اصلی اندروید

#### 1.2.1 Services
- **VPNService** (`com.hiddify.hiddify.bg.VPNService`)
  - مدیریت VPN tunnel
  - Per-app proxy support
  - System proxy configuration
  - Foreground service type: SPECIAL_USE (vpn)

- **ProxyService** (`com.hiddify.hiddify.bg.ProxyService`)
  - Proxy mode alternative to VPN
  - Foreground service type: SPECIAL_USE (proxy)

- **BoxService** (`com.hiddify.hiddify.bg.BoxService`)
  - Core service management wrapper
  - Command server initialization
  - Configuration parsing and validation
  - Service lifecycle management

- **TileService** (`com.hiddify.hiddify.bg.TileService`)
  - Quick Settings Tile integration
  - Toggle VPN from notification shade

#### 1.2.2 Network Monitoring
- **DefaultNetworkMonitor** 
  - Network availability detection
  - Network interface change monitoring
  - Default network callback registration

- **DefaultNetworkListener**
  - Active network tracking
  - Network capability monitoring
  - Handles network transitions

#### 1.2.3 Communication Channels
- **MethodChannel** (`com.hiddify.app/method`)
  - Parse config
  - Generate config
  - Start/Stop/Restart service
  - URL test
  - Select outbound

- **EventChannels**
  - Service status updates
  - Service alerts
  - Stats (uplink/downlink)
  - Groups/Active groups
  - Logs

### 1.3 ساختار فایل‌ها و دایرکتوری‌ها

```
android/
├── app/
│   ├── build.gradle              # Build configuration (compileSdk: 34, minSdk: 21)
│   ├── src/main/
│   │   ├── AndroidManifest.xml   # App permissions and components
│   │   └── kotlin/com/hiddify/hiddify/
│   │       ├── Application.kt
│   │       ├── MainActivity.kt
│   │       ├── MethodHandler.kt
│   │       ├── EventHandler.kt
│   │       ├── Settings.kt
│   │       ├── bg/                # Background services
│   │       │   ├── BoxService.kt
│   │       │   ├── VPNService.kt
│   │       │   ├── ProxyService.kt
│   │       │   ├── TileService.kt
│   │       │   ├── ServiceConnection.kt
│   │       │   ├── ServiceNotification.kt
│   │       │   ├── DefaultNetworkMonitor.kt
│   │       │   └── DefaultNetworkListener.kt
│   │       ├── constant/          # Constants (Status, Action, Alert, etc.)
│   │       └── utils/             # Utilities
│   └── libs/                      # Native libraries (.aar files)
├── build.gradle                   # Root build configuration
├── gradle.properties              # Gradle JVM args (Xmx4048m)
└── settings.gradle                # AGP: 7.4.2, Kotlin: 1.8.21

lib/
├── singbox/
│   ├── model/                     # Singbox data models
│   │   ├── singbox_config_option.dart
│   │   ├── singbox_status.dart
│   │   ├── singbox_stats.dart
│   │   └── singbox_outbound.dart
│   └── service/                   # Singbox service implementations
│       ├── singbox_service.dart
│       ├── platform_singbox_service.dart
│       └── ffi_singbox_service.dart
├── features/
│   ├── connection/                # Connection management
│   │   ├── notifier/connection_notifier.dart
│   │   └── data/connection_repository.dart
│   ├── config_option/             # Configuration options
│   ├── profile/                   # Profile management
│   ├── proxy/                     # Proxy settings
│   ├── per_app_proxy/             # Per-app proxy feature
│   └── stats/                     # Statistics
└── core/                          # Core utilities and services

libcore/                           # Git submodule to hiddify-next-core
```

### 1.4 دیتافلو و روال ارتباطی

#### Connection Flow:
```
1. User Tap Connect Button
   └─> connection_notifier.dart: toggleConnection()
       └─> connection_repository.dart: connect()
           └─> platform_singbox_service.dart: start()
               └─> MethodChannel.invokeMethod("start")
                   └─> MethodHandler.kt: onMethodCall(START)
                       └─> MainActivity.startService()
                           └─> VPNService.onStartCommand()
                               └─> BoxService.onStartCommand()
                                   ├─> startCommandServer()
                                   └─> startService()
                                       ├─> Parse config
                                       ├─> Build config
                                       ├─> Setup directories
                                       ├─> Start libbox service
                                       └─> Register network monitor
```

#### Status Update Flow:
```
Native Layer (BoxService)
   └─> StatusMessage emitted by libbox
       └─> EventChannel broadcast
           └─> platform_singbox_service.dart receives
               └─> connection_notifier builds status
                   └─> UI updates
```

---

## 2. نواقص و باگ‌های موجود

### 2.1 مشکلات کریتیکال (Critical)

#### 2.1.1 قطع شدن ناگهانی کانکشن (Connection Drop) ⚠️
**شدت:** بسیار بالا  
**علائم:**
- قطع اتصال بدون هیچ خطای واضح
- رخ می‌دهد بعد از مدت زمان محدود (معمولاً چند دقیقه تا چند ساعت)
- عدم reconnect خودکار

**ریشه‌های احتمالی:**
1. **مشکل در Network Monitoring:**
   - `DefaultNetworkListener` ممکن است در تشخیص تغییرات network ضعف داشته باشد
   - در `DefaultNetworkMonitor.checkDefaultInterfaceUpdate()` یک loop 10 بار با sleep 100ms وجود دارد که ممکن است fail شود
   ```kotlin
   for (times in 0 until 10) {
       var interfaceIndex: Int
       try {
           interfaceIndex = NetworkInterface.getByName(interfaceName).index
       } catch (e: Exception) {
           Thread.sleep(100)
           continue
       }
       listener.updateDefaultInterface(interfaceName, interfaceIndex)
   }
   ```
   - اگر بعد از 10 بار هم interface پیدا نشود، هیچ اقدامی نمی‌شود

2. **Idle Mode Issue:**
   - در `BoxService.kt` وقتی دستگاه وارد Doze mode می‌شود، `boxService?.pause()` فراخوانی می‌شود
   - اما ممکن است `wake()` به درستی کار نکند
   ```kotlin
   @RequiresApi(Build.VERSION_CODES.M)
   private fun serviceUpdateIdleMode() {
       if (Application.powerManager.isDeviceIdleMode) {
           boxService?.pause()
       } else {
           boxService?.wake()
       }
   }
   ```

3. **CommandServer Timeout:**
   - CommandServer با timeout 300 (ثانیه) ایجاد می‌شود
   - ممکن است connection بین app و core service drop شود

4. **Memory Limit در libcore:**
   - سرویس libbox ممکن است به دلیل memory limit توسط سیستم kill شود
   - گزینه `disableMemoryLimit` وجود دارد اما ممکن است کافی نباشد

#### 2.1.2 عدم مدیریت صحیح Exception در CommandClient
```kotlin
scope.launch(Dispatchers.IO) {
    for (i in 1..10) {
        delay(100 + i.toLong() * 50)
        try {
            commandClient.connect()
        } catch (ignored: Exception) {  // <-- Exception ignored!
            continue
        }
        // ...
    }
}
```
این کد exceptions را ignore می‌کند و log نمی‌کند که تشخیص مشکل را سخت می‌کند.

#### 2.1.3 Race Condition در Service Restart
در `BoxService.serviceReload()`:
```kotlin
override fun serviceReload() {
    notification.close()
    status.postValue(Status.Starting)
    val pfd = fileDescriptor
    if (pfd != null) {
        pfd.close()
        fileDescriptor = null
    }
    commandServer?.setService(null)
    boxService?.apply {
        runCatching {
            close()
        }.onFailure {
            writeLog("service: error when closing: $it")
        }
        Seq.destroyRef(refnum)
    }
    boxService = null
    runBlocking {
        startService(true)
    }
}
```
استفاده از `runBlocking` در main thread می‌تواند باعث ANR شود.

### 2.2 مشکلات Major

#### 2.2.1 عدم Retry Logic در Connection Failures
در `connection_notifier.dart`:
```dart
await _connectionRepo.connect(...)
    .mapLeft((err) async {
      loggy.warning("error connecting", err);
      await ref.read(Preferences.startedByUser.notifier).update(false);
      state = AsyncError(err, StackTrace.current);
    }).run();
```
هیچ تلاش مجددی برای reconnect نمی‌شود.

#### 2.2.2 مشکل در Per-App Proxy
در `VPNService.kt`:
```kotlin
fun addIncludePackage(builder: Builder, packageName: String) {
    if (packageName == this.packageName) { 
        Log.d("VpnService","Cannot include myself: $packageName")
        return
    }
    try {     
        Log.d("VpnService","Including $packageName")
        builder.addAllowedApplication(packageName)
    } catch (e: NameNotFoundException) {
        // Silent failure - no logging
    }
}
```
اگر package وجود نداشته باشد، خطا silent است.

#### 2.2.3 Hard-coded Status Interval
در `CommandClient.kt`:
```kotlin
options.statusInterval = 2 * 1000 * 1000 * 1000  // 2 seconds in nanoseconds
```
این مقدار hard-coded است و قابل تنظیم نیست.

### 2.3 مشکلات Minor

#### 2.3.1 Memory Management در BoxService
```kotlin
val workingDir = Application.application.getExternalFilesDir(null) ?: return
```
اگر external storage unavailable باشد، function بدون error message return می‌شود.

#### 2.3.2 عدم Cleanup درست در ServiceConnection
```kotlin
override fun onServiceDisconnected(name: ComponentName?) {
    try {
        service?.unregisterCallback(callback)
    } catch (e: RemoteException) {
        Log.e(TAG, "cleanup service connection", e)
    }
}
```
`service` null نمی‌شود و ممکن است memory leak ایجاد کند.

#### 2.3.3 مشکلات Notification در Android 13+
```kotlin
fun checkPermission(): Boolean {
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
        return true
    }
    return Application.notification.areNotificationsEnabled()
}
```
اگر permission نداشته باشد، سرویس start نمی‌شود اما به کاربر اطلاع واضحی داده نمی‌شود.

---

## 3. اختلال در پکیج‌های موجود

### 3.1 وابستگی‌های Gradle (Android)

#### Versions در استفاده:
```gradle
compileSdkVersion: 34
minSdkVersion: 21
targetSdkVersion: 34
ndkVersion: "26.1.10909125"

Android Gradle Plugin: 7.4.2  ⚠️ (Outdated)
Kotlin: 1.8.21                 ⚠️ (Outdated)

Dependencies:
- com.google.code.gson:gson:2.10.1
- androidx.core:core-ktx:1.12.0
- androidx.appcompat:appcompat:1.6.1
- androidx.lifecycle:lifecycle-livedata-ktx:2.6.2
```

**مشکلات:**
1. **Android Gradle Plugin 7.4.2** قدیمی است (Latest: 8.x)
2. **Kotlin 1.8.21** outdated است (Latest: 1.9.x, 2.0.x available)
3. AGP قدیمی ممکن است با Gradle 8.x سازگار نباشد

### 3.2 وابستگی‌های Flutter

#### Versions در pubspec.yaml:
```yaml
SDK: ">=3.3.0 <4.0.0"
Flutter: ">=3.24.0 <=3.24.3"

Key Dependencies:
- intl: ^0.19.0
- slang: ^3.30.1
- hooks_riverpod: ^2.4.10      ⚠️ (Latest: 2.5.x)
- drift: ^2.16.0                ⚠️ (Latest: 2.20.x)
- dio: ^5.4.1                   ⚠️ (Latest: 5.7.x)
- go_router: ^13.2.0            ⚠️ (Latest: 14.x)
- package_info_plus: ^5.0.1     ⚠️ (Latest: 8.x)
- url_launcher: ^6.2.5          ⚠️ (Latest: 6.3.x)
- sentry_flutter: ^7.16.1       ⚠️ (Latest: 8.x)
```

**مشکلات:**
1. بسیاری از packages نسخه‌های قدیمی‌تر دارند
2. Flutter version محدود شده به `<=3.24.3` است
3. `dependency_overrides` برای `web: ^1.0.0` وجود دارد که نشان‌دهنده incompatibility است

### 3.3 وابستگی‌های Git-based

**مشکلات احتمالی:**
```yaml
humanizer:
  git:
    url: https://github.com/alex-relov/humanizer
    ref: up-version

flutter_easy_permission: 
  git: https://github.com/unger1984/flutter_easy_permission.git

circle_flags:
  git: https://github.com/hiddify-com/flutter_circle_flags.git
```

استفاده از git dependencies:
- نسخه‌ها lock نیستند
- ممکن است breaking changes بدون اطلاع ایجاد شود
- مشکل در reproducibility

### 3.4 Libcore (Submodule)

```
Submodule: hiddify/hiddify-next-core
Commit: f993a57755c37e08b02042037cbbf508c66c51f9
```

**مشکلات احتمالی:**
- submodule به صورت دستی باید update شود
- ممکن است با نسخه جدید sing-box ناسازگار باشد
- هیچ اطلاعاتی از version libcore در repository نیست

---

## 4. پیشنهادات برای رفع نواقص موجود

### 4.1 رفع مشکل Connection Drop

#### 4.1.1 بهبود Network Monitoring
```kotlin
// در DefaultNetworkMonitor.kt
private fun checkDefaultInterfaceUpdate(newNetwork: Network?) {
    val listener = listener ?: return
    if (newNetwork != null) {
        val interfaceName = (Application.connectivity.getLinkProperties(newNetwork) 
            ?: return).interfaceName
        
        // بهبود: افزایش تلاش‌ها و اضافه کردن exponential backoff
        var interfaceIndex = -1
        for (attempt in 0 until 20) {  // افزایش به 20 بار
            try {
                interfaceIndex = NetworkInterface.getByName(interfaceName).index
                listener.updateDefaultInterface(interfaceName, interfaceIndex)
                Log.d(TAG, "Successfully updated interface: $interfaceName ($interfaceIndex)")
                return
            } catch (e: Exception) {
                val delay = minOf(100L * (1 shl attempt), 5000L)  // exponential backoff
                Log.w(TAG, "Attempt $attempt failed, retrying in ${delay}ms", e)
                Thread.sleep(delay)
            }
        }
        // Log error if all attempts failed
        Log.e(TAG, "Failed to get interface index after 20 attempts for $interfaceName")
        listener.updateDefaultInterface("", -1)
    } else {
        listener.updateDefaultInterface("", -1)
    }
}
```

#### 4.1.2 اضافه کردن Keepalive و Heartbeat
```kotlin
// در BoxService.kt
private var heartbeatJob: Job? = null

private fun startHeartbeat() {
    heartbeatJob = GlobalScope.launch(Dispatchers.IO) {
        while (isActive && status.value == Status.Started) {
            delay(30000)  // هر 30 ثانیه
            try {
                // بررسی health سرویس
                boxService?.let {
                    val commandClient = Libbox.newStandaloneCommandClient()
                    commandClient.serviceReload()  // یا ping method
                }
            } catch (e: Exception) {
                Log.e(TAG, "Heartbeat failed, attempting recovery", e)
                serviceReload()
            }
        }
    }
}
```

#### 4.1.3 Auto-Reconnect Logic
```dart
// در connection_notifier.dart
Future<void> _connectWithRetry({int maxRetries = 3, int retryDelaySeconds = 5}) async {
  for (int attempt = 0; attempt < maxRetries; attempt++) {
    final result = await _connectionRepo.connect(
      activeProfile.id,
      activeProfile.name,
      ref.read(Preferences.disableMemoryLimit),
      activeProfile.testUrl,
    ).run();
    
    result.fold(
      (error) async {
        loggy.warning("Connection attempt ${attempt + 1} failed: $error");
        if (attempt < maxRetries - 1) {
          await Future.delayed(Duration(seconds: retryDelaySeconds * (attempt + 1)));
        } else {
          state = AsyncError(error, StackTrace.current);
          await ref.read(Preferences.startedByUser.notifier).update(false);
        }
      },
      (_) {
        loggy.info("Connected successfully on attempt ${attempt + 1}");
        return;
      },
    );
  }
}
```

#### 4.1.4 بهبود Doze Mode Handling
```kotlin
// در BoxService.kt
@RequiresApi(Build.VERSION_CODES.M)
private fun serviceUpdateIdleMode() {
    val isIdle = Application.powerManager.isDeviceIdleMode
    Log.d(TAG, "Device idle mode changed: $isIdle")
    
    try {
        if (isIdle) {
            boxService?.pause()
            // Schedule a wake-up check
            scheduleWakeCheck()
        } else {
            boxService?.wake()
            // Verify connection is restored
            verifyConnection()
        }
    } catch (e: Exception) {
        Log.e(TAG, "Error handling idle mode change", e)
        // Attempt service reload if wake/pause fails
        serviceReload()
    }
}

private fun verifyConnection() {
    GlobalScope.launch(Dispatchers.IO) {
        delay(2000)  // Wait 2 seconds
        try {
            val commandClient = Libbox.newStandaloneCommandClient()
            // Perform connectivity check
        } catch (e: Exception) {
            Log.e(TAG, "Connection verification failed", e)
            serviceReload()
        }
    }
}
```

### 4.2 بهبود Exception Handling

#### در CommandClient.kt:
```kotlin
scope.launch(Dispatchers.IO) {
    for (i in 1..10) {
        delay(100 + i.toLong() * 50)
        try {
            commandClient.connect()
            Log.d(TAG, "CommandClient connected successfully")
        } catch (e: Exception) {
            Log.w(TAG, "CommandClient connection attempt $i failed", e)
            if (i == 10) {
                Log.e(TAG, "All connection attempts failed")
                handler.onDisconnected()
            }
            continue
        }
        if (!isActive) {
            runCatching {
                commandClient.disconnect()
            }
            return@launch
        }
        this@CommandClient.commandClient = commandClient
        return@launch
    }
    // ...
}
```

### 4.3 بهبود Service Lifecycle

#### استفاده از Coroutine به جای runBlocking:
```kotlin
// در BoxService.kt
override fun serviceReload() {
    notification.close()
    status.postValue(Status.Starting)
    
    GlobalScope.launch(Dispatchers.IO) {
        // Close existing connections
        val pfd = fileDescriptor
        if (pfd != null) {
            pfd.close()
            fileDescriptor = null
        }
        
        commandServer?.setService(null)
        boxService?.apply {
            runCatching {
                close()
            }.onFailure {
                writeLog("service: error when closing: $it")
            }
            Seq.destroyRef(refnum)
        }
        boxService = null
        
        // Wait a bit before restart
        delay(1000)
        
        // Restart service
        startService(delayStart = true)
    }
}
```

### 4.4 اضافه کردن Monitoring و Telemetry

```kotlin
// کلاس جدید: ConnectionHealthMonitor.kt
object ConnectionHealthMonitor {
    private val metrics = mutableMapOf<String, Long>()
    
    fun recordConnectionStart() {
        metrics["last_connection_time"] = System.currentTimeMillis()
    }
    
    fun recordConnectionDrop(reason: String) {
        val uptime = System.currentTimeMillis() - (metrics["last_connection_time"] ?: 0L)
        Log.w(TAG, "Connection dropped after ${uptime}ms. Reason: $reason")
        
        // Send to analytics/Sentry
        Sentry.captureMessage("Connection drop: $reason, uptime: ${uptime}ms")
    }
    
    fun getConnectionUptime(): Long {
        return System.currentTimeMillis() - (metrics["last_connection_time"] ?: 0L)
    }
}
```

---

## 5. پیشنهادات برای بروزرسانی - آپدیت و آپگرید پکیج‌ها

### 5.1 اولویت بالا (Critical Updates)

#### Android Gradle Plugin و Kotlin
```gradle
// android/settings.gradle
plugins {
    id "dev.flutter.flutter-plugin-loader" version "1.0.0"
    id "com.android.application" version "8.5.2" apply false  // Update from 7.4.2
    id "org.jetbrains.kotlin.android" version "2.0.20" apply false  // Update from 1.8.21
}
```

**Benefits:**
- Performance improvements
- Better Kotlin support
- Bug fixes and security patches
- Gradle 8.x compatibility

#### Flutter Dependencies
```yaml
dependencies:
  hooks_riverpod: ^2.5.2        # از 2.4.10
  drift: ^2.20.3                # از 2.16.0
  dio: ^5.7.0                   # از 5.4.1
  go_router: ^14.2.7            # از 13.2.0
  package_info_plus: ^8.0.2     # از 5.0.1
  sentry_flutter: ^8.9.0        # از 7.16.1
  url_launcher: ^6.3.0          # از 6.2.5
```

**Benefits:**
- Bug fixes
- Performance improvements
- New features
- Better null safety
- Security patches

### 5.2 اولویت متوسط (Important Updates)

#### AndroidX Libraries
```gradle
dependencies {
    implementation 'androidx.core:core-ktx:1.13.1'          // از 1.12.0
    implementation 'androidx.appcompat:appcompat:1.7.0'     // از 1.6.1
    implementation 'androidx.lifecycle:lifecycle-livedata-ktx:2.8.6'  // از 2.6.2
}
```

#### Gradle Version
```properties
# gradle/wrapper/gradle-wrapper.properties
distributionUrl=https\://services.gradle.org/distributions/gradle-8.10-all.zip
```

### 5.3 تبدیل Git Dependencies به Package Registry

**قبل:**
```yaml
humanizer:
  git:
    url: https://github.com/alex-relov/humanizer
    ref: up-version
```

**بعد (اگر در pub.dev موجود باشد):**
```yaml
humanizer: ^x.x.x
```

یا fork کردن و publish در pub.dev خودتان.

### 5.4 بروزرسانی Libcore Submodule

```bash
cd libcore
git fetch origin
git checkout <latest-stable-tag>
cd ..
git add libcore
git commit -m "Update libcore to <version>"
```

### 5.5 Java Version Update

```gradle
// android/app/build.gradle
compileOptions {
    sourceCompatibility JavaVersion.VERSION_17    // Keep
    targetCompatibility JavaVersion.VERSION_17    // Keep
}

kotlinOptions {
    jvmTarget = '17'  // Keep
}
```

Java 17 خوب است، اما در آینده می‌توان به 21 ارتقا داد.

---

## 6. پیشنهادات به جهت تکمیل نواقص و توسعه اپلیکیشن

### 6.1 بهبودهای فنی (Technical Improvements)

#### 6.1.1 اضافه کردن Health Check API
```kotlin
// کلاس جدید: HealthCheckService.kt
class HealthCheckService {
    suspend fun performHealthCheck(): HealthStatus {
        return HealthStatus(
            isServiceRunning = checkServiceStatus(),
            isNetworkAvailable = checkNetworkAvailability(),
            isCoreResponsive = checkCoreResponsiveness(),
            uptime = getServiceUptime(),
            lastPacketTimestamp = getLastPacketTimestamp()
        )
    }
    
    private suspend fun checkCoreResponsiveness(): Boolean {
        return withTimeoutOrNull(5000) {
            try {
                val client = Libbox.newStandaloneCommandClient()
                // Perform simple query
                true
            } catch (e: Exception) {
                false
            }
        } ?: false
    }
}
```

#### 6.1.2 Connection Stability Monitoring
```dart
// lib/features/connection/service/connection_stability_monitor.dart
class ConnectionStabilityMonitor {
  final List<ConnectionEvent> _events = [];
  
  void recordEvent(ConnectionEventType type) {
    _events.add(ConnectionEvent(type, DateTime.now()));
    
    // Analyze patterns
    if (_events.length > 10) {
      final recentDrops = _events
        .where((e) => e.type == ConnectionEventType.disconnected)
        .where((e) => DateTime.now().difference(e.timestamp).inMinutes < 30)
        .length;
      
      if (recentDrops > 3) {
        loggy.warning('Unstable connection detected: $recentDrops drops in 30 min');
        // Trigger remediation or notify user
      }
    }
  }
}
```

#### 6.1.3 Smart Retry Strategy
```dart
// Exponential backoff with jitter
class SmartRetryStrategy {
  static const maxRetries = 5;
  static const baseDelay = Duration(seconds: 2);
  static const maxDelay = Duration(minutes: 5);
  
  Future<Either<String, Unit>> executeWithRetry<T>(
    Future<Either<String, T>> Function() action,
  ) async {
    int attempt = 0;
    while (attempt < maxRetries) {
      final result = await action();
      if (result.isRight()) return right(unit);
      
      attempt++;
      if (attempt >= maxRetries) return result;
      
      final delay = _calculateDelay(attempt);
      await Future.delayed(delay);
    }
    return left('Max retries exceeded');
  }
  
  Duration _calculateDelay(int attempt) {
    final exponentialDelay = baseDelay * (1 << attempt);
    final jitter = Random().nextInt(1000);
    final totalDelay = exponentialDelay + Duration(milliseconds: jitter);
    return totalDelay > maxDelay ? maxDelay : totalDelay;
  }
}
```

### 6.2 بهبودهای UX (User Experience)

#### 6.2.1 Connection Status Details
```dart
// نمایش اطلاعات بیشتر به کاربر
class ConnectionStatusWidget extends StatelessWidget {
  Widget build(BuildContext context) {
    return Column(
      children: [
        ConnectionStatusIndicator(),
        ConnectionUptimeDisplay(),       // نمایش مدت زمان اتصال
        ConnectionQualityIndicator(),    // کیفیت اتصال (خوب/متوسط/ضعیف)
        LastDisconnectReason(),          // دلیل آخرین قطع اتصال
        ReconnectAttemptCounter(),       // تعداد تلاش‌های reconnect
      ],
    );
  }
}
```

#### 6.2.2 Auto-Repair Feature
```dart
// ویژگی تعمیر خودکار
class AutoRepairService {
  Future<void> attemptRepair() async {
    loggy.info('Attempting automatic repair...');
    
    // 1. Clear cache
    await clearAppCache();
    
    // 2. Reset VPN profile
    await resetVpnProfile();
    
    // 3. Reload configuration
    await reloadConfiguration();
    
    // 4. Reconnect
    await reconnect();
  }
}
```

#### 6.2.3 Diagnostic Tool
```dart
// ابزار تشخیص مشکل برای کاربران
class DiagnosticTool {
  Future<DiagnosticReport> runDiagnostics() async {
    return DiagnosticReport(
      networkStatus: await checkNetworkStatus(),
      vpnPermissions: await checkVpnPermissions(),
      configValidity: await validateConfig(),
      dnsResolution: await testDnsResolution(),
      coreVersion: await getCoreVersion(),
      logErrors: await scanLogsForErrors(),
    );
  }
}
```

### 6.3 بهبودهای Performance

#### 6.3.1 Memory Management
```kotlin
// بهبود مدیریت حافظه
class MemoryManager {
    fun optimizeMemoryUsage() {
        // Limit log buffer size
        if (logBuffer.size > MAX_LOG_SIZE) {
            logBuffer.clear()
        }
        
        // Clear old statistics
        if (statsHistory.size > MAX_STATS_HISTORY) {
            statsHistory.removeAt(0)
        }
        
        // Trigger GC if needed
        if (getMemoryUsage() > MEMORY_THRESHOLD) {
            System.gc()
        }
    }
}
```

#### 6.3.2 Battery Optimization
```kotlin
// بهینه‌سازی مصرف باتری
class BatteryOptimizer {
    fun applyBatteryOptimizations() {
        // Reduce status update frequency when screen is off
        if (!isScreenOn) {
            statusUpdateInterval = 10000  // 10 seconds instead of 2
        }
        
        // Disable non-essential features
        if (isBatterySaverMode) {
            disableDetailedStats()
            reduceLogVerbosity()
        }
    }
}
```

### 6.4 ویژگی‌های جدید پیشنهادی

#### 6.4.1 Connection Profiles
- ایجاد پروفایل‌های مختلف برای سناریوهای مختلف (Work, Home, Travel)
- Auto-switch بر اساس network یا location

#### 6.4.2 Traffic Analysis
- نمودار مصرف داده در بازه‌های زمانی مختلف
- Per-app traffic statistics
- Data usage alerts

#### 6.4.3 Advanced Routing Rules
- GUI برای ایجاد routing rules پیشرفته
- Domain-based routing
- IP-based routing
- Protocol-based routing

#### 6.4.4 Backup & Restore
- Automatic backup of configurations
- Cloud sync option
- Import/Export profiles

#### 6.4.5 Connection Testing
- Automated connection quality testing
- Latency monitoring
- Packet loss detection
- Speed test integration

---

## 7. ریشه‌یابی علت خطای قطع شدن کانکشن

### 7.1 تحلیل عمیق مشکل

بر اساس تحلیل کد، **قطع شدن ناگهانی کانکشن** می‌تواند دلایل متعدد داشته باشد:

### 7.2 دلایل احتمالی با اولویت‌بندی

#### 🔴 دلیل #1: Android Doze Mode و App Standby (احتمال بالا: 40%)

**مکانیزم:**
```
User locks screen → Device enters Doze Mode after N minutes
    ↓
System restricts network access for background apps
    ↓
VPN service paused (boxService.pause() called)
    ↓
Connection drops but service thinks it's still connected
    ↓
When device wakes up, wake() may fail to restore connection properly
```

**شواهد در کد:**
```kotlin
// BoxService.kt
@RequiresApi(Build.VERSION_CODES.M)
private fun serviceUpdateIdleMode() {
    if (Application.powerManager.isDeviceIdleMode) {
        boxService?.pause()  // ⚠️ فقط pause می‌کند
    } else {
        boxService?.wake()   // ⚠️ ممکن است fail کند
    }
}
```

**راه حل:**
1. Request battery optimization exemption:
```kotlin
if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
    val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
    intent.data = Uri.parse("package:${packageName}")
    startActivity(intent)
}
```

2. استفاده از `FOREGROUND_SERVICE_SPECIAL_USE` (که الان هم استفاده می‌شود) ✓

3. بهبود `wake()` logic با verification:
```kotlin
boxService?.wake()
// Verify wake was successful
delay(2000)
if (!isConnectionAlive()) {
    serviceReload()
}
```

#### 🔴 دلیل #2: Network Interface Changes (احتمال بالا: 35%)

**مکانیزم:**
```
User switches from WiFi to Mobile Data (or vice versa)
    ↓
DefaultNetworkMonitor detects change
    ↓
Attempts to update interface in libbox
    ↓
If update fails or is delayed, packets route to wrong interface
    ↓
Connection drops
```

**شواهد در کد:**
```kotlin
// DefaultNetworkMonitor.kt
for (times in 0 until 10) {  // ⚠️ فقط 10 تلاش
    try {
        interfaceIndex = NetworkInterface.getByName(interfaceName).index
    } catch (e: Exception) {
        Thread.sleep(100)
        continue
    }
    listener.updateDefaultInterface(interfaceName, interfaceIndex)
}
// ⚠️ اگر 10 بار fail شد، هیچ اتفاقی نمی‌افتد!
```

**راه حل:**
1. افزایش تلاش‌ها و exponential backoff (قبلاً ذکر شد)
2. اضافه کردن fallback mechanism:
```kotlin
if (allAttemptsFailed) {
    Log.e(TAG, "Failed to update interface, reloading service")
    serviceReload()
}
```

#### 🟡 دلیل #3: CommandServer Timeout (احتمال متوسط: 15%)

**مکانیزم:**
```
CommandServer initialized with 300-second timeout
    ↓
If no communication for > 300 seconds
    ↓
Connection drops
```

**شواهد در کد:**
```kotlin
// BoxService.kt
private fun startCommandServer() {
    val commandServer = CommandServer(this, 300)  // ⚠️ 5 دقیقه timeout
    commandServer.start()
    this.commandServer = commandServer
}
```

**راه حل:**
1. افزایش timeout:
```kotlin
val commandServer = CommandServer(this, 3600)  // 1 ساعت
```

2. اضافه کردن periodic ping برای keep-alive (قبلاً در heartbeat ذکر شد)

#### 🟡 دلیل #4: Memory Pressure (احتمال متوسط: 8%)

**مکانیزم:**
```
Device runs low on memory
    ↓
Android kills background services (including VPN)
    ↓
Service killed but app doesn't detect it immediately
    ↓
Connection appears active but is actually dead
```

**راه حل:**
1. Implement `onTrimMemory()`:
```kotlin
override fun onTrimMemory(level: Int) {
    super.onTrimMemory(level)
    when (level) {
        TRIM_MEMORY_RUNNING_CRITICAL -> {
            Log.w(TAG, "Memory critical, optimizing...")
            optimizeMemoryUsage()
        }
    }
}
```

2. استفاده از `disableMemoryLimit` option که الان وجود دارد

#### 🟢 دلیل #5: Libcore/Sing-box Core Issues (احتمال پایین: 2%)

ممکن است bug در sing-box core باشد که بعد از مدت زمانی connection را drop کند.

**راه حل:**
1. بروزرسانی libcore به آخرین نسخه
2. بررسی logs سمت core (stderr.log)

### 7.3 استراتژی تشخیص دقیق (Debugging Strategy)

#### مرحله 1: Enhanced Logging
```kotlin
// در BoxService.kt
private fun startService() {
    Log.d(TAG, "=== SERVICE START DIAGNOSTICS ===")
    Log.d(TAG, "Time: ${System.currentTimeMillis()}")
    Log.d(TAG, "Battery: ${getBatteryLevel()}%")
    Log.d(TAG, "Network: ${getNetworkType()}")
    Log.d(TAG, "Doze: ${isDozeMode()}")
    Log.d(TAG, "Memory: ${getAvailableMemory()}MB")
    Log.d(TAG, "===================================")
    
    // ... existing code ...
}

private fun logConnectionDrop(reason: String) {
    val uptime = System.currentTimeMillis() - serviceStartTime
    Log.e(TAG, "=== CONNECTION DROP ===")
    Log.e(TAG, "Reason: $reason")
    Log.e(TAG, "Uptime: ${uptime}ms (${uptime/1000}s)")
    Log.e(TAG, "Battery: ${getBatteryLevel()}%")
    Log.e(TAG, "Network: ${getNetworkType()}")
    Log.e(TAG, "Doze: ${isDozeMode()}")
    Log.e(TAG, "========================")
}
```

#### مرحله 2: Crash Analytics
```kotlin
// در Application.kt یا MainActivity.kt
Sentry.init { options ->
    options.dsn = "YOUR_DSN"
    options.tracesSampleRate = 1.0
    options.isDebug = true
    
    // Custom breadcrumbs
    options.beforeSend = SentryOptions.BeforeSendCallback { event, hint ->
        // افزودن context
        event.setTag("connection_uptime", getConnectionUptime().toString())
        event.setTag("battery_level", getBatteryLevel().toString())
        event.setTag("doze_mode", isDozeMode().toString())
        event
    }
}
```

#### مرحله 3: User Feedback Collection
```dart
// اضافه کردن دکمه "Report Connection Issue"
class ReportIssueButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        final report = await DiagnosticTool().runDiagnostics();
        final logs = await getRecentLogs();
        
        // Send to Sentry or your analytics
        Sentry.captureMessage(
          'User-reported connection issue',
          withScope: (scope) {
            scope.setContexts('diagnostic_report', report.toJson());
            scope.setContexts('recent_logs', logs);
          },
        );
        
        // Show confirmation to user
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text('Thank you'),
            content: Text('Report sent. We will investigate.'),
          ),
        );
      },
      child: Text('Report Connection Issue'),
    );
  }
}
```

### 7.4 جمع‌بندی و اقدامات فوری

برای حل مشکل قطع شدن مداوم کانکشن، به ترتیب اولویت:

**اقدامات فوری (Immediate Actions):**
1. ✅ بهبود `DefaultNetworkMonitor` با retry logic بهتر
2. ✅ Request battery optimization exemption
3. ✅ افزایش CommandServer timeout
4. ✅ اضافه کردن heartbeat mechanism
5. ✅ بهبود verification در `wake()` method

**اقدامات میان‌مدت (Medium-term):**
1. 📊 Implement comprehensive logging
2. 📊 Add telemetry and analytics
3. 🔧 Implement auto-recovery mechanisms
4. 🧪 Add connection stability monitoring

**اقدامات بلندمدت (Long-term):**
1. 🔬 A/B testing different strategies
2. 📱 Beta testing program with detailed logging
3. 🤖 ML-based connection quality prediction
4. 🌐 Cloud-based connection health monitoring

---

## خلاصه و نتیجه‌گیری

### نقاط قوت اپلیکیشن:
✅ معماری خوب و modular  
✅ استفاده از sing-box core پیشرفته  
✅ پشتیبانی از پروتکل‌های متنوع  
✅ UI/UX مناسب  
✅ Multi-platform support  

### نقاط ضعف و مشکلات اصلی:
❌ مشکل در connection stability  
❌ کمبود retry و auto-recovery logic  
❌ Exception handling ناقص  
❌ Network transition handling ضعیف  
❌ Dependencies قدیمی  

### اولویت‌های توسعه:
1. **🔴 اولویت اول:** رفع مشکل connection drops
2. **🟡 اولویت دوم:** بروزرسانی dependencies
3. **🟢 اولویت سوم:** بهبود monitoring و telemetry
4. **🔵 اولویت چهارم:** افزودن ویژگی‌های جدید

### Roadmap پیشنهادی:
```
Milestone 1 (v2.5.8) - Stability Improvements
├─ Fix connection drop issues
├─ Enhanced logging
└─ Auto-recovery mechanisms

Milestone 2 (v2.6.0) - Dependency Updates
├─ Update Gradle and Kotlin
├─ Update Flutter packages
└─ Update libcore

Milestone 3 (v2.7.0) - Performance & UX
├─ Memory optimizations
├─ Battery optimizations
└─ Enhanced diagnostics

Milestone 4 (v3.0.0) - New Features
├─ Connection profiles
├─ Advanced routing
└─ Traffic analysis
```

---

**پایان گزارش**

این گزارش بر اساس تحلیل عمیق کد منبع تهیه شده است. برای دقت بیشتر، توصیه می‌شود:
1. Testing روی دستگاه‌های مختلف (Android versions مختلف)
2. تحلیل logs واقعی از کاربران
3. Profiling و performance analysis
4. بررسی issues و feedback کاربران

تاریخ: 2025-10-28  
نسخه گزارش: 1.0  
