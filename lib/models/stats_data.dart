import 'chart_datum.dart';

class StatsData {
  final int goal;
  final int currentStreak;
  final int longestStreak;
  final List<ChartDatum> chartData;
  StatsData({
    required this.goal,
    required this.currentStreak,
    required this.longestStreak,
    required this.chartData,
  });
}

class StatsDataWrapper {
  final StatsData? data;
  StatsDataWrapper({this.data});
}
