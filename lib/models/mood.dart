/// 五档心情。颜色值是低饱和的冷灰到暖橙，不依赖 Flutter 类型，便于
/// 在后台 isolate 与单元测试中直接使用。
enum Mood {
  veryLow(1, '很低落', 0xFF7E8689),
  low(2, '有点低', 0xFF9B9993),
  calm(3, '平静', 0xFFA9A493),
  good(4, '不错', 0xFFC39A70),
  great(5, '很好', 0xFFCF8955);

  const Mood(this.value, this.label, this.colorValue);

  final int value;
  final String label;
  final int colorValue;

  static Mood? fromValue(int? value) {
    if (value == null) return null;
    for (final mood in Mood.values) {
      if (mood.value == value) return mood;
    }
    return null;
  }
}
