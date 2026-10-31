import 'dart:convert';
import 'package:http/http.dart' as http;

class Weather {
  final double temperature;
  final double windSpeed;
  final int weatherCode;
  final String time;
  final double feelsLike;
  final int humidity;
  final bool isDay;

  Weather({
    required this.temperature,
    required this.windSpeed,
    required this.weatherCode,
    required this.time,
    required this.feelsLike,
    required this.humidity,
    required this.isDay,
  });

  factory Weather.fromJson(Map<String, dynamic> json) {
    final c = json['current'];
    return Weather(
      temperature: (c['temperature_2m'] as num).toDouble(),
      windSpeed: (c['wind_speed_10m'] as num).toDouble(),
      weatherCode: c['weather_code'] as int,
      time: c['time'] as String,
      feelsLike: (c['apparent_temperature'] as num).toDouble(),
      humidity: (c['relative_humidity_2m'] as num).round(),
      isDay: c['is_day'] == 1,
    );
  }

  Map<String, dynamic> toMap() => {
        'temperature': temperature,
        'windSpeed': windSpeed,
        'weatherCode': weatherCode,
        'time': time,
        'feelsLike': feelsLike,
        'humidity': humidity,
        'isDay': isDay,
      };
}

Future<Weather> fetchWeather(double lat, double lon) async {
  final url = Uri.parse(
    'https://api.open-meteo.com/v1/forecast'
    '?latitude=$lat&longitude=$lon'
    '&current=temperature_2m,apparent_temperature,relative_humidity_2m,'
    'wind_speed_10m,weather_code,is_day',
  );
  final response = await http.get(url);
  if (response.statusCode != 200) {
    throw Exception('Server error: ${response.statusCode}');
  }
  return Weather.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
}
