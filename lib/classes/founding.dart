class Founding {
  int userId;
  int unitId;
  double foundingPerc;

  Founding({
    required this.userId,
    required this.unitId,
    required this.foundingPerc,
  });
}

List<Founding> toFoundings(List<dynamic> data) {
  List<Founding> foundings = [];

  for (var element in data) {
    foundings.add(Founding(
      userId: int.parse(element['userId']),
      unitId: int.parse(element['unitId']),
      foundingPerc: double.parse(element['foundingPerc']),
    ));
  }
  return foundings;
}
