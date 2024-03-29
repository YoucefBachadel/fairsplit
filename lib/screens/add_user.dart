import 'package:flutter/material.dart';

import '/models/effort.dart';
import '/models/founding.dart';
import '/models/threshold.dart' as my_threshold;
import '/models/unit.dart';
import '/models/user.dart';
import '/shared/functions.dart';
import '/shared/constants.dart';
import '/shared/widgets.dart';

class AddUser extends StatefulWidget {
  final User user;
  const AddUser({Key? key, required this.user}) : super(key: key);

  @override
  State<AddUser> createState() => _AddUserState();
}

class _AddUserState extends State<AddUser> {
  late String name, phone, type, capital, threshold, founding, effort, months;
  late double evaluation;
  List<Unit> allUnits = [];
  late List<my_threshold.Threshold> thresholds;
  late List<Founding> foundings;
  late List<Effort> efforts;
  late DateTime joinDate;
  bool isLoading = true;
  bool isMoney = false;
  bool isEffort = false;
  bool isEffortGlobal = false;

  // this to check if has been changed, it will be modified on conferm or delete item
  bool thresholdsHasChanged = false;
  bool foundingssHasChanged = false;
  bool effortssHasChanged = false;
  bool typeHasChanged = false;

  void deleteUser(int userId) async {
    setState(() => isLoading = true);
    Navigator.pop(context);
    await sqlQuery(insertUrl, {
      'sql1': 'DELETE FROM Threshold WHERE userId = $userId',
      'sql2': 'DELETE FROM Founding WHERE userId = $userId',
      'sql3': 'DELETE FROM Effort WHERE userId = $userId',
      'sql4': 'DELETE FROM Users WHERE userId = $userId',
    });

    Navigator.pop(context, true);
    snackBar(context, 'User deleted successfully');
  }

  void loadUnits() async {
    var res = await sqlQuery(selectUrl, {'sql1': '''SELECT unitId , name , type FROM Units;'''});
    List<dynamic> data = res[0];
    for (var element in data) {
      allUnits.add(Unit(unitId: int.parse(element['unitId']), name: element['name'], type: element['type']));
    }
    setState(() => isLoading = false);
  }

  void save() async {
    if (name == '') {
      snackBar(context, 'Name can not be empty!!!', duration: 5);
    } else {
      setState(() => isLoading = true);

      bool isNew = widget.user.userId == -1;

      //chack if the nae exist befor
      bool nameExist = false;
      if (isNew || name != widget.user.name) {
        var res = await sqlQuery(selectUrl, {'sql1': '''SELECT COUNT(*) AS count FROM users WHERE name = '$name';'''});
        nameExist = res[0][0]['count'] != '0';
      }

      if (nameExist) {
        setState(() => isLoading = false);
        snackBar(context, 'Name already exist!!!');
      } else {
        int _userId = widget.user.userId;
        List<String> sqls = [];
        if (isNew) {
          // sending a post request to the url and get the inserted id
          _userId = await sqlQuery(insertSPUrl, {
            'sql':
                '''INSERT INTO Users (name,phone,joinDate,type,capital,initialCapital,money,moneyExtern,threshold,founding,effort,effortExtern,evaluation,months) VALUES ('$name' , '$phone' , '$joinDate' , '$type' , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , $evaluation , '$months');''',
          });
        } else {
          sqls.add(
            '''UPDATE Users SET name = '$name' ,phone = '$phone'  ,joinDate = '$joinDate' ,type = '$type' ,evaluation = $evaluation ,months = '$months' Where userId = $_userId;''',
          );
        }

        userNames.add(name);

        //now we insert the threshold / founding / effort  but first we check if they been changed

        String sql = '';

        if (!isNew) {
          //if the type or the list has changed we delete all existing items of the user and we insert it again
          if (typeHasChanged || thresholdsHasChanged) sqls.add('DELETE FROM Threshold WHERE userId = $_userId;');

          if (typeHasChanged || foundingssHasChanged) sqls.add('DELETE FROM Founding WHERE userId = $_userId;');

          if (typeHasChanged || effortssHasChanged) sqls.add('DELETE FROM Effort WHERE userId = $_userId;');
        }

        if (isMoney && thresholds.isNotEmpty && (typeHasChanged || thresholdsHasChanged)) {
          sql = 'INSERT INTO Threshold(userId, unitId, thresholdPerc) VALUES ';
          for (var element in thresholds) {
            sql += '($_userId , ${element.unitId} , ${element.thresholdPerc}),';
          }
          sql = sql.substring(0, sql.length - 1);
          sql += ';';

          sqls.add(sql);
        }
        if (isMoney && foundings.isNotEmpty && (typeHasChanged || foundingssHasChanged)) {
          sql = 'INSERT INTO Founding(userId, unitId, foundingPerc) VALUES ';
          for (var element in foundings) {
            sql += '($_userId , ${element.unitId} , ${element.foundingPerc}),';
          }
          sql = sql.substring(0, sql.length - 1);
          sql += ';';

          sqls.add(sql);
        }
        if (isEffort && efforts.isNotEmpty && (typeHasChanged || effortssHasChanged)) {
          sql = 'INSERT INTO Effort(userId, unitId, effortPerc,globalUnits) VALUES ';
          for (var element in efforts) {
            sql += '''($_userId , ${element.unitId} , ${element.effortPerc} , '${efforts.first.globalUnits.join(',')}'),''';
          }
          sql = sql.substring(0, sql.length - 1);
          sql += ';';

          sqls.add(sql);
        }

        if (sqls.isNotEmpty) await sqlQuery(insertUrl, {for (var sql in sqls) 'sql${sqls.indexOf(sql) + 1}': sql});
        Navigator.pop(context, true);
        snackBar(context, isNew ? 'User added successfully' : 'User updated successfully');
      }
      setState(() => isLoading = false);
    }
  }

  @override
  void initState() {
    loadUnits();

    name = widget.user.name;
    phone = widget.user.phone;
    type = widget.user.type;
    isMoney = type == 'money' || type == 'both';
    isEffort = type == 'effort' || type == 'both';
    capital = widget.user.capital.toString();
    threshold = widget.user.threshold.toString();
    founding = widget.user.founding.toString();
    effort = widget.user.effort.toString();
    joinDate = widget.user.joinDate;
    evaluation = widget.user.evaluation;
    months = widget.user.months;
    thresholds = widget.user.thresholds;
    foundings = widget.user.foundings;
    efforts = widget.user.efforts;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: (isEffort && efforts.isNotEmpty) || (isEffort && isMoney) ? getWidth(context, .7) : getWidth(context, .47),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            alignment: Alignment.center,
            child: Row(
              children: [
                if (widget.user.userId != -1 && widget.user.capital == 0)
                  myIconButton(
                      onPressed: () => createDialog(
                            context,
                            deleteConfirmation(
                              context,
                              'Are you sure you want to delete this user, once deleted all related information will be deleted too',
                              () => deleteUser(widget.user.userId),
                            ),
                          ),
                      icon: Icons.delete_forever),
                Expanded(
                  child: Text(
                    widget.user.userId == -1 ? 'User' : name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20.0,
                    ),
                  ),
                ),
                myIconButton(onPressed: () => Navigator.pop(context, false), icon: Icons.close)
              ],
            ),
            decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20.0),
                  topRight: Radius.circular(20.0),
                )),
          ),
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
                color: scaffoldColor,
                borderRadius: const BorderRadius.only(
                  bottomRight: Radius.circular(20.0),
                  bottomLeft: Radius.circular(20.0),
                )),
            child: isLoading
                ? SizedBox(height: getHeight(context, .6), child: myProgress())
                : Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: information()),
                          if (efforts.isNotEmpty) SizedBox(height: getHeight(context, .25), child: const VerticalDivider(width: 50)),
                          if (efforts.isNotEmpty) monthsDetail(),
                        ],
                      ),
                      mySizedBox(context),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (isEffort) effortDetail(),
                          if (isMoney) thresholdDetail(),
                          if (isMoney) foundingDetail(),
                        ],
                      ),
                      mySizedBox(context),
                      myButton(context, onTap: () => save()),
                    ],
                  ),
          )
        ],
      ),
    );
  }

  Widget information() {
    Map<String, String> usersTypes = {
      if (efforts.isEmpty) 'money': 'Money',
      if (thresholds.isEmpty && foundings.isEmpty) 'effort': 'Effort',
      'both': 'Both',
    };
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: myText('Name')),
            Expanded(
              flex: 4,
              child: myTextField(
                context,
                hint: name,
                width: getWidth(context, .33),
                onChanged: ((text) {
                  name = text;
                }),
              ),
            ),
          ],
        ),
        mySizedBox(context),
        Row(
          children: [
            Expanded(child: myText('Type')),
            Expanded(
              flex: 4,
              child: Container(
                alignment: Alignment.centerLeft,
                child: myDropDown(
                  context,
                  value: type,
                  width: getWidth(context, .13),
                  items: usersTypes.entries.map((item) {
                    return DropdownMenuItem(
                      value: getKeyFromValue(usersTypes, item.value),
                      alignment: AlignmentDirectional.center,
                      child: Text(item.value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      type = value.toString();
                      typeHasChanged = true;
                      isMoney = type == 'money' || type == 'both';
                      isEffort = type == 'effort' || type == 'both';
                    });
                  },
                ),
              ),
            ),
          ],
        ),
        mySizedBox(context),
        Row(
          children: [
            Expanded(child: myText('Join Date')),
            Expanded(
              flex: 4,
              child: Row(
                children: [
                  Container(
                      height: getHeight(context, textFeildHeight),
                      width: getWidth(context, .10),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.black),
                        borderRadius: const BorderRadius.all(Radius.circular(12)),
                      ),
                      child: myText(myDateFormate.format(joinDate))),
                  mySizedBox(context),
                  myIconButton(
                    icon: Icons.calendar_month,
                    color: primaryColor,
                    onPressed: () async {
                      final DateTime? selected = await showDatePicker(
                        context: context,
                        initialDate: joinDate,
                        initialEntryMode: DatePickerEntryMode.input,
                        firstDate: DateTime(1900, 01, 01, 00, 00, 00),
                        lastDate: DateTime.now(),
                      );
                      if (selected != null && selected != joinDate) {
                        setState(() => joinDate = selected);
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        mySizedBox(context),
        Row(
          children: [
            Expanded(child: myText('Phone')),
            Expanded(
              flex: 4,
              child: myTextField(
                context,
                hint: phone,
                width: getWidth(context, .13),
                onChanged: ((text) {
                  phone = text;
                }),
                isNumberOnly: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget thresholdDetail() {
    return Container(
      height: getHeight(context, .44),
      width: getWidth(context, .22),
      margin: const EdgeInsets.all(2.0),
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(width: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 40,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Threshold',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                if (thresholds.length != allUnits.where((element) => element.type == 'intern').length)
                  myIconButton(
                    onPressed: () {
                      final _allIds = allUnits.where((element) => element.type == 'intern').map((e) => e.unitId).toSet();
                      final _thresholdsIds = thresholds.map((e) => e.unitId).toSet();
                      final _filteredIds = _allIds.difference(_thresholdsIds);
                      createDialog(
                        context,
                        unitSelect(
                          2,
                          units: allUnits.where((element) => _filteredIds.contains(element.unitId)).toList(),
                        ),
                      ).whenComplete(() => setState(() {}));
                    },
                    icon: Icons.add,
                    color: primaryColor,
                  ),
              ],
            ),
          ),
          const Divider(
            thickness: 1.0,
            color: Colors.black,
          ),
          Expanded(
            child: thresholds.isEmpty
                ? emptyList()
                : SingleChildScrollView(
                    child: dataTable(
                      context,
                      columns: ['Unit', 'Percentage', ''].map((e) => dataColumn(context, e)).toList(),
                      rows: thresholds
                          .map((e) => DataRow(
                                onSelectChanged: (value) => createDialog(
                                  context,
                                  unitSelect(
                                    2, listIndex: thresholds.indexOf(e),
                                    percentage: e.thresholdPerc,
                                    //list of units contain only selected unit
                                    units: [Unit(unitId: e.unitId, name: getUnitName(allUnits, e.unitId))],
                                  ),
                                ).whenComplete(() => setState(() {})),
                                cells: [
                                  dataCell(context, getUnitName(allUnits, e.unitId), textAlign: TextAlign.start),
                                  dataCell(context, myPercentage(e.thresholdPerc)),
                                  DataCell(
                                    Center(
                                      child: myIconButton(
                                        onPressed: () {
                                          createDialog(
                                            context,
                                            deleteConfirmation(
                                              context,
                                              'Are you sure you want to delete this item',
                                              () => setState(() {
                                                thresholdsHasChanged = true;
                                                thresholds.remove(e);
                                                Navigator.of(context).pop();
                                              }),
                                              authontication: false,
                                            ),
                                          );
                                        },
                                        icon: Icons.delete_forever,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ),
                                ],
                              ))
                          .toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget foundingDetail() {
    return Container(
      height: getHeight(context, .44),
      width: getWidth(context, .22),
      margin: const EdgeInsets.all(2.0),
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(width: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: [
        SizedBox(
          height: 40,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Founding',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              if (foundings.length != allUnits.where((element) => element.type == 'intern').length)
                myIconButton(
                  onPressed: () {
                    final _allIds = allUnits.where((element) => element.type == 'intern').map((e) => e.unitId).toSet();
                    final _foundingsIds = foundings.map((e) => e.unitId).toSet();
                    final _filteredIds = _allIds.difference(_foundingsIds);
                    createDialog(
                      context,
                      unitSelect(3, units: allUnits.where((element) => _filteredIds.contains(element.unitId)).toList()),
                    ).whenComplete(() => setState(() {}));
                  },
                  icon: Icons.add,
                  color: primaryColor,
                ),
            ],
          ),
        ),
        const Divider(
          thickness: 1.0,
          color: Colors.black,
        ),
        Expanded(
            child: foundings.isEmpty
                ? emptyList()
                : SingleChildScrollView(
                    child: dataTable(
                      context,
                      columns: ['Unit', 'Percentage', ''].map((e) => dataColumn(context, e)).toList(),
                      rows: foundings
                          .map((e) => DataRow(
                                onSelectChanged: (value) => createDialog(
                                  context,
                                  unitSelect(
                                    3, listIndex: foundings.indexOf(e),
                                    percentage: e.foundingPerc,
                                    //list of units contain only selected unit
                                    units: [Unit(unitId: e.unitId, name: getUnitName(allUnits, e.unitId))],
                                  ),
                                ).whenComplete(() => setState(() {})),
                                cells: [
                                  dataCell(context, getUnitName(allUnits, e.unitId), textAlign: TextAlign.start),
                                  dataCell(context, myPercentage(e.foundingPerc)),
                                  DataCell(
                                    Center(
                                      child: myIconButton(
                                        onPressed: () {
                                          createDialog(
                                            context,
                                            deleteConfirmation(
                                              context,
                                              'Are you sure you want to delete this item',
                                              () => setState(() {
                                                foundingssHasChanged = true;
                                                foundings.remove(e);
                                                Navigator.of(context).pop();
                                              }),
                                              authontication: false,
                                            ),
                                          );
                                        },
                                        icon: Icons.delete_forever,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ),
                                ],
                              ))
                          .toList(),
                    ),
                  )),
      ]),
    );
  }

  Widget effortDetail() {
    if (efforts.isNotEmpty) isEffortGlobal = efforts.first.unitId == -1;
    return Container(
      height: getHeight(context, .44),
      width: getWidth(context, .22),
      margin: const EdgeInsets.all(2.0),
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(width: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: [
        SizedBox(
          height: 40,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Effort',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              efforts.isNotEmpty && isEffortGlobal || efforts.length == allUnits.length
                  ? const SizedBox()
                  : myIconButton(
                      onPressed: () {
                        final _allIds = allUnits.map((e) => e.unitId).toSet();
                        final _effortsIds = efforts.map((e) => e.unitId).toSet();
                        final _filteredIds = _allIds.difference(_effortsIds);
                        createDialog(
                          context,
                          unitSelect(1,
                              units: _effortsIds.isEmpty
                                  ? [Unit(unitId: -1, name: 'Global')] + allUnits
                                  : allUnits.where((element) => _filteredIds.contains(element.unitId)).toList()),
                        ).whenComplete(() => setState(() {
                              if (efforts.first.unitId == -1) {
                                for (var unit in allUnits) {
                                  efforts.first.globalUnits.add(unit.unitId);
                                }
                              }
                            }));
                      },
                      icon: Icons.add,
                      color: primaryColor,
                    ),
            ],
          ),
        ),
        const Divider(
          thickness: 1.0,
          color: Colors.black,
        ),
        Expanded(
          child: efforts.isEmpty
              ? emptyList()
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      dataTable(
                        context,
                        columns: ['Unit', 'Percentage', ''].map((e) => dataColumn(context, e)).toList(),
                        rows: efforts
                            .map((e) => DataRow(
                                  onSelectChanged: (value) => createDialog(
                                    context,
                                    unitSelect(
                                      1, listIndex: efforts.indexOf(e),
                                      percentage: e.effortPerc,
                                      //list of units contain only selected unit
                                      units: [
                                        Unit(
                                          unitId: e.unitId,
                                          name: getUnitName([Unit(unitId: -1, name: 'Global')] + allUnits, e.unitId),
                                        )
                                      ],
                                    ),
                                  ).whenComplete(() => setState(() {})),
                                  cells: [
                                    dataCell(
                                      context,
                                      getUnitName([Unit(unitId: -1, name: 'Global')] + allUnits, e.unitId),
                                      textAlign: TextAlign.start,
                                    ),
                                    dataCell(context, myPercentage(e.effortPerc)),
                                    DataCell(
                                      Center(
                                        child: myIconButton(
                                          onPressed: () {
                                            createDialog(
                                              context,
                                              deleteConfirmation(
                                                context,
                                                'Are you sure you want to delete this item',
                                                () => setState(() {
                                                  effortssHasChanged = true;
                                                  efforts.remove(e);
                                                  Navigator.of(context).pop();
                                                }),
                                                authontication: false,
                                              ),
                                            );
                                          },
                                          icon: Icons.delete_forever,
                                          color: Colors.red,
                                        ),
                                      ),
                                    ),
                                  ],
                                ))
                            .toList(),
                      ),
                      if (isEffortGlobal) const Divider(),
                      if (isEffortGlobal)
                        ...allUnits
                            .map((unit) => CheckboxListTile(
                                  value: efforts.first.globalUnits.contains(unit.unitId),
                                  title: myText(unit.name),
                                  onChanged: (value) {
                                    effortssHasChanged = true;
                                    setState(() => value == null
                                        ? null
                                        : value
                                            ? efforts.first.globalUnits.add(unit.unitId)
                                            : efforts.first.globalUnits.remove(unit.unitId));
                                  },
                                ))
                            .toList(),
                    ],
                  ),
                ),
        ),
      ]),
    );
  }

  Widget monthsDetail() {
    return Column(
      children: [
        SizedBox(
          width: getWidth(context, .15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              myText('Evaluation'),
              myTextField(
                context,
                hint: myPercentage(evaluation),
                onChanged: (text) => evaluation = double.parse(text),
                isNumberOnly: true,
              ),
            ],
          ),
        ),
        SizedBox(width: getWidth(context, .15), child: const Divider()),
        Row(
          children: [
            SizedBox(
              width: getWidth(context, .1),
              child: Column(
                children: monthsOfYear
                    .sublist(0, 6)
                    .map((e) => SizedBox(
                          height: 30,
                          child: CheckboxListTile(
                              value: months[monthsOfYear.indexOf(e)] == '1',
                              title: myText(e),
                              onChanged: (val) {
                                setState(() {
                                  final chars = months.characters.toList();
                                  chars[monthsOfYear.indexOf(e)] = val == false ? '0' : '1';
                                  months = chars.join('');
                                });
                              }),
                        ))
                    .toList(),
              ),
            ),
            SizedBox(
              width: getWidth(context, .1),
              child: Column(
                children: monthsOfYear
                    .sublist(6, 12)
                    .map((e) => SizedBox(
                          height: 30,
                          child: CheckboxListTile(
                              value: months[monthsOfYear.indexOf(e)] == '1',
                              title: myText(e),
                              onChanged: (val) {
                                setState(() {
                                  final chars = months.characters.toList();
                                  chars[monthsOfYear.indexOf(e)] = val == false ? '0' : '1';
                                  months = chars.join('');
                                });
                              }),
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget unitSelect(
    int type, {
    List<Unit> units = const [],
    int listIndex = -1,
    double percentage = 0,
  }) {
    //type 1:effort 2:threshold 3:founding
    int _selectedUnitId = units[0].unitId;

    return StatefulBuilder(
      builder: (context, setState) => Container(
        width: getWidth(context, .29),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: scaffoldColor,
          border: Border.all(width: 2.0),
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(child: myText('Unit')),
                Expanded(
                    flex: 3,
                    child: myDropDown(
                      context,
                      value: _selectedUnitId,
                      width: getWidth(context, .19),
                      items: units.map((item) {
                        return DropdownMenuItem(
                          value: item.unitId,
                          alignment: AlignmentDirectional.center,
                          child: Text(item.name),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => _selectedUnitId = value as int),
                    )),
              ],
            ),
            mySizedBox(context),
            Row(
              children: [
                Expanded(child: myText('Percentage')),
                Expanded(
                  flex: 3,
                  child: myTextField(
                    context,
                    hint: myPercentage(percentage),
                    onChanged: ((text) => percentage = double.parse(text)),
                    isNumberOnly: true,
                  ),
                ),
              ],
            ),
            mySizedBox(context),
            myButton(
              context,
              icon: Icons.add,
              text: 'Add',
              onTap: () {
                if (percentage != 0) {
                  switch (type) {
                    case 1:
                      effortssHasChanged = true;
                      if (listIndex == -1) {
                        efforts.add(Effort(
                          userId: widget.user.userId,
                          unitId: _selectedUnitId,
                          effortPerc: percentage,
                          globalUnits: {},
                        ));
                      } else {
                        efforts[listIndex].effortPerc = percentage;
                      }
                      break;
                    case 2:
                      thresholdsHasChanged = true;
                      if (listIndex == -1) {
                        thresholds.add(my_threshold.Threshold(
                          userId: widget.user.userId,
                          unitId: _selectedUnitId,
                          thresholdPerc: percentage,
                        ));
                      } else {
                        thresholds[listIndex].thresholdPerc = percentage;
                      }
                      break;
                    case 3:
                      foundingssHasChanged = true;
                      if (listIndex == -1) {
                        foundings.add(Founding(
                          userId: widget.user.userId,
                          unitId: _selectedUnitId,
                          foundingPerc: percentage,
                        ));
                      } else {
                        foundings[listIndex].foundingPerc = percentage;
                      }
                      break;
                  }

                  Navigator.of(context).pop();
                } else {
                  snackBar(context, 'Value can not be zero!!', duration: 5);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
