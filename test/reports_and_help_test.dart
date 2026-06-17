import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ayni_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:ayni_app/features/home/presentation/screens/home_screen.dart';
import 'package:ayni_app/features/home/presentation/screens/help_screen.dart';
import 'package:ayni_app/features/reports/presentation/screens/reports_screen.dart';
import 'package:ayni_app/shared/widgets/ayni_bottom_nav.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      // Mock session for auth
      'auth.currentUser.v1': '{"id":"123","email":"diego.rafael@yourdomain.com","fullName":"Diego Rafael","role":"farmer","createdAt":"2026-06-17T00:00:00.000Z"}',
      'auth.currentSession.v1': '{"userId":"123","issuedAt":"2026-06-17T00:00:00.000Z","expiresAt":"2026-06-18T00:00:00.000Z"}',
    });
  });

  testWidgets('HomeScreen should navigate to HelpScreen and show Guide and FAQ tabs', (WidgetTester tester) async {
    final sharedPrefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(sharedPrefs),
        ],
        child: const MaterialApp(
          home: HomeScreen(isOfflineMode: false),
        ),
      ),
    );

    final element = tester.element(find.byType(HomeScreen));
    final container = ProviderScope.containerOf(element);
    await container.read(authNotifierProvider.notifier).bootstrap();
    await tester.pumpAndSettle();

    // Go to Account tab
    final personIconInBottomNav = find.descendant(
      of: find.byType(AyniBottomNav),
      matching: find.byIcon(Icons.person_outline),
    );
    await tester.tap(personIconInBottomNav);
    await tester.pumpAndSettle();

    // Verify "Ayuda" tile exists and tap it
    final helpTile = find.text('Ayuda');
    expect(helpTile, findsOneWidget);
    await tester.tap(helpTile);
    await tester.pumpAndSettle();

    // Verify HelpScreen loaded
    expect(find.byType(HelpScreen), findsOneWidget);
    expect(find.text('Centro de Ayuda'), findsOneWidget);
    expect(find.text('Guía de Captura'), findsOneWidget);
    expect(find.text('Preguntas Frecuentes'), findsOneWidget);

    // Verify contents of capture guide
    expect(find.text('Buena Iluminación'), findsOneWidget);
    expect(find.text('Enfoque Claro'), findsOneWidget);

    // Switch to FAQ tab
    await tester.tap(find.text('Preguntas Frecuentes'));
    await tester.pumpAndSettle();

    // Verify FAQ items
    expect(find.text('¿Cómo funciona el diagnóstico sin conexión (Offline)?'), findsOneWidget);

    // Go back
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();

    expect(find.byType(HelpScreen), findsNothing);
  });

  testWidgets('ReportsScreen shows empty state if there is no diagnosis history', (WidgetTester tester) async {
    final sharedPrefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(sharedPrefs),
        ],
        child: const MaterialApp(
          home: HomeScreen(isOfflineMode: false),
        ),
      ),
    );

    final element = tester.element(find.byType(HomeScreen));
    final container = ProviderScope.containerOf(element);
    await container.read(authNotifierProvider.notifier).bootstrap();
    await tester.pumpAndSettle();

    // Go to Account tab
    final personIconInBottomNav = find.descendant(
      of: find.byType(AyniBottomNav),
      matching: find.byIcon(Icons.person_outline),
    );
    await tester.tap(personIconInBottomNav);
    await tester.pumpAndSettle();

    // Verify "Reportes fitosanitarios" exists and tap it
    final reportsTile = find.text('Reportes fitosanitarios');
    expect(reportsTile, findsOneWidget);
    await tester.ensureVisible(reportsTile);
    await tester.tap(reportsTile);
    await tester.pumpAndSettle();

    // Verify ReportsScreen loaded with empty state
    expect(find.byType(ReportsScreen), findsOneWidget);
    expect(find.text('Reportes Fitosanitarios'), findsOneWidget);
    expect(find.text('Sin datos para reportes'), findsOneWidget);
    expect(find.text('Necesitas realizar al menos un diagnóstico de hojas de café para poder generar y descargar reportes PDF o CSV.'), findsOneWidget);

    // Go back
    await tester.tap(find.byIcon(Icons.arrow_back_ios_rounded));
    await tester.pumpAndSettle();
    expect(find.byType(ReportsScreen), findsNothing);
  });

  testWidgets('ReportsScreen displays stats, previsualizes, downloads and shares when history is populated', (WidgetTester tester) async {
    // Seed SharedPreferences with mock diagnosis history data
    final mockDiagnosisJson = '['
        '  {'
        '    "id": "diag_1",'
        '    "dateTime": "2026-06-17T10:00:00.000Z",'
        '    "originalImagePath": "/path/to/img1.jpg",'
        '    "isOffline": true,'
        '    "isSynced": false,'
        '    "latitude": -12.0463,'
        '    "longitude": -77.0311,'
        '    "detectedLeaves": ['
        '      {'
        '        "id": "leaf_1",'
        '        "boxX": 0.1, "boxY": 0.1, "boxWidth": 0.5, "boxHeight": 0.5,'
        '        "croppedImagePath": "/path/to/crop1.jpg",'
        '        "diagnosedPest": "roya",'
        '        "confidence": 0.90,'
        '        "severity": 0.85'
        '      },'
        '      {'
        '        "id": "leaf_2",'
        '        "boxX": 0.2, "boxY": 0.2, "boxWidth": 0.4, "boxHeight": 0.4,'
        '        "croppedImagePath": "/path/to/crop2.jpg",'
        '        "diagnosedPest": "healthy",'
        '        "confidence": 0.98,'
        '        "severity": 0.0'
        '      }'
        '    ]'
        '  }'
        ']';

    final sharedPrefs = await SharedPreferences.getInstance();
    await sharedPrefs.setString('diagnosis_history_key', mockDiagnosisJson);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(sharedPrefs),
        ],
        child: const MaterialApp(
          home: HomeScreen(isOfflineMode: false),
        ),
      ),
    );

    final element = tester.element(find.byType(HomeScreen));
    final container = ProviderScope.containerOf(element);
    await container.read(authNotifierProvider.notifier).bootstrap();
    await tester.pumpAndSettle();

    // Navigate to Reports screen
    final personIconInBottomNav = find.descendant(
      of: find.byType(AyniBottomNav),
      matching: find.byIcon(Icons.person_outline),
    );
    await tester.tap(personIconInBottomNav);
    await tester.pumpAndSettle();

    final reportsTile = find.text('Reportes fitosanitarios');
    expect(reportsTile, findsOneWidget);
    await tester.ensureVisible(reportsTile);
    await tester.tap(reportsTile);
    await tester.pumpAndSettle();

    // Verify Stats card displays correctly
    expect(find.byType(ReportsScreen), findsOneWidget);
    expect(find.text('Salud Foliar'), findsOneWidget);
    expect(find.text('50.0%'), findsOneWidget); // 1 healthy leaf / 2 total leaves = 50.0%
    expect(find.text('1'), findsOneWidget); // 1 diagnosis
    expect(find.text('Roya'), findsOneWidget); // Stats card plaga principal

    // Tap "Ver" under PDF card
    final viewPdfButton = find.widgetWithText(OutlinedButton, 'Ver').first;
    await tester.ensureVisible(viewPdfButton);
    await tester.tap(viewPdfButton);
    await tester.pumpAndSettle();

    // Verify PDF preview is shown
    expect(find.text('Vista Previa de Impresión PDF'), findsOneWidget);
    expect(find.text('Reporte Fitosanitario de Finca'), findsOneWidget);
    expect(find.text('Diego Rafael Cisneros / Francis Daniel Mamani'), findsOneWidget);

    // Close preview
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Vista Previa de Impresión PDF'), findsNothing);

    // Tap "Descargar" under PDF card
    final downloadPdfButton = find.widgetWithText(OutlinedButton, 'Descargar').first;
    await tester.ensureVisible(downloadPdfButton);
    await tester.tap(downloadPdfButton);
    await tester.pump(); // Pump frame to show opening dialog

    // Verify generator dialog is visible
    expect(find.text('Generando Reporte'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);

    // Wait for simulation to finish
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Verify success SnackBar appeared
    expect(find.textContaining('¡Reporte PDF exportado con éxito!'), findsOneWidget);

    // Tap "Compartir" under PDF card
    final sharePdfButton = find.widgetWithText(OutlinedButton, 'Compartir').first;
    await tester.ensureVisible(sharePdfButton);
    await tester.tap(sharePdfButton);
    await tester.pumpAndSettle();

    // Verify Share Sheet opened
    expect(find.text('Compartir Reporte (PDF)'), findsOneWidget);
    expect(find.text('WhatsApp'), findsOneWidget);

    // Tap WhatsApp option
    await tester.tap(find.text('WhatsApp'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Verify success toast/SnackBar
    expect(find.text('Reporte compartido con éxito vía WhatsApp'), findsOneWidget);
  });

  testWidgets('Dark Mode toggle is not present in Account screen options', (WidgetTester tester) async {
    final sharedPrefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(sharedPrefs),
        ],
        child: const MaterialApp(
          home: HomeScreen(isOfflineMode: false),
        ),
      ),
    );

    final element = tester.element(find.byType(HomeScreen));
    final container = ProviderScope.containerOf(element);
    await container.read(authNotifierProvider.notifier).bootstrap();
    await tester.pumpAndSettle();

    // Navigate to Account screen
    final personIconInBottomNav = find.descendant(
      of: find.byType(AyniBottomNav),
      matching: find.byIcon(Icons.person_outline),
    );
    await tester.tap(personIconInBottomNav);
    await tester.pumpAndSettle();

    // Verify that "Modo oscuro" text is not present
    expect(find.text('Modo oscuro'), findsNothing);
  });
}
