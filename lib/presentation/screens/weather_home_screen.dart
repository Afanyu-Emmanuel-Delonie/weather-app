import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../../data/models/weather_model.dart';
import '../../data/weather_store.dart';

class WeatherHomeScreen extends StatefulWidget {
  const WeatherHomeScreen({super.key});

  @override
  State<WeatherHomeScreen> createState() => _WeatherHomeScreenState();
}

class _WeatherHomeScreenState extends State<WeatherHomeScreen> {
  Weather? _weather;
  DateTime? _savedAt;
  bool _loading = true;
  String? _error;
  String? _offlineNotice;
  String _locationLabel = 'My Location';

  final _uid = FirebaseAuth.instance.currentUser!.uid;

  CollectionReference get _logsRef => FirebaseFirestore.instance
      .collection('users')
      .doc(_uid)
      .collection('weather_logs');

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final cached = await WeatherStore.load();
    if (cached != null && mounted) {
      setState(() {
        _weather = cached.weather;
        _savedAt = cached.savedAt;
        _loading = false;
      });
    }
    await _loadWeather();
  }

  Future<void> _loadWeather() async {
    setState(() {
      _loading = _weather == null;
      _error = null;
      _offlineNotice = null;
    });
    try {
      final pos = await _getPosition();
      final w = await fetchWeather(pos.latitude, pos.longitude);
      await WeatherStore.save(w);
      await _logsRef.add({
        ...w.toMap(),
        'lat': pos.latitude,
        'lon': pos.longitude,
        'fetchedAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      setState(() {
        _weather = w;
        _savedAt = DateTime.now();
        _locationLabel =
            '${pos.latitude.toStringAsFixed(2)}°, ${pos.longitude.toStringAsFixed(2)}°';
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (_weather == null) {
          _error = e is LocationException
              ? e.message
              : 'Could not load weather.\nCheck your internet and try again.';
        } else {
          _offlineNotice =
              'Could not refresh. Showing saved weather from ${_fmt(_savedAt!)}.';
        }
      });
    }
  }

  Future<Position> _getPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationException('Location services are disabled. Please enable GPS.');
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw LocationException('Location permission denied.');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw LocationException(
          'Location permission permanently denied.\nEnable it in app settings.');
    }
    return Geolocator.getCurrentPosition();
  }

  String _fmt(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _todayText() {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = ['January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'];
    final now = DateTime.now();
    return '${days[now.weekday - 1]} ${now.day} ${months[now.month - 1]} ${now.year}';
  }

  IconData _icon(Weather w) {
    if (w.weatherCode >= 95) return Icons.thunderstorm;
    if (w.weatherCode >= 51) return Icons.water_drop;
    if (w.weatherCode >= 2) return Icons.cloud;
    return w.isDay ? Icons.wb_sunny : Icons.nightlight_round;
  }

  Color _iconColor(Weather w) {
    if (w.weatherCode >= 51) return Colors.blue;
    if (w.weatherCode >= 2) return Colors.blueGrey;
    return w.isDay ? Colors.orange : Colors.indigo;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_locationLabel),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadWeather,
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                  minWidth: constraints.maxWidth,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_greeting(),
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Text(_todayText(),
                          style: const TextStyle(fontSize: 16, color: Colors.black45)),
                      const SizedBox(height: 40),
                      if (_loading)
                        const CircularProgressIndicator()
                      else if (_error != null) ...[
                        const Icon(Icons.wifi_off, size: 80, color: Colors.black26),
                        const SizedBox(height: 12),
                        Text(_error!, textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 16)),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _loadWeather,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ] else ...[
                        Icon(_icon(_weather!), size: 120, color: _iconColor(_weather!)),
                        const SizedBox(height: 12),
                        Text('${_weather!.temperature.round()}°C',
                            style: const TextStyle(
                                fontSize: 56, fontWeight: FontWeight.bold)),
                        if (_offlineNotice != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.orange.withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.wifi_off,
                                    size: 18, color: Colors.orange),
                                const SizedBox(width: 8),
                                Expanded(
                                    child: Text(_offlineNotice!,
                                        style: const TextStyle(fontSize: 12.5))),
                                TextButton(
                                    onPressed: _loadWeather,
                                    child: const Text('Retry')),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _StatTile(
                                icon: Icons.thermostat,
                                label: 'Feels like',
                                value: '${_weather!.feelsLike.round()}°'),
                            _StatTile(
                                icon: Icons.water_drop_outlined,
                                label: 'Humidity',
                                value: '${_weather!.humidity}%'),
                            _StatTile(
                                icon: Icons.air,
                                label: 'Wind',
                                value: '${_weather!.windSpeed.round()} km/h'),
                          ],
                        ),
                        const SizedBox(height: 40),
                        _WeatherLogList(logsRef: _logsRef),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _StatTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.black45),
        const SizedBox(height: 6),
        Text(value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label,
            style: const TextStyle(fontSize: 13, color: Colors.black45)),
      ],
    );
  }
}

class _WeatherLogList extends StatelessWidget {
  final CollectionReference logsRef;
  const _WeatherLogList({required this.logsRef});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: logsRef.orderBy('fetchedAt', descending: true).limit(5).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.docs.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Recent fetches',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black45)),
            const SizedBox(height: 8),
            ...snap.data!.docs.map((doc) {
              final d = doc.data() as Map<String, dynamic>;
              final ts = d['fetchedAt'] as Timestamp?;
              final time = ts != null
                  ? ts.toDate().toLocal().toString().substring(11, 16)
                  : '--:--';
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  '$time  •  ${(d['temperature'] as num).round()}°C  '
                  '${(d['humidity'] as num)}% humidity',
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
              );
            }),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }
}

class LocationException implements Exception {
  final String message;
  const LocationException(this.message);
}
