import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/task_provider.dart';
import '../providers/auth_provider.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(taskProvider.notifier).loadDashboard());
  }

  @override
  Widget build(BuildContext context) {
    final taskState = ref.watch(taskProvider);
    final authState = ref.watch(authProvider);
    final stats = taskState.dashboardStats;

    final totalTasks = stats['total_tasks'] ?? 0;
    final byStatus = stats['by_status'] as Map<String, dynamic>? ?? {'todo': 0, 'in_progress': 0, 'done': 0};
    final myTasks = (stats['my_tasks'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    final overdueTasks = (stats['overdue_tasks'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFF13141C),
      appBar: AppBar(
        title: Text('Welcome, ${authState.user?.name ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      drawer: Drawer(
        backgroundColor: const Color(0xFF1E1F2A),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFF4C1D95)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Icon(Icons.account_circle, size: 48, color: Colors.white),
                  const SizedBox(height: 12),
                  Text(authState.user?.name ?? '', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(authState.user?.email ?? '', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard_outlined, color: Colors.white),
              title: const Text('Dashboard', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.folder_outlined, color: Colors.white),
              title: const Text('Projects', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                context.go('/projects');
              },
            ),
            if (authState.user?.isSuperadmin == true) ...[
              const Divider(color: Colors.white12),
              ListTile(
                leading: const Icon(Icons.admin_panel_settings, color: Color(0xFFEF4444)),
                title: const Text('Super Admin Panel', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/admin');
                },
              ),
            ],
            const Divider(color: Colors.white12),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.white),
              title: const Text('Logout', style: TextStyle(color: Colors.white)),
              onTap: () async {
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) context.go('/login');
              },
            ),
          ],
        ),
      ),
      body: taskState.isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Overview', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 24),
                  
                  // Top Stats Row
                  Row(
                    children: [
                      _buildStatCard(
                        'Total Tasks',
                        totalTasks.toString(),
                        Icons.task_alt,
                        const [Color(0xFF7C3AED), Color(0xFF4C1D95)],
                      ),
                      const SizedBox(width: 16),
                      _buildStatCard(
                        'Completed',
                        (byStatus['done'] ?? 0).toString(),
                        Icons.check_circle_outline,
                        const [Color(0xFF10B981), Color(0xFF047857)],
                      ),
                      const SizedBox(width: 16),
                      _buildStatCard(
                        'Overdue',
                        overdueTasks.length.toString(),
                        Icons.warning_amber_rounded,
                        const [Color(0xFFEF4444), Color(0xFFB91C1C)],
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Charts Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Pie Chart
                      Expanded(
                        flex: 1,
                        child: _buildChartContainer(
                          'Tasks by Status',
                          SizedBox(
                            height: 250,
                            child: PieChart(
                              PieChartData(
                                sectionsSpace: 4,
                                centerSpaceRadius: 60,
                                sections: [
                                  PieChartSectionData(
                                    color: const Color(0xFF7C3AED),
                                    value: (byStatus['todo'] ?? 0).toDouble(),
                                    title: 'To Do',
                                    radius: 40,
                                    titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                  PieChartSectionData(
                                    color: const Color(0xFF06B6D4),
                                    value: (byStatus['in_progress'] ?? 0).toDouble(),
                                    title: 'Progress',
                                    radius: 40,
                                    titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                  PieChartSectionData(
                                    color: const Color(0xFF10B981),
                                    value: (byStatus['done'] ?? 0).toDouble(),
                                    title: 'Done',
                                    radius: 40,
                                    titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      // Workload by User — card-based
                      Expanded(
                        flex: 2,
                        child: _buildChartContainer(
                          'My Workload',
                          myTasks.isEmpty
                              ? const SizedBox(
                                  height: 200,
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.assignment_turned_in, color: Colors.white24, size: 48),
                                        SizedBox(height: 12),
                                        Text('No active tasks assigned', style: TextStyle(color: Colors.white38, fontSize: 14)),
                                      ],
                                    ),
                                  ),
                                )
                              : Column(
                                  children: myTasks.map((t) {
                                    final projectName = t['project_name'] as String;
                                    final taskTitle = t['task_title'] as String;
                                    final todo = t['todo'] as int? ?? 0;
                                    final inProgress = t['in_progress'] as int? ?? 0;
                                    final total = todo + inProgress;
                                    final todoFrac = total > 0 ? todo / total : 0.0;
                                    final initials = projectName.isNotEmpty ? projectName[0].toUpperCase() : 'P';
                                    
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 16),
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.04),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: Colors.white.withOpacity(0.07)),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              CircleAvatar(
                                                radius: 20,
                                                backgroundColor: const Color(0xFF7C3AED).withOpacity(0.3),
                                                child: Text(initials, style: const TextStyle(color: Color(0xFFB894FF), fontWeight: FontWeight.bold, fontSize: 16)),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(projectName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                                                    Text(taskTitle, style: const TextStyle(color: Colors.white38, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                                                  ],
                                                ),
                                              ),
                                              // Total badge
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF7C3AED).withOpacity(0.2),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Text('$total active', style: const TextStyle(color: Color(0xFFB894FF), fontSize: 12, fontWeight: FontWeight.bold)),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 14),
                                          // Progress bar split: todo (purple) + in_progress (cyan)
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(6),
                                            child: Stack(
                                              children: [
                                                Container(height: 8, color: Colors.white12),
                                                Row(
                                                  children: [
                                                    Flexible(
                                                      flex: (todoFrac * 100).round(),
                                                      child: Container(height: 8, color: const Color(0xFF7C3AED)),
                                                    ),
                                                    Flexible(
                                                      flex: ((1 - todoFrac) * 100).round(),
                                                      child: Container(height: 8, color: const Color(0xFF06B6D4)),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          // Legend
                                          Row(
                                            children: [
                                              Container(width: 10, height: 10, decoration: BoxDecoration(color: const Color(0xFF7C3AED), borderRadius: BorderRadius.circular(3))),
                                              const SizedBox(width: 6),
                                              Text('To Do: $todo', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                                              const SizedBox(width: 16),
                                              Container(width: 10, height: 10, decoration: BoxDecoration(color: const Color(0xFF06B6D4), borderRadius: BorderRadius.circular(3))),
                                              const SizedBox(width: 6),
                                              Text('In Progress: $inProgress', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  // Overdue Tasks Alert List
                  if (overdueTasks.isNotEmpty) ...[
                    const Text('Overdue Tasks', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 16),
                    ...overdueTasks.map((t) => Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withOpacity(0.1),
                            border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.5)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.warning_rounded, color: Color(0xFFEF4444)),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(t['title'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                    const SizedBox(height: 4),
                                    Text('Due: ${t['due_date']} (Project #${t['project_id']})', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                                  ],
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () => context.go('/projects/${t['project_id']}'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFEF4444).withOpacity(0.2),
                                  foregroundColor: const Color(0xFFEF4444),
                                  elevation: 0,
                                ),
                                child: const Text('View Project'),
                              )
                            ],
                          ),
                        )),
                  ],
                ],
              ),
            ),
    );
  }

  double _getMaxY(List<Map<String, dynamic>> tasksPerUser) {
    if (tasksPerUser.isEmpty) return 10;
    double max = 0;
    for (var u in tasksPerUser) {
      if ((u['count'] as int).toDouble() > max) {
        max = (u['count'] as int).toDouble();
      }
    }
    return max + 5;
  }

  Widget _buildStatCard(String title, String value, IconData icon, List<Color> gradient) {
    return Expanded(
      child: Container(
        height: 140,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: gradient[0].withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Icon(icon, color: Colors.white38, size: 28),
            ),
            Align(
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text(value, style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartContainer(String title, Widget chart) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1F2A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 32),
          chart,
        ],
      ),
    );
  }
}
