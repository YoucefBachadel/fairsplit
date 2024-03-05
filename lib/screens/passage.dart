import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:toggle_switch/toggle_switch.dart';

import '/main.dart';
import '/models/transaction.dart';
import '/models/unit.dart';
import '/models/user.dart';
import '/shared/functions.dart';
import '/shared/widgets.dart';
import '/shared/constants.dart';

class Passage extends StatefulWidget {
  const Passage({super.key});

  @override
  State<Passage> createState() => _PassageState();
}

class _PassageState extends State<Passage> {
  List<User> users = [];
  List<Unit> units = [];
  List<Transaction> transactionsTemp = [];
  pw.Document pdf = pw.Document();
  TextEditingController zakatController = TextEditingController(), materialsController = TextEditingController();
  double zakatQuorum = 0, materialsValue = 0;
  String _zakatQuorum = '', _materialsValue = '';
  double caisse = 0, reserve = 0, reserveYear = 0, reserveProfit = 0, donation = 0, donationProfit = 0, zakat = 0;
  double totalCapital = 0, totalZakat = 0, totalIn = 0, totalOut = 0, reserveZakat = 0;
  double materialsValuePerc = 0;
  int reference = 0;
  int bottemNavigationSelectedInex = 0;
  bool isLoading = true, isCalculated = false, isPrinted = false;
  String printIntro = '', printConclusion = '';
  PdfPageFormat pageFormat = PdfPageFormat.a5;
  DateTime selectedDate = DateTime.now();
  late DateTime lastTransactionDate;

  void loadData() async {
    var data = await sqlQuery(selectUrl, {
      'sql1': '''SELECT u.*,
                    (SELECT COALESCE(SUM(amount),0)FROM transaction t WHERE t.userId =u.userId AND t.type = 'in') AS totalIn,
                    (SELECT COALESCE(SUM(amount),0)FROM transaction t WHERE t.userId =u.userId AND t.type = 'out') AS totalOut 
            FROM Users u;''',
      'sql2': 'SELECT * FROM Units;',
      'sql3': 'SELECT * FROM transactiontemp;',
      'sql4':
          'SELECT caisse, reserve, donation, reserveYear, reserveProfit, reserveProfitIntern, donationProfit, donationProfitIntern, zakat, reference FROM settings;',
      'sql5': '''SELECT MAX(max_date) AS lastDate FROM (
                          SELECT MAX(date) AS max_date FROM transaction
                          UNION ALL SELECT MAX(date) AS max_date FROM transactionothers
                          UNION ALL SELECT MAX(date) AS max_date FROM transactionsp
	                        UNION ALL SELECT MAX(date) AS max_date FROM transactiontemp
                        ) AS all_max_dates''',
    });
    var dataUsers = data[0];
    var dataUnits = data[1];
    var dataTransactionTemp = data[2];
    var dataSettings = data[3][0];
    lastTransactionDate = DateTime.parse(data[4][0]['lastDate']);

    caisse = double.parse(dataSettings['caisse']);
    reserve = double.parse(dataSettings['reserve']);
    reserveYear = double.parse(dataSettings['reserveYear']);
    reserveProfit = double.parse(dataSettings['reserveProfit']) + double.parse(dataSettings['reserveProfitIntern']);
    donation = double.parse(dataSettings['donation']);
    donationProfit = double.parse(dataSettings['donationProfit']) + double.parse(dataSettings['donationProfitIntern']);
    zakat = double.parse(dataSettings['zakat']);
    reference = int.parse(dataSettings['reference']);

    users = toUsers(dataUsers, [], [], [], ispassage: true);
    for (var ele in dataUnits) {
      units.add(Unit(
        unitId: int.parse(ele['unitId']),
        name: ele['name'],
        type: ele['type'],
        capital: double.parse(ele['capital']),
        profit: double.parse(ele['profit']),
        profitability: double.parse(ele['profitability']),
        reservePerc: double.parse(ele['reservePerc']),
        donationPerc: double.parse(ele['donationPerc']),
        moneyPerc: double.parse(ele['moneyPerc']),
        effortPerc: double.parse(ele['effortPerc']),
        thresholdPerc: double.parse(ele['thresholdPerc']),
        foundingPerc: double.parse(ele['foundingPerc']),
        currentMonthOrYear: int.parse(ele['currentMonthOrYear']),
      ));
    }
    units.sort((a, b) => a.name.compareTo(b.name));

    for (var ele in dataTransactionTemp) {
      transactionsTemp.add(Transaction(
        transactionId: int.parse(ele['transactionId']),
        reference: ele['reference'],
        userId: int.parse(ele['userId']),
        userName: ele['userName'],
        date: DateTime.parse(ele['date']),
        type: ele['type'],
        amount: double.parse(ele['amount']),
        soldeUser: 0,
        isCaisseChanged: int.parse(ele['changeCaisse']) == 1,
        soldeCaisse: double.parse(ele['soldeCaisse']),
        note: ele['note'],
        reciver: ele['reciver'],
        amountOnLetter: ele['amountOnLetter'],
        intermediates: ele['intermediates'],
        printingNotes: ele['printingNotes'],
      ));
    }

    // reset Users Capitals To 31-12
    for (var user in users) {
      for (var trans in transactionsTemp.where((element) => element.userId == user.userId)) {
        if (trans.type == 'in') {
          user.capital -= trans.amount;
          user.newCapital -= trans.amount;
        } else {
          user.capital += trans.amount;
          user.newCapital += trans.amount;
        }
      }
      if (user.capital.abs() < 0.001) user.capital = 0;
      if (user.newCapital.abs() < 0.001) user.newCapital = 0;
      totalCapital += user.capital;
      totalIn += user.totalIn;
      totalOut += user.totalOut;
    }

    //reset reserv to 31-12
    for (var trans in transactionsTemp.where((element) => element.userId == -1)) {
      trans.type == 'in' ? reserve -= trans.amount : reserve += trans.amount;
    }

    setState(() => isLoading = false);
  }

  void calculate() async {
    zakatController.clear();
    materialsController.clear();

    //calculate zakat for each user
    materialsValuePerc = materialsValue / (totalCapital + reserve);

    double _reserveForZakat = (reserve - (reserve * materialsValuePerc)) + reserveYear + reserveProfit;

    if (_reserveForZakat >= zakatQuorum) reserveZakat = _reserveForZakat * 0.026;

    for (var user in users) {
      double _userCapitalForZakat = (user.capital - (user.capital * materialsValuePerc)) + user.money + user.threshold + user.founding + user.effort;

      user.isUnderZakatQuorum = _userCapitalForZakat < zakatQuorum;
      user.zakat = _userCapitalForZakat * 0.026;
      totalZakat += user.zakat;

      user.elhawl = user.initialCapital >= zakatQuorum;
      user.zakatOut = user.elhawl;
      user.showZakat = user.elhawl;
    }

    setState(() => isCalculated = true);
  }

  void passage() async {
    List<String> sqls = [];

    // insert user history
    var userHistory =
        'INSERT INTO userhistory(name, year, startCapital, totalIn, totalOut, endCapital, weightedCapital, moneyProfit, thresholdProfit, foundingProfit, effortProfit, externProfit, totalProfit, newCapital, zakat) VALUES ';
    for (var user in users) {
      if (!user.zakatOut && !user.zakatOutToZakatCaisse) user.zakat = 0;

      userHistory +=
          '''('${user.name}',$currentYear,${user.initialCapital},${user.totalIn},${user.totalOut},${user.capital},${user.weightedCapital},${user.money + user.moneyExtern},${user.threshold},${user.founding},${user.effort + user.effortExtern},${user.externProfit},${user.totalProfit},${user.newCapital},${user.zakat}),''';
    }
    userHistory = userHistory.substring(0, userHistory.length - 1) + ';';
    sqls.add(userHistory);

    //move user profit to it's capital and insert it as transactions in 01-01
    var userTransaction =
        'INSERT INTO transaction(reference, userId, userName, date, type, amount, soldeUser, changeCaisse, soldeCaisse, note, amountOnLetter, intermediates, printingNotes, reciver) VALUES ';
    DateTime date = DateTime(currentYear + 1, 1, 1, 0, 0, 0).subtract(const Duration(seconds: 1));
    for (var user in users) {
      double userTotalProfitWithoutExtern = user.money + user.threshold + user.founding + user.effort;
      if (user.newCapital.abs() < 0.001) user.newCapital = 0;
      user.capital = user.newCapital;

      if (userTotalProfitWithoutExtern != 0) {
        userTransaction +=
            '''('${currentYear % 100}/${reference.toString().padLeft(4, '0')}' , ${user.userId} , '${user.name}' , '$date' , '${userTotalProfitWithoutExtern > 0 ? 'in' : 'out'}' ,${userTotalProfitWithoutExtern.abs()} , ${user.newCapital} , 0, $caisse , 'Passage_$currentYear' , '${numberToArabicWords(userTotalProfitWithoutExtern.abs())}' , '' , '' , '' ),''';
        reference++;
      }
    }
    userTransaction = userTransaction.substring(0, userTransaction.length - 1) + ';';
    sqls.add(userTransaction);

    //move reserveyear to reserve and dontionprofit to donation with transaction
    reserve += reserveYear;
    sqls.add(
        '''INSERT INTO transactionsp (reference,category,date,type,amount,solde,changeCaisse,soldeCaisse,note,amountOnLetter,intermediates,printingNotes,reciver) VALUES ('${currentYear % 100}/${reference.toString().padLeft(4, '0')}' ,'reserve' , '$date' , '${reserveYear >= 0 ? 'in' : 'out'}' ,${reserveYear.abs()} ,$reserve , 0, $caisse , 'Passage_$currentYear','${numberToArabicWords(reserveYear.abs())}','','','');''');
    reference++;
    donation += donationProfit;
    sqls.add(
        '''INSERT INTO transactionsp (reference,category,date,type,amount,solde,changeCaisse,soldeCaisse,note,amountOnLetter,intermediates,printingNotes,reciver) VALUES ('${currentYear % 100}/${reference.toString().padLeft(4, '0')}' ,'donation' , '$date' , '${donationProfit >= 0 ? 'in' : 'out'}' ,${donationProfit.abs()} ,$donation , 0, $caisse , 'Passage_$currentYear','${numberToArabicWords(donationProfit.abs())}','','','');''');

    //move transaction temp to oraginal table
    var reserveTempTransaction =
        'INSERT INTO transactionsp (reference,category,date,type,amount,solde,changeCaisse,soldeCaisse,note,amountOnLetter,intermediates,printingNotes,reciver) VALUES ';
    var userTempTransaction =
        'INSERT INTO transaction (reference, userId, userName, date, type, amount, soldeUser, changeCaisse, soldeCaisse, note, amountOnLetter, intermediates, printingNotes, reciver) VALUES ';

    for (var trans in transactionsTemp) {
      if (trans.userId == -1) {
        trans.type == 'in' ? reserve += trans.amount : reserve -= trans.amount;
        reserveTempTransaction +=
            '''('${trans.reference}' ,'reserve' ,'${trans.date}' ,'${trans.type}' ,${trans.amount} ,$reserve , ${trans.isCaisseChanged ? 1 : 0}, ${trans.soldeCaisse} ,'${trans.note}' ,'${trans.amountOnLetter}','${trans.intermediates}','${trans.printingNotes}','${trans.reciver}'),''';
      } else {
        int userIndex = users.indexOf(users.firstWhere((user) => user.userId == trans.userId));
        trans.type == 'in' ? users[userIndex].capital += trans.amount : users[userIndex].capital -= trans.amount;
        userTempTransaction +=
            '''('${trans.reference}' , ${trans.userId} , '${trans.userName}' , '${trans.date}' , '${trans.type}' ,${trans.amount} , ${users[userIndex].capital} , ${trans.isCaisseChanged ? 1 : 0}, ${trans.soldeCaisse} , '${trans.note}' , '${trans.amountOnLetter}' , '${trans.intermediates}' , '${trans.printingNotes}' , '${trans.reciver}' ),''';
      }
    }

    if (userTempTransaction[userTempTransaction.length - 1] == ',') {
      userTempTransaction = userTempTransaction.substring(0, userTempTransaction.length - 1) + ';';
      sqls.add(userTempTransaction);
    }
    if (reserveTempTransaction[reserveTempTransaction.length - 1] == ',') {
      reserveTempTransaction = reserveTempTransaction.substring(0, reserveTempTransaction.length - 1) + ';';
      sqls.add(reserveTempTransaction);
    }

    //clear transaction temp table
    sqls.add('DELETE FROM transactiontemp;');

    //insert zakat transactions
    currentYear++;
    reference = 1;

    double totalToZakat = 0;
    int _changeCaisse = 0;
    date = selectedDate;
    var zakatTransactions =
        'INSERT INTO transaction (reference, userId, userName, date, type, amount, soldeUser,changeCaisse, soldeCaisse, note, amountOnLetter, intermediates, printingNotes, reciver) VALUES ';

    for (var user in users) {
      if (user.zakatOut || user.zakatOutToZakatCaisse) {
        _changeCaisse = 0;
        user.capital -= user.zakat;
        if (user.zakatOutToZakatCaisse) totalToZakat += user.zakat;
        if (user.zakatOut) {
          caisse -= user.zakat;
          _changeCaisse = 1;
          date = date.add(const Duration(seconds: 1));
        }

        zakatTransactions +=
            '''('${currentYear % 100}/${reference.toString().padLeft(4, '0')}' , ${user.userId} , '${user.name}' , '$date' , 'out' ,${user.zakat} , ${user.capital} , $_changeCaisse , $caisse , 'زكاة ${currentYear - 1}' , '${numberToArabicWords(user.zakat)}' , '' , '' , '' ),''';
        reference++;
      }
    }
    if (zakatTransactions[zakatTransactions.length - 1] == ',') {
      zakatTransactions = zakatTransactions.substring(0, zakatTransactions.length - 1) + ';';
      sqls.add(zakatTransactions);
    }

    //insert zakat Transaction
    if (reserveZakat != 0) {
      reserve -= reserveZakat;
      totalToZakat += reserveZakat;
      sqls.add(
          '''INSERT INTO transactionsp (reference,category,date,type,amount,solde,changeCaisse,soldeCaisse,note,amountOnLetter,intermediates,printingNotes,reciver) VALUES ('${currentYear % 100}/${reference.toString().padLeft(4, '0')}' ,'reserve' , '$date' , 'out' ,$reserveZakat ,$reserve , 0, $caisse , 'زكاة ${currentYear - 1}','${numberToArabicWords(reserveZakat)}','','','');''');
      reference++;
    }

    //insert users zakat total to zakat caisse
    if (totalToZakat != 0) {
      zakat += totalToZakat;
      sqls.add(
          '''INSERT INTO transactionsp (reference,category,date,type,amount,solde,changeCaisse,soldeCaisse,note,amountOnLetter,intermediates,printingNotes,reciver) VALUES ('${currentYear % 100}/${reference.toString().padLeft(4, '0')}' ,'zakat' , '$date' , 'in' ,$totalToZakat ,$zakat , 0, $caisse , 'Passage_${currentYear - 1}','${numberToArabicWords(totalToZakat)}','','','');''');
      reference++;
    }

    //update setting
    sqls.add(
        'UPDATE settings SET caisse=$caisse ,reserve=$reserve ,reserveYear=0 ,donation=$donation ,zakat=$zakat ,profitability=0 ,reserveProfit=$reserveProfit ,reserveProfitIntern=0 ,donationProfit=0 ,donationProfitIntern=0 ,currentYear=$currentYear ,reference=$reference');

    //update unit informations
    sqls.add('UPDATE units SET profit=0,profitability=0;');
    sqls.add('''UPDATE units SET currentMonthOrYear=1 WHERE type='intern';''');

    //update users information
    var userInfo = 'INSERT INTO users(userId, capital, initialCapital, money, moneyExtern, threshold, founding, effort, effortExtern) VALUES ';
    for (var user in users) {
      userInfo += '''(${user.userId}, ${user.capital}, ${user.newCapital}, 0,0,0,0,0,0),''';
    }
    userInfo = userInfo.substring(0, userInfo.length - 1);
    userInfo +=
        ' ON DUPLICATE KEY UPDATE capital = VALUES(capital),initialCapital = VALUES(initialCapital),money = 0,moneyExtern = 0,threshold = 0,founding = 0,effort = 0,effortExtern = 0;';
    sqls.add(userInfo);

    await sqlQuery(insertUrl, {for (var sql in sqls) 'sql${sqls.indexOf(sql) + 1}': sql});
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MyApp(index: 'da')));
    snackBar(context, 'Passage done successfully');
  }

  pw.Widget userInfoItem(String titel, String data) {
    return pw.Row(children: [
      pw.Expanded(
        child: pw.Container(
            alignment: pw.Alignment.center,
            child: pdfData(data),
            padding: pw.EdgeInsets.all(data.isEmpty ? 8.8 : 0),
            decoration: pw.BoxDecoration(border: pw.Border.all(width: .5))),
      ),
      pw.Expanded(
        child: pw.Container(alignment: pw.Alignment.center, child: pdfData(titel), decoration: pw.BoxDecoration(border: pw.Border.all(width: .5))),
      ),
    ]);
  }

  pw.MultiPage page(User user) {
    return pdfPage(pdfPageFormat: pageFormat, build: [
      pw.Center(child: pdfTitle('بسم الله الرحمان الرحيم')),
      pdfSizedBox(context),
      pw.Center(child: pdfTitle('التقرير العام لسنة $currentYear')),
      pdfSizedBox(context),
      pw.Row(children: [
        pdfData(myDateFormate.format(selectedDate)),
        pdfTitle('التاريخ   '),
        pw.Spacer(),
        pdfData(user.realName),
        pdfTitle('اﻹسم   '),
      ]),
      pdfSizedBox(context),
      pdfData(printIntro),
      pdfSizedBox(context),
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 30),
        child: pw.Column(children: [
          userInfoItem('رأس المال اﻹفتتاحي', myCurrency(user.initialCapital)),
          userInfoItem('اﻹيداعات', myCurrency(user.totalIn)),
          userInfoItem('السحوبات', myCurrency(user.totalOut)),
          if (user.money + user.moneyExtern != 0) userInfoItem('أرباح المال', myCurrency(user.money + user.moneyExtern)),
          if (user.threshold != 0) userInfoItem('أرباح العتبة', myCurrency(user.threshold)),
          if (user.founding != 0) userInfoItem('أرباح التأسيس', myCurrency(user.founding)),
          if (user.effort + user.effortExtern != 0) userInfoItem('أرباح الجهد', myCurrency(user.effort + user.effortExtern)),
          userInfoItem('''رأس المال الجديد${user.showZakat ? ' (دون حذف الزكاة)' : ''}''', myCurrency(user.newCapital)),
          if (user.showZakat) userInfoItem('الزكاة', myCurrency(user.zakat)),
        ]),
      ),
      pdfSizedBox(context),
      pdfData(printConclusion),
      pdfSizedBox(context),
    ]);
  }

  Widget printPageBuilder() {
    pdf = pw.Document();

    for (var user in users) {
      pdf.addPage(page(user));
    }

    pdf.addPage(pdfPage(pdfPageFormat: pageFormat, build: [
      pw.Center(child: pdfTitle('بسم الله الرحمان الرحيم')),
      pdfSizedBox(context),
      pw.Center(child: pdfTitle('التقرير العام لسنة $currentYear')),
      pdfSizedBox(context),
      pw.Row(children: [
        pdfData(myDateFormate.format(selectedDate)),
        pdfTitle('التاريخ   '),
        pw.Spacer(),
        pdfTitle('اﻹسم   '),
      ]),
      pdfSizedBox(context),
      pdfData(printIntro),
      pdfSizedBox(context),
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 30),
        child: pw.Column(children: [
          userInfoItem('رأس المال اﻹفتتاحي', ''),
          userInfoItem('اﻹيداعات', ''),
          userInfoItem('السحوبات', ''),
          userInfoItem('أرباح المال', ''),
          userInfoItem('أرباح العتبة', ''),
          userInfoItem('أرباح التأسيس', ''),
          userInfoItem('أرباح الجهد', ''),
          userInfoItem('رأس المال الجديد (دون حذف الزكاة)', ''),
          userInfoItem('الزكاة', ''),
        ]),
      ),
      pdfSizedBox(context),
      pdfData(printConclusion),
      pdfSizedBox(context),
    ]));

    pdf.addPage(pdfPage(pdfPageFormat: pageFormat, build: [
      pw.Center(child: pdfTitle('بسم الله الرحمان الرحيم')),
      pdfSizedBox(context),
      pw.Center(child: pdfTitle('التقرير العام لسنة $currentYear')),
      pdfSizedBox(context),
      pw.Row(children: [
        pdfData(myDateFormate.format(selectedDate)),
        pdfTitle('التاريخ   '),
        pw.Spacer(),
        pdfTitle('اﻹسم   '),
      ]),
      pdfSizedBox(context),
      pdfData(printIntro),
      pdfSizedBox(context),
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 30),
        child: pw.Column(children: [
          userInfoItem('رأس المال اﻹفتتاحي', ''),
          userInfoItem('اﻹيداعات', ''),
          userInfoItem('السحوبات', ''),
          userInfoItem('أرباح المال', ''),
          userInfoItem('أرباح العتبة', ''),
          userInfoItem('أرباح التأسيس', ''),
          userInfoItem('أرباح الجهد', ''),
          userInfoItem('رأس المال الجديد', ''),
        ]),
      ),
      pdfSizedBox(context),
      pdfData(printConclusion),
      pdfSizedBox(context),
    ]));

    return SizedBox(width: getWidth(context, .392), child: pdfPreview(context, pdf, 'Passage_$currentYear'));
  }

  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: getHeight(context, .8),
      width: getWidth(context, .78),
      child: Column(children: [
        Container(
          alignment: Alignment.center,
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Passage',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20.0,
                  ),
                ),
              ),
              myIconButton(onPressed: () => Navigator.pop(context), icon: Icons.close)
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
          child: isLoading
              ? myProgress()
              : Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (isCalculated)
                            InkWell(
                              child: myText(myDateFormate.format(selectedDate), size: 20),
                              hoverColor: Colors.transparent,
                              onTap: () async {
                                final DateTime? selected = await showDatePicker(
                                  context: context,
                                  initialDate: selectedDate,
                                  firstDate: lastTransactionDate,
                                  lastDate: DateTime.now(),
                                  locale: const Locale("fr", "FR"),
                                );
                                if (selected != null && selected != selectedDate) {
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
                                  setState(() => selectedDate = _selectedDate);
                                }
                              },
                            ),
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Column(
                                  children: [
                                    const Text('Zakat'),
                                    myTextField(
                                      context,
                                      controller: zakatController,
                                      hint: myCurrency(zakatQuorum),
                                      width: getWidth(context, .10),
                                      isNumberOnly: true,
                                      autoFocus: true,
                                      onChanged: ((text) => setState(() => _zakatQuorum = text)),
                                      enabled: !isCalculated,
                                    ),
                                  ],
                                ),
                                mySizedBox(context),
                                Column(
                                  children: [
                                    const Text('Materials'),
                                    myTextField(
                                      context,
                                      controller: materialsController,
                                      hint: myCurrency(materialsValue),
                                      width: getWidth(context, .10),
                                      isNumberOnly: true,
                                      onChanged: ((text) => setState(() => _materialsValue = text)),
                                      enabled: !isCalculated,
                                    ),
                                  ],
                                ),
                                if (zakatController.text.isNotEmpty && materialsController.text.isNotEmpty)
                                  myIconButton(
                                    icon: Icons.play_arrow,
                                    color: secondaryColor,
                                    size: 24,
                                    onPressed: () {
                                      zakatQuorum = double.parse(_zakatQuorum);
                                      materialsValue = double.parse(_materialsValue);
                                      calculate();
                                    },
                                  )
                              ],
                            ),
                          ),
                          if (isCalculated)
                            myButton(
                              context,
                              width: getWidth(context, .07),
                              text: 'Passage',
                              noIcon: true,
                              enabled: isPrinted,
                              onTap: () async {
                                await createDialog(
                                    context,
                                    Container(
                                      padding: const EdgeInsets.all(12.0),
                                      decoration: BoxDecoration(
                                        color: scaffoldColor,
                                        border: Border.all(width: 2.0),
                                        borderRadius: BorderRadius.circular(12.0),
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Passage Confirmation',
                                            textAlign: TextAlign.center,
                                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                                          ),
                                          SizedBox(width: getWidth(context, .16), child: const Divider()),
                                          mySizedBox(context),
                                          myButton(
                                            context,
                                            onTap: () {
                                              setState(() => isLoading = true);
                                              passage();
                                              Navigator.pop(context);
                                            },
                                            noIcon: true,
                                            text: 'Confirm',
                                          )
                                        ],
                                      ),
                                    ),
                                    dismissable: true);
                              },
                            ),
                        ],
                      ),
                      const Divider(),
                      Expanded(
                        child: Row(
                          children: [
                            zakatUsersSelector(),
                            const VerticalDivider(),
                            Expanded(child: printDetails()),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ]),
    );
  }

  Widget zakatUsersSelector() {
    return !isCalculated
        ? SizedBox(width: getWidth(context, .35), child: emptyList())
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              mySizedBox(context),
              myText('Reserve Zakat : ${myCurrency(reserveZakat)}', size: 20),
              mySizedBox(context),
              Expanded(
                child: SingleChildScrollView(
                  child: dataTable(
                    context,
                    columns: [
                      dataColumn(context, 'Name'),
                      dataColumn(context, 'Amount'),
                      dataColumn(context, 'Enable'),
                      dataColumn(context, 'Out'),
                      dataColumn(context, 'Out To Zakat'),
                      dataColumn(context, 'Show'),
                    ],
                    rows: users
                        .map((e) => DataRow(
                                onSelectChanged: (value) {},
                                color: e.isUnderZakatQuorum ? MaterialStatePropertyAll(Colors.red[100]) : null,
                                cells: [
                                  DataCell(Container(
                                    alignment: Alignment.center,
                                    width: getWidth(context, .18),
                                    child: Text(
                                      e.realName,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontFamily: 'IBM'),
                                    ),
                                  )),
                                  DataCell(Container(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      myCurrency(e.zakat),
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontFamily: 'IBM'),
                                    ),
                                  )),
                                  DataCell(Center(
                                    child: Checkbox(
                                      value: e.elhawl,
                                      onChanged: (bool? value) => setState(() {
                                        if (value == true) {
                                          e.elhawl = true;
                                        } else if (value == false) {
                                          e.elhawl = false;
                                          e.zakatOut = false;
                                          e.zakatOutToZakatCaisse = false;
                                          e.showZakat = false;
                                        }
                                      }),
                                    ),
                                  )),
                                  DataCell(Container(
                                    alignment: Alignment.center,
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    child: !e.elhawl
                                        ? const SizedBox()
                                        : Checkbox(
                                            value: e.zakatOut,
                                            onChanged: (bool? value) => setState(() {
                                              if (value == true) {
                                                e.zakatOut = true;
                                                e.zakatOutToZakatCaisse = false;
                                                e.showZakat = true;
                                              } else if (value == false) {
                                                e.zakatOut = false;
                                              }
                                            }),
                                          ),
                                  )),
                                  DataCell(!e.elhawl
                                      ? const SizedBox()
                                      : Center(
                                          child: Checkbox(
                                            value: e.zakatOutToZakatCaisse,
                                            onChanged: (bool? value) => setState(() {
                                              if (value == true) {
                                                e.zakatOutToZakatCaisse = true;
                                                e.zakatOut = false;
                                                e.showZakat = true;
                                              } else if (value == false) {
                                                e.zakatOutToZakatCaisse = false;
                                              }
                                            }),
                                          ),
                                        )),
                                  DataCell(!e.elhawl
                                      ? const SizedBox()
                                      : Container(
                                          alignment: Alignment.center,
                                          padding: const EdgeInsets.only(left: 8),
                                          child: Checkbox(
                                            value: e.showZakat,
                                            onChanged: (bool? value) => e.zakatOut || e.zakatOutToZakatCaisse
                                                ? null
                                                : setState(() {
                                                    if (value == true) {
                                                      e.showZakat = true;
                                                    } else if (value == false) {
                                                      e.showZakat = false;
                                                    }
                                                  }),
                                          ),
                                        )),
                                ]))
                        .toList(),
                  ),
                ),
              ),
            ],
          );
  }

  Widget printDetails() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: myText('Type')),
                Expanded(
                  flex: 4,
                  child: Row(
                    children: [
                      ToggleSwitch(
                        minWidth: getWidth(context, .05),
                        minHeight: getHeight(context, .035),
                        borderWidth: 1,
                        inactiveBgColor: Colors.white,
                        borderColor: const [Colors.black],
                        activeBgColors: [
                          [Colors.green[800]!],
                          [Colors.green[800]!],
                        ],
                        initialLabelIndex: pageFormat == PdfPageFormat.a5 ? 0 : 1,
                        labels: const ['A5', 'A4'],
                        onToggle: (index) {
                          pageFormat = index == 0 ? PdfPageFormat.a5 : PdfPageFormat.a4;
                          setState(() => isPrinted = false);
                        },
                      ),
                    ],
                  ),
                ),
                if (isCalculated)
                  FloatingActionButton(
                      mini: true,
                      child: const Icon(Icons.print),
                      onPressed: () async {
                        setState(() => isPrinted = true);
                        await createDialog(context, printPageBuilder(), dismissable: true);
                      })
              ],
            ),
            mySizedBox(context),
            myText('Introduction'),
            mySizedBox(context),
            TextFormField(
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.start,
              minLines: 14,
              maxLines: 14,
              textDirection: TextDirection.rtl,
              onChanged: (value) {
                printIntro = value;
                setState(() => isPrinted = false);
              },
              decoration: const InputDecoration(
                hintTextDirection: TextDirection.rtl,
                contentPadding: EdgeInsets.all(12),
                border: OutlineInputBorder(
                  gapPadding: 0,
                  borderSide: BorderSide(width: 0.5),
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
            ),
            mySizedBox(context),
            myText('Conclusion'),
            mySizedBox(context),
            TextFormField(
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.start,
              minLines: 14,
              maxLines: 14,
              textDirection: TextDirection.rtl,
              onChanged: (value) {
                printConclusion = value;
                setState(() => isPrinted = false);
              },
              decoration: const InputDecoration(
                hintTextDirection: TextDirection.rtl,
                contentPadding: EdgeInsets.all(12),
                border: OutlineInputBorder(
                  gapPadding: 0,
                  borderSide: BorderSide(width: 0.5),
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
