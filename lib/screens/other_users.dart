import 'package:fairsplit/providers/filter.dart';
import 'package:fairsplit/screens/add_transaction.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../models/other_user.dart';
import '../screens/add_other_user.dart';
import '../shared/functions.dart';
import '../shared/lists.dart';
import '../shared/constants.dart';
import '../shared/widgets.dart';

class OtherUsers extends StatefulWidget {
  const OtherUsers({Key? key}) : super(key: key);

  @override
  State<OtherUsers> createState() => _OtherUsersState();
}

class _OtherUsersState extends State<OtherUsers> {
  List<OtherUser> allUsers = [], users = [];
  List<String> usersWithCapital = []; //list of users with capital != 0
  var userNames = <String>{};
  bool isloading = true;
  String _search = '';
  String _type = 'tout';
  double totalLoan = 0, totalDeposit = 0;
  int? _sortColumnIndex = 1;
  bool _isAscending = true;
  TextEditingController _controller = TextEditingController();
  final ScrollController _controllerH = ScrollController(), _controllerV = ScrollController();

  void _newUser(BuildContext context, OtherUser user) async => await createDialog(context, AddOtherUser(user: user));

  void loadData() async {
    var res = await sqlQuery(selectUrl, {
      'sql1': 'SELECT name FROM users WHERE capital != 0;',
      'sql2': 'SELECT * FROM OtherUsers;',
    });

    for (var ele in res[0]) {
      usersWithCapital.add(ele['name']);
    }

    for (var ele in res[1]) {
      OtherUser user = OtherUser(
        userId: int.parse(ele['userId']),
        name: ele['name'],
        type: ele['type'],
        joinDate: DateTime.parse(ele['joinDate']),
        phone: ele['phone'],
        amount: double.parse(ele['amount']),
        rest: double.parse(ele['rest']),
      );
      user.isUserWithCapital = user.type == 'loan' && user.rest != 0 && usersWithCapital.contains(user.name);
      allUsers.add(user);

      userNames.add(ele['name']);
    }

    setState(() {
      isloading = false;
    });
  }

  void filterUsers() {
    users.clear();
    totalLoan = 0;
    totalDeposit = 0;
    for (var user in allUsers) {
      if ((_search.isEmpty || user.name == _search) && (_type == 'tout' || user.type == _type)) {
        users.add(user);
        user.type == 'loan' ? totalLoan += user.rest : totalDeposit += user.rest;
      }
    }

    onSort();
  }

  void onSort() {
    switch (_sortColumnIndex) {
      case 1:
        users.sort((a, b) => _isAscending ? a.name.compareTo(b.name) : b.name.compareTo(a.name));
        break;
      case 3:
        users.sort((a, b) => _isAscending ? a.amount.compareTo(b.amount) : b.amount.compareTo(a.amount));
        break;
      case 4:
        users.sort((a, b) => _isAscending ? a.rest.compareTo(b.rest) : b.rest.compareTo(a.rest));
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
    _type = context.watch<Filter>().loanDeposit;
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
      ...[getText('amount'), getText('rest')].map((e) => sortableDataColumn(
            context,
            e,
            (columnIndex, ascending) => setState(() {
              _sortColumnIndex = columnIndex;
              _isAscending = ascending;
            }),
          )),
      if (isAdmin) dataColumn(context, ''),
    ];

    List<DataRow> rows = users
        .map((user) => DataRow(
              color: user.isUserWithCapital ? MaterialStatePropertyAll(Colors.red[100]) : null,
              onLongPress: () {
                context.read<Filter>().change(
                      transactionCategory: '${user.type}s',
                      search: user.name,
                    );
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MyApp(index: 'tr')));
              },
              onSelectChanged: (value) async => await createDialog(
                context,
                AddTransaction(
                  sourceTab: 'ou',
                  userId: user.userId,
                  selectedName: user.name,
                  type: user.type,
                  amount: user.amount,
                  rest: user.rest,
                  selectedTransactionType: user.type == 'loan' ? 2 : 3,
                ),
                dismissable: false,
              ),
              cells: [
                dataCell(context, (users.indexOf(user) + 1).toString()),
                dataCell(context, user.name, textAlign: TextAlign.start),
                // dataCell(context, myDateFormate.format(user.joinDate)),
                // dataCell(context, user.phone),
                dataCell(context, getText(user.type)),
                dataCell(context, myCurrency.format(user.amount), textAlign: TextAlign.end),
                dataCell(context, myCurrency.format(user.rest), textAlign: TextAlign.end),
                if (isAdmin)
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
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              mini: true,
              onPressed: () => _newUser(context, OtherUser()),
              tooltip: getText('newUser'),
              child: const Icon(Icons.add),
            )
          : null,
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
        child: Column(children: [
          const SizedBox(width: double.minPositive, height: 8.0),
          searchBar(),
          const SizedBox(width: double.minPositive, height: 8.0),
          SizedBox(width: getWidth(context, .20), child: const Divider()),
          const SizedBox(width: double.minPositive, height: 8.0),
          Expanded(
            child: isloading
                ? myProgress()
                : users.isEmpty
                    ? SizedBox(width: getWidth(context, .60), child: emptyList())
                    : users.isEmpty
                        ? emptyList()
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              myText('${getText('totalLoan')} :      ${myCurrency.format(totalLoan)}'),
              SizedBox(width: getWidth(context, .05)),
              myText('${getText('totalDeposit')} :      ${myCurrency.format(totalDeposit)}'),
              SizedBox(width: getWidth(context, .05)),
            ],
          ),
          mySizedBox(context),
        ]),
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
                getText('type'),
                style: const TextStyle(fontSize: 14),
              ),
            ),
            myDropDown(
              context,
              value: _type,
              color: _type == 'tout' ? Colors.grey : primaryColor,
              items: otherUsersTypesSearch.entries.map((item) {
                return DropdownMenuItem(
                  value: getKeyFromValue(item.value),
                  alignment: AlignmentDirectional.center,
                  child: Text(item.value),
                );
              }).toList(),
              onChanged: (value) => setState(() => context.read<Filter>().change(loanDeposit: value.toString())),
            ),
          ],
        ),
        mySizedBox(context),
        IconButton(
            onPressed: () => createExcel(
                  getText('otherUsers'),
                  [
                    ['#', getText('name'), getText('type'), getText('amount'), getText('rest')],
                    ...users.map((user) => [
                          users.indexOf(user) + 1,
                          user.name,
                          getText(user.type),
                          user.amount,
                          user.rest,
                        ]),
                  ],
                ),
            icon: Icon(
              Icons.file_download,
              color: primaryColor,
            )),
        mySizedBox(context),
        (_controller.text.isNotEmpty || _type != 'tout')
            ? IconButton(
                onPressed: () => setState(() {
                  _search = '';
                  _controller.clear();
                  context.read<Filter>().resetFilter();
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
