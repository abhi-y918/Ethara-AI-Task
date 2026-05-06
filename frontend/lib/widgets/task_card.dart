import 'package:flutter/material.dart';
import '../models/task.dart';
import 'priority_badge.dart';

class TaskCard extends StatelessWidget {
  final TaskModel task;
  final VoidCallback? onTap;

  const TaskCard({super.key, required this.task, this.onTap});

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(task.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                if (task.description != null) ...[
                  const SizedBox(height: 4),
                  Text(task.description!, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    PriorityBadge(priority: task.priority),
                    const Spacer(),
                    const Icon(Icons.calendar_today, size: 12, color: Colors.white38),
                    const SizedBox(width: 4),
                    Text(task.dueDate, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
}
