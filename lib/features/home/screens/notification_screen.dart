import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/api_config.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // 🔥 IMPORT REPLACEMENT: Menggunakan FCM menggantikan Pusher
import 'dart:async';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<dynamic> _notifications = [];
  bool _isLoading = true;
  String? _errorMessage; 
  
  // StreamSubscription untuk mendengarkan real-time message stream FCM
  StreamSubscription<RemoteMessage>? _fcmSubscription;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    // 🔌 Membersihkan stream listener FCM saat keluar dari halaman agar tidak terjadi memory leak
    _fcmSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    await _fetchNotifications();
    await _initFirebaseMessaging();
  }

  // 1. MENGAMBIL HISTORI NOTIFIKASI DARI REST API BACKEND
  Future<void> _fetchNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null || token.isEmpty) {
        setState(() {
          _errorMessage = "Sesi login tidak ditemukan. Silakan login kembali.";
          _isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse(ApiConfig.notificationsEndpoint),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> rawList = data['data'] ?? [];
        
        // 🛡️ SOLUSI 1: Bersihkan duplikasi yang berasal dari Database Rest API
        final List<dynamic> uniqueList = [];
        final Set<String> seenFingerprints = {};

        for (var item in rawList) {
          String judul = item['judul'] ?? 'Pemberitahuan';
          String pesan = item['pesan'] ?? '';
          String fingerprint = "${judul}_$pesan".trim();

          if (!seenFingerprints.contains(fingerprint)) {
            seenFingerprints.add(fingerprint);
            uniqueList.add(item);
          }
        }

        setState(() {
          _notifications = uniqueList;
          _errorMessage = null;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = "Gagal memuat data server (Status: ${response.statusCode})";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Terjadi kesalahan koneksi internet.";
        _isLoading = false;
      });
    }
  }

  // 2. MENDENGARKAN REAL-TIME NOTIFIKASI MENGGUNAKAN FIREBASE CLOUD MESSAGING (FCM)
  Future<void> _initFirebaseMessaging() async {
    if (_errorMessage != null) return;

    try {
      FirebaseMessaging messaging = FirebaseMessaging.instance;

      // 🔐 Meminta Izin Notifikasi (Sangat Penting untuk Android 13+ dan iOS)
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint("🚫 [FCM]: Izin notifikasi ditolak oleh pengguna.");
        return;
      }

      // 📩 Menangkap Notifikasi Real-time saat aplikasi sedang menyala/aktif (Foreground)
      _fcmSubscription = FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint("📩 [FCM Foreground]: Pesan masuk masuk dengan ID: ${message.messageId}");

        // Ekstraksi data payload dari Laravel Notification Framework yang dikirim via FCM
        String judulRealtime = 'Pemberitahuan Baru';
        String pesanRealtime = '';

        // Deteksi payload tipe "notification" bawaan atau tipe custom payload "data"
        if (message.notification != null) {
          judulRealtime = message.notification!.title ?? 'Pemberitahuan Baru';
          pesanRealtime = message.notification!.body ?? '';
        } else if (message.data.isNotEmpty) {
          judulRealtime = message.data['judul'] ?? message.data['title'] ?? 'Pemberitahuan Baru';
          pesanRealtime = message.data['pesan'] ?? message.data['message'] ?? '';
        }

        final String currentFingerprint = "${judulRealtime}_$pesanRealtime".trim();

        // 🛡️ SOLUSI 2: Cocokkan fingerprint data baru dengan data yang sudah tampil di layar (Anti-Double Binding)
        final bool isDuplicate = _notifications.any((notif) {
          String existingJudul = notif['judul'] ?? '';
          String existingPesan = notif['pesan'] ?? '';
          return "${existingJudul}_$existingPesan".trim() == currentFingerprint;
        });
        
        if (isDuplicate) {
          debugPrint("🛡️ [FCM Filter]: Berhasil memblokir data duplikat di layar UI: $judulRealtime");
          return; 
        }

        if (mounted) {
          setState(() {
            // Masukkan data baru ke baris paling atas List Notifikasi secara real-time
            _notifications.insert(0, {
              'id': message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
              'judul': judulRealtime,
              'pesan': pesanRealtime,
              'dibaca': false,
              'dibuat_pada': DateTime.now().toIso8601String(),
            });
          });

          // 🔥 POP UP REAL-TIME: Snack Bar Melayang Elegan saat aplikasi aktif
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.star_rounded, color: Color(0xFFF0B85E)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "$judulRealtime: $pesanRealtime",
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF422E26),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      });

    } catch (e) {
      debugPrint("❌ Error Exception FCM Initialization: $e");
    }
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null) return "Baru saja";
    try {
      final dateTime = DateTime.parse(dateStr).toLocal();
      return "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
    } catch (_) {
      return "Baru saja";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F8F6),
      appBar: AppBar(
        title: const Text(
          "Notifikasi", 
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        centerTitle: true,
        backgroundColor: const Color(0xFF422E26),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF422E26))))
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(color: Color(0xFFFDECEB), shape: BoxShape.circle),
                          child: const Icon(Icons.wifi_off_rounded, size: 48, color: Colors.redAccent),
                        ),
                        const SizedBox(height: 20),
                        Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: 160,
                          height: 42,
                          child: ElevatedButton(
                            onPressed: _loadInitialData,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF422E26),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                              elevation: 0,
                            ),
                            child: const Text("Coba Lagi", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        )
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchNotifications, 
                  color: const Color(0xFF422E26),
                  child: _notifications.isEmpty
                      ? ListView(
                          children: [
                            SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                            Center(
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                                    child: Icon(Icons.notifications_none_rounded, size: 64, color: Colors.grey.shade400),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text("Belum Ada Notifikasi", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF422E26))),
                                  const SizedBox(height: 6),
                                  Text("Info lowongan & lamaran terbaru Anda akan muncul di sini.", style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                                ],
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          itemCount: _notifications.length,
                          itemBuilder: (context, index) {
                            final notif = _notifications[index];
                            final String displayJudul = notif['judul'] ?? 'Pemberitahuan';
                            final String displayPesan = notif['pesan'] ?? 'Detail pemberitahuan.';
                            final bool dibaca = notif['dibaca'] ?? true; 

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  color: dibaca ? Colors.white : const Color(0xFFFFFBEF),
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: dibaca ? const Color(0xFFF5F5F5) : const Color(0xFFFFF4E6),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.work_outline_rounded, 
                                          size: 20, 
                                          color: dibaca ? Colors.grey : const Color(0xFFF0B85E)
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    displayJudul,
                                                    style: TextStyle(
                                                      fontWeight: dibaca ? FontWeight.w600 : FontWeight.bold, 
                                                      fontSize: 14,
                                                      color: const Color(0xFF422E26)
                                                    ),
                                                  ),
                                                ),
                                                Text(
                                                  _formatTime(notif['dibuat_pada'] ?? notif['created_at']),
                                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              displayPesan,
                                              style: TextStyle(
                                                fontSize: 13, 
                                                color: dibaca ? Colors.black54 : Colors.black87,
                                                height: 1.3
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (!dibaca)
                                        Container(
                                          margin: const EdgeInsets.only(left: 8, top: 4),
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(color: Color(0xFFF0B85E), shape: BoxShape.circle),
                                        )
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
    );
  }
}