import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';

class AppLayout extends ConsumerWidget {
  final Widget child;
  const AppLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF13141C),
      body: Row(
        children: [
          // Permanent Sidebar
          Container(
            width: 260,
            color: const Color(0xFF1E1F2A),
            child: Column(
              children: [
                // User Profile Section
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFF4C1D95)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.account_circle, size: 48, color: Colors.white),
                      const SizedBox(height: 12),
                      Text(authState.user?.name ?? '', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(authState.user?.email ?? '', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Navigation Links
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      _buildNavItem(context, Icons.dashboard_outlined, 'Dashboard', '/dashboard'),
                      _buildNavItem(context, Icons.folder_outlined, 'Projects', '/projects'),
                      if (authState.user?.isSuperadmin == true) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: Divider(color: Colors.white12),
                        ),
                        _buildNavItem(context, Icons.admin_panel_settings, 'Super Admin Panel', '/admin', color: const Color(0xFFEF4444)),
                      ],
                    ],
                  ),
                ),
                
                // Logout Button
                const Divider(color: Colors.white12),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  leading: const Icon(Icons.logout, color: Colors.white),
                  title: const Text('Logout', style: TextStyle(color: Colors.white)),
                  onTap: () async {
                    await ref.read(authProvider.notifier).logout();
                    if (context.mounted) context.go('/login');
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          
          // Main Content Area
          Expanded(
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, String title, String route, {Color color = Colors.white}) {
    final currentRoute = GoRouterState.of(context).matchedLocation;
    final isSelected = currentRoute.startsWith(route);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF7C3AED).withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        leading: Icon(icon, color: isSelected ? const Color(0xFFB894FF) : color),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? const Color(0xFFB894FF) : color,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onTap: () => context.go(route),
      ),
    );
  }
}
