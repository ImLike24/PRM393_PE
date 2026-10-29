import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class Session {
  Session._();

  static User? user;
  static ThemeMode themeMode = ThemeMode.dark;
  static VoidCallback? onChanged;

  static bool get isLoggedIn => user != null;
  static int get userId => user?.userId ?? 0;

  static void _notify() {
    onChanged?.call();
  }

  static Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final dark = p.getBool('dark_mode') ?? true;
    themeMode = dark ? ThemeMode.dark : ThemeMode.light;

    final id = p.getInt('user_id');
    final name = p.getString('username');
    if (id != null && name != null) {
      user = User(
        userId: id,
        username: name,
        password: '',
        email: p.getString('email'),
      );
    }
  }

  static Future<void> setUser(User? u) async {
    user = u;
    final p = await SharedPreferences.getInstance();
    if (u == null) {
      await p.remove('user_id');
      await p.remove('username');
      await p.remove('email');
    } else {
      await p.setInt('user_id', u.userId!);
      await p.setString('username', u.username);
      if (u.email != null) await p.setString('email', u.email!);
    }
    _notify();
  }

  static Future<void> toggleTheme() async {
    themeMode =
    themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.light;
    // fix: toggle dung
    themeMode =
    themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    final p = await SharedPreferences.getInstance();
    await p.setBool('dark_mode', themeMode == ThemeMode.dark);
    _notify();
  }
}