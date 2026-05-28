import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:laravel_echo/laravel_echo.dart';
import 'package:pusher_client/pusher_client.dart';
import '../../../core/network/api_config.dart';

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
  Echo? _echo;
  int? _userId;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    if (_userId != null && _echo != null) {
      try {
        _echo!.private('App.Models.User.$_userId')
              .stopListening('.Illuminate\\Notifications\\Events\\BroadcastNotificationCreated');
      } catch (e) {
        debugPrint("❌ Error stop listening: $e");
      }
    }
    _pusher?.disconnect();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    await _fetchNotifications();
    await _initRealtimeWebsocket();
  }

  // 1. MEMBUAT HISTORI NOTIFIKASI DARI API
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

  // 2. MENGAKTIFKAN WEBSOCKET REAL-TIME UNTUK LOWONGAN BARU
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

      PusherOptions options = PusherOptions(
        host: ApiConfig.reverbHost,
        wsPort: port,
        wssPort: port,
        encrypted: false, 
        cluster: 'mt1', 
        auth: PusherAuth(
          ApiConfig.broadcastingAuthEndpoint,
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      _pusher = PusherClient(ApiConfig.reverbAppKey, options, autoConnect: false);

      _pusher!.onConnectionStateChange((state) {
        debugPrint("🔌 [Reverb Status]: ${state?.currentState}");
      });

      _pusher!.onConnectionError((error) {
        debugPrint("❌ [Reverb Error]: ${error?.message}");
      });

      await _pusher!.connect();

      _echo = Echo(
        broadcaster: EchoBroadcasterType.Pusher,
        client: _pusher,
      );

      // Mendengarkan channel private notification user
      _echo!.private('App.Models.User.$_userId')
            .listen('.Illuminate\\Notifications\\Events\\BroadcastNotificationCreated', (dynamic event) {
        
        debugPrint("🔥 NOTIFIKASI REAL-TIME MASUK: $event");
        
        final Map<String, dynamic> incoming = Map<String, dynamic>.from(event);

        // Menyesuaikan penangkapan data real-time broadcast dari Laravel
        final String judulRealtime = incoming['judul'] ?? incoming['title'] ?? 'Pemberitahuan Baru';
        final String pesanRealtime = incoming['pesan'] ?? incoming['message'] ?? 'Ada lowongan baru tersedia.';

        if (mounted) {
          setState(() {
            // Masukkan data baru ke urutan paling atas list secara real-time
            _notifications.insert(0, {
              'id': incoming['id'] ?? DateTime.now().millisecondsSinceEpoch,
              'judul': judulRealtime,
              'pesan': pesanRealtime,
              'dibaca': false,
              'dibuat_pada': DateTime.now().toIso8601String(),
            });
          });

          // Munculkan SnackBer di dalam aplikasi secara langsung
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("$judulRealtime\n$pesanRealtime"),
              backgroundColor: const Color(0xFF635147),
            ),
          );
        }
      });

    } catch (e) {
      debugPrint("❌ Gagal inisialisasi real-time (Exception): $e");
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
                            
                            // 🛠️ FIX UTAMA: Membaca langsung sesuai log JSON asli Anda
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