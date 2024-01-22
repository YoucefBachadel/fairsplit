import 'package:fairsplit/shared/constants.dart';

class OtherUser {
  int userId;
  String name;
  String realName;
  String phone;
  DateTime joinDate;
  String type;
  double amount;
  double rest;
  bool isUserWithCapital; // used to check if loan user has rest but he exist as user with capital != 0

  OtherUser({
    this.userId = -1,
    this.name = '',
    this.phone = '0',
    DateTime? joinDate,
    this.type = 'loan',
    this.amount = 0,
    this.rest = 0,
    this.isUserWithCapital = false,
  })  : realName = realUserNames[name] ?? name,
        joinDate = joinDate ?? DateTime.now();
}
