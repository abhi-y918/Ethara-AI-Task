import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/task_provider.dart';
import '../models/task.dart';

class ProjectDetailPage extends ConsumerStatefulWidget {
  final String projectId;
  const ProjectDetailPage({super.key, required this.projectId});

  @override
  ConsumerState<ProjectDetailPage> createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends ConsumerState<ProjectDetailPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(taskProvider.notifier).loadTasks(int.parse(widget.projectId)));
  }

  List<TaskModel> _filterByStatus(List<TaskModel> tasks, TaskStatus status) =>
      tasks.where((t) => t.status == status).toList();

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(taskProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Project #${widget.projectId}'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: show create task dialog
        },
        label: const Text('New Task'),
        icon: const Icon(Icons.add),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // TODO: Replace with KanbanColumn widgets
                _buildColumn('To Do', _filterByStatus(state.tasks, TaskStatus.todo), const Color(0xFF7C3AED)),
                _buildColumn('In Progress', _filterByStatus(state.tasks, TaskStatus.in_progress), const Color(0xFF06B6D4)),
                _buildColumn('Done', _filterByStatus(state.tasks, TaskStatus.done), const Color(0xFF10B981)),
              ],
            ),
    );
  }

  Widget _buildColumn(String title, List<TaskModel> tasks, Color color) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Text('(${tasks.length})', style: const TextStyle(color: Colors.white54)),
            ]),
            const SizedBox(height: 12),
            ...tasks.map((t) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(t.title, style: const TextStyle(color: Colors.white)),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
