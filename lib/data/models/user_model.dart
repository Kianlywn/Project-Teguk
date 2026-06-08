class UserModel {
  final String id;
  final String fullname;
  final String email;
  final String role;
  final int age;
  final double weight;
  final String gender;
  final String activityLevel;
  final String environmentCondition;
  final int targetWater;

  UserModel({
    required this.id,
    required this.fullname,
    required this.email,
    required this.role,
    this.age = 0,
    this.weight = 0.0,
    this.gender = '',
    this.activityLevel = 'Low',
    this.environmentCondition = 'Normal',
    this.targetWater = 2000,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? json['_id'] ?? '',
      // Menangani inkonsistensi field name dari backend
      fullname: json['fullname'] ?? json['fullName'] ?? 'Tanpa Nama',
      email: json['email'] ?? '',
      role: json['role'] ?? 'User',
      age: json['age'] as int? ?? 0,
      weight: (json['weight'] as num?)?.toDouble() ?? 0.0,
      gender: json['gender'] ?? '',
      activityLevel: json['activityLevel'] ?? 'Low',
      environmentCondition: json['environmentCondition'] ?? 'Normal',
      targetWater: (json['targetWater'] as num?)?.toInt() ?? 2000,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullname': fullname,
      'email': email,
      'role': role,
      'age': age,
      'weight': weight,
      'gender': gender,
      'activityLevel': activityLevel,
      'environmentCondition': environmentCondition,
      'targetWater': targetWater,
    };
  }
}
