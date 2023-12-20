class TransactionOther {
  int transactionId;
  String reference;
  String userName;
  String category;
  String type;
  DateTime date;
  double amount;
  double soldeUser;
  double soldeCaisse;
  String note;
  String reciver;
  String amountOnLetter;
  String intermediates;
  String printingNotes;

  TransactionOther({
    required this.transactionId,
    required this.reference,
    this.userName = '',
    required this.category,
    required this.date,
    required this.type,
    required this.amount,
    required this.soldeUser,
    required this.soldeCaisse,
    required this.note,
    this.reciver = '',
    this.amountOnLetter = '',
    this.intermediates = '',
    this.printingNotes = '',
  });
}
