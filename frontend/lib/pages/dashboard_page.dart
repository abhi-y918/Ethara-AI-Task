import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, ${authState.user?.name ?? ''}'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
      body: taskState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Dashboard', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 24),
                  // TODO: Replace with StatCard widgets and fl_chart charts
                  Text('Total Tasks: ${stats['total_tasks'] ?? 0}', style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 8),
                  Text('Stats: ${stats.toString()}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
    );
  }
}
