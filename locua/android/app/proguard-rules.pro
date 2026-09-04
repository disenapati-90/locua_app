# ==============================================================================
# Flutter Core & Runtime Wrapper Rules
# ==============================================================================
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# Preserve code architecture traits crucial for Reflection & Serializers
-keepattributes *Annotation*,Signature,InnerClasses,EnclosingMethod,SourceFile,LineNumberTable

# ==============================================================================
# Hive Database Reflection Security Rules
# ==============================================================================
# Protect underlying binary adapters
-keep class com.io7m.jlexing.** { *; }
-keep class io.hive.** { *; }
-dontwarn io.hive.**

# Explicitly stop R8 from renaming your annotated business models and fields
-keepclassmembers class * {
    @io.hive.HiveField <fields>;
    @io.hive.annotations.HiveField <fields>;
    @io.hive.HiveType <methods>;
}

# Keep all auto-generated TypeAdapters from hive_generator untouched
-keep class * extends io.hive.HiveObject { *; }
-keep class * implements io.hive.TypeAdapter { *; }
-keep class **.*Adapter { *; }

# Legacy placeholders matching fallback definitions
-keep class * extends io.realm.RealmObject { *; }
-keep class * implements generic.model.** { *; }

# ==============================================================================
# Native Audio & Utility Plugin Support Rules
# ==============================================================================
# Text-to-Speech (flutter_tts)
-dontwarn android.speech.tts.**

# Local Notifications Plugin Engine Bindings
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-dontwarn com.dexterous.flutterlocalnotifications.**
