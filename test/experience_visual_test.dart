import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:resource_memory/app/routing/resource_routes.dart';
import 'package:resource_memory/features/commitment/data/commitment_store.dart';
import 'package:resource_memory/features/focus_flow/data/focus_store.dart';
import 'package:resource_memory/features/resource/data/resource_store.dart';
import 'package:resource_memory/features/resource/data/welcome_store.dart';
import 'package:resource_memory/features/widget/todoist_light.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  testWidgets('render the complete guided experience for visual review', (tester) async {
    final temp = await Directory.systemTemp.createTemp('nanynany-visual-');
    Hive.init(temp.path);
    await ResourceStore.initialize(); await WelcomeStore.initialize();
    await CommitmentStore.initialize(); await FocusStore.initialize();
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize); addTearDown(tester.view.resetDevicePixelRatio);
    final router = GoRouter(navigatorKey: memoryRootNavigatorKey, routes: resourceRoutes);
    final boundary = GlobalKey();
    await tester.pumpWidget(RepaintBoundary(key: boundary, child: MaterialApp.router(
      theme: TodoistLightScope.themeFor(ThemeData()), routerConfig: router,
    )));
    await tester.pumpAndSettle();
    Future<void> picture(String name) async {
      expect(tester.takeException(), isNull);
      final paint = boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await paint.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File('build/experience-review/$name.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }
    Future<void> tap(String label) async {
      final target = find.text(label).last;
      await tester.ensureVisible(target); await tester.tap(target); await tester.pumpAndSettle();
    }
    await picture('01-welcome');
    await tap('Get started'); await picture('02-save');
    await tap('Save the example');
    await tester.enterText(find.byType(TextField), 'that article about grants');
    await tap('Find my memory'); await picture('03-found');
    await tap('See how reminders work'); await picture('04-reminder-preview');
    await tap('Go to my memory'); await picture('05-home');
    await tap('Save something'); await picture('06-capture-sheet');
    await tester.tap(find.byTooltip('Close capture')); await tester.pumpAndSettle();
    router.go('/library?q=grants'); await tester.pumpAndSettle(); await picture('07-memory');
    router.go('/commitments'); await tester.pumpAndSettle(); await picture('08-reminders');
    router.go('/focus'); await tester.pumpAndSettle(); await picture('09-focus');
    router.go('/');
    tester.view.physicalSize = const Size(1280, 900);
    await tester.pumpAndSettle(); await picture('10-desktop-home');
    await tester.pumpWidget(const SizedBox()); await tester.pumpAndSettle();
    router.dispose(); await Hive.close(); await temp.delete(recursive: true);
  });
}
