import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants.dart';
import '../pages/login_page.dart';
import '../pages/signup_page.dart';
import '../pages/otp_page.dart';
import '../pages/dashboard_page.dart';
import '../pages/projects_page.dart';
import '../pages/project_detail_page.dart';
import '../pages/task_detail_page.dart';
import '../pages/admin_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: kRouteLogin,
    routes: [
      GoRoute(path: kRouteLogin,   builder: (_, __) => const LoginPage()),
      GoRoute(path: kRouteSignup,  builder: (_, __) => const SignupPage()),
      GoRoute(
        path: '/otp',
        builder: (context, state) {
          final extras = state.extra as Map<String, dynamic>? ?? {};
          return OtpPage(
            email: extras['email'] ?? '',
            password: extras['password'] ?? '',
          );
        },
      ),
      GoRoute(path: kRouteDashboard, builder: (_, __) => const DashboardPage()),
      GoRoute(path: kRouteProjects,  builder: (_, __) => const ProjectsPage()),
      GoRoute(
        path: kRouteProjectDetail,
        builder: (_, state) => ProjectDetailPage(projectId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: kRouteTaskDetail,
        builder: (_, state) => TaskDetailPage(taskId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/admin',
        builder: (_, __) => const AdminPage(),
      ),
    ],
  );
});
