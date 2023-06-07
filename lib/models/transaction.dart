class Transaction {
  int transactionId;
  int userId;
  String userName;
  String source; //used for all caisse transactions inTransactions users-specials-loan-deposit-caisse
  int year;
  String type;
  DateTime date;
  double amount;
  double soldeUser;
  double soldeCaisse;
  String note;
  bool isCaisseChanged; // used to filter the transaction that didn't change soled caisse in caisse traansactions

  Transaction({
    required this.transactionId,
    this.userId = 0,
    this.userName = '',
    this.source = 'user',
    this.year = 0,
    required this.date,
    required this.type,
    required this.amount,
    this.soldeUser = 0,
    this.soldeCaisse = 0,
    this.note = '',
    this.isCaisseChanged = true,
  });
}
