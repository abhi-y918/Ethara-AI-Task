import '../models/task.dart';
import 'api_service.dart';

class TaskService {
  final _dio = ApiService().dio;

  Future<List<TaskModel>> getProjectTasks(int projectId) async {
    final res = await _dio.get('/projects/$projectId/tasks');
    return (res.data as List).map((e) => TaskModel.fromJson(e)).toList();
  }

  Future<TaskModel> createTask(int projectId, Map<String, dynamic> data) async {
    final res = await _dio.post('/projects/$projectId/tasks', data: data);
    return TaskModel.fromJson(res.data);
  }

  Future<TaskModel> getTask(int taskId) async {
    final res = await _dio.get('/tasks/$taskId');
    return TaskModel.fromJson(res.data);
  }

  Future<TaskModel> updateTask(int taskId, Map<String, dynamic> data) async {
    final res = await _dio.patch('/tasks/$taskId', data: data);
    return TaskModel.fromJson(res.data);
  }

  Future<void> deleteTask(int taskId) async {
    await _dio.delete('/tasks/$taskId');
  }

  Future<Map<String, dynamic>> getDashboardStats() async {
    final res = await _dio.get('/dashboard/stats');
    return res.data as Map<String, dynamic>;
  }
}
