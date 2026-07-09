import 'package:geolocator/geolocator.dart';

/// Ubicación GPS best-effort para diagnósticos.
///
/// Nunca lanza ni bloquea el flujo de captura: si el GPS está apagado, el
/// permiso fue denegado (incluso permanentemente) o la lectura tarda más de
/// [_timeout], retorna `null` y el diagnóstico simplemente se guarda sin
/// coordenadas. Por ahora la ubicación es opcional; si en el futuro se
/// vuelve obligatoria para algún flujo, ese caller debe pedirla explícitamente
/// y manejar el `null` como bloqueo, no este helper.
class LocationUtils {
  static const _timeout = Duration(seconds: 8);

  static Future<Position?> getCurrentLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: _timeout,
        ),
      );
    } catch (_) {
      return null;
    }
  }
}
