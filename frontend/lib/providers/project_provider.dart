import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/project.dart';
import '../services/project_service.dart';
import 'package:dio/dio.dart';

String _parseError(Object e) {
  if (e is DioException) {
    final data = e.response?.data;
    if (data is Map && data.containsKey('detail')) {
      return data['detail'].toString();
    }
    return e.message ?? 'Network error';
  }
  return e.toString();
}

class ProjectState {
  final List<ProjectModel> projects;
  final bool isLoading;
  final String? error;

  const ProjectState({this.projects = const [], this.isLoading = false, this.error});

  ProjectState copyWith({List<ProjectModel>? projects, bool? isLoading, String? error}) =>
      ProjectState(projects: projects ?? this.projects, isLoading: isLoading ?? this.isLoading, error: error);
}

class ProjectNotifier extends StateNotifier<ProjectState> {
  final ProjectService _service = ProjectService();

  ProjectNotifier() : super(const ProjectState());

  Future<void> loadProjects() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final projects = await _service.getProjects();
      state = state.copyWith(projects: projects, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
    }
  }

  Future<void> createProject(String name, String? description) async {
    try {
      final project = await _service.createProject(name, description);
      state = state.copyWith(projects: [...state.projects, project]);
    } catch (e) {
      state = state.copyWith(error: _parseError(e));
    }
  }

  Future<void> deleteProject(int id) async {
    try {
      await _service.deleteProject(id);
      state = state.copyWith(projects: state.projects.where((p) => p.id != id).toList());
    } catch (e) {
      state = state.copyWith(error: _parseError(e));
    }
  }

  Future<void> addMember(int projectId, String email) async {
    try {
      await _service.addMember(projectId, email);
    } catch (e) {
      final msg = _parseError(e);
      state = state.copyWith(error: msg);
      throw Exception(msg);
    }
  }
}

final projectProvider = StateNotifierProvider<ProjectNotifier, ProjectState>(
  (ref) => ProjectNotifier(),
);
