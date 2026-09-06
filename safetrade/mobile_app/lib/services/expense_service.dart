import 'dart:convert';
import 'api_client.dart';
import '../models/expense.dart';

class ExpenseService {
  final ApiClient _client = ApiClient();

  Future<Map<String, dynamic>> recordExpense({
    required String category, // transport | rent | utilities | salaries | other
    required String period, // daily | weekly | monthly | one_time
    required double amount,
    required String expenseDate, // YYYY-MM-DD
    String description = "",
  }) async {
    final res = await _client.post("/expenses/", {
      "category": category, "period": period, "amount": amount,
      "expense_date": expenseDate, "description": description,
    });
    return {"statusCode": res.statusCode, "data": jsonDecode(res.body)};
  }

  Future<List<Expense>> listExpenses() async {
    final res = await _client.get("/expenses/");
    if (res.statusCode != 200) return [];
    final List data = jsonDecode(res.body);
    return data.map((e) => Expense.fromJson(e)).toList();
  }
}
