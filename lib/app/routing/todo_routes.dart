import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:taskee/app/routing/app_route.dart';
import 'package:taskee/features/project/presentation/pages/project_match_screen.dart';
import 'package:taskee/features/resource/presentation/pages/library_screen.dart';
import 'package:taskee/features/resource/presentation/pages/resource_home_screen.dart';
import 'package:taskee/features/resource/presentation/pages/save_resource_screen.dart';

final List<RouteBase> todoRoutes = <RouteBase>[
  GoRoute(
    path: Routes.homeScreen,
    builder: (BuildContext context, GoRouterState state) =>
        const ResourceHomeScreen(),
    routes: <RouteBase>[
      GoRoute(
        path: Routes.saveResourceScreen,
        builder: (BuildContext context, GoRouterState state) =>
            const SaveResourceScreen(),
      ),
      GoRoute(
        path: Routes.libraryScreen,
        builder: (BuildContext context, GoRouterState state) =>
            const LibraryScreen(),
      ),
      GoRoute(
        path: Routes.projectMatchScreen,
        builder: (BuildContext context, GoRouterState state) =>
            const ProjectMatchScreen(),
      ),
    ],
  ),
];
