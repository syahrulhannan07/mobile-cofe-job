import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:cofe_job/main.dart';

void main() {
  testWidgets('App builds successfully', (WidgetTester tester) async {
    // Build our app
    await tester.pumpWidget(const CafeJobApp());

    // Verify that MaterialApp exists
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
