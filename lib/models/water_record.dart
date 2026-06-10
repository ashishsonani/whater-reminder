class WaterRecord {
  final String id;
  final int amount;
  final String type;
  final DateTime createdAt;
  final int? currentIntakeAtTime;
  final int? targetIntakeAtTime;
  final String? userId;
  final bool isMl;
  final String? drinkType;

  WaterRecord({
    required this.id,
    required this.amount,
    required this.type,
    required this.createdAt,
    this.currentIntakeAtTime,
    this.targetIntakeAtTime,
    this.userId,
    this.isMl = true,
    this.drinkType,
  });

  DateTime? get date => createdAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'amount': amount,
    'type': type,
    'createdAt': createdAt.toIso8601String(),
    'currentIntakeAtTime': currentIntakeAtTime,
    'targetIntakeAtTime': targetIntakeAtTime,
    'userId': userId,
    'isMl': isMl,
    'drinkType': drinkType,
  };

  factory WaterRecord.fromJson(Map<String, dynamic> json) => WaterRecord(
    id: json['id'] ?? '',
    amount: json['amount']?.toInt() ?? 0,
    type: json['type'] ?? '',
    createdAt: json['createdAt'] is String
        ? DateTime.parse(json['createdAt'])
        : (json['createdAt'] as dynamic).toDate(),
    currentIntakeAtTime: json['currentIntakeAtTime']?.toInt(),
    targetIntakeAtTime: json['targetIntakeAtTime']?.toInt(),
    userId: json['userId'],
    isMl: json['isMl'] ?? true,
    drinkType: json['drinkType'],
  );
}
