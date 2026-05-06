import 'package:flutter/material.dart';

class MemberTile extends StatelessWidget {
  final String name;
  final String email;
  final String role;
  final VoidCallback? onRemove;

  const MemberTile({
    super.key,
    required this.name,
    required this.email,
    required this.role,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) => ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF7C3AED),
          child: Text(name[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        title: Text(name, style: const TextStyle(color: Colors.white)),
        subtitle: Text(email, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: role == 'admin' ? const Color(0xFF7C3AED).withOpacity(0.2) : const Color(0xFF06B6D4).withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(role.toUpperCase(), style: TextStyle(color: role == 'admin' ? const Color(0xFF7C3AED) : const Color(0xFF06B6D4), fontSize: 10, fontWeight: FontWeight.bold)),
            ),
            if (onRemove != null) ...[
              const SizedBox(width: 8),
              IconButton(icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20), onPressed: onRemove),
            ],
          ],
        ),
      );
}
