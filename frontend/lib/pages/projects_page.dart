import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/project_provider.dart';

class ProjectsPage extends ConsumerStatefulWidget {
  const ProjectsPage({super.key});

  @override
  ConsumerState<ProjectsPage> createState() => _ProjectsPageState();
}

class _ProjectsPageState extends ConsumerState<ProjectsPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(projectProvider.notifier).loadProjects());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(projectProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Projects'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: show create project dialog
        },
        label: const Text('New Project'),
        icon: const Icon(Icons.add),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.projects.isEmpty
              ? const Center(child: Text('No projects yet. Create one!', style: TextStyle(color: Colors.white54)))
              : GridView.builder(
                  padding: const EdgeInsets.all(24),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 320,
                    mainAxisExtent: 160,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: state.projects.length,
                  itemBuilder: (context, i) {
                    final project = state.projects[i];
                    return Card(
                      child: InkWell(
                        onTap: () => context.go('/projects/${project.id}'),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(project.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 8),
                              Text(project.description ?? 'No description', style: const TextStyle(color: Colors.white54, fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
