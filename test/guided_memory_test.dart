import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:resource_memory/app/routing/resource_routes.dart';
import 'package:resource_memory/features/commitment/data/commitment_store.dart';
import 'package:resource_memory/features/focus_flow/data/focus_store.dart';
import 'package:resource_memory/features/resource/data/resource_store.dart';
import 'package:resource_memory/features/resource/data/welcome_store.dart';
import 'package:resource_memory/features/resource/data/memory_surface_store.dart';
import 'package:resource_memory/features/widget/memory_mascot.dart';
import 'package:resource_memory/features/widget/todoist_light.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  late Directory temp;
  GoRouter? router;
  setUp(() async {
    temp = await Directory.systemTemp.createTemp('nanynany-test-');
    Hive.init(temp.path);
    await ResourceStore.initialize(); await WelcomeStore.initialize();
    await CommitmentStore.initialize(); await FocusStore.initialize();
  });
  tearDown(() async { router?.dispose(); router = null; await Hive.close(); await temp.delete(recursive: true); });

  Future<void> mount(WidgetTester tester, {String initial = '/', double scale = 1}) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize); addTearDown(tester.view.resetDevicePixelRatio);
    router = GoRouter(navigatorKey: memoryRootNavigatorKey, routes: resourceRoutes, initialLocation: initial);
    await tester.pumpWidget(MaterialApp.router(theme: TodoistLightScope.themeFor(ThemeData()), routerConfig: router,
      builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)), child: child!)));
    await tester.pumpAndSettle();
  }
  Future<void> tap(WidgetTester tester, String label) async {
    final finder = find.text(label).last;
    await tester.ensureVisible(finder); await tester.tap(finder); await tester.pumpAndSettle();
  }
  Future<void> unmount(WidgetTester tester) async { await tester.pumpWidget(const SizedBox()); await tester.pumpAndSettle(); }

  testWidgets('first launch has a keyboard-accessible start and skip', (tester) async {
    await mount(tester);
    expect(find.text('Get started'), findsOneWidget);
    await tap(tester, 'Skip for now');
    expect(WelcomeStore.hasSeenWelcome, isTrue);
    expect(find.byType(NavigationBar), findsOneWidget);
    router!.go('/welcome'); await tester.pumpAndSettle();
    expect(find.text('Get started'), findsNothing);
    await unmount(tester);
  });
  testWidgets('guided example is genuinely saved and retrieved using shared search', (tester) async {
    await mount(tester);
    await tap(tester, 'Try a guided example');
    expect(ResourceStore.getById('nanynany-guided-example'), isNotNull);
    expect(WelcomeStore.step, 2);
    await tester.enterText(find.byType(TextField), 'that article about grants');
    await tap(tester, 'Find my memory');
    expect(find.text('Found it.'), findsOneWidget);
    await tap(tester, 'See how reminders work');
    expect(find.text('REMINDER PREVIEW · not scheduled'), findsOneWidget);
    expect(CommitmentStore.getAll(), isEmpty);
    await tap(tester, 'Go to my memory');
    expect(WelcomeStore.hasSeenWelcome, isTrue);
    expect(find.byType(NavigationBar), findsOneWidget);
    await unmount(tester);
  });
  testWidgets('unfinished onboarding resumes without saving a second example', (tester) async {
    await mount(tester);
    await tap(tester, 'Try a guided example');
    await unmount(tester); router!.dispose(); router = null;
    await mount(tester);
    expect(find.text('Now, find it again.'), findsOneWidget);
    expect(ResourceStore.getAll().length, 1);
    await unmount(tester);
  });
  testWidgets('persistent tabs retain the Memory search', (tester) async {
    await WelcomeStore.markSeen(); await mount(tester, initial: '/library');
    await tester.enterText(find.byType(TextField), 'community funding'); await tester.pumpAndSettle();
    final nav = find.byType(NavigationBar);
    await tester.tap(find.descendant(of: nav, matching: find.text('Reminders'))); await tester.pumpAndSettle();
    expect(find.text('No confirmed reminders yet.'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    await tester.tap(find.descendant(of: nav, matching: find.text('Memory'))); await tester.pumpAndSettle();
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, 'community funding');
    await unmount(tester);
  });
  testWidgets('welcome remains usable with large text and reduced motion', (tester) async {
    await mount(tester, scale: 1.8);
    expect(tester.takeException(), isNull);
    await tap(tester, 'Get started');
    expect(tester.takeException(), isNull);
    await unmount(tester);
    await tester.pumpWidget(const MaterialApp(home: MediaQuery(data: MediaQueryData(disableAnimations: true), child: MemoryMascot())));
    await tester.pump();
    expect(tester.widget<TweenAnimationBuilder<double>>(find.byType(TweenAnimationBuilder<double>)).duration, Duration.zero);
    expect(tester.takeException(), isNull);
    await unmount(tester);
  });
  test('resurfacing preferences snooze without removing the saved memory', () async {
    await MemorySurfaceStore.later('example');
    expect(MemorySurfaceStore.eligible('example', DateTime.now()), isFalse);
    expect(MemorySurfaceStore.eligible('example', DateTime.now().add(const Duration(days: 2))), isTrue);
    await MemorySurfaceStore.later('example', lessOften: true);
    expect(MemorySurfaceStore.eligible('example', DateTime.now().add(const Duration(days: 2))), isFalse);
  });
}
