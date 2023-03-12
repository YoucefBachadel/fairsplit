class Threshold {
  int userId;
  int unitId;
  double thresholdPerc;

  Threshold({
    required this.userId,
    required this.unitId,
    required this.thresholdPerc,
  });
}

List<Threshold> toThresholds(List<dynamic> data) {
  List<Threshold> thresholds = [];

  for (var element in data) {
    thresholds.add(Threshold(
      userId: int.parse(element['userId']),
      unitId: int.parse(element['unitId']),
      thresholdPerc: double.parse(element['thresholdPerc']),
    ));
  }
  return thresholds;
}
