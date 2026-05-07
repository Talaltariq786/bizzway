# Flutter (R8)
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# JSON / reflection (Dio, models)
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses

# Google Play services / Maps
-keep class com.google.android.gms.maps.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# OkHttp / Kotlin (Dio)
-dontwarn okhttp3.**
-dontwarn okio.**
