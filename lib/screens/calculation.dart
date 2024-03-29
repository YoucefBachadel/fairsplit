import 'dart:collection';

import 'package:flutter/material.dart';

import '/main.dart';
import '/shared/functions.dart';
import '/shared/widgets.dart';
import '/shared/constants.dart';
import '/models/transaction.dart';
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
  List<Transaction> transactions = [], allTransactions = [];
  var transactionsDays = <DateTime>{}; //list of days that containe transactions
  double reserve = 0, caisse = 0, reserveProfit = 0;
  double unitProfitValue = 0, unitProfitHint = 0;
  String _unitProfitValue = '';
  bool isloading = true, iscalculated = false;
  int bottemNavigationSelectedInex = 0;
  int daysInMonth = 0;
  int reference = 0;
  DateTime date = DateTime.now();
  late DateTime lastTransactionDate;
  late bool isIntern;

  double caMoneyProfitPerDay = 0; //caMoney / days in month
  //profitability used to calculate the weighted capital for each money user = day profit / total day capital
  double profitability = 0;

  double caReserve = 0,
      caReserveProfit = 0,
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
      'sql1': '''SELECT caisse, reserve, reserveProfit, reference FROM Settings;''',
      'sql2': '''SELECT userId, name, capital FROM Users WHERE type IN ('money','both');''',
      'sql3':
          '''SELECT e.userId, u.name, e.effortPerc, e.globalUnits, u.months FROM Effort e, Users u WHERE e.unitId = -1 AND e.userId = u.userId;''',
      'sql4':
          '''SELECT e.userId, u.name, e.effortPerc, u.months FROM Effort e, Users u WHERE e.unitId = ${widget.unit.unitId} AND e.userId = u.userId;''',
      'sql5': '''SELECT t.userId,u.name, t.thresholdPerc FROM Threshold t, Users u WHERE t.unitId = ${widget.unit.unitId} AND t.userId = u.userId;''',
      'sql6': '''SELECT f.userId,u.name, f.foundingPerc FROM Founding f, Users u WHERE f.unitId = ${widget.unit.unitId} AND f.userId = u.userId;''',
      'sql7': isIntern
          ? '''SELECT transactionId,userId,userName,date,type,amount FROM Transaction WHERE date >= '${DateTime(currentYear, widget.unit.currentMonthOrYear, 1)}';'''
          : '''SELECT transactionId,userId,userName,date,type,amount FROM Transaction WHERE Year(date) >= ${widget.unit.currentMonthOrYear};''',
      'sql8': isIntern
          ? '''SELECT transactionId,date,type,amount FROM transactionsp WHERE category = 'reserve' AND date >= '${DateTime(currentYear, widget.unit.currentMonthOrYear, 1)}';'''
          : '''SELECT transactionId,date,type,amount FROM transactionsp WHERE category = 'reserve' AND Year(date) >= ${widget.unit.currentMonthOrYear};''',
      'sql9': '''SELECT transactionId,userId,userName,date,type,amount FROM transactiontemp  WHERE userName != 'reserveProfit';''',
      if (!isIntern)
        'sql10': '''SELECT MAX(max_date) AS lastDate FROM (
                          SELECT MAX(date) AS max_date FROM transaction
                          UNION ALL SELECT MAX(date) AS max_date FROM transactionothers
                          UNION ALL SELECT MAX(date) AS max_date FROM transactionsp
	                        UNION ALL SELECT MAX(date) AS max_date FROM transactiontemp
                        ) AS all_max_dates''',
    });

    caisse = double.parse(res[0][0]['caisse']);
    reserve = double.parse(res[0][0]['reserve']);
    reserveProfit = double.parse(res[0][0]['reserveProfit']);
    reference = int.parse(res[0][0]['reference']);
    if (!isIntern) lastTransactionDate = DateTime.parse(res[9][0]['lastDate']);

    for (var ele in res[1]) {
      moneyUsers.add(User(userId: int.parse(ele['userId']), name: ele['name'], capital: double.parse(ele['capital'])));
    }

    moneyUsers.sort((a, b) => a.name.compareTo(b.name));

    //add reserve to money users list
    moneyUsers.insert(0, User(userId: 0, name: 'Reserve', capital: reserve));

    Set<int> _userGlobalUbits = {};
    String _globalUnitsData = '';
    for (var ele in res[2]) {
      if (!isIntern || (isIntern && ele['months'][widget.unit.currentMonthOrYear - 1] == '1')) {
        _userGlobalUbits.clear();
        _globalUnitsData = ele['globalUnits'];

        if (_globalUnitsData.isNotEmpty) {
          for (var id in _globalUnitsData.split(',')) {
            _userGlobalUbits.add(int.parse(id));
          }
        }

        if (_userGlobalUbits.contains(widget.unit.unitId)) {
          globalEffortUsers.add(User(userId: int.parse(ele['userId']), name: ele['name'], effortPerc: double.parse(ele['effortPerc'])));
        }
      }
    }

    globalEffortUsers.sort((a, b) => a.name.compareTo(b.name));

    for (var ele in res[3]) {
      if (!isIntern || (isIntern && ele['months'][widget.unit.currentMonthOrYear - 1] == '1')) {
        unitEffortUsers.add(User(userId: int.parse(ele['userId']), name: ele['name'], effortPerc: double.parse(ele['effortPerc'])));
      }
    }

    unitEffortUsers.sort((a, b) => a.name.compareTo(b.name));

    if (!isIntern) {
      for (var user in globalEffortUsers) {
        user.evaluation = 0;
      }
      for (var user in unitEffortUsers) {
        user.evaluation = 0;
      }
    }

    for (var ele in res[4]) {
      thresholdUsers.add(User(userId: int.parse(ele['userId']), name: ele['name'], thresholdPerc: double.parse(ele['thresholdPerc'])));
    }

    thresholdUsers.sort((a, b) => a.name.compareTo(b.name));

    for (var ele in res[5]) {
      foundingUsers.add(User(userId: int.parse(ele['userId']), name: ele['name'], foundingPerc: double.parse(ele['foundingPerc'])));
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
      allTransactions.add(transaction);

      if ((isIntern && transaction.date.year == currentYear && transaction.date.month == widget.unit.currentMonthOrYear) ||
          (!isIntern && transaction.date.year == widget.unit.currentMonthOrYear)) {
        //filter the transactions of the calculated month or the calculated year if it is extern
        transactions.add(transaction);
        transactionsDays.add(DateTime(transaction.date.year, transaction.date.month, transaction.date.day));
      }
    }

    for (var ele in res[7]) {
      Transaction transaction = Transaction(
        transactionId: int.parse(ele['transactionId']),
        userId: 0,
        userName: 'Reserve',
        date: DateTime.parse(ele['date']),
        type: ele['type'],
        amount: double.parse(ele['amount']),
      );
      allTransactions.add(transaction);

      if ((isIntern && transaction.date.year == currentYear && transaction.date.month == widget.unit.currentMonthOrYear) ||
          (!isIntern && transaction.date.year == widget.unit.currentMonthOrYear)) {
        //filter the transactions of the calculated month or the calculated year if it is extern
        transactions.add(transaction);
        transactionsDays.add(DateTime(transaction.date.year, transaction.date.month, transaction.date.day));
      }
    }

    for (var ele in res[8]) {
      Transaction transaction = Transaction(
        transactionId: int.parse(ele['transactionId']),
        userId: ele['userName'] == 'reserve' ? 0 : int.parse(ele['userId']),
        userName: ele['userName'] == 'reserve' ? 'Reserve' : ele['userName'],
        date: DateTime.parse(ele['date']),
        type: ele['type'],
        amount: double.parse(ele['amount']),
      );
      allTransactions.add(transaction);
    }

    //  if extern unit we use 365 else we calculate number of days in current month
    daysInMonth = !isIntern
        ? DateTime(widget.unit.currentMonthOrYear + 1).difference(DateTime(widget.unit.currentMonthOrYear)).inDays
        : DateUtils.getDaysInMonth(currentYear, widget.unit.currentMonthOrYear);

    //if is intern unit we add the first day of the current month and next month
    //if is extern unit we add the first day of janury of the current year and next year
    transactionsDays.addAll(isIntern
        ? {
            DateTime(currentYear, widget.unit.currentMonthOrYear, 1),
            DateTime(currentYear, widget.unit.currentMonthOrYear + 1, 1),
          }
        : {
            DateTime(widget.unit.currentMonthOrYear, 1, 1),
            DateTime(widget.unit.currentMonthOrYear + 1, 1, 1),
          });

    transactionsDays = SplayTreeSet.from(transactionsDays);
    allTransactions.sort((tr1, tr2) => tr2.date.compareTo(tr1.date));
    transactions.sort((tr1, tr2) => tr1.date.compareTo(tr2.date));

    //reset the users capital to its value in the first day of the month
    for (var user in moneyUsers) {
      for (var trans in allTransactions) {
        if (trans.userId == user.userId) {
          trans.type == 'in' ? user.capital -= trans.amount : user.capital += trans.amount;
        }
      }
      //set initial capital of user
      if (user.capital.abs() < 0.001) user.capital = 0;
      user.initialCapital = user.capital;
    }

    setState(() => isloading = false);
  }

  void calculate() async {
    setState(() => isloading = true);
    iscalculated = true;
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
      // user.effort = (caEffort * user.effortPerc / 100);
      user.effort = caEffort * user.effortPerc / 100;

      // for extern units we calculate the user evaluation and months
      if (!isIntern) user.effort = calculateEvaluation(user.effort, user.evaluation) * user.monthsForExtern / 12;
      caTotalEffortUnit += user.effort;
    }

    caEffortGlobal = caEffort - caTotalEffortUnit;

    for (var user in globalEffortUsers) {
      // user.effort = (caEffortGlobal * user.effortPerc / 100) * user.evaluation / 100;
      user.effort = caEffortGlobal * user.effortPerc / 100;
      if (!isIntern) user.effort = calculateEvaluation(user.effort, user.evaluation) * user.monthsForExtern / 12;
    }

    //calculated money profit / number of days in month
    caMoneyProfitPerDay = caMoney / daysInMonth;

    // loop the list of days that has transactions
    for (var i = 0; i < transactionsDays.length - 1; i++) {
      //loop the list of transactions in the selected day
      //for the transactions list we loop all the list if unit type is intern else we loop only the transactions of currentMonthOrYear
      for (var caTrans in transactions) {
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
      int daysCountToNextTransaction = transactionsDays.elementAt(i + 1).difference(transactionsDays.elementAt(i)).inDays;

      // calculate the profitability
      profitability += caMoneyProfitPerDay / totalUsersCapital * daysCountToNextTransaction;

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

    caReserveProfit = moneyUsers[0].money;
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

    moneySQL += isIntern
        ? ' ON DUPLICATE KEY UPDATE money = money + VALUES(money);'
        : ' ON DUPLICATE KEY UPDATE capital = capital + VALUES(money) , moneyExtern = moneyExtern + VALUES(money);';
    effortUnitSQL += isIntern
        ? ' ON DUPLICATE KEY UPDATE effort = effort + VALUES(effort);'
        : ''' ON DUPLICATE KEY UPDATE type = 'both' , capital = capital + VALUES(effort) , effortExtern = effortExtern + VALUES(effort);''';
    effortGlobalSQL += isIntern
        ? ' ON DUPLICATE KEY UPDATE effort = effort + VALUES(effort);'
        : ''' ON DUPLICATE KEY UPDATE type = 'both' , capital = capital + VALUES(effort) , effortExtern = effortExtern + VALUES(effort);''';
    thresholdSQL += ' ON DUPLICATE KEY UPDATE threshold = threshold + VALUES(threshold);';
    foundingSQL += ' ON DUPLICATE KEY UPDATE founding = founding + VALUES(founding);';

    List<String> sqls = [];
    if (moneyUsers.isNotEmpty) sqls.add(moneySQL);

    if (unitEffortUsers.isNotEmpty) sqls.add(effortUnitSQL);

    if (globalEffortUsers.isNotEmpty) sqls.add(effortGlobalSQL);

    if (thresholdUsers.isNotEmpty) sqls.add(thresholdSQL);

    if (foundingUsers.isNotEmpty) sqls.add(foundingSQL);

    if (!isIntern) {
      //for extern unit we add the added profit to capital as transactions

      bool isNewYear = DateTime.now().year != currentYear;
      if (isNewYear) years.add(DateTime.now().year.toString());

      Set<int> usersId = {};
      for (var user in moneyUsers) {
        usersId.add(user.userId);
      }

      for (var user in globalEffortUsers) {
        //if user exist in moneys list we add the effort profit else we add the user to the list
        if (usersId.contains(user.userId)) {
          moneyUsers.firstWhere((element) => element.userId == user.userId).effort = user.effort;
        } else {
          moneyUsers.add(user);
        }
      }

      String transactionSQL =
          ''' INSERT INTO ${isNewYear ? 'transactiontemp' : 'transaction'} (reference,userId,userName,date,type,amount,${isNewYear ? '' : ' soldeUser,'}changeCaisse,soldeCaisse,note,amountOnLetter,intermediates,printingNotes,reciver) VALUES ''';
      String _type = unitProfitValue >= 0 ? 'in' : 'out';
      for (var user in moneyUsers) {
        user.capital += user.money + user.effort;
        if ((user.money + user.effort).abs() > 0.001) {
          transactionSQL +=
              '''('${currentYear % 100}/${reference.toString().padLeft(4, '0')}' ,${user.userId}, '${user.name}', '$date' , '$_type' , ${(user.money + user.effort).abs()} ,  ${isNewYear ? '' : '${user.capital},'} 0, $caisse , '${widget.unit.name} ${widget.unit.currentMonthOrYear}','${numberToArabicWords((user.money + user.effort).abs())}','','',''),''';
          reference++;
        }
      }

      transactionSQL = transactionSQL.substring(0, transactionSQL.length - 1) + ';';

      sqls.add(transactionSQL);

      if (caReserve != 0) {
        sqls.add(isNewYear
            ? '''INSERT INTO transactiontemp(reference,userId,userName,date,type,amount,changeCaisse,soldeCaisse,note,amountOnLetter,intermediates,printingNotes,reciver) VALUES ('${currentYear % 100}/${reference.toString().padLeft(4, '0')}' , -1 ,'reserve' , '$date' , '$_type' ,${caReserve.abs()} , 0, $caisse , '${widget.unit.name} ${widget.unit.currentMonthOrYear}','${numberToArabicWords(caReserve.abs())}','','','');'''
            : '''INSERT INTO transactionsp (reference,category,date,type,amount,solde,changeCaisse,soldeCaisse,note,amountOnLetter,intermediates,printingNotes,reciver) VALUES ('${currentYear % 100}/${reference.toString().padLeft(4, '0')}' ,'reserve' , '$date' , '$_type' ,${caReserve.abs()} , ${reserve + caReserve} , 0, $caisse , '${widget.unit.name} ${widget.unit.currentMonthOrYear}','${numberToArabicWords(caReserve.abs())}','','','');''');
        reference++;
      }
      if (caReserveProfit != 0) {
        sqls.add(
            '''INSERT INTO transactionsp (reference,category,date,type,amount,solde,changeCaisse,soldeCaisse,note,amountOnLetter,intermediates,printingNotes,reciver) VALUES ('${currentYear % 100}/${reference.toString().padLeft(4, '0')}' ,'reserveProfit' , '$date' , '$_type' ,${caReserveProfit.abs()} , ${reserveProfit + caReserveProfit}, 0, $caisse , '${widget.unit.name} ${widget.unit.currentMonthOrYear}','${numberToArabicWords(caReserveProfit.abs())}','','','');''');
        reference++;
      }
    }

    sqls.add(
        ''' UPDATE Units SET profit = profit + $unitProfitValue, profitability = profitability + $profitability, currentMonthOrYear = ${widget.unit.currentMonthOrYear + 1}  WHERE unitId = ${widget.unit.unitId}; ''');

    sqls.add(
        '''INSERT INTO unithistory(name, year, month, capital, profit, profitability, unitProfitability, reserve, donation, money, effort, threshold, founding) VALUES ('${widget.unit.name}',$currentYear,${!isIntern ? 0 : widget.unit.currentMonthOrYear},${widget.unit.capital},$unitProfitValue,$profitability,${caMoney / widget.unit.capital},$caReserve,$caDonation,$caMoney,$caEffort,$caThreshold,$caFounding);''');

    sqls.add(isIntern
        ? 'UPDATE settings SET profitability = profitability + $profitability , reserveYear = reserveYear + $caReserve , reserveProfitIntern = reserveProfitIntern + $caReserveProfit , donationProfitIntern = donationProfitIntern + $caDonation ;'
        : 'UPDATE settings SET profitability = profitability + $profitability , reserve = reserve + $caReserve , reserveProfit = reserveProfit + $caReserveProfit , donationProfit = donationProfit + $caDonation , reference = $reference;');

    await sqlQuery(insertUrl, {for (var sql in sqls) 'sql${sqls.indexOf(sql) + 1}': sql});
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MyApp(index: 'un')));
    snackBar(context, 'Calculation done successfully');
  }

  @override
  void initState() {
    isIntern = widget.unit.type == 'intern';
    loadData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: getHeight(context, .8),
      width: getWidth(context, .78),
      child: Column(
        children: [
          Container(
            alignment: Alignment.center,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${widget.unit.name} - ${widget.unit.type == 'extern' ? widget.unit.currentMonthOrYear : monthsOfYear[widget.unit.currentMonthOrYear - 1]}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20.0,
                    ),
                  ),
                ),
                myIconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icons.close,
                )
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
            child: isloading
                ? myProgress()
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0, right: 8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            mySizedBox(context),
                            if (!isIntern && iscalculated)
                              InkWell(
                                child: myText(myDateFormate.format(date), size: 20),
                                hoverColor: Colors.transparent,
                                onTap: () async {
                                  final DateTime? selected = await showDatePicker(
                                    context: context,
                                    initialDate: date,
                                    firstDate: lastTransactionDate,
                                    lastDate: DateTime.now(),
                                    locale: const Locale("fr", "FR"),
                                  );
                                  if (selected != null && selected != date) {
                                    DateTime _selectedDate = DateTime(
                                      selected.year,
                                      selected.month,
                                      selected.day,
                                      DateTime.now().hour,
                                      DateTime.now().minute,
                                      DateTime.now().second,
                                    );
                                    if (_selectedDate.isBefore(lastTransactionDate)) {
                                      _selectedDate = DateTime(
                                        selected.year,
                                        selected.month,
                                        selected.day,
                                        lastTransactionDate.hour,
                                        lastTransactionDate.minute,
                                        lastTransactionDate.second + 1,
                                      );
                                    }
                                    setState(() => date = _selectedDate);
                                  }
                                },
                              ),
                            Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  myTextField(
                                    context,
                                    controller: controller,
                                    hint: myCurrency(unitProfitHint),
                                    width: getWidth(context, .18),
                                    onChanged: ((text) => _unitProfitValue = text),
                                    autoFocus: true,
                                    onSubmited: ((text) {
                                      if (!iscalculated) {
                                        try {
                                          unitProfitValue = double.parse(_unitProfitValue);

                                          if (!isIntern &&
                                              (unitEffortUsers.where((user) => user.evaluation == 0).isNotEmpty ||
                                                  globalEffortUsers.where((user) => user.evaluation == 0).isNotEmpty)) {
                                            snackBar(context, 'add effort users evaluations');
                                            setState(() => bottemNavigationSelectedInex =
                                                unitEffortUsers.where((user) => user.evaluation == 0).isNotEmpty ? 4 : 5);
                                          } else {
                                            calculate();
                                          }
                                        } catch (e) {
                                          snackBar(context, 'numbers only !!!');
                                        }
                                      }
                                    }),
                                    enabled: !iscalculated,
                                  ),
                                  if (!iscalculated)
                                    myIconButton(
                                      icon: Icons.play_arrow,
                                      color: secondaryColor,
                                      onPressed: () {
                                        try {
                                          unitProfitValue = double.parse(_unitProfitValue);

                                          if (!isIntern &&
                                              (unitEffortUsers.where((user) => user.evaluation == 0).isNotEmpty ||
                                                  globalEffortUsers.where((user) => user.evaluation == 0).isNotEmpty)) {
                                            snackBar(context, 'add effort users evaluations');
                                            setState(() => bottemNavigationSelectedInex =
                                                unitEffortUsers.where((user) => user.evaluation == 0).isNotEmpty ? 4 : 5);
                                          } else {
                                            calculate();
                                          }
                                        } catch (e) {
                                          snackBar(context, 'number only !!!');
                                        }
                                      },
                                    )
                                ],
                              ),
                            ),
                            if (iscalculated)
                              myButton(context, width: getWidth(context, .07), onTap: () {
                                setState(() => isloading = true);
                                save();
                              }),
                          ],
                        ),
                      ),
                      const Divider(),
                      if (bottemNavigationSelectedInex == 0) Expanded(child: information()),
                      if (bottemNavigationSelectedInex == 1) Expanded(child: money()),
                      if (bottemNavigationSelectedInex == 2) Expanded(child: threshold()),
                      if (bottemNavigationSelectedInex == 3) Expanded(child: founding()),
                      if (bottemNavigationSelectedInex == 4) Expanded(child: effort()),
                      if (bottemNavigationSelectedInex == 5) Expanded(child: global()),
                      const Divider(),
                      BottomNavigationBar(
                        type: BottomNavigationBarType.fixed,
                        items: const <BottomNavigationBarItem>[
                          BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Information'),
                          BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Money'),
                          BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Threshold'),
                          BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Founding'),
                          BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Effort Unit'),
                          BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Effort Global'),
                        ],
                        selectedFontSize: 26,
                        unselectedFontSize: 18,
                        currentIndex: bottemNavigationSelectedInex,
                        onTap: (index) => setState(() => bottemNavigationSelectedInex = index),
                        selectedIconTheme: const IconThemeData(opacity: 0.0, size: 0),
                        unselectedIconTheme: const IconThemeData(opacity: 0.0, size: 0),
                        selectedItemColor: primaryColor,
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                      ),
                      mySizedBox(context),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget information() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        infoItem('Capital', myCurrency(widget.unit.capital), '', ''),
        infoItem(
          'Unit Profitability',
          myPercentage(caMoney / widget.unit.capital * 100),
          'Daily Profit',
          myCurrency(caMoneyProfitPerDay),
        ),
        infoItem(
          'Profitability',
          myPercentage(profitability * 100),
          'Weighted Capital',
          myCurrency(profitability == 0 ? 0 : caMoney / profitability),
        ),
        infoItem('Reserve %', myPercentage(widget.unit.reservePerc), 'Reserve', myCurrency(caReserve)),
        infoItem(
          'Donation %',
          myPercentage(widget.unit.donationPerc),
          'Donation',
          myCurrency(caDonation),
        ),
        infoItem('', '', 'Net Profit', myCurrency(caNetProfit)),
        infoItem(
          'Money %',
          myPercentage(widget.unit.moneyPerc),
          'Money',
          myCurrency(caMoney),
        ),
        infoItem(
          'Effort %',
          myPercentage(widget.unit.effortPerc),
          'Effort',
          myCurrency(caEffort),
        ),
        infoItem('', '', 'Effort Global', myCurrency(caEffortGlobal)),
        infoItem(
          'Threshold %',
          myPercentage(widget.unit.thresholdPerc),
          'Threshold',
          myCurrency(caThreshold),
        ),
        infoItem(
          'Founding %',
          myPercentage(widget.unit.foundingPerc),
          'Founding',
          myCurrency(caFounding),
        ),
      ],
    );
  }

  Widget infoItem(String title1, String value1, String title2, String value2) {
    return Row(
      children: [
        const Spacer(),
        SizedBox(
          width: getWidth(context, .3),
          child: value1.isEmpty
              ? const SizedBox()
              : Row(
                  children: [
                    Expanded(flex: 2, child: myText(title1)),
                    Expanded(flex: 3, child: myText(':      $value1', fontFamily: 'IBM')),
                  ],
                ),
        ),
        const Spacer(),
        SizedBox(
          width: getWidth(context, .3),
          child: value2.isEmpty
              ? const SizedBox()
              : Row(
                  children: [
                    Expanded(flex: 2, child: myText(title2)),
                    Expanded(flex: 3, child: myText(':      $value2', fontFamily: 'IBM')),
                  ],
                ),
        ),
      ],
    );
  }

  Widget money() {
    List<DataColumn> column = ['', 'Name', 'Initial Capital', 'Capital', 'Weighted Capital', 'Profit'].map((e) => dataColumn(context, e)).toList();
    List<DataRow> rows = moneyUsers
        .map(
          (user) => DataRow(cells: [
            dataCell(context, (moneyUsers.indexOf(user) + 1).toString()),
            dataCell(context, user.realName, textAlign: TextAlign.start),
            dataCell(context, myCurrency(user.initialCapital), textAlign: TextAlign.end),
            dataCell(context, myCurrency(user.capital), textAlign: TextAlign.end),
            dataCell(context, myCurrency(profitability == 0 ? 0 : user.money / profitability), textAlign: TextAlign.end),
            dataCell(context, myCurrency(user.money), textAlign: TextAlign.end),
          ]),
        )
        .toList();
    return moneyUsers.isEmpty
        ? Center(child: emptyList())
        : SingleChildScrollView(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    myText('Money  :  ${myCurrency(caMoney)} '),
                    mySizedBox(context),
                    if (caMoney != 0)
                      myIconButton(
                        onPressed: () => createExcel(
                          '${widget.unit.name} --- ${widget.unit.type == 'extern' ? widget.unit.currentMonthOrYear : '${monthsOfYear[widget.unit.currentMonthOrYear - 1]} $currentYear'}',
                          [
                            ['#', 'Name', 'Initial Capital', 'Capital', 'Weighted Capital', 'Profit'],
                            ...moneyUsers.map((user) => [
                                  moneyUsers.indexOf(user) + 1,
                                  user.name,
                                  user.initialCapital,
                                  user.capital,
                                  profitability == 0 ? 0 : user.money / profitability,
                                  user.money,
                                ])
                          ],
                        ),
                        icon: Icons.file_download,
                        color: primaryColor,
                      ),
                  ],
                ),
                mySizedBox(context),
                dataTable(context, columns: column, rows: rows),
              ],
            ),
          );
  }

  Widget threshold() {
    List<DataColumn> column = [
      '',
      'Name',
      'Threshold %',
      'Profit',
    ].map((e) => dataColumn(context, e)).toList();
    List<DataRow> rows = thresholdUsers
        .map(
          (user) => DataRow(cells: [
            dataCell(context, (thresholdUsers.indexOf(user) + 1).toString()),
            dataCell(context, user.realName, textAlign: TextAlign.start),
            dataCell(context, user.thresholdPerc.toString()),
            dataCell(context, myCurrency(user.threshold), textAlign: TextAlign.end),
          ]),
        )
        .toList();
    return thresholdUsers.isEmpty
        ? Center(child: emptyList())
        : SingleChildScrollView(
            child: Column(
              children: [
                myText('Threshold  :  ${myCurrency(caThreshold)} '),
                mySizedBox(context),
                dataTable(context, columns: column, rows: rows),
              ],
            ),
          );
  }

  Widget founding() {
    List<DataColumn> column = [
      '',
      'Name',
      'Founding %',
      'Profit',
    ].map((e) => dataColumn(context, e)).toList();
    List<DataRow> rows = foundingUsers
        .map(
          (user) => DataRow(cells: [
            dataCell(context, (foundingUsers.indexOf(user) + 1).toString()),
            dataCell(context, user.realName, textAlign: TextAlign.start),
            dataCell(context, user.foundingPerc.toString()),
            dataCell(context, myCurrency(user.founding), textAlign: TextAlign.end),
          ]),
        )
        .toList();
    return foundingUsers.isEmpty
        ? Center(child: emptyList())
        : SingleChildScrollView(
            child: Column(
              children: [
                myText('Founding  :  ${myCurrency(caFounding)} '),
                mySizedBox(context),
                dataTable(context, columns: column, rows: rows),
              ],
            ),
          );
  }

  Widget effort() {
    List<DataColumn> column = [
      '',
      'Name',
      'Effort %',
      if (!isIntern) 'Evaluation',
      if (!isIntern) 'Month',
      'Profit',
    ].map((e) => dataColumn(context, e)).toList();
    List<DataRow> rows = unitEffortUsers
        .map(
          (user) => DataRow(cells: [
            dataCell(context, (unitEffortUsers.indexOf(user) + 1).toString()),
            dataCell(context, user.realName, textAlign: TextAlign.start),
            dataCell(context, user.effortPerc.toString()),
            if (!isIntern)
              DataCell(myTextField(context,
                  isNumberOnly: true,
                  noBorder: true,
                  enabled: !iscalculated,
                  hint: myPercentage(user.evaluation),
                  onSubmited: (value) => setState(() {}),
                  onChanged: ((value) => user.evaluation = double.parse(value)))),
            if (!isIntern)
              DataCell(myTextField(context,
                  isNumberOnly: true,
                  noBorder: true,
                  enabled: !iscalculated,
                  hint: user.monthsForExtern.toString(),
                  onSubmited: (value) => setState(() {}),
                  onChanged: ((value) => user.monthsForExtern = int.parse(value)))),
            dataCell(context, myCurrency(user.effort), textAlign: TextAlign.end),
          ]),
        )
        .toList();
    return unitEffortUsers.isEmpty
        ? Center(child: emptyList())
        : SingleChildScrollView(
            child: Column(
              children: [
                myText('Effort  :  ${myCurrency(caEffort)} '),
                mySizedBox(context),
                dataTable(context, columns: column, rows: rows),
              ],
            ),
          );
  }

  Widget global() {
    List<DataColumn> column = [
      '',
      'Name',
      'Effort %',
      if (!isIntern) 'Evaluation',
      if (!isIntern) 'Month',
      'Profit',
    ].map((e) => dataColumn(context, e)).toList();
    List<DataRow> rows = globalEffortUsers
        .map(
          (user) => DataRow(cells: [
            dataCell(context, (globalEffortUsers.indexOf(user) + 1).toString()),
            dataCell(context, user.realName, textAlign: TextAlign.start),
            dataCell(context, user.effortPerc.toString()),
            if (!isIntern)
              DataCell(myTextField(context,
                  isNumberOnly: true,
                  noBorder: true,
                  enabled: !iscalculated,
                  hint: myPercentage(user.evaluation),
                  onSubmited: (value) => setState(() {}),
                  onChanged: ((value) => user.evaluation = double.parse(value)))),
            if (!isIntern)
              DataCell(myTextField(context,
                  isNumberOnly: true,
                  noBorder: true,
                  enabled: !iscalculated,
                  hint: user.monthsForExtern.toString(),
                  onSubmited: (value) => setState(() {}),
                  onChanged: ((value) => user.monthsForExtern = int.parse(value)))),
            dataCell(context, myCurrency(user.effort), textAlign: TextAlign.end),
          ]),
        )
        .toList();
    return globalEffortUsers.isEmpty
        ? Center(child: emptyList())
        : SingleChildScrollView(
            child: Column(
              children: [
                myText('Effort Global  :  ${myCurrency(caEffortGlobal)} '),
                mySizedBox(context),
                dataTable(context, columns: column, rows: rows),
              ],
            ),
          );
  }
}
