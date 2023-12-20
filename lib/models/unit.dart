class Unit {
  int unitId;
  String name;
  String type;
  double capital;
  double profit;
  double profitability;
  double reservePerc;
  double donationPerc;
  double thresholdPerc;
  double foundingPerc;
  double effortPerc;
  double moneyPerc;
  int currentMonthOrYear;

  Unit({
    this.unitId = -1,
    this.name = '',
    this.type = 'intern',
    this.capital = 0,
    this.profit = 0,
    this.profitability = 0,
    this.reservePerc = 0,
    this.donationPerc = 0,
    this.thresholdPerc = 0,
    this.foundingPerc = 0,
    this.effortPerc = 0,
    this.moneyPerc = 0,
    this.currentMonthOrYear = 1,
  });
}

String getUnitName(List<Unit> units, int unitId) {
  for (var element in units) {
    if (element.unitId == unitId) return element.name;
  }
  return '';
}
