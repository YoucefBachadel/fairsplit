class TransactionOthers {
  int transactionId;
  String userName;
  int year;
  String type;
  DateTime date;
  double amount;
  double soldeCaisse;
  String note;

  TransactionOthers({
    required this.transactionId,
    this.userName = '',
    required this.year,
    required this.date,
    required this.type,
    required this.amount,
    required this.soldeCaisse,
    required this.note,
  });
}
