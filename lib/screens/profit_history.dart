import 'dart:collection';

import 'package:fairsplit/models/profit.dart';
import 'package:flutter/material.dart';

import '../shared/lists.dart';
import '../shared/constants.dart';
import '../shared/widgets.dart';

class ProfitHistory extends StatefulWidget {
  const ProfitHistory({super.key});

  @override
  State<ProfitHistory> createState() => _ProfitHistoryState();
}

class _ProfitHistoryState extends State<ProfitHistory> {
  List<Profit> allProfitsHistroy = [], profitsHistory = [];
  var years = <String>{};
  var names = <String>{};
  bool isloading = true;
  String _name = 'tout';
  String _year = 'tout';
  String _month = 'tout';
  String _type = 'tout';
  int? _sortColumnIndex = 3;
  bool _isAscending = false;

  void loadData() async {
    var res = await sqlQuery(selectUrl, {'sql1': 'SELECT * FROM ProfitHistory;'});
    var data = res[0];

    for (var ele in data) {
      allProfitsHistroy.add(Profit(
        profitId: int.parse(ele['profitId']),
        name: ele['name'],
        year: int.parse(ele['year']),
        month: int.parse(ele['month']),
        profit: double.parse(ele['profit']),
        profitability: double.parse(ele['profitability']),
        reserve: double.parse(ele['reserve']),
        donation: double.parse(ele['donation']),
        threshold: double.parse(ele['threshold']),
        founding: double.parse(ele['founding']),
        effort: double.parse(ele['effort']),
        money: double.parse(ele['money']),
      ));

      names.add(ele['name']);
      years.add(ele['year']);
    }

    names = SplayTreeSet.from(names);
    years = SplayTreeSet.from(years, (a, b) => b.compareTo(a));

    setState(() => isloading = false);
  }

  void filterHistory() {
    profitsHistory.clear();
    for (var profit in allProfitsHistroy) {
      if ((_name == 'tout' || profit.name == _name) &&
          (_type == 'tout' || profit.type == _type) &&
          (_year == 'tout' || profit.year.toString() == _year) &&
          (_month == 'tout' || profit.month == monthsOfYear.indexOf(_month) + 1)) {
        profitsHistory.add(profit);
      }
    }
    onSort();
  }

  void onSort() {
    switch (_sortColumnIndex) {
      case 1:
        profitsHistory.sort((tr1, tr2) => !_isAscending ? tr2.name.compareTo(tr1.name) : tr1.name.compareTo(tr2.name));
        break;
      case 3:
        profitsHistory.sort((tr1, tr2) {
          int yearComp = !_isAscending ? tr2.year.compareTo(tr1.year) : tr1.year.compareTo(tr2.year);
          if (yearComp == 0) return !_isAscending ? tr2.month.compareTo(tr1.month) : tr1.month.compareTo(tr2.month);
          return yearComp;
        });
        break;
      case 5:
        profitsHistory
            .sort((tr1, tr2) => !_isAscending ? tr2.profit.compareTo(tr1.profit) : tr1.profit.compareTo(tr2.profit));
        break;
      case 6:
        profitsHistory.sort((tr1, tr2) => !_isAscending
            ? tr2.profitability.compareTo(tr1.profitability)
            : tr1.profitability.compareTo(tr2.profitability));
        break;
      case 7:
        profitsHistory.sort(
            (tr1, tr2) => !_isAscending ? tr2.reserve.compareTo(tr1.reserve) : tr1.reserve.compareTo(tr2.reserve));
        break;
      case 8:
        profitsHistory.sort(
            (tr1, tr2) => !_isAscending ? tr2.donation.compareTo(tr1.donation) : tr1.donation.compareTo(tr2.donation));
        break;
      case 9:
        profitsHistory
            .sort((tr1, tr2) => !_isAscending ? tr2.money.compareTo(tr1.money) : tr1.money.compareTo(tr2.money));
        break;
      case 10:
        profitsHistory
            .sort((tr1, tr2) => !_isAscending ? tr2.effort.compareTo(tr1.effort) : tr1.effort.compareTo(tr2.effort));
        break;
      case 11:
        profitsHistory.sort((tr1, tr2) =>
            !_isAscending ? tr2.threshold.compareTo(tr1.threshold) : tr1.threshold.compareTo(tr2.threshold));
        break;
      case 12:
        profitsHistory.sort(
            (tr1, tr2) => !_isAscending ? tr2.founding.compareTo(tr1.founding) : tr1.founding.compareTo(tr2.founding));
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
      sortableDataColumn(
        context,
        getText('name'),
        (columnIndex, ascending) => setState(() {
          _sortColumnIndex = columnIndex;
          _isAscending = ascending;
        }),
      ),
      dataColumn(context, getText('type')),
      sortableDataColumn(
        context,
        getText('year'),
        (columnIndex, ascending) => setState(() {
          _sortColumnIndex = columnIndex;
          _isAscending = ascending;
        }),
      ),
      dataColumn(context, getText('month')),
      ...[
        getText('profit'),
        '${getText('profitability')} %',
        getText('reserve'),
        getText('donation'),
        getText('money'),
        getText('effort'),
        getText('threshold'),
        getText('founding'),
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

    List<DataRow> rows = profitsHistory
        .map(
          (profit) => DataRow(
            cells: [
              dataCell(context, (profitsHistory.indexOf(profit) + 1).toString()),
              dataCell(context, profit.name, textAlign: TextAlign.start),
              dataCell(context, getText(profit.type)),
              dataCell(context, profit.year.toString()),
              dataCell(
                context,
                profit.month == 0 ? '/' : monthsOfYear.elementAt(profit.month - 1),
              ),
              dataCell(context, myCurrency.format(profit.profit), textAlign: TextAlign.end),
              dataCell(context, (profit.profitability * 100).toStringAsFixed(2)),
              ...[
                myCurrency.format(profit.reserve),
                myCurrency.format(profit.donation),
                myCurrency.format(profit.money),
                myCurrency.format(profit.effort),
                myCurrency.format(profit.threshold),
                myCurrency.format(profit.founding),
              ].map((e) => dataCell(context, e, textAlign: TextAlign.end)).toList(),
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
                      ? myProgress()
                      : profitsHistory.isEmpty
                          ? SizedBox(width: getWidth(context, .60), child: emptyList())
                          : SingleChildScrollView(
                              child: dataTable(
                                isAscending: _isAscending,
                                sortColumnIndex: _sortColumnIndex,
                                columnSpacing: 30,
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
              color: _name == 'tout' ? Colors.grey : primaryColor,
              items: [constans['tout'] ?? '', ...names].map((item) {
                return DropdownMenuItem(
                  value: item == constans['tout'] ? 'tout' : item,
                  alignment: AlignmentDirectional.center,
                  child: Text(item),
                );
              }).toList(),
              onChanged: (value) => setState(() => _name = value.toString()),
            )
          ],
        ),
        mySizedBox(context),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text(
                getText('type'),
                style: const TextStyle(fontSize: 14),
              ),
            ),
            myDropDown(
              context,
              value: _type,
              color: _type == 'tout' ? Colors.grey : primaryColor,
              items: unitsTypesSearch.entries.map((item) {
                return DropdownMenuItem(
                  value: getKeyFromValue(item.value),
                  alignment: AlignmentDirectional.center,
                  child: Text(item.value),
                );
              }).toList(),
              onChanged: (value) => setState(() => _type = value.toString()),
            ),
          ],
        ),
        mySizedBox(context),
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
              onChanged: (value) => setState(() => _year = value.toString()),
            )
          ],
        ),
        mySizedBox(context),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text(
                getText('month'),
                style: const TextStyle(fontSize: 14),
              ),
            ),
            myDropDown(
              context,
              value: _month,
              color: _month == 'tout' ? Colors.grey : primaryColor,
              items: [constans['tout'] ?? '', ...monthsOfYear].map((item) {
                return DropdownMenuItem(
                  value: item == constans['tout'] ? 'tout' : item,
                  alignment: AlignmentDirectional.center,
                  child: Text(item),
                );
              }).toList(),
              onChanged: (value) => setState(() => _month = value.toString()),
            )
          ],
        ),
        mySizedBox(context),
        (_name != 'tout' || _year != 'tout' || _month != 'tout' || _type != 'tout')
            ? IconButton(
                onPressed: () => setState(() {
                  _name = 'tout';
                  _year = 'tout';
                  _month = 'tout';
                  _type = 'tout';
                }),
                icon: Icon(
                  Icons.update,
                  color: primaryColor,
                ),
              )
            : const SizedBox(),
      ],
    );
  }
}
