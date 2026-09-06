import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../l10n/tr.dart';
import '../widgets/language_switcher.dart';
import 'otp_verification_screen.dart';

/// Usajili wa Business Owner - NIDA + Namba ya Simu (SIYO leseni tena).
/// Mfumo unathibitisha dhidi ya NIDA API kabla ya kutuma OTP - kama
/// namba ya simu haiendani na NIDA, mtumiaji anaona ujumbe wa mismatch
/// na HAAMBIWI kuingiza OTP (kwa sababu haitatumwa kabisa).
class RegisterOwnerScreen extends StatefulWidget {
  const RegisterOwnerScreen({super.key});

  @override
  State<RegisterOwnerScreen> createState() => _RegisterOwnerScreenState();
}

class _RegisterOwnerScreenState extends State<RegisterOwnerScreen> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _nidaNumber = TextEditingController();
  final _phoneNumber = TextEditingController();
  final _businessName = TextEditingController();
  final _auth = AuthService();
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    setState(() { _loading = true; _error = null; });
    final result = await _auth.registerOwner(
      username: _username.text.trim(),
      password: _password.text,
      nidaNumber: _nidaNumber.text.trim(),
      phoneNumber: _phoneNumber.text.trim(),
      businessName: _businessName.text.trim(),
    );
    setState(() => _loading = false);

    if (result["statusCode"] == 201) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => OtpVerificationScreen(phoneNumber: _phoneNumber.text.trim()),
          ),
        );
      }
    } else if (result["data"]?["error"] == "mismatch") {
      // SHERIA MUHIMU: mismatch kati ya NIDA na namba ya simu - hakuna
      // OTP iliyotumwa, mtumiaji anaarifiwa wazi. Ujumbe huu unatoka
      // moja kwa moja backend (tayari umeandikwa vizuri kwa Kiswahili) -
      // hauko kwenye kamusi ya app kwa sababu ni maudhui ya business
      // logic, siyo UI chrome.
      setState(() => _error = result["data"]["message"]);
    } else {
      setState(() => _error = tr(context, "register_generic_error"));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr(context, "register_owner_title")),
        actions: const [LanguageSwitcher(), SizedBox(width: 8)],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: _businessName,
              decoration: InputDecoration(labelText: tr(context, "business_name_label")),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nidaNumber,
              decoration: InputDecoration(
                labelText: tr(context, "nida_number_label"),
                helperText: tr(context, "nida_number_helper"),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneNumber,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: tr(context, "phone_number_nida_label"),
                helperText: tr(context, "phone_number_helper"),
              ),
            ),
            const SizedBox(height: 12),
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
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const CircularProgressIndicator()
                    : Text(tr(context, "confirm_continue_button")),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
