# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Keep Riverpod classes
-keep class * extends androidx.lifecycle.ViewModel
-keep class * implements riverpod.Consumer

# Keep connectivity_plus
-keep class dev.fluttercommunity.connectivity.** { *; }

# Keep shared_preferences
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# Keep url_launcher
-keep class io.flutter.plugins.urllauncher.** { *; }

# Keep cached_network_image
-keep class com.fluttercandies.image_loader.** { *; }

# General optimization
-dontwarn io.flutter.embedding.**
-keepattributes Signature
-keepattributes *Annotation*
