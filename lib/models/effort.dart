class Effort {
  int userId;
  int unitId;
  double effortPerc;

  Effort({
    required this.userId,
    required this.unitId,
    required this.effortPerc,
  });
}

List<Effort> toEfforts(List<dynamic> data) {
  List<Effort> efforts = [];

  for (var element in data) {
    efforts.add(Effort(
      userId: int.parse(element['userId']),
      unitId: int.parse(element['unitId']),
      effortPerc: double.parse(element['effortPerc']),
    ));
  }
  return efforts;
}
