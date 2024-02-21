import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/user_history.dart';
import '../shared/functions.dart';
import '../shared/lists.dart';
import '../shared/constants.dart';
import '../shared/widgets.dart';

class UsersHistory extends StatefulWidget {
  const UsersHistory({Key? key}) : super(key: key);

  @override
  State<UsersHistory> createState() => _UsersHistoryState();
}

class _UsersHistoryState extends State<UsersHistory> {
  List<UserHistory> allUsersHistroy = [], usersHistory = [];
  bool isloading = true;
  String _search = '';
  String _year = 'tout';

  int? _sortColumnIndex = 1;
  bool _isAscending = true;

  TextEditingController _controller = TextEditingController();
  final ScrollController _controllerH = ScrollController(), _controllerV = ScrollController();
  double tStartCapital = 0,
      tEndCapital = 0,
      tNewCapital = 0,
      tMoney = 0,
      tThreshold = 0,
      tFounding = 0,
      tEffort = 0,
      tTotalProfit = 0,
      tZakat = 0;

  void loadData() async {
    var res = await sqlQuery(selectUrl, {'sql1': 'SELECT * FROM UserHistory;'});
    var data = res[0];

    for (var ele in data) {
      allUsersHistroy.add(UserHistory(
        name: ele['name'],
        year: int.parse(ele['year']),
        startCapital: double.parse(ele['startCapital']),
        totalIn: double.parse(ele['totalIn']),
        totalOut: double.parse(ele['totalOut']),
        endCapital: double.parse(ele['endCapital']),
        weightedCapital: double.parse(ele['weightedCapital']),
        moneyProfit: double.parse(ele['moneyProfit']),
        thresholdProfit: double.parse(ele['thresholdProfit']),
        foundingProfit: double.parse(ele['foundingProfit']),
        effortProfit: double.parse(ele['effortProfit']),
        externProfit: double.parse(ele['externProfit']),
        totalProfit: double.parse(ele['totalProfit']),
        newCapital: double.parse(ele['newCapital']),
        zakat: double.parse(ele['zakat']),
      ));
    }

    setState(() {
      isloading = false;
    });
  }

  void filterHistory() {
    usersHistory.clear();
    tStartCapital = 0;
    tEndCapital = 0;
    tNewCapital = 0;
    tMoney = 0;
    tThreshold = 0;
    tFounding = 0;
    tEffort = 0;
    tTotalProfit = 0;
    tZakat = 0;
    for (var userHistory in allUsersHistroy) {
      if ((_search.isEmpty || userHistory.realName == _search) &&
          (_year == 'tout' || userHistory.year.toString() == _year)) {
        usersHistory.add(userHistory);
        tStartCapital += userHistory.startCapital;
        tEndCapital += userHistory.endCapital;
        tNewCapital += userHistory.newCapital;
        tMoney += userHistory.moneyProfit;
        tThreshold += userHistory.thresholdProfit;
        tFounding += userHistory.foundingProfit;
        tEffort += userHistory.effortProfit;
        tTotalProfit += userHistory.totalProfit;
        tZakat += userHistory.zakat;
      }
    }

    onSort();
  }

  void onSort() {
    switch (_sortColumnIndex) {
      case 1:
        usersHistory.sort((tr1, tr2) {
          return !_isAscending ? tr2.realName.compareTo(tr1.realName) : tr1.realName.compareTo(tr2.realName);
        });
        break;
      case 2:
        usersHistory.sort((tr1, tr2) {
          return !_isAscending ? tr2.year.compareTo(tr1.year) : tr1.year.compareTo(tr2.year);
        });
        break;
      case 3:
        usersHistory.sort((tr1, tr2) {
          return !_isAscending
              ? tr2.startCapital.compareTo(tr1.startCapital)
              : tr1.startCapital.compareTo(tr2.startCapital);
        });
        break;
      case 4:
        usersHistory.sort((tr1, tr2) {
          return !_isAscending ? tr2.totalIn.compareTo(tr1.totalIn) : tr1.totalIn.compareTo(tr2.totalIn);
        });
        break;
      case 5:
        usersHistory.sort((tr1, tr2) {
          return !_isAscending ? tr2.totalOut.compareTo(tr1.totalOut) : tr1.totalOut.compareTo(tr2.totalOut);
        });
        break;
      case 6:
        usersHistory.sort((tr1, tr2) {
          return !_isAscending ? tr2.endCapital.compareTo(tr1.endCapital) : tr1.endCapital.compareTo(tr2.endCapital);
        });
        break;
      case 7:
        usersHistory.sort((tr1, tr2) {
          return !_isAscending
              ? tr2.weightedCapital.compareTo(tr1.weightedCapital)
              : tr1.weightedCapital.compareTo(tr2.weightedCapital);
        });
        break;
      case 8:
        usersHistory.sort((tr1, tr2) {
          return !_isAscending
              ? tr2.moneyProfit.compareTo(tr1.moneyProfit)
              : tr1.moneyProfit.compareTo(tr2.moneyProfit);
        });
        break;
      case 9:
        usersHistory.sort((tr1, tr2) {
          return !_isAscending
              ? tr2.thresholdProfit.compareTo(tr1.thresholdProfit)
              : tr1.thresholdProfit.compareTo(tr2.thresholdProfit);
        });
        break;
      case 10:
        usersHistory.sort((tr1, tr2) {
          return !_isAscending
              ? tr2.foundingProfit.compareTo(tr1.foundingProfit)
              : tr1.foundingProfit.compareTo(tr2.foundingProfit);
        });
        break;
      case 11:
        usersHistory.sort((tr1, tr2) {
          return !_isAscending
              ? tr2.effortProfit.compareTo(tr1.effortProfit)
              : tr1.effortProfit.compareTo(tr2.effortProfit);
        });
        break;
      case 12:
        usersHistory.sort((tr1, tr2) {
          return !_isAscending
              ? tr2.externProfit.compareTo(tr1.externProfit)
              : tr1.externProfit.compareTo(tr2.externProfit);
        });
        break;
      case 13:
        usersHistory.sort((tr1, tr2) {
          return !_isAscending
              ? tr2.totalProfit.compareTo(tr1.totalProfit)
              : tr1.totalProfit.compareTo(tr2.totalProfit);
        });
        break;
      case 14:
        usersHistory.sort((tr1, tr2) {
          return !_isAscending ? tr2.newCapital.compareTo(tr1.newCapital) : tr1.newCapital.compareTo(tr2.newCapital);
        });
        break;
      case 15:
        usersHistory.sort((tr1, tr2) {
          return !_isAscending ? tr2.zakat.compareTo(tr1.zakat) : tr1.zakat.compareTo(tr2.zakat);
        });
        break;
    }
  }

  void clearSearch() => setState(() {
        _search = '';
        _controller.clear();
      });

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
        getText('startCapital'),
        getText('totalIn'),
        getText('totalOut'),
        getText('endCapital'),
        getText('weightedCapital'),
        getText('money'),
        getText('threshold'),
        getText('founding'),
        getText('effort'),
        getText('externProfit'),
        getText('totalProfit'),
        getText('newCapital'),
        getText('zakat'),
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
    ];

    List<DataRow> rows = usersHistory
        .map(
          (userHistory) => DataRow(
            cells: [
              dataCell(context, (usersHistory.indexOf(userHistory) + 1).toString()),
              dataCell(context, userHistory.realName, textAlign: TextAlign.start),
              dataCell(context, userHistory.year.toString()),
              ...[
                myCurrency(userHistory.startCapital),
                myCurrency(userHistory.totalIn),
                myCurrency(userHistory.totalOut),
                myCurrency(userHistory.endCapital),
                myCurrency(userHistory.weightedCapital),
                myCurrency(userHistory.moneyProfit),
                myCurrency(userHistory.thresholdProfit),
                myCurrency(userHistory.foundingProfit),
                myCurrency(userHistory.effortProfit),
                myCurrency(userHistory.externProfit),
                myCurrency(userHistory.totalProfit),
                myCurrency(userHistory.newCapital),
                myCurrency(userHistory.zakat),
              ].map((e) => dataCell(context, e, textAlign: e == '/' ? TextAlign.center : TextAlign.end)).toList(),
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
                flex: 5,
                child: isloading
                    ? myProgress()
                    : usersHistory.isEmpty
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
            SizedBox(width: getWidth(context, .52), child: const Divider()),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  children: [
                    totalItem(context, getText('startCapital'), myCurrency(tStartCapital)),
                    totalItem(context, getText('endCapital'), myCurrency(tEndCapital)),
                    totalItem(context, getText('newCapital'), myCurrency(tNewCapital)),
                  ],
                ),
                SizedBox(height: getHeight(context, .08), child: const VerticalDivider(width: 50)),
                Column(
                  children: [
                    totalItem(context, getText('money'), myCurrency(tMoney)),
                    totalItem(context, getText('zakat'), myCurrency(tZakat)),
                    totalItem(context, getText('totalProfit'), myCurrency(tTotalProfit)),
                  ],
                ),
                SizedBox(height: getHeight(context, .08), child: const VerticalDivider(width: 50)),
                Column(
                  children: [
                    totalItem(context, getText('effort'), myCurrency(tEffort)),
                    totalItem(context, getText('threshold'), myCurrency(tThreshold)),
                    totalItem(context, getText('founding'), myCurrency(tFounding)),
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
              Autocomplete<String>(
                onSelected: (item) => setState(() => _search = item),
                optionsBuilder: (textEditingValue) =>
                    userNames.where((item) => item.toLowerCase().contains(textEditingValue.text.toLowerCase())),
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
                        hint: getText('search'),
                        borderColor: _search.isEmpty ? Colors.grey : primaryColor,
                        prefixIcon: const Icon(Icons.search, size: 20.0),
                        suffixIcon: _controller.text.isEmpty
                            ? null
                            : IconButton(
                                onPressed: () {
                                  setState(() {
                                    _controller.clear();
                                    _search = '';
                                  });
                                },
                                icon: const Icon(Icons.clear, size: 20.0)),
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
                              onTap: () {
                                onSelected(option);
                              },
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
                    getText('userHistory'),
                    [
                      [
                        '#',
                        getText('name'),
                        getText('type'),
                        getText('year'),
                        getText('startCapital'),
                        getText('totalIn'),
                        getText('totalOut'),
                        getText('moneyProfit'),
                        getText('effortProfit'),
                        getText('thresholdProfit'),
                        getText('foundingProfit'),
                        getText('externProfit'),
                        getText('totalProfit'),
                        getText('newCapital'),
                        getText('zakat'),
                      ],
                      ...usersHistory.map((user) => [
                            usersHistory.indexOf(user) + 1,
                            user.realName,
                            user.year,
                            user.startCapital,
                            user.totalIn,
                            user.totalOut,
                            user.endCapital,
                            user.weightedCapital,
                            user.moneyProfit,
                            user.effortProfit,
                            user.thresholdProfit,
                            user.foundingProfit,
                            user.externProfit,
                            user.totalProfit,
                            user.newCapital,
                            user.zakat,
                          ])
                    ],
                  ),
              icon: Icon(
                Icons.file_download,
                color: primaryColor,
              )),
          IconButton(
            icon: Icon(Icons.print, color: primaryColor),
            onPressed: () => createDialog(context, SizedBox(child: printPage())),
          ),
          if (_search.isNotEmpty || _year != 'tout')
            IconButton(
              onPressed: () => setState(() {
                _search = '';
                _controller.clear();
                _year = 'tout';
              }),
              icon: Icon(
                Icons.update,
                color: primaryColor,
              ),
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
            getText('name'),
            getText('year'),
            getText('startCapital'),
            getText('totalIn'),
            getText('totalOut'),
            getText('endCapital'),
            getText('money'),
            getText('threshold'),
            getText('founding'),
            getText('effort'),
            getText('externProfit'),
            getText('newCapital'),
            getText('zakat'),
          ],
          data: usersHistory
              .map((userHistory) => [
                    userHistory.realName,
                    userHistory.year,
                    myCurrency(userHistory.startCapital),
                    myCurrency(userHistory.totalIn),
                    myCurrency(userHistory.totalOut),
                    myCurrency(userHistory.endCapital),
                    myCurrency(userHistory.moneyProfit),
                    myCurrency(userHistory.thresholdProfit),
                    myCurrency(userHistory.foundingProfit),
                    myCurrency(userHistory.effortProfit),
                    myCurrency(userHistory.externProfit),
                    myCurrency(userHistory.newCapital),
                    myCurrency(userHistory.zakat),
                  ])
              .toList(),
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
          cellStyle: const pw.TextStyle(fontSize: 8),
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

    return pdfPreview(context, pdf, 'Users History');
  }
}
