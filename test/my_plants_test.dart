import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ayni_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:ayni_app/features/home/presentation/screens/home_screen.dart';
import 'package:ayni_app/shared/widgets/ayni_bottom_nav.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      // Auth data so HomeScreen doesn't boot to guest / loading
      'auth.currentUser.v1': '{"id":"123","email":"andrew.ainsley@yourdomain.com","fullName":"Andrew Ainsley","role":"farmer","createdAt":"2026-06-17T00:00:00.000Z"}',
      'auth.currentSession.v1': '{"userId":"123","issuedAt":"2026-06-17T00:00:00.000Z","expiresAt":"2026-06-18T00:00:00.000Z"}',
      // Crops data
      'parcels_key': '[{"id":"parcel-1","name":"Parcela Alta","farmName":"Finca La Esperanza","sizeHectares":2.5,"variety":"Bourbon","plantCount":1,"createdAt":"2026-06-17T00:00:00.000Z","updatedAt":"2026-06-17T00:00:00.000Z"},{"id":"parcel-2","name":"Parcela Baja","farmName":"Finca Santa Teresa","sizeHectares":1.8,"variety":"Catimor","plantCount":1,"createdAt":"2026-06-17T00:00:00.000Z","updatedAt":"2026-06-17T00:00:00.000Z"}]',
      'crops_key': '[{"id":"crop-1","parcelId":"parcel-1","name":"Cafeto Bourbon Lote 1","variety":"bourbon","plantingDate":"2026-06-17T00:00:00.000Z","status":"withPest","lastDiagnosisDaysAgo":2,"lastDiagnosisPest":"roya","latitude":-12.0463,"longitude":-77.0311,"createdAt":"2026-06-17T00:00:00.000Z","updatedAt":"2026-06-17T00:00:00.000Z"},{"id":"crop-2","parcelId":"parcel-2","name":"Cafeto Catimor Lote Norte","variety":"catimor","plantingDate":"2026-06-17T00:00:00.000Z","status":"healthy","lastDiagnosisDaysAgo":0,"lastDiagnosisPest":null,"latitude":-12.0463,"longitude":-77.0311,"createdAt":"2026-06-17T00:00:00.000Z","updatedAt":"2026-06-17T00:00:00.000Z"}]',
    });
  });

  testWidgets('MyPlants tab loads list, handles filters, search, and opens detail screen', (WidgetTester tester) async {
    final sharedPrefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(sharedPrefs),
        ],
        child: const MaterialApp(
          home: HomeScreen(
            isOfflineMode: false,
          ),
        ),
      ),
    );

    // Bootstrap session to ensure user is logged in
    final element = tester.element(find.byType(HomeScreen));
    final container = ProviderScope.containerOf(element);
    await container.read(authNotifierProvider.notifier).bootstrap();
    await tester.pumpAndSettle();

    // Navigate to My Plants tab
    final plantsTabFinder = find.descendant(
      of: find.byType(AyniBottomNav),
      matching: find.byIcon(Icons.eco_outlined),
    );
    expect(plantsTabFinder, findsOneWidget);
    await tester.tap(plantsTabFinder);
    await tester.pumpAndSettle();

    // Verify initial parcel list loads
    expect(find.text('Parcela Alta'), findsOneWidget);
    expect(find.text('Parcela Baja'), findsOneWidget);
    expect(find.text('2 plantas registradas'), findsOneWidget);

    // Test Search input
    final searchFieldFinder = find.byType(TextField);
    expect(searchFieldFinder, findsOneWidget);
    await tester.enterText(searchFieldFinder, 'Bourbon');
    await tester.pumpAndSettle();

    // Verify search filtered results (only Bourbon parcel should remain)
    expect(find.text('Parcela Alta'), findsOneWidget);
    expect(find.text('Parcela Baja'), findsNothing);

    // Clear search
    await tester.enterText(searchFieldFinder, '');
    await tester.pumpAndSettle();

    // Test Search with no matches
    await tester.enterText(searchFieldFinder, 'Inexistente XYZ');
    await tester.pumpAndSettle();
    expect(find.text('No se encontraron parcelas'), findsOneWidget);

    // Clear search again
    await tester.enterText(searchFieldFinder, '');
    await tester.pumpAndSettle();

    // Test Quick Filter/Stats Chips are present
    expect(find.text('1 Sanas'), findsOneWidget);
    expect(find.text('1 Con plaga'), findsOneWidget);

    // Tap a parcel to open its detail screen
    final parcelFinder = find.text('Parcela Alta');
    await tester.tap(parcelFinder);
    await tester.pumpAndSettle();

    // Verify detail screen is shown with expected elements
    expect(find.text('Parcela Alta'), findsAtLeast(1));
    expect(find.text('Cafeto Bourbon Lote 1'), findsOneWidget);
    expect(find.text('Agregar planta'), findsOneWidget);
  });
}
