import 'package:flutter/material.dart';

// Versi CafeJobApp yang bisa di-test tanpa Firebase
class TestableApp extends StatelessWidget {
  final Widget home;
  const TestableApp({super.key, required this.home});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cafe Job Test',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'sans-serif', useMaterial3: true),
      home: home,
    );
  }
}

// Widget sederhana untuk simulasi halaman login
class MockLoginScreen extends StatelessWidget {
  const MockLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF2E2),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.coffee_rounded, 
              size: 80, color: Color(0xFF422E26)),
            const SizedBox(height: 16),
            const Text(
              'Cafe Job',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF422E26),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {},
              child: const Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget sederhana untuk simulasi halaman utama
class MockMainLayout extends StatelessWidget {
  const MockMainLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cafe Job'),
        backgroundColor: const Color(0xFF422E26),
      ),
      body: const Center(
        child: Text('Selamat datang di Cafe Job!'),
      ),
    );
  }
}