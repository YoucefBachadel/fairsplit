import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:provider/provider.dart';
import 'package:pdf/widgets.dart' as pw;

import '../main.dart';
import '../providers/filter.dart';
import '../shared/functions.dart';
import '../models/transaction.dart';
import '../models/transaction_sp.dart';
import '../shared/constants.dart';
import '../shared/widgets.dart';
import 'add_transaction.dart';
import 'print_transaction.dart';

class Transactions extends StatefulWidget {
  const Transactions({Key? key}) : super(key: key);

  @override
  State<Transactions> createState() => _TransactionsState();
}

class _TransactionsState extends State<Transactions> {
  List<Transaction> allTransactions = [], transactions = [], allCaisseTransactions = [];
  List<TransactionSP> allTransactionsSP = [], transactionsSP = [];

  bool isloading = true;
  String transactionCategory = 'users'; //caisse users specials
  String _userCategory = 'tout'; //tout users loans deposits
  String _compt = 'tout'; // caisse reserve donation zakat
  String _reference = '';
  String _search = ''; //search by user name
  String _year = currentYear.toString();
  String _month = 'tout';
  String _type = 'tout'; // entrie sortie

  double totalIn = 0;
  double totalOut = 0;

  DateTime _fromDate = DateTime.now();
  DateTime _toDate = DateTime.now();

  int? _sortColumnIndexTransUser = 4;
  bool _isAscendingTransUser = false;
  int? _sortColumnIndexTransCaisse = 4;
  bool _isAscendingTransCaisse = false;
  int? _sortColumnIndexTransSP = 3;
  bool _isAscendingTransSP = false;

  TextEditingController _searchController = TextEditingController();
  final TextEditingController _referenceController = TextEditingController();
  final ScrollController _searchControllerH = ScrollController(), _searchControllerV = ScrollController();

  void loadData() async {
    _year = transactionFilterYear;

    var params = {
      'sql1': 'SELECT * FROM transaction ${_year == 'tout' ? '' : '''WHERE Year(date) = '$_year\''''};',
      'sql2': 'SELECT * FROM transactionsp ${_year == 'tout' ? '' : '''WHERE Year(date) = '$_year\''''};',
      'sql3': 'SELECT * FROM transactionothers ${_year == 'tout' ? '' : '''WHERE Year(date) = '$_year\''''};',
      'sql4': 'SELECT * FROM transactiontemp;',
    };

    var res = await sqlQuery(selectUrl, params);
    var dataTransaction = res[0];
    var dataTransactionSP = res[1];
    var dataTransactionOther = res[2];
    var dataTransactionTemp = res[3];

    for (var ele in dataTransaction) {
      Transaction trans = Transaction(
        reference: ele['reference'],
        transactionId: int.parse(ele['transactionId']),
        userName: ele['userName'],
        date: DateTime.parse(ele['date']),
        type: ele['type'],
        amount: double.parse(ele['amount']),
        soldeUser: double.parse(ele['soldeUser']),
        isCaisseChanged: int.parse(ele['changeCaisse']) == 1,
        soldeCaisse: double.parse(ele['soldeCaisse']),
        note: ele['note'],
        reciver: ele['reciver'],
        amountOnLetter: ele['amountOnLetter'],
        intermediates: ele['intermediates'],
        printingNotes: ele['printingNotes'],
      );
      allTransactions.add(trans);
      allCaisseTransactions.add(trans);
    }

    for (var ele in dataTransactionOther) {
      Transaction trans = Transaction(
        reference: ele['reference'],
        transactionId: int.parse(ele['transactionId']),
        userName: ele['userName'],
        source: ele['category'],
        date: DateTime.parse(ele['date']),
        type: ele['type'],
        amount: double.parse(ele['amount']),
        soldeUser: double.parse(ele['soldeUser']),
        isCaisseChanged: int.parse(ele['changeCaisse']) == 1,
        soldeCaisse: double.parse(ele['soldeCaisse']),
        note: ele['note'],
        reciver: ele['reciver'],
        amountOnLetter: ele['amountOnLetter'],
        intermediates: ele['intermediates'],
        printingNotes: ele['printingNotes'],
      );

      allTransactions.add(trans);
      allCaisseTransactions.add(trans);
    }

    for (var ele in dataTransactionSP) {
      allTransactionsSP.add(TransactionSP(
        reference: ele['reference'],
        transactionId: int.parse(ele['transactionId']),
        category: ele['category'],
        type: ele['type'],
        date: DateTime.parse(ele['date']),
        amount: double.parse(ele['amount']),
        solde: double.parse(ele['solde']),
        note: ele['note'],
        reciver: ele['reciver'],
        amountOnLetter: ele['amountOnLetter'],
        intermediates: ele['intermediates'],
        printingNotes: ele['printingNotes'],
      ));

      allCaisseTransactions.add(Transaction(
        reference: ele['reference'],
        transactionId: int.parse(ele['transactionId']),
        userName: getText(compts, ele['category']),
        source: ele['category'],
        date: DateTime.parse(ele['date']),
        type: ele['type'],
        amount: double.parse(ele['amount']),
        soldeUser: double.parse(ele['solde']),
        isCaisseChanged: int.parse(ele['changeCaisse']) == 1,
        soldeCaisse: double.parse(ele['soldeCaisse']),
        note: ele['note'],
        reciver: ele['reciver'],
        amountOnLetter: ele['amountOnLetter'],
        intermediates: ele['intermediates'],
        printingNotes: ele['printingNotes'],
      ));
    }

    for (var ele in dataTransactionTemp) {
      if (int.parse(ele['userId']) == -1) {
        allTransactionsSP.add(TransactionSP(
          reference: ele['reference'],
          transactionId: int.parse(ele['transactionId']),
          category: ele['userName'],
          type: ele['type'],
          date: DateTime.parse(ele['date']),
          amount: double.parse(ele['amount']),
          solde: -0.01,
          note: ele['note'],
          reciver: ele['reciver'],
          amountOnLetter: ele['amountOnLetter'],
          intermediates: ele['intermediates'],
          printingNotes: ele['printingNotes'],
        ));

        allCaisseTransactions.add(Transaction(
          reference: ele['reference'],
          transactionId: int.parse(ele['transactionId']),
          userName: (int.parse(ele['userId']) == -1) ? 'Reserve' : ele['userName'],
          source: (int.parse(ele['userId']) == -1) ? ele['userName'] : 'user',
          date: DateTime.parse(ele['date']),
          type: ele['type'],
          amount: double.parse(ele['amount']),
          soldeUser: -0.01,
          isCaisseChanged: int.parse(ele['changeCaisse']) == 1,
          soldeCaisse: double.parse(ele['soldeCaisse']),
          note: ele['note'],
          reciver: ele['reciver'],
          amountOnLetter: ele['amountOnLetter'],
          intermediates: ele['intermediates'],
          printingNotes: ele['printingNotes'],
        ));
      } else {
        Transaction trans = Transaction(
          reference: ele['reference'],
          transactionId: int.parse(ele['transactionId']),
          userName: ele['userName'],
          date: DateTime.parse(ele['date']),
          type: ele['type'],
          amount: double.parse(ele['amount']),
          soldeUser: -0.01,
          isCaisseChanged: int.parse(ele['changeCaisse']) == 1,
          soldeCaisse: double.parse(ele['soldeCaisse']),
          note: ele['note'],
          reciver: ele['reciver'],
          amountOnLetter: ele['amountOnLetter'],
          intermediates: ele['intermediates'],
          printingNotes: ele['printingNotes'],
        );

        allTransactions.add(trans);
        allCaisseTransactions.add(trans);
      }
    }

    _fromDate = _year == 'tout' ? DateTime(int.parse(years.last)) : DateTime(int.parse(_year));
    _toDate = _year == 'tout'
        ? DateTime(int.parse(years.first) + 1).subtract(const Duration(seconds: 1))
        : DateTime(int.parse(_year) + 1).subtract(const Duration(seconds: 1));

    setState(() => isloading = false);
  }

  void filterTransactionUser() {
    transactions.clear();
    for (var trans in allTransactions) {
      if ((_search.isEmpty || trans.realUserName == _search) &&
          (_reference.isEmpty || trans.reference.contains(_reference)) &&
          (_type == 'tout' || trans.type == _type) &&
          (_userCategory == 'tout' || trans.source == _userCategory) &&
          (trans.date.isAfter(_fromDate) || myDateFormate.format(trans.date) == myDateFormate.format(_fromDate)) &&
          (trans.date.isBefore(_toDate) || myDateFormate.format(trans.date) == myDateFormate.format(_toDate))) {
        transactions.add(trans);
        trans.type == 'in' ? totalIn += trans.amount : totalOut += trans.amount;
      }
    }

    onSortTransUser();
  }

  void filterTransactionCaisse() {
    transactions.clear();
    for (var trans in allCaisseTransactions) {
      if ((_reference.isEmpty || trans.reference.contains(_reference)) &&
          (_type == 'tout' || trans.type == _type) &&
          (trans.date.isAfter(_fromDate) || myDateFormate.format(trans.date) == myDateFormate.format(_fromDate)) &&
          (trans.date.isBefore(_toDate) || myDateFormate.format(trans.date) == myDateFormate.format(_toDate)) &&
          trans.isCaisseChanged) {
        transactions.add(trans);
        trans.type == 'in' ? totalIn += trans.amount : totalOut += trans.amount;
      }
    }

    onSortTransCaisse();
  }

  void filterTransactionSP() {
    transactionsSP.clear();
    for (var trans in allTransactionsSP) {
      if ((_reference.isEmpty || trans.reference.contains(_reference)) &&
          (_compt == 'tout' || trans.category == _compt) &&
          (_type == 'tout' || trans.type == _type) &&
          (trans.date.isAfter(_fromDate) || myDateFormate.format(trans.date) == myDateFormate.format(_fromDate)) &&
          (trans.date.isBefore(_toDate) || myDateFormate.format(trans.date) == myDateFormate.format(_toDate))) {
        transactionsSP.add(trans);
        trans.type == 'in' ? totalIn += trans.amount : totalOut += trans.amount;
      }
    }
    onSortTransSP();
  }

  void onSortTransUser() {
    switch (_sortColumnIndexTransUser) {
      case 2:
        transactions.sort((tr1, tr2) {
          return !_isAscendingTransUser
              ? tr2.realUserName.compareTo(tr1.realUserName)
              : tr1.realUserName.compareTo(tr2.realUserName);
        });
        break;
      case 4:
        transactions.sort((tr1, tr2) {
          return !_isAscendingTransUser ? tr2.date.compareTo(tr1.date) : tr1.date.compareTo(tr2.date);
        });
        break;
      case 6:
        transactions.sort((a, b) => _isAscendingTransUser
            ? (a.type == 'in' ? a.amount : double.infinity).compareTo(b.type == 'in' ? b.amount : double.infinity)
            : (b.type == 'in' ? b.amount : -double.infinity).compareTo(a.type == 'in' ? a.amount : -double.infinity));
        break;
      case 7:
        transactions.sort((a, b) => _isAscendingTransUser
            ? (a.type == 'out' ? a.amount : double.infinity).compareTo(b.type == 'out' ? b.amount : double.infinity)
            : (b.type == 'out' ? b.amount : -double.infinity).compareTo(a.type == 'out' ? a.amount : -double.infinity));
        break;
    }
  }

  void onSortTransCaisse() {
    switch (_sortColumnIndexTransCaisse) {
      case 2:
        transactions.sort((tr1, tr2) {
          return !_isAscendingTransCaisse
              ? tr2.realUserName.compareTo(tr1.realUserName)
              : tr1.realUserName.compareTo(tr2.realUserName);
        });
        break;
      case 4:
        transactions.sort((tr1, tr2) {
          return !_isAscendingTransCaisse ? tr2.date.compareTo(tr1.date) : tr1.date.compareTo(tr2.date);
        });
        break;
      case 6:
        transactions.sort((a, b) => _isAscendingTransCaisse
            ? (a.type == 'in' ? a.amount : double.infinity).compareTo(b.type == 'in' ? b.amount : double.infinity)
            : (b.type == 'in' ? b.amount : -double.infinity).compareTo(a.type == 'in' ? a.amount : -double.infinity));
        break;
      case 7:
        transactions.sort((a, b) => _isAscendingTransCaisse
            ? (a.type == 'out' ? a.amount : double.infinity).compareTo(b.type == 'out' ? b.amount : double.infinity)
            : (b.type == 'out' ? b.amount : -double.infinity).compareTo(a.type == 'out' ? a.amount : -double.infinity));
        break;
    }
  }

  void onSortTransSP() {
    switch (_sortColumnIndexTransSP) {
      case 3:
        transactionsSP.sort((tr1, tr2) {
          return !_isAscendingTransSP ? tr2.date.compareTo(tr1.date) : tr1.date.compareTo(tr2.date);
        });
        break;
      case 5:
        transactionsSP.sort((a, b) => _isAscendingTransSP
            ? (a.type == 'in' ? a.amount : double.infinity).compareTo(b.type == 'in' ? b.amount : double.infinity)
            : (b.type == 'in' ? b.amount : -double.infinity).compareTo(a.type == 'in' ? a.amount : -double.infinity));
        break;
      case 6:
        transactionsSP.sort((a, b) => _isAscendingTransSP
            ? (a.type == 'out' ? a.amount : double.infinity).compareTo(b.type == 'out' ? b.amount : double.infinity)
            : (b.type == 'out' ? b.amount : -double.infinity).compareTo(a.type == 'out' ? a.amount : -double.infinity));
        break;
    }
  }

  void _newTransaction(BuildContext context) async => await createDialog(context, const SelectTransactionCategoty());

  @override
  void initState() {
    loadData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    transactionCategory = context.watch<Filter>().transactionCategory;
    _compt = context.watch<Filter>().compt;
    _search = context.watch<Filter>().search;

    totalIn = 0;
    totalOut = 0;
    if (transactionCategory == 'users') {
      filterTransactionUser();
    } else if (transactionCategory == 'caisse') {
      filterTransactionCaisse();
    } else if (transactionCategory == 'specials') {
      filterTransactionSP();
    }

    List<DataColumn> columnsTrans = [
      dataColumn(context, ''),
      dataColumn(context, 'Reference'),
      sortableDataColumn(
          context,
          'Name',
          (columnIndex, ascending) => setState(() {
                _sortColumnIndexTransUser = columnIndex;
                _isAscendingTransUser = ascending;
              })),
      dataColumn(context, 'Category'),
      sortableDataColumn(
          context,
          'Date',
          (columnIndex, ascending) => setState(() {
                _sortColumnIndexTransUser = columnIndex;
                _isAscendingTransUser = ascending;
              })),
      dataColumn(context, 'Type'),
      sortableDataColumn(
          context,
          'Entrie',
          (columnIndex, ascending) => setState(() {
                _sortColumnIndexTransUser = columnIndex;
                _isAscendingTransUser = ascending;
              })),
      sortableDataColumn(
          context,
          'Sortie',
          (columnIndex, ascending) => setState(() {
                _sortColumnIndexTransUser = columnIndex;
                _isAscendingTransUser = ascending;
              })),
      dataColumn(context, 'Solde User'),
      dataColumn(context, 'Note'),
    ];
    List<DataColumn> columnsTransCaisse = [
      dataColumn(context, ''),
      dataColumn(context, 'Reference'),
      sortableDataColumn(
          context,
          'Name',
          (columnIndex, ascending) => setState(() {
                _sortColumnIndexTransCaisse = columnIndex;
                _isAscendingTransCaisse = ascending;
              })),
      dataColumn(context, 'Category'),
      sortableDataColumn(
          context,
          'Date',
          (columnIndex, ascending) => setState(() {
                _sortColumnIndexTransCaisse = columnIndex;
                _isAscendingTransCaisse = ascending;
              })),
      dataColumn(context, 'Type'),
      sortableDataColumn(
          context,
          'Entrie',
          (columnIndex, ascending) => setState(() {
                _sortColumnIndexTransCaisse = columnIndex;
                _isAscendingTransCaisse = ascending;
              })),
      sortableDataColumn(
          context,
          'Sortie',
          (columnIndex, ascending) => setState(() {
                _sortColumnIndexTransCaisse = columnIndex;
                _isAscendingTransCaisse = ascending;
              })),
      dataColumn(context, 'Solde Caisse'),
      dataColumn(context, 'Note'),
    ];
    List<DataColumn> columnsTransSP = [
      dataColumn(context, ''),
      dataColumn(context, 'Reference'),
      dataColumn(context, 'Category'),
      sortableDataColumn(
          context,
          'Date',
          (columnIndex, ascending) => setState(() {
                _sortColumnIndexTransSP = columnIndex;
                _isAscendingTransSP = ascending;
              })),
      dataColumn(context, 'Type'),
      sortableDataColumn(
          context,
          'Entrie',
          (columnIndex, ascending) => setState(() {
                _sortColumnIndexTransSP = columnIndex;
                _isAscendingTransSP = ascending;
              })),
      sortableDataColumn(
          context,
          'Sortie',
          (columnIndex, ascending) => setState(() {
                _sortColumnIndexTransSP = columnIndex;
                _isAscendingTransSP = ascending;
              })),
      dataColumn(context, 'Solde'),
      dataColumn(context, 'Note'),
    ];

    List<DataRow> rowsTrans = transactions
        .map((transaction) => DataRow(
              onSelectChanged: ((value) async => await createDialog(
                  context,
                  dismissable: true,
                  PrintTransaction(
                    source: transaction.source,
                    type: transaction.type,
                    reference: transaction.reference,
                    user: transaction.realUserName,
                    amount: transaction.amount,
                    solde: transaction.soldeUser,
                    date: myDateFormate.format(transaction.date),
                    reciver: transaction.reciver,
                    amountOnLetter: transaction.amountOnLetter,
                    intermediates: transaction.intermediates,
                    printingNotes: transaction.printingNotes,
                  ))),
              cells: [
                dataCell(context, (transactions.indexOf(transaction) + 1).toString()),
                dataCell(context, transaction.reference),
                dataCell(context, transaction.realUserName, textAlign: TextAlign.start),
                dataCell(context, getText(sources, transaction.source)),
                dataCell(context, myDateFormate.format(transaction.date)),
                dataCell(context, transaction.type == 'in' ? 'Entrie' : 'Sortie'),
                dataCell(context, myCurrency(transaction.type == 'in' ? transaction.amount : 0),
                    textAlign: TextAlign.end),
                dataCell(context, myCurrency(transaction.type == 'out' ? transaction.amount : 0),
                    textAlign: TextAlign.end),
                dataCell(context, transaction.soldeUser == -0.01 ? '/' : myCurrency(transaction.soldeUser),
                    textAlign: TextAlign.end),
                DataCell(ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: getWidth(context, .18)),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Tooltip(
                      message: transaction.note,
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        transaction.note,
                        overflow: TextOverflow.ellipsis,
                        textDirection: TextDirection.rtl,
                        style: const TextStyle(fontFamily: 'IBM'),
                      ),
                    ),
                  ),
                )),
              ],
            ))
        .toList();
    List<DataRow> rowsTransCaisse = transactions
        .map((transaction) => DataRow(
              onSelectChanged: ((value) async => await createDialog(
                  context,
                  dismissable: true,
                  PrintTransaction(
                    source: transaction.source,
                    type: transaction.type,
                    reference: transaction.reference,
                    user: transaction.realUserName,
                    amount: transaction.amount,
                    solde: transaction.soldeUser,
                    date: myDateFormate.format(transaction.date),
                    reciver: transaction.reciver,
                    amountOnLetter: transaction.amountOnLetter,
                    intermediates: transaction.intermediates,
                    printingNotes: transaction.printingNotes,
                  ))),
              cells: [
                dataCell(context, (transactions.indexOf(transaction) + 1).toString()),
                dataCell(context, transaction.reference),
                dataCell(context, transaction.realUserName, textAlign: TextAlign.start),
                dataCell(context, getText(sources, transaction.source)),
                dataCell(context, myDateFormate.format(transaction.date)),
                dataCell(context, transaction.type == 'in' ? 'Entrie' : 'Sortie'),
                dataCell(context, myCurrency(transaction.type == 'in' ? transaction.amount : 0),
                    textAlign: TextAlign.end),
                dataCell(context, myCurrency(transaction.type == 'out' ? transaction.amount : 0),
                    textAlign: TextAlign.end),
                dataCell(context, myCurrency(transaction.soldeCaisse), textAlign: TextAlign.end),
                DataCell(ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: getWidth(context, .18)),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Tooltip(
                      message: transaction.note,
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        transaction.note,
                        overflow: TextOverflow.ellipsis,
                        textDirection: TextDirection.rtl,
                        style: const TextStyle(fontFamily: 'IBM'),
                      ),
                    ),
                  ),
                )),
              ],
            ))
        .toList();
    List<DataRow> rowsTransSP = transactionsSP
        .map((transaction) => DataRow(
              onSelectChanged: ((value) async => await createDialog(
                  context,
                  dismissable: true,
                  PrintTransaction(
                    source: 'special',
                    type: transaction.type,
                    reference: transaction.reference,
                    user: getText(compts, transaction.category),
                    amount: transaction.amount,
                    solde: transaction.solde,
                    date: myDateFormate.format(transaction.date),
                    reciver: transaction.reciver,
                    amountOnLetter: transaction.amountOnLetter,
                    intermediates: transaction.intermediates,
                    printingNotes: transaction.printingNotes,
                  ))),
              cells: [
                dataCell(context, (transactionsSP.indexOf(transaction) + 1).toString()),
                dataCell(context, transaction.reference),
                dataCell(context, getText(compts, transaction.category), textAlign: TextAlign.start),
                dataCell(context, myDateFormate.format(transaction.date)),
                dataCell(context, transaction.type == 'in' ? 'Entrie' : 'Sortie'),
                dataCell(context, myCurrency(transaction.type == 'in' ? transaction.amount : 0),
                    textAlign: TextAlign.end),
                dataCell(context, myCurrency(transaction.type == 'out' ? transaction.amount : 0),
                    textAlign: TextAlign.end),
                dataCell(context, transaction.solde == -0.01 ? '/' : myCurrency(transaction.solde),
                    textAlign: TextAlign.end),
                DataCell(ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: getWidth(context, .18)),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Tooltip(
                      message: transaction.note,
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        transaction.note,
                        overflow: TextOverflow.ellipsis,
                        textDirection: TextDirection.rtl,
                        style: const TextStyle(fontFamily: 'IBM'),
                      ),
                    ),
                  ),
                )),
              ],
            ))
        .toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        mini: true,
        onPressed: () => _newTransaction(context),
        tooltip: 'New Transaction',
        child: const Icon(Icons.add),
      ),
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
          SizedBox(width: getWidth(context, .45), child: const Divider()),
          const SizedBox(width: double.minPositive, height: 8.0),
          Expanded(
              child: isloading
                  ? myProgress()
                  : transactionCategory == 'users'
                      ? transactions.isEmpty
                          ? SizedBox(width: getWidth(context, .60), child: emptyList())
                          : myScorallable(
                              dataTable(
                                context,
                                isAscending: _isAscendingTransUser,
                                sortColumnIndex: _sortColumnIndexTransUser,
                                columns: columnsTrans,
                                rows: rowsTrans,
                              ),
                              _searchControllerH,
                              _searchControllerV)
                      : transactionCategory == 'caisse'
                          ? transactions.isEmpty
                              ? SizedBox(width: getWidth(context, .60), child: emptyList())
                              : myScorallable(
                                  dataTable(
                                    context,
                                    isAscending: _isAscendingTransCaisse,
                                    sortColumnIndex: _sortColumnIndexTransCaisse,
                                    columns: columnsTransCaisse,
                                    rows: rowsTransCaisse,
                                  ),
                                  _searchControllerH,
                                  _searchControllerV)
                          : transactionCategory == 'specials'
                              ? transactionsSP.isEmpty
                                  ? SizedBox(width: getWidth(context, .60), child: emptyList())
                                  : myScorallable(
                                      dataTable(
                                        context,
                                        isAscending: _isAscendingTransSP,
                                        sortColumnIndex: _sortColumnIndexTransSP,
                                        columns: columnsTransSP,
                                        rows: rowsTransSP,
                                      ),
                                      _searchControllerH,
                                      _searchControllerV)
                              : const SizedBox()),
          SizedBox(width: getWidth(context, .52), child: const Divider()),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              totalItem(context, 'Total Entrie', myCurrency(totalIn), isExpanded: false),
              totalItem(context, 'Total Sortie', myCurrency(totalOut), isExpanded: false),
              totalItem(context, 'Total', myCurrency(totalIn - totalOut), isExpanded: false),
            ],
          ),
          mySizedBox(context),
        ]),
      ),
    );
  }

  Widget searchBar() {
    Map<String, String> transactionsCategorys = {
      'users': 'Users',
      'caisse': 'Caisse',
      'specials': 'Specials',
    };
    Map<String, String> usersCategorys = {
      'tout': 'Tout',
      'user': 'User',
      'loan': 'Loan',
      'deposit': 'Deposit',
    };
    Map<String, String> comptsSearch = {
      'tout': 'Tout',
      'caisse': 'Caisse',
      'reserve': 'Reserve',
      'reserveProfit': 'Reserve Profit',
      'donation': 'Donation',
      'zakat': 'Zakat',
    };
    Map<String, String> transactionsTypesSearch = {
      'tout': 'Tout',
      'in': 'Entrie',
      'out': 'Sortie',
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
                child: Text('Category', style: TextStyle(fontSize: 14)),
              ),
              myDropDown(
                context,
                value: transactionCategory,
                items: transactionsCategorys.entries.map((item) {
                  return DropdownMenuItem(
                    value: getKeyFromValue(transactionsCategorys, item.value),
                    alignment: AlignmentDirectional.center,
                    child: Text(item.value),
                  );
                }).toList(),
                onChanged: (value) => setState(() {
                  context.read<Filter>().change(transactionCategory: value.toString());
                  context.read<Filter>().resetFilter();
                  _reference = '';
                  _userCategory = 'tout';
                  _searchController.clear();
                  _referenceController.clear();
                }),
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
                color: Colors.grey,
                items: ['Tout', ...years].map((item) {
                  return DropdownMenuItem(
                    value: item == 'Tout' ? 'tout' : item,
                    alignment: AlignmentDirectional.center,
                    child: Text(item),
                  );
                }).toList(),
                onChanged: (value) {
                  if (transactionFilterYear != value) {
                    transactionFilterYear = value;
                    Navigator.pushReplacement(
                        context, MaterialPageRoute(builder: (context) => const MyApp(index: 'tr')));
                  }
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
                child: Text('Reference', style: TextStyle(fontSize: 14)),
              ),
              SizedBox(
                height: getHeight(context, textFeildHeight),
                width: getWidth(context, dropDownWidth),
                child: TextField(
                  controller: _referenceController,
                  onSubmitted: (value) => setState(() => _reference = value),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                  decoration: textInputDecoration(
                    hint: '...',
                    borderColor: _reference.isEmpty ? Colors.grey : primaryColor,
                    suffixIcon: _referenceController.text.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              setState(() {
                                _referenceController.clear();
                                _reference = '';
                              });
                            },
                            icon: const Icon(Icons.clear, size: 20.0)),
                  ),
                ),
              ),
            ],
          ),
          mySizedBox(context),
          if (transactionCategory == 'specials')
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 8.0),
                  child: Text('Category', style: TextStyle(fontSize: 14)),
                ),
                myDropDown(
                  context,
                  value: _compt,
                  width: getWidth(context, .1),
                  color: _compt == 'tout' ? Colors.grey : primaryColor,
                  items: comptsSearch.entries.map((item) {
                    return DropdownMenuItem(
                      value: getKeyFromValue(comptsSearch, item.value),
                      alignment: AlignmentDirectional.center,
                      child: Text(item.value),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => context.read<Filter>().change(compt: value.toString())),
                ),
              ],
            ),
          if (transactionCategory == 'users')
            autoComplete(
              onSeleted: (item) => setState(() => context.read<Filter>().change(search: item)),
              optionsBuilder: (textEditingValue) =>
                  userNames.where((item) => item.toLowerCase().contains(textEditingValue.text.toLowerCase())),
            ),
          if (transactionCategory == 'users') mySizedBox(context),
          if (transactionCategory == 'users')
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 8.0),
                  child: Text('Category', style: TextStyle(fontSize: 14)),
                ),
                myDropDown(
                  context,
                  value: _userCategory,
                  color: _userCategory == 'tout' ? Colors.grey : primaryColor,
                  items: usersCategorys.entries.map((item) {
                    return DropdownMenuItem(
                      value: getKeyFromValue(usersCategorys, item.value),
                      alignment: AlignmentDirectional.center,
                      child: Text(item.value),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _userCategory = value.toString()),
                ),
              ],
            ),
          if (transactionCategory != 'caisse') mySizedBox(context),
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
                items: transactionsTypesSearch.entries.map((item) {
                  return DropdownMenuItem(
                    value: getKeyFromValue(transactionsTypesSearch, item.value),
                    alignment: AlignmentDirectional.center,
                    child: Text(item.value),
                  );
                }).toList(),
                onChanged: (value) => setState(() {
                  _type = value.toString();
                }),
              ),
            ],
          ),
          if (_year != 'tout')
            Row(
              children: [
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
                      width: getWidth(context, .072),
                      color: _month == 'tout' ? Colors.grey : primaryColor,
                      items: ['Tout', ...monthsOfYear].map((item) {
                        return DropdownMenuItem(
                          value: item == 'Tout' ? 'tout' : item,
                          alignment: AlignmentDirectional.center,
                          child: Text(item),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() {
                        _month = value.toString();
                        if (_month == 'tout') {
                          _fromDate = DateTime(int.parse(_year));
                          _toDate = DateTime(int.parse(_year) + 1).subtract(const Duration(seconds: 1));
                        } else {
                          _fromDate = DateTime(int.parse(_year), monthsOfYear.indexOf(_month) + 1, 1);
                          _toDate = DateTime(int.parse(_year), monthsOfYear.indexOf(_month) + 2, 1)
                              .subtract(const Duration(seconds: 1));
                        }
                      }),
                    )
                  ],
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
                  'From',
                  style: TextStyle(fontSize: 14),
                ),
              ),
              InkWell(
                onTap: () async {
                  final DateTime? selected = await showDatePicker(
                    context: context,
                    initialDate: _fromDate,
                    initialEntryMode: DatePickerEntryMode.input,
                    firstDate: _year == 'tout' ? DateTime(int.parse(years.last)) : DateTime(int.parse(_year)),
                    lastDate: _toDate,
                  );
                  if (selected != null && selected != _fromDate) {
                    setState(() {
                      _fromDate = selected;
                    });
                  }
                },
                child: Container(
                    height: getHeight(context, textFeildHeight),
                    width: getWidth(context, dropDownWidth),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                        color: ((_year == 'tout' && _fromDate == DateTime(int.parse(years.last))) ||
                                (_year != 'tout' && _fromDate == DateTime(int.parse(_year))))
                            ? Colors.grey
                            : primaryColor,
                      ),
                      borderRadius: const BorderRadius.all(Radius.circular(12)),
                    ),
                    child: myText(myDateFormate.format(_fromDate))),
              ),
            ],
          ),
          mySizedBox(context),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 8.0),
                child: Text('To', style: TextStyle(fontSize: 14)),
              ),
              InkWell(
                onTap: () async {
                  final DateTime? selected = await showDatePicker(
                    context: context,
                    initialDate: _toDate,
                    firstDate: _fromDate,
                    initialEntryMode: DatePickerEntryMode.input,
                    lastDate: _year == 'tout'
                        ? DateTime(int.parse(years.first) + 1).subtract(const Duration(seconds: 1))
                        : DateTime(int.parse(_year) + 1).subtract(const Duration(seconds: 1)),
                  );
                  if (selected != null && selected != _toDate) {
                    setState(() {
                      _toDate = selected;
                    });
                  }
                },
                child: Container(
                    height: getHeight(context, textFeildHeight),
                    width: getWidth(context, dropDownWidth),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                        color: ((_year == 'tout' &&
                                    _toDate ==
                                        DateTime(int.parse(years.first) + 1).subtract(const Duration(seconds: 1))) ||
                                (_year != 'tout' &&
                                    _toDate == DateTime(int.parse(_year) + 1).subtract(const Duration(seconds: 1))))
                            ? Colors.grey
                            : primaryColor,
                      ),
                      borderRadius: const BorderRadius.all(Radius.circular(12)),
                    ),
                    child: myText(myDateFormate.format(_toDate))),
              ),
            ],
          ),
          mySizedBox(context),
          IconButton(
            icon: Icon(
              Icons.calendar_month,
              color: primaryColor,
            ),
            onPressed: () async {
              final DateTime? selected = await showDatePicker(
                context: context,
                initialDate: _fromDate,
                initialEntryMode: DatePickerEntryMode.input,
                firstDate: _year == 'tout' ? DateTime(int.parse(years.last)) : DateTime(int.parse(_year)),
                lastDate: _year == 'tout'
                    ? DateTime(int.parse(years.first) + 1).subtract(const Duration(seconds: 1))
                    : DateTime(int.parse(_year) + 1).subtract(const Duration(seconds: 1)),
              );
              if (selected != null && selected != _fromDate) {
                setState(() {
                  _fromDate = selected;
                  _toDate = selected.add(const Duration(seconds: 86399));
                });
              }
            },
          ),
          IconButton(
              icon: Icon(
                Icons.file_download,
                color: primaryColor,
              ),
              onPressed: () => createExcel(
                    'Transaction',
                    [
                      [
                        '#',
                        'Reference',
                        if (transactionCategory == 'specials') 'Category' else 'Name',
                        if (transactionCategory == 'caisse' || transactionCategory == 'users') 'Source',
                        'Date',
                        'Type',
                        'Entrie',
                        'Sortie',
                        if (transactionCategory == 'caisse')
                          'Solde Caisse'
                        else if (transactionCategory == 'specials')
                          'Solde'
                        else
                          'Solde User',
                        'Note',
                      ],
                      if (transactionCategory == 'users')
                        ...transactions.map((trans) => [
                              transactions.indexOf(trans) + 1,
                              trans.reference,
                              trans.realUserName,
                              getText(sources, trans.source),
                              myDateFormate.format(trans.date),
                              trans.type == 'in' ? 'Entrie' : 'Sortie',
                              trans.type == 'in' ? trans.amount : zero,
                              trans.type == 'out' ? trans.amount : zero,
                              trans.soldeUser != -0.01 ? trans.soldeUser : '/',
                              trans.note,
                            ])
                      else if (transactionCategory == 'caisse')
                        ...transactions.map((trans) => [
                              transactions.indexOf(trans) + 1,
                              trans.reference,
                              trans.realUserName,
                              getText(sources, trans.source),
                              myDateFormate.format(trans.date),
                              trans.type == 'in' ? 'Entrie' : 'Sortie',
                              trans.type == 'in' ? trans.amount : zero,
                              trans.type == 'out' ? trans.amount : zero,
                              trans.soldeCaisse,
                              trans.note,
                            ])
                      else if (transactionCategory == 'specials')
                        ...transactionsSP.map((trans) => [
                              transactionsSP.indexOf(trans) + 1,
                              trans.reference,
                              trans.category,
                              myDateFormate.format(trans.date),
                              trans.type == 'in' ? 'Entrie' : 'Sortie',
                              trans.type == 'in' ? trans.amount : zero,
                              trans.type == 'out' ? trans.amount : zero,
                              trans.solde != -0.01 ? trans.solde : '/',
                              trans.note,
                            ])
                    ],
                  )),
          if (transactionCategory == 'users' || transactionCategory == 'caisse')
            IconButton(
              icon: Icon(
                Icons.print,
                color: primaryColor,
              ),
              onPressed: () {
                createDialog(
                  context,
                  SizedBox(
                    width: getWidth(context, .7),
                    child: printPage(),
                  ),
                );
              },
            ),
          if (_search.isNotEmpty ||
              _reference.isNotEmpty ||
              _userCategory != 'tout' ||
              _compt != 'tout' ||
              _type != 'tout' ||
              _month != 'tout' ||
              (_year == 'tout' && _fromDate != DateTime(int.parse(years.last))) ||
              (_year != 'tout' && _fromDate != DateTime(int.parse(_year))) ||
              (_year == 'tout' &&
                  _toDate != DateTime(int.parse(years.first) + 1).subtract(const Duration(seconds: 1))) ||
              (_year != 'tout' && _toDate != DateTime(int.parse(_year) + 1).subtract(const Duration(seconds: 1))))
            IconButton(
              icon: Icon(
                Icons.update,
                color: primaryColor,
              ),
              onPressed: () => setState(() {
                context.read<Filter>().resetFilter();
                _reference = '';
                _searchController.clear();
                _referenceController.clear();
                _userCategory = 'tout';
                _type = 'tout';
                _month = 'tout';
                _fromDate = _year == 'tout' ? DateTime(int.parse(years.last)) : DateTime(int.parse(_year));
                _toDate = _year == 'tout'
                    ? DateTime(int.parse(years.first) + 1).subtract(const Duration(seconds: 1))
                    : DateTime(int.parse(_year) + 1).subtract(const Duration(seconds: 1));
              }),
            ),
        ],
      ),
    );
  }

  Widget autoComplete({
    required Function(String) onSeleted,
    required Iterable<String> Function(TextEditingValue) optionsBuilder,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 8.0),
          child: Text('Name', style: TextStyle(fontSize: 14)),
        ),
        Autocomplete<String>(
          onSelected: onSeleted,
          optionsBuilder: optionsBuilder,
          fieldViewBuilder: (
            context,
            textEditingController,
            focusNode,
            onFieldSubmitted,
          ) {
            _searchController = textEditingController;
            _searchController.text = _search;

            return SizedBox(
              height: getHeight(context, textFeildHeight),
              width: getWidth(context, .18),
              child: TextField(
                controller: _searchController,
                focusNode: focusNode,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
                onSubmitted: ((value) {
                  if (optionsBuilder(_searchController.value).first.isNotEmpty) {
                    setState(
                        () => context.read<Filter>().change(search: optionsBuilder(_searchController.value).first));
                    onFieldSubmitted;
                  }
                }),
                decoration: textInputDecoration(
                  hint: 'Search...',
                  borderColor: _searchController.text.isEmpty ? Colors.grey : primaryColor,
                  prefixIcon: const Icon(Icons.search, size: 20.0),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              context.read<Filter>().resetFilter();
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
                  constraints: BoxConstraints(maxHeight: getHeight(context, .2), maxWidth: getWidth(context, .18)),
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
    );
  }

  Widget printPage() {
    pw.Text data(String text, {double fontSize = 10}) => pw.Text(text, style: pw.TextStyle(fontSize: fontSize));

    pw.Text title(String text) => pw.Text(text, style: pw.TextStyle(fontWeight: pw.FontWeight.bold));
    final pdf = pw.Document();
    List<Map<String, String>> printTransactions = [];
    Map<String, String> _categories = {
      'user': 'مساهم',
      'loan': 'سلف',
      'deposit': 'وديعة',
    };

    transactions.sort((a, b) => a.date.compareTo(b.date));

    if (transactionCategory == 'users') {
      transactions.map((trans) {
        printTransactions.add({
          'date': myDateFormate.format(trans.date),
          'source': _categories[trans.source] ?? '',
          'name': trans.realUserName,
          'in': myCurrency(trans.type == 'in' ? trans.amount : 0),
          'out': myCurrency(trans.type == 'out' ? trans.amount : 0),
          'solde': trans.soldeUser != -0.01 ? myCurrency(trans.soldeUser) : '/'
        });
      }).toList();
    } else if (transactionCategory == 'caisse') {
      transactions.map((trans) {
        printTransactions.add({
          'date': myDateFormate.format(trans.date),
          'source': getText(sources, trans.source),
          'name': trans.realUserName,
          'in': myCurrency(trans.type == 'in' ? trans.amount : 0),
          'out': myCurrency(trans.type == 'out' ? trans.amount : 0),
          'solde': myCurrency(trans.soldeCaisse)
        });
      }).toList();
    }

    pdf.addPage(pdfPage(
      pdfPageFormat: PdfPageFormat.a4,
      build: [
        pw.Center(child: title(_search)),
        pw.SizedBox(height: 10),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
          children: [
            pw.Row(children: [
              data(myDateFormate.format(_toDate), fontSize: 12),
              title('إلى     '),
            ]),
            pw.Row(children: [
              data(myDateFormate.format(_fromDate), fontSize: 12),
              title('من    '),
            ]),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Table.fromTextArray(
          headers: [
            'التاريخ',
            if (_search.isEmpty || transactionCategory == 'caisse') 'اﻹسم',
            'النوع',
            'اﻹيداعات',
            'السحوبات',
            'الرصيد',
          ],
          data: printTransactions
              .map((trans) => [
                    trans['date'],
                    if (_search.isEmpty || transactionCategory == 'caisse') trans['name'],
                    trans['source'],
                    trans['in'],
                    trans['out'],
                    trans['solde'],
                  ])
              .toList(),
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
            0: pw.Alignment.center,
            1: pw.Alignment.center,
            2: _search.isEmpty || transactionCategory == 'caisse' ? pw.Alignment.center : pw.Alignment.centerRight,
            3: pw.Alignment.centerRight,
            4: pw.Alignment.centerRight,
            if (_search.isEmpty || transactionCategory == 'caisse') 5: pw.Alignment.centerRight,
          },
        ),
      ],
    ));

    return pdfPreview(context, pdf, 'Transactions');
  }
}
