import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ayni_app/features/home/presentation/screens/home_screen.dart';
import 'package:ayni_app/features/home/presentation/widgets/my_plants_body.dart';
import 'package:ayni_app/features/diagnosis/presentation/providers/diagnosis_provider.dart';
import 'package:ayni_app/shared/widgets/ayni_bottom_nav.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('MyPlants tab loads list, handles filters, search, and opens detail sheet', (WidgetTester tester) async {
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

    // Navigate to My Plants tab
    final plantsTabFinder = find.descendant(
      of: find.byType(AyniBottomNav),
      matching: find.byIcon(Icons.eco_outlined),
    );
    expect(plantsTabFinder, findsOneWidget);
    await tester.tap(plantsTabFinder);
    await tester.pumpAndSettle();

    // Verify initial plant list loads
    expect(find.text('Cafeto Bourbon Lote 1'), findsOneWidget);
    expect(find.text('Cafeto Catimor Lote Norte'), findsOneWidget);
    expect(find.text('Cafeto Typica Lote 3'), findsOneWidget);
    expect(find.text('Mis Cafetos (5)'), findsOneWidget);

    // Test Search input
    final searchFieldFinder = find.byType(TextField);
    expect(searchFieldFinder, findsOneWidget);
    await tester.enterText(searchFieldFinder, 'Bourbon');
    await tester.pumpAndSettle();

    // Verify search filtered results (only Bourbon plants should remain)
    expect(find.text('Cafeto Bourbon Lote 1'), findsOneWidget);
    expect(find.text('Cafeto Bourbon Jóvenes'), findsOneWidget);
    expect(find.text('Cafeto Catimor Lote Norte'), findsNothing);
    expect(find.text('Mis Cafetos (2)'), findsOneWidget);

    // Clear search
    await tester.enterText(searchFieldFinder, '');
    await tester.pumpAndSettle();

    // Test Search with no matches
    await tester.enterText(searchFieldFinder, 'Inexistente XYZ');
    await tester.pumpAndSettle();
    expect(find.text('No se encontraron plantas'), findsOneWidget);

    // Clear search again
    await tester.enterText(searchFieldFinder, '');
    await tester.pumpAndSettle();

    // Test Quick Filter Chips
    final sanasChipFinder = find.text('Sanas');
    expect(sanasChipFinder, findsOneWidget);
    await tester.tap(sanasChipFinder);
    await tester.pumpAndSettle();

    // Verify only healthy plants are shown
    expect(find.text('Cafeto Catimor Lote Norte'), findsOneWidget);
    expect(find.text('Cafeto Bourbon Jóvenes'), findsOneWidget);
    expect(find.text('Cafeto Bourbon Lote 1'), findsNothing); // Sick with Roya
    expect(find.text('Mis Cafetos (2)'), findsOneWidget);

    // Go back to all
    await tester.tap(find.text('Todas'));
    await tester.pumpAndSettle();

    // Tap a sick plant to open details bottom sheet
    final sickPlantFinder = find.text('Cafeto Bourbon Lote 1');
    await tester.tap(sickPlantFinder);
    await tester.pumpAndSettle();

    // Verify detail sheet is shown with expected elements
    expect(find.text('Variedad: Bourbon | Lote: Finca La Esperanza'), findsOneWidget);
    expect(find.text('Infección Detectada'), findsOneWidget);
    expect(find.text('Recomendaciones de Cuidado'), findsOneWidget);
    expect(find.text('Volver a Diagnosticar'), findsOneWidget);

    // Ensure button is visible before tapping
    final diagnoseButton = find.text('Volver a Diagnosticar');
    await tester.ensureVisible(diagnoseButton);
    await tester.tap(diagnoseButton);
    await tester.pumpAndSettle();
  });
}
