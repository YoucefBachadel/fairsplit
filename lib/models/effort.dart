class Effort {
  int userId;
  int unitId;
  double effortPerc;
  double evaluation;

  Effort({
    required this.userId,
    required this.unitId,
    required this.effortPerc,
    required this.evaluation,
  });
}

List<Effort> toEfforts(List<dynamic> data) {
  List<Effort> efforts = [];

  for (var element in data) {
    efforts.add(Effort(
      userId: int.parse(element['userId']),
      unitId: int.parse(element['unitId']),
      effortPerc: double.parse(element['effortPerc']),
      evaluation: double.parse(element['evaluation']),
    ));
  }
  return efforts;
}
