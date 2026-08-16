import 'package:flutter/material.dart';

class ProjectMatchScreen extends StatefulWidget {
  const ProjectMatchScreen({super.key});

  @override
  State<ProjectMatchScreen> createState() => _ProjectMatchScreenState();
}

class _ProjectMatchScreenState extends State<ProjectMatchScreen> {
  final TextEditingController _projectController = TextEditingController();

  @override
  void dispose() {
    _projectController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Start a project')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'What are you building?',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text('Describe it normally. We will use that context to bring back relevant resources.'),
            const SizedBox(height: 20),
            TextField(
              controller: _projectController,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: 'Example: I am building a Roblox inventory system in Luau.',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () {},
              child: const Text('Find what I already saved'),
            ),
          ],
        ),
      ),
    );
  }
}
