# Keep Flutter and embedding APIs
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }

# Keep Kotlin metadata (for reflection/tooling)
-keep class kotlin.Metadata { *; }

# Keep Gson types used via reflection and annotations (safe default)
-keep class com.google.gson.** { *; }

# Keep app classes that may be accessed reflectively
-keep class com.hiddify.hiddify.** { *; }

# Keep gomobile generated bindings and libbox interfaces
-keep class go.** { *; }
-keep class io.nekohasekai.libbox.** { *; }

# Don't warn on gomobile internals
-dontwarn go.**

# Optimize/obfuscate everything else by default
