# AYNI App — Documentación Técnica

> Aplicación móvil Flutter para detección temprana de plagas en hojas de café  
> Autores: Cisneros Tafur, Diego Rafael · Mamani Silva, Francis Daniel  
> Proyecto hermano: [ayni-backend](../ayni-backend/CLAUDE.md) (microservicios Java/Spring Boot)  
> Design system: [design.md](../design.md)

---

## Instrucciones para el Agente

1. **Nunca escribir código sin consultar la documentación de la librería/SDK.** Usar `context7` para verificar APIs de Flutter, Dart, Riverpod, go_router, tflite_flutter, etc., según la versión del proyecto. No asumir que el conocimiento de entrenamiento está actualizado.

2. **Siempre respetar el design system.** Colores, tipografía, espaciado y componentes deben tomarse de `design.md` y de los tokens definidos en `core/constants/`. No inventar valores hardcodeados.

3. **No generar código especulativo.** Si no hay certeza sobre cómo funciona una API en la versión exacta usada, consultar primero.

4. **Arquitectura: Feature-First + Clean Architecture.** Cada feature tiene sus capas `data/`, `domain/`, `presentation/`. No crear carpetas genéricas `models/`, `services/` o `providers/` a nivel de `lib/`.

5. **El código debe ser claro y legible.** Nombres descriptivos, funciones pequeñas con una sola responsabilidad, evitar abreviaciones crípticas.

---

## Stack Tecnológico

| Capa | Tecnología | Versión |
|---|---|---|
| Framework | Flutter | 3.44 |
| Lenguaje | Dart | 3.10 |
| State management | Riverpod | ^3.3.2 |
| Navegación | go_router | ^14.0.0 |
| HTTP client | dio | ^5.0.0 |
| Base de datos local | sqflite | ^2.0.0 |
| ML en dispositivo | tflite_flutter | ^0.11.0 |
| Imágenes | image_picker | ^1.0.0 |
| Compresión | image | ^4.0.0 |
| GPS | geolocator | ^12.0.0 |
| Notificaciones push | firebase_messaging | ^15.0.0 |
| Diseño | Material Design 3 | — |
| Inyección de dependencias | Riverpod providers | — |

---

## Estructura de Carpetas

```
ayni_app/
├── lib/
│   ├── main.dart
│   │
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_colors.dart        # Design tokens: colores
│   │   │   ├── app_text_styles.dart   # Design tokens: tipografía Nunito
│   │   │   ├── app_spacing.dart       # Design tokens: espaciado (8px base)
│   │   │   ├── app_breakpoints.dart   # Breakpoints responsive
│   │   │   └── app_strings.dart       # Strings de la app (español peruano)
│   │   ├── errors/
│   │   │   ├── failures.dart          # Failure classes (Either<Failure, Success>)
│   │   │   └── exceptions.dart        # Excepciones tipadas
│   │   ├── network/
│   │   │   ├── api_client.dart        # Cliente HTTP dio con interceptors
│   │   │   ├── connectivity_service.dart  # Detección online/offline
│   │   │   └── auth_interceptor.dart  # Adjunta JWT a cada request
│   │   └── utils/
│   │       ├── compression_utils.dart  # Comprimir imagen a ≤800 KB
│   │       ├── location_utils.dart     # Helper GPS
│   │       └── formatters.dart        # Format date, confidence, etc.
│   │
│   ├── features/
│   │   ├── auth/
│   │   │   ├── data/
│   │   │   │   ├── datasources/
│   │   │   │   │   ├── auth_remote_datasource.dart
│   │   │   │   │   └── auth_local_datasource.dart    # SharedPreferences tokens
│   │   │   │   ├── models/
│   │   │   │   │   └── auth_models.dart              # AuthResponse, UserDto
│   │   │   │   └── repositories/
│   │   │   │       └── auth_repository_impl.dart
│   │   │   ├── domain/
│   │   │   │   ├── entities/
│   │   │   │   │   └── user.dart
│   │   │   │   ├── repositories/
│   │   │   │   │   └── auth_repository.dart          # Abstract
│   │   │   │   └── usecases/
│   │   │   │       ├── login_usecase.dart
│   │   │   │       ├── register_usecase.dart
│   │   │   │       └── logout_usecase.dart
│   │   │   └── presentation/
│   │   │       ├── screens/
│   │   │       │   ├── login_screen.dart
│   │   │       │   ├── register_screen.dart
│   │   │       │   └── splash_screen.dart
│   │   │       ├── widgets/
│   │   │       │   └── auth_form.dart
│   │   │       └── providers/
│   │   │           └── auth_provider.dart            # Riverpod providers
│   │   │
│   │   ├── diagnosis/
│   │   │   ├── data/
│   │   │   │   ├── datasources/
│   │   │   │   │   ├── diagnosis_remote_datasource.dart
│   │   │   │   │   └── diagnosis_local_datasource.dart  # SQLite
│   │   │   │   ├── models/
│   │   │   │   │   ├── diagnosis_model.dart
│   │   │   │   │   └── pest_result_model.dart
│   │   │   │   └── repositories/
│   │   │   │       └── diagnosis_repository_impl.dart
│   │   │   ├── domain/
│   │   │   │   ├── entities/
│   │   │   │   │   ├── diagnosis.dart
│   │   │   │   │   └── pest_type.dart                 # Enum: RUST, MINER, PHOMA, HEALTHY
│   │   │   │   ├── repositories/
│   │   │   │   │   └── diagnosis_repository.dart
│   │   │   │   └── usecases/
│   │   │   │       ├── analyze_image_usecase.dart
│   │   │   │       ├── analyze_offline_usecase.dart   # TFLite local
│   │   │   │       └── sync_diagnoses_usecase.dart
│   │   │   └── presentation/
│   │   │       ├── screens/
│   │   │       │   ├── diagnosis_capture_screen.dart  # Pantalla principal: botón captura
│   │   │       │   ├── diagnosis_result_screen.dart   # Resultado con Grad-CAM
│   │   │       │   └── diagnosis_history_screen.dart
│   │   │       ├── widgets/
│   │   │       │   ├── capture_button.dart            # Botón dominante 72×72 min
│   │   │       │   ├── confidence_bar.dart
│   │   │       │   ├── pest_badge.dart
│   │   │       │   └── gradcam_viewer.dart
│   │   │       └── providers/
│   │   │           ├── diagnosis_provider.dart
│   │   │           └── tflite_provider.dart           # TFLite interpreter
│   │   │
│   │   ├── sync/
│   │   │   ├── data/
│   │   │   │   ├── datasources/
│   │   │   │   │   └── sync_local_datasource.dart     # SQLite sync_queue
│   │   │   │   ├── models/
│   │   │   │   │   └── sync_item_model.dart
│   │   │   │   └── repositories/
│   │   │   │       └── sync_repository_impl.dart
│   │   │   ├── domain/
│   │   │   │   ├── entities/
│   │   │   │   │   └── sync_item.dart
│   │   │   │   ├── repositories/
│   │   │   │   │   └── sync_repository.dart
│   │   │   │   └── usecases/
│   │   │   │       └── sync_pending_usecases.dart
│   │   │   └── presentation/
│   │   │       ├── screens/
│   │   │       │   └── sync_status_screen.dart
│   │   │       └── providers/
│   │   │           └── sync_provider.dart
│   │   │
│   │   ├── crops/
│   │   │   ├── data/...
│   │   │   ├── domain/...
│   │   │   └── presentation/...
│   │   │
│   │   ├── profile/
│   │   │   ├── data/...
│   │   │   ├── domain/...
│   │   │   └── presentation/...
│   │   │
│   │   └── notifications/
│   │       ├── data/...
│   │       ├── domain/...
│   │       └── presentation/...
│   │
│   ├── shared/
│   │   ├── widgets/
│   │   │   ├── ayni_button.dart        # Primary, Secondary, Social variants
│   │   │   ├── ayni_text_field.dart    # TextField según design.md
│   │   │   ├── ayni_loading_overlay.dart
│   │   │   ├── confidence_bar.dart
│   │   │   ├── pest_badge.dart
│   │   │   └── offline_indicator.dart
│   │   └── theme/
│   │       └── app_theme.dart          # ThemeData con colorScheme, textTheme
│   │
│   └── router/
│       └── app_router.dart             # go_router configuration
│
├── assets/
│   └── icons/
│
├── pubspec.yaml
└── README.md
```

---

## Convenciones de Código

### Nomenclatura de archivos
```
Archivos Dart:     snake_case.dart  → diagnosis_capture_screen.dart, pest_type.dart
Widgets:           PascalCase      → DiagnosisCaptureScreen, PestBadge
Providers:         camelCase + Provider suffix → diagnosisProvider, authProvider
```

### Nomenclatura de clases y variables
```
Clases/Widgets:    PascalCase       → class DiagnosisCaptureScreen
Métodos/vars:      camelCase        → analyzePestImage(), confidenceScore
Constantes:        kPascalCase      → kPrimaryGreen, kMaxImageSizeMb
Enums:             PascalCase       → PestType, DiagnosisSource
```

### Reglas de código
- **Nunito** como única fuente (del package `google_fonts`)
- Sin `final` innecesario en campos de clase que mutan
- Inyección de dependencias vía Riverpod (`ref.read`, `ref.watch`)
- Errors como `Failure` (tipeados), nunca strings sueltos
- Async: `try/catch` con `Left(Failure(...))` para errores

---

## Flujo Offline-First (Crítico)

### Diagnóstico online (conexión disponible)
```
1. image_picker → capturar foto
2. CompressionUtils.compress() → ≤ 800 KB
3. ConnectivityService.isConnected() == true
4. ApiClient.post('/diagnoses/analyze', multipart)
5. Mostrar resultado con Grad-CAM
6. Guardar en historial SQLite local
```

### Diagnóstico offline (sin conexión)
```
1. image_picker → capturar foto
2. CompressionUtils.compress() → ≤ 800 KB
3. ConnectivityService.isConnected() == false
4. TFLiteProvider.infer(imageBytes) → pestType + confidence (sin Grad-CAM)
5. SQLite: insert into sync_queue (status: PENDING)
6. Mostrar resultado local inmediatamente
```

### Sincronización al recuperar conexión
```
1. ConnectivityService detecta conexión restaurada
2. SyncProvider.syncPending() → lee SQLite sync_queue
3. ApiClient.post('/sync/batch', items)
4. Por cada item: marca DONE en SQLite
5. NotificationService.fire('Diagnósticos sincronizados')
```

---

## Configuración de Proyecto

### pubspec.yaml (dependencias requeridas)
```yaml
dependencies:
  flutter:
    sdk: flutter

  # State management
  flutter_riverpod: ^3.3.2
  riverpod_annotation: ^3.0.0

  # Navegación
  go_router: ^14.0.0

  # HTTP
  dio: ^5.0.0

  # Base de datos local
  sqflite: ^2.0.0
  path: ^1.9.0

  # ML
  tflite_flutter: ^0.11.0
  image: ^4.0.0

  # Imágenes
  image_picker: ^1.0.0

  # GPS
  geolocator: ^12.0.0

  # Notificaciones push
  firebase_messaging: ^15.0.0
  firebase_core: ^3.0.0

  # UI
  google_fonts: ^6.0.0
  lucide_icons: ^0.200.0
  cached_network_image: ^3.0.0

  # Utils
  equatable: ^2.0.0
  intl: ^0.19.0
  connectivity_plus: ^6.0.0
  shared_preferences: ^2.0.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
  riverpod_generator: ^3.0.0
  build_runner: ^2.4.0
```

### Android (minSdkVersion)
```gradle
// android/app/build.gradle.kts
minSdkVersion = 26  # Android 8.0 — requerido por tflite_flutter y geolocator
```

### Assets
```yaml
flutter:
  assets:
    - assets/icons/
    - assets/models/    # modelos TFLite .tflite
```

---

## Design Tokens (del design.md)

### Colores (app_colors.dart)
```dart
class AppColors {
  // Brand
  static const Color primary   = Color(0xFF04A033);
  static const Color secondary = Color(0xFFDDFFE7);

  // State
  static const Color info    = Color(0xFFC2BFBF);
  static const Color success = Color(0xFF27AE60);
  static const Color warning = Color(0xFFE2B93B);
  static const Color error   = Color(0xFFEB5757);

  // Black
  static const Color black1 = Color(0xFF000000);
  static const Color black2 = Color(0xFF1D1D1D);
  static const Color black3 = Color(0xFF282828);

  // Grey
  static const Color gray1 = Color(0xFF333333);
  static const Color gray2 = Color(0xFF4F4F4F);
  static const Color gray3 = Color(0xFF828282);
  static const Color gray4 = Color(0xFFBDBDBD);
  static const Color gray5 = Color(0xFFE0E0E0);

  static const Color white = Color(0xFFFFFFFF);
}
```

### Espaciado (app_spacing.dart)
```dart
class AppSpacing {
  static const double s1  = 8;
  static const double s2  = 16;
  static const double s3  = 24;
  static const double s4  = 32;
  static const double s5  = 40;
  static const double s6  = 56;
  static const double s7  = 72;
  static const double s8  = 80;
  static const double s9  = 96;
  static const double s10 = 120;
}
```

---

## Reglas de UI/UX

### Tamaño mínimo de tap: 48×48 dp
(Accesibilidad para usuarios con guantes de trabajo en campo)

### Botón de captura (pantalla principal)
- Elemento visual dominante
- Tamaño mínimo: 72×72 dp
- Icono: camera_alt · 32 px

### Indicador de confianza de diagnóstico
- ≥ 85% → color success (verde)
- 60–84% → color warning (amarillo)
- < 60% → color error (rojo)

### Conectividad offline
- Banner superior fixed con color warning y texto "Sin conexión — diagnósticos guardados localmente"
- Icono: cloud_off

### Textos en español peruano simple
(No usar jerga técnica. Dirigido a caficultores con baja alfabetización digital)

---

## API Base URL

```
API Gateway local desarrollo: http://10.0.2.2:8080/api
(Android emulator usa 10.0.2.2 para localhost del host)

Production: https://api.ayni.pe/api
```

### Endpoints principales
| Método | Ruta | Descripción |
|---|---|---|
| POST | `/auth/login` | Login, retorna JWT |
| POST | `/auth/register` | Registro |
| POST | `/auth/forgot-password` | Recuperar contraseña — envía código OTP de 6 dígitos por correo (HU0039) |
| POST | `/auth/reset-password` | Confirmar el reseteo con `{ email, code, newPassword }` (HU0039) |
| POST | `/diagnoses/analyze` | Diagnóstico online (multipart) |
| POST | `/sync/batch` | Sincronizar lote offline |
| GET | `/history` | Historial de diagnósticos |
| GET | `/notifications` | Notificaciones push |

---

## Testing

```bash
# Unit tests
flutter test

# Widget tests
flutter test widget_test.dart

# Integration tests
flutter test integration_test/

# Run with coverage
flutter test --coverage
```

---

*Documentación generada para el proyecto Ayni — Ciclo 2026-1*
*UPC — Programa Académico de Ingeniería de Software*
