class WaterLogModel {
  final String id;
  final int amountMl;
  final DateTime? date;

  WaterLogModel({
    required this.id,
    required this.amountMl,
    this.date,
  });

  factory WaterLogModel.fromJson(Map<String, dynamic> json) {
    return WaterLogModel(
      id: json['id'] ?? json['_id'] ?? '',
      amountMl: (json['amountMl'] as num?)?.toInt() ?? 0,
      date: json['date'] != null
          ? DateTime.tryParse(json['date'])?.toLocal()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amountMl': amountMl,
      'date': date?.toIso8601String(),
    };
  }
}

class DailyWaterProgress {
  final int totalDrink;
  final int target;
  final double percentage;

  DailyWaterProgress({
    required this.totalDrink,
    required this.target,
    required this.percentage,
  });

  factory DailyWaterProgress.fromJson(Map<String, dynamic> json) {
    return DailyWaterProgress(
      totalDrink: (json['totalDrink'] as num?)?.toInt() ?? 0,
      target: (json['target'] as num?)?.toInt() ?? 2000,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalDrink': totalDrink,
      'target': target,
      'percentage': percentage,
    };
  }
}
