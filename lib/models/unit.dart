class Unit {
  int unitId;
  String name;
  String type;
  double capital;
  double reservePerc;
  double donationPerc;
  double thresholdFoundingPerc;
  double thresholdPerc;
  double foundingPerc;
  double effortPerc;
  double moneyPerc;
  bool calculated;
  int currentMonth;

  Unit({
    this.unitId = -1,
    this.name = '',
    this.type = 'intern',
    this.capital = 0,
    this.reservePerc = 0,
    this.donationPerc = 0,
    this.thresholdFoundingPerc = 0,
    this.thresholdPerc = 0,
    this.foundingPerc = 0,
    this.effortPerc = 0,
    this.moneyPerc = 0,
    this.calculated = false,
    this.currentMonth = 1,
  });
}

String getUnitName(List<Unit> units, int unitId) {
  for (var element in units) {
    if (element.unitId == unitId) {
      return element.name;
    }
  }
  return '';
}
