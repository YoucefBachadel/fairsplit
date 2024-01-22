import 'package:fairsplit/shared/constants.dart';

class Transaction {
  int transactionId;
  String reference;
  int userId;
  String userName;
  String realUserName;
  String source; //used for all caisse transactions inTransactions users-specials-loan-deposit-caisse
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
  bool isCaisseChanged; // used to filter the transaction that didn't change soled caisse in caisse traansactions

  Transaction({
    required this.transactionId,
    this.reference = '',
    this.userId = 0,
    this.userName = '',
    this.source = 'user',
    required this.date,
    required this.type,
    required this.amount,
    this.soldeUser = 0,
    this.soldeCaisse = 0,
    this.note = '',
    this.reciver = '',
    this.amountOnLetter = '',
    this.intermediates = '',
    this.printingNotes = '',
    this.isCaisseChanged = true,
  }) : realUserName = realUserNames[userName] ?? userName;
}
