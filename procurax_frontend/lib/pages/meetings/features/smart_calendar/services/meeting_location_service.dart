import 'dart:convert';
import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../../../../../config/environment.dart';

/// API key for Google Maps / Places.
const String googleMapsApiKey = Environment.androidGoogleMapsApiKey;

/// Service that handles location-related operations for meetings:
/// - Distance calculation (Haversine formula)
/// - Travel time estimation
/// - Google Places autocomplete (via HTTP)
/// - Current location retrieval
class MeetingLocationService {
  // ── Google Places Autocomplete (raw HTTP) ───────────────────────────────

  /// Returns place autocomplete predictions for the given [query].
  /// Optionally biases results near [latitude],[longitude].
  static Future<List<PlacePrediction>> getPlacePredictions(
    String query, {
    double? latitude,
    double? longitude,
  }) async {
    if (query.trim().isEmpty) return [];

    try {
      final params = <String, String>{
        'input': query,
        'key': googleMapsApiKey,
        'language': 'en',
      };

      if (latitude != null && longitude != null) {
        params['location'] = '$latitude,$longitude';
        params['radius'] = '50000'; // 50km bias
      }

      final uri = Uri.https(
        'maps.googleapis.com',
        '/maps/api/place/autocomplete/json',
        params,
      );

      final response = await http.get(uri);
      if (response.statusCode != 200) return [];

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['status'] != 'OK') return [];

      final predictions = json['predictions'] as List<dynamic>;
      return predictions
          .map((p) {
            final structured =
                p['structured_formatting'] as Map<String, dynamic>?;
            return PlacePrediction(
              placeId: p['place_id']?.toString() ?? '',
              mainText:
                  structured?['main_text']?.toString() ??
                  p['description']?.toString() ??
                  '',
              secondaryText: structured?['secondary_text']?.toString() ?? '',
              fullDescription: p['description']?.toString() ?? '',
            );
          })
          .where((p) => p.placeId.isNotEmpty)
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Gets the details (lat/lng, formatted address) for a [placeId].
  static Future<PlaceDetail?> getPlaceDetails(String placeId) async {
    try {
      final uri =
          Uri.https('maps.googleapis.com', '/maps/api/place/details/json', {
            'place_id': placeId,
            'fields': 'geometry,formatted_address,name',
            'key': googleMapsApiKey,
          });

      final response = await http.get(uri);
      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['status'] != 'OK') return null;

      final result = json['result'] as Map<String, dynamic>;
      final geometry = result['geometry'] as Map<String, dynamic>?;
      final location = geometry?['location'] as Map<String, dynamic>?;

      return PlaceDetail(
        formattedAddress: result['formatted_address']?.toString() ?? '',
        name: result['name']?.toString() ?? '',
        latitude: (location?['lat'] as num?)?.toDouble(),
        longitude: (location?['lng'] as num?)?.toDouble(),
      );
    } catch (e) {
      return null;
    }
  }

  // ── Current Location ────────────────────────────────────────────────────

  /// Returns the user's current [Position].
  /// Handles permission request automatically.
  static Future<Position?> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) return null;

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (e) {
      return null;
    }
  }

  // ── Distance Calculation (Haversine) ────────────────────────────────────

  /// Calculates the distance in **kilometers** between two GPS coordinates
  /// using the Haversine formula.
  static double calculateDistanceKm({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) {
    const double earthRadiusKm = 6371.0;

    final dLat = _degreesToRadians(toLat - fromLat);
    final dLng = _degreesToRadians(toLng - fromLng);

    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(fromLat)) *
            math.cos(_degreesToRadians(toLat)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadiusKm * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180;
  }

  /// Returns a human-readable distance string.
  /// e.g. "2.3 km", "450 m"
  static String formatDistance(double distanceKm) {
    if (distanceKm < 1.0) {
      final meters = (distanceKm * 1000).round();
      return '$meters m';
    }
    return '${distanceKm.toStringAsFixed(1)} km';
  }

  // ── Travel Time Estimation ──────────────────────────────────────────────

  /// Estimates driving travel time in **minutes** based on distance.
  /// Uses average speeds:
  /// - < 5 km  → 25 km/h  (city traffic)
  /// - < 30 km → 40 km/h  (suburban)
  /// - ≥ 30 km → 60 km/h  (highway mix)
  /// Adds a 10-minute buffer for parking, walking, etc.
  static int estimateTravelTimeMinutes(double distanceKm) {
    double avgSpeedKmh;

    if (distanceKm < 5) {
      avgSpeedKmh = 25;
    } else if (distanceKm < 30) {
      avgSpeedKmh = 40;
    } else {
      avgSpeedKmh = 60;
    }

    final travelMinutes = (distanceKm / avgSpeedKmh) * 60;
    // Add 10 min buffer for parking, walking to venue, etc.
    return travelMinutes.ceil() + 10;
  }

  /// Returns a human-readable travel time string.
  /// e.g. "~25 min", "~1 hr 15 min"
  static String formatTravelTime(int minutes) {
    if (minutes < 60) {
      return '~$minutes min';
    }
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (remainingMinutes == 0) {
      return '~$hours hr';
    }
    return '~$hours hr $remainingMinutes min';
  }

  /// Calculates the distance from current position to a meeting location
  /// and returns a [DistanceInfo] object.
  static Future<DistanceInfo?> getDistanceToLocation({
    required double meetingLat,
    required double meetingLng,
  }) async {
    final position = await getCurrentLocation();
    if (position == null) return null;

    final distanceKm = calculateDistanceKm(
      fromLat: position.latitude,
      fromLng: position.longitude,
      toLat: meetingLat,
      toLng: meetingLng,
    );

    final travelMinutes = estimateTravelTimeMinutes(distanceKm);

    return DistanceInfo(
      distanceKm: distanceKm,
      travelTimeMinutes: travelMinutes,
      userLat: position.latitude,
      userLng: position.longitude,
    );
  }
}

/// A place prediction from Google Places Autocomplete.
class PlacePrediction {
  final String placeId;
  final String mainText;
  final String secondaryText;
  final String fullDescription;

  const PlacePrediction({
    required this.placeId,
    required this.mainText,
    required this.secondaryText,
    required this.fullDescription,
  });
}

/// Details for a specific place from Google Places Details API.
class PlaceDetail {
  final String formattedAddress;
  final String name;
  final double? latitude;
  final double? longitude;

  const PlaceDetail({
    required this.formattedAddress,
    required this.name,
    this.latitude,
    this.longitude,
  });
}

/// Holds distance + travel time info between the user and a meeting location.
class DistanceInfo {
  final double distanceKm;
  final int travelTimeMinutes;
  final double userLat;
  final double userLng;

  const DistanceInfo({
    required this.distanceKm,
    required this.travelTimeMinutes,
    required this.userLat,
    required this.userLng,
  });

  String get formattedDistance =>
      MeetingLocationService.formatDistance(distanceKm);

  String get formattedTravelTime =>
      MeetingLocationService.formatTravelTime(travelTimeMinutes);
}
