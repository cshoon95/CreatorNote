# Supabase
-keep class io.github.jan.supabase.** { *; }

# Ktor + OkHttp
-keep class io.ktor.** { *; }
-dontwarn io.ktor.**
-keep class okhttp3.** { *; }
-dontwarn okhttp3.**
-keep class okio.** { *; }
-dontwarn okio.**

# Kotlinx Serialization
-keepattributes *Annotation*, InnerClasses
-dontnote kotlinx.serialization.AnnotationsKt
-keepclassmembers class kotlinx.serialization.json.** { *** Companion; }
-keepclasseswithmembers class kotlinx.serialization.json.** { kotlinx.serialization.KSerializer serializer(...); }
-keep,includedescriptorclasses class com.soohoon.influe.**$$serializer { *; }
-keepclassmembers class com.soohoon.influe.** { *** Companion; }
-keepclasseswithmembers class com.soohoon.influe.** { kotlinx.serialization.KSerializer serializer(...); }

# Kotlinx Datetime
-keep class kotlinx.datetime.** { *; }

# Google Credentials / Identity
-keep class androidx.credentials.** { *; }
-keep class com.google.android.libraries.identity.** { *; }
-dontwarn com.google.android.libraries.identity.**

# DataStore
-keep class androidx.datastore.** { *; }
