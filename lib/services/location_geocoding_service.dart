import 'dart:convert';

import 'package:http/http.dart' as http;

class GeoCoordinates {
  const GeoCoordinates({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}

/// Finds an approximate city-level location. Exact home addresses are never sent.
class LocationGeocodingService {
  static Future<GeoCoordinates?> findPhilippineCity({
    required String city,
    String province = '',
  }) async {
    if (city.trim().isEmpty) return null;
    try {
      final place = [city.trim(), if (province.trim().isNotEmpty) province.trim(), 'Philippines'].join(', ');
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'q': place,
        'format': 'jsonv2',
        'limit': '1',
        'countrycodes': 'ph',
      });
      final response = await http.get(uri, headers: const {
        'User-Agent': 'LifeLink/1.0 (donor map geocoding)',
      });
      if (response.statusCode != 200) return null;
      final results = jsonDecode(response.body) as List<dynamic>;
      if (results.isEmpty) return null;
      final result = results.first as Map<String, dynamic>;
      return GeoCoordinates(
        latitude: double.parse(result['lat'] as String),
        longitude: double.parse(result['lon'] as String),
      );
    } catch (_) {
      return null;
    }
  }

  static Future<String?> findCityAt(GeoCoordinates location) async {
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
        'lat': '${location.latitude}',
        'lon': '${location.longitude}',
        'format': 'jsonv2',
        'zoom': '10',
      });
      final response = await http.get(uri, headers: const {
        'User-Agent': 'LifeLink/1.0 (request location picker)',
      });
      if (response.statusCode != 200) return null;
      final address = (jsonDecode(response.body) as Map<String, dynamic>)['address'] as Map<String, dynamic>?;
      if (address == null) return null;
      for (final key in ['city', 'municipality', 'town', 'village']) {
        final value = address[key] as String?;
        if (value != null && value.trim().isNotEmpty) return value.trim();
      }
    } catch (_) {}
    return null;
  }
}
