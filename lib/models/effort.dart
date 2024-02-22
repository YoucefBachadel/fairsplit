class Effort {
  int userId;
  int unitId;
  double effortPerc;
  Set<int> globalUnits;

  Effort({
    required this.userId,
    required this.unitId,
    required this.effortPerc,
    required this.globalUnits,
  });
}

List<Effort> toEfforts(List<dynamic> data) {
  List<Effort> efforts = [];
  late int _unitId;
  late String _globalUnitData;
  late Set<int> _globalUnits;

  for (var element in data) {
    _unitId = int.parse(element['unitId']);
    _globalUnitData = element['globalUnits'];
    _globalUnits = {};

    if (_unitId == -1 && _globalUnitData.isNotEmpty) {
      for (var id in _globalUnitData.split(',')) {
        _globalUnits.add(int.parse(id));
      }
    }

    efforts.add(Effort(
      userId: int.parse(element['userId']),
      unitId: _unitId,
      effortPerc: double.parse(element['effortPerc']),
      globalUnits: _globalUnits,
    ));
  }
  return efforts;
}
