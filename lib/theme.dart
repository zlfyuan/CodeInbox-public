import 'package:flutter/material.dart';

import 'domain/models.dart';

const seed = Color(0xFF0F766E);
const githubDot = Color(0xFF24292F);
const giteeDot = Color(0xFFC71D23);
const gitlabDot = Color(0xFFFC6D26);
const codeupDot = Color(0xFFFF6A00);
const gongfengDot = Color(0xFF0052D9);
const codingDot = Color(0xFF0066FF);

ThemeData codeInboxTheme({required Brightness brightness}) {
  final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: brightness);
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    navigationBarTheme: NavigationBarThemeData(
      indicatorColor: scheme.primary.withValues(alpha: 0.14),
    ),
  );
}

Color platformDot(ForgePlatform platform) => switch (platform) {
      ForgePlatform.github => githubDot,
      ForgePlatform.gitee => giteeDot,
      ForgePlatform.gitlab => gitlabDot,
      ForgePlatform.codeup => codeupDot,
      ForgePlatform.gongfeng => gongfengDot,
      ForgePlatform.coding => codingDot,
    };
