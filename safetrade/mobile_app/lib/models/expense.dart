class Expense {
  final String id;
  final String category; // transport | rent | utilities | salaries | other
  final String period; // daily | weekly | monthly | one_time
  final double amount;
  final String description;
  final String expenseDate;

  Expense({
    required this.id, required this.category, required this.period,
    required this.amount, required this.description, required this.expenseDate,
  });

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
        id: json["id"], category: json["category"], period: json["period"],
        amount: double.tryParse(json["amount"].toString()) ?? 0,
        description: json["description"] ?? "", expenseDate: json["expense_date"],
      );
}
