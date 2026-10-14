import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:resource_memory/features/widget/memory_app_shell.dart';
import 'package:resource_memory/features/commitment/presentation/pages/commitments_screen.dart';
import 'package:resource_memory/features/focus_flow/presentation/pages/focus_flow_screen.dart';
import 'package:resource_memory/features/commitment/presentation/pages/spoken_reminder_settings_screen.dart';
import 'package:resource_memory/features/project/presentation/pages/project_match_screen.dart';
import 'package:resource_memory/features/resource/presentation/pages/install_app_screen.dart';
import 'package:resource_memory/features/resource/presentation/pages/library_screen.dart';
import 'package:resource_memory/features/resource/presentation/pages/resource_detail_screen.dart';
import 'package:resource_memory/features/resource/presentation/pages/resource_home_screen.dart';
import 'package:resource_memory/features/resource/presentation/pages/save_resource_screen.dart';
import 'package:resource_memory/features/resource/presentation/pages/sync_screen.dart';
import 'package:resource_memory/features/resource/presentation/pages/voice_memory_screen.dart';
import 'package:resource_memory/features/resource/presentation/pages/welcome_screen.dart';
import 'package:resource_memory/features/resource/data/welcome_store.dart';

final memoryRootNavigatorKey = GlobalKey<NavigatorState>();
final List<RouteBase> resourceRoutes = [
  GoRoute(path: '/welcome', redirect: (_, state) => WelcomeStore.hasSeenWelcome && state.uri.queryParameters['tour'] != '1' ? '/' : null, builder: (context, state) => WelcomeScreen(isTour: state.uri.queryParameters['tour'] == '1')),
  StatefulShellRoute.indexedStack(
    builder: (context, state, navigation) => MemoryAppShell(navigation: navigation),
    branches: [
      StatefulShellBranch(routes: [GoRoute(path: '/', redirect: (_, __) => WelcomeStore.hasSeenWelcome ? null : '/welcome', builder: (_, __) => const ResourceHomeScreen())]),
      StatefulShellBranch(routes: [GoRoute(path: '/focus', builder: (_, __) => const FocusFlowScreen())]),
      StatefulShellBranch(routes: [GoRoute(path: '/commitments', builder: (_, __) => const CommitmentsScreen())]),
      StatefulShellBranch(routes: [GoRoute(path: '/library', builder: (_, state) => LibraryScreen(initialQuery: state.uri.queryParameters['q'] ?? ''))]),
    ],
  ),
  GoRoute(path: '/save-resource', builder: (_, __) => const SaveResourceScreen()),
  GoRoute(path: '/voice-memory', builder: (_, __) => const VoiceMemoryScreen()),
  GoRoute(path: '/spoken-reminders', builder: (_, __) => const SpokenReminderSettingsScreen()),
  GoRoute(path: '/resource/:id', builder: (_, state) => ResourceDetailScreen(resourceId: state.pathParameters['id']!)),
  GoRoute(path: '/project-match', builder: (_, __) => const ProjectMatchScreen()),
  GoRoute(path: '/sync', builder: (_, __) => const SyncScreen()),
  GoRoute(path: '/install-app', builder: (_, __) => const InstallAppScreen()),
];
