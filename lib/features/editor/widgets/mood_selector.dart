import 'package:flutter/material.dart';

import '../../../core/app_colors.dart';
import '../../../models/mood.dart';

class MoodSelector extends StatelessWidget {
  const MoodSelector({super.key, required this.value, required this.onChanged});

  final Mood? value;
  final ValueChanged<Mood> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: Mood.values.map((mood) {
        final selected = value == mood;
        final base = Color(mood.colorValue);
        final color = isDark ? Color.lerp(base, Colors.white, 0.15)! : base;
        return Semantics(
          button: true,
          selected: selected,
          label: '心情：${mood.label}',
          child: InkResponse(
            onTap: () => onChanged(mood),
            radius: 24,
            containedInkWell: true,
            child: SizedBox(
              width: 48,
              height: 54,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedScale(
                    scale: selected ? 1.15 : 1,
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: selected
                            ? Border.all(
                                color: colors.text.withValues(alpha: 0.82),
                                width: 1.6,
                              )
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  AnimatedOpacity(
                    opacity: selected ? 1 : 0,
                    duration: const Duration(milliseconds: 150),
                    child: Text(
                      mood.label,
                      style: TextStyle(
                        color: colors.secondaryText,
                        fontSize: 9.5,
                        height: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
