class TransactionSP {
  int transactionId;
  int year;
  String category;
  DateTime date;
  String type;
  double amount;
  double solde;
  String note;

  TransactionSP({
    required this.transactionId,
    required this.category,
    required this.type,
    required this.date,
    required this.year,
    required this.amount,
    required this.solde,
    required this.note,
  });
}
