import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/disclosure/disclosure_screen.dart';
import '../features/home/home_screen.dart';
import '../features/apps_picker/apps_picker_screen.dart';
import '../features/profiles/profiles_screen.dart';
import '../features/settings/settings_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/disclosure',
  routes: [
    GoRoute(
      path: '/disclosure',
      builder: (context, state) => const DisclosureScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/apps',
      builder: (context, state) => const AppsPickerScreen(),
    ),
    GoRoute(
      path: '/profiles',
      builder: (context, state) => const ProfilesScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);
