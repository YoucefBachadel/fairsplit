class TransactionOther {
  int transactionId;
  String userName;
  String category;
  int year;
  String type;
  DateTime date;
  double amount;
  double soldeCaisse;
  String note;

  TransactionOther({
    required this.transactionId,
    this.userName = '',
    required this.category,
    required this.year,
    required this.date,
    required this.type,
    required this.amount,
    required this.soldeCaisse,
    required this.note,
  });
}
