# Flutter specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# TensorFlow Lite rules
-keep class org.tensorflow.** { *; }
-dontwarn org.tensorflow.**

# tflite_flutter specific rules
-keep class com.tfliteflutter.** { *; }
-dontwarn com.tfliteflutter.**

# Prevent R8 from removing GPU delegate classes
-keep class org.tensorflow.lite.gpu.** { *; }
-dontwarn org.tensorflow.lite.gpu.**

# Google Play Core library rules (needed by Flutter embedding)
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**
