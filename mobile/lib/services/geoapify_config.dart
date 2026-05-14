import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeoapifyConfig {
  static String get apiKey {
    return dotenv.env['GEOAPIFY_API_KEY'] ?? 'YOUR_API_KEY_HERE';
  }
  
  static const String baseUrl = 'https://maps.geoapify.com/v1';
  static const String staticMapUrl = 'https://maps.geoapify.com/v1/staticmap';
  
  static String getTileUrl(int z, int x, int y) {
    return '$baseUrl/tile/osm-bright/{$z}/{$x}/{$y}.png?apiKey=${apiKey}';
  }
}