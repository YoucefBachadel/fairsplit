import 'package:fairsplit/shared/constants.dart';

class TransactionOther {
  int transactionId;
  String reference;
  String userName;
  String realUserName;
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
    required this.userName,
    required this.category,
    required this.date,
    required this.type,
    required this.amount,
    required this.soldeUser,
    required this.soldeCaisse,
    required this.note,
    required this.reciver,
    required this.amountOnLetter,
    required this.intermediates,
    required this.printingNotes,
  }) : realUserName = realUserNames[userName] ?? userName;
}
