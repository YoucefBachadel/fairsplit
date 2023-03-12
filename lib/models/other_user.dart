class OtherUser {
  int userId;
  String name;
  String phone;
  DateTime joinDate;
  String type;
  double amount;
  double rest;

  OtherUser({
    this.userId = -1,
    this.name = '',
    this.phone = '0',
    DateTime? joinDate,
    this.type = 'loan',
    this.amount = 0,
    this.rest = 0,
  }) : joinDate = joinDate ?? DateTime.now();
}
