class UserModel {
  final int id;
  final String name;
  final String email;
  final bool isSuperadmin;
  final String createdAt;

  UserModel({
    required this.id, 
    required this.name, 
    required this.email, 
    required this.isSuperadmin,
    required this.createdAt
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'],
        name: json['name'],
        email: json['email'],
        isSuperadmin: json['is_superadmin'] ?? false,
        createdAt: json['created_at'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id, 
        'name': name, 
        'email': email,
        'is_superadmin': isSuperadmin,
      };
}
