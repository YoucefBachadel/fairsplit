import 'dart:convert';
import 'dart:io';

import 'package:fairsplit/shared/functions.dart';
import 'package:fairsplit/shared/widgets.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:universal_html/html.dart' show AnchorElement;
import 'package:flutter/foundation.dart' show kIsWeb;

import '../main.dart';
import '../models/transaction.dart';
import '../models/unit.dart';
import '../models/user.dart';
import '../shared/constants.dart';
import '../shared/lists.dart';

class Passage extends StatefulWidget {
  const Passage({super.key});

  @override
  State<Passage> createState() => _PassageState();
}

class _PassageState extends State<Passage> {
  List<User> users = [], zakatUsers = [];
  List<Unit> units = [];
  List<Transaction> transactionsTemp = [];
  pw.Document pdf = pw.Document();
  TextEditingController zakatController = TextEditingController(), materialsController = TextEditingController();
  double zakatQuorum = 0, materialsValue = 0;
  String _zakatQuorum = '', _materialsValue = '';
  double caisse = 0, reserve = 0, reserveYear = 0, donation = 0, donationProfit = 0, zakat = 0;
  double totalCapital = 0, totalZakat = 0, totalIn = 0, totalOut = 0;
  double materialsValuePerc = 0;
  int reference = 0;
  int bottemNavigationSelectedInex = 0;
  bool isLoading = true, isCalculating = false, isCalculated = false, isSaving = false;

  void loadData() async {
    var data = await sqlQuery(selectUrl, {
      'sql1':
          '''SELECT u.*,
                    (SELECT COALESCE(SUM(amount),0)FROM transaction t WHERE t.userId =u.userId AND t.type = 'in') AS totalIn,
                    (SELECT COALESCE(SUM(amount),0)FROM transaction t WHERE t.userId =u.userId AND t.type = 'out') AS totalOut 
            FROM Users u;''',
      'sql2': 'SELECT * FROM Units;',
      'sql3': 'SELECT * FROM transactiontemp;',
      'sql4': 'SELECT caisse, reserve, donation, reserveYear, donationProfit, zakat, reference FROM settings;',
    });
    var dataUsers = data[0];
    var dataUnits = data[1];
    var dataTransactionTemp = data[2];
    var dataSettings = data[3][0];

    caisse = double.parse(dataSettings['caisse']);
    reserve = double.parse(dataSettings['reserve']);
    donation = double.parse(dataSettings['donation']);
    reserveYear = double.parse(dataSettings['reserveYear']);
    donationProfit = double.parse(dataSettings['donationProfit']);
    zakat = double.parse(dataSettings['zakat']);
    reference = int.parse(dataSettings['reference']);

    users = toUsers(dataUsers, [], [], []);
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
    materialsValuePerc = materialsValue * 100 / totalCapital;
    for (var user in users) {
      double _userCapitalForZakat = user.newCapital - (user.newCapital * materialsValuePerc / 100);
      if (_userCapitalForZakat >= zakatQuorum) {
        user.zakat = _userCapitalForZakat * 2.6 / 100;
        totalZakat += user.zakat;
        zakatUsers.add(user);
      }
    }

    await buildPdf();
    isCalculated = true;
    setState(() => isCalculating = false);
  }

  void passage() async {
    Map<String, String> params = {};

    // insert user history
    var userHistory =
        'INSERT INTO userhistory(name, year, startCapital, totalIn, totalOut, endCapital, weightedCapital, moneyProfit, thresholdProfit, foundingProfit, effortProfit, totalProfit, zakat) VALUES ';
    for (var user in users) {
      userHistory +=
          '''('${user.name}',$currentYear,${user.initialCapital},${user.totalIn},${user.totalOut},${user.capital},${user.weightedCapital},${user.money + user.moneyExtern},${user.threshold},${user.founding},${user.effort + user.effortExtern},${user.totalProfit},${user.zakat}),''';
    }
    userHistory = userHistory.substring(0, userHistory.length - 1) + ';';
    params['sql1'] = userHistory;

    // insert unit history
    var unitHistory = 'INSERT INTO unithistory(name, year, type, capital, profit, profitability) VALUES ';
    for (var unit in units) {
      unitHistory +=
          '''('${unit.name}',$currentYear,'${unit.type}',${unit.capital},${unit.profit},${unit.profitability}),''';
    }
    unitHistory = unitHistory.substring(0, unitHistory.length - 1) + ';';
    params['sql2'] = unitHistory;

    //move user profit to it's capital and insert it as transactions in 01-01
    var userTransaction =
        'INSERT INTO transaction(reference, userId, userName, date, type, amount, soldeUser, soldeCaisse, note, amountOnLetter, intermediates, printingNotes, reciver) VALUES ';
    DateTime date = DateTime(currentYear + 1, 1, 1, 0, 0, 0);
    for (var user in users) {
      double userTotalProfitWithoutExtern = user.money + user.threshold + user.founding + user.effort;
      if (user.newCapital.abs() < 0.001) user.newCapital = 0;
      user.capital = user.newCapital;

      if (userTotalProfitWithoutExtern != 0) {
        userTransaction +=
            '''('${currentYear % 100}/${reference.toString().padLeft(4, '0')}' , ${user.userId} , '${user.name}' , '$date' , '${userTotalProfitWithoutExtern > 0 ? 'in' : 'out'}' ,${userTotalProfitWithoutExtern.abs()} , ${user.newCapital} , $caisse , 'Passage_$currentYear' , '${numberToArabicWords(userTotalProfitWithoutExtern.abs())}' , '' , '' , '' ),''';
        date = date.add(const Duration(seconds: 1));
        reference++;
      }
    }
    userTransaction = userTransaction.substring(0, userTransaction.length - 1) + ';';
    params['sql3'] = userTransaction;

    //move reserveyear to reserve and dontionprofit to donation with transaction
    reserve += reserveYear;
    donation += donationProfit;
    params['sql4'] =
        '''INSERT INTO transactionsp (reference,category,date,type,amount,solde,soldeCaisse,note,amountOnLetter,intermediates,printingNotes,reciver) VALUES ('${currentYear % 100}/${reference.toString().padLeft(4, '0')}' ,'reserve' , '$date' , '${reserveYear >= 0 ? 'in' : 'out'}' ,${reserveYear.abs()} ,$reserve ,$caisse , 'Passage_$currentYear','${numberToArabicWords(reserveYear.abs())}','','','');''';
    date = date.add(const Duration(seconds: 1));
    reference++;
    params['sql5'] =
        '''INSERT INTO transactionsp (reference,category,date,type,amount,solde,soldeCaisse,note,amountOnLetter,intermediates,printingNotes,reciver) VALUES ('${currentYear % 100}/${reference.toString().padLeft(4, '0')}' ,'donation' , '$date' , '${donationProfit >= 0 ? 'in' : 'out'}' ,${donationProfit.abs()} ,$donation ,$caisse , 'Passage_$currentYear','${numberToArabicWords(donationProfit.abs())}','','','');''';

    //move transaction temp to oraginal table
    var userTempTransaction =
        'INSERT INTO transaction (reference, userId, userName, date, type, amount, soldeUser, soldeCaisse, note, amountOnLetter, intermediates, printingNotes, reciver) VALUES ';
    var reserveTempTransaction =
        'INSERT INTO transactionsp (reference,category,date,type,amount,solde,soldeCaisse,note,amountOnLetter,intermediates,printingNotes,reciver) VALUES ';

    for (var trans in transactionsTemp) {
      if (trans.userId == -1) {
        trans.type == 'in' ? reserve += trans.amount : reserve -= trans.amount;
        reserveTempTransaction +=
            '''('${trans.reference}' ,'reserve' ,'${trans.date}' ,'${trans.type}' ,${trans.amount} ,$reserve ,${trans.soldeCaisse} ,'${trans.note}' ,'${trans.amountOnLetter}','${trans.intermediates}','${trans.printingNotes}','${trans.reciver}'),''';
      } else {
        int userIndex = users.indexOf(users.firstWhere((user) => user.userId == trans.userId));
        trans.type == 'in' ? users[userIndex].capital += trans.amount : users[userIndex].capital -= trans.amount;
        userTempTransaction +=
            '''('${trans.reference}' , ${trans.userId} , '${trans.userName}' , '${trans.date}' , '${trans.type}' ,${trans.amount} , ${users[userIndex].capital} , ${trans.soldeCaisse} , '${trans.note}' , '${trans.amountOnLetter}' , '${trans.intermediates}' , '${trans.printingNotes}' , '${trans.reciver}' ),''';
      }
    }

    int counter = 11;
    if (userTempTransaction[userTempTransaction.length - 1] == ',') {
      userTempTransaction = userTempTransaction.substring(0, userTempTransaction.length - 1) + ';';
      params['sql$counter'] = userTempTransaction;
      counter++;
    }
    if (reserveTempTransaction[reserveTempTransaction.length - 1] == ',') {
      reserveTempTransaction = reserveTempTransaction.substring(0, reserveTempTransaction.length - 1) + ';';
      params['sql$counter'] = reserveTempTransaction;
      counter++;
    }

    //clear transaction temp table
    params['sql6'] = 'DELETE FROM transactiontemp;';

    //insert zakat transactions
    currentYear++;
    reference = 1;

    double selectedZakatUsersTotal = 0;
    var zakatTransactions =
        'INSERT INTO transaction (reference, userId, userName, date, type, amount, soldeUser, soldeCaisse, note, amountOnLetter, intermediates, printingNotes, reciver) VALUES ';
    for (var user in zakatUsers) {
      if (user.zakatOut || user.zakatOutToZakatCaisse) {
        user.capital -= user.zakat;
        if (user.zakatOut) caisse -= user.zakat;
        if (user.zakatOutToZakatCaisse) selectedZakatUsersTotal += user.zakat;

        zakatTransactions +=
            '''('${currentYear % 100}/${reference.toString().padLeft(4, '0')}' , ${user.userId} , '${user.name}' , '${DateTime.now()}' , 'out' ,${user.zakat} , ${user.capital} , $caisse , 'زكاة ${currentYear - 1}' , '${numberToArabicWords(user.zakat)}' , '' , '' , '' ),''';
        reference++;
      }
    }
    if (zakatTransactions[zakatTransactions.length - 1] == ',') {
      zakatTransactions = zakatTransactions.substring(0, zakatTransactions.length - 1) + ';';
      params['sql$counter'] = zakatTransactions;
      counter++;
    }

    //insert users zakat total to zakat caisse
    if (selectedZakatUsersTotal != 0) {
      zakat += selectedZakatUsersTotal;
      params['sql$counter'] =
          '''INSERT INTO transactionsp (reference,category,date,type,amount,solde,soldeCaisse,note,amountOnLetter,intermediates,printingNotes,reciver) VALUES ('${currentYear % 100}/${reference.toString().padLeft(4, '0')}' ,'zakat' , '${DateTime.now()}' , 'in' ,$selectedZakatUsersTotal ,$zakat ,$caisse , 'Passage_${currentYear - 1}','${numberToArabicWords(selectedZakatUsersTotal)}','','','');''';
      counter++;
      reference++;
    }

    //update setting
    params['sql7'] =
        'UPDATE settings SET caisse=$caisse ,reserve=$reserve ,reserveYear=0 ,donation=$donation ,zakat=$zakat ,profitability=0 ,donationProfit=0 ,currentYear=$currentYear ,reference=$reference';

    //update unit informations
    params['sql8'] = 'UPDATE units SET profit=0,profitability=0;';
    params['sql9'] = '''UPDATE units SET currentMonthOrYear=1 WHERE type='intern';''';

    //update users information
    var userInfo =
        'INSERT INTO users(userId, capital, initialCapital, money, moneyExtern, threshold, founding, effort, effortExtern) VALUES ';
    for (var user in users) {
      userInfo += '''(${user.userId}, ${user.capital}, ${user.newCapital}, 0,0,0,0,0,0),''';
    }
    userInfo = userInfo.substring(0, userInfo.length - 1);
    userInfo +=
        ' ON DUPLICATE KEY UPDATE capital = VALUES(capital),initialCapital = VALUES(initialCapital),money = 0,moneyExtern = 0,threshold = 0,founding = 0,effort = 0,effortExtern = 0;';
    params['sql10'] = userInfo;

    await sqlQuery(insertUrl, params);
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MyApp(index: 'da')));
    snackBar(context, getMessage('passageDone'));
    setState(() => isSaving = false);
  }

  Future buildPdf() async {
    for (var user in users) {
      pdf.addPage(page(user));
    }
  }

  pw.MultiPage page(User user) => pdfPage(pdfPageFormat: PdfPageFormat.a4, build: [pw.Text(user.name)]);

  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: getHeight(context, .8),
      width: getWidth(context, .8),
      child: Column(children: [
        Container(
          alignment: Alignment.center,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  getText('passage'),
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
          child: isLoading
              ? myProgress()
              : Row(children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      children: [
                        mySizedBox(context),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Spacer(),
                            Column(
                              children: [
                                Text(getText('zakat')),
                                myTextField(
                                  context,
                                  controller: zakatController,
                                  hint: myCurrency(zakatQuorum),
                                  width: getWidth(context, .10),
                                  isNumberOnly: true,
                                  onChanged: ((text) => setState(() => _zakatQuorum = text)),
                                  enabled: !isCalculated,
                                ),
                              ],
                            ),
                            mySizedBox(context),
                            Column(
                              children: [
                                Text(getText('materials')),
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
                            const Spacer(),
                            myButton(
                              context,
                              text: isCalculated ? getText('passage') : 'Calculate',
                              noIcon: true,
                              width: getWidth(context, .08),
                              enabled: isCalculated
                                  ? true
                                  : zakatController.text.isNotEmpty && materialsController.text.isNotEmpty,
                              isLoading: isCalculated ? isSaving : isCalculating,
                              onTap: () {
                                if (isCalculated) {
                                  setState(() => isSaving = true);
                                  passage();
                                } else {
                                  setState(() => isCalculating = true);
                                  zakatQuorum = double.parse(_zakatQuorum);
                                  materialsValue = double.parse(_materialsValue);
                                  calculate();
                                }
                              },
                            ),
                            const Spacer(),
                          ],
                        ),
                        const Divider(),
                        if (bottemNavigationSelectedInex == 0) Expanded(child: informations()),
                        if (bottemNavigationSelectedInex == 1) Expanded(child: zakatUsersSelector()),
                        const Divider(),
                        BottomNavigationBar(
                          type: BottomNavigationBarType.fixed,
                          items: <BottomNavigationBarItem>[
                            BottomNavigationBarItem(icon: const Icon(Icons.add), label: getText('info')),
                            BottomNavigationBarItem(icon: const Icon(Icons.add), label: getText('zakat')),
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
                      ],
                    ),
                  ),
                  printPreview(),
                  SizedBox(width: getWidth(context, .01))
                ]),
        ),
      ]),
    );
  }

  Widget informations() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        infoItem(getText('year'), currentYear.toString()),
        infoItem(getText('profitability'), profitability == 0 ? zero : myPercentage(profitability * 100)),
        infoItem(getText('totalCapital'), myCurrency(totalCapital)),
        infoItem(getText('totalIn'), myCurrency(totalIn)),
        infoItem(getText('totalOut'), myCurrency(totalOut)),
        infoItem('${getText('materials')} %', myPercentage(materialsValuePerc)),
        infoItem(getText('totalZakat'), myCurrency(totalZakat)),
      ],
    );
  }

  Widget printPreview() {
    return Expanded(
      flex: 4,
      child: pdf.document.pdfPageList.pages.isEmpty
          ? Container(color: Colors.grey, child: emptyList(textColor: Colors.white))
          : Stack(
              children: [
                pdfPreview(pdf.save()),
                Positioned(
                  bottom: 16,
                  right: 20,
                  child: FloatingActionButton(
                    mini: true,
                    onPressed: () => printPdf(context, pdf.save()),
                    child: const Icon(Icons.print),
                  ),
                ),
                Positioned(
                  bottom: 16,
                  left: 20,
                  child: FloatingActionButton(
                    mini: true,
                    onPressed: () async {
                      if (kIsWeb) {
                        AnchorElement(
                            href:
                                "data:application/octet-stream;charset=utf-16le;base64,${base64.encode(List.from(await pdf.save()))}")
                          ..setAttribute("download", "Passage_$currentYear.pdf")
                          ..click();
                      } else {
                        final String? initialDirectory = (await getDownloadsDirectory())?.path;
                        String? fileName = await FilePicker.platform.saveFile(
                          dialogTitle: 'Please select an output file:',
                          initialDirectory: initialDirectory,
                          fileName: 'Passage_$currentYear',
                          allowedExtensions: ['pdf'],
                        );

                        if (fileName != null) {
                          final File file = File('$fileName.pdf');
                          await file.writeAsBytes(await pdf.save());
                        }
                      }
                    },
                    child: const Icon(Icons.download),
                  ),
                ),
              ],
            ),
    );
  }

  Widget infoItem(String title, String value) {
    return SizedBox(
      width: getWidth(context, .25),
      child: value.isEmpty
          ? const SizedBox()
          : Row(children: [
              Expanded(flex: 2, child: myText(title)),
              Expanded(flex: 3, child: myText(':      $value')),
            ]),
    );
  }

  Widget zakatUsersSelector() {
    return Column(
      children: [
        if (zakatUsers.isNotEmpty)
          Row(
            children: [
              SizedBox(
                  width: getWidth(context, .195),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: myText(
                        'Selected : ${zakatUsers.where((user) => user.zakatOut || user.zakatOutToZakatCaisse).length}'),
                  )),
              SizedBox(
                width: getWidth(context, .068),
                child: CheckboxListTile(
                  value: zakatUsers.length == zakatUsers.where((user) => user.zakatOut).length,
                  title: myText('All'),
                  onChanged: (value) => setState(() {
                    if (value == true) {
                      for (var user in zakatUsers) {
                        user.zakatOut = true;
                        user.zakatOutToZakatCaisse = false;
                      }
                    } else if (value == false) {
                      for (var user in zakatUsers) {
                        user.zakatOut = false;
                      }
                    }
                  }),
                ),
              ),
              SizedBox(
                width: getWidth(context, .068),
                child: CheckboxListTile(
                  value: zakatUsers.length == zakatUsers.where((user) => user.zakatOutToZakatCaisse).length,
                  title: myText('All'),
                  onChanged: (value) => setState(() {
                    if (value == true) {
                      for (var user in zakatUsers) {
                        user.zakatOutToZakatCaisse = true;
                        user.zakatOut = false;
                      }
                    } else if (value == false) {
                      for (var user in zakatUsers) {
                        user.zakatOutToZakatCaisse = false;
                      }
                    }
                  }),
                ),
              ),
            ],
          ),
        Expanded(
          child: zakatUsers.isEmpty
              ? emptyList()
              : SingleChildScrollView(
                  child: dataTable(
                    context,
                    columns: [
                      dataColumn(context, getText('name')),
                      dataColumn(context, 'Out'),
                      dataColumn(context, 'Out To Zakat'),
                    ],
                    rows: zakatUsers
                        .map((e) => DataRow(cells: [
                              DataCell(Container(
                                alignment: Alignment.centerLeft,
                                width: getWidth(context, .18),
                                child: Text(
                                  e.realName,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontFamily: 'IBM'),
                                ),
                              )),
                              DataCell(Container(
                                width: getWidth(context, .06),
                                alignment: Alignment.center,
                                child: Center(
                                  child: Checkbox(
                                    value: e.zakatOut,
                                    onChanged: (bool? value) => setState(() {
                                      if (value == true) {
                                        e.zakatOut = true;
                                        e.zakatOutToZakatCaisse = false;
                                      } else if (value == false) {
                                        e.zakatOut = false;
                                      }
                                    }),
                                  ),
                                ),
                              )),
                              DataCell(Container(
                                width: getWidth(context, .06),
                                alignment: Alignment.center,
                                child: Checkbox(
                                  value: e.zakatOutToZakatCaisse,
                                  onChanged: (bool? value) => setState(() {
                                    if (value == true) {
                                      e.zakatOutToZakatCaisse = true;
                                      e.zakatOut = false;
                                    } else if (value == false) {
                                      e.zakatOutToZakatCaisse = false;
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
}
