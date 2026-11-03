import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import 'api_config.dart';

/// Dịch vụ quản lý xác thực người dùng (Đăng nhập & Đăng ký).
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  /// Đăng nhập tài khoản bằng username và password.
  Future<User> login(String username, String password) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    if (res.statusCode != 200) {
      final data = jsonDecode(res.body);
      throw Exception(data['error'] ?? 'Đăng nhập thất bại!');
    }
    return User.fromMap(Map<String, dynamic>.from(jsonDecode(res.body)));
  }

  /// Đăng ký tài khoản mới với username, password và email (tùy chọn).
  Future<User> register(String username, String password, String? email) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
        'email': email,
      }),
    );
    if (res.statusCode != 200) {
      final data = jsonDecode(res.body);
      throw Exception(data['error'] ?? 'Đăng ký thất bại!');
    }
    return User.fromMap(Map<String, dynamic>.from(jsonDecode(res.body)));
  }
}
