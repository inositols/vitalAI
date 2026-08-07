class CaregiverModel {
  final String id;
  final String name;
  final String email;
  final bool active;
  final String? relationship;

  CaregiverModel({
    required this.id,
    required this.name,
    required this.email,
    this.active = true,
    this.relationship,
  });

  CaregiverModel copyWith({
    String? id,
    String? name,
    String? email,
    bool? active,
    String? relationship,
  }) {
    return CaregiverModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      active: active ?? this.active,
      relationship: relationship ?? this.relationship,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'active': active,
      'relationship': relationship,
    };
  }

  factory CaregiverModel.fromJson(Map<String, dynamic> json) {
    return CaregiverModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      active: json['active'] as bool? ?? true,
      relationship: json['relationship'] as String?,
    );
  }
}
