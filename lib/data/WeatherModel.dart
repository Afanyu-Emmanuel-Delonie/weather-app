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
    final current = json['current'];
    return Weather(
      temperature: (current['temperature_2m'] as num).toDouble(),
      windSpeed: (current['wind_speed_10m'] as num).toDouble(),
      weatherCode: current['weather_code'] as int,
      time: current['time'] as String,
      feelsLike: (current['apparent_temperature'] as num).toDouble(),
      humidity: (current['relative_humidity_2m'] as num).round(),
      isDay: current['is_day'] == 1,
    );
  }
}

Future<Weather> fetchWeather(double lat, double lon) async {
  final url = Uri.parse('https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current=temperature_2m,apparent_temperature,relative_humidity_2m,wind_speed_10m,weather_code,is_day');

  final response = await http.get(url);

  if (response.statusCode != 200) {
    throw Exception('Server error: ${response.statusCode}');
  }


  final data = jsonDecode(response.body) as Map<String, dynamic>;
  return Weather.fromJson(data);
}