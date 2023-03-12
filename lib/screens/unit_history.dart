import 'dart:collection';

import 'package:flutter/material.dart';

import '../shared/lists.dart';
import '../models/unit_history.dart';
import '../shared/parameters.dart';
import '../widgets/widget.dart';

class UnitHistoryScreen extends StatefulWidget {
  const UnitHistoryScreen({Key? key}) : super(key: key);

  @override
  State<UnitHistoryScreen> createState() => _UnitHistoryScreenState();
}

class _UnitHistoryScreenState extends State<UnitHistoryScreen> {
  List<UnitHistory> allUnitsHistroy = [], unitsHistory = [];
  var names = <String>{};
  var years = <String>{};

  bool isloading = true;
  String _name = 'tout';
  String _year = 'tout';

  int? _sortColumnIndex = 2;
  bool _isAscending = false;

  void loadData() async {
    var res = await sqlQuery(selectUrl, {'sql1': 'SELECT * FROM UnitHistory;'});
    var data = res[0];

    for (var ele in data) {
      allUnitsHistroy.add(UnitHistory(
          name: ele['name'],
          year: int.parse(ele['year']),
          rawProfit: double.parse(ele['rawProfit']),
          reserve: double.parse(ele['reserve']),
          donation: double.parse(ele['donation']),
          netProfit: double.parse(ele['netProfit']),
          thresholdFounding: double.parse(ele['thresholdFounding']),
          threshold: double.parse(ele['threshold']),
          founding: double.parse(ele['founding']),
          effort: double.parse(ele['effort']),
          money: double.parse(ele['money']),
          capital: double.parse(ele['capital']),
          profitability: double.parse(ele['profitability'])));

      names.add(ele['name']);
      years.add(ele['year']);
    }

    names = SplayTreeSet.from(names);
    years = SplayTreeSet.from(years, (a, b) => b.compareTo(a));

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
        unitsHistory.sort((tr1, tr2) {
          return !_isAscending ? tr2.name.compareTo(tr1.name) : tr1.name.compareTo(tr2.name);
        });
        break;
      case 2:
        unitsHistory.sort((tr1, tr2) {
          return !_isAscending ? tr2.year.compareTo(tr1.year) : tr1.year.compareTo(tr2.year);
        });
        break;
      case 3:
        unitsHistory.sort((tr1, tr2) {
          return !_isAscending ? tr2.rawProfit.compareTo(tr1.rawProfit) : tr1.rawProfit.compareTo(tr2.rawProfit);
        });
        break;
      case 4:
        unitsHistory.sort((tr1, tr2) {
          return !_isAscending ? tr2.reserve.compareTo(tr1.reserve) : tr1.reserve.compareTo(tr2.reserve);
        });
        break;
      case 5:
        unitsHistory.sort((tr1, tr2) {
          return !_isAscending ? tr2.donation.compareTo(tr1.donation) : tr1.donation.compareTo(tr2.donation);
        });
        break;
      case 6:
        unitsHistory.sort((tr1, tr2) {
          return !_isAscending ? tr2.netProfit.compareTo(tr1.netProfit) : tr1.netProfit.compareTo(tr2.netProfit);
        });
        break;
      case 7:
        unitsHistory.sort((tr1, tr2) {
          return !_isAscending
              ? tr2.thresholdFounding.compareTo(tr1.thresholdFounding)
              : tr1.thresholdFounding.compareTo(tr2.thresholdFounding);
        });
        break;
      case 8:
        unitsHistory.sort((tr1, tr2) {
          return !_isAscending ? tr2.threshold.compareTo(tr1.threshold) : tr1.threshold.compareTo(tr2.threshold);
        });
        break;
      case 9:
        unitsHistory.sort((tr1, tr2) {
          return !_isAscending ? tr2.founding.compareTo(tr1.founding) : tr1.founding.compareTo(tr2.founding);
        });
        break;
      case 10:
        unitsHistory.sort((tr1, tr2) {
          return !_isAscending ? tr2.effort.compareTo(tr1.effort) : tr1.effort.compareTo(tr2.effort);
        });
        break;
      case 11:
        unitsHistory.sort((tr1, tr2) {
          return !_isAscending ? tr2.money.compareTo(tr1.money) : tr1.money.compareTo(tr2.money);
        });
        break;
      case 12:
        unitsHistory.sort((tr1, tr2) {
          return !_isAscending ? tr2.capital.compareTo(tr1.capital) : tr1.capital.compareTo(tr2.capital);
        });
        break;
      case 13:
        unitsHistory.sort((tr1, tr2) {
          return !_isAscending
              ? tr2.profitability.compareTo(tr1.profitability)
              : tr1.profitability.compareTo(tr2.profitability);
        });
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
        getText('rawProfit'),
        getText('reserve'),
        getText('donation'),
        getText('netProfit'),
        getText('thresholdFounding'),
        getText('threshold'),
        getText('founding'),
        getText('effort'),
        getText('money'),
        getText('capital'),
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
          .toList()
    ];

    List<DataRow> rows = unitsHistory
        .map(
          (unitHistory) => DataRow(
            cells: [
              dataCell(context, (unitsHistory.indexOf(unitHistory) + 1).toString()),
              dataCell(context, unitHistory.name, textAlign: TextAlign.start),
              ...[
                unitHistory.year.toString(),
                myCurrency.format(unitHistory.rawProfit),
                myCurrency.format(unitHistory.reserve),
                myCurrency.format(unitHistory.donation),
                myCurrency.format(unitHistory.netProfit),
                myCurrency.format(unitHistory.thresholdFounding),
                myCurrency.format(unitHistory.threshold),
                myCurrency.format(unitHistory.founding),
                myCurrency.format(unitHistory.effort),
                myCurrency.format(unitHistory.money),
                myCurrency.format(unitHistory.capital),
              ].map((e) => dataCell(context, e, textAlign: TextAlign.end)).toList(),
              dataCell(context, unitHistory.profitability.toString()),
            ],
          ),
        )
        .toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Row(
        children: [
          const Spacer(),
          Container(
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
                      ? myPogress()
                      : unitsHistory.isEmpty
                          ? SizedBox(width: getWidth(context, .45), child: emptyList())
                          : SingleChildScrollView(
                              child: dataTable(
                                isAscending: _isAscending,
                                sortColumnIndex: _sortColumnIndex,
                                columns: columns,
                                rows: rows,
                              ),
                            ),
                ),
              ],
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget searchBar() {
    return Row(
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
              color: _name == 'tout' ? Colors.grey : winTileColor,
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
              color: _year == 'tout' ? Colors.grey : winTileColor,
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
        const SizedBox(width: 8.0),
        (_name != 'tout' || _year != 'tout')
            ? IconButton(
                onPressed: () => setState(() {
                  _name = 'tout';
                  _year = 'tout';
                }),
                icon: Icon(
                  Icons.update,
                  color: winTileColor,
                ),
              )
            : const SizedBox(),
      ],
    );
  }
}
