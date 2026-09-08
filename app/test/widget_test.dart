// SAFE//SPIT — smoke widget test
// Verifies the app launches without crashing into the PermissionGate.

import 'package:flutter_test/flutter_test.dart';
import 'package:safespit/main.dart';

void main() {
  testWidgets('App launches and shows SAFE//SPIT branding', (WidgetTester tester) async {
    await tester.pumpWidget(const SafeSpitApp());
    await tester.pump(); // First frame

    // The PermissionGate shows SAFE//SPIT title
    expect(find.text('SAFE//SPIT'), findsWidgets);
  });
}
