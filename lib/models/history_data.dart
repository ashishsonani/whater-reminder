class HistoryData {
  final Map<String, DailyGoalStatus>? data;
  HistoryData({this.data});
}

class DailyGoalStatus {
  final bool goalMet;
  DailyGoalStatus({required this.goalMet});
}
