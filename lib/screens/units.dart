import 'package:fairsplit/screens/calculation.dart';
import 'package:flutter/material.dart';

import '../models/unit.dart';
import '../shared/functions.dart';
import '../shared/lists.dart';
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
  double totalCapital = 0, internCapital = 0, externCapital = 0;
  int internCount = 0, externCount = 0;

  int? _sortColumnIndex = 0;
  bool _isAscending = true;
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
      } else {
        externCount += 1;
        externCapital += double.parse(ele['capital']);
      }
    }

    units.sort((a, b) => a.name.compareTo(b.name));

    setState(() {
      isLoadingUnits = false;
    });
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
        getText('name'),
        getText('type'),
        getText('capital'),
        '${getText('capital')} %',
        getText('profit'),
        '${getText('profitability')} %',
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
      dataColumn(context, getText('month')),
      if (isAdmin) dataColumn(context, ''),
    ];

    List<DataRow> rows = units
        .map((unit) => DataRow(
              onSelectChanged: ((value) => isAdmin ? _newUnit(context, unit) : null),
              cells: [
                dataCell(context, unit.name, textAlign: TextAlign.start),
                dataCell(context, getText(unit.type), textAlign: TextAlign.start),
                dataCell(context, myCurrency(unit.capital), textAlign: TextAlign.end),
                dataCell(context, (unit.capital * 100 / totalCapital).toStringAsFixed(2)),
                dataCell(context, myCurrency(unit.profit), textAlign: TextAlign.end),
                dataCell(context, (unit.profitability * 100).toStringAsFixed(2)),
                ...[
                  unit.type == 'extern'
                      ? unit.currentMonthOrYear
                      : unit.currentMonthOrYear == 13
                          ? '-'
                          : monthsOfYear[unit.currentMonthOrYear - 1],
                ].map((e) => dataCell(context, e.toString())).toList(),
                if (isAdmin)
                  DataCell(
                    unit.currentMonthOrYear == 13
                        ? const Center(child: Icon(Icons.done))
                        : IconButton(
                            onPressed: () => createDialog(context, Calculation(unit: unit), dismissable: false),
                            hoverColor: Colors.transparent,
                            icon: Icon(Icons.play_arrow, color: secondaryColor)),
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
              tooltip: getText('newUnit'),
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
            mySizedBox(context),
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      children: [
                        myText(getText('intern')),
                        const SizedBox(width: 40, child: Divider()),
                        mySizedBox(context),
                        totalItem(context, getText('count'), internCount.toString()),
                        totalItem(context, getText('percentage'),
                            '${(internCapital * 100 / totalCapital).toStringAsFixed(2)} %'),
                        totalItem(context, getText('capital'), myCurrency(internCapital)),
                      ],
                    ),
                    SizedBox(height: getHeight(context, .125), child: const VerticalDivider(width: 50)),
                    Column(
                      children: [
                        myText(getText('extern')),
                        const SizedBox(width: 40, child: Divider()),
                        mySizedBox(context),
                        totalItem(context, getText('count'), externCount.toString()),
                        totalItem(context, getText('percentage'),
                            '${(externCapital * 100 / totalCapital).toStringAsFixed(2)} %'),
                        totalItem(context, getText('capital'), myCurrency(externCapital)),
                      ],
                    ),
                  ],
                ),
                mySizedBox(context),
                SizedBox(width: getWidth(context, .4), child: const Divider()),
                myText('${getText('totalCapital')}            :            ${myCurrency(totalCapital)}'),
                mySizedBox(context),
              ],
            )
          ],
        ),
      ),
    );
  }
}
