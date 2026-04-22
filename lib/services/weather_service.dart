import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherData {
  final double temperature;
  final int humidity;
  final double rainfall;
  final String description;
  final DateTime lastUpdated;

  WeatherData({
    required this.temperature,
    required this.humidity,
    required this.rainfall,
    required this.description,
    required this.lastUpdated,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      temperature: (json['main']['temp'] as num).toDouble() - 273.15,
      humidity: json['main']['humidity'] as int,
      rainfall: (json['rain']?['1h'] as num?)?.toDouble() ?? 0.0,
      description: json['weather'][0]['description'] as String,
      lastUpdated: DateTime.now(),
    );
  }
}

class WeatherService {
  static const String _apiKey = 'YOUR_OPENWEATHERMAP_API_KEY';
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5/weather';
  static const String _city = 'Nairobi';

  static Future<WeatherData?> fetchWeather() async {
    try {
      final url = Uri.parse('$_baseUrl?q=$_city&appid=$_apiKey');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return WeatherData.fromJson(data);
      } else {
        print('Weather API error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Weather fetch error: $e');
      return null;
    }
  }
}
