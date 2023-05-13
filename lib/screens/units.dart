import 'package:fairsplit/screens/new_calculation.dart';
import 'package:flutter/material.dart';

import '../models/unit.dart';
import '../shared/lists.dart';
import '../shared/parameters.dart';
import '../widgets/widget.dart';
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

  void _newUnit(BuildContext context, Unit unit) async => await createDialog(context, AddUnit(unit: unit), false);

  void loadUnits() async {
    var res = await sqlQuery(selectUrl, {'sql1': 'SELECT * FROM Units;'});
    var dataUnits = res[0];
    for (var ele in dataUnits) {
      units.add(Unit(
        unitId: int.parse(ele['unitId']),
        name: ele['name'],
        type: ele['type'],
        capital: double.parse(ele['capital']),
        reservePerc: double.parse(ele['reservePerc']),
        donationPerc: double.parse(ele['donationPerc']),
        moneyPerc: double.parse(ele['moneyPerc']),
        effortPerc: double.parse(ele['effortPerc']),
        thresholdFoundingPerc: double.parse(ele['thresholdFoundingPerc']),
        thresholdPerc: double.parse(ele['thresholdPerc']),
        foundingPerc: double.parse(ele['foundingPerc']),
        calculated: ele['calculated'] == '1',
        currentMonth: int.parse(ele['currentMonth']),
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
        units.sort(
            (a, b) => _isAscending ? a.reservePerc.compareTo(b.reservePerc) : b.reservePerc.compareTo(a.reservePerc));
        break;
      case 5:
        units.sort((a, b) =>
            _isAscending ? a.donationPerc.compareTo(b.donationPerc) : b.donationPerc.compareTo(a.donationPerc));
        break;
      case 6:
        units.sort((a, b) => _isAscending ? a.moneyPerc.compareTo(b.moneyPerc) : b.moneyPerc.compareTo(a.moneyPerc));
        break;
      case 7:
        units
            .sort((a, b) => _isAscending ? a.effortPerc.compareTo(b.effortPerc) : b.effortPerc.compareTo(a.effortPerc));
        break;
      case 8:
        units.sort((a, b) => _isAscending
            ? a.thresholdFoundingPerc.compareTo(b.thresholdFoundingPerc)
            : b.thresholdFoundingPerc.compareTo(a.thresholdFoundingPerc));
        break;
      case 9:
        units.sort((a, b) =>
            _isAscending ? a.thresholdPerc.compareTo(b.thresholdPerc) : b.thresholdPerc.compareTo(a.thresholdPerc));
        break;
      case 10:
        units.sort((a, b) =>
            _isAscending ? a.foundingPerc.compareTo(b.foundingPerc) : b.foundingPerc.compareTo(a.foundingPerc));
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
        '${getText('reserve')} %',
        '${getText('donation')} %',
        '${getText('money')} %',
        '${getText('effort')} %',
        '${getText('thresholdFounding')} %',
        '${getText('threshold')} %',
        '${getText('founding')} %',
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
      dataColumn(context, ''),
    ];

    List<DataRow> rows = units
        .map((unit) => DataRow(onSelectChanged: ((value) => _newUnit(context, unit)), cells: [
              dataCell(context, unit.name, textAlign: TextAlign.start),
              dataCell(context, getText(unit.type), textAlign: TextAlign.start),
              ...[
                myCurrency.format(unit.capital),
                (unit.capital * 100 / totalCapital).toStringAsFixed(2),
                unit.reservePerc,
                unit.donationPerc,
                unit.moneyPerc,
                unit.effortPerc,
                unit.thresholdFoundingPerc,
                unit.thresholdPerc,
                unit.foundingPerc,
                unit.type == 'extern' ? '/' : monthsOfYear[unit.currentMonth - 1],
              ].map((e) => dataCell(context, e.toString())).toList(),
              DataCell(
                unit.calculated
                    ? const Center(child: Icon(Icons.done))
                    : IconButton(
                        onPressed: () => createDialog(context, NewCalculation(unit: unit), false),
                        hoverColor: Colors.transparent,
                        icon: Icon(Icons.play_arrow, color: secondaryColor)),
              ),
            ]))
        .toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        mini: true,
        onPressed: () => _newUnit(context, Unit()),
        tooltip: getText('newUnit'),
        child: const Icon(Icons.add),
      ),
      body: Row(
        children: [
          const Spacer(),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16.0),
            padding: const EdgeInsets.all(16.0),
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
                Expanded(
                  flex: 5,
                  child: isLoadingUnits
                      ? myPogress()
                      : SingleChildScrollView(
                          child: units.isEmpty
                              ? emptyList()
                              : dataTable(
                                  isAscending: _isAscending,
                                  sortColumnIndex: _sortColumnIndex,
                                  columns: columns,
                                  rows: rows,
                                ),
                        ),
                ),
                const SizedBox(height: 8.0),
                SizedBox(width: getWidth(context, .52), child: const Divider()),
                const SizedBox(height: 8.0),
                Column(
                  children: [
                    Row(
                      children: [
                        Column(
                          children: [
                            myText(getText('intern')),
                            const SizedBox(width: 40, child: Divider()),
                            const SizedBox(height: 8.0),
                            totalItem(getText('count'), internCount.toString()),
                            totalItem(
                                getText('percentage'), '${(internCapital * 100 / totalCapital).toStringAsFixed(2)} %'),
                            totalItem(getText('capital'), myCurrency.format(internCapital)),
                          ],
                        ),
                        SizedBox(height: getHeight(context, .125), child: const VerticalDivider(width: 50)),
                        Column(
                          children: [
                            myText(getText('extern')),
                            const SizedBox(width: 40, child: Divider()),
                            const SizedBox(height: 8.0),
                            totalItem(getText('count'), externCount.toString()),
                            totalItem(
                                getText('percentage'), '${(externCapital * 100 / totalCapital).toStringAsFixed(2)} %'),
                            totalItem(getText('capital'), myCurrency.format(externCapital)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8.0),
                    SizedBox(width: getWidth(context, .4), child: const Divider()),
                    myText('${getText('totalCapital')}            :            ${myCurrency.format(totalCapital)}'),
                    const SizedBox(height: 8.0),
                  ],
                )
              ],
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget totalItem(String title, String value) {
    return SizedBox(
      width: getWidth(context, .2),
      child: Row(
        children: [
          Expanded(child: myText(title)),
          Expanded(flex: 2, child: myText(':            $value')),
        ],
      ),
    );
  }
}
