##---------------Begin: ProGuard configuration for Hiddify Android App  ----------

# General optimization settings for R8
-optimizationpasses 5
-dontusemixedcaseclassnames
-dontskipnonpubliclibraryclasses
-verbose

# Preserve line numbers for better stack traces
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# Keep annotations, signatures, and other metadata
-keepattributes *Annotation*,Signature,InnerClasses,EnclosingMethod

##---------------Begin: Flutter configuration ----------
# Keep Flutter and embedding APIs
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-dontwarn io.flutter.**

# Keep Flutter JNI methods
-keepclassmembers class * {
    native <methods>;
}
##---------------End: Flutter configuration ----------

##---------------Begin: Kotlin configuration ----------
# Keep Kotlin metadata (for reflection/tooling)
-keep class kotlin.Metadata { *; }
-keep class kotlin.** { *; }
-keep interface kotlin.** { *; }

# Kotlin coroutines
-keepnames class kotlinx.coroutines.internal.MainDispatcherFactory {}
-keepnames class kotlinx.coroutines.CoroutineExceptionHandler {}
-keepclassmembers class kotlinx.coroutines.** {
    volatile <fields>;
}
-dontwarn kotlinx.coroutines.**
##---------------End: Kotlin configuration ----------

##---------------Begin: AndroidX configuration ----------
# AndroidX
-keep class androidx.** { *; }
-keep interface androidx.** { *; }
-dontwarn androidx.**

# Lifecycle
-keep class * extends androidx.lifecycle.ViewModel { *; }
-keep class * extends androidx.lifecycle.AndroidViewModel { *; }
##---------------End: AndroidX configuration ----------

##---------------Begin: Gson configuration ----------
# Keep Gson types used via reflection and annotations
-keep class com.google.gson.** { *; }
-keep class sun.misc.Unsafe { *; }
-keep class com.google.gson.stream.** { *; }

# Keep generic signatures for Gson
-keepattributes Signature

# Keep data classes for Gson serialization
-keepclassmembers,allowobfuscation class * {
    @com.google.gson.annotations.SerializedName <fields>;
}
##---------------End: Gson configuration ----------

##---------------Begin: App-specific configuration ----------
# Keep app classes that may be accessed reflectively
-keep class com.hiddify.hiddify.** { *; }
-keep class app.hiddify.com.** { *; }

# Keep native methods
-keepclasseswithmembernames,includedescriptorclasses class * {
    native <methods>;
}

# Keep ViewBinding classes
-keep class * implements androidx.viewbinding.ViewBinding {
    public static ** bind(android.view.View);
    public static ** inflate(android.view.LayoutInflater);
}
##---------------End: App-specific configuration ----------

##---------------Begin: Gomobile/Libbox configuration ----------
# Keep gomobile generated bindings and libbox interfaces
-keep class go.** { *; }
-keep class io.nekohasekai.libbox.** { *; }
-keep interface io.nekohasekai.** { *; }

# Don't warn on gomobile internals
-dontwarn go.**
-dontwarn io.nekohasekai.**

# Keep all JNI methods for Go bindings
-keepclasseswithmembers class * {
    native <methods>;
}
##---------------End: Gomobile/Libbox configuration ----------

##---------------Begin: Reflection and serialization ----------
# Keep methods that are called via reflection
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# Keep enums
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Keep Parcelables
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# Keep Serializable classes
-keepnames class * implements java.io.Serializable
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    !static !transient <fields>;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}
##---------------End: Reflection and serialization ----------

##---------------Begin: Remove logging in release ----------
# Remove all logging in release builds
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
}
##---------------End: Remove logging in release ----------

# Optimize and obfuscate everything else by default
