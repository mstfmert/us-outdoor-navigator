# ─────────────────────────────────────────────────────────────────────────────
# US Outdoor Navigator — ProGuard Rules
# ─────────────────────────────────────────────────────────────────────────────

# Flutter engine — never obfuscate
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.embedding.**

# Flutter plugin registrar
-keep class com.mert.usoutdoor.** { *; }

# Kotlin coroutines
-keepnames class kotlinx.coroutines.internal.MainDispatcherFactory { *; }
-keepnames class kotlinx.coroutines.CoroutineExceptionHandler { *; }
-keepclassmembers class kotlinx.coroutines.** { volatile <fields>; }

# OkHttp (network_image, http package kullanır)
-keep class okhttp3.** { *; }
-dontwarn okhttp3.**
-dontwarn okio.**

# Google Play Billing (RevenueCat bağımlılığı)
-keep class com.android.billingclient.** { *; }
-dontwarn com.android.billingclient.**

# RevenueCat
-keep class com.revenuecat.purchases.** { *; }
-dontwarn com.revenuecat.purchases.**

# Geolocator plugin
-keep class com.baseflow.geolocator.** { *; }

# flutter_map / Mapbox tiles
-keep class com.mapbox.** { *; }
-dontwarn com.mapbox.**

# JSON serialization (dart:convert bridge)
-keepattributes Signature
-keepattributes *Annotation*

# Firebase (devre dışı olsa da bağımlılıklar var)
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Prevent crash on Android 12+ exact alarms
-keep class android.app.AlarmManager { *; }

# Keep R8 from stripping native crash reporters
-keepattributes LineNumberTable, SourceFile
-renamesourcefileattribute SourceFile
