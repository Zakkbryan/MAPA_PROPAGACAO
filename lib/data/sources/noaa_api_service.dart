import 'dart:convert';
import 'package:http/http.dart' as http;

class SolarData {
  final int sfi;
  final double kp;
  final DateTime updatedAt;
  final bool isCached;

  SolarData({
    required this.sfi,
    required this.kp,
    required this.updatedAt,
    this.isCached = false,
  });

  String get geomagneticStatus {
    if (kp >= 5.0) return 'Tempestade (Ruim)';
    if (kp >= 4.0) return 'Instável';
    return 'Calmo (Bom)';
  }
}

class NoaaApiService {
  static const _sfiUrl =
      'https://services.swpc.noaa.gov/products/summary/10cm-flux.json';
  static const _kpUrl =
      'https://services.swpc.noaa.gov/products/noaa-planetary-k-index.json';

  Future<SolarData> fetchSpaceWeather() async {
    try {
      final responses = await Future.wait([
        http.get(Uri.parse(_sfiUrl)).timeout(const Duration(seconds: 8)),
        http.get(Uri.parse(_kpUrl)).timeout(const Duration(seconds: 8)),
      ]);

      int sfi = 120;
      double kp = 2.0;

      if (responses[0].statusCode == 200) {
        final sfiJson = jsonDecode(responses[0].body);
        sfi = int.tryParse(sfiJson['Flux'].toString()) ?? 120;
      }

      if (responses[1].statusCode == 200) {
        final List<dynamic> kpList = jsonDecode(responses[1].body);
        if (kpList.length > 1) {
          final latestRow = kpList.last as List<dynamic>;
          kp = double.tryParse(latestRow[1].toString()) ?? 2.0;
        }
      }

      return SolarData(
        sfi: sfi,
        kp: kp,
        updatedAt: DateTime.now(),
      );
    } catch (_) {
      return SolarData(
        sfi: 135,
        kp: 2.0,
        updatedAt: DateTime.now(),
        isCached: true,
      );
    }
  }
}
