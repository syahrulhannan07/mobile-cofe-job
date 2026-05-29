# Mengabaikan warning class logger slf4j yang hilang agar build release sukses
-dontwarn org.slf4j.**

# Jika kamu menggunakan pusher, baris ini juga sangat baik untuk menjaga class pusher agar tidak rusak di-minify
-keep class com.pusher.client.** { *; }