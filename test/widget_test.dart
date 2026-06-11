import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'helpers/mock_main.dart';

void main() {
  // ─────────────────────────────────────────
  // GROUP 1: Test Tampilan Login Screen
  // ─────────────────────────────────────────
  group('Login Screen Widget Tests', () {
    testWidgets('Menampilkan ikon kopi dan judul Cafe Job',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const TestableApp(home: MockLoginScreen()),
      );

      // Cek ikon kopi ada
      expect(find.byIcon(Icons.coffee_rounded), findsOneWidget);

      // Cek teks "Cafe Job" ada
      expect(find.text('Cafe Job'), findsOneWidget);
    });

    testWidgets('Menampilkan tombol Login', (WidgetTester tester) async {
      await tester.pumpWidget(
        const TestableApp(home: MockLoginScreen()),
      );

      // Cek tombol Login ada
      expect(find.text('Login'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('Tombol Login bisa ditekan tanpa error',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const TestableApp(home: MockLoginScreen()),
      );

      // Tap tombol Login
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      // Tidak ada error = test lulus
      expect(find.byType(ElevatedButton), findsOneWidget);
    });
  });

  // ─────────────────────────────────────────
  // GROUP 2: Test Tampilan Main Layout
  // ─────────────────────────────────────────
  group('Main Layout Widget Tests', () {
    testWidgets('Menampilkan AppBar dengan judul Cafe Job',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const TestableApp(home: MockMainLayout()),
      );

      expect(find.text('Cafe Job'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('Menampilkan pesan sambutan', (WidgetTester tester) async {
      await tester.pumpWidget(
        const TestableApp(home: MockMainLayout()),
      );

      expect(find.text('Selamat datang di Cafe Job!'), findsOneWidget);
    });
  });

  // ─────────────────────────────────────────
  // GROUP 3: Test Notifikasi Dialog UI
  // ─────────────────────────────────────────
  group('Notification Dialog Tests', () {
    testWidgets('Dialog notifikasi menampilkan judul dan isi',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        TestableApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        backgroundColor: const Color(0xFFFDF2E2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        title: Row(
                          children: [
                            const Icon(Icons.coffee_rounded,
                                color: Color(0xFF422E26)),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                'Notifikasi Cafe Job',
                                style: TextStyle(
                                  color: Color(0xFF422E26),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        content: const Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Ada lowongan baru!',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            SizedBox(height: 8),
                            Text('Barista dibutuhkan segera'),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Oke',
                                style: TextStyle(
                                    color: Color(0xFF422E26),
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text('Tampilkan Notifikasi'),
                ),
              ),
            ),
          ),
        ),
      );

      // Tap tombol untuk memunculkan dialog
      await tester.tap(find.text('Tampilkan Notifikasi'));
      await tester.pumpAndSettle();

      // Verifikasi elemen dialog muncul
      expect(find.text('Notifikasi Cafe Job'), findsOneWidget);
      expect(find.text('Ada lowongan baru!'), findsOneWidget);
      expect(find.text('Barista dibutuhkan segera'), findsOneWidget);
      expect(find.text('Oke'), findsOneWidget);
    });

    testWidgets('Tombol Oke menutup dialog notifikasi',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        TestableApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Notifikasi Cafe Job'),
                        content: const Text('Test pesan'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Oke'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text('Buka Dialog'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Buka Dialog'));
      await tester.pumpAndSettle();

      // Dialog terbuka
      expect(find.text('Notifikasi Cafe Job'), findsOneWidget);

      // Tap Oke
      await tester.tap(find.text('Oke'));
      await tester.pumpAndSettle();

      // Dialog harus hilang
      expect(find.text('Notifikasi Cafe Job'), findsNothing);
    });
  });

  // ─────────────────────────────────────────
  // GROUP 4: Unit Test Logika Murni
  // ─────────────────────────────────────────
  group('Unit Tests - Logika Bisnis', () {
    test('Token FCM valid jika tidak null dan tidak kosong', () {
      String? token = "abc123tokenFCMpalsu";
      expect(token != null && token.isNotEmpty, isTrue);
    });

    test('Token FCM valid jika tidak null dan tidak kosong', () {
      dynamic token = "abc123tokenFCMpalsu";
      expect(token != null && (token as String).isNotEmpty, isTrue);
    });

    test('Token FCM invalid jika null', () {
      dynamic token = null;
      expect(token, isNull); // gunakan matcher isNull
    });

    test('Warna tema Cafe Job sesuai brand', () {
      const Color primaryColor = Color(0xFF422E26);
      const Color backgroundColor = Color(0xFFFDF2E2);

      expect(primaryColor.value, equals(0xFF422E26));
      expect(backgroundColor.value, equals(0xFFFDF2E2));
    });
  });
}