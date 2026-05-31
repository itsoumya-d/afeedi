# Flutter-specific rules
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# Keep Firebase classes if used
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Keep Google Sign-In
-keep class com.google.android.gms.auth.** { *; }

# Keep Facebook Auth
-keep class com.facebook.** { *; }

# Keep Hive model classes (annotated with @HiveType)
-keep class com.afeedi.app.** { *; }

# Keep classes used via reflection (json_serializable, etc.)
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes Exceptions

# Preserve line number information for stack traces in crash reports
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# OkHttp (used by dio/http)
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }
