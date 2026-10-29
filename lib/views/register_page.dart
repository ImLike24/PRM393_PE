import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/session.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final userCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  bool loading = false;

  Future<void> _register() async {
    setState(() => loading = true);
    try {
      final u = await AuthService.instance.register(
        userCtrl.text.trim(),
        passCtrl.text,
        emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
      );
      await Session.setUser(u);
      if (mounted) Navigator.popUntil(context, (r) => r.isFirst);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dang ky')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: userCtrl,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(labelText: 'Email (tuy chon)'),
            ),
            TextField(
              controller: passCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: loading ? null : _register,
              child: const Text('Tao tai khoan'),
            ),
          ],
        ),
      ),
    );
  }
}