import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';

class TrackingTimelineScreen extends StatelessWidget {
  final String jobTitle;
  final String companyName;
  final String status;

  const TrackingTimelineScreen({
    super.key,
    required this.jobTitle,
    required this.companyName,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.brownDark,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Tracking Timeline",
          style: TextStyle(
            color: AppColors.brownDark,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card (Info Pekerjaan)
            _buildHeaderCard(),
            const SizedBox(height: 30),

            const Text(
              "Tracking Timeline",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.brownDark,
              ),
            ),
            const SizedBox(height: 25),

            // Timeline List
            _buildTimelineItem(
              title: "Lamaran Dikirim",
              subtitle: "23 Maret 2026 - 10:50",
              description:
                  "Lamaran Anda telah berhasil diterima oleh tim rekrutmen $companyName.",
              isLast: false,
            ),
            _buildTimelineItem(
              title: "Dalam Review",
              subtitle: "23 Maret 2026 - 10:50",
              description:
                  "Tim HRD sedang meninjau portofolio dan pengalaman kerja Anda.",
              isLast: false,
            ),
            _buildTimelineItem(
              title: "Lamaran Diterima",
              subtitle: "24 Maret 2026 - 13:20",
              description:
                  "Lamaran anda lolos seleksi, selanjutnya tunggu informasi jadwal wawancara Anda.",
              isLast: false,
            ),
            _buildTimelineItem(
              title: "Jadwal Wawancara",
              subtitle: "25 Maret 2026 - 10:07",
              description: "Anda diundang untuk sesi wawancara.",
              isLast: true,
              hasAction: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.brownDark,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                jobTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                companyName,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Dikirim pada 23 Maret 2026",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orangeAccent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem({
    required String title,
    required String subtitle,
    required String description,
    required bool isLast,
    bool hasAction = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Indikator Titik dan Garis
        Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppColors.brownDark,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.coffee_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 100, // Menyesuaikan panjang konten
                color: AppColors.brownDark,
              ),
          ],
        ),
        const SizedBox(width: 15),
        // Konten Card Timeline
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            subtitle,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.brownDark.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              description,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                              ),
                            ),
                            if (hasAction) ...[
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orangeAccent,
                                  minimumSize: const Size(double.infinity, 30),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  "Lihat Jadwal",
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),
            ],
          ),
        ),
      ],
    );
  }
}
