import 'dart:collection';

import 'package:fairsplit/models/transaction.dart';
import 'package:fairsplit/widgets/widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../main.dart';
import '../shared/lists.dart';
import '/shared/parameters.dart';
import '/models/unit.dart';
import '/models/user.dart';

class Calculation extends StatefulWidget {
  final Unit unit;
  const Calculation({super.key, required this.unit});

  @override
  State<Calculation> createState() => _CalculationState();
}

class _CalculationState extends State<Calculation> {
  TextEditingController controller = TextEditingController();
  List<User> moneyUsers = [], globalEffortUsers = [], unitEffortUsers = [], thresholdUsers = [], foundingUsers = [];
  List<Transaction> transactions = [];
  var transactionsDays = <DateTime>{}; //list of days that containe transactions
  late double reserve;
  double unitProfitValue = 0, unitProfitHint = 0;
  // bool reserveIsMoneyPartner = false;
  bool isloading = true, iscalculated = false;
  int bottemNavigationSelectedInex = 0;
  int daysInMonth = 0;

  double caMoneyProfitPerDay = 0; //caMoney / days in month
  //weightedProfitability used to calculate the weighted capital for each money user = day profit / total day capital
  double weightedProfitability = 0;

  double caReserve = 0,
      caReserveMoneyProfit = 0,
      caDonation = 0,
      caNetProfit = 0,
      caMoney = 0,
      caEffort = 0,
      caTotalEffortUnit = 0,
      caEffortGlobal = 0,
      caThreshold = 0,
      caFounding = 0;

  void loadData() async {
    var res = await sqlQuery(selectUrl, {
      'sql1': '''SELECT reserve FROM Settings;''',
      'sql2': '''SELECT userId, name, capital FROM Users WHERE type IN ('money','both');''',
      'sql3':
          '''SELECT e.userId, u.name, e.effortPerc,  u.months FROM Effort e, Users u WHERE e.unitId = -1 AND e.userId = u.userId;''',
      'sql4':
          '''SELECT e.userId, u.name, e.effortPerc,  u.months FROM Effort e, Users u WHERE e.unitId = ${widget.unit.unitId} AND e.userId = u.userId;''',
      'sql5':
          '''SELECT t.userId,u.name, t.thresholdPerc FROM Threshold t, Users u WHERE t.unitId = ${widget.unit.unitId} AND t.userId = u.userId;''',
      'sql6':
          '''SELECT f.userId,u.name, f.foundingPerc FROM Founding f, Users u WHERE f.unitId = ${widget.unit.unitId} AND f.userId = u.userId;''',
      'sql7': widget.unit.type == 'intern'
          ? '''SELECT transactionId,userId,userName,date,type,amount FROM Transaction WHERE Month(date) = ${widget.unit.currentMonthOrYear} AND Year(date) = $currentYear;'''
          : '''SELECT transactionId,userId,userName,date,type,amount FROM Transaction WHERE Year(date) >= ${widget.unit.currentMonthOrYear};''',
      'sql8': widget.unit.type == 'intern'
          ? '''SELECT transactionId,date,type,amount FROM transactionsp WHERE category = 'reserve' AND Month(date) = ${widget.unit.currentMonthOrYear} AND Year(date) = $currentYear;'''
          : '''SELECT transactionId,date,type,amount FROM transactionsp WHERE category = 'reserve' AND Year(date) >= ${widget.unit.currentMonthOrYear};''',
    });

    reserve = double.parse(res[0][0]['reserve']);

    for (var ele in res[1]) {
      moneyUsers.add(User(userId: int.parse(ele['userId']), name: ele['name'], capital: double.parse(ele['capital'])));
    }

    moneyUsers.sort((a, b) => a.name.compareTo(b.name));

    //add reserve to money users list
    moneyUsers.insert(0, User(userId: 0, name: getText('reserve'), capital: reserve));

    for (var ele in res[2]) {
      if (widget.unit.type == 'intern' && ele['months'][widget.unit.currentMonthOrYear - 1] == '1') {
        globalEffortUsers.add(
            User(userId: int.parse(ele['userId']), name: ele['name'], effortPerc: double.parse(ele['effortPerc'])));
      }
    }

    globalEffortUsers.sort((a, b) => a.name.compareTo(b.name));

    for (var ele in res[3]) {
      if (widget.unit.type == 'intern' && ele['months'][widget.unit.currentMonthOrYear - 1] == '1') {
        unitEffortUsers.add(
            User(userId: int.parse(ele['userId']), name: ele['name'], effortPerc: double.parse(ele['effortPerc'])));
      }
    }

    unitEffortUsers.sort((a, b) => a.name.compareTo(b.name));

    for (var ele in res[4]) {
      thresholdUsers.add(
          User(userId: int.parse(ele['userId']), name: ele['name'], thresholdPerc: double.parse(ele['thresholdPerc'])));
    }

    thresholdUsers.sort((a, b) => a.name.compareTo(b.name));

    for (var ele in res[5]) {
      foundingUsers.add(
          User(userId: int.parse(ele['userId']), name: ele['name'], foundingPerc: double.parse(ele['foundingPerc'])));
    }

    foundingUsers.sort((a, b) => a.name.compareTo(b.name));

    for (var ele in res[6]) {
      Transaction transaction = Transaction(
        transactionId: int.parse(ele['transactionId']),
        userId: int.parse(ele['userId']),
        userName: ele['userName'],
        date: DateTime.parse(ele['date']),
        type: ele['type'],
        amount: double.parse(ele['amount']),
      );
      transactions.add(transaction);

      if (widget.unit.type == 'intern' || transaction.date.year == widget.unit.currentMonthOrYear) {
        // we add the transaction day if it's  unit type is intern or (extern and trasaction year = unit currentMonthOrYear )
        transactionsDays.add(DateTime(transaction.date.year, transaction.date.month, transaction.date.day));
      }
    }

    for (var ele in res[7]) {
      Transaction transaction = Transaction(
        transactionId: int.parse(ele['transactionId']),
        userId: 0,
        userName: getText('reserve'),
        date: DateTime.parse(ele['date']),
        type: ele['type'],
        amount: double.parse(ele['amount']),
      );
      transactions.add(transaction);
      if (widget.unit.type == 'intern' ||
          (widget.unit.type == 'extern' && transaction.date.year == widget.unit.currentMonthOrYear)) {
        // we add the transaction day if it's  unit type is intern or (extern and trasaction year = unit currentMonthOrYear )
        transactionsDays.add(DateTime(transaction.date.year, transaction.date.month, transaction.date.day));
      }
    }

    //  if extern unit we use 365 else we calculate number of days in current month
    daysInMonth = widget.unit.type == 'extern'
        ? DateTime(widget.unit.currentMonthOrYear + 1).difference(DateTime(widget.unit.currentMonthOrYear)).inDays
        : DateUtils.getDaysInMonth(currentYear, widget.unit.currentMonthOrYear);

    //if is intern unit we add the first day of the current month and next month
    //if is extern unit we add the first dat of janury of the current year and next year
    transactionsDays.addAll({
      DateTime(
        widget.unit.type == 'extern' ? widget.unit.currentMonthOrYear : currentYear,
        widget.unit.type == 'extern' ? 1 : widget.unit.currentMonthOrYear,
        1,
      ),
      DateTime(
        widget.unit.type == 'extern' ? widget.unit.currentMonthOrYear + 1 : currentYear,
        widget.unit.type == 'extern' ? 1 : widget.unit.currentMonthOrYear + 1,
        1,
      ),
    });

    transactionsDays = SplayTreeSet.from(transactionsDays);
    transactions.sort((tr1, tr2) => tr1.date.compareTo(tr2.date));

    //reset the users capital to its value in the first day of the month
    for (var user in moneyUsers) {
      for (var trans in transactions) {
        if (trans.userId == user.userId) {
          trans.type == 'in' ? user.capital -= trans.amount : user.capital += trans.amount;
        }
      }
      //set initial capital of user
      user.initialCapital = user.capital;
    }

    setState(() => isloading = false);
  }

  void calculate() async {
    setState(() {
      isloading = true;
      iscalculated = true;
    });
    controller.clear();
    unitProfitHint = unitProfitValue;
    caTotalEffortUnit = 0;

    caReserve = unitProfitValue * widget.unit.reservePerc / 100;
    caDonation = (unitProfitValue - caReserve) * widget.unit.donationPerc / 100;
    caNetProfit = unitProfitValue - caReserve - caDonation;
    caMoney = caNetProfit * widget.unit.moneyPerc / 100;
    caEffort = caNetProfit * widget.unit.effortPerc / 100;
    caThreshold = caNetProfit * widget.unit.thresholdPerc / 100;
    caFounding = caNetProfit * widget.unit.foundingPerc / 100;

    for (var user in thresholdUsers) {
      user.threshold = caThreshold * user.thresholdPerc / 100;
    }

    for (var user in foundingUsers) {
      user.founding = caFounding * user.foundingPerc / 100;
    }

    for (var user in unitEffortUsers) {
      // user.effort = (caEffort * user.effortPerc / 100) * user.evaluation / 100;
      user.effort = caEffort * user.effortPerc / 100;
      caTotalEffortUnit += user.effort;
    }

    caEffortGlobal = caEffort - caTotalEffortUnit;

    for (var user in globalEffortUsers) {
      // user.effort = (caEffortGlobal * user.effortPerc / 100) * user.evaluation / 100;
      user.effort = caEffortGlobal * user.effortPerc / 100;
    }

    //calculated money profit / number of days in month
    caMoneyProfitPerDay = caMoney / daysInMonth;

    // loop the list of days that has transactions
    for (var i = 0; i < transactionsDays.length - 1; i++) {
      //loop the list of transactions in the selected day
      //for the transactions list we loop all the list if unit type is intern else we loop only the transactions of currentMonthOrYear
      for (var caTrans in transactions
          .where((element) => (widget.unit.type == 'intern' || element.date.year == widget.unit.currentMonthOrYear))) {
        if (DateTime(caTrans.date.year, caTrans.date.month, caTrans.date.day) == transactionsDays.elementAt(i)) {
          // get the user of the transaction
          User caTransUser = moneyUsers.firstWhere((user) => user.userId == caTrans.userId);

          // add the transaction into the user capital
          caTrans.type == 'in' ? caTransUser.capital += caTrans.amount : caTransUser.capital -= caTrans.amount;
        }
      }

      // calculate the total of all users capitals
      double totalUsersCapital = 0; // the sum of all users capital including reserve
      for (var user in moneyUsers) {
        totalUsersCapital += user.capital;
      }

      // count number of days till the next day that has transaction
      int daysCountToNextTransaction =
          transactionsDays.elementAt(i + 1).difference(transactionsDays.elementAt(i)).inDays;

      // calculate the weighted profitability
      weightedProfitability += caMoneyProfitPerDay / totalUsersCapital * daysCountToNextTransaction;

      for (var user in moneyUsers) {
        // percentage of user capital compare to tho total users capital
        double userCapitalPerc = user.capital * 100 / totalUsersCapital;

        // (money profit per day * percentage of user capital /100) * count of days till next transaction then add it to user money profit
        user.money += (caMoneyProfitPerDay * userCapitalPerc / 100) * daysCountToNextTransaction;
      }
    }

    setState(() => isloading = false);
  }

  void save() async {
    String moneySQL = 'INSERT INTO Users(userId, money) VALUES ';
    String thresholdSQL = 'INSERT INTO Users(userId, threshold) VALUES ';
    String foundingSQL = 'INSERT INTO Users(userId, founding) VALUES ';
    String effortUnitSQL = 'INSERT INTO Users(userId, effort) VALUES ';
    String effortGlobalSQL = 'INSERT INTO Users(userId, effort) VALUES ';

    caReserveMoneyProfit = moneyUsers[0].money;
    moneyUsers.removeAt(0);

    for (var user in moneyUsers) {
      moneySQL += '(${user.userId}, ${user.money}),';
    }

    for (var user in thresholdUsers) {
      thresholdSQL += '(${user.userId}, ${user.threshold}),';
    }

    for (var user in foundingUsers) {
      foundingSQL += '(${user.userId}, ${user.founding}),';
    }

    for (var user in unitEffortUsers) {
      effortUnitSQL += '(${user.userId}, ${user.effort}),';
    }

    for (var user in globalEffortUsers) {
      effortGlobalSQL += '(${user.userId}, ${user.effort}),';
    }

    moneySQL = moneySQL.substring(0, moneySQL.length - 1);
    thresholdSQL = thresholdSQL.substring(0, thresholdSQL.length - 1);
    foundingSQL = foundingSQL.substring(0, foundingSQL.length - 1);
    effortUnitSQL = effortUnitSQL.substring(0, effortUnitSQL.length - 1);
    effortGlobalSQL = effortGlobalSQL.substring(0, effortGlobalSQL.length - 1);

    moneySQL += ' ON DUPLICATE KEY UPDATE money = money + VALUES(money);';
    thresholdSQL += ' ON DUPLICATE KEY UPDATE threshold = threshold + VALUES(threshold);';
    foundingSQL += ' ON DUPLICATE KEY UPDATE founding = founding + VALUES(founding);';
    effortUnitSQL += ' ON DUPLICATE KEY UPDATE effort = effort + VALUES(effort);';
    effortGlobalSQL += ' ON DUPLICATE KEY UPDATE effort = effort + VALUES(effort);';

    int nextMonthOrYear = widget.unit.type == 'extern'
        ? widget.unit.currentMonthOrYear + 1
        : widget.unit.currentMonthOrYear == 12
            ? 1
            : widget.unit.currentMonthOrYear + 1;

    int calculated = widget.unit.type == 'extern' || nextMonthOrYear == 1 ? 1 : 0;

    await sqlQuery(insertUrl, {
      'sql1': moneySQL,
      'sql2': thresholdSQL,
      'sql3': foundingSQL,
      'sql4': effortUnitSQL,
      'sql5': effortGlobalSQL,
      'sql6':
          ''' UPDATE Units SET profit = profit + $unitProfitValue, calculated = $calculated, currentMonthOrYear = $nextMonthOrYear  WHERE unitId = ${widget.unit.unitId}; ''',
      'sql7':
          '''INSERT INTO ProfitHistory(name, year, month, profit, reserve, donation, money, effort, threshold, founding) VALUES ('${widget.unit.name}',${widget.unit.type == 'extern' ? widget.unit.currentMonthOrYear : currentYear},${widget.unit.type == 'extern' ? 0 : widget.unit.currentMonthOrYear},$unitProfitValue,${caReserve.toStringAsFixed(2)},${caDonation.toStringAsFixed(2)},${caMoney.toStringAsFixed(2)},${caEffort.toStringAsFixed(2)},${caThreshold.toStringAsFixed(2)},${caFounding.toStringAsFixed(2)});''',
      'sql8':
          'UPDATE settings SET reserveProfit = reserveProfit + $caReserve + $caReserveMoneyProfit , donationProfit = donationProfit + $caDonation '
    });

    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MyApp(index: 'un')));
    snackBar(context, 'Calculation done successfully');
  }

  @override
  void initState() {
    loadData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: getHeight(context, 1),
      width: getWidth(context, .75),
      child: Column(
        children: [
          Container(
            alignment: Alignment.center,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.unit.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20.0,
                    ),
                  ),
                ),
                IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                    ))
              ],
            ),
            decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20.0),
                  topRight: Radius.circular(20.0),
                )),
          ),
          Expanded(
              child: Container(
            padding: const EdgeInsets.only(top: 8.0, left: 8.0, right: 8.0),
            width: double.infinity,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.only(
                bottomRight: Radius.circular(20.0),
                bottomLeft: Radius.circular(20.0),
              ),
            ),
            child: isloading
                ? myProgress()
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: RawKeyboardListener(
                                focusNode: FocusNode(),
                                onKey: (event) {
                                  if (event.isKeyPressed(LogicalKeyboardKey.enter) && !iscalculated) calculate();
                                },
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    myTextField(
                                      context,
                                      controller: controller,
                                      hint: myCurrency.format(unitProfitHint),
                                      width: getWidth(context, .25),
                                      onChanged: ((text) => unitProfitValue = double.parse(text)),
                                      isNumberOnly: true,
                                      autoFocus: true,
                                      enabled: !iscalculated,
                                    ),
                                    if (!iscalculated)
                                      IconButton(
                                        icon: Icon(Icons.play_arrow, color: secondaryColor),
                                        hoverColor: Colors.transparent,
                                        onPressed: () => calculate(),
                                      )
                                  ],
                                ),
                              ),
                            ),
                            !iscalculated
                                ? const SizedBox()
                                : myButton(context, width: getWidth(context, .07), onTap: () {
                                    setState(() => isloading = true);
                                    save();
                                  }),
                          ],
                        ),
                      ),
                      mySizedBox(context),
                      SizedBox(width: getWidth(context, 1), child: const Divider()),
                      mySizedBox(context),
                      if (bottemNavigationSelectedInex == 0)
                        Expanded(child: Center(child: SingleChildScrollView(child: information()))),
                      if (bottemNavigationSelectedInex == 1) tabScreen(transaction()),
                      if (bottemNavigationSelectedInex == 2) tabScreen(money()),
                      if (bottemNavigationSelectedInex == 3) tabScreen(threshold()),
                      if (bottemNavigationSelectedInex == 4) tabScreen(founding()),
                      if (bottemNavigationSelectedInex == 5) tabScreen(effort()),
                      if (bottemNavigationSelectedInex == 6) tabScreen(global()),
                      mySizedBox(context),
                      SizedBox(width: getWidth(context, 1), child: const Divider()),
                      SizedBox(
                        child: BottomNavigationBar(
                          type: BottomNavigationBarType.fixed,
                          items: <BottomNavigationBarItem>[
                            BottomNavigationBarItem(icon: const Icon(Icons.add), label: getText('info')),
                            BottomNavigationBarItem(icon: const Icon(Icons.add), label: getText('transaction')),
                            BottomNavigationBarItem(icon: const Icon(Icons.add), label: getText('money')),
                            BottomNavigationBarItem(icon: const Icon(Icons.add), label: getText('threshold')),
                            BottomNavigationBarItem(icon: const Icon(Icons.add), label: getText('founding')),
                            BottomNavigationBarItem(icon: const Icon(Icons.add), label: getText('effortUnit')),
                            BottomNavigationBarItem(icon: const Icon(Icons.add), label: getText('effortGlobal')),
                          ],
                          selectedFontSize: 26,
                          unselectedFontSize: 18,
                          currentIndex: bottemNavigationSelectedInex,
                          onTap: (index) => setState(() => bottemNavigationSelectedInex = index),
                          selectedIconTheme: const IconThemeData(opacity: 0.0, size: 0),
                          unselectedIconTheme: const IconThemeData(opacity: 0.0, size: 0),
                          selectedItemColor: primaryColor,
                          backgroundColor: Colors.white,
                          elevation: 0,
                        ),
                      ),
                      mySizedBox(context),
                    ],
                  ),
          ))
        ],
      ),
    );
  }

  Widget tabScreen(Widget view) => Expanded(child: SingleChildScrollView(child: view));

  Widget information() {
    return Row(
      children: [
        const Spacer(),
        Column(
          children: [
            {'key': getText('unit'), 'val': widget.unit.name},
            {'key': getText('capital'), 'val': myCurrency.format(widget.unit.capital)},
            {
              'key': widget.unit.type == "extern" ? getText('year') : getText('month'),
              'val': widget.unit.type == "extern"
                  ? widget.unit.currentMonthOrYear.toString()
                  : monthsOfYear[widget.unit.currentMonthOrYear - 1]
            },
            {'key': '${getText('unitProfitability')} %', 'val': (caMoney / widget.unit.capital).toStringAsFixed(2)},
            {'key': '${getText('profitability')} %', 'val': (weightedProfitability * 100).toStringAsFixed(2)},
            {'key': '${getText('reserve')} %', 'val': widget.unit.reservePerc.toString()},
            {'key': '${getText('donation')} %', 'val': widget.unit.donationPerc.toString()},
            {'key': '', 'val': ''},
            {'key': '${getText('money')} %', 'val': widget.unit.moneyPerc.toString()},
            {'key': '${getText('effort')} %', 'val': widget.unit.effortPerc.toString()},
            {'key': '', 'val': ''},
            {'key': '${getText('threshold')} %', 'val': widget.unit.thresholdPerc.toString()},
            {'key': '${getText('founding')} %', 'val': widget.unit.foundingPerc.toString()},
          ].map((e) => infoItem(e['key']!, e['val']!)).toList(),
        ),
        const Spacer(),
        Column(
          children: [
            {'key': '', 'val': ''},
            {'key': '', 'val': ''},
            {'key': '', 'val': ''},
            {'key': '', 'val': ''},
            {
              'key': getText('weightedCapital'),
              'val': myCurrency.format(weightedProfitability == 0 ? 0 : caMoney / weightedProfitability)
            },
            {'key': getText('reserve'), 'val': myCurrency.format(caReserve)},
            {'key': getText('donation'), 'val': myCurrency.format(caDonation)},
            {'key': 'Net Profit', 'val': myCurrency.format(caNetProfit)},
            {'key': getText('money'), 'val': myCurrency.format(caMoney)},
            {'key': getText('effort'), 'val': myCurrency.format(caEffort)},
            {'key': getText('effortGlobal'), 'val': myCurrency.format(caEffortGlobal)},
            {'key': getText('threshold'), 'val': myCurrency.format(caThreshold)},
            {'key': getText('founding'), 'val': myCurrency.format(caFounding)},
          ].map((e) => infoItem(e['key']!, e['val']!)).toList(),
        ),
        const Spacer(),
      ],
    );
  }

  Widget infoItem(String title, String value) {
    return SizedBox(
      width: getWidth(context, .25),
      height: getHeight(context, .05),
      child: value.isEmpty
          ? const SizedBox()
          : Row(
              children: [
                Expanded(child: myText(title)),
                Expanded(child: myText(':      $value')),
              ],
            ),
    );
  }

  Widget transaction() {
    List<DataColumn> column = [
      '',
      getText('name'),
      getText('date'),
      getText('type'),
      getText('in'),
      getText('out'),
    ].map((e) => dataColumn(context, e)).toList();
    List<DataRow> rows = transactions
        .where((element) => (widget.unit.type == 'intern' || element.date.year == widget.unit.currentMonthOrYear))
        .map(
          (transaction) => DataRow(cells: [
            dataCell(context, (transactions.indexOf(transaction) + 1).toString()),
            dataCell(context, transaction.userName, textAlign: TextAlign.start),
            dataCell(context, myDateFormate.format(transaction.date)),
            dataCell(
                context, transaction.type == 'in' ? transactionsTypes['in'] ?? '' : transactionsTypes['out'] ?? ''),
            dataCell(context, transaction.type == 'in' ? myCurrency.format(transaction.amount) : '/',
                textAlign: transaction.type == 'in' ? TextAlign.end : TextAlign.center),
            dataCell(context, transaction.type == 'out' ? myCurrency.format(transaction.amount) : '/',
                textAlign: transaction.type == 'out' ? TextAlign.end : TextAlign.center),
          ]),
        )
        .toList();
    return transactions.isEmpty ? emptyList() : dataTable(columns: column, rows: rows, columnSpacing: 30);
  }

  Widget money() {
    List<DataColumn> column = [
      '',
      getText('name'),
      getText('initialCapital'),
      getText('weightedCapital'),
      getText('profit')
    ].map((e) => dataColumn(context, e)).toList();
    List<DataRow> rows = moneyUsers
        .map(
          (user) => DataRow(cells: [
            dataCell(context, (moneyUsers.indexOf(user) + 1).toString()),
            dataCell(context, user.name, textAlign: TextAlign.start),
            dataCell(context, myCurrency.format(user.initialCapital), textAlign: TextAlign.end),
            dataCell(context, myCurrency.format(weightedProfitability == 0 ? 0 : user.money / weightedProfitability),
                textAlign: TextAlign.end),
            dataCell(context, myCurrency.format(user.money), textAlign: TextAlign.end),
          ]),
        )
        .toList();
    return Column(
      children: [
        myText('${getText('money')}  :  ${myCurrency.format(caMoney)} '),
        mySizedBox(context),
        moneyUsers.isEmpty ? emptyList() : dataTable(columns: column, rows: rows, columnSpacing: 30),
      ],
    );
  }

  Widget threshold() {
    List<DataColumn> column = [
      '',
      getText('name'),
      '${getText('threshold')} %',
      getText('profit'),
    ].map((e) => dataColumn(context, e)).toList();
    List<DataRow> rows = thresholdUsers
        .map(
          (user) => DataRow(cells: [
            dataCell(context, (thresholdUsers.indexOf(user) + 1).toString()),
            dataCell(context, user.name, textAlign: TextAlign.start),
            dataCell(context, user.thresholdPerc.toString()),
            dataCell(context, myCurrency.format(user.threshold), textAlign: TextAlign.end),
          ]),
        )
        .toList();
    return Column(
      children: [
        myText('${getText('threshold')}  :  ${myCurrency.format(caThreshold)} '),
        mySizedBox(context),
        thresholdUsers.isEmpty ? emptyList() : dataTable(columns: column, rows: rows, columnSpacing: 30),
      ],
    );
  }

  Widget founding() {
    List<DataColumn> column = [
      '',
      getText('name'),
      '${getText('founding')} %',
      getText('profit'),
    ].map((e) => dataColumn(context, e)).toList();
    List<DataRow> rows = foundingUsers
        .map(
          (user) => DataRow(cells: [
            dataCell(context, (foundingUsers.indexOf(user) + 1).toString()),
            dataCell(context, user.name, textAlign: TextAlign.start),
            dataCell(context, user.foundingPerc.toString()),
            dataCell(context, myCurrency.format(user.founding), textAlign: TextAlign.end),
          ]),
        )
        .toList();
    return Column(
      children: [
        myText('${getText('founding')}  :  ${myCurrency.format(caFounding)} '),
        mySizedBox(context),
        foundingUsers.isEmpty ? emptyList() : dataTable(columns: column, rows: rows, columnSpacing: 30),
      ],
    );
  }

  Widget effort() {
    List<DataColumn> column = [
      '',
      getText('name'),
      '${getText('effort')} %',
      getText('profit'),
    ].map((e) => dataColumn(context, e)).toList();
    List<DataRow> rows = unitEffortUsers
        .map(
          (user) => DataRow(cells: [
            dataCell(context, (unitEffortUsers.indexOf(user) + 1).toString()),
            dataCell(context, user.name, textAlign: TextAlign.start),
            dataCell(context, user.effortPerc.toString()),
            dataCell(context, myCurrency.format(user.effort), textAlign: TextAlign.end),
          ]),
        )
        .toList();
    return Column(
      children: [
        myText('${getText('effort')}  :  ${myCurrency.format(caEffort)} '),
        mySizedBox(context),
        unitEffortUsers.isEmpty ? emptyList() : dataTable(columns: column, rows: rows, columnSpacing: 30),
      ],
    );
  }

  Widget global() {
    List<DataColumn> column = [
      '',
      getText('name'),
      '${getText('effort')} %',
      getText('profit'),
    ].map((e) => dataColumn(context, e)).toList();
    List<DataRow> rows = globalEffortUsers
        .map(
          (user) => DataRow(cells: [
            dataCell(context, (globalEffortUsers.indexOf(user) + 1).toString()),
            dataCell(context, user.name, textAlign: TextAlign.start),
            dataCell(context, user.effortPerc.toString()),
            dataCell(context, myCurrency.format(user.effort), textAlign: TextAlign.end),
          ]),
        )
        .toList();
    return Column(
      children: [
        myText('${getText('effortGlobal')}  :  ${myCurrency.format(caEffortGlobal)} '),
        mySizedBox(context),
        globalEffortUsers.isEmpty ? emptyList() : dataTable(columns: column, rows: rows, columnSpacing: 30),
      ],
    );
  }
}
