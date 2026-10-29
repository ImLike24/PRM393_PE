import 'package:flutter/material.dart';
import 'services/session.dart';
import 'views/main_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Session.load();
  runApp(const MusicApp());
}

class MusicApp extends StatefulWidget {
  const MusicApp({super.key});

  @override
  State<MusicApp> createState() => _MusicAppState();
}

class _MusicAppState extends State<MusicApp> {
  @override
  void initState() {
    super.initState();
    Session.onChanged = () {
      if (mounted) setState(() {});
    };
  }

  @override
  void dispose() {
    Session.onChanged = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vinyl Room',
      debugShowCheckedModeBanner: false,
      themeMode: Session.themeMode,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: const Color(0xFFE8A35A),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: const Color(0xFFE8A35A),
        scaffoldBackgroundColor: const Color(0xFF100E0C),
      ),
      home: const MainShell(),
    );
  }
}