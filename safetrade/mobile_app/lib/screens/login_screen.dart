import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../l10n/tr.dart';
import '../widgets/language_switcher.dart';
import 'register_owner_screen.dart';
import 'role_router_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _auth = AuthService();
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    setState(() { _loading = true; _error = null; });
    final result = await _auth.login(_username.text.trim(), _password.text);
    setState(() => _loading = false);

    if (result["statusCode"] == 200) {
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const RoleRouterScreen()),
          (route) => false,
        );
      }
    } else {
      setState(() => _error = tr(context, "login_error"));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr(context, "app_name")),
        actions: const [LanguageSwitcher(), SizedBox(width: 8)],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset("assets/branding/safetrade_logo.png", width: 140),
            const SizedBox(height: 24),
            TextField(
              controller: _username,
              decoration: InputDecoration(labelText: tr(context, "username_label")),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _password,
              obscureText: true,
              decoration: InputDecoration(labelText: tr(context, "password_label")),
            ),
            const SizedBox(height: 20),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const CircularProgressIndicator()
                    : Text(tr(context, "login_button")),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const RegisterOwnerScreen()),
              ),
              child: Text(tr(context, "register_owner_link")),
            ),
          ],
        ),
      ),
    );
  }
}
