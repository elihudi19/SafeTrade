import 'package:flutter/material.dart';
import '../../services/expense_service.dart';
import '../../l10n/tr.dart';
import '../../widgets/language_switcher.dart';

class ExpenseCreateScreen extends StatefulWidget {
  const ExpenseCreateScreen({super.key});

  @override
  State<ExpenseCreateScreen> createState() => _ExpenseCreateScreenState();
}

class _ExpenseCreateScreenState extends State<ExpenseCreateScreen> {
  final _expenseService = ExpenseService();
  String _category = "transport";
  String _period = "one_time";
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _expenseDate = DateTime.now();
  bool _submitting = false;
  String? _error;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context, initialDate: _expenseDate,
      firstDate: DateTime(2020), lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _expenseDate = picked);
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      setState(() => _error = tr(context, "expense_failed_message"));
      return;
    }
    setState(() { _submitting = true; _error = null; });

    final dateStr =
        "${_expenseDate.year.toString().padLeft(4, '0')}-${_expenseDate.month.toString().padLeft(2, '0')}-${_expenseDate.day.toString().padLeft(2, '0')}";

    final result = await _expenseService.recordExpense(
      category: _category, period: _period, amount: amount,
      expenseDate: dateStr, description: _descriptionController.text.trim(),
    );
    setState(() => _submitting = false);

    if (result["statusCode"] == 201) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr(context, "expense_saved_message"))),
        );
        Navigator.of(context).pop(true);
      }
    } else {
      setState(() => _error = tr(context, "expense_failed_message"));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr(context, "expense_title")),
        actions: const [LanguageSwitcher(), SizedBox(width: 8)],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: _category,
              decoration: InputDecoration(labelText: tr(context, "expense_category_label")),
              items: [
                DropdownMenuItem(value: "transport", child: Text(tr(context, "category_transport"))),
                DropdownMenuItem(value: "rent", child: Text(tr(context, "category_rent"))),
                DropdownMenuItem(value: "utilities", child: Text(tr(context, "category_utilities"))),
                DropdownMenuItem(value: "salaries", child: Text(tr(context, "category_salaries"))),
                DropdownMenuItem(value: "other", child: Text(tr(context, "category_other"))),
              ],
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _period,
              decoration: InputDecoration(labelText: tr(context, "expense_period_label")),
              items: [
                DropdownMenuItem(value: "one_time", child: Text(tr(context, "period_one_time"))),
                DropdownMenuItem(value: "daily", child: Text(tr(context, "period_daily"))),
                DropdownMenuItem(value: "weekly", child: Text(tr(context, "period_weekly"))),
                DropdownMenuItem(value: "monthly", child: Text(tr(context, "period_monthly"))),
              ],
              onChanged: (v) => setState(() => _period = v!),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: tr(context, "amount_label")),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: tr(context, "description_optional_label")),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(tr(context, "expense_date_label")),
              subtitle: Text(
                "${_expenseDate.year}-${_expenseDate.month.toString().padLeft(2, '0')}-${_expenseDate.day.toString().padLeft(2, '0')}",
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickDate,
            ),
            const SizedBox(height: 12),
            if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const CircularProgressIndicator()
                    : Text(tr(context, "save_expense_button")),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
