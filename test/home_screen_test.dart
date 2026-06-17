import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ayni_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:ayni_app/features/home/presentation/screens/home_screen.dart';
import 'package:ayni_app/features/diagnosis/presentation/screens/pest_catalog_screen.dart';
import 'package:ayni_app/features/diagnosis/presentation/screens/pest_detail_screen.dart';
import 'package:ayni_app/shared/widgets/ayni_bottom_nav.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      // Seed SharedPreferences with mock session so bootstrap resolves authenticated
      'auth.currentUser.v1': '{"id":"123","email":"andrew.ainsley@yourdomain.com","fullName":"Andrew Ainsley","role":"farmer","createdAt":"2026-06-17T00:00:00.000Z"}',
      'auth.currentSession.v1': '{"userId":"123","issuedAt":"2026-06-17T00:00:00.000Z","expiresAt":"2026-06-18T00:00:00.000Z"}',
    });
  });

  testWidgets('HomeScreen can navigate to Account tab and show profile details', (WidgetTester tester) async {
    final sharedPrefs = await SharedPreferences.getInstance();
    bool logoutCalled = false;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(sharedPrefs),
        ],
        child: MaterialApp(
          home: HomeScreen(
            isOfflineMode: false,
            onLogout: () {
              logoutCalled = true;
            },
          ),
        ),
      ),
    );

    // Bootstrap session to ensure user is logged in
    final element = tester.element(find.byType(HomeScreen));
    final container = ProviderScope.containerOf(element);
    await container.read(authNotifierProvider.notifier).bootstrap();
    await tester.pumpAndSettle();

    // Verify we are on home body initially (Andrew greeting)
    expect(find.text('¡Hola, Andrew!'), findsOneWidget);

    // Tap the Account tab (represented by Icons.person_outline in bottom navigation)
    final personIconInBottomNav = find.descendant(
      of: find.byType(AyniBottomNav),
      matching: find.byIcon(Icons.person_outline),
    );
    await tester.tap(personIconInBottomNav);
    await tester.pumpAndSettle();

    // Verify profile info is displayed
    expect(find.text('Andrew Ainsley'), findsOneWidget);
    expect(find.text('andrew.ainsley@yourdomain.com'), findsOneWidget);

    // Verify settings list is shown
    expect(find.text('Notificaciones'), findsOneWidget);
    expect(find.text('Mis cultivos'), findsOneWidget);
    expect(find.text('Cerrar sesión'), findsOneWidget);

    // Scroll logout row into view and tap it
    final logoutFinder = find.text('Cerrar sesión');
    await tester.ensureVisible(logoutFinder);
    await tester.tap(logoutFinder);
    await tester.pumpAndSettle();

    // Verify logout dialog appears
    expect(find.text('Cerrar sesión'), findsAtLeast(1));
    expect(find.text('¿Estás seguro de que deseas cerrar sesión?'), findsOneWidget);

    // Tap confirm logout button in dialog
    final confirmButton = find.descendant(
      of: find.byType(TextButton),
      matching: find.text('Cerrar sesión'),
    );
    await tester.tap(confirmButton);
    await tester.pumpAndSettle();

    // Verify logout callback was called
    expect(logoutCalled, isTrue);
  });

  testWidgets('HomeScreen displays disease cards and navigates to pest catalog and details', (WidgetTester tester) async {
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

    // Verify we see "Enfermedades Comunes" section
    expect(find.text('Enfermedades Comunes'), findsOneWidget);
    expect(find.text('Roya'), findsOneWidget);
    expect(find.text('Minador'), findsOneWidget);

    // Navigate to Account tab to find the Pest Catalog option
    final personIconInBottomNav = find.descendant(
      of: find.byType(AyniBottomNav),
      matching: find.byIcon(Icons.person_outline),
    );
    await tester.tap(personIconInBottomNav);
    await tester.pumpAndSettle();

    // Find and tap 'Catálogo de plagas'
    final catalogTileFinder = find.text('Catálogo de plagas');
    await tester.ensureVisible(catalogTileFinder);
    await tester.tap(catalogTileFinder);
    await tester.pumpAndSettle();

    // Verify we are on PestCatalogScreen
    expect(find.byType(PestCatalogScreen), findsOneWidget);
    expect(find.text('Catálogo de Plagas'), findsOneWidget);
    expect(find.text('Roya'), findsOneWidget);

    // Tap on Roya to see detail screen
    final royaTileFinder = find.text('Roya');
    await tester.tap(royaTileFinder);
    await tester.pumpAndSettle();

    // Verify PestDetailScreen displays properly
    expect(find.byType(PestDetailScreen), findsOneWidget);
    expect(find.text('Síntomas Visibles'), findsOneWidget);
    expect(find.text('Control y Tratamiento'), findsOneWidget);
    expect(find.text('Medidas de Prevención'), findsOneWidget);
    expect(find.text('Volver a Diagnosticar'), findsOneWidget);

    // Go back to catalog
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();

    // Verify we are back on catalog screen
    expect(find.byType(PestCatalogScreen), findsOneWidget);

    // Go back to home screen
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();

    // Verify we are back on home/account screen
    expect(find.text('Catálogo de plagas'), findsOneWidget);
  });
}
