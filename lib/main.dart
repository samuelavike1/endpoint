import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/theme/app_theme.dart';
import 'features/home/views/app_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Allow Google Fonts to use system fallback fonts while downloading
  // This prevents the app from showing blank text or waiting for downloads
  GoogleFonts.config.allowRuntimeFetching = true;

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.surface,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const ProviderScope(child: EndpointApp()));
}

class EndpointApp extends StatelessWidget {
  const EndpointApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Endpoint',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      // Prevent layout rebuild when keyboard opens (fixes slow keyboard animation)
      home: const AppShell(),
    );
  }
}
