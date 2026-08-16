import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:taskee/app/routing/app_route.dart';

class ResourceHomeScreen extends StatelessWidget {
  const ResourceHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Resource Memory')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'What are you working on?',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tell Resource Memory what you are building. It will bring back things you already saved that may help.',
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => context.go('/${Routes.projectMatchScreen}'),
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Start a project'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => context.go('/${Routes.saveResourceScreen}'),
                icon: const Icon(Icons.add_link),
                label: const Text('Save something useful'),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () => context.go('/${Routes.libraryScreen}'),
                icon: const Icon(Icons.bookmarks_outlined),
                label: const Text('Open library'),
              ),
              const Spacer(),
              const Text(
                'Save it once. Find it when it matters.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
