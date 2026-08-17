import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:taskee/app/routing/go_router.dart';
import 'package:taskee/app/theme/app_theme.dart';
import 'package:taskee/features/resource/data/resource_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await ResourceStore.initialize();
  runApp(const ResourceMemoryApp());
}

class ResourceMemoryApp extends StatelessWidget {
  const ResourceMemoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: MaterialApp.router(
        title: 'Resource Memory',
        theme: AppTheme.dark,
        debugShowCheckedModeBanner: false,
        routerConfig: goRouter,
      ),
    );
  }
}
