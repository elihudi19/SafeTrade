import 'package:flutter/material.dart';
import '../../services/staff_service.dart';
import '../../services/store_service.dart';
import '../../l10n/tr.dart';
import '../../widgets/language_switcher.dart';

class StaffCreateScreen extends StatefulWidget {
  const StaffCreateScreen({super.key});

  @override
  State<StaffCreateScreen> createState() => _StaffCreateScreenState();
}

class _StaffCreateScreenState extends State<StaffCreateScreen> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _phone = TextEditingController();
  final _staffService = StaffService();
  final _storeService = StoreService();

  List<Map<String, dynamic>> _stores = [];
  String? _selectedStoreId;
  String _role = "cashier";
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStores();
  }

  Future<void> _loadStores() async {
    final stores = await _storeService.listStores();
    setState(() {
      _stores = stores;
      if (stores.isNotEmpty) _selectedStoreId = stores.first["id"];
    });
  }

  Future<void> _submit() async {
    if (_selectedStoreId == null) {
      setState(() => _error = tr(context, "select_store_first_error"));
      return;
    }
    setState(() { _loading = true; _error = null; });
    final result = await _staffService.createStaff(
      username: _username.text.trim(),
      password: _password.text,
      role: _role,
      storeId: _selectedStoreId!,
      phoneNumber: _phone.text.trim(),
    );
    setState(() => _loading = false);

    if (result["statusCode"] == 201) {
      if (mounted) Navigator.of(context).pop(true);
    } else {
      setState(() => _error = tr(context, "staff_create_error"));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr(context, "add_staff_title")),
        actions: const [LanguageSwitcher(), SizedBox(width: 8)],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: _selectedStoreId,
              decoration: InputDecoration(labelText: tr(context, "store_label")),
              items: _stores
                  .map((s) => DropdownMenuItem(value: s["id"] as String, child: Text(s["name"])))
                  .toList(),
              onChanged: (v) => setState(() => _selectedStoreId = v),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _role,
              decoration: InputDecoration(labelText: tr(context, "staff_type_label")),
              items: [
                DropdownMenuItem(value: "cashier", child: Text(tr(context, "cashier_role"))),
                DropdownMenuItem(value: "storekeeper", child: Text(tr(context, "storekeeper_role"))),
              ],
              onChanged: (v) => setState(() => _role = v!),
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
            const SizedBox(height: 12),
            TextField(
              controller: _phone,
              decoration: InputDecoration(labelText: tr(context, "phone_number_label")),
            ),
            const SizedBox(height: 20),
            if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const CircularProgressIndicator()
                    : Text(tr(context, "register_button")),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
