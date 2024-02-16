import 'package:fairsplit/shared/constants.dart';

class UserHistory {
  String name;
  String realName;
  int year;
  double startCapital;
  double totalIn;
  double totalOut;
  double endCapital;
  double weightedCapital;
  double moneyProfit;
  double thresholdProfit;
  double foundingProfit;
  double effortProfit;
  double totalProfit;
  double zakat;

  UserHistory({
    required this.name,
    required this.year,
    required this.startCapital,
    required this.totalIn,
    required this.totalOut,
    required this.endCapital,
    required this.weightedCapital,
    required this.moneyProfit,
    required this.thresholdProfit,
    required this.foundingProfit,
    required this.effortProfit,
    required this.totalProfit,
    required this.zakat,
  }) : realName = realUserNames[name] ?? name;
}
