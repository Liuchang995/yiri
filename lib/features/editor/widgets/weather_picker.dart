import 'package:flutter/material.dart';

import '../../../core/app_colors.dart';
import '../../../models/weather_code.dart';

IconData weatherIcon(WeatherCode code) {
  return switch (code) {
    WeatherCode.sunny => Icons.wb_sunny_outlined,
    WeatherCode.cloudy => Icons.cloud_outlined,
    WeatherCode.overcast => Icons.cloud,
    WeatherCode.rain => Icons.grain,
    WeatherCode.snow => Icons.ac_unit,
    WeatherCode.fog => Icons.blur_on,
    WeatherCode.wind => Icons.air,
  };
}

Color weatherColor(WeatherCode code, Brightness brightness) {
  final dark = brightness == Brightness.dark;
  return switch (code) {
    WeatherCode.sunny =>
      dark ? const Color(0xFFD9B26A) : const Color(0xFFC6923F),
    WeatherCode.cloudy =>
      dark ? const Color(0xFFA8B0B6) : const Color(0xFF82919A),
    WeatherCode.overcast =>
      dark ? const Color(0xFF9A9FA1) : const Color(0xFF727A7D),
    WeatherCode.rain =>
      dark ? const Color(0xFF8FAFC4) : const Color(0xFF557B96),
    WeatherCode.snow =>
      dark ? const Color(0xFFB8D0D8) : const Color(0xFF7E9FA9),
    WeatherCode.fog => dark ? const Color(0xFFA5A29B) : const Color(0xFF8A857B),
    WeatherCode.wind =>
      dark ? const Color(0xFFAAB4A6) : const Color(0xFF718072),
  };
}

Future<WeatherCode?> showWeatherPicker(BuildContext context) {
  return showModalBottomSheet<WeatherCode>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.32),
    useSafeArea: true,
    isScrollControlled: true,
    builder: (context) => const _WeatherPickerSheet(),
  );
}

class WeatherChip extends StatelessWidget {
  const WeatherChip({
    super.key,
    required this.code,
    required this.temperature,
    required this.onTap,
    this.city,
  });

  final WeatherCode? code;
  final int? temperature;
  final String? city;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final brightness = Theme.of(context).brightness;
    final selected = code;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: colors.field,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected == null
                  ? Icons.add_circle_outline
                  : weatherIcon(selected),
              size: 19,
              color: selected == null
                  ? colors.secondaryText
                  : weatherColor(selected, brightness),
            ),
            const SizedBox(width: 7),
            Text(
              [
                if (city?.trim().isNotEmpty == true) city!.trim(),
                if (selected == null)
                  '选择天气'
                else if (temperature == null)
                  selected.label
                else
                  '${selected.label}  $temperature°',
              ].join(' · '),
              style: TextStyle(
                color: selected == null ? colors.secondaryText : colors.text,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeatherPickerSheet extends StatelessWidget {
  const _WeatherPickerSheet();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final brightness = Theme.of(context).brightness;
    return Material(
      color: colors.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                '选择天气',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: WeatherCode.values.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisExtent: 78,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemBuilder: (context, index) {
                  final weather = WeatherCode.values[index];
                  return InkWell(
                    onTap: () => Navigator.of(context).pop(weather),
                    borderRadius: BorderRadius.circular(12),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.field,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            weatherIcon(weather),
                            size: 24,
                            color: weatherColor(weather, brightness),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            weather.label,
                            style: TextStyle(color: colors.text, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
