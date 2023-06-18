import 'dart:collection';

import 'package:fairsplit/models/transactio_others.dart';
import 'package:fairsplit/providers/filter.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../shared/functions.dart';
import '../shared/lists.dart';
import '../models/transaction.dart';
import '../models/transaction_sp.dart';
import '../screens/add_transaction.dart';
import '../shared/constants.dart';
import '../shared/widgets.dart';

class Transactions extends StatefulWidget {
  const Transactions({Key? key}) : super(key: key);

  @override
  State<Transactions> createState() => _TransactionsState();
}

class _TransactionsState extends State<Transactions> {
  List<Transaction> allTransactions = [], transactions = [], allCaisseTransactions = [];
  List<TransactionSP> allTransactionsSP = [], transactionsSP = [];
  List<TransactionOther> allLoanTransactions = [],
      allDepositTransactions = [],
      loanTransactions = [],
      depositTransactions = [];
  var userNames = <String>{};
  var loanNames = <String>{};
  var depositNames = <String>{};
  var years = <String>{'1900'};

  bool isloading = true;
  String transactionCategory = 'caisse'; //caisse users loans deposits specials
  String _compt = 'tout'; // caisse reserve donation zakat
  String _search = ''; //search by user name
  String _year = 'tout';
  String _type = 'tout'; // entrie sortie

  double totalIn = 0;
  double totalOut = 0;

  final DateTime today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

  DateTime _fromDate = DateTime.now();
  DateTime _toDate = DateTime.now();

  int? _sortColumnIndexTrans = 2;
  bool _isAscendingTrans = false;
  int? _sortColumnIndexTransCaisse = 3;
  bool _isAscendingTransCaisse = false;
  int? _sortColumnIndexTransSP = 2;
  bool _isAscendingTransSP = false;
  int? _sortColumnIndexTransLoan = 2;
  bool _isAscendingTransLoan = false;
  int? _sortColumnIndexTransDeposit = 2;
  bool _isAscendingTransDeposit = false;

  TextEditingController _controller = TextEditingController();

  void loadData() async {
    var res = await sqlQuery(selectUrl, {
      'sql1': 'SELECT * FROM Transaction;',
      'sql2': 'SELECT * FROM TransactionSP;',
      'sql3': 'SELECT * FROM TransactionOthers;',
    });
    var dataTransaction = res[0];
    var dataTransactionSP = res[1];
    var dataTransactionOther = res[2];

    years.clear();

    for (var ele in dataTransaction) {
      allTransactions.add(Transaction(
        transactionId: int.parse(ele['transactionId']),
        userName: ele['userName'],
        year: int.parse(ele['year']),
        date: DateTime.parse(ele['date']),
        type: ele['type'],
        amount: double.parse(ele['amount']),
        soldeUser: double.parse(ele['soldeUser']),
        soldeCaisse: double.parse(ele['soldeCaisse']),
        note: ele['note'],
      ));

      userNames.add(ele['userName']);
      years.add(ele['year']);
    }

    allCaisseTransactions.addAll(allTransactions);

    for (var ele in dataTransactionSP) {
      allTransactionsSP.add(TransactionSP(
        transactionId: int.parse(ele['transactionId']),
        category: ele['category'],
        year: int.parse(ele['year']),
        type: ele['type'],
        date: DateTime.parse(ele['date']),
        amount: double.parse(ele['amount']),
        solde: double.parse(ele['solde']),
        note: ele['note'],
      ));

      allCaisseTransactions.add(Transaction(
        transactionId: int.parse(ele['transactionId']),
        userName: getText(ele['category']),
        source: ele['category'],
        year: int.parse(ele['year']),
        date: DateTime.parse(ele['date']),
        type: ele['type'],
        amount: double.parse(ele['amount']),
        soldeCaisse: double.parse(ele['soldeCaisse']),
        note: ele['note'],
      ));

      years.add(ele['year']);
    }

    for (var ele in dataTransactionOther) {
      TransactionOther other = TransactionOther(
        transactionId: int.parse(ele['transactionId']),
        userName: ele['userName'],
        category: ele['category'],
        year: int.parse(ele['year']),
        date: DateTime.parse(ele['date']),
        type: ele['type'],
        amount: double.parse(ele['amount']),
        soldeUser: double.parse(ele['soldeUser']),
        soldeCaisse: double.parse(ele['soldeCaisse']),
        note: ele['note'],
      );
      Transaction trans = Transaction(
        transactionId: other.transactionId,
        userName: other.userName,
        source: other.category,
        year: other.year,
        date: other.date,
        type: other.type,
        amount: other.amount,
        soldeCaisse: other.soldeCaisse,
        note: other.note,
      );

      if (other.category == 'loan') {
        allLoanTransactions.add(other);
        loanNames.add(other.userName);
      } else {
        allDepositTransactions.add(other);
        depositNames.add(other.userName);
      }

      allCaisseTransactions.add(trans);
      years.add(other.year.toString());
    }

    if (years.isEmpty) years.add(currentYear.toString());

    if (userNames.isNotEmpty) userNames = SplayTreeSet.from(userNames);
    if (loanNames.isNotEmpty) loanNames = SplayTreeSet.from(loanNames);
    if (depositNames.isNotEmpty) depositNames = SplayTreeSet.from(depositNames);
    years = SplayTreeSet.from(years, (a, b) => b.compareTo(a));

    _fromDate = DateTime(int.parse(years.last));
    _toDate = today.add(const Duration(seconds: 86399));

    setState(() => isloading = false);
  }

  void filterTransaction() {
    transactions.clear();
    for (var trans in allTransactions) {
      if ((_search.isEmpty || trans.userName == _search) &&
          (_year == 'tout' || trans.year.toString() == _year) &&
          (_type == 'tout' || trans.type == _type) &&
          (trans.date.isAfter(_fromDate) || trans.date == _fromDate) &&
          (trans.date.isBefore(_toDate) || trans.date == _toDate)) {
        transactions.add(trans);
        trans.type == 'in' ? totalIn += trans.amount : totalOut += trans.amount;
      }
    }

    onSortTrans();
  }

  void filterTransactionCaisse() {
    allCaisseTransactions.sort((a, b) => b.date.compareTo(a.date));
    for (int i = 0; i < allCaisseTransactions.length - 1; i++) {
      if (allCaisseTransactions[i].soldeCaisse == allCaisseTransactions[i + 1].soldeCaisse) {
        allCaisseTransactions[i].isCaisseChanged = false;
      }
    }

    transactions.clear();
    for (var trans in allCaisseTransactions) {
      if ((_year == 'tout' || trans.year.toString() == _year) &&
          (_type == 'tout' || trans.type == _type) &&
          (trans.date.isAfter(_fromDate) || trans.date == _fromDate) &&
          (trans.date.isBefore(_toDate) || trans.date == _toDate) &&
          trans.isCaisseChanged) {
        transactions.add(trans);
        trans.type == 'in' ? totalIn += trans.amount : totalOut += trans.amount;
      }
    }

    // onSortTransCaisse();
  }

  void filterTransactionSP() {
    transactionsSP.clear();
    for (var trans in allTransactionsSP) {
      if ((_compt == 'tout' || trans.category == _compt) &&
          (_year == 'tout' || trans.year.toString() == _year) &&
          (_type == 'tout' || trans.type == _type) &&
          (trans.date.isAfter(_fromDate) || trans.date == _fromDate) &&
          (trans.date.isBefore(_toDate) || trans.date == _toDate)) {
        transactionsSP.add(trans);
        trans.type == 'in' ? totalIn += trans.amount : totalOut += trans.amount;
      }
    }
    onSortTransSP();
  }

  void filterTransactionLoan() {
    loanTransactions.clear();
    for (var trans in allLoanTransactions) {
      if ((_search.isEmpty || trans.userName == _search) &&
          (_year == 'tout' || trans.year.toString() == _year) &&
          (_type == 'tout' || trans.type == _type) &&
          (trans.date.isAfter(_fromDate) || trans.date == _fromDate) &&
          (trans.date.isBefore(_toDate) || trans.date == _toDate)) {
        loanTransactions.add(trans);
        trans.type == 'in' ? totalIn += trans.amount : totalOut += trans.amount;
      }
    }
    onSortTransLoan();
  }

  void filterTransactionDeposit() {
    depositTransactions.clear();
    for (var trans in allDepositTransactions) {
      if ((_search.isEmpty || trans.userName == _search) &&
          (_year == 'tout' || trans.year.toString() == _year) &&
          (_type == 'tout' || trans.type == _type) &&
          (trans.date.isAfter(_fromDate) || trans.date == _fromDate) &&
          (trans.date.isBefore(_toDate) || trans.date == _toDate)) {
        depositTransactions.add(trans);
        trans.type == 'in' ? totalIn += trans.amount : totalOut += trans.amount;
      }
    }
    onSortTransDeposit();
  }

  void onSortTrans() {
    switch (_sortColumnIndexTrans) {
      case 1:
        transactions.sort((tr1, tr2) {
          return !_isAscendingTrans ? tr2.userName.compareTo(tr1.userName) : tr1.userName.compareTo(tr2.userName);
        });
        break;
      case 2:
        transactions.sort((tr1, tr2) {
          return !_isAscendingTrans ? tr2.date.compareTo(tr1.date) : tr1.date.compareTo(tr2.date);
        });
        break;
      case 4:
        transactions.sort(
            (tr1, tr2) => !_isAscendingTrans ? tr2.amount.compareTo(tr1.amount) : tr1.amount.compareTo(tr2.amount));
        transactions.sort((tr1, tr2) => tr1.type.compareTo(tr2.type));
        break;
      case 5:
        transactions.sort(
            (tr1, tr2) => !_isAscendingTrans ? tr2.amount.compareTo(tr1.amount) : tr1.amount.compareTo(tr2.amount));
        transactions.sort((tr1, tr2) => tr2.type.compareTo(tr1.type));
        break;
    }
  }

  void onSortTransCaisse() {
    switch (_sortColumnIndexTransCaisse) {
      case 1:
        transactions.sort((tr1, tr2) {
          return !_isAscendingTransCaisse ? tr2.userName.compareTo(tr1.userName) : tr1.userName.compareTo(tr2.userName);
        });
        break;
      case 3:
        transactions.sort((tr1, tr2) {
          return !_isAscendingTransCaisse ? tr2.date.compareTo(tr1.date) : tr1.date.compareTo(tr2.date);
        });
        break;
      case 5:
        transactions.sort((tr1, tr2) =>
            !_isAscendingTransCaisse ? tr2.amount.compareTo(tr1.amount) : tr1.amount.compareTo(tr2.amount));
        transactions.sort((tr1, tr2) => tr1.type.compareTo(tr2.type));
        break;
      case 6:
        transactions.sort((tr1, tr2) =>
            !_isAscendingTransCaisse ? tr2.amount.compareTo(tr1.amount) : tr1.amount.compareTo(tr2.amount));
        transactions.sort((tr1, tr2) => tr2.type.compareTo(tr1.type));
        break;
    }
  }

  void onSortTransSP() {
    switch (_sortColumnIndexTransSP) {
      case 2:
        transactionsSP.sort((tr1, tr2) {
          return !_isAscendingTransSP ? tr2.date.compareTo(tr1.date) : tr1.date.compareTo(tr2.date);
        });
        break;
      case 4:
        transactionsSP.sort((tr1, tr2) {
          return !_isAscendingTransSP ? tr2.amount.compareTo(tr1.amount) : tr1.amount.compareTo(tr2.amount);
        });
        transactionsSP.sort((tr1, tr2) => tr1.type.compareTo(tr2.type));
        break;
      case 5:
        transactionsSP.sort((tr1, tr2) {
          return !_isAscendingTransSP ? tr2.amount.compareTo(tr1.amount) : tr1.amount.compareTo(tr2.amount);
        });
        transactionsSP.sort((tr1, tr2) => tr2.type.compareTo(tr1.type));
        break;
    }
  }

  void onSortTransLoan() {
    switch (_sortColumnIndexTransLoan) {
      case 1:
        loanTransactions.sort((tr1, tr2) {
          return !_isAscendingTransLoan ? tr2.userName.compareTo(tr1.userName) : tr1.userName.compareTo(tr2.userName);
        });
        break;
      case 2:
        loanTransactions.sort((tr1, tr2) {
          return !_isAscendingTransLoan ? tr2.date.compareTo(tr1.date) : tr1.date.compareTo(tr2.date);
        });
        break;
      case 4:
        loanTransactions.sort(
            (tr1, tr2) => !_isAscendingTransLoan ? tr2.amount.compareTo(tr1.amount) : tr1.amount.compareTo(tr2.amount));
        loanTransactions.sort((tr1, tr2) => tr1.type.compareTo(tr2.type));
        break;
      case 5:
        loanTransactions.sort(
            (tr1, tr2) => !_isAscendingTransLoan ? tr2.amount.compareTo(tr1.amount) : tr1.amount.compareTo(tr2.amount));
        loanTransactions.sort((tr1, tr2) => tr2.type.compareTo(tr1.type));
        break;
    }
  }

  void onSortTransDeposit() {
    switch (_sortColumnIndexTransDeposit) {
      case 1:
        depositTransactions.sort((tr1, tr2) {
          return !_isAscendingTransDeposit
              ? tr2.userName.compareTo(tr1.userName)
              : tr1.userName.compareTo(tr2.userName);
        });
        break;
      case 2:
        depositTransactions.sort((tr1, tr2) {
          return !_isAscendingTransDeposit ? tr2.date.compareTo(tr1.date) : tr1.date.compareTo(tr2.date);
        });
        break;
      case 4:
        depositTransactions.sort((tr1, tr2) =>
            !_isAscendingTransDeposit ? tr2.amount.compareTo(tr1.amount) : tr1.amount.compareTo(tr2.amount));
        depositTransactions.sort((tr1, tr2) => tr1.type.compareTo(tr2.type));
        break;
      case 5:
        depositTransactions.sort((tr1, tr2) =>
            !_isAscendingTransDeposit ? tr2.amount.compareTo(tr1.amount) : tr1.amount.compareTo(tr2.amount));
        depositTransactions.sort((tr1, tr2) => tr2.type.compareTo(tr1.type));
        break;
    }
  }

  void _newTransaction(BuildContext context) async {
    await createDialog(
      context,
      const SelectTransactionCategoty(),
    );
  }

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
    if (transactionCategory == 'caisse') {
      filterTransactionCaisse();
    } else if (transactionCategory == 'users') {
      filterTransaction();
    } else if (transactionCategory == 'specials') {
      filterTransactionSP();
    } else if (transactionCategory == 'loans') {
      filterTransactionLoan();
    } else {
      filterTransactionDeposit();
    }

    List<DataColumn> columnsTransCaisse = [
      dataColumn(context, ''),
      sortableDataColumn(
          context,
          getText('name'),
          (columnIndex, ascending) => setState(() {
                _sortColumnIndexTransCaisse = columnIndex;
                _isAscendingTransCaisse = ascending;
              })),
      dataColumn(context, getText('source')),
      sortableDataColumn(
          context,
          getText('date'),
          (columnIndex, ascending) => setState(() {
                _sortColumnIndexTransCaisse = columnIndex;
                _isAscendingTransCaisse = ascending;
              })),
      dataColumn(context, getText('type')),
      sortableDataColumn(
          context,
          getText('in'),
          (columnIndex, ascending) => setState(() {
                _sortColumnIndexTransCaisse = columnIndex;
                _isAscendingTransCaisse = ascending;
              })),
      sortableDataColumn(
          context,
          getText('out'),
          (columnIndex, ascending) => setState(() {
                _sortColumnIndexTransCaisse = columnIndex;
                _isAscendingTransCaisse = ascending;
              })),
      dataColumn(context, getText('soldeCaisse')),
      dataColumn(context, getText('note')),
    ];
    List<DataColumn> columnsTrans = [
      dataColumn(context, ''),
      sortableDataColumn(
          context,
          getText('name'),
          (columnIndex, ascending) => setState(() {
                _sortColumnIndexTrans = columnIndex;
                _isAscendingTrans = ascending;
              })),
      sortableDataColumn(
          context,
          getText('date'),
          (columnIndex, ascending) => setState(() {
                _sortColumnIndexTrans = columnIndex;
                _isAscendingTrans = ascending;
              })),
      dataColumn(context, getText('type')),
      sortableDataColumn(
          context,
          getText('in'),
          (columnIndex, ascending) => setState(() {
                _sortColumnIndexTrans = columnIndex;
                _isAscendingTrans = ascending;
              })),
      sortableDataColumn(
          context,
          getText('out'),
          (columnIndex, ascending) => setState(() {
                _sortColumnIndexTrans = columnIndex;
                _isAscendingTrans = ascending;
              })),
      dataColumn(context, getText('soldeUser')),
      dataColumn(context, getText('note')),
    ];
    List<DataColumn> columnsTransSP = [
      dataColumn(context, ''),
      dataColumn(context, getText('category')),
      sortableDataColumn(
          context,
          getText('date'),
          (columnIndex, ascending) => setState(() {
                _sortColumnIndexTransSP = columnIndex;
                _isAscendingTransSP = ascending;
              })),
      dataColumn(context, getText('type')),
      sortableDataColumn(
          context,
          getText('in'),
          (columnIndex, ascending) => setState(() {
                _sortColumnIndexTransSP = columnIndex;
                _isAscendingTransSP = ascending;
              })),
      sortableDataColumn(
          context,
          getText('out'),
          (columnIndex, ascending) => setState(() {
                _sortColumnIndexTransSP = columnIndex;
                _isAscendingTransSP = ascending;
              })),
      dataColumn(context, getText('solde')),
      dataColumn(context, getText('note')),
    ];
    List<DataColumn> columnsTransLoan = [
      dataColumn(context, ''),
      sortableDataColumn(
          context,
          getText('name'),
          (columnIndex, ascending) => setState(() {
                _sortColumnIndexTransLoan = columnIndex;
                _isAscendingTransLoan = ascending;
              })),
      sortableDataColumn(
          context,
          getText('date'),
          (columnIndex, ascending) => setState(() {
                _sortColumnIndexTransLoan = columnIndex;
                _isAscendingTransLoan = ascending;
              })),
      dataColumn(context, getText('type')),
      sortableDataColumn(
          context,
          getText('in'),
          (columnIndex, ascending) => setState(() {
                _sortColumnIndexTransLoan = columnIndex;
                _isAscendingTransLoan = ascending;
              })),
      sortableDataColumn(
          context,
          getText('out'),
          (columnIndex, ascending) => setState(() {
                _sortColumnIndexTransLoan = columnIndex;
                _isAscendingTransLoan = ascending;
              })),
      dataColumn(context, getText('soldeUser')),
      dataColumn(context, getText('note')),
    ];
    List<DataColumn> columnsTransDeposit = [
      dataColumn(context, ''),
      sortableDataColumn(
          context,
          getText('name'),
          (columnIndex, ascending) => setState(() {
                _sortColumnIndexTransDeposit = columnIndex;
                _isAscendingTransDeposit = ascending;
              })),
      sortableDataColumn(
          context,
          getText('date'),
          (columnIndex, ascending) => setState(() {
                _sortColumnIndexTransDeposit = columnIndex;
                _isAscendingTransDeposit = ascending;
              })),
      dataColumn(context, getText('type')),
      sortableDataColumn(
          context,
          getText('in'),
          (columnIndex, ascending) => setState(() {
                _sortColumnIndexTransDeposit = columnIndex;
                _isAscendingTransDeposit = ascending;
              })),
      sortableDataColumn(
          context,
          getText('out'),
          (columnIndex, ascending) => setState(() {
                _sortColumnIndexTransDeposit = columnIndex;
                _isAscendingTransDeposit = ascending;
              })),
      dataColumn(context, getText('soldeUser')),
      dataColumn(context, getText('note')),
    ];

    List<DataRow> rowsTransCaisse = transactions
        .map((transaction) => DataRow(
              cells: [
                dataCell(context, (transactions.indexOf(transaction) + 1).toString()),
                dataCell(
                    context,
                    namesHidden
                        ? transaction.source == 'user'
                            ? '1${userNames.toList().indexOf(transaction.userName)}'
                            : transaction.source == 'loan'
                                ? '2${loanNames.toList().indexOf(transaction.userName)}'
                                : transaction.source == 'deposit'
                                    ? '3${depositNames.toList().indexOf(transaction.userName)}'
                                    : '4'
                        : transaction.userName,
                    textAlign: namesHidden ? TextAlign.center : TextAlign.start),
                dataCell(context, getText(transaction.source)),
                dataCell(context, myDateFormate.format(transaction.date)),
                dataCell(
                    context, transaction.type == 'in' ? transactionsTypes['in'] ?? '' : transactionsTypes['out'] ?? ''),
                dataCell(context, transaction.type == 'in' ? myCurrency.format(transaction.amount) : '/',
                    textAlign: transaction.type == 'in' ? TextAlign.end : TextAlign.center),
                dataCell(context, transaction.type == 'out' ? myCurrency.format(transaction.amount) : '/',
                    textAlign: transaction.type == 'out' ? TextAlign.end : TextAlign.center),
                dataCell(context, myCurrency.format(transaction.soldeCaisse), textAlign: TextAlign.end),
                transaction.note.length < 40
                    ? dataCell(context, transaction.note)
                    : DataCell(
                        ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: getWidth(context, .22)),
                          child: Tooltip(
                            message: transaction.note,
                            textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),
                            padding: const EdgeInsets.all(8.0),
                            margin: const EdgeInsets.only(left: 800, right: 100),
                            child: Text(
                              transaction.note,
                              textAlign: TextAlign.start,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ),
                      ),
              ],
            ))
        .toList();
    List<DataRow> rowsTrans = transactions
        .map((transaction) => DataRow(
              cells: [
                dataCell(context, (transactions.indexOf(transaction) + 1).toString()),
                dataCell(context,
                    namesHidden ? userNames.toList().indexOf(transaction.userName).toString() : transaction.userName,
                    textAlign: namesHidden ? TextAlign.center : TextAlign.start),
                dataCell(context, myDateFormate.format(transaction.date)),
                dataCell(
                    context, transaction.type == 'in' ? transactionsTypes['in'] ?? '' : transactionsTypes['out'] ?? ''),
                dataCell(context, transaction.type == 'in' ? myCurrency.format(transaction.amount) : '/',
                    textAlign: transaction.type == 'in' ? TextAlign.end : TextAlign.center),
                dataCell(context, transaction.type == 'out' ? myCurrency.format(transaction.amount) : '/',
                    textAlign: transaction.type == 'out' ? TextAlign.end : TextAlign.center),
                dataCell(context, myCurrency.format(transaction.soldeUser), textAlign: TextAlign.end),
                transaction.note.length < 40
                    ? dataCell(context, transaction.note)
                    : DataCell(
                        ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: getWidth(context, .22)),
                          child: Tooltip(
                            message: transaction.note,
                            textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),
                            padding: const EdgeInsets.all(8.0),
                            margin: const EdgeInsets.only(left: 800, right: 100),
                            child: Text(
                              transaction.note,
                              textAlign: TextAlign.start,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ),
                      ),
              ],
            ))
        .toList();
    List<DataRow> rowsTransSP = transactionsSP
        .map((transaction) => DataRow(
              cells: [
                dataCell(context, (transactionsSP.indexOf(transaction) + 1).toString()),
                dataCell(context, getText(transaction.category), textAlign: TextAlign.start),
                dataCell(context, myDateFormate.format(transaction.date)),
                dataCell(
                    context, transaction.type == 'in' ? transactionsTypes['in'] ?? '' : transactionsTypes['out'] ?? ''),
                dataCell(context, transaction.type == 'in' ? myCurrency.format(transaction.amount) : '/',
                    textAlign: transaction.type == 'in' ? TextAlign.end : TextAlign.center),
                dataCell(context, transaction.type == 'out' ? myCurrency.format(transaction.amount) : '/',
                    textAlign: transaction.type == 'out' ? TextAlign.end : TextAlign.center),
                dataCell(context, myCurrency.format(transaction.solde), textAlign: TextAlign.end),
                transaction.note.length < 40
                    ? dataCell(context, transaction.note)
                    : DataCell(
                        ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: getWidth(context, .22)),
                          child: Tooltip(
                            message: transaction.note,
                            textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),
                            padding: const EdgeInsets.all(8.0),
                            // margin: const EdgeInsets.only(left: 800, right: 100),
                            child: Text(
                              transaction.note,
                              textAlign: TextAlign.start,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ),
                      ),
              ],
            ))
        .toList();
    List<DataRow> rowsTransLoan = loanTransactions
        .map((transaction) => DataRow(
              cells: [
                dataCell(context, (loanTransactions.indexOf(transaction) + 1).toString()),
                dataCell(context,
                    namesHidden ? loanNames.toList().indexOf(transaction.userName).toString() : transaction.userName,
                    textAlign: namesHidden ? TextAlign.center : TextAlign.start),
                dataCell(context, myDateFormate.format(transaction.date)),
                dataCell(
                    context, transaction.type == 'in' ? transactionsTypes['in'] ?? '' : transactionsTypes['out'] ?? ''),
                dataCell(context, transaction.type == 'in' ? myCurrency.format(transaction.amount) : '/',
                    textAlign: transaction.type == 'in' ? TextAlign.end : TextAlign.center),
                dataCell(context, transaction.type == 'out' ? myCurrency.format(transaction.amount) : '/',
                    textAlign: transaction.type == 'out' ? TextAlign.end : TextAlign.center),
                dataCell(context, myCurrency.format(transaction.soldeUser), textAlign: TextAlign.end),
                transaction.note.length < 40
                    ? dataCell(context, transaction.note)
                    : DataCell(
                        ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: getWidth(context, .22)),
                          child: Tooltip(
                            message: transaction.note,
                            textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),
                            padding: const EdgeInsets.all(8.0),
                            margin: const EdgeInsets.only(left: 800, right: 100),
                            child: Text(
                              transaction.note,
                              textAlign: TextAlign.start,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ),
                      ),
              ],
            ))
        .toList();
    List<DataRow> rowsTransDeposit = depositTransactions
        .map((transaction) => DataRow(
              cells: [
                dataCell(context, (depositTransactions.indexOf(transaction) + 1).toString()),
                dataCell(context,
                    namesHidden ? depositNames.toList().indexOf(transaction.userName).toString() : transaction.userName,
                    textAlign: namesHidden ? TextAlign.center : TextAlign.start),
                dataCell(context, myDateFormate.format(transaction.date)),
                dataCell(
                    context, transaction.type == 'in' ? transactionsTypes['in'] ?? '' : transactionsTypes['out'] ?? ''),
                dataCell(context, transaction.type == 'in' ? myCurrency.format(transaction.amount) : '/',
                    textAlign: transaction.type == 'in' ? TextAlign.end : TextAlign.center),
                dataCell(context, transaction.type == 'out' ? myCurrency.format(transaction.amount) : '/',
                    textAlign: transaction.type == 'out' ? TextAlign.end : TextAlign.center),
                dataCell(context, myCurrency.format(transaction.soldeUser), textAlign: TextAlign.end),
                transaction.note.length < 40
                    ? dataCell(context, transaction.note)
                    : DataCell(
                        ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: getWidth(context, .22)),
                          child: Tooltip(
                            message: transaction.note,
                            textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),
                            padding: const EdgeInsets.all(8.0),
                            margin: const EdgeInsets.only(left: 800, right: 100),
                            child: Text(
                              transaction.note,
                              textAlign: TextAlign.start,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ),
                      ),
              ],
            ))
        .toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        mini: true,
        tooltip: getText('newTransaction'),
        onPressed: () => _newTransaction(context),
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
            child: Column(children: [
              const SizedBox(width: double.minPositive, height: 8.0),
              searchBar(),
              const SizedBox(width: double.minPositive, height: 8.0),
              SizedBox(width: getWidth(context, .45), child: const Divider()),
              const SizedBox(width: double.minPositive, height: 8.0),
              Expanded(
                  child: isloading
                      ? myProgress()
                      : transactionCategory == 'caisse'
                          ? transactions.isEmpty
                              ? SizedBox(width: getWidth(context, .60), child: emptyList())
                              : SingleChildScrollView(
                                  child: dataTable(
                                    isAscending: _isAscendingTransCaisse,
                                    sortColumnIndex: _sortColumnIndexTransCaisse,
                                    columns: columnsTransCaisse,
                                    rows: rowsTransCaisse,
                                    columnSpacing: 30,
                                  ),
                                )
                          : transactionCategory == 'users'
                              ? transactions.isEmpty
                                  ? SizedBox(width: getWidth(context, .60), child: emptyList())
                                  : SingleChildScrollView(
                                      child: dataTable(
                                        isAscending: _isAscendingTrans,
                                        sortColumnIndex: _sortColumnIndexTrans,
                                        columns: columnsTrans,
                                        rows: rowsTrans,
                                        columnSpacing: 30,
                                      ),
                                    )
                              : transactionCategory == 'specials'
                                  ? transactionsSP.isEmpty
                                      ? SizedBox(width: getWidth(context, .60), child: emptyList())
                                      : SingleChildScrollView(
                                          child: dataTable(
                                            isAscending: _isAscendingTransSP,
                                            sortColumnIndex: _sortColumnIndexTransSP,
                                            columns: columnsTransSP,
                                            rows: rowsTransSP,
                                            columnSpacing: 30,
                                          ),
                                        )
                                  : transactionCategory == 'loans'
                                      ? loanTransactions.isEmpty
                                          ? SizedBox(width: getWidth(context, .60), child: emptyList())
                                          : SingleChildScrollView(
                                              child: dataTable(
                                                isAscending: _isAscendingTransLoan,
                                                sortColumnIndex: _sortColumnIndexTransLoan,
                                                columns: columnsTransLoan,
                                                rows: rowsTransLoan,
                                                columnSpacing: 30,
                                              ),
                                            )
                                      : transactionCategory == 'deposits'
                                          ? depositTransactions.isEmpty
                                              ? SizedBox(width: getWidth(context, .60), child: emptyList())
                                              : SingleChildScrollView(
                                                  child: dataTable(
                                                    isAscending: _isAscendingTransDeposit,
                                                    sortColumnIndex: _sortColumnIndexTransDeposit,
                                                    columns: columnsTransDeposit,
                                                    rows: rowsTransDeposit,
                                                    columnSpacing: 30,
                                                  ),
                                                )
                                          : const SizedBox()),
              const SizedBox(height: 8.0),
              SizedBox(width: getWidth(context, .52), child: const Divider()),
              const SizedBox(height: 8.0),
              Row(
                children: [
                  myText('${getText('totalIn')} :      ${myCurrency.format(totalIn)}'),
                  SizedBox(width: getWidth(context, .05)),
                  myText('${getText('totalOut')} :      ${myCurrency.format(totalOut)}'),
                  SizedBox(width: getWidth(context, .05)),
                  myText('${getText('total')} :      ${myCurrency.format(totalIn - totalOut)}'),
                ],
              ),
              const SizedBox(height: 8.0),
            ]),
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
        myDropDown(
          context,
          value: transactionCategory,
          items: transactionsCategorys.entries.map((item) {
            return DropdownMenuItem(
              value: getKeyFromValue(item.value),
              alignment: AlignmentDirectional.center,
              child: Text(item.value),
            );
          }).toList(),
          onChanged: (value) => setState(() {
            context.read<Filter>().change(transactionCategory: value.toString());
            context.read<Filter>().resetFilter();
            _controller.clear();
            _type = 'tout';
            _year = 'tout';
            _fromDate = DateTime(int.parse(years.last));
            _toDate = today.add(const Duration(seconds: 86399));
          }),
        ),
        const SizedBox(width: 8.0),
        const SizedBox(height: 40, child: VerticalDivider()),
        const SizedBox(width: 8.0),
        if (transactionCategory == 'specials')
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text(
                  getText('category'),
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              myDropDown(
                context,
                value: _compt,
                color: _compt == 'tout' ? Colors.grey : primaryColor,
                items: comptsSearch.entries.map((item) {
                  return DropdownMenuItem(
                    value: getKeyFromValue(item.value),
                    alignment: AlignmentDirectional.center,
                    child: Text(item.value),
                  );
                }).toList(),
                onChanged: (value) => setState(() => context.read<Filter>().change(compt: value.toString())),
              ),
            ],
          ),
        transactionCategory == 'users'
            ? autoComplete(
                onSeleted: (item) => setState(() =>
                    context.read<Filter>().change(search: namesHidden ? userNames.elementAt(int.parse(item)) : item)),
                optionsBuilder: (textEditingValue) {
                  if (namesHidden) {
                    Set<String> indexes = {};
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
              )
            : const SizedBox(),
        transactionCategory == 'loans'
            ? autoComplete(
                onSeleted: (item) => setState(() =>
                    context.read<Filter>().change(search: namesHidden ? loanNames.elementAt(int.parse(item)) : item)),
                optionsBuilder: (textEditingValue) {
                  if (namesHidden) {
                    Set<String> indexes = {};
                    for (var ele in loanNames) {
                      if (loanNames.toList().indexOf(ele).toString().contains(textEditingValue.text)) {
                        indexes.add(loanNames.toList().indexOf(ele).toString());
                      }
                    }
                    return indexes;
                  } else {
                    return loanNames.where((item) => item.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                  }
                },
              )
            : const SizedBox(),
        transactionCategory == 'deposits'
            ? autoComplete(
                onSeleted: (item) => setState(() => context
                    .read<Filter>()
                    .change(search: namesHidden ? depositNames.elementAt(int.parse(item)) : item)),
                optionsBuilder: (textEditingValue) {
                  if (namesHidden) {
                    Set<String> indexes = {};
                    for (var ele in depositNames) {
                      if (depositNames.toList().indexOf(ele).toString().contains(textEditingValue.text)) {
                        indexes.add(depositNames.toList().indexOf(ele).toString());
                      }
                    }
                    return indexes;
                  } else {
                    return depositNames
                        .where((item) => item.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                  }
                },
              )
            : const SizedBox(),
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
              items: transactionsTypesSearch.entries.map((item) {
                return DropdownMenuItem(
                  value: getKeyFromValue(item.value),
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
                if (_year == 'tout') {
                  _fromDate = DateTime(int.parse(years.last));
                  _toDate = today.add(const Duration(seconds: 86399));
                } else {
                  _fromDate = DateTime(int.parse(_year));
                  _toDate = double.parse(_year) == currentYear
                      ? today.add(const Duration(seconds: 86399))
                      : DateTime(int.parse(_year) + 1).subtract(const Duration(seconds: 1));
                }
              }),
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
                getText('from'),
                style: const TextStyle(fontSize: 14),
              ),
            ),
            InkWell(
              onTap: () async {
                final DateTime? selected = await showDatePicker(
                  context: context,
                  initialDate: _fromDate,
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
                  width: getWidth(context, .09),
                  padding: const EdgeInsets.all(8.0),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                      color: _fromDate == DateTime(int.parse(years.last)) ? Colors.grey : primaryColor,
                    ),
                    borderRadius: const BorderRadius.all(Radius.circular(12)),
                  ),
                  child: myText(myDateFormate.format(_fromDate))),
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
                getText('to'),
                style: const TextStyle(fontSize: 14),
              ),
            ),
            InkWell(
              onTap: () async {
                final DateTime? selected = await showDatePicker(
                  context: context,
                  initialDate: _toDate,
                  firstDate: _fromDate,
                  lastDate: _year == 'tout'
                      ? today.add(const Duration(seconds: 86399))
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
                  width: getWidth(context, .09),
                  padding: const EdgeInsets.all(8.0),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                      color: _toDate == today.add(const Duration(seconds: 86399)) ? Colors.grey : primaryColor,
                    ),
                    borderRadius: const BorderRadius.all(Radius.circular(12)),
                  ),
                  child: myText(myDateFormate.format(_toDate))),
            ),
          ],
        ),
        const SizedBox(width: 8.0),
        IconButton(
          icon: Icon(
            Icons.calendar_month,
            color: primaryColor,
          ),
          onPressed: () async {
            final DateTime? selected = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(int.parse(years.last)),
              lastDate: today.add(const Duration(seconds: 86399)),
            );
            if (selected != null && selected != _fromDate) {
              setState(() {
                _fromDate = selected;
                _toDate = selected.add(const Duration(seconds: 86399));
              });
            }
          },
        ),
        (_controller.text.isNotEmpty ||
                _compt != 'tout' ||
                _type != 'tout' ||
                _year != 'tout' ||
                _fromDate != DateTime(int.parse(years.last)) ||
                _toDate != today.add(const Duration(seconds: 86399)))
            ? IconButton(
                onPressed: () => setState(() {
                  context.read<Filter>().resetFilter();
                  _controller.clear();
                  _type = 'tout';
                  _year = 'tout';
                  _fromDate = DateTime(int.parse(years.last));
                  _toDate = today.add(const Duration(seconds: 86399));
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

  Widget autoComplete(
      {required Function(String) onSeleted, required Iterable<String> Function(TextEditingValue) optionsBuilder}) {
    return Column(
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
            onSelected: onSeleted,
            optionsBuilder: optionsBuilder,
            fieldViewBuilder: (
              context,
              textEditingController,
              focusNode,
              onFieldSubmitted,
            ) {
              _controller = textEditingController;
              var list = transactionCategory == 'users'
                  ? userNames
                  : transactionCategory == 'loans'
                      ? loanNames
                      : depositNames;
              _controller.text = !namesHidden
                  ? _search
                  : _search.isEmpty
                      ? ''
                      : list.toList().indexOf(_search).toString();

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
                                  context.read<Filter>().resetFilter();
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
                    constraints: BoxConstraints(maxHeight: getHeight(context, .2), maxWidth: getWidth(context, .23)),
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
    );
  }
}
