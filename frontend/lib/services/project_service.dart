import '../models/project.dart';
import 'api_service.dart';

class ProjectService {
  final _dio = ApiService().dio;

  Future<List<ProjectModel>> getProjects() async {
    final res = await _dio.get('/projects/');
    return (res.data as List).map((e) => ProjectModel.fromJson(e)).toList();
  }

  Future<ProjectModel> createProject(String name, String? description) async {
    final res = await _dio.post('/projects/', data: {'name': name, 'description': description});
    return ProjectModel.fromJson(res.data);
  }

  Future<ProjectModel> getProject(int id) async {
    final res = await _dio.get('/projects/$id');
    return ProjectModel.fromJson(res.data);
  }

  Future<void> deleteProject(int id) async {
    await _dio.delete('/projects/$id');
  }

  Future<void> addMember(int projectId, String email) async {
    await _dio.post('/projects/$projectId/members', data: {'email': email});
  }

  Future<void> removeMember(int projectId, int userId) async {
    await _dio.delete('/projects/$projectId/members/$userId');
  }
}
