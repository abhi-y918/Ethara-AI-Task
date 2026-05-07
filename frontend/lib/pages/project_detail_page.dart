import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/task_provider.dart';
import '../providers/project_provider.dart';
import '../providers/auth_provider.dart';
import '../services/project_service.dart';
import '../models/task.dart';
import '../models/project.dart';
import 'package:intl/intl.dart';

class ProjectDetailPage extends ConsumerStatefulWidget {
  final String projectId;
  const ProjectDetailPage({super.key, required this.projectId});

  @override
  ConsumerState<ProjectDetailPage> createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends ConsumerState<ProjectDetailPage> {
  List<Map<String, dynamic>> _members = [];
  bool _membersLoading = false;

  bool get _isAdmin {
    final currentUser = ref.read(authProvider).user;
    if (currentUser == null) return false;
    final me = _members.firstWhere(
      (m) => m['email'] == currentUser.email,
      orElse: () => {},
    );
    return me['role'] == 'admin';
  }

  Future<void> _loadMembers() async {
    setState(() => _membersLoading = true);
    try {
      final members = await ProjectService().getMembers(int.parse(widget.projectId));
      setState(() {
        _members = members;
        _membersLoading = false;
      });
    } catch (_) {
      setState(() => _membersLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(taskProvider.notifier).loadTasks(int.parse(widget.projectId));
      if (ref.read(projectProvider).projects.isEmpty) {
        ref.read(projectProvider.notifier).loadProjects();
      }
    });
    _loadMembers();
  }

  void _showCreateTaskDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    DateTime? selectedDate = DateTime.now().add(const Duration(days: 7));
    String priority = 'medium';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2A2D3E), Color(0xFF1E1F2A)],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, 10))
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('New Task', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 24),
                    TextField(
                      controller: titleCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Task Title',
                        labelStyle: const TextStyle(color: Colors.white70),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF7C3AED))),
                        filled: true,
                        fillColor: Colors.black.withOpacity(0.2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descCtrl,
                      maxLines: 3,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Description (Optional)',
                        labelStyle: const TextStyle(color: Colors.white70),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF7C3AED))),
                        filled: true,
                        fillColor: Colors.black.withOpacity(0.2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: selectedDate ?? DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (date != null) setState(() => selectedDate = date);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white.withOpacity(0.1)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today, color: Colors.white70, size: 20),
                                  const SizedBox(width: 12),
                                  Text(
                                    selectedDate != null ? DateFormat('MMM d, yyyy').format(selectedDate!) : 'Due Date',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: priority,
                            dropdownColor: const Color(0xFF2A2D3E),
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Priority',
                              labelStyle: const TextStyle(color: Colors.white70),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF7C3AED))),
                              filled: true,
                              fillColor: Colors.black.withOpacity(0.2),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'low', child: Text('Low')),
                              DropdownMenuItem(value: 'medium', child: Text('Medium')),
                              DropdownMenuItem(value: 'high', child: Text('High')),
                            ],
                            onChanged: (val) => setState(() => priority = val!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: () {
                            if (titleCtrl.text.trim().isNotEmpty && selectedDate != null) {
                              ref.read(taskProvider.notifier).createTask(
                                int.parse(widget.projectId),
                                titleCtrl.text.trim(),
                                descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                                DateFormat('yyyy-MM-dd').format(selectedDate!),
                                priority,
                              );
                              Navigator.pop(context);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7C3AED),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: const Text('Create Task', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        });
      },
    );
  }

  void _showInviteMemberDialog() {
    final emailCtrl = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2A2D3E), Color(0xFF1E1F2A)],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, 10))
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Invite Member', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 8),
                const Text('Invite someone to collaborate on this project.', style: TextStyle(color: Colors.white54, fontSize: 13)),
                const SizedBox(height: 24),
                TextField(
                  controller: emailCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'User Email',
                    labelStyle: const TextStyle(color: Colors.white70),
                    prefixIcon: const Icon(Icons.email_outlined, color: Colors.white70),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF7C3AED))),
                    filled: true,
                    fillColor: Colors.black.withOpacity(0.2),
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () async {
                        if (emailCtrl.text.trim().isNotEmpty) {
                          try {
                            await ref.read(projectProvider.notifier).addMember(int.parse(widget.projectId), emailCtrl.text.trim());
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Member added successfully!'), backgroundColor: Color(0xFF10B981)));
                              _loadMembers(); // Refresh members list
                            }
                          } catch (e) {
                            if (context.mounted) {
                              String errorMessage = e.toString().replaceAll('Exception: ', '');
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)), backgroundColor: const Color(0xFFEF4444)));
                            }
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text('Invite', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<TaskModel> _filterByStatus(List<TaskModel> tasks, TaskStatus status) =>
      tasks.where((t) => t.status == status).toList();

  Widget _buildTeamColumn() {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1F2A).withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('Team', style: TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold, fontSize: 13)),
                ),
                const SizedBox(width: 8),
                Text('${_members.length}', style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            if (_membersLoading)
              const Center(child: SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFF59E0B))))
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _members.length,
                itemBuilder: (context, index) {
                  final member = _members[index];
                  final isAdmin = member['role'] == 'admin';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2D3E),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.06)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: isAdmin
                              ? const Color(0xFF7C3AED).withOpacity(0.3)
                              : const Color(0xFF06B6D4).withOpacity(0.3),
                          child: Text(
                            (member['name'] as String).isNotEmpty
                                ? (member['name'] as String)[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              color: isAdmin ? const Color(0xFFB894FF) : const Color(0xFF67E8F9),
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                member['name'],
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                member['email'],
                                style: const TextStyle(color: Colors.white54, fontSize: 11),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isAdmin
                                ? const Color(0xFF7C3AED).withOpacity(0.2)
                                : const Color(0xFF06B6D4).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isAdmin ? 'Admin' : 'Member',
                            style: TextStyle(
                              color: isAdmin ? const Color(0xFFB894FF) : const Color(0xFF67E8F9),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(taskProvider);
    final projectState = ref.watch(projectProvider);
    
    // Find the current project from the provider to get its name
    final currentProject = projectState.projects.firstWhere(
      (p) => p.id.toString() == widget.projectId,
      orElse: () => ProjectModel(id: int.parse(widget.projectId), name: 'Project #${widget.projectId}', createdBy: 0, createdAt: ''),
    );

    return Scaffold(
      backgroundColor: const Color(0xFF13141C),
      appBar: AppBar(
        title: Text(currentProject.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/projects'),
        ),
        actions: [
          if (_isAdmin)
            TextButton.icon(
              onPressed: _showInviteMemberDialog,
              icon: const Icon(Icons.person_add_alt_1, color: Colors.white),
              label: const Text('Invite Member', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF06B6D4).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF06B6D4).withOpacity(0.5)),
                ),
                child: const Text('Member', style: TextStyle(color: Color(0xFF67E8F9), fontSize: 13, fontWeight: FontWeight.bold)),
              ),
            ),
          const SizedBox(width: 16),
        ],
      ),
      floatingActionButton: _isAdmin
          ? FloatingActionButton.extended(
              onPressed: _showCreateTaskDialog,
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
              elevation: 4,
              label: const Text('New Task', style: TextStyle(fontWeight: FontWeight.bold)),
              icon: const Icon(Icons.add),
            )
          : null,
      body: state.isLoading && state.tasks.isEmpty
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildKanbanColumn('To Do', _filterByStatus(state.tasks, TaskStatus.todo), const Color(0xFF7C3AED), TaskStatus.todo),
                  const SizedBox(width: 24),
                  _buildKanbanColumn('In Progress', _filterByStatus(state.tasks, TaskStatus.in_progress), const Color(0xFF06B6D4), TaskStatus.in_progress),
                  const SizedBox(width: 24),
                  _buildKanbanColumn('Done', _filterByStatus(state.tasks, TaskStatus.done), const Color(0xFF10B981), TaskStatus.done),
                  const SizedBox(width: 24),
                  _buildTeamColumn(),
                ],
              ),
            ),
    );
  }

  Widget _buildKanbanColumn(String title, List<TaskModel> tasks, Color color, TaskStatus columnStatus) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1F2A).withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    title,
                    style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${tasks.length}',
                  style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                return _buildTaskCard(task);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCard(TaskModel task) {
    Color priorityColor = Colors.grey;
    if (task.priority == TaskPriority.high) priorityColor = const Color(0xFFEF4444);
    if (task.priority == TaskPriority.medium) priorityColor = const Color(0xFFF59E0B);
    if (task.priority == TaskPriority.low) priorityColor = const Color(0xFF3B82F6);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2D3E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      task.title,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_horiz, color: Colors.white54, size: 20),
                    color: const Color(0xFF1E1F2A),
                    onSelected: (value) {
                      if (value == 'delete') {
                        ref.read(taskProvider.notifier).deleteTask(task.id);
                      } else {
                        TaskStatus newStatus = TaskStatus.values.firstWhere((e) => e.name == value);
                        ref.read(taskProvider.notifier).updateTaskStatus(task.id, newStatus);
                      }
                    },
                    itemBuilder: (context) => [
                      if (task.status != TaskStatus.todo)
                        const PopupMenuItem(value: 'todo', child: Text('Move to To Do', style: TextStyle(color: Colors.white))),
                      if (task.status != TaskStatus.in_progress)
                        const PopupMenuItem(value: 'in_progress', child: Text('Move to In Progress', style: TextStyle(color: Colors.white))),
                      if (task.status != TaskStatus.done)
                        const PopupMenuItem(value: 'done', child: Text('Move to Done', style: TextStyle(color: Colors.white))),
                      const PopupMenuDivider(),
                      const PopupMenuItem(value: 'delete', child: Text('Delete Task', style: TextStyle(color: Colors.redAccent))),
                    ],
                  ),
                ],
              ),
              if (task.description != null && task.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  task.description!,
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.flag, size: 14, color: priorityColor),
                      const SizedBox(width: 4),
                      Text(
                        task.priority.name.toUpperCase(),
                        style: TextStyle(color: priorityColor, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 14, color: Colors.white54),
                      const SizedBox(width: 4),
                      Text(
                        task.dueDate,
                        style: const TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                    ],
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
