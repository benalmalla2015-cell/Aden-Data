# TensorFlow Lite
-keep class org.tensorflow.lite.** { *; }
-keep class org.tensorflow.lite.gpu.** { *; }
-dontwarn org.tensorflow.**

# Flutter
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**

# Aden Data VPN Bridge
-keep class net.aden.data.** { *; }

# Kotlin coroutines
-keepclassmembers class kotlinx.coroutines.** { volatile <fields>; }
-dontwarn kotlinx.coroutines.**

# AndroidX
-keep class androidx.** { *; }
-dontwarn androidx.**

# General
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
