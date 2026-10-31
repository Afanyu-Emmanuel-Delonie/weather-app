import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/weather_model.dart';

class CachedWeather {
  final Weather weather;
  final DateTime savedAt;
  CachedWeather({required this.weather, required this.savedAt});
}

class WeatherStore {
  static const _key = 'cached_weather';

  static Future<void> save(Weather w) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode({...w.toMap(), 'savedAt': DateTime.now().toIso8601String()}),
    );
  }

  static Future<CachedWeather?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    final d = jsonDecode(raw) as Map<String, dynamic>;
    return CachedWeather(
      weather: Weather(
        temperature: (d['temperature'] as num).toDouble(),
        windSpeed: (d['windSpeed'] as num).toDouble(),
        weatherCode: d['weatherCode'] as int,
        time: d['time'] as String,
        feelsLike: (d['feelsLike'] as num).toDouble(),
        humidity: d['humidity'] as int,
        isDay: d['isDay'] as bool,
      ),
      savedAt: DateTime.parse(d['savedAt'] as String),
    );
  }
}
