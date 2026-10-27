import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'WeatherModel.dart';

class CachedWeather {
  final Weather weather;
  final DateTime savedAt;

  CachedWeather({required this.weather, required this.savedAt});
}

class WeatherStore {
  static const _key = 'cached_weather';

  static Future<void> save(Weather weather) async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'temperature': weather.temperature,
      'windSpeed': weather.windSpeed,
      'weatherCode': weather.weatherCode,
      'time': weather.time,
      'feelsLike': weather.feelsLike,
      'humidity': weather.humidity,
      'isDay': weather.isDay,
      'savedAt': DateTime.now().toIso8601String(),
    };
    await prefs.setString(_key, jsonEncode(data));
  }

  static Future<CachedWeather?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;

    final data = jsonDecode(raw) as Map<String, dynamic>;
    final weather = Weather(
      temperature: (data['temperature'] as num).toDouble(),
      windSpeed: (data['windSpeed'] as num).toDouble(),
      weatherCode: data['weatherCode'] as int,
      time: data['time'] as String,
      feelsLike: (data['feelsLike'] as num).toDouble(),
      humidity: data['humidity'] as int,
      isDay: data['isDay'] as bool,
    );
    return CachedWeather(
      weather: weather,
      savedAt: DateTime.parse(data['savedAt'] as String),
    );
  }
}
