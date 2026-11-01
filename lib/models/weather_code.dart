/// 应用内固定的七种天气，数据库保存 [code]。
enum WeatherCode {
  sunny('sunny', '晴'),
  cloudy('cloudy', '多云'),
  overcast('overcast', '阴'),
  rain('rain', '雨'),
  snow('snow', '雪'),
  fog('fog', '雾'),
  wind('wind', '风');

  const WeatherCode(this.code, this.label);

  final String code;
  final String label;

  static WeatherCode? fromCode(String? code) {
    if (code == null) return null;
    for (final weather in WeatherCode.values) {
      if (weather.code == code) return weather;
    }
    return null;
  }

  /// WMO Weather interpretation codes，用于 Open-Meteo 的 `weather_code`。
  static WeatherCode fromWmo(int code) {
    if (code == 0) return WeatherCode.sunny;
    if (code == 1 || code == 2) return WeatherCode.cloudy;
    if (code == 3) return WeatherCode.overcast;
    if (code == 45 || code == 48) return WeatherCode.fog;
    if (code >= 51 && code <= 67) return WeatherCode.rain;
    if (code >= 71 && code <= 77) return WeatherCode.snow;
    if (code >= 80 && code <= 82) return WeatherCode.rain;
    if (code == 85 || code == 86) return WeatherCode.snow;
    if (code >= 95) return WeatherCode.rain;
    return WeatherCode.cloudy;
  }
}
