import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ayni_app/features/home/presentation/screens/home_screen.dart';
import 'package:ayni_app/features/diagnosis/presentation/providers/diagnosis_provider.dart';
import 'package:ayni_app/shared/widgets/ayni_bottom_nav.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
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

    // Verify we are on home body initially (Juan greeting)
    expect(find.text('¡Hola, Juan!'), findsOneWidget);

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
    expect(find.text('Upgrade Plan to Unlock More!'), findsOneWidget);

    // Verify settings list is shown
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Account & Security'), findsOneWidget);
    expect(find.text('Logout'), findsOneWidget);

    // Scroll logout row into view and tap it
    final logoutFinder = find.text('Logout');
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

  testWidgets('HomeScreen displays interactive disease cards and expert consultation chat simulator', (WidgetTester tester) async {
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

    // Verify we see "Enfermedades Comunes" section
    expect(find.text('Enfermedades Comunes'), findsOneWidget);
    expect(find.text('Roya'), findsOneWidget);
    expect(find.text('Minador'), findsOneWidget);

    // Scroll Roya into view and tap it
    final royaFinder = find.text('Roya');
    await tester.ensureVisible(royaFinder);
    await tester.tap(royaFinder);
    await tester.pumpAndSettle();

    // Verify Bottom Sheet details are shown for Roya
    expect(find.text('Plaga de Café'), findsOneWidget);
    expect(find.text('¿Qué es?'), findsOneWidget);
    expect(find.text('Recomendaciones de Control y Tratamiento'), findsOneWidget);
    expect(find.text('Entendido'), findsOneWidget);

    // Scroll 'Entendido' into view and tap it
    final entendidoFinder = find.text('Entendido');
    await tester.ensureVisible(entendidoFinder);
    await tester.tap(entendidoFinder);
    await tester.pumpAndSettle();

    // Verify bottom sheet is dismissed
    expect(find.text('¿Qué es?'), findsNothing);

    // Scroll 'Consultar Experto' into view and tap it
    final expertTileFinder = find.text('Consultar Experto');
    await tester.ensureVisible(expertTileFinder);
    await tester.tap(expertTileFinder);
    await tester.pumpAndSettle();

    // Verify expert sheet loads
    expect(find.text('Asesores Técnicos de Café'), findsOneWidget);
    expect(find.text('Ing. Carlos Mendoza'), findsOneWidget);
    expect(find.text('Dra. Sofía Altamirano'), findsOneWidget);

    // Tap on Carlos Mendoza to trigger chat simulator dialog
    await tester.tap(find.text('Ing. Carlos Mendoza'));
    await tester.pumpAndSettle();

    // Verify chat simulation dialog is visible
    expect(find.text('Asesor en línea'), findsOneWidget);
    expect(find.text('Escribe tu consulta...'), findsOneWidget);

    // Enter text and click send
    final textInputFinder = find.widgetWithText(TextField, 'Escribe tu consulta...');
    expect(textInputFinder, findsOneWidget);
    await tester.enterText(textInputFinder, 'Hola, tengo Roya');
    await tester.pump();

    final sendButtonFinder = find.byIcon(Icons.send_rounded);
    expect(sendButtonFinder, findsOneWidget);
    await tester.tap(sendButtonFinder);
    await tester.pumpAndSettle();

    // Verify message is shown in chat list
    expect(find.text('Hola, tengo Roya'), findsOneWidget);

    // Wait for the simulated agronomist answer (1.5 seconds mock delay)
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    // Verify reply is rendered
    expect(find.text('Para la Roya del café, te sugiero aplicar caldos minerales (sulfocálcico) preventivamente y retirar hojas enfermas para evitar esporas.'), findsOneWidget);

    // Close the chat simulation dialog
    final closeButtonFinder = find.byIcon(Icons.close);
    await tester.tap(closeButtonFinder);
    await tester.pumpAndSettle();
  });
}
