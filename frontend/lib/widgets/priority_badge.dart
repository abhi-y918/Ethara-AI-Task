import 'package:flutter/material.dart';
import '../models/task.dart';

class PriorityBadge extends StatelessWidget {
  final TaskPriority priority;
  const PriorityBadge({super.key, required this.priority});

  Color get _color => switch (priority) {
        TaskPriority.high => const Color(0xFFEF4444),
        TaskPriority.medium => const Color(0xFFF59E0B),
        TaskPriority.low => const Color(0xFF10B981),
      };

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: _color.withOpacity(0.2), borderRadius: BorderRadius.circular(6), border: Border.all(color: _color.withOpacity(0.5))),
        child: Text(priority.name.toUpperCase(), style: TextStyle(color: _color, fontSize: 10, fontWeight: FontWeight.bold)),
      );
}
