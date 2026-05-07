import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task.dart';
import '../services/task_service.dart';

class TaskState {
  final List<TaskModel> tasks;
  final Map<String, dynamic> dashboardStats;
  final bool isLoading;
  final String? error;

  const TaskState({
    this.tasks = const [],
    this.dashboardStats = const {},
    this.isLoading = false,
    this.error,
  });

  TaskState copyWith({
    List<TaskModel>? tasks,
    Map<String, dynamic>? dashboardStats,
    bool? isLoading,
    String? error,
  }) =>
      TaskState(
        tasks: tasks ?? this.tasks,
        dashboardStats: dashboardStats ?? this.dashboardStats,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class TaskNotifier extends StateNotifier<TaskState> {
  final TaskService _service = TaskService();

  TaskNotifier() : super(const TaskState());

  Future<void> loadTasks(int projectId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final tasks = await _service.getProjectTasks(projectId);
      state = state.copyWith(tasks: tasks, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateTaskStatus(int taskId, TaskStatus status) async {
    try {
      final updated = await _service.updateTask(taskId, {'status': status.name});
      state = state.copyWith(
        tasks: state.tasks.map((t) => t.id == taskId ? updated : t).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> createTask(int projectId, String title, String? description, String dueDate, String priority) async {
    try {
      final task = await _service.createTask(projectId, {
        'title': title,
        'description': description,
        'due_date': dueDate,
        'priority': priority,
      });
      state = state.copyWith(tasks: [...state.tasks, task]);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteTask(int taskId) async {
    try {
      await _service.deleteTask(taskId);
      state = state.copyWith(tasks: state.tasks.where((t) => t.id != taskId).toList());
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> loadDashboard() async {
    try {
      final stats = await _service.getDashboardStats();
      state = state.copyWith(dashboardStats: stats);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final taskProvider = StateNotifierProvider<TaskNotifier, TaskState>(
  (ref) => TaskNotifier(),
);
