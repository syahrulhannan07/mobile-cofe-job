import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/api_config.dart';
import 'package:pusher_client_fixed/pusher_client_fixed.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<dynamic> _notifications = [];
  bool _isLoading = true;
  String? _errorMessage; 
  
  PusherClient? _pusher;
  Channel? _channel;
  int? _userId;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _cleanupWebsocket();
    super.dispose();
  }

  // Membersihkan koneksi websocket saat keluar dari halaman agar tidak memory leak
  void _cleanupWebsocket() {
    if (_userId != null) {
      final String channelName = "private-App.Models.User.$_userId";
      try {
        if (_pusher != null && _channel != null) {
          _pusher!.unsubscribe(channelName);
        }
        _pusher?.disconnect();
        debugPrint("🔌 [Reverb]: Berhasil disconnect dan unsubscribe.");
      } catch (e) {
        debugPrint("❌ Error closing pusher: $e");
      }
    }
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    await _fetchNotifications();
    await _initRealtimeWebsocket();
  }

  // 1. MENGAMBIL HISTORI NOTIFIKASI DARI API DATABASE (REST API)
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
        setState(() {
          _notifications = data['data'] ?? [];
          _errorMessage = null;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = "Gagal memuat data dari server (Status: ${response.statusCode})";
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

  // 2. MENDENGARKAN WEBSOCKET REAL-TIME DARI 6 NOTIFIKASI BACKEND LARAVEL REVERB
  Future<void> _initRealtimeWebsocket() async {
    if (_errorMessage != null) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    _userId = prefs.getInt('user_id'); 

    if (token == null || _userId == null) {
      debugPrint("⚠️ Websocket dibatalkan: Token atau User ID NULL!");
      return;
    }

    try {
      final int port = int.tryParse(ApiConfig.reverbPort) ?? 80;
      final String targetChannel = "private-App.Models.User.$_userId";

      // Konfigurasi opsi Reverb menggunakan PusherOptions
      PusherOptions options = PusherOptions(
        host: ApiConfig.reverbHost,
        wsPort: port,
        wssPort: port,
        encrypted: false, // Set menjadi true jika server produksi VPS Anda menggunakan HTTPS/WSS
        auth: PusherAuth(
          ApiConfig.broadcastingAuthEndpoint,
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      // Inisialisasi instansi PusherClient
      _pusher = PusherClient(
        ApiConfig.reverbAppKey,
        options,
        autoConnect: false,
      );

      // Menghubungkan ke server Laravel Reverb
      await _pusher!.connect();

      _pusher!.onConnectionStateChange((state) {
        debugPrint("🔌 [Reverb Status]: ${state?.currentState}");
      });

      _pusher!.onConnectionError((error) {
        debugPrint("❌ [Reverb Error]: ${error?.message}");
      });

      // Mendaftar masuk ke private channel user
      _channel = _pusher!.subscribe(targetChannel);

      // Mendengarkan event notifikasi bawaan back-end Laravel (Menangani ke-6 kelas notifikasi sekaligus)
      _channel!.bind('Illuminate\\Notifications\\Events\\BroadcastNotificationCreated', (PusherEvent? event) {
        if (event == null || event.data == null) return;
        
        debugPrint("🔥 DATA NOTIFIKASI VALID MASUK: ${event.data}");
        
        try {
          // Mengubah data string mentah menjadi Map JSON
          final Map<String, dynamic> incoming = json.decode(event.data!);

          // Sinkronisasi dengan key 'judul' & 'pesan' dari payload toBroadcast() Laravel kamu
          final String judulRealtime = incoming['judul'] ?? 'Pemberitahuan Baru';
          final String pesanRealtime = incoming['pesan'] ?? 'Ada pembaruan status lamaran terbaru.';

          if (mounted) {
            setState(() {
              // Menyisipkan data baru ke baris paling atas List agar langsung terlihat
              _notifications.insert(0, {
                'id': incoming['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
                'judul': judulRealtime,
                'pesan': pesanRealtime,
                'dibaca': false,
                'dibuat_pada': incoming['created_at'] ?? DateTime.now().toIso8601String(),
              });
            });

            // Tampilkan snackbar pop-up interaktif di dalam aplikasi saat itu juga
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.notifications_active, color: Color(0xFFF0B85E)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(judulRealtime, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                          Text(pesanRealtime, style: const TextStyle(fontSize: 12, color: Colors.white70)),
                        ],
                      ),
                    ),
                  ],
                ),
                backgroundColor: const Color(0xFF635147),
                duration: const Duration(seconds: 4),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            );
          }
        } catch (e) {
          debugPrint("❌ Gagal parsing JSON data event: $e");
        }
      });

    } catch (e) {
      debugPrint("❌ Gagal inisialisasi pusher_client (Exception): $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifikasi", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF422E26),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (!_isLoading && _errorMessage == null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _fetchNotifications,
              tooltip: "Segarkan",
            )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(_errorMessage!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadInitialData,
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF422E26)),
                          child: const Text("Coba Lagi", style: TextStyle(color: Colors.white)),
                        )
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchNotifications, 
                  child: _notifications.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey),
                              SizedBox(height: 8),
                              Text("Tidak ada notifikasi", style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _notifications.length,
                          itemBuilder: (context, index) {
                            final notif = _notifications[index];
                            
                            final String displayJudul = notif['judul'] ?? 'Pemberitahuan';
                            final String displayPesan = notif['pesan'] ?? 'Detail pemberitahuan kosong.';

                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              elevation: 2,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                leading: const CircleAvatar(
                                  backgroundColor: Color(0xFFFFF4E6),
                                  child: Icon(Icons.notifications_active, color: Color(0xFFF0B85E)),
                                ),
                                title: Text(
                                  displayJudul,
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF422E26)),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  // Mendukung pesan multi-line jika pesan dari HRD cukup panjang
                                  child: Text(displayPesan, style: const TextStyle(color: Colors.black87)),
                                ),
                              ),
                            );
                          },
                        ),
                ),
    );
  }
}