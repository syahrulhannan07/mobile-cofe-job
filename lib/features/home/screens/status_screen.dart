// lib/features/home/screens/status_screen.dart
import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import 'tracking_timeline_screen.dart';

class StatusScreen extends StatefulWidget {
  const StatusScreen({super.key});

  @override
  State<StatusScreen> createState() => _StatusScreenState();
}

class _StatusScreenState extends State<StatusScreen> {
  // Status default yang terpilih
  String selectedStatus = "SEMUA";

  // List data lamaran (Simulasi data dari API/Database)
  final List<Map<String, dynamic>> allApplications = [
    {
      "logo": Icons.coffee,
      "jobTitle": "Senior Barista",
      "company": "Indra Coffee Roasters",
      "date": "20 Maret 2026",
      "status": "DIPROSES",
      "color": Colors.orange,
    },
    {
      "logo": Icons.precision_manufacturing,
      "jobTitle": "Head Roaster",
      "company": "Mangga Dua Coffee Hub",
      "date": "22 Maret 2026",
      "status": "DITOLAK",
      "color": Colors.redAccent,
    },
    {
      "logo": Icons.room_service,
      "jobTitle": "Service Attendant",
      "company": "Cimanuk Brew House",
      "date": "22 Maret 2026",
      "status": "DITERIMA",
      "color": Colors.green,
    },
    {
      "logo": Icons.manage_accounts,
      "jobTitle": "Outlet Manager",
      "company": "Dermayu Beans & Co.",
      "date": "23 Maret 2026",
      "status": "WAWANCARA",
      "color": Colors.blue,
    },
  ];

  @override
  Widget build(BuildContext context) {
    // Logika Filter: Jika "SEMUA", tampilkan semua. Jika tidak, filter berdasarkan status.
    List<Map<String, dynamic>> filteredApplications = selectedStatus == "SEMUA"
        ? allApplications
        : allApplications
              .where((app) => app['status'] == selectedStatus)
              .toList();

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Header "Status Lamaran"
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.symmetric(vertical: 16),
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.brownLight,
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Text(
                "Status Lamaran",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: AppColors.textMain,
                ),
              ),
            ),

            // Tab Filter Status
            _buildStatusTabs(),

            // Konten Daftar Lamaran
            Expanded(
              child: filteredApplications.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      itemCount: filteredApplications.length,
                      itemBuilder: (context, index) {
                        final app = filteredApplications[index];
                        return _buildStatusCard(
                          context,
                          logo: app['logo'],
                          jobTitle: app['jobTitle'],
                          companyName: app['company'],
                          date: app['date'],
                          status: app['status'],
                          statusColor: app['color'],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget Tab Filter (Ditambah DITOLAK)
  Widget _buildStatusTabs() {
    List<String> tabs = [
      "SEMUA",
      "DIPROSES",
      "WAWANCARA",
      "DITERIMA",
      "DITOLAK",
    ];
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 20),
        itemCount: tabs.length,
        itemBuilder: (context, index) {
          bool isActive = selectedStatus == tabs[index];
          return GestureDetector(
            onTap: () {
              setState(() {
                selectedStatus = tabs[index];
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 25),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isActive ? AppColors.brownDark : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Text(
                tabs[index],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isActive ? AppColors.brownDark : Colors.grey,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Tampilan jika filter tidak menemukan data
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.info_outline, size: 50, color: Colors.grey[400]),
          const SizedBox(height: 10),
          Text(
            "Tidak ada lamaran dengan status $selectedStatus",
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(
    BuildContext context, {
    required IconData logo,
    required String jobTitle,
    required String companyName,
    required String date,
    required String status,
    required Color statusColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.brownDark,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(logo, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      jobTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      companyName,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      "Dikirim pada $date",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          const Divider(color: Colors.white24),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: statusColor.withOpacity(0.5)),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TrackingTimelineScreen(
                        jobTitle: jobTitle,
                        companyName: companyName,
                        status: status,
                      ),
                    ),
                  );
                },
                child: const Row(
                  children: [
                    Text(
                      "Lihat Detail",
                      style: TextStyle(
                        color: AppColors.brownLight,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: AppColors.brownLight,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
