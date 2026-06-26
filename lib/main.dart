import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme.dart';
import 'presentation/screens/chat_screen.dart';
import 'providers/theme_provider.dart';

void main() {
  runApp(const ProviderScope(child: GuffGaffApp()));
}

class GuffGaffApp extends ConsumerWidget {
  const GuffGaffApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp(
      title: 'GuffGaff AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      home: const ChatScreen(),
    );
  }
}
