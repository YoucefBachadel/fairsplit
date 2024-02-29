import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:provider/provider.dart';
import 'package:pdf/widgets.dart' as pw;

import '../main.dart';
import '../models/effort.dart';
import '../models/founding.dart';
import '../models/threshold.dart';
import '../providers/filter.dart';
import '../shared/functions.dart';
import '../models/unit.dart';
import '../models/user.dart';
import '../shared/constants.dart';
import '../shared/widgets.dart';
import '../screens/add_user.dart';
import 'add_transaction.dart';

class Users extends StatefulWidget {
  const Users({Key? key}) : super(key: key);

  @override
  State<Users> createState() => _UsersState();
}

class _UsersState extends State<Users> {
  List<User> allUsers = [], users = [];
  List<Unit> units = [];
  bool isloading = true;
  String _search = '';
  String _type = 'tout';
  int _thresholdUnitFilter = -2;
  int _foundingUnitFilter = -2;
  int _effortUnitFilter = -2;
  double tcapital = 0, tinitialCapital = 0, tmoney = 0, teffort = 0, tthreshold = 0, tfounding = 0;

  int? _sortColumnIndex = 1;
  bool _isAscending = true;
  TextEditingController _controller = TextEditingController();
  final ScrollController _controllerH = ScrollController(), _controllerV = ScrollController();

  void _newUser(BuildContext context, User user) async =>
      await createDialog(context, AddUser(user: user), dismissable: false);

  void loadData() async {
    var data = await sqlQuery(selectUrl, {
      'sql1': 'SELECT * FROM Threshold;',
      'sql2': 'SELECT * FROM Founding;',
      'sql3': 'SELECT * FROM Effort;',
      'sql4':
          '''SELECT u.*,
                    (SELECT COALESCE(SUM(amount),0)FROM transaction t WHERE t.userId =u.userId AND t.type = 'in' AND Year(date) = $currentYear) AS totalIn,
                    (SELECT COALESCE(SUM(amount),0)FROM transaction t WHERE t.userId =u.userId AND t.type = 'out' AND Year(date) = $currentYear) AS totalOut 
            FROM Users u;''',
      'sql5': '''SELECT unitId , name , type FROM Units;''',
    });
    var dataThresholds = data[0];
    var dataFoundings = data[1];
    var dataEfforts = data[2];
    var dataUsers = data[3];
    var dataUnits = data[4];

    allUsers = toUsers(dataUsers, toThresholds(dataThresholds), toFoundings(dataFoundings), toEfforts(dataEfforts));

    for (var element in dataUnits) {
      units.add(Unit(unitId: int.parse(element['unitId']), name: element['name'], type: element['type']));
    }

    units.sort((a, b) => a.name.compareTo(b.name));

    setState(() {
      isloading = false;
    });
  }

  void filterUsers() async {
    bool _isthresholdFilter = false;
    bool _isfoundingFilter = false;
    bool _iseffortFilter = false;

    tcapital = 0;
    tinitialCapital = 0;
    tmoney = 0;
    teffort = 0;
    tthreshold = 0;
    tfounding = 0;

    users.clear();
    for (var user in allUsers) {
      //first we check if selected threshold filter exist in the user list of thresholds
      if (_thresholdUnitFilter != -2) {
        for (var element in user.thresholds) {
          if (element.unitId == _thresholdUnitFilter) {
            _isthresholdFilter = true;
            user.thresholdPerc = element.thresholdPerc;
            break;
          }
        }
      }
      //same thing with foundings
      if (_foundingUnitFilter != -2) {
        for (var element in user.foundings) {
          if (element.unitId == _foundingUnitFilter) {
            _isfoundingFilter = true;
            user.foundingPerc = element.foundingPerc;
            break;
          }
        }
      }
      //and with efforts
      if (_effortUnitFilter != -2) {
        for (var element in user.efforts) {
          if (element.unitId == _effortUnitFilter) {
            _iseffortFilter = true;
            user.effortPerc = element.effortPerc;
            break;
          }
        }
      }

      //to add user it mast contain search name and the type and the three list filter
      if ((_search.isEmpty || user.realName == _search) &&
          (_type == 'tout' || user.type == _type) &&
          (_thresholdUnitFilter == -2 || _isthresholdFilter) &&
          (_foundingUnitFilter == -2 || _isfoundingFilter) &&
          (_effortUnitFilter == -2 || _iseffortFilter)) {
        users.add(user);

        tcapital += user.capital;
        tinitialCapital += user.initialCapital;
        tmoney += user.money;
        teffort += user.effort;
        tthreshold += user.threshold;
        tfounding += user.founding;
      }

      //at the end we reset the serch atrebut for the next user
      _isthresholdFilter = false;
      _isfoundingFilter = false;
      _iseffortFilter = false;
    }

    onSort();
  }

  void onSort() {
    switch (_sortColumnIndex) {
      case 1:
        users.sort((tr1, tr2) {
          return !_isAscending ? tr2.realName.compareTo(tr1.realName) : tr1.realName.compareTo(tr2.realName);
        });
        break;
      case 3:
        users.sort((tr1, tr2) {
          return !_isAscending ? tr2.capital.compareTo(tr1.capital) : tr1.capital.compareTo(tr2.capital);
        });
        break;
      case 4:
        users.sort((tr1, tr2) {
          return !_isAscending
              ? tr2.weightedCapital.compareTo(tr1.weightedCapital)
              : tr1.weightedCapital.compareTo(tr2.weightedCapital);
        });
        break;
      case 5:
        users.sort((tr1, tr2) {
          return !_isAscending
              ? tr2.initialCapital.compareTo(tr1.initialCapital)
              : tr1.initialCapital.compareTo(tr2.initialCapital);
        });
        break;
      case 6:
        users.sort((tr1, tr2) {
          return !_isAscending ? tr2.totalIn.compareTo(tr1.totalIn) : tr1.totalIn.compareTo(tr2.totalIn);
        });
        break;
      case 7:
        users.sort((tr1, tr2) {
          return !_isAscending ? tr2.totalOut.compareTo(tr1.totalOut) : tr1.totalOut.compareTo(tr2.totalOut);
        });
        break;
      case 8:
        users.sort((tr1, tr2) {
          return !_isAscending
              ? (tr2.money + tr2.moneyExtern).compareTo(tr1.money + tr1.moneyExtern)
              : (tr1.money + tr1.moneyExtern).compareTo(tr2.money + tr2.moneyExtern);
        });
        break;
      case 9:
        users.sort((tr1, tr2) {
          return !_isAscending ? tr2.threshold.compareTo(tr1.threshold) : tr1.threshold.compareTo(tr2.threshold);
        });
        break;
      case 10:
        users.sort((tr1, tr2) {
          return !_isAscending ? tr2.founding.compareTo(tr1.founding) : tr1.founding.compareTo(tr2.founding);
        });
        break;
      case 11:
        users.sort((tr1, tr2) {
          return !_isAscending
              ? (tr2.effort + tr2.effortExtern).compareTo(tr1.effort + tr1.effortExtern)
              : (tr1.effort + tr1.effortExtern).compareTo(tr2.effort + tr2.effortExtern);
        });
        break;
      case 12:
        users.sort((tr1, tr2) {
          if (_thresholdUnitFilter != -2) {
            return !_isAscending
                ? tr2.thresholdPerc.compareTo(tr1.thresholdPerc)
                : tr1.thresholdPerc.compareTo(tr2.thresholdPerc);
          } else if (_foundingUnitFilter != -2) {
            return !_isAscending
                ? tr2.foundingPerc.compareTo(tr1.foundingPerc)
                : tr1.foundingPerc.compareTo(tr2.foundingPerc);
          } else {
            return !_isAscending ? tr2.effortPerc.compareTo(tr1.effortPerc) : tr1.effortPerc.compareTo(tr2.effortPerc);
          }
        });
        break;
      case 13:
        users.sort((tr1, tr2) {
          if (_thresholdUnitFilter != -2 && _foundingUnitFilter != -2) {
            return !_isAscending
                ? tr2.foundingPerc.compareTo(tr1.foundingPerc)
                : tr1.foundingPerc.compareTo(tr2.foundingPerc);
          } else if ((_thresholdUnitFilter == -2 && _foundingUnitFilter != -2) ||
              (_thresholdUnitFilter != -2 && _foundingUnitFilter == -2)) {
            return !_isAscending ? tr2.effortPerc.compareTo(tr1.effortPerc) : tr1.effortPerc.compareTo(tr2.effortPerc);
          } else {
            return !_isAscending ? tr2.evaluation.compareTo(tr1.evaluation) : tr1.evaluation.compareTo(tr2.evaluation);
          }
        });
        break;
      case 14:
        users.sort((tr1, tr2) {
          if (_thresholdUnitFilter != -2 && _foundingUnitFilter != -2) {
            return !_isAscending ? tr2.effort.compareTo(tr1.effort) : tr1.effort.compareTo(tr2.effort);
          } else {
            return !_isAscending ? tr2.evaluation.compareTo(tr1.evaluation) : tr1.evaluation.compareTo(tr2.evaluation);
          }
        });
        break;
      case 15:
        users.sort((tr1, tr2) {
          return !_isAscending ? tr2.evaluation.compareTo(tr1.evaluation) : tr1.evaluation.compareTo(tr2.evaluation);
        });
        break;
    }
  }

  void clearSearch() {
    setState(() {
      _search = '';
      _controller.clear();
    });
  }

  @override
  void initState() {
    loadData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    filterUsers();

    List<DataColumn> columns = [
      dataColumn(context, ''),
      sortableDataColumn(
        context,
        'Name',
        (columnIndex, ascending) => setState(() {
          _sortColumnIndex = columnIndex;
          _isAscending = ascending;
        }),
      ),
      dataColumn(context, 'Type'),
      ...[
        'Capital',
        'Weighted Capital',
        'Initial Capital',
        'Total Entrie',
        'Total Sortie',
        'Money',
        'Threshold',
        'Founding',
        'Effort',
        if (_thresholdUnitFilter != -2) 'Threshold %',
        if (_foundingUnitFilter != -2) 'Founding %',
        if (_effortUnitFilter != -2) ...['Effort %', 'Evaluation'],
      ].map(
        (e) => sortableDataColumn(
          context,
          e,
          (columnIndex, ascending) => setState(() {
            _sortColumnIndex = columnIndex;
            _isAscending = ascending;
          }),
        ),
      ),
      if (isAdmin) dataColumn(context, ''),
    ];

    List<DataRow> rows = users
        .map((user) => DataRow(
              color: user.capital < 0
                  ? MaterialStatePropertyAll(Colors.red[100])
                  : ((user.capital != 0 && user.type == 'effort') ||
                          (user.effort + user.effortExtern != 0 && user.type == 'money'))
                      ? MaterialStatePropertyAll(Colors.green[100])
                      : null,
              onLongPress: () {
                context.read<Filter>().change(transactionCategory: 'users', search: user.realName);
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MyApp(index: 'tr')));
              },
              onSelectChanged: (value) async => await createDialog(
                context,
                AddTransaction(
                  sourceTab: 'us',
                  userId: user.userId,
                  selectedName: user.name,
                  userCapital: user.capital,
                  selectedTransactionType: 1,
                ),
                dismissable: false,
              ),
              cells: [
                dataCell(context, (users.indexOf(user) + 1).toString()),
                dataCell(context, user.realName, textAlign: TextAlign.start),
                dataCell(context, getText(userTypes, user.type)),
                dataCell(context, myCurrency(user.capital), textAlign: TextAlign.end),
                dataCell(context, myCurrency(user.weightedCapital), textAlign: TextAlign.end),
                dataCell(context, myCurrency(user.initialCapital), textAlign: TextAlign.end),
                dataCell(context, myCurrency(user.totalIn), textAlign: TextAlign.end),
                dataCell(context, myCurrency(user.totalOut), textAlign: TextAlign.end),
                dataCell(context, myCurrency(user.money + user.moneyExtern), textAlign: TextAlign.end),
                dataCell(context, myCurrency(user.threshold), textAlign: TextAlign.end),
                dataCell(context, myCurrency(user.founding), textAlign: TextAlign.end),
                dataCell(
                  context,
                  myCurrency(user.effort + user.effortExtern),
                  textAlign: TextAlign.end,
                ),
                if (_thresholdUnitFilter != -2)
                  dataCell(
                      context,
                      myPercentage(user.thresholds
                          .firstWhere((element) => element.unitId == _thresholdUnitFilter)
                          .thresholdPerc)),
                if (_foundingUnitFilter != -2)
                  dataCell(
                      context,
                      myPercentage(
                          user.foundings.firstWhere((element) => element.unitId == _foundingUnitFilter).foundingPerc)),
                if (_effortUnitFilter != -2) ...[
                  dataCell(
                    context,
                    myPercentage(user.efforts.first.unitId == -1
                        ? user.efforts.first.effortPerc
                        : user.efforts.firstWhere((element) => element.unitId == _effortUnitFilter).effortPerc),
                  ),
                  dataCell(
                    context,
                    myPercentage(user.evaluation),
                  ),
                ],
                if (isAdmin)
                  DataCell(
                    myIconButton(
                      onPressed: () => _newUser(context, user),
                      icon: Icons.edit,
                      color: primaryColor,
                    ),
                  ),
              ],
            ))
        .toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              mini: true,
              onPressed: () => _newUser(context, User()),
              tooltip: 'New User',
              child: const Icon(Icons.add),
            )
          : null,
      body: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0),
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey,
              blurRadius: 3.0,
            ),
          ],
        ),
        child: Column(
          children: [
            const SizedBox(width: double.minPositive, height: 8.0),
            searchBar(),
            const SizedBox(width: double.minPositive, height: 8.0),
            SizedBox(width: getWidth(context, .52), child: const Divider()),
            const SizedBox(width: double.minPositive, height: 8.0),
            Expanded(
                child: isloading
                    ? myProgress()
                    : users.isEmpty
                        ? SizedBox(width: getWidth(context, .45), child: emptyList())
                        : users.isEmpty
                            ? emptyList()
                            : myScorallable(
                                dataTable(
                                  context,
                                  isAscending: _isAscending,
                                  sortColumnIndex: _sortColumnIndex,
                                  columns: columns,
                                  rows: rows,
                                ),
                                _controllerH,
                                _controllerV,
                              )),
            SizedBox(width: getWidth(context, .52), child: const Divider()),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  children: [
                    totalItem(context, 'Capital', myCurrency(tcapital)),
                    totalItem(context, 'Initial Capital', myCurrency(tinitialCapital)),
                  ],
                ),
                SizedBox(height: getHeight(context, .05), child: const VerticalDivider(width: 50)),
                Column(
                  children: [
                    totalItem(context, 'Money', myCurrency(tmoney)),
                    totalItem(context, 'Effort', myCurrency(teffort)),
                  ],
                ),
                SizedBox(height: getHeight(context, .05), child: const VerticalDivider(width: 50)),
                Column(
                  children: [
                    totalItem(context, 'Threshold', myCurrency(tthreshold)),
                    totalItem(context, 'Founding', myCurrency(tfounding)),
                  ],
                ),
              ],
            ),
            mySizedBox(context),
          ],
        ),
      ),
    );
  }

  Widget searchBar() {
    Map<String, String> usersTypesSearch = {
      'tout': 'Tout',
      'money': 'Money',
      'effort': 'Effort',
      'both': 'Both',
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 8.0),
                child: Text('Name', style: TextStyle(fontSize: 14)),
              ),
              Autocomplete<String>(
                onSelected: (item) => setState(() => _search = item),
                optionsBuilder: (textEditingValue) {
                  return userNames.where((item) => item.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                },
                fieldViewBuilder: (
                  context,
                  textEditingController,
                  focusNode,
                  onFieldSubmitted,
                ) {
                  _controller = textEditingController;
                  return SizedBox(
                    height: getHeight(context, textFeildHeight),
                    width: getWidth(context, .18),
                    child: TextField(
                      controller: _controller,
                      focusNode: focusNode,
                      style: const TextStyle(fontSize: 16.0),
                      textAlign: TextAlign.center,
                      onSubmitted: ((value) {
                        if (userNames.where((item) => item.toLowerCase().contains(value.toLowerCase())).isNotEmpty) {
                          String text =
                              userNames.firstWhere((item) => item.toLowerCase().contains(value.toLowerCase()));
                          setState(() {
                            _controller.text = text;
                            _search = text;
                          });
                        }
                      }),
                      decoration: textInputDecoration(
                        hint: 'Search...',
                        borderColor: _search.isEmpty ? Colors.grey : primaryColor,
                        prefixIcon: const Icon(Icons.search, size: 20.0),
                        suffixIcon: _controller.text.isEmpty
                            ? null
                            : myIconButton(
                                onPressed: () {
                                  setState(() {
                                    _controller.clear();
                                    _search = '';
                                  });
                                },
                                icon: Icons.clear,
                                color: Colors.grey),
                      ),
                    ),
                  );
                },
                optionsViewBuilder: (
                  BuildContext context,
                  AutocompleteOnSelected<String> onSelected,
                  Iterable<String> options,
                ) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 8.0,
                      child: ConstrainedBox(
                        constraints:
                            BoxConstraints(maxHeight: getHeight(context, .2), maxWidth: getWidth(context, .18)),
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: options.length,
                          itemBuilder: (BuildContext context, int index) {
                            final String option = options.elementAt(index);
                            return InkWell(
                              onTap: () => onSelected(option),
                              child: Container(
                                padding: const EdgeInsets.all(16.0),
                                alignment: Alignment.centerLeft,
                                child: myText(option),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          mySizedBox(context),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 8.0),
                child: Text('Type', style: TextStyle(fontSize: 14)),
              ),
              myDropDown(
                context,
                value: _type,
                color: _type == 'tout' ? Colors.grey : primaryColor,
                items: usersTypesSearch.entries.map((item) {
                  return DropdownMenuItem(
                    value: getKeyFromValue(usersTypesSearch, item.value),
                    alignment: AlignmentDirectional.center,
                    child: Text(item.value),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _type = value.toString();
                  });
                },
              ),
            ],
          ),
          mySizedBox(context),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 8.0),
                child: Text('Threshold', style: TextStyle(fontSize: 14)),
              ),
              myDropDown(
                context,
                value: _thresholdUnitFilter,
                width: getWidth(context, .14),
                color: _thresholdUnitFilter == -2 ? Colors.grey : primaryColor,
                items: ([Unit(unitId: -2, name: 'Tout')] + units.where((element) => element.type == 'intern').toList())
                    .map((item) {
                  return DropdownMenuItem(
                    value: item.unitId,
                    alignment: AlignmentDirectional.center,
                    child: Text(item.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _thresholdUnitFilter = int.parse(value.toString());
                  });
                },
              )
            ],
          ),
          mySizedBox(context),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 8.0),
                child: Text('Founding', style: TextStyle(fontSize: 14)),
              ),
              myDropDown(
                context,
                value: _foundingUnitFilter,
                width: getWidth(context, .14),
                color: _foundingUnitFilter == -2 ? Colors.grey : primaryColor,
                items: ([Unit(unitId: -2, name: 'Tout')] + units.where((element) => element.type == 'intern').toList())
                    .map((item) {
                  return DropdownMenuItem(
                    value: item.unitId,
                    alignment: AlignmentDirectional.center,
                    child: Text(item.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _foundingUnitFilter = int.parse(value.toString());
                  });
                },
              )
            ],
          ),
          mySizedBox(context),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 8.0),
                child: Text('Effort', style: TextStyle(fontSize: 14)),
              ),
              myDropDown(
                context,
                value: _effortUnitFilter,
                width: getWidth(context, .14),
                color: _effortUnitFilter == -2 ? Colors.grey : primaryColor,
                items: ([Unit(unitId: -2, name: 'Tout'), Unit(unitId: -1, name: 'Global')] + units).map((item) {
                  return DropdownMenuItem(
                    value: item.unitId,
                    alignment: AlignmentDirectional.center,
                    child: Text(item.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _effortUnitFilter = int.parse(value.toString());
                  });
                },
              )
            ],
          ),
          mySizedBox(context),
          myIconButton(
            onPressed: () => createExcel(
              'Users',
              [
                [
                  '#',
                  'Name',
                  'Phone',
                  'Join Date',
                  'Type',
                  'Capital',
                  'Weighted Capital',
                  'Initial Capital',
                  'Total Entrie',
                  'Total Sortie',
                  'Money',
                  'Threshold',
                  'Founding',
                  'Effort',
                  if (_thresholdUnitFilter != -2) 'Threshold',
                  if (_foundingUnitFilter != -2) 'Founding',
                  if (_effortUnitFilter != -2) ...['Effort', 'Evaluation']
                ],
                ...users.map((user) => [
                      users.indexOf(user) + 1,
                      user.realName,
                      user.phone,
                      myDateFormate.format(user.joinDate),
                      getText(userTypes, user.type),
                      user.capital,
                      user.weightedCapital,
                      user.initialCapital,
                      user.totalIn,
                      user.totalOut,
                      user.money + user.moneyExtern,
                      user.threshold,
                      user.founding,
                      user.effort + user.effortExtern,
                      if (_thresholdUnitFilter != -2) user.thresholdPerc,
                      if (_foundingUnitFilter != -2) user.foundingPerc,
                      if (_effortUnitFilter != -2) ...[user.effortPerc, user.evaluation]
                    ])
              ],
            ),
            icon: Icons.file_download,
            color: primaryColor,
          ),
          myIconButton(
            icon: Icons.print,
            color: primaryColor,
            onPressed: () => createDialog(context, SizedBox(child: printPage())),
          ),
          if (_controller.text.isNotEmpty ||
              _type != 'tout' ||
              _thresholdUnitFilter != -2 ||
              _foundingUnitFilter != -2 ||
              _effortUnitFilter != -2)
            myIconButton(
              onPressed: () => setState(() {
                _search = '';
                _controller.clear();
                _type = 'tout';
                _thresholdUnitFilter = -2;
                _foundingUnitFilter = -2;
                _effortUnitFilter = -2;
                if (_sortColumnIndex! > 8) _sortColumnIndex = 1;
              }),
              icon: Icons.update,
              color: primaryColor,
            ),
        ],
      ),
    );
  }

  Widget printPage() {
    final pdf = pw.Document();

    pdf.addPage(pdfPage(
      pdfPageFormat: PdfPageFormat.a4.landscape,
      pageOrientation: pw.PageOrientation.landscape,
      build: [
        pw.Table.fromTextArray(
          headers: [
            'Name',
            'Type',
            'Capital',
            'Weighted Capital',
            'Initial Capital',
            'Total Entrie',
            'Total Sortie',
            'Money',
            'Threshold',
            'Founding',
            'Effort',
          ],
          data: users
              .map((user) => [
                    user.realName,
                    getText(userTypes, user.type),
                    myCurrency(user.capital),
                    myCurrency(user.weightedCapital),
                    myCurrency(user.initialCapital),
                    myCurrency(user.totalIn),
                    myCurrency(user.totalOut),
                    myCurrency(user.money + user.moneyExtern),
                    myCurrency(user.threshold),
                    myCurrency(user.founding),
                    myCurrency(user.effort + user.effortExtern),
                  ])
              .toList(),
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
          cellStyle: const pw.TextStyle(fontSize: 10),
          cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8),
          border: const pw.TableBorder(
            horizontalInside: pw.BorderSide(width: .01, color: PdfColors.grey),
            verticalInside: pw.BorderSide(width: .01, color: PdfColors.grey),
            top: pw.BorderSide(width: .01, color: PdfColors.grey),
            left: pw.BorderSide(width: .01, color: PdfColors.grey),
            bottom: pw.BorderSide(width: .01, color: PdfColors.grey),
            right: pw.BorderSide(width: .01, color: PdfColors.grey),
          ),
          cellAlignments: {
            0: pw.Alignment.centerLeft,
            1: pw.Alignment.center,
            2: pw.Alignment.centerRight,
            3: pw.Alignment.centerRight,
            4: pw.Alignment.centerRight,
            5: pw.Alignment.centerRight,
            6: pw.Alignment.centerRight,
            7: pw.Alignment.centerRight,
            8: pw.Alignment.centerRight,
            9: pw.Alignment.centerRight,
            10: pw.Alignment.centerRight,
            11: pw.Alignment.centerRight,
            12: pw.Alignment.centerRight,
            13: pw.Alignment.centerRight,
          },
        ),
      ],
    ));

    return pdfPreview(context, pdf, 'Users');
  }
}
