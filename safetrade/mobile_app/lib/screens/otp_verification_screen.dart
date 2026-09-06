import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../l10n/tr.dart';
import '../widgets/language_switcher.dart';
import 'login_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  const OtpVerificationScreen({super.key, required this.phoneNumber});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _code = TextEditingController();
  final _auth = AuthService();
  bool _loading = false;
  String? _error;

  Future<void> _verify() async {
    setState(() { _loading = true; _error = null; });
    final result = await _auth.verifyOtp(widget.phoneNumber, _code.text.trim());
    setState(() => _loading = false);

    if (result["statusCode"] == 200) {
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    } else {
      setState(() => _error = result["data"]?["error"] ?? tr(context, "otp_invalid_error"));
    }
  }

  Future<void> _resend() async {
    await _auth.resendOtp(widget.phoneNumber);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(context, "otp_resent_message"))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr(context, "otp_verify_title")),
        actions: const [LanguageSwitcher(), SizedBox(width: 8)],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("${tr(context, "otp_sent_to")} ${widget.phoneNumber}"),
            const SizedBox(height: 16),
            TextField(
              controller: _code,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(labelText: tr(context, "otp_input_label")),
            ),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _verify,
                child: _loading
                    ? const CircularProgressIndicator()
                    : Text(tr(context, "otp_verify_button")),
              ),
            ),
            TextButton(onPressed: _resend, child: Text(tr(context, "otp_resend_button"))),
          ],
        ),
      ),
    );
  }
}
