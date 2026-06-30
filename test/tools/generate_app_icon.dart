// Herramienta de desarrollo: rasteriza el AyniLogo a un PNG 1024x1024
// con fondo squircle verde primario, para usarlo como ícono de launcher.
//
// Uso: flutter test --update-goldens test/tools/generate_app_icon.dart
// Genera test/tools/app_icon_golden.png
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ayni_app/shared/widgets/ayni_logo.dart';

void main() {
  testWidgets('generate app_icon golden', (tester) async {
    const double canvasSize = 1024;

    await tester.binding.setSurfaceSize(const Size(canvasSize, canvasSize));
    tester.view.physicalSize = const Size(canvasSize, canvasSize);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.binding.setSurfaceSize(null);
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: RepaintBoundary(
          child: AyniLogo(size: canvasSize),
        ),
      ),
    );

    await tester.pump();

    await expectLater(
      find.byType(RepaintBoundary).first,
      matchesGoldenFile('app_icon_golden.png'),
    );
  });
}
