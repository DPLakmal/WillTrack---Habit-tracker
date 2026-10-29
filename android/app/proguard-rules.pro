# Flutter standard rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Flutter Deferred Components / Play Core Split Install (unused)
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**

# Drift and native SQLite3 bindings
-keep class com.simonbinder.sqlite3.** { *; }
-keep class eu.simonbinder.sqlite3.** { *; }
-keepclasseswithmembernames class * {
    native <methods>;
}

# Flutter Local Notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class com.google.android.gms.internal.** { *; }

# Timezone & Core Desugaring
-keep class org.threeten.bp.** { *; }
-dontwarn java.time.**
