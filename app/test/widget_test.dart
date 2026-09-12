// SAFE//SPIT — smoke widget test
// Verifies the app launches without crashing into the PermissionGate.

import 'package:flutter_test/flutter_test.dart';
import 'package:safespit/main.dart';
import 'package:safespit/services/player_service.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    final playerService = PlayerService();

    // Build our app and trigger a frame.
    await tester.pumpWidget(SafeSpitApp(
      playerService: playerService,
    ));
    await tester.pump(); // First frame

    // The OnboardingScreen shows ENTER CALLSIGN because onboarding is not complete
    expect(find.text('ENTER CALLSIGN'), findsOneWidget);
  });
}
