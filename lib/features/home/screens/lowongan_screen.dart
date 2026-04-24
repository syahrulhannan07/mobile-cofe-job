// lib/features/home/screens/lowongan_screen.dart
import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';

class LowonganScreen extends StatelessWidget {
  const LowonganScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // 1. Header "Lowongan" (Cokelat Muda Kotak)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.symmetric(vertical: 16),
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.brownLight,
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Text(
                "Lowongan",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: AppColors.textMain,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 2. Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                decoration: InputDecoration(
                  hintText: "Search",
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.textMain,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(color: AppColors.textMain),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(color: AppColors.textMain),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 3. Daftar Card Lowongan (Listview Placeholder)
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: 5, // Jumlah card placeholder
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  return Container(
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white, // Card putih murni
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: AppColors.cardOutline,
                        width: 1,
                      ), // Border cokelat tipis
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
