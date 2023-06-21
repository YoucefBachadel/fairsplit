import 'package:fairsplit/shared/constants.dart';

import '../models/effort.dart';
import '../models/founding.dart';
import '../models/threshold.dart';

class User {
  int userId;
  String name;
  String phone;
  DateTime joinDate;
  String type;
  double capital;
  double weightedCapital;
  double initialCapital; //used in calculation and to store user capital after passage
  double money;
  double moneyExtern;
  double threshold;
  double founding;
  double effort;
  double effortExtern;
  String months;
  List<Threshold> thresholds;
  List<Founding> foundings;
  List<Effort> efforts;
  double thresholdPerc; // used in users filter for sort
  double foundingPerc; // used in users filter for sort
  double effortPerc; // used in users filter for sort
  double evaluation; // used in users filter for sort

  User({
    this.userId = -1,
    this.name = '',
    this.phone = '0',
    DateTime? joinDate,
    this.type = 'money',
    this.capital = 0,
    this.money = 0,
    this.moneyExtern = 0,
    this.threshold = 0,
    this.founding = 0,
    this.effort = 0,
    this.effortExtern = 0,
    this.months = '111111111111',
    List<Threshold>? thresholds,
    List<Founding>? foundings,
    List<Effort>? efforts,
    this.thresholdPerc = 0,
    this.foundingPerc = 0,
    this.effortPerc = 0,
    this.evaluation = 0,
    this.initialCapital = 0,
  })  : joinDate = joinDate ?? DateTime.now(),
        thresholds = thresholds ?? [],
        foundings = foundings ?? [],
        efforts = efforts ?? [],
        weightedCapital = profitability == 0 ? 0 : (money + moneyExtern) / profitability;
}

List<User> toUsers(
  List<dynamic> data,
  List<Threshold> allThresholds,
  List<Founding> allFoundings,
  List<Effort> allEfforts,
) {
  List<User> users = [];

  for (var element in data) {
    users.add(User(
      userId: int.parse(element['userId']),
      name: element['name'],
      phone: element['phone'],
      joinDate: DateTime.parse(element['joinDate']),
      type: element['type'],
      capital: double.parse(element['capital']),
      initialCapital: double.parse(element['initialCapital']),
      money: double.parse(element['money']),
      moneyExtern: double.parse(element['moneyExtern']),
      threshold: double.parse(element['threshold']),
      founding: double.parse(element['founding']),
      effort: double.parse(element['effort']),
      effortExtern: double.parse(element['effortExtern']),
      months: element['months'],
      thresholds: allThresholds.where((ele) => ele.userId == int.parse(element['userId'])).toList(),
      foundings: allFoundings.where((ele) => ele.userId == int.parse(element['userId'])).toList(),
      efforts: allEfforts.where((ele) => ele.userId == int.parse(element['userId'])).toList(),
    ));
  }
  return users;
}
