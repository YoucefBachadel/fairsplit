class UserHistory {
  String name;
  int year;
  String type;
  double startCapital;
  double totalIn;
  double totalOut;
  double moneyProfit;
  double thresholdProfit;
  double foundingProfit;
  double effortProfit;
  double totalProfit;
  double zakat;
  bool isMoney = false;
  bool isEffort = false;

  UserHistory({
    required this.name,
    required this.year,
    required this.type,
    required this.startCapital,
    required this.totalIn,
    required this.totalOut,
    required this.moneyProfit,
    required this.thresholdProfit,
    required this.foundingProfit,
    required this.effortProfit,
    required this.totalProfit,
    required this.zakat,
  }) {
    isMoney = type == 'money' || type == 'both';
    isEffort = type == 'effort' || type == 'both';
  }
}
