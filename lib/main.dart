// lib/main.dart
import 'package:flutter/foundation.dart'; 
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart'; 
import 'package:firebase_messaging/firebase_messaging.dart'; 
import 'features/auth/screens/login_screen.dart';
import 'features/main_layout.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// 🔥 1. HANDLER UNTUK NOTIFIKASI SAAT APLIKASI DI BACKGROUND / MATI (TERMINATED)
// Wajib diletakkan di luar main() dan diberi anotasi @pragma('vm:entry-point')
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Pastikan Firebase diinisialisasi di background process
  await Firebase.initializeApp();
  print("🔔 Notifikasi Masuk di Background/Mati: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyAFSiVC-CSY5GMWZDyKGJvi9ko7-i8p1w0",
          authDomain: "cafejob-6a969.firebaseapp.com",
          projectId: "cafejob-6a969",
          storageBucket: "cafejob-6a969.firebasestorage.app",
          messagingSenderId: "234748322219",
          appId: "1:234748322219:web:6bfd0511f59b67127e72ee",
        ),
      );
    } else {
      // ✅ 2. PENYESUAIAN BERDASARKAN GOOGLE-SERVICES.JSON TERBARU ANDA (ANDROID)
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyABpNgm0jaOgnChTixoKU2lyCgQpR7GEQM", // Diambil dari "current_key"
          appId: "1:234748322219:android:30302aef0796be6c7e72ee", // Diambil dari "mobilesdk_app_id" (Sudah beralih ke Android)
          messagingSenderId: "234748322219", // Diambil dari "project_number"
          projectId: "cafejob-6a969", // Diambil dari "project_id"
          storageBucket: "cafejob-6a969.firebasestorage.app", // Diambil dari "storage_bucket"
        ),
      );
    }
  } catch (e) {
    print("Firebase Initialization Error: $e");
  }

  // 🔥 3. DAFTARKAN BACKGROUND HANDLER DI SINI
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // 4. Minta Izin Notifikasi
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print('User memberikan izin notifikasi.');

    try {
      String? token;
      if (kIsWeb) {
        token = await messaging.getToken(
          vapidKey: "BFyTUtfjsVrRFPZlrLU6KO_O2Olz48gGvv7yLoaWM3qXWQvFUlE2zacy5vlBjm0G-0GhMCLG8uB1toZK0NcVftI",
        );
        print("====== TOKEN FCM WEB CHROME SAYA ======\n$token\n=======================================");
      } else {
        // ✅ Ambil Token untuk HP Fisik Android
        token = await messaging.getToken();
        print("====== TOKEN FCM HP FISIK SAYA ======\n$token\n=====================================");
      }
      
      // Simpan token ke lokal device agar bisa dikirim ke Laravel nanti
      if (token != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_token', token);
      }
    } catch (e) {
      print("Gagal mengambil token FCM: $e");
    }
  } else {
    print('User menolak izin notifikasi.');
  }

  // 5. Listener saat aplikasi menyala di depan (Foreground)
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print("🔔 NOTIFIKASI REALTIME MASUK (FOREGROUND)!");
    final context = navigatorKey.currentContext;
    if (context != null) {
      // Menampilkan Dialog Kustom Cafe Job jika aplikasi sedang dibuka
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: const Color(0xFFFDF2E2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            title: const Row(
              children: [
                Icon(Icons.coffee_rounded, color: Color(0xFF422E26)),
                SizedBox(width: 10),
                Text("Notifikasi Cafe Job", style: TextStyle(color: Color(0xFF422E26), fontWeight: FontWeight.bold)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message.notification?.title ?? "Judul Kosong", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Text(message.notification?.body ?? "Isi pesan kosong"),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Oke", style: TextStyle(color: Color(0xFF422E26), fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      );
    }
  });

  final prefs = await SharedPreferences.getInstance();
  final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  runApp(CafeJobApp(isLoggedIn: isLoggedIn));
}

class CafeJobApp extends StatelessWidget {
  final bool isLoggedIn;
  const CafeJobApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cafe Job',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'sans-serif', useMaterial3: true),
      home: isLoggedIn ? const MainLayout() : const LoginScreen(),
    );
  }
}