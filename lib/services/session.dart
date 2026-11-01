import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

/// Quản lý phiên làm việc của người dùng hiện tại và cài đặt giao diện (ThemeMode).
class Session {
  Session._();

  static User? user;
  static ThemeMode themeMode = ThemeMode.dark;
  static VoidCallback? onChanged;

  /// Kiểm tra xem người dùng đã đăng nhập chưa.
  static bool get isLoggedIn => user != null;

  /// Trả về ID của người dùng (trả về 0 nếu chưa đăng nhập).
  static int get userId => user?.userId ?? 0;

  /// Thông báo cho giao diện khi phiên làm việc hoặc theme thay đổi.
  static void _notify() {
    onChanged?.call();
  }

  /// Tải thông tin người dùng và cài đặt giao diện đã lưu từ bộ nhớ máy (SharedPreferences).
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

  /// Lưu thông tin đăng nhập người dùng (truyền null nếu muốn đăng xuất).
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

  /// Chuyển đổi giữa chế độ sáng và tối (Light / Dark mode).
  static Future<void> toggleTheme() async {
    themeMode = themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    final p = await SharedPreferences.getInstance();
    await p.setBool('dark_mode', themeMode == ThemeMode.dark);
    _notify();
  }
}
