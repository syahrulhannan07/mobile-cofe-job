import 'package:flutter_test/flutter_test.dart';

// Simulasi logika validasi yang ada di app
bool isValidToken(String? token) {
  return token != null && token.isNotEmpty;
}

bool isUserLoggedIn(bool? storedValue) {
  return storedValue ?? false;
}

String getNotificationTitle(String? title) {
  return title ?? 'Judul Kosong';
}

String getNotificationBody(String? body) {
  return body ?? 'Isi pesan kosong';
}

void main() {
  group('Auth Logic Tests', () {
    test('isValidToken: token valid', () {
      expect(isValidToken('abc123'), isTrue);
    });

    test('isValidToken: token null = tidak valid', () {
      expect(isValidToken(null), isFalse);
    });

    test('isValidToken: token kosong = tidak valid', () {
      expect(isValidToken(''), isFalse);
    });

    test('isUserLoggedIn: default false jika null', () {
      expect(isUserLoggedIn(null), isFalse);
    });

    test('isUserLoggedIn: true jika tersimpan true', () {
      expect(isUserLoggedIn(true), isTrue);
    });
  });

  group('Notification Content Tests', () {
    test('Judul notifikasi fallback jika null', () {
      expect(getNotificationTitle(null), equals('Judul Kosong'));
    });

    test('Judul notifikasi tampil jika ada', () {
      expect(getNotificationTitle('Ada lowongan baru!'),
          equals('Ada lowongan baru!'));
    });

    test('Body notifikasi fallback jika null', () {
      expect(getNotificationBody(null), equals('Isi pesan kosong'));
    });
  });
}