import 'package:flutter/material.dart';
import 'services/session.dart';
import 'views/main_shell.dart';

/// Điểm khởi đầu của ứng dụng Vinyl Room.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Session.load();
  runApp(const MusicApp());
}

/// Widget gốc của ứng dụng quản lý Theme và điều hướng chung.
class MusicApp extends StatefulWidget {
  const MusicApp({super.key});

  @override
  State<MusicApp> createState() => _MusicAppState();
}

class _MusicAppState extends State<MusicApp> {
  @override
  void initState() {
    super.initState();
    // Lắng nghe sự thay đổi phiên làm việc hoặc giao diện sáng/tối
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
      // Giao diện Sáng (Light Theme) chuyên nghiệp, tông màu ấm áp
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD49345),
          brightness: Brightness.light,
          primary: const Color(0xFFD49345),
          surface: const Color(0xFFFDFBF7),
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F4EE),
        cardTheme: CardThemeData(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
        ),
      ),
      // Giao diện Tối (Dark Theme) chuyên nghiệp, tông màu Vinyl sang trọng
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE8A35A),
          brightness: Brightness.dark,
          primary: const Color(0xFFE8A35A),
          surface: const Color(0xFF181512),
          surfaceContainerHighest: const Color(0xFF26211C),
        ),
        scaffoldBackgroundColor: const Color(0xFF0F0E0D),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: const Color(0xFF181512),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: const Color(0xFF151210),
          indicatorColor: const Color(0xFFE8A35A).withValues(alpha: 0.2),
        ),
      ),
      home: const MainShell(),
    );
  }
}
