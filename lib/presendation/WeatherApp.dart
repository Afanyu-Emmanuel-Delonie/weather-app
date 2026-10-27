import 'package:flutter/material.dart';
import '../data/WeatherModel.dart';
import '../data/WeatherStore.dart';

class WeatherApp extends StatefulWidget {
  const WeatherApp({super.key});

  @override
  State<WeatherApp> createState() => _WeatherAppState();
}

class _WeatherAppState extends State<WeatherApp> {
  Weather? _weather;
  DateTime? _savedAt;
  bool _loading = true;
  String? _error;
  String? _offlineNotice;

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
      final w = await fetchWeather(-1.9441, 30.0619);
      await WeatherStore.save(w);
      if (!mounted) return;
      setState(() {
        _weather = w;
        _savedAt = DateTime.now();
        _loading = false;
        _error = null;
        _offlineNotice = null;
      });
    } catch (e) {
      debugPrint('Weather error: $e');
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (_weather == null) {
          _error = 'Could not load the weather.\nCheck your internet and try again.';
        } else {
          _offlineNotice = 'Could not refresh. Showing saved weather from ${_formatSavedAt(_savedAt!)}.';
        }
      });
    }
  }

  String _formatSavedAt(DateTime time) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(time.hour)}:${two(time.minute)}';
  }

  void _retry() {
    _loadWeather();
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _todayText() {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July',
      'August', 'September', 'October', 'November', 'December'];
    final now = DateTime.now();
    return '${days[now.weekday - 1]} ${now.day} ${months[now.month - 1]} ${now.year}';
  }

  IconData _weatherIcon(Weather w) {
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
                      Text(
                        _greeting(),
                        style: const TextStyle(color: Colors.black, fontSize: 24, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _todayText(),
                        style: const TextStyle(color: Colors.black45, fontSize: 16),
                      ),
                      const SizedBox(height: 40),
                      if (_loading)
                        const CircularProgressIndicator()
                      else if (_error != null) ...[
                        const Icon(Icons.wifi_off, size: 80, color: Colors.black26),
                        const SizedBox(height: 12),
                        Text(_error!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _retry,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ] else ...[
                        Icon(_weatherIcon(_weather!), size: 120, color: _iconColor(_weather!)),
                        const SizedBox(height: 12),
                        Text(
                          '${_weather!.temperature.round()}°C',
                          style: const TextStyle(fontSize: 56, fontWeight: FontWeight.bold),
                        ),
                        if (_offlineNotice != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.wifi_off, size: 18, color: Colors.orange),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _offlineNotice!,
                                    style: const TextStyle(fontSize: 12.5),
                                  ),
                                ),
                                TextButton(
                                  onPressed: _retry,
                                  child: const Text('Retry'),
                                ),
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
                              value: '${_weather!.feelsLike.round()}°',
                            ),
                            _StatTile(
                              icon: Icons.water_drop_outlined,
                              label: 'Humidity',
                              value: '${_weather!.humidity}%',
                            ),
                            _StatTile(
                              icon: Icons.air,
                              label: 'Wind',
                              value: '${_weather!.windSpeed.round()} km/h',
                            ),
                          ],
                        ),
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
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.black45)),
      ],
    );
  }
}