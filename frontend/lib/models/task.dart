enum TaskPriority { low, medium, high }
enum TaskStatus { todo, in_progress, done }

class TaskModel {
  final int id;
  final String title;
  final String? description;
  final String dueDate;
  final TaskPriority priority;
  final TaskStatus status;
  final int projectId;
  final int? assignedTo;
  final int createdBy;
  final String createdAt;
  final String? updatedAt;

  TaskModel({
    required this.id,
    required this.title,
    this.description,
    required this.dueDate,
    required this.priority,
    required this.status,
    required this.projectId,
    this.assignedTo,
    required this.createdBy,
    required this.createdAt,
    this.updatedAt,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) => TaskModel(
        id: json['id'],
        title: json['title'],
        description: json['description'],
        dueDate: json['due_date'],
        priority: TaskPriority.values.firstWhere((e) => e.name == json['priority']),
        status: TaskStatus.values.firstWhere((e) => e.name == json['status']),
        projectId: json['project_id'],
        assignedTo: json['assigned_to'],
        createdBy: json['created_by'],
        createdAt: json['created_at'] ?? '',
        updatedAt: json['updated_at'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'due_date': dueDate,
        'priority': priority.name,
        'status': status.name,
        'project_id': projectId,
        'assigned_to': assignedTo,
      };
}
