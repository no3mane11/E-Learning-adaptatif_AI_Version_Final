class User {
  final int id;
  final String nom;
  final String email;
  final String role;
  final String? createdAt;
  final String? updatedAt;
  final bool? isActive;

  User({
    required this.id,
    required this.nom,
    required this.email,
    required this.role,
    this.createdAt,
    this.updatedAt,
    this.isActive,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: (json['id'] is int) ? json['id'] as int : int.parse(json['id'].toString()),
      nom: json['nom'] ?? json['name'] ?? '',
      email: json['email'] ?? '',
      role: (json['role'] ?? '').toString(),
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
      isActive: json['isActive'] != null ? json['isActive'] as bool : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nom': nom,
        'email': email,
        'role': role,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'isActive': isActive,
      };
}
