import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ayni_app/main.dart';
import 'package:ayni_app/features/diagnosis/presentation/providers/diagnosis_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('App boots up showing Splash Screen', (WidgetTester tester) async {
    final sharedPrefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(sharedPrefs),
        ],
        child: const AyniApp(),
      ),
    );

    // Verify Ayni branding or loading indicator is shown initially
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Ayn'), findsOneWidget);

    // Let the splash timer finish to avoid pending timer exception
    await tester.pump(const Duration(seconds: 3));
  });
}
