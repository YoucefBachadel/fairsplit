class OtherUser {
  int userId;
  String name;
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
  }) : joinDate = joinDate ?? DateTime.now();
}
