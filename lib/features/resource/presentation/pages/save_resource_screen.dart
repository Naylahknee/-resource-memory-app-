import 'package:flutter/material.dart';

class SaveResourceScreen extends StatefulWidget {
  const SaveResourceScreen({super.key});

  @override
  State<SaveResourceScreen> createState() => _SaveResourceScreenState();
}

class _SaveResourceScreenState extends State<SaveResourceScreen> {
  final TextEditingController _urlController = TextEditingController();

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Save something useful')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Paste a link',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text('Threads, YouTube, GitHub, websites, tutorials — anything you want Future You to remember.'),
            const SizedBox(height: 20),
            TextField(
              controller: _urlController,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                hintText: 'https://...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () {},
              child: const Text('Understand and save'),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.image_outlined),
              label: const Text('Upload a screenshot'),
            ),
          ],
        ),
      ),
    );
  }
}
