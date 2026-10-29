import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import 'api_config.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  Future<User> login(String username, String password) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    if (res.statusCode != 200) {
      throw Exception(jsonDecode(res.body)['error'] ?? 'Dang nhap that bai');
    }
    return User.fromMap(Map<String, dynamic>.from(jsonDecode(res.body)));
  }

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
      throw Exception(jsonDecode(res.body)['error'] ?? 'Dang ky that bai');
    }
    return User.fromMap(Map<String, dynamic>.from(jsonDecode(res.body)));
  }
}