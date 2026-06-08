class ConsultationModel {
  final String consultationId;
  final String expertId;
  final String expertName;
  final String userId;
  final String status; // 'Active', 'Completed', dll.
  final DateTime? createdAt;

  ConsultationModel({
    required this.consultationId,
    required this.expertId,
    required this.expertName,
    required this.userId,
    required this.status,
    this.createdAt,
  });

  factory ConsultationModel.fromJson(Map<String, dynamic> json) {
    return ConsultationModel(
      consultationId: json['consultationId'] ?? '',
      expertId: json['expertId'] ?? '',
      expertName: json['expertName'] ?? 'Expert',
      userId: json['userId'] ?? '',
      status: json['status'] ?? '-',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])?.toLocal()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'consultationId': consultationId,
      'expertId': expertId,
      'expertName': expertName,
      'userId': userId,
      'status': status,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
