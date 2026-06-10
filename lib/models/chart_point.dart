class ChartPoint {
  final String label;
  final double value;

  const ChartPoint({
    required this.label,
    required this.value,
  });
}

enum ChartMode {
  bar,
  line,
}
