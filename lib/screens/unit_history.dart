import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/unit_history.dart';
import '../shared/functions.dart';
import '../shared/constants.dart';
import '../shared/widgets.dart';

class UnitsHistory extends StatefulWidget {
  const UnitsHistory({super.key});

  @override
  State<UnitsHistory> createState() => _UnitsHistoryState();
}

class _UnitsHistoryState extends State<UnitsHistory> {
  List<UnitHistory> allUnitsHistroy = [], unitsHistory = [];
  var names = <String>{};
  bool isloading = true;
  String _name = 'tout';
  String _year = 'tout';
  String _month = 'tout';
  String _type = 'tout';
  int? _sortColumnIndex = 3;
  bool _isAscending = false;
  final ScrollController _controllerH = ScrollController(), _controllerV = ScrollController();

  double tprofit = 0,
      tprofitability = 0,
      tunitProfitability = 0,
      treserve = 0,
      tdonation = 0,
      tmoney = 0,
      teffort = 0,
      tthreshold = 0,
      tfounding = 0;

  void loadData() async {
    var res = await sqlQuery(selectUrl, {'sql1': 'SELECT * FROM unithistory;'});
    var data = res[0];

    for (var ele in data) {
      allUnitsHistroy.add(UnitHistory(
        profitId: int.parse(ele['profitId']),
        name: ele['name'],
        year: int.parse(ele['year']),
        month: int.parse(ele['month']),
        capital: double.parse(ele['capital']),
        profit: double.parse(ele['profit']),
        profitability: double.parse(ele['profitability']),
        unitProfitability: double.parse(ele['unitProfitability']),
        reserve: double.parse(ele['reserve']),
        donation: double.parse(ele['donation']),
        threshold: double.parse(ele['threshold']),
        founding: double.parse(ele['founding']),
        effort: double.parse(ele['effort']),
        money: double.parse(ele['money']),
      ));

      names.add(ele['name']);
    }

    names = SplayTreeSet.from(names);

    setState(() => isloading = false);
  }

  void filterHistory() {
    unitsHistory.clear();
    tprofit = 0;
    tprofitability = 0;
    tunitProfitability = 0;
    treserve = 0;
    tdonation = 0;
    tmoney = 0;
    teffort = 0;
    tthreshold = 0;
    tfounding = 0;
    for (var profit in allUnitsHistroy) {
      if ((_name == 'tout' || profit.name == _name) &&
          (_type == 'tout' || profit.type == _type) &&
          (_year == 'tout' || profit.year.toString() == _year) &&
          (_month == 'tout' || profit.month == monthsOfYear.indexOf(_month) + 1)) {
        unitsHistory.add(profit);

        tprofit += profit.profit;
        tprofitability += profit.profitability;
        tunitProfitability += profit.unitProfitability;
        treserve += profit.reserve;
        tdonation += profit.donation;
        tmoney += profit.money;
        teffort += profit.effort;
        tthreshold += profit.threshold;
        tfounding += profit.founding;
      }
    }
    onSort();
  }

  void onSort() {
    switch (_sortColumnIndex) {
      case 1:
        unitsHistory.sort((tr1, tr2) => !_isAscending ? tr2.name.compareTo(tr1.name) : tr1.name.compareTo(tr2.name));
        break;
      case 3:
        unitsHistory.sort((tr1, tr2) {
          int yearComp = !_isAscending ? tr2.year.compareTo(tr1.year) : tr1.year.compareTo(tr2.year);
          if (yearComp == 0) return !_isAscending ? tr2.month.compareTo(tr1.month) : tr1.month.compareTo(tr2.month);
          return yearComp;
        });
        break;
      case 5:
        unitsHistory.sort(
            (tr1, tr2) => !_isAscending ? tr2.capital.compareTo(tr1.capital) : tr1.capital.compareTo(tr2.capital));
        break;
      case 6:
        unitsHistory
            .sort((tr1, tr2) => !_isAscending ? tr2.profit.compareTo(tr1.profit) : tr1.profit.compareTo(tr2.profit));
        break;
      case 7:
        unitsHistory.sort((tr1, tr2) => !_isAscending
            ? tr2.profitability.compareTo(tr1.profitability)
            : tr1.profitability.compareTo(tr2.profitability));
        break;
      case 8:
        unitsHistory.sort((tr1, tr2) => !_isAscending
            ? tr2.unitProfitability.compareTo(tr1.unitProfitability)
            : tr1.unitProfitability.compareTo(tr2.unitProfitability));
        break;
      case 9:
        unitsHistory.sort(
            (tr1, tr2) => !_isAscending ? tr2.reserve.compareTo(tr1.reserve) : tr1.reserve.compareTo(tr2.reserve));
        break;
      case 10:
        unitsHistory.sort(
            (tr1, tr2) => !_isAscending ? tr2.donation.compareTo(tr1.donation) : tr1.donation.compareTo(tr2.donation));
        break;
      case 11:
        unitsHistory
            .sort((tr1, tr2) => !_isAscending ? tr2.money.compareTo(tr1.money) : tr1.money.compareTo(tr2.money));
        break;
      case 12:
        unitsHistory
            .sort((tr1, tr2) => !_isAscending ? tr2.effort.compareTo(tr1.effort) : tr1.effort.compareTo(tr2.effort));
        break;
      case 13:
        unitsHistory.sort((tr1, tr2) =>
            !_isAscending ? tr2.threshold.compareTo(tr1.threshold) : tr1.threshold.compareTo(tr2.threshold));
        break;
      case 14:
        unitsHistory.sort(
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
        'Name',
        (columnIndex, ascending) => setState(() {
          _sortColumnIndex = columnIndex;
          _isAscending = ascending;
        }),
      ),
      dataColumn(context, 'Type'),
      sortableDataColumn(
        context,
        'Year',
        (columnIndex, ascending) => setState(() {
          _sortColumnIndex = columnIndex;
          _isAscending = ascending;
        }),
      ),
      dataColumn(context, 'Month'),
      ...[
        'Capital',
        'Profit',
        'Profitability',
        'Unit Profitability',
        'Reserve',
        'Donation',
        'Money',
        'Effort',
        'Threshold',
        'Founding',
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
            onSelectChanged: (value) {},
            cells: [
              dataCell(context, (unitsHistory.indexOf(unitHistory) + 1).toString()),
              dataCell(context, unitHistory.name, textAlign: TextAlign.start),
              dataCell(context, getText(unitsTypes, unitHistory.type)),
              dataCell(context, unitHistory.year.toString()),
              dataCell(
                context,
                unitHistory.month == 0 ? '/' : monthsOfYear.elementAt(unitHistory.month - 1),
              ),
              dataCell(context, myCurrency(unitHistory.capital), textAlign: TextAlign.end),
              dataCell(context, myCurrency(unitHistory.profit), textAlign: TextAlign.end),
              dataCell(context, myPercentage(unitHistory.profitability * 100)),
              dataCell(context, myPercentage(unitHistory.unitProfitability * 100)),
              ...[
                myCurrency(unitHistory.reserve),
                myCurrency(unitHistory.donation),
                myCurrency(unitHistory.money),
                myCurrency(unitHistory.effort),
                myCurrency(unitHistory.threshold),
                myCurrency(unitHistory.founding),
              ].map((e) => dataCell(context, e, textAlign: TextAlign.end)).toList(),
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
                        ),
            ),
            SizedBox(width: getWidth(context, .52), child: const Divider()),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  children: [
                    totalItem(context, 'Profit', myCurrency(tprofit)),
                    totalItem(context, 'Profitability', myPercentage(tprofitability * 100)),
                    totalItem(context, 'Unit Profitability', myPercentage(tunitProfitability * 100)),
                  ],
                ),
                SizedBox(height: getHeight(context, .08), child: const VerticalDivider(width: 50)),
                Column(
                  children: [
                    totalItem(context, 'Money', myCurrency(tmoney)),
                    totalItem(context, 'Reserve', myCurrency(treserve)),
                    totalItem(context, 'Donation', myCurrency(tdonation)),
                  ],
                ),
                SizedBox(height: getHeight(context, .08), child: const VerticalDivider(width: 50)),
                Column(
                  children: [
                    totalItem(context, 'Effort', myCurrency(teffort)),
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
    Map<String, String> unitsTypesSearch = {
      'tout': 'Tout',
      'intern': 'Intern',
      'extern': 'Extern',
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
              myDropDown(
                context,
                value: _name,
                width: getWidth(context, .16),
                color: _name == 'tout' ? Colors.grey : primaryColor,
                items: ['Tout', ...names].map((item) {
                  return DropdownMenuItem(
                    value: item == 'Tout' ? 'tout' : item,
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
              const Padding(
                padding: EdgeInsets.only(left: 8.0),
                child: Text('Type', style: TextStyle(fontSize: 14)),
              ),
              myDropDown(
                context,
                value: _type,
                color: _type == 'tout' ? Colors.grey : primaryColor,
                items: unitsTypesSearch.entries.map((item) {
                  return DropdownMenuItem(
                    value: getKeyFromValue(unitsTypesSearch, item.value),
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
              const Padding(
                padding: EdgeInsets.only(left: 8.0),
                child: Text(
                  'Year',
                  style: TextStyle(fontSize: 14),
                ),
              ),
              myDropDown(
                context,
                value: _year,
                color: _year == 'tout' ? Colors.grey : primaryColor,
                items: ['Tout', ...years].map((item) {
                  return DropdownMenuItem(
                    value: item == 'Tout' ? 'tout' : item,
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
              const Padding(
                padding: EdgeInsets.only(left: 8.0),
                child: Text('Month', style: TextStyle(fontSize: 14)),
              ),
              myDropDown(
                context,
                value: _month,
                color: _month == 'tout' ? Colors.grey : primaryColor,
                items: ['Tout', ...monthsOfYear].map((item) {
                  return DropdownMenuItem(
                    value: item == 'Tout' ? 'tout' : item,
                    alignment: AlignmentDirectional.center,
                    child: Text(item),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _month = value.toString()),
              )
            ],
          ),
          mySizedBox(context),
          myIconButton(
            onPressed: () => createExcel(
              'Unit History',
              [
                [
                  '#',
                  'Name',
                  'Type',
                  'Year',
                  'Month',
                  'Capital',
                  'Profit',
                  'Profitability',
                  'Unit Profitability',
                  'Reserve',
                  'Donation',
                  'Money',
                  'Effort',
                  'Threshold',
                  'Founding',
                ],
                ...unitsHistory.map((unitHistory) => [
                      unitsHistory.indexOf(unitHistory) + 1,
                      unitHistory.name,
                      getText(unitsTypes, unitHistory.type),
                      unitHistory.year,
                      unitHistory.month == 0 ? '/' : monthsOfYear.elementAt(unitHistory.month - 1),
                      unitHistory.capital,
                      unitHistory.profit,
                      myPercentage(unitHistory.profitability * 100),
                      myPercentage(unitHistory.unitProfitability * 100),
                      unitHistory.reserve,
                      unitHistory.donation,
                      unitHistory.money,
                      unitHistory.effort,
                      unitHistory.threshold,
                      unitHistory.founding,
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
          if (_name != 'tout' || _year != 'tout' || _month != 'tout' || _type != 'tout')
            myIconButton(
              onPressed: () => setState(() {
                _name = 'tout';
                _year = 'tout';
                _month = 'tout';
                _type = 'tout';
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
            'Year',
            'Month',
            'Capital',
            'Profit',
            'Profitability',
            'Unit Profitability',
            'Reserve',
            'Donation',
            'Money',
            'Effort',
            'Threshold',
            'Founding',
          ],
          data: unitsHistory
              .map((unitHistory) => [
                    unitHistory.name,
                    getText(unitsTypes, unitHistory.type),
                    unitHistory.year,
                    unitHistory.month == 0 ? '/' : monthsOfYear.elementAt(unitHistory.month - 1),
                    myCurrency(unitHistory.capital),
                    myCurrency(unitHistory.profit),
                    myPercentage(unitHistory.profitability * 100),
                    myPercentage(unitHistory.unitProfitability * 100),
                    myCurrency(unitHistory.reserve),
                    myCurrency(unitHistory.donation),
                    myCurrency(unitHistory.money),
                    myCurrency(unitHistory.effort),
                    myCurrency(unitHistory.threshold),
                    myCurrency(unitHistory.founding),
                  ])
              .toList(),
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
          cellStyle: const pw.TextStyle(fontSize: 7),
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
            2: pw.Alignment.center,
            3: pw.Alignment.center,
            4: pw.Alignment.centerRight,
            5: pw.Alignment.centerRight,
            6: pw.Alignment.center,
            7: pw.Alignment.center,
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

    return pdfPreview(context, pdf, 'Units History');
  }
}
