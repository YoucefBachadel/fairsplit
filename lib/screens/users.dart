import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../models/effort.dart';
import '../models/founding.dart';
import '../models/threshold.dart';
import '../providers/transactions_filter.dart';
import '../shared/lists.dart';
import '../models/unit.dart';
import '../models/user.dart';
import '../shared/parameters.dart';
import '../widgets/widget.dart';
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
  var userNames = <String>{};
  bool isloading = true;
  String _search = '';
  String _type = 'tout';
  int _thresholdUnitFilter = -2;
  int _foundingUnitFilter = -2;
  int _effortUnitFilter = -2;

  int? _sortColumnIndex = 1;
  bool _isAscending = true;
  TextEditingController _controller = TextEditingController();

  void _newUser(BuildContext context, User user) async => await createDialog(context, AddUser(user: user), false);

  void loadData() async {
    var data = await sqlQuery(selectUrl, {
      'sql1': 'SELECT * FROM Threshold;',
      'sql2': 'SELECT * FROM Founding;',
      'sql3': 'SELECT * FROM Effort;',
      'sql4': 'SELECT * FROM Users;',
      'sql5': '''SELECT unitId , name FROM Units WHERE type = 'intern';''',
    });
    var dataThresholds = data[0];
    var dataFoundings = data[1];
    var dataEfforts = data[2];
    var dataUsers = data[3];
    var dataUnits = data[4];

    allUsers = toUsers(dataUsers, toThresholds(dataThresholds), toFoundings(dataFoundings), toEfforts(dataEfforts));

    for (var ele in dataUsers) {
      userNames.add(namesHidden ? ele['userId'] : ele['name']);
    }
    for (var element in dataUnits) {
      units.add(Unit(unitId: int.parse(element['unitId']), name: element['name']));
    }

    units.sort((a, b) => a.name.compareTo(b.name));
    userNames = SplayTreeSet.from(userNames);

    setState(() {
      isloading = false;
    });
  }

  void filterUsers() async {
    bool _isthresholdFilter = false;
    bool _isfoundingFilter = false;
    bool _iseffortFilter = false;

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
            user.evaluation = element.evaluation;
            break;
          }
        }
      }

      //to add user it mast contain search name and the type and the three list filter
      if ((_search.isEmpty || user.name == _search || (namesHidden && user.userId == int.parse(_search))) &&
          (_type == 'tout' || user.type == _type) &&
          (_thresholdUnitFilter == -2 || _isthresholdFilter) &&
          (_foundingUnitFilter == -2 || _isfoundingFilter) &&
          (_effortUnitFilter == -2 || _iseffortFilter)) users.add(user);

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
          return !_isAscending ? tr2.name.compareTo(tr1.name) : tr1.name.compareTo(tr2.name);
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
              ? (tr2.money + tr2.moneyExtern).compareTo(tr1.money + tr1.moneyExtern)
              : (tr1.money + tr1.moneyExtern).compareTo(tr2.money + tr2.moneyExtern);
        });
        break;
      case 6:
        users.sort((tr1, tr2) {
          return !_isAscending ? tr2.threshold.compareTo(tr1.threshold) : tr1.threshold.compareTo(tr2.threshold);
        });
        break;
      case 7:
        users.sort((tr1, tr2) {
          return !_isAscending ? tr2.founding.compareTo(tr1.founding) : tr1.founding.compareTo(tr2.founding);
        });
        break;
      case 8:
        users.sort((tr1, tr2) {
          return !_isAscending
              ? (tr2.effort + tr2.effortExtern).compareTo(tr1.effort + tr1.effortExtern)
              : (tr1.effort + tr1.effortExtern).compareTo(tr2.effort + tr2.effortExtern);
        });
        break;
      case 9:
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
      case 10:
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
      case 11:
        users.sort((tr1, tr2) {
          if (_thresholdUnitFilter != -2 && _foundingUnitFilter != -2) {
            return !_isAscending ? tr2.effort.compareTo(tr1.effort) : tr1.effort.compareTo(tr2.effort);
          } else {
            return !_isAscending ? tr2.evaluation.compareTo(tr1.evaluation) : tr1.evaluation.compareTo(tr2.evaluation);
          }
        });
        break;
      case 12:
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
        getText('name'),
        (columnIndex, ascending) => setState(() {
          _sortColumnIndex = columnIndex;
          _isAscending = ascending;
        }),
      ),
      ...[
        // getText('joinDate'),
        // getText('phone'),
        getText('type'),
      ].map((e) => dataColumn(context, e)),
      ...[
        getText('capital'),
        getText('weightedCapital'),
        getText('money'),
        getText('threshold'),
        getText('founding'),
        getText('effort'),
        if (_thresholdUnitFilter != -2) '${getText('threshold')} %',
        if (_foundingUnitFilter != -2) '${getText('founding')} %',
        if (_effortUnitFilter != -2) ...['${getText('effort')} %', getText('evaluation')],
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
      ...[''].map((e) => dataColumn(context, e)),
    ];

    List<DataRow> rows = users
        .map((user) => DataRow(
              onLongPress: () {
                context.read<TransactionsFilter>().change(
                      transactionCategory: 'users',
                      search: user.name,
                    );
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
                false,
              ),
              cells: [
                dataCell(context, (users.indexOf(user) + 1).toString()),
                dataCell(context, namesHidden ? user.userId.toString() : user.name,
                    textAlign: namesHidden ? TextAlign.center : TextAlign.start),
                // dataCell(context, myDateFormate.format(user.joinDate)),
                // dataCell(context, user.phone),
                dataCell(context, getText(user.type)),
                dataCell(
                  context,
                  user.type == 'effort' ? '/' : myCurrency.format(user.capital),
                  textAlign: user.type == 'effort' ? TextAlign.center : TextAlign.end,
                ),
                dataCell(
                  context,
                  user.type == 'effort' ? '/' : myCurrency.format(user.weightedCapital),
                  textAlign: user.type == 'effort' ? TextAlign.center : TextAlign.end,
                ),
                dataCell(
                  context,
                  user.type == 'effort' ? '/' : myCurrency.format(user.money + user.moneyExtern),
                  textAlign: user.type == 'effort' ? TextAlign.center : TextAlign.end,
                ),
                dataCell(
                  context,
                  user.type == 'effort' ? '/' : myCurrency.format(user.threshold),
                  textAlign: user.type == 'effort' ? TextAlign.center : TextAlign.end,
                ),
                dataCell(
                  context,
                  user.type == 'effort' ? '/' : myCurrency.format(user.founding),
                  textAlign: user.type == 'effort' ? TextAlign.center : TextAlign.end,
                ),
                dataCell(
                  context,
                  user.type == 'money' ? '/' : myCurrency.format(user.effort + user.effortExtern),
                  textAlign: user.type == 'money' ? TextAlign.center : TextAlign.end,
                ),
                if (_thresholdUnitFilter != -2)
                  dataCell(
                      context,
                      user.thresholds
                          .firstWhere((element) => element.unitId == _thresholdUnitFilter)
                          .thresholdPerc
                          .toString()),
                if (_foundingUnitFilter != -2)
                  dataCell(
                      context,
                      user.foundings
                          .firstWhere((element) => element.unitId == _foundingUnitFilter)
                          .foundingPerc
                          .toString()),
                if (_effortUnitFilter != -2) ...[
                  dataCell(
                    context,
                    user.efforts.firstWhere((element) => element.unitId == _effortUnitFilter).effortPerc.toString(),
                  ),
                  dataCell(
                    context,
                    user.efforts.firstWhere((element) => element.unitId == _effortUnitFilter).evaluation.toString(),
                  ),
                ],
                DataCell(IconButton(
                  onPressed: () => _newUser(context, user),
                  hoverColor: Colors.transparent,
                  icon: Icon(Icons.edit, size: 22, color: primaryColor),
                )),
              ],
            ))
        .toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        mini: true,
        onPressed: () => _newUser(context, User()),
        tooltip: getText('newUser'),
        child: const Icon(Icons.add),
      ),
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
                SizedBox(width: getWidth(context, .52), child: const Divider()),
                const SizedBox(width: double.minPositive, height: 8.0),
                Expanded(
                  child: isloading
                      ? myProgress()
                      : users.isEmpty
                          ? SizedBox(width: getWidth(context, .45), child: emptyList())
                          : users.isEmpty
                              ? emptyList()
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
            SizedBox(
              height: getHeight(context, textFeildHeight),
              width: getWidth(context, .22),
              child: Autocomplete<String>(
                onSelected: (item) => setState(() {
                  _search = item;
                }),
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
                          prefixIcon: const Icon(Icons.search, size: 20.0),
                          suffixIcon: textEditingController.text.isEmpty
                              ? const SizedBox()
                              : IconButton(
                                  onPressed: () {
                                    setState(() {
                                      textEditingController.clear();
                                      _search = '';
                                    });
                                  },
                                  icon: const Icon(Icons.clear, size: 20.0)),
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
                              onTap: () => onSelected(option),
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
                getText('type'),
                style: const TextStyle(fontSize: 14),
              ),
            ),
            myDropDown(
              context,
              value: _type,
              color: _type == 'tout' ? Colors.grey : primaryColor,
              items: usersTypesSearch.entries.map((item) {
                return DropdownMenuItem(
                  value: getKeyFromValue(item.value),
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
        const SizedBox(width: 8.0),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text(
                getText('threshold'),
                style: const TextStyle(fontSize: 14),
              ),
            ),
            myDropDown(
              context,
              value: _thresholdUnitFilter,
              width: getWidth(context, .14),
              color: _thresholdUnitFilter == -2 ? Colors.grey : primaryColor,
              items: ([Unit(unitId: -2, name: constans['tout'] ?? '')] + units).map((item) {
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
        const SizedBox(width: 8.0),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text(
                getText('founding'),
                style: const TextStyle(fontSize: 14),
              ),
            ),
            myDropDown(
              context,
              value: _foundingUnitFilter,
              width: getWidth(context, .14),
              color: _foundingUnitFilter == -2 ? Colors.grey : primaryColor,
              items: ([Unit(unitId: -2, name: constans['tout'] ?? '')] + units).map((item) {
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
        const SizedBox(width: 8.0),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text(
                getText('effort'),
                style: const TextStyle(fontSize: 14),
              ),
            ),
            myDropDown(
              context,
              value: _effortUnitFilter,
              width: getWidth(context, .14),
              color: _effortUnitFilter == -2 ? Colors.grey : primaryColor,
              items: ([
                        Unit(unitId: -2, name: constans['tout'] ?? ''),
                        Unit(unitId: -1, name: constans['global'] ?? '')
                      ] +
                      units)
                  .map((item) {
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
        const SizedBox(width: 8.0),
        (_controller.text.isNotEmpty ||
                _type != 'tout' ||
                _thresholdUnitFilter != -2 ||
                _foundingUnitFilter != -2 ||
                _effortUnitFilter != -2)
            ? IconButton(
                onPressed: () => setState(() {
                  _search = '';
                  _controller.clear();
                  _type = 'tout';
                  _thresholdUnitFilter = -2;
                  _foundingUnitFilter = -2;
                  _effortUnitFilter = -2;
                  if (_sortColumnIndex! > 8) _sortColumnIndex = 1;
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
