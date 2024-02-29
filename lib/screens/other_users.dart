import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:provider/provider.dart';
import 'package:pdf/widgets.dart' as pw;

import '../main.dart';
import '../models/other_user.dart';
import '../screens/add_other_user.dart';
import '../screens/add_transaction.dart';
import '../providers/filter.dart';
import '../shared/functions.dart';
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
        rest: double.parse(ele['rest']),
      );
      user.isUserWithCapital = user.type == 'loan' && user.rest != 0 && usersWithCapital.contains(user.name);
      allUsers.add(user);
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
      if ((_search.isEmpty || user.realName == _search) && (_type == 'tout' || user.type == _type)) {
        users.add(user);
        user.type == 'loan' ? totalLoan += user.rest : totalDeposit += user.rest;
      }
    }

    onSort();
  }

  void onSort() {
    switch (_sortColumnIndex) {
      case 1:
        users.sort((a, b) => _isAscending ? a.realName.compareTo(b.realName) : b.realName.compareTo(a.realName));
        break;
      case 3:
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
        'Name',
        (columnIndex, ascending) => setState(() {
          _sortColumnIndex = columnIndex;
          _isAscending = ascending;
        }),
      ),
      ...[
        'Type',
      ].map((e) => dataColumn(context, e)),
      sortableDataColumn(
        context,
        'Rest',
        (columnIndex, ascending) => setState(() {
          _sortColumnIndex = columnIndex;
          _isAscending = ascending;
        }),
      ),
      if (isAdmin) dataColumn(context, ''),
    ];

    List<DataRow> rows = users
        .map((user) => DataRow(
              color: user.isUserWithCapital ? MaterialStatePropertyAll(Colors.red[100]) : null,
              onLongPress: () {
                context.read<Filter>().change(transactionCategory: 'users', search: user.realName);
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MyApp(index: 'tr')));
              },
              onSelectChanged: (value) async => await createDialog(
                context,
                AddTransaction(
                  sourceTab: 'ou',
                  userId: user.userId,
                  selectedName: user.name,
                  type: user.type,
                  rest: user.rest,
                  selectedTransactionType: user.type == 'loan' ? 2 : 3,
                ),
                dismissable: false,
              ),
              cells: [
                dataCell(context, (users.indexOf(user) + 1).toString()),
                dataCell(context, user.realName, textAlign: TextAlign.start),
                dataCell(context, getText(otherUserTypes, user.type)),
                dataCell(context, myCurrency(user.rest), textAlign: TextAlign.end),
                if (isAdmin)
                  DataCell(myIconButton(
                    onPressed: () => _newUser(context, user),
                    icon: Icons.edit,
                    size: 18,
                    color: primaryColor,
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
              tooltip: 'New User',
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
          SizedBox(width: getWidth(context, .52), child: const Divider()),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              totalItem(context, 'Total Laon', myCurrency(totalLoan), isExpanded: false),
              totalItem(context, 'Total Deposit', myCurrency(totalDeposit), isExpanded: false),
            ],
          ),
          mySizedBox(context),
        ]),
      ),
    );
  }

  Widget searchBar() {
    Map<String, String> otherUsersTypesSearch = {
      'tout': 'Tout',
      'loan': 'Loan',
      'deposit': 'Deposit',
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
              Autocomplete<String>(
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
                        hint: 'Search...',
                        borderColor: _search.isEmpty ? Colors.grey : primaryColor,
                        prefixIcon: const Icon(Icons.search, size: 20.0),
                        suffixIcon: _controller.text.isEmpty
                            ? null
                            : myIconButton(
                                onPressed: () {
                                  setState(() {
                                    _controller.clear();
                                    _search = '';
                                  });
                                },
                                icon: Icons.clear),
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
                items: otherUsersTypesSearch.entries.map((item) {
                  return DropdownMenuItem(
                    value: getKeyFromValue(otherUsersTypesSearch, item.value),
                    alignment: AlignmentDirectional.center,
                    child: Text(item.value),
                  );
                }).toList(),
                onChanged: (value) => setState(() => context.read<Filter>().change(loanDeposit: value.toString())),
              ),
            ],
          ),
          mySizedBox(context),
          myIconButton(
            onPressed: () => createExcel(
              'Other Users',
              [
                ['#', 'Name', 'Type', 'Rest'],
                ...users.map((user) => [
                      users.indexOf(user) + 1,
                      user.realName,
                      getText(otherUserTypes, user.type),
                      user.rest,
                    ]),
              ],
            ),
            icon: Icons.file_download,
            color: primaryColor,
          ),
          myIconButton(
            icon: Icons.print,
            color: primaryColor,
            onPressed: () {
              createDialog(
                context,
                SizedBox(
                  width: getWidth(context, .392),
                  child: printPage(),
                ),
              );
            },
          ),
          if (_search.isNotEmpty || _type != 'tout')
            myIconButton(
              onPressed: () => setState(() {
                _search = '';
                _controller.clear();
                context.read<Filter>().resetFilter();
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
      pdfPageFormat: PdfPageFormat.a5,
      build: [
        pw.Table.fromTextArray(
          headers: [
            'Name',
            'Type',
            'Rest',
          ],
          data:
              users.map((user) => [user.realName, getText(otherUserTypes, user.type), myCurrency(user.rest)]).toList(),
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
          cellStyle: const pw.TextStyle(fontSize: 10),
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
          },
        ),
      ],
    ));

    return pdfPreview(context, pdf, 'Other Users');
  }
}
