import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../../models/weather_code.dart';
import '../poetry/poetry_service.dart';

final weatherServiceProvider = Provider<WeatherService>((ref) {
  return WeatherService(ref.watch(dioProvider));
});

class WeatherSnapshot {
  const WeatherSnapshot({required this.code, this.temperature, this.city});

  final WeatherCode code;
  final int? temperature;
  final String? city;
}

class WeatherService {
  WeatherService(this.dio);

  final Dio dio;

  /// 城市级天气。用户触发时允许弹出系统定位权限。
  Future<WeatherSnapshot?> currentWeather({
    bool requestPermission = true,
  }) async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied && requestPermission) {
        permission = await Geolocator.requestPermission();
      }
      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        return null;
      }
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return null;

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 8),
        ),
      ).timeout(const Duration(seconds: 9));

      String? city;
      try {
        final places = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        ).timeout(const Duration(seconds: 5));
        if (places.isNotEmpty) {
          final place = places.first;
          city = _pickCity(place);
        }
      } catch (_) {
        // 逆地理编码失败不影响天气本身。
      }

      final response = await dio
          .get<dynamic>(
            'https://api.open-meteo.com/v1/forecast',
            queryParameters: {
              'latitude': position.latitude.toStringAsFixed(4),
              'longitude': position.longitude.toStringAsFixed(4),
              'current': 'temperature_2m,weather_code',
              'timezone': 'auto',
            },
            options: Options(
              receiveTimeout: const Duration(seconds: 6),
              sendTimeout: const Duration(seconds: 6),
            ),
          )
          .timeout(const Duration(seconds: 7));

      final data = response.data;
      if (data is! Map) return null;
      final current = data['current'];
      if (current is! Map) return null;
      final rawCode = current['weather_code'];
      if (rawCode is! num) return null;
      final rawTemperature = current['temperature_2m'];
      return WeatherSnapshot(
        code: WeatherCode.fromWmo(rawCode.round()),
        temperature: rawTemperature is num ? rawTemperature.round() : null,
        city: city,
      );
    } catch (_) {
      return null;
    }
  }

  String? _pickCity(Placemark place) {
    for (final value in [
      place.locality,
      place.subAdministrativeArea,
      place.administrativeArea,
    ]) {
      final trimmed = value?.trim();
      if (trimmed != null && trimmed.isNotEmpty) return trimmed;
    }
    return null;
  }
}
