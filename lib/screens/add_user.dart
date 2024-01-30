import 'package:flutter/material.dart';

import '../models/effort.dart';
import '../models/founding.dart';
import '../models/threshold.dart' as my_threshold;
import '../models/unit.dart';
import '../main.dart';
import '../shared/functions.dart';
import '../shared/lists.dart';
import '../shared/constants.dart';
import '../shared/widgets.dart';
import '../models/user.dart';

class AddUser extends StatefulWidget {
  final User user;
  const AddUser({Key? key, required this.user}) : super(key: key);

  @override
  State<AddUser> createState() => _AddUserState();
}

class _AddUserState extends State<AddUser> {
  late String name, phone, type, capital, threshold, founding, effort, months;
  List<Unit> allUnits = [];
  late List<my_threshold.Threshold> thresholds;
  late List<Founding> foundings;
  late List<Effort> efforts;
  late DateTime joinDate;
  bool isLoading = true;
  bool isMoney = false;
  bool isEffort = false;
  // String password = '';

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

    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MyApp(index: 'us')));
    snackBar(context, getMessage('deleteUser'));

    setState(() => isLoading = false);
  }

  void loadUnits() async {
    var res = await sqlQuery(selectUrl, {'sql1': '''SELECT unitId , name FROM Units WHERE type = 'intern';'''});
    List<dynamic> data = res[0];
    for (var element in data) {
      allUnits.add(Unit(unitId: int.parse(element['unitId']), name: element['name']));
    }
    setState(() => isLoading = false);
  }

  void save() async {
    if (name == '') {
      snackBar(context, getMessage('emptyName'), duration: 5);
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
        snackBar(context, getMessage('existName'));
      } else {
        int _userId = widget.user.userId;
        List<String> sqls = [];
        if (isNew) {
          // sending a post request to the url and get the inserted id
          _userId = await sqlQuery(insertSPUrl, {
            'sql':
                '''INSERT INTO Users (name,phone,joinDate,type,capital,initialCapital,money,moneyExtern,threshold,founding,effort,effortExtern,months) VALUES ('$name' , '$phone' , '$joinDate' , '$type' , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , '$months');''',
          });
        } else {
          sqls.add(
            '''UPDATE Users SET name = '$name' ,phone = '$phone'  ,joinDate = '$joinDate' ,type = '$type' ,months = '$months' Where userId = $_userId;''',
          );
        }

        userNames.add(name);

        //now we insert the threshold / founding / effort  but first we check if they been changed

        String sql = '';

        if (!isNew) {
          //if the type or the list has changed we delete all existing items of the user and we insert it again
          if (typeHasChanged || thresholdsHasChanged) sqls.add('DELETE FROM Threshold WHERE userId = $_userId');

          if (typeHasChanged || foundingssHasChanged) sqls.add('DELETE FROM Founding WHERE userId = $_userId');

          if (typeHasChanged || effortssHasChanged) sqls.add('DELETE FROM Effort WHERE userId = $_userId');
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
          sql = 'INSERT INTO Effort(userId, unitId, effortPerc, evaluation) VALUES ';
          for (var element in efforts) {
            sql += '($_userId , ${element.unitId} , ${element.effortPerc} , ${element.evaluation}),';
          }
          sql = sql.substring(0, sql.length - 1);
          sql += ';';

          sqls.add(sql);
        }

        if (sql.isNotEmpty) await sqlQuery(insertUrl, {for (var sql in sqls) 'sql${sqls.indexOf(sql) + 1}': sql});

        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MyApp(index: 'us')));
        snackBar(context, isNew ? getMessage('addUser') : getMessage('updateUser'));
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
    months = widget.user.months;
    thresholds = widget.user.thresholds;
    foundings = widget.user.foundings;
    efforts = widget.user.efforts;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: getHeight(context, .85),
      width: isEffort ? getWidth(context, .75) : getWidth(context, .47),
      child: Column(
        children: [
          Container(
            alignment: Alignment.center,
            child: Row(
              children: [
                if (widget.user.userId != -1 && widget.user.capital == 0)
                  IconButton(
                      onPressed: () => createDialog(
                            context,
                            delteConfirmation(
                              context,
                              getMessage('deleteUserConfirmation'),
                              () => deleteUser(widget.user.userId),
                            ),
                          ),
                      icon: const Icon(
                        Icons.delete_forever,
                        color: Colors.white,
                      )),
                Expanded(
                  child: Text(
                    widget.user.userId == -1 ? getText('user') : name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20.0,
                    ),
                  ),
                ),
                IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                    ))
              ],
            ),
            decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20.0),
                  topRight: Radius.circular(20.0),
                )),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                  color: scaffoldColor,
                  borderRadius: const BorderRadius.only(
                    bottomRight: Radius.circular(20.0),
                    bottomLeft: Radius.circular(20.0),
                  )),
              child: isLoading
                  ? myProgress()
                  : Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: information()),
                            if (efforts.isNotEmpty)
                              SizedBox(height: getHeight(context, .25), child: const VerticalDivider(width: 50)),
                            if (efforts.isNotEmpty) monthsDetail(),
                          ],
                        ),
                        const Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (isEffort) effortDetail(),
                            if (isMoney) thresholdDetail(),
                            if (isMoney) foundingDetail(),
                          ],
                        ),
                        const SizedBox(height: 16.0),
                        myButton(context, onTap: () => save()),
                      ],
                    ),
            ),
          )
        ],
      ),
    );
  }

  Widget information() {
    Map<String, String> usersTypes = {
      'money': getText('money'),
      'effort': getText('effort'),
      'both': getText('both'),
    };
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: myText(getText('name'))),
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
            Expanded(child: myText(getText('type'))),
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
                      value: getKeyFromValue(item.value),
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
            Expanded(child: myText(getText('joinDate'))),
            Expanded(
              flex: 4,
              child: Row(
                children: [
                  myTextField(
                    context,
                    hint: myDateFormate.format(joinDate),
                    width: getWidth(context, .1),
                    enabled: false,
                    onChanged: ((text) {}),
                  ),
                  const SizedBox(width: 5.0),
                  IconButton(
                    icon: Icon(
                      Icons.calendar_month,
                      color: primaryColor,
                    ),
                    onPressed: () async {
                      final DateTime? selected = await showDatePicker(
                        context: context,
                        initialDate: joinDate,
                        initialEntryMode: DatePickerEntryMode.input,
                        firstDate: DateTime(1900, 01, 01, 00, 00, 00),
                        lastDate: DateTime.now(),
                      );
                      if (selected != null && selected != joinDate) {
                        setState(() {
                          joinDate = selected;
                        });
                      }
                    },
                  )
                ],
              ),
            ),
          ],
        ),
        mySizedBox(context),
        Row(
          children: [
            Expanded(child: myText(getText('phone'))),
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
                    getText('threshold'),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                if (thresholds.length != allUnits.length)
                  IconButton(
                    onPressed: () {
                      final _allIds = allUnits.map((e) => e.unitId).toSet();
                      final _thresholdsIds = thresholds.map((e) => e.unitId).toSet();
                      final _filteredIds = _allIds.difference(_thresholdsIds);
                      createDialog(
                        context,
                        unitSelect(2,
                            units: allUnits.where((element) => _filteredIds.contains(element.unitId)).toList()),
                      );
                    },
                    icon: Icon(
                      Icons.add,
                      color: primaryColor,
                    ),
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
                      columns: [getText('unit'), getText('percentage'), ''].map((e) => dataColumn(context, e)).toList(),
                      rows: thresholds
                          .map((e) => DataRow(
                                onSelectChanged: (value) => createDialog(
                                  context,
                                  unitSelect(
                                    2, listIndex: thresholds.indexOf(e),
                                    percentage: e.thresholdPerc,
                                    //list of units contain only selected unit
                                    units: [
                                      Unit(
                                        unitId: e.unitId,
                                        name: getUnitName(allUnits, e.unitId),
                                      )
                                    ],
                                  ),
                                ),
                                cells: [
                                  dataCell(context, getUnitName(allUnits, e.unitId), textAlign: TextAlign.start),
                                  dataCell(context, e.thresholdPerc.toString()),
                                  DataCell(
                                    Center(
                                      child: IconButton(
                                          onPressed: () {
                                            createDialog(
                                              context,
                                              delteConfirmation(
                                                context,
                                                getMessage('deleteItem'),
                                                () => setState(() {
                                                  thresholdsHasChanged = true;
                                                  thresholds.remove(e);
                                                  Navigator.of(context).pop();
                                                }),
                                                authontication: false,
                                              ),
                                            );
                                          },
                                          icon: const Icon(
                                            Icons.delete_forever,
                                            color: Colors.red,
                                          )),
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
                  getText('founding'),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              if (foundings.length != allUnits.length)
                IconButton(
                  onPressed: () {
                    final _allIds = allUnits.map((e) => e.unitId).toSet();
                    final _foundingsIds = foundings.map((e) => e.unitId).toSet();
                    final _filteredIds = _allIds.difference(_foundingsIds);
                    createDialog(
                      context,
                      unitSelect(3, units: allUnits.where((element) => _filteredIds.contains(element.unitId)).toList()),
                    );
                  },
                  icon: Icon(
                    Icons.add,
                    color: primaryColor,
                  ),
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
                      columns: [getText('unit'), getText('percentage'), ''].map((e) => dataColumn(context, e)).toList(),
                      rows: foundings
                          .map((e) => DataRow(
                                onSelectChanged: (value) => createDialog(
                                  context,
                                  unitSelect(
                                    3, listIndex: foundings.indexOf(e),
                                    percentage: e.foundingPerc,
                                    //list of units contain only selected unit
                                    units: [
                                      Unit(
                                        unitId: e.unitId,
                                        name: getUnitName(allUnits, e.unitId),
                                      )
                                    ],
                                  ),
                                ),
                                cells: [
                                  dataCell(context, getUnitName(allUnits, e.unitId), textAlign: TextAlign.start),
                                  dataCell(context, e.foundingPerc.toString()),
                                  DataCell(
                                    Center(
                                      child: IconButton(
                                          onPressed: () {
                                            createDialog(
                                              context,
                                              delteConfirmation(
                                                context,
                                                getMessage('deleteItem'),
                                                () => setState(() {
                                                  foundingssHasChanged = true;
                                                  foundings.remove(e);
                                                  Navigator.of(context).pop();
                                                }),
                                                authontication: false,
                                              ),
                                            );
                                          },
                                          icon: const Icon(
                                            Icons.delete_forever,
                                            color: Colors.red,
                                          )),
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
    return Container(
      height: getHeight(context, .44),
      width: getWidth(context, .27),
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
                  getText('effort'),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              efforts.isNotEmpty && efforts[0].unitId == -1 || efforts.length == allUnits.length
                  ? const SizedBox()
                  : IconButton(
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
                        );
                      },
                      icon: Icon(
                        Icons.add,
                        color: primaryColor,
                      ),
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
                  child: dataTable(
                    context,
                    columns: [getText('unit'), getText('percentage'), getText('evaluation'), '']
                        .map((e) => dataColumn(context, e))
                        .toList(),
                    rows: efforts
                        .map((e) => DataRow(
                              onSelectChanged: (value) => createDialog(
                                context,
                                unitSelect(
                                  1, listIndex: efforts.indexOf(e),
                                  percentage: e.effortPerc,
                                  evaluation: e.evaluation,
                                  //list of units contain only selected unit
                                  units: [
                                    Unit(
                                      unitId: e.unitId,
                                      name: getUnitName([Unit(unitId: -1, name: 'Global')] + allUnits, e.unitId),
                                    )
                                  ],
                                ),
                              ),
                              cells: [
                                dataCell(
                                  context,
                                  getUnitName([Unit(unitId: -1, name: 'Global')] + allUnits, e.unitId),
                                  textAlign: TextAlign.start,
                                ),
                                dataCell(context, e.effortPerc.toString()),
                                dataCell(context, e.evaluation.toString()),
                                DataCell(
                                  Center(
                                    child: IconButton(
                                        onPressed: () {
                                          createDialog(
                                            context,
                                            delteConfirmation(
                                              context,
                                              getMessage('deleteItem'),
                                              () => setState(() {
                                                effortssHasChanged = true;
                                                efforts.remove(e);
                                                Navigator.of(context).pop();
                                              }),
                                              authontication: false,
                                            ),
                                          );
                                        },
                                        icon: const Icon(
                                          Icons.delete_forever,
                                          color: Colors.red,
                                        )),
                                  ),
                                ),
                              ],
                            ))
                        .toList(),
                  ),
                ),
        ),
      ]),
    );
  }

  Widget monthsDetail() {
    return Row(
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
    );
  }

  Widget unitSelect(
    int type, {
    List<Unit> units = const [],
    int listIndex = -1,
    double percentage = 0,
    double evaluation = 100,
  }) {
    //type 1:effort 2:threshold 3:founding
    int _selectedUnitId = units[0].unitId;
    String _percentage = percentage.toString();
    String _evaluation = evaluation.toString();

    return Container(
      height: type == 1 ? getHeight(context, .28) : getHeight(context, .23),
      width: getWidth(context, .29),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: scaffoldColor,
        border: Border.all(width: 2.0),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: myText(getText('unit'))),
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
                    onChanged: (value) {
                      _selectedUnitId = value as int;
                    },
                  )),
            ],
          ),
          mySizedBox(context),
          Row(
            children: [
              Expanded(child: myText(getText('percentage'))),
              Expanded(
                flex: 3,
                child: myTextField(
                  context,
                  hint: percentage.toString(),
                  onChanged: ((text) {
                    _percentage = text;
                  }),
                  isNumberOnly: true,
                ),
              ),
            ],
          ),
          mySizedBox(context),
          if (type == 1)
            Row(
              children: [
                Expanded(child: myText(getText('evaluation'))),
                Expanded(
                  flex: 3,
                  child: myTextField(
                    context,
                    hint: evaluation.toString(),
                    onChanged: ((text) {
                      _evaluation = text;
                    }),
                    isNumberOnly: true,
                  ),
                ),
              ],
            ),
          mySizedBox(context),
          myButton(
            context,
            icon: Icons.add,
            text: getText('add'),
            onTap: () {
              try {
                if (_percentage != '0' && _evaluation != '0') {
                  percentage = double.parse(_percentage);
                  evaluation = double.parse(_evaluation);

                  switch (type) {
                    case 1:
                      effortssHasChanged = true;
                      if (listIndex == -1) {
                        efforts.add(Effort(
                          userId: widget.user.userId,
                          unitId: _selectedUnitId,
                          effortPerc: percentage,
                          evaluation: evaluation,
                        ));
                      } else {
                        efforts[listIndex].effortPerc = percentage;
                        efforts[listIndex].evaluation = evaluation;
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

                  setState(() => Navigator.of(context).pop());
                } else {
                  snackBar(
                    context,
                    getMessage('zeroValue'),
                    duration: 5,
                  );
                }
              } on Exception {
                snackBar(context, getMessage('checkData'), duration: 5);
              }
            },
          ),
          mySizedBox(context),
        ],
      ),
    );
  }
}
