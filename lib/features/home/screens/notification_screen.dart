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
  
  // 🔥 Menggunakan objek milik pusher_client_fixed
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

  // Membersihkan koneksi websocket saat keluar dari halaman
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

  // 1. MEMBUAT HISTORI NOTIFIKASI DARI API REST
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

  // 2. MENGAKTIFKAN WEBSOCKET REAL-TIME LANGSUNG KE LARAVEL REVERB
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

      // Konfigurasi opsi Reverb didukung penuh oleh penulisan PusherOptions ini
      PusherOptions options = PusherOptions(
        host: ApiConfig.reverbHost,
        wsPort: port,
        wssPort: port,
        encrypted: false, // Set true jika server VPS sudah menggunakan SSL (WSS)
        auth: PusherAuth(
          ApiConfig.broadcastingAuthEndpoint,
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      // Inisialisasi instansi PusherClient baru
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

      // Mendengarkan event notifikasi bawaan back-end Laravel
      _channel!.bind('Illuminate\\Notifications\\Events\\BroadcastNotificationCreated', (PusherEvent? event) {
        if (event == null || event.data == null) return;
        
        debugPrint("🔥 DATA NOTIFIKASI VALID MASUK: ${event.data}");
        
        try {
          // Mengubah data string mentah menjadi Map JSON
          final Map<String, dynamic> incoming = json.decode(event.data!);

          final String judulRealtime = incoming['judul'] ?? incoming['title'] ?? 'Pemberitahuan Baru';
          final String pesanRealtime = incoming['pesan'] ?? incoming['message'] ?? 'Ada lowongan baru tersedia.';

          if (mounted) {
            setState(() {
              // Menyisipkan data baru ke baris paling atas List
              _notifications.insert(0, {
                'id': incoming['id'] ?? DateTime.now().millisecondsSinceEpoch,
                'judul': judulRealtime,
                'pesan': pesanRealtime,
                'dibaca': false,
                'dibuat_pada': DateTime.now().toIso8601String(),
              });
            });

            // Tampilkan snackbar pemberitahuan pop-up
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("$judulRealtime\n$pesanRealtime"),
                backgroundColor: const Color(0xFF635147),
                duration: const Duration(seconds: 4),
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
                      ? const Center(child: Text("Tidak ada notifikasi"))
                      : ListView.builder(
                          itemCount: _notifications.length,
                          itemBuilder: (context, index) {
                            final notif = _notifications[index];
                            
                            final String displayJudul = notif['judul'] ?? 'Pemberitahuan';
                            final String displayPesan = notif['pesan'] ?? 'Detail pemberitahuan kosong.';

                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              child: ListTile(
                                leading: const Icon(Icons.notifications_active, color: Color(0xFFF0B85E)),
                                title: Text(
                                  displayJudul,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(displayPesan),
                              ),
                            );
                          },
                        ),
                ),
    );
  }
}