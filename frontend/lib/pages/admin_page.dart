import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';

import '../core/constants.dart';
import '../services/api_service.dart';

final adminStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final dio = ApiService().dio;
  
  final usersRes = await dio.get('/admin/users');
  final projectsRes = await dio.get('/admin/projects');
  
  return {
    'users': usersRes.data,
    'projects': projectsRes.data,
  };
});

class AdminPage extends ConsumerStatefulWidget {
  const AdminPage({super.key});

  @override
  ConsumerState<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends ConsumerState<AdminPage> {

  Future<void> _deleteUser(int userId, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2D3E),
        title: const Text('Delete User', style: TextStyle(color: Colors.white)),
        content: Text('Are you sure you want to permanently delete $name?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await ApiService().dio.delete('/admin/users/$userId');
      ref.refresh(adminStatsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User deleted successfully'), backgroundColor: Color(0xFF10B981)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete user: $e'), backgroundColor: Colors.redAccent));
      }
    }
  }

  Future<void> _deleteProject(int projectId, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2D3E),
        title: const Text('Delete Project', style: TextStyle(color: Colors.white)),
        content: Text('Are you sure you want to permanently delete $name?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await ApiService().dio.delete('/projects/$projectId');
      ref.refresh(adminStatsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Project deleted successfully'), backgroundColor: Color(0xFF10B981)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete project: $e'), backgroundColor: Colors.redAccent));
      }
    }
  }

  Future<void> _editUserName(int userId, String currentName) async {
    final nameCtrl = TextEditingController(text: currentName);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2D3E),
        title: const Text('Edit User Name', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: nameCtrl,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Name',
            labelStyle: const TextStyle(color: Colors.white70),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF7C3AED))),
            filled: true,
            fillColor: Colors.black.withOpacity(0.2),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, nameCtrl.text.trim()),
            child: const Text('Save', style: TextStyle(color: Color(0xFF7C3AED), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    
    if (newName == null || newName.isEmpty || newName == currentName) return;

    try {
      await ApiService().dio.put('/admin/users/$userId', data: {'name': newName});
      ref.refresh(adminStatsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name updated successfully'), backgroundColor: Color(0xFF10B981)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update name: $e'), backgroundColor: Colors.redAccent));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(adminStatsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF13141C),
      appBar: AppBar(
        title: const Text('Super Admin Dashboard'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(kRouteDashboard),
        ),
      ),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED))),
        error: (e, _) => Center(child: Text('Error loading admin data: $e', style: const TextStyle(color: Colors.redAccent))),
        data: (data) {
          final users = (data['users'] as List).cast<Map<String, dynamic>>();
          final projects = (data['projects'] as List).cast<Map<String, dynamic>>();

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildUserList(users)),
              const SizedBox(width: 16),
              Expanded(child: _buildProjectList(projects)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildUserList(List<Map<String, dynamic>> users) {
    return Container(
      margin: const EdgeInsets.only(left: 24, bottom: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1F2A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text('All Users', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: users.length,
              separatorBuilder: (_, __) => const Divider(color: Colors.white12, height: 1),
              itemBuilder: (context, index) {
                final u = users[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: u['is_superadmin'] == true ? const Color(0xFFEF4444) : const Color(0xFF7C3AED),
                    child: Text(u['name'][0].toUpperCase(), style: const TextStyle(color: Colors.white)),
                  ),
                  title: Text(u['name'], style: const TextStyle(color: Colors.white)),
                  subtitle: Text(u['email'], style: const TextStyle(color: Colors.white54)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: Colors.blueAccent),
                        onPressed: () => _editUserName(u['id'], u['name']),
                        tooltip: 'Edit Name',
                      ),
                      if (u['is_superadmin'] == true)
                        const Chip(label: Text('Super Admin'), backgroundColor: Colors.redAccent, labelStyle: TextStyle(color: Colors.white, fontSize: 10)),
                      if (u['is_superadmin'] != true)
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          onPressed: () => _deleteUser(u['id'], u['name']),
                          tooltip: 'Remove User',
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectList(List<Map<String, dynamic>> projects) {
    return Container(
      margin: const EdgeInsets.only(right: 24, bottom: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1F2A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text('All Projects Overview', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: projects.length,
              separatorBuilder: (_, __) => const Divider(color: Colors.white12, height: 1),
              itemBuilder: (context, index) {
                final p = projects[index];
                return ListTile(
                  onTap: () => context.push('/projects/${p['id']}'),
                  title: Text(p['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text('Creator: ${p['created_by']}', style: const TextStyle(color: Colors.white54)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildBadge(Icons.people, '${p['member_count']}', Colors.blueAccent),
                      const SizedBox(width: 8),
                      _buildBadge(Icons.task_alt, '${p['task_count']}', Colors.green),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        onPressed: () => _deleteProject(p['id'], p['name']),
                        tooltip: 'Delete Project',
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
