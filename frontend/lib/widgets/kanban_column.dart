import 'package:flutter/material.dart';
import '../models/task.dart';
import 'task_card.dart';

class KanbanColumn extends StatelessWidget {
  final String title;
  final List<TaskModel> tasks;
  final Color accentColor;
  final void Function(TaskModel)? onTaskTap;

  const KanbanColumn({
    super.key,
    required this.title,
    required this.tasks,
    required this.accentColor,
    this.onTaskTap,
  });

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E2E),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(width: 10, height: 10, decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(width: 6),
                Text('${tasks.length}', style: TextStyle(color: accentColor, fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (_, i) => TaskCard(task: tasks[i], onTap: () => onTaskTap?.call(tasks[i])),
                ),
              ),
            ],
          ),
        ),
      );
}
