import 'dart:collection';

import 'package:flutter/material.dart';

import '../models/user_history.dart';
import '../shared/functions.dart';
import '../shared/lists.dart';
import '../shared/constants.dart';
import '../shared/widgets.dart';

class UserHistoryScreen extends StatefulWidget {
  const UserHistoryScreen({Key? key}) : super(key: key);

  @override
  State<UserHistoryScreen> createState() => _UserHistoryScreenState();
}

class _UserHistoryScreenState extends State<UserHistoryScreen> {
  List<UserHistory> allUsersHistroy = [], usersHistory = [];
  var years = <String>{};
  var userNames = <String>{};
  bool isloading = true;
  String _search = '';
  String _year = 'tout';

  int? _sortColumnIndex = 2;
  bool _isAscending = false;

  TextEditingController _controller = TextEditingController();

  void loadData() async {
    var res = await sqlQuery(selectUrl, {'sql1': 'SELECT * FROM UserHistory;'});
    var data = res[0];

    for (var ele in data) {
      allUsersHistroy.add(UserHistory(
        name: ele['name'],
        year: int.parse(ele['year']),
        type: ele['type'],
        startCapital: double.parse(ele['startCapital']),
        totalIn: double.parse(ele['totalIn']),
        totalOut: double.parse(ele['totalOut']),
        moneyProfit: double.parse(ele['moneyProfit']),
        thresholdProfit: double.parse(ele['thresholdProfit']),
        foundingProfit: double.parse(ele['foundingProfit']),
        effortProfit: double.parse(ele['effortProfit']),
        totalProfit: double.parse(ele['totalProfit']),
        zakat: double.parse(ele['zakat']),
      ));

      userNames.add(ele['name']);
      years.add(ele['year']);
    }

    userNames = SplayTreeSet.from(userNames);
    years = SplayTreeSet.from(years, (a, b) => b.compareTo(a));

    setState(() {
      isloading = false;
    });
  }

  void filterHistory() {
    usersHistory.clear();
    for (var userHistory in allUsersHistroy) {
      if ((_search.isEmpty || userHistory.name == _search) &&
          (_year == 'tout' || userHistory.year.toString() == _year)) {
        usersHistory.add(userHistory);
      }
    }

    onSort();
  }

  void onSort() {
    switch (_sortColumnIndex) {
      case 1:
        usersHistory.sort((tr1, tr2) {
          return !_isAscending ? tr2.name.compareTo(tr1.name) : tr1.name.compareTo(tr2.name);
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
          return !_isAscending
              ? tr2.moneyProfit.compareTo(tr1.moneyProfit)
              : tr1.moneyProfit.compareTo(tr2.moneyProfit);
        });
        break;
      case 7:
        usersHistory.sort((tr1, tr2) {
          return !_isAscending
              ? tr2.thresholdProfit.compareTo(tr1.thresholdProfit)
              : tr1.thresholdProfit.compareTo(tr2.thresholdProfit);
        });
        break;
      case 8:
        usersHistory.sort((tr1, tr2) {
          return !_isAscending
              ? tr2.foundingProfit.compareTo(tr1.foundingProfit)
              : tr1.foundingProfit.compareTo(tr2.foundingProfit);
        });
        break;
      case 9:
        usersHistory.sort((tr1, tr2) {
          return !_isAscending
              ? tr2.effortProfit.compareTo(tr1.effortProfit)
              : tr1.effortProfit.compareTo(tr2.effortProfit);
        });
        break;
      case 10:
        usersHistory.sort((tr1, tr2) {
          return !_isAscending
              ? tr2.totalProfit.compareTo(tr1.totalProfit)
              : tr1.totalProfit.compareTo(tr2.totalProfit);
        });
        break;
      case 11:
        usersHistory.sort((tr1, tr2) {
          return !_isAscending ? tr2.zakat.compareTo(tr1.zakat) : tr1.zakat.compareTo(tr2.zakat);
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
    filterHistory();

    List<DataColumn> columns = [
      dataColumn(context, ''),
      ...[
        getText('name'),
        getText('year'),
        getText('startCapital'),
        getText('totalIn'),
        getText('totalOut'),
        getText('moneyProfit'),
        getText('thresholdProfit'),
        getText('foundingProfit'),
        getText('effortProfit'),
        getText('totalProfit'),
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
              dataCell(
                  context, namesHidden ? userNames.toList().indexOf(userHistory.name).toString() : userHistory.name,
                  textAlign: namesHidden ? TextAlign.center : TextAlign.start),
              ...[
                userHistory.year.toString(),
                userHistory.isMoney ? myCurrency.format(userHistory.startCapital) : '/',
                userHistory.isMoney ? myCurrency.format(userHistory.totalIn) : '/',
                userHistory.isMoney ? myCurrency.format(userHistory.totalOut) : '/',
                userHistory.isMoney ? myCurrency.format(userHistory.moneyProfit) : '/',
                userHistory.isMoney ? myCurrency.format(userHistory.thresholdProfit) : '/',
                userHistory.isMoney ? myCurrency.format(userHistory.foundingProfit) : '/',
                userHistory.isEffort ? myCurrency.format(userHistory.effortProfit) : '/',
                myCurrency.format(userHistory.totalProfit),
                userHistory.isMoney ? myCurrency.format(userHistory.zakat) : '/',
              ].map((e) => dataCell(context, e, textAlign: e == '/' ? TextAlign.center : TextAlign.end)).toList(),
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
                serachBar(),
                const SizedBox(width: double.minPositive, height: 8.0),
                SizedBox(width: getWidth(context, .19), child: const Divider()),
                const SizedBox(width: double.minPositive, height: 8.0),
                Expanded(
                  flex: 5,
                  child: isloading
                      ? myProgress()
                      : usersHistory.isEmpty
                          ? SizedBox(width: getWidth(context, .60), child: emptyList())
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

  Widget serachBar() {
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
            SizedBox(
              height: getHeight(context, textFeildHeight),
              width: getWidth(context, .22),
              child: Autocomplete<String>(
                onSelected: (item) =>
                    setState(() => _search = namesHidden ? userNames.elementAt(int.parse(item)) : item),
                optionsBuilder: (textEditingValue) {
                  if (namesHidden) {
                    List<String> indexes = [];
                    for (var ele in userNames) {
                      if (userNames.toList().indexOf(ele).toString().contains(textEditingValue.text)) {
                        indexes.add(userNames.toList().indexOf(ele).toString());
                      }
                    }
                    return indexes;
                  } else {
                    return userNames.where((item) => item.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                  }
                },
                fieldViewBuilder: (
                  context,
                  textEditingController,
                  focusNode,
                  onFieldSubmitted,
                ) {
                  _controller = textEditingController;
                  return Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: _controller.text.isEmpty ? Colors.grey : primaryColor),
                        borderRadius: const BorderRadius.all(Radius.circular(12)),
                      ),
                      child: TextFormField(
                        controller: _controller,
                        focusNode: focusNode,
                        style: const TextStyle(fontSize: 18.0),
                        onChanged: ((value) => setState(() {})),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8.0),
                          hintText: getText('search'),
                          border: const OutlineInputBorder(
                            borderSide: BorderSide.none,
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                          prefixIcon: const Icon(
                            Icons.search,
                            size: 20.0,
                          ),
                          suffixIcon: textEditingController.text.isEmpty
                              ? const SizedBox()
                              : IconButton(
                                  onPressed: () {
                                    setState(() {
                                      textEditingController.clear();
                                      _search = '';
                                    });
                                  },
                                  icon: const Icon(
                                    Icons.clear,
                                    size: 20.0,
                                  )),
                        ),
                      ));
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
                            BoxConstraints(maxHeight: getHeight(context, .2), maxWidth: getWidth(context, .22)),
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
                                alignment: namesHidden ? Alignment.center : Alignment.centerLeft,
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
                      getText('totalProfit'),
                      getText('zakat'),
                    ],
                    ...usersHistory.map((user) => [
                          usersHistory.indexOf(user) + 1,
                          user.name,
                          getText(user.type),
                          user.year,
                          user.startCapital,
                          user.totalIn,
                          user.totalOut,
                          user.moneyProfit,
                          user.effortProfit,
                          user.thresholdProfit,
                          user.foundingProfit,
                          user.totalProfit,
                          user.zakat,
                        ])
                  ],
                  getText('userHistory'),
                ),
            icon: Icon(
              Icons.file_download,
              color: primaryColor,
            )),
        mySizedBox(context),
        (_controller.text.isNotEmpty || _year != 'tout')
            ? IconButton(
                onPressed: () => setState(() {
                  _search = '';
                  _controller.clear();
                  _year = 'tout';
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
