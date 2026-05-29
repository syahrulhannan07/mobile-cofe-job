# 1. Mengabaikan warning dari SLF4J yang menyebabkan R8 error di GitHub Actions
-dontwarn org.slf4j.**
-keep class org.slf4j.** { *; }

# 2. Aturan keamanan tambahan khusus untuk library internal Pusher Client
-keep class com.pusher.client.** { *; }
-dontwarn com.pusher.client.**