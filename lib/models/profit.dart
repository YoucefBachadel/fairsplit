class Profit {
  int profitId;
  String name;
  String type; //intern/extern
  int year;
  int month;
  double profit;
  double reserve;
  double donation;
  double money;
  double effort;
  double threshold;
  double founding;
  Profit({
    this.profitId = 0,
    this.name = '',
    this.type = '',
    this.year = 0,
    this.month = 0,
    this.profit = 0,
    this.reserve = 0,
    this.donation = 0,
    this.money = 0,
    this.effort = 0,
    this.threshold = 0,
    this.founding = 0,
  }) {
    type = month == 0 ? 'extern' : 'intern';
  }
}
