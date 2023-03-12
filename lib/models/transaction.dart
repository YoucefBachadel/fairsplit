class Transaction {
  int transactionId;
  String userName;
  String source; //used for all caisse transactions inTransactions users-specials-loan-deposit-caisse
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
    this.source = 'user',
    required this.year,
    required this.date,
    required this.type,
    required this.amount,
    this.soldeUser = 0,
    required this.soldeCaisse,
    required this.note,
  });
}
