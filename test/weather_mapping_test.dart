import 'package:flutter_test/flutter_test.dart';
import 'package:yiri/models/mood.dart';
import 'package:yiri/models/weather_code.dart';

void main() {
  test('Open-Meteo WMO 代码映射到七种天气', () {
    expect(WeatherCode.fromWmo(0), WeatherCode.sunny);
    expect(WeatherCode.fromWmo(2), WeatherCode.cloudy);
    expect(WeatherCode.fromWmo(3), WeatherCode.overcast);
    expect(WeatherCode.fromWmo(45), WeatherCode.fog);
    expect(WeatherCode.fromWmo(61), WeatherCode.rain);
    expect(WeatherCode.fromWmo(75), WeatherCode.snow);
    expect(WeatherCode.fromWmo(95), WeatherCode.rain);
  });

  test('天气/心情枚举保持固定语义', () {
    expect(WeatherCode.values.map((e) => e.code), [
      'sunny',
      'cloudy',
      'overcast',
      'rain',
      'snow',
      'fog',
      'wind',
    ]);
    expect(Mood.values.map((e) => e.label), ['很低落', '有点低', '平静', '不错', '很好']);
    expect(Mood.fromValue(5), Mood.great);
    expect(Mood.fromValue(99), isNull);
    expect(WeatherCode.fromCode('rain'), WeatherCode.rain);
    expect(WeatherCode.fromCode('unknown'), isNull);
  });
}
