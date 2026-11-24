import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/utils/geo_math.dart';
import '../../data/sources/noaa_api_service.dart';

class HomeMapScreen extends StatefulWidget {
  const HomeMapScreen({super.key});

  @override
  State<HomeMapScreen> createState() => _HomeMapScreenState();
}

class _HomeMapScreenState extends State<HomeMapScreen> {
  final NoaaApiService _noaaService = NoaaApiService();

  // QTH padrão inicial (Campinas/SP - GG67)
  LatLng _myQth = const LatLng(-22.9099, -47.0626);
  // Destino inicial (Lisboa/PT - IM58)
  LatLng _targetQth = const LatLng(38.7223, -9.1393);

  String _selectedBand = '20m';
  SolarData? _solarData;
  bool _loading = true;

  final List<String> _bands = ['80m', '40m', '20m', '15m', '10m'];

  @override
  void initState() {
    super.initState();
    _loadSolarData();
  }

  Future<void> _loadSolarData() async {
    final data = await _noaaService.fetchSpaceWeather();
    if (mounted) {
      setState(() {
        _solarData = data;
        _loading = false;
      });
    }
  }

  String _estimateOpening(double distanceKm, int sfi, double kp) {
    if (kp >= 5.0 && (_selectedBand == '10m' || _selectedBand == '15m')) {
      return 'Fechada / Absorção (Kp alto)';
    }
    if (_selectedBand == '10m' || _selectedBand == '15m') {
      if (sfi >= 140 && distanceKm > 2000) return 'Excelente (DX aberto)';
      if (sfi >= 110) return 'Moderada (Dependente de horário solar)';
      return 'Fraca (SFI baixo para bandas altas)';
    }
    if (_selectedBand == '20m') {
      return distanceKm > 1000 ? 'Aberta (Boa estabilidade)' : 'Zona de Silêncio (Skip)';
    }
    return distanceKm < 2500
        ? 'Aberta (Regional/Curto alcance)'
        : 'Melhor na Linha Cinza/Noite';
  }

  @override
  Widget build(BuildContext context) {
    final distance = GeoMath.calculateDistanceKm(_myQth, _targetQth);
    final azimuth = GeoMath.calculateAzimuth(_myQth, _targetQth);
    final myGrid = GeoMath.latLonToMaidenhead(_myQth.latitude, _myQth.longitude);
    final targetGrid = GeoMath.latLonToMaidenhead(_targetQth.latitude, _targetQth.longitude);
    final terminatorPoints = GeoMath.getSolarTerminatorPoints(DateTime.now().toUtc());
    final greatCirclePath = GeoMath.getGreatCirclePoints(_myQth, _targetQth);

    final sfi = _solarData?.sfi ?? 120;
    final kp = _solarData?.kp ?? 2.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de Propagação HF'),
        actions: [
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                setState(() => _loading = true);
                _loadSolarData();
              },
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: Colors.black54,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'SFI: $sfi',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber),
                ),
                Text(
                  'Kp: ${kp.toStringAsFixed(1)} (${_solarData?.geomagneticStatus ?? "..."})',
                  style: TextStyle(color: kp >= 5 ? Colors.redAccent : Colors.greenAccent),
                ),
                Text('QTH: $myGrid', style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: const LatLng(0, -25),
                initialZoom: 2.2,
                onTap: (tapPosition, point) {
                  setState(() => _targetQth = point);
                },
                onLongPress: (tapPosition, point) {
                  setState(() => _myQth = point);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Novo QTH definido: ${GeoMath.latLonToMaidenhead(point.latitude, point.longitude)}',
                      ),
                    ),
                  );
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                  subdomains: const ['a', 'b', 'c', 'd'],
                  userAgentPackageName: 'br.com.radioamador.hfmap',
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: terminatorPoints,
                      color: Colors.orangeAccent.withOpacity(0.75),
                      strokeWidth: 2.5,
                    ),
                    Polyline(
                      points: greatCirclePath,
                      color: Colors.cyanAccent,
                      strokeWidth: 3.0,
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _myQth,
                      width: 36,
                      height: 36,
                      child: const Icon(Icons.cell_tower, color: Colors.greenAccent, size: 30),
                    ),
                    Marker(
                      point: _targetQth,
                      width: 36,
                      height: 36,
                      child: const Icon(Icons.location_on, color: Colors.redAccent, size: 30),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: _bands.map((band) {
                    final selected = band == _selectedBand;
                    return ChoiceChip(
                      label: Text(band),
                      selected: selected,
                      onSelected: (_) => setState(() => _selectedBand = band),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Alvo: $targetGrid', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('Distância: ${distance.toStringAsFixed(0)} km'),
                    Text('Rumo: ${azimuth.toStringAsFixed(0)}°'),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Previsão ($_selectedBand): ${_estimateOpening(distance, sfi, kp)}',
                  style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Toque no mapa para mudar o destino • Segure para mudar seu QTH.',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
