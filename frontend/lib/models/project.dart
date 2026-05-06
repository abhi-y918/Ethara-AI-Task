class ProjectModel {
  final int id;
  final String name;
  final String? description;
  final int createdBy;
  final String createdAt;

  ProjectModel({
    required this.id,
    required this.name,
    this.description,
    required this.createdBy,
    required this.createdAt,
  });

  factory ProjectModel.fromJson(Map<String, dynamic> json) => ProjectModel(
        id: json['id'],
        name: json['name'],
        description: json['description'],
        createdBy: json['created_by'],
        createdAt: json['created_at'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'created_by': createdBy,
      };
}
