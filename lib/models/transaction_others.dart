class TransactionOther {
  int transactionId;
  String reference;
  String userName;
  String category;
  int year;
  String type;
  DateTime date;
  double amount;
  double soldeUser;
  double soldeCaisse;
  String note;

  TransactionOther({
    required this.transactionId,
    required this.reference,
    this.userName = '',
    required this.category,
    required this.year,
    required this.date,
    required this.type,
    required this.amount,
    required this.soldeUser,
    required this.soldeCaisse,
    required this.note,
  });
}
