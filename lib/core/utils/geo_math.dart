import 'dart:math';
import 'package:latlong2/latlong.dart';

class GeoMath {
  static const double _earthRadiusKm = 6371.0;

  /// Converte Latitude/Longitude para Grid Maidenhead (6 caracteres, ex: GG67ra)
  static String latLonToMaidenhead(double lat, double lon) {
    final adjLon = (lon + 180.0).clamp(0.0, 359.9999);
    final adjLat = (lat + 90.0).clamp(0.0, 179.9999);

    final fieldLon = String.fromCharCode('A'.codeUnitAt(0) + (adjLon / 20).floor());
    final fieldLat = String.fromCharCode('A'.codeUnitAt(0) + (adjLat / 10).floor());

    final squareLon = ((adjLon % 20) / 2).floor().toString();
    final squareLat = ((adjLat % 10) / 1).floor().toString();

    final subLon = String.fromCharCode(
        'a'.codeUnitAt(0) + (((adjLon % 2) / (2 / 24)).floor()));
    final subLat = String.fromCharCode(
        'a'.codeUnitAt(0) + (((adjLat % 1) / (1 / 24)).floor()));

    return '$fieldLon$fieldLat$squareLon$squareLat$subLon$subLat';
  }

  /// Calcula distância em km entre dois pontos (Haversine)
  static double calculateDistanceKm(LatLng start, LatLng end) {
    final dLat = _degToRad(end.latitude - start.latitude);
    final dLon = _degToRad(end.longitude - start.longitude);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(start.latitude)) *
            cos(_degToRad(end.latitude)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return _earthRadiusKm * c;
  }

  /// Calcula o Azimute Inicial (Rumo em graus 0° - 360°)
  static double calculateAzimuth(LatLng start, LatLng end) {
    final lat1 = _degToRad(start.latitude);
    final lat2 = _degToRad(end.latitude);
    final dLon = _degToRad(end.longitude - start.longitude);

    final y = sin(dLon) * cos(lat2);
    final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
    final bearing = _radToDeg(atan2(y, x));

    return (bearing + 360) % 360;
  }

  /// Gera pontos intermediários ao longo do Círculo Máximo (Great Circle)
  static List<LatLng> getGreatCirclePoints(LatLng start, LatLng end, {int steps = 40}) {
    final lat1 = _degToRad(start.latitude);
    final lon1 = _degToRad(start.longitude);
    final lat2 = _degToRad(end.latitude);
    final lon2 = _degToRad(end.longitude);

    final d = 2 * asin(sqrt(
      pow(sin((lat1 - lat2) / 2), 2) +
          cos(lat1) * cos(lat2) * pow(sin((lon1 - lon2) / 2), 2),
    ));

    if (d < 1e-6) return [start, end];

    final List<LatLng> path = [];
    for (int i = 0; i <= steps; i++) {
      final f = i / steps;
      final a = sin((1 - f) * d) / sin(d);
      final b = sin(f * d) / sin(d);
      final x = a * cos(lat1) * cos(lon1) + b * cos(lat2) * cos(lon2);
      final y = a * cos(lat1) * sin(lon1) + b * cos(lat2) * sin(lon2);
      final z = a * sin(lat1) + b * sin(lat2);
      final lat = atan2(z, sqrt(x * x + y * y));
      final lon = atan2(y, x);
      path.add(LatLng(_radToDeg(lat), _radToDeg(lon)));
    }
    return path;
  }

  /// Gera os pontos da Linha Cinza (Terminador Solar) para o horário UTC atual
  static List<LatLng> getSolarTerminatorPoints(DateTime utcTime) {
    final dayOfYear = utcTime.difference(DateTime.utc(utcTime.year, 1, 1)).inDays + 1;
    final fractionalHour = utcTime.hour + (utcTime.minute / 60.0);

    final declination = _degToRad(
      -23.44 * cos(_degToRad((360.0 / 365.0) * (dayOfYear + 10))),
    );

    final subSolarLon = (12.0 - fractionalHour) * 15.0;

    final List<LatLng> points = [];
    for (double lon = -180.0; lon <= 180.0; lon += 2.0) {
      final hourAngle = _degToRad(lon - subSolarLon);
      final latRad = atan(-cos(hourAngle) / tan(declination));
      points.add(LatLng(_radToDeg(latRad), lon));
    }
    return points;
  }

  static double _degToRad(double deg) => deg * (pi / 180.0);
  static double _radToDeg(double rad) => rad * (180.0 / pi);
}
