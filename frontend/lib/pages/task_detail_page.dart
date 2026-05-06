import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/task_provider.dart';
import '../models/task.dart';

class TaskDetailPage extends ConsumerWidget {
  final String taskId;
  const TaskDetailPage({super.key, required this.taskId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: load single task by ID
    return Scaffold(
      appBar: AppBar(
        title: Text('Task #$taskId'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: const Center(
        child: Text('Task Detail — TODO', style: TextStyle(color: Colors.white54)),
      ),
    );
  }
}
