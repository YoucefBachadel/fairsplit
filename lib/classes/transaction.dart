class Transaction {
  int transactionId;
  String userName;
  int year;
  String type;
  DateTime date;
  double amount;
  double soldeUser;
  double soldeCaisse;
  String note;

  Transaction({
    required this.transactionId,
    this.userName = '',
    required this.year,
    required this.date,
    required this.type,
    required this.amount,
    required this.soldeUser,
    required this.soldeCaisse,
    required this.note,
  });
}
