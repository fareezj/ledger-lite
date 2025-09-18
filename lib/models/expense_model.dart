class ExpenseModel {
  final String id;
  final String category;
  final String amount;
  final String date;

  ExpenseModel({
    required this.id,
    required this.category,
    required this.amount,
    required this.date,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['id'] ?? '',
      category: json['category'] ?? '',
      amount: json['amount'] ?? '',
      date: json['date'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'category': category, 'amount': amount, 'date': date};
  }

  ExpenseModel copyWith({
    String? id,
    String? category,
    String? amount,
    String? date,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      date: date ?? this.date,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExpenseModel &&
        other.id == id &&
        other.category == category &&
        other.amount == amount &&
        other.date == date;
  }

  @override
  int get hashCode {
    return id.hashCode ^ category.hashCode ^ amount.hashCode ^ date.hashCode;
  }

  @override
  String toString() {
    return 'ExpenseModel(id: $id, category: $category, amount: $amount, date: $date)';
  }
}
