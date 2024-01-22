class TransactionSP {
  int transactionId;
  String reference;
  String category;
  DateTime date;
  String type;
  double amount;
  double solde;
  String note;
  String reciver;
  String amountOnLetter;
  String intermediates;
  String printingNotes;

  TransactionSP({
    required this.reference,
    required this.transactionId,
    required this.category,
    required this.type,
    required this.date,
    required this.amount,
    required this.solde,
    required this.note,
    required this.reciver,
    required this.amountOnLetter,
    required this.intermediates,
    required this.printingNotes,
  });
}
