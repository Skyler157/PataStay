// Renders key screens in light and dark mode with the real fonts, so colour
// and contrast problems can be reviewed visually. Regenerate with:
//   flutter test test/theme_screenshots_test.dart --update-goldens
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_flow_test.dart' as flow;

Future<void> _loadFonts() async {
  final dir = Directory('../../packages/patastay_core/assets/fonts');
  final loader = FontLoader('packages/patastay_core/PlusJakartaSans');
  for (final f in dir.listSync().whereType<File>().where((f) => f.path.endsWith('.ttf'))) {
    loader.addFont(Future.value(ByteData.view(f.readAsBytesSync().buffer)));
  }
  await loader.load();
  final materialIcons = File('${Platform.environment['FLUTTER_ROOT'] ?? '../../../../flutter'}'
      '/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
  if (materialIcons.existsSync()) {
    final icons = FontLoader('MaterialIcons')..addFont(Future.value(ByteData.view(materialIcons.readAsBytesSync().buffer)));
    await icons.load();
  }
}

void main() {
  setUpAll(_loadFonts);

  for (final dark in [false, true]) {
    final mode = dark ? 'dark' : 'light';

    testWidgets('home ($mode)', (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 2.75;
      tester.platformDispatcher.platformBrightnessTestValue = dark ? Brightness.dark : Brightness.light;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

      await tester.pumpWidget(flow.buildApp(prefs: flow.FakePreferences(onboardingSeen: true)));
      await tester.pumpAndSettle();
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('screenshots/home_$mode.png'));
    });

    testWidgets('details ($mode)', (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 2.75;
      tester.platformDispatcher.platformBrightnessTestValue = dark ? Brightness.dark : Brightness.light;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

      await tester.pumpWidget(flow.buildApp(prefs: flow.FakePreferences(onboardingSeen: true)));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Where in Nairobi?'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bright studio near Yaya Centre'));
      await tester.pumpAndSettle();
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('screenshots/details_$mode.png'));
    });
  }
}
