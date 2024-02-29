import 'package:fairsplit/main.dart';
import 'package:fairsplit/screens/calculation.dart';
import 'package:flutter/material.dart';

import '../models/unit.dart';
import '../shared/functions.dart';
import '../shared/constants.dart';
import '../shared/widgets.dart';
import 'add_unit.dart';

class Units extends StatefulWidget {
  const Units({Key? key}) : super(key: key);

  @override
  State<Units> createState() => _UnitsState();
}

class _UnitsState extends State<Units> {
  bool isLoadingUnits = true;
  List<Unit> units = [];
  double totalCapital = 1,
      internCapital = 0,
      externCapital = 0,
      internProfit = 0,
      externProfit = 0,
      internProfitability = 0,
      externProfitability = 0;
  int internCount = 0, externCount = 0;

  int? _sortColumnIndex = 0;
  bool _isAscending = true, isResetting = false;
  final ScrollController _controllerH = ScrollController(), _controllerV = ScrollController();

  void _newUnit(BuildContext context, Unit unit) async => await createDialog(context, AddUnit(unit: unit));

  void loadUnits() async {
    var res = await sqlQuery(selectUrl, {'sql1': 'SELECT * FROM Units;'});
    var dataUnits = res[0];
    for (var ele in dataUnits) {
      units.add(Unit(
        unitId: int.parse(ele['unitId']),
        name: ele['name'],
        type: ele['type'],
        capital: double.parse(ele['capital']),
        profit: double.parse(ele['profit']),
        profitability: double.parse(ele['profitability']),
        reservePerc: double.parse(ele['reservePerc']),
        donationPerc: double.parse(ele['donationPerc']),
        moneyPerc: double.parse(ele['moneyPerc']),
        effortPerc: double.parse(ele['effortPerc']),
        thresholdPerc: double.parse(ele['thresholdPerc']),
        foundingPerc: double.parse(ele['foundingPerc']),
        currentMonthOrYear: int.parse(ele['currentMonthOrYear']),
      ));
      totalCapital += double.parse(ele['capital']);
      if (ele['type'] == 'intern') {
        internCount += 1;
        internCapital += double.parse(ele['capital']);
        internProfit += double.parse(ele['profit']);
        internProfitability += double.parse(ele['profitability']);
      } else {
        externCount += 1;
        externCapital += double.parse(ele['capital']);
        externProfit += double.parse(ele['profit']);
        externProfitability += double.parse(ele['profitability']);
      }
    }
    totalCapital -= 1;

    units.sort((a, b) => a.name.compareTo(b.name));

    setState(() => isLoadingUnits = false);
  }

  void onSort() {
    switch (_sortColumnIndex) {
      case 0:
        units.sort((a, b) => _isAscending ? a.name.compareTo(b.name) : b.name.compareTo(a.name));
        break;
      case 1:
        units.sort((a, b) => _isAscending ? a.type.compareTo(b.type) : b.type.compareTo(a.type));
        break;
      case 2:
        units.sort((a, b) => _isAscending ? a.capital.compareTo(b.capital) : b.capital.compareTo(a.capital));
        break;
      case 3:
        units.sort((a, b) => _isAscending ? a.capital.compareTo(b.capital) : b.capital.compareTo(a.capital));
        break;
      case 4:
        units.sort((a, b) => _isAscending ? a.profit.compareTo(b.profit) : b.profit.compareTo(a.profit));
        break;
      case 5:
        units.sort((a, b) =>
            _isAscending ? a.profitability.compareTo(b.profitability) : b.profitability.compareTo(a.profitability));
        break;
    }
  }

  void resetInterUnits() async {
    var res = await sqlQuery(selectUrl,
        {'sql1': '''SELECT SUM(profitability) AS totalInternProfitability FROM units WHERE type = 'intern';'''});

    var data = res[0][0];
    double totalInternProfitability = double.parse(data['totalInternProfitability']);

    List<String> sqls = [];

    sqls.add('''UPDATE units SET profit=0,profitability=0,currentMonthOrYear=1 WHERE type = 'intern';''');
    sqls.add('UPDATE users SET money=0,threshold=0,founding=0,effort=0;');
    sqls.add('''DELETE FROM unithistory WHERE year = $currentYear AND month != 0;''');
    sqls.add(
        'UPDATE settings SET profitability= profitability - $totalInternProfitability,reserveProfitIntern=0,donationProfitIntern=0;');

    await sqlQuery(insertUrl, {for (var sql in sqls) 'sql${sqls.indexOf(sql) + 1}': sql});
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MyApp(index: 'un')));
    snackBar(context, 'Reset Intern Units Done successfully');
  }

  @override
  void initState() {
    loadUnits();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    onSort();

    List<DataColumn> columns = [
      ...[
        'Name',
        'Type',
        'Capital',
        'Capital %',
        'Profit',
        'Profitability',
      ]
          .map((e) => sortableDataColumn(
                context,
                e,
                (columnIndex, ascending) => setState(() {
                  _sortColumnIndex = columnIndex;
                  _isAscending = ascending;
                }),
              ))
          .toList(),
      dataColumn(context, 'Month'),
      if (isAdmin)
        DataColumn(
          label: myIconButton(
            icon: Icons.refresh,
            color: primaryColor,
            onPressed: () async {
              await createDialog(
                context,
                dismissable: true,
                StatefulBuilder(
                  builder: (context, setState) => Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: scaffoldColor,
                      border: Border.all(width: 2.0),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Reset Intern Units',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(width: getWidth(context, .16), child: const Divider()),
                        mySizedBox(context),
                        myButton(
                          context,
                          noIcon: true,
                          text: 'Reset',
                          isLoading: isResetting,
                          onTap: () {
                            setState(() => isResetting = true);
                            resetInterUnits();
                          },
                        )
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
    ];

    List<DataRow> rows = units
        .map((unit) => DataRow(
              onSelectChanged: ((value) => isAdmin ? _newUnit(context, unit) : null),
              cells: [
                dataCell(context, unit.name, textAlign: TextAlign.start),
                dataCell(context, getText(unitsTypes, unit.type), textAlign: TextAlign.start),
                dataCell(context, myCurrency(unit.capital), textAlign: TextAlign.end),
                dataCell(context, myPercentage(unit.capital * 100 / totalCapital)),
                dataCell(context, myCurrency(unit.profit), textAlign: TextAlign.end),
                dataCell(context, myPercentage(unit.profitability * 100)),
                ...[
                  unit.type == 'extern'
                      ? unit.currentMonthOrYear
                      : unit.currentMonthOrYear == 13
                          ? zero
                          : monthsOfYear[unit.currentMonthOrYear - 1],
                ].map((e) => dataCell(context, e.toString())).toList(),
                if (isAdmin)
                  DataCell(
                    unit.currentMonthOrYear == 13
                        ? Center(child: Icon(Icons.done, size: defaultIconSize))
                        : myIconButton(
                            onPressed: () => createDialog(context, Calculation(unit: unit), dismissable: false),
                            icon: Icons.play_arrow,
                            color: secondaryColor),
                  ),
              ],
            ))
        .toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              mini: true,
              onPressed: () => _newUnit(context, Unit()),
              tooltip: 'New Unit',
              child: const Icon(Icons.add),
            )
          : null,
      body: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0),
        padding: const EdgeInsets.all(16.0),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.grey, blurRadius: 3.0),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              child: isLoadingUnits
                  ? myProgress()
                  : units.isEmpty
                      ? SizedBox(width: getWidth(context, .60), child: emptyList())
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
                        ),
            ),
            mySizedBox(context),
            SizedBox(width: getWidth(context, .52), child: const Divider()),
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      children: [
                        myText('Intern'),
                        const SizedBox(width: 40, child: Divider()),
                        totalItem(context, 'Count', internCount.toString()),
                        totalItem(context, 'Capital', myCurrency(internCapital)),
                        totalItem(context, 'Capital %', myPercentage(internCapital * 100 / totalCapital)),
                        totalItem(context, 'Profit', myCurrency(internProfit)),
                        totalItem(context, 'Profitability', myPercentage(internProfitability)),
                      ],
                    ),
                    SizedBox(height: getHeight(context, .125), child: const VerticalDivider(width: 50)),
                    Column(
                      children: [
                        myText('Extern'),
                        const SizedBox(width: 40, child: Divider()),
                        totalItem(context, 'Count', externCount.toString()),
                        totalItem(context, 'Capital', myCurrency(externCapital)),
                        totalItem(context, 'Capital %', myPercentage(externCapital * 100 / totalCapital)),
                        totalItem(context, 'Profit', myCurrency(externProfit)),
                        totalItem(context, 'Profitability', myPercentage(externProfitability)),
                      ],
                    ),
                  ],
                ),
                SizedBox(width: getWidth(context, .4), child: const Divider()),
                totalItem(context, 'Total Capital', myCurrency(totalCapital)),
              ],
            )
          ],
        ),
      ),
    );
  }
}
