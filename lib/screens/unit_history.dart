import 'dart:collection';

import 'package:flutter/material.dart';

import '../shared/functions.dart';
import '../shared/lists.dart';
import '../models/unit_history.dart';
import '../shared/constants.dart';
import '../shared/widgets.dart';

class UnitHistoryScreen extends StatefulWidget {
  const UnitHistoryScreen({Key? key}) : super(key: key);

  @override
  State<UnitHistoryScreen> createState() => _UnitHistoryScreenState();
}

class _UnitHistoryScreenState extends State<UnitHistoryScreen> {
  List<UnitHistory> allUnitsHistroy = [], unitsHistory = [];
  var names = <String>{};

  bool isloading = true;
  String _name = 'tout';
  String _year = 'tout';

  int? _sortColumnIndex = 1;
  bool _isAscending = true;
  final ScrollController _controllerH = ScrollController(), _controllerV = ScrollController();

  void loadData() async {
    var res = await sqlQuery(selectUrl, {'sql1': 'SELECT * FROM UnitHistory;'});
    var data = res[0];

    for (var ele in data) {
      allUnitsHistroy.add(UnitHistory(
          name: ele['name'],
          year: int.parse(ele['year']),
          type: ele['type'],
          capital: double.parse(ele['capital']),
          profit: double.parse(ele['profit']),
          profitability: double.parse(ele['profitability'])));

      names.add(ele['name']);
    }

    names = SplayTreeSet.from(names);

    setState(() {
      isloading = false;
    });
  }

  void filterHistory() {
    unitsHistory.clear();
    for (var unitHistory in allUnitsHistroy) {
      if ((_name == 'tout' || unitHistory.name == _name) && (_year == 'tout' || unitHistory.year.toString() == _year)) {
        unitsHistory.add(unitHistory);
      }
    }
    onSort();
  }

  void onSort() {
    switch (_sortColumnIndex) {
      case 1:
        unitsHistory.sort((tr1, tr2) => !_isAscending ? tr2.name.compareTo(tr1.name) : tr1.name.compareTo(tr2.name));
        break;
      case 2:
        unitsHistory.sort((tr1, tr2) => !_isAscending ? tr2.year.compareTo(tr1.year) : tr1.year.compareTo(tr2.year));
        break;
      case 3:
        unitsHistory.sort((tr1, tr2) => !_isAscending ? tr2.type.compareTo(tr1.type) : tr1.type.compareTo(tr2.type));
        break;
      case 4:
        unitsHistory.sort(
            (tr1, tr2) => !_isAscending ? tr2.capital.compareTo(tr1.capital) : tr1.capital.compareTo(tr2.capital));
        break;
      case 5:
        unitsHistory
            .sort((tr1, tr2) => !_isAscending ? tr2.profit.compareTo(tr1.profit) : tr1.profit.compareTo(tr2.profit));
        break;
      case 6:
        unitsHistory.sort((tr1, tr2) => !_isAscending
            ? tr2.profitability.compareTo(tr1.profitability)
            : tr1.profitability.compareTo(tr2.profitability));
        break;
    }
  }

  @override
  void initState() {
    loadData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    filterHistory();

    List<DataColumn> columns = [
      dataColumn(context, ''),
      ...[
        getText('name'),
        getText('year'),
        getText('type'),
        getText('capital'),
        getText('profit'),
        getText('profitability'),
      ]
          .map((e) => sortableDataColumn(
                context,
                e,
                (columnIndex, ascending) => setState(() {
                  _sortColumnIndex = columnIndex;
                  _isAscending = ascending;
                }),
              ))
          .toList()
    ];

    List<DataRow> rows = unitsHistory
        .map(
          (unitHistory) => DataRow(
            cells: [
              dataCell(context, (unitsHistory.indexOf(unitHistory) + 1).toString()),
              dataCell(context, unitHistory.name, textAlign: TextAlign.start),
              dataCell(context, unitHistory.year.toString()),
              dataCell(context, getText(unitHistory.type)),
              ...[
                myCurrency(unitHistory.capital),
                myCurrency(unitHistory.profit),
              ].map((e) => dataCell(context, e, textAlign: TextAlign.end)).toList(),
              dataCell(context, myPercentage(unitHistory.profitability * 100)),
            ],
          ),
        )
        .toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
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
            SizedBox(width: getWidth(context, .19), child: const Divider()),
            const SizedBox(width: double.minPositive, height: 8.0),
            Expanded(
                child: isloading
                    ? myProgress()
                    : unitsHistory.isEmpty
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
                          )),
            mySizedBox(context),
            SizedBox(width: getWidth(context, .52), child: const Divider()),
            mySizedBox(context),
            const Row(),
          ],
        ),
      ),
    );
  }

  Widget searchBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text(
                  getText('name'),
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              myDropDown(
                context,
                value: _name,
                width: getWidth(context, .16),
                color: _name == 'tout' ? Colors.grey : primaryColor,
                items: [constans['tout'] ?? '', ...names].map((item) {
                  return DropdownMenuItem(
                    value: item == constans['tout'] ? 'tout' : item,
                    alignment: AlignmentDirectional.center,
                    child: Text(item),
                  );
                }).toList(),
                onChanged: (value) => setState(() {
                  _name = value.toString();
                }),
              )
            ],
          ),
          const SizedBox(width: 8.0),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text(
                  getText('year'),
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              myDropDown(
                context,
                value: _year,
                color: _year == 'tout' ? Colors.grey : primaryColor,
                items: [constans['tout'] ?? '', ...years].map((item) {
                  return DropdownMenuItem(
                    value: item == constans['tout'] ? 'tout' : item,
                    alignment: AlignmentDirectional.center,
                    child: Text(item),
                  );
                }).toList(),
                onChanged: (value) => setState(() {
                  _year = value.toString();
                }),
              )
            ],
          ),
          mySizedBox(context),
          IconButton(
              onPressed: () => createExcel(
                    getText('unitHistory'),
                    [
                      [
                        '#',
                        getText('name'),
                        getText('year'),
                        getText('type'),
                        getText('capital'),
                        getText('profit'),
                        getText('profitability'),
                      ],
                      ...unitsHistory.map((unit) => [
                            unitsHistory.indexOf(unit) + 1,
                            unit.name,
                            unit.year,
                            unit.type,
                            unit.capital,
                            unit.profit,
                            (unit.profitability * 100).toStringAsFixed(2),
                          ])
                    ],
                  ),
              icon: Icon(
                Icons.file_download,
                color: primaryColor,
              )),
          (_name != 'tout' || _year != 'tout')
              ? IconButton(
                  onPressed: () => setState(() {
                    _name = 'tout';
                    _year = 'tout';
                  }),
                  icon: Icon(
                    Icons.update,
                    color: primaryColor,
                  ),
                )
              : const SizedBox(),
        ],
      ),
    );
  }
}
