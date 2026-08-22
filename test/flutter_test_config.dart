import 'dart:async';
import 'dart:io';

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  final isGitHubActions = Platform.environment.containsKey('GITHUB_ACTIONS');

  return AlchemistConfig.runWithConfig(
    config: AlchemistConfig(
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF005AC1),
          onPrimary: Color(0xFFFFFFFF),
          secondary: Color(0xFF535F70),
          onSecondary: Color(0xFFFFFFFF),
          surface: Color(0xFFFFFFFF),
          onSurface: Color(0xFF1A1C1E),
          error: Color(0xFFBA1A1A),
          onError: Color(0xFFFFFFFF),
        ),
        scaffoldBackgroundColor: const Color(0xFFFFFFFF),
      ),
      goldenTestTheme: GoldenTestTheme(
        backgroundColor: const Color(0xFFFFFFFF),
        borderColor: const Color(0xFF000000),
        nameTextStyle: const TextStyle(
          color: Color(0xFF000000),
          fontSize: 14,
          height: 1,
        ),
        padding: const EdgeInsets.all(8),
      ),
      platformGoldensConfig: PlatformGoldensConfig(
        enabled: !isGitHubActions,
        obscureText: false,
      ),
      ciGoldensConfig: const CiGoldensConfig(
        enabled: true,
        obscureText: true,
        renderShadows: false,
        diffThreshold: 0,
      ),
    ),
    run: testMain,
  );
}
