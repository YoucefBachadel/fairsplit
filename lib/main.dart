import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:fairsplit/providers/filter.dart';
import 'package:fairsplit/screens/profit_history.dart';
import 'package:fairsplit/shared/functions.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:pdf/widgets.dart' as pw;

import 'screens/other_users.dart';
import 'screens/units.dart';
import 'shared/lists.dart';
import 'screens/transactions.dart';
import 'screens/user_history.dart';
import 'screens/users.dart';
import 'screens/dashboard.dart';
import 'screens/unit_history.dart';
import 'shared/constants.dart';
import 'shared/widgets.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => Filter()),
      ],
      child: MaterialApp(
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('fr')],
        debugShowCheckedModeBanner: false,
        title: 'FairSplit',
        theme: ThemeData(
            primarySwatch: MaterialColor(
              0XFF02333c,
              {
                50: primaryColor,
                100: primaryColor,
                200: primaryColor,
                300: primaryColor,
                400: primaryColor,
                500: primaryColor,
                600: primaryColor,
                700: primaryColor,
                800: primaryColor,
                900: primaryColor,
              },
            ),
            fontFamily: 'Itim'),
        home: const MyApp(index: 'first'),
      ),
    ),
  );

  doWhenWindowReady(() {
    const initialSize = Size(1800, 950);
    appWindow.minSize = initialSize;
    appWindow.title = "FairSplit";
    appWindow.maximize();
    appWindow.show();
  });
}

class WindowButtons extends StatelessWidget {
  const WindowButtons({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final buttonColors = WindowButtonColors(
      iconNormal: Colors.white,
      mouseOver: const Color(0xFFF6A00C),
      mouseDown: const Color(0xFF805306),
      iconMouseOver: const Color(0xFF805306),
      iconMouseDown: const Color(0xFFFFD500),
    );

    final closeButtonColors = WindowButtonColors(
      mouseOver: const Color(0xFFD32F2F),
      mouseDown: const Color(0xFFB71C1C),
      iconNormal: Colors.white,
      iconMouseOver: Colors.white,
    );
    return Row(
      children: [
        MinimizeWindowButton(colors: buttonColors),
        MaximizeWindowButton(colors: buttonColors),
        CloseWindowButton(colors: closeButtonColors),
      ],
    );
  }
}

class MyApp extends StatefulWidget {
  final String index;
  const MyApp({Key? key, required this.index}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late int selectedTab;
  bool isLoading = false;

  Map<String, int> tabsIndex = {
    'da': 0,
    'un': 1,
    'us': 2,
    'ou': 3,
    'tr': 4,
    'prh': 5,
    'ush': 6,
    'unh': 7,
  };

  List<String> tabs = [
    getText('dashboard'),
    getText('units'),
    getText('users'),
    getText('otherUsers'),
    getText('transaction'),
    getText('profitHistory'),
    getText('userHistory'),
    getText('unitHistory'),
  ];

  List<Widget> tabScreens = [
    const Dashboard(),
    const Units(),
    const Users(),
    const OtherUsers(),
    const Transactions(),
    const ProfitHistory(),
    const UserHistoryScreen(),
    const UnitHistoryScreen(),
  ];

  void updateamountOnLetter() async {
    var params = {
      'sql1': 'SELECT transactionId,amount FROM transaction;',
      'sql2': 'SELECT transactionId,amount FROM transactionsp;',
      'sql3': 'SELECT transactionId,amount FROM transactionothers;',
      'sql4': 'SELECT transactionId,amount FROM transactiontemp;',
    };

    var res = await sqlQuery(selectUrl, params);
    var dataTransaction = res[0];
    var dataTransactionSP = res[1];
    var dataTransactionOther = res[2];
    var dataTransactionTemp = res[3];

    String transactionsSQL = 'INSERT INTO transaction (transactionId,amountOnLetter) VALUES ';
    String transactionsSPSQL = 'INSERT INTO transactionsp (transactionId,amountOnLetter) VALUES ';
    String transactionsOthersSQL = 'INSERT INTO transactionothers (transactionId,amountOnLetter) VALUES ';
    String transactionsTempSQL = 'INSERT INTO transactiontemp (transactionId,amountOnLetter) VALUES ';

    for (var ele in dataTransaction) {
      transactionsSQL +=
          '''(${int.parse(ele['transactionId'])},'${numberToArabicWords(double.parse(ele['amount']))}'),''';
    }
    transactionsSQL = transactionsSQL.substring(0, transactionsSQL.length - 1);
    transactionsSQL += ' ON DUPLICATE KEY UPDATE amountOnLetter = VALUES(amountOnLetter);';

    for (var ele in dataTransactionOther) {
      transactionsOthersSQL +=
          '''(${int.parse(ele['transactionId'])},'${numberToArabicWords(double.parse(ele['amount']))}'),''';
    }
    transactionsOthersSQL = transactionsOthersSQL.substring(0, transactionsOthersSQL.length - 1);
    transactionsOthersSQL += ' ON DUPLICATE KEY UPDATE amountOnLetter = VALUES(amountOnLetter);';

    for (var ele in dataTransactionSP) {
      transactionsSPSQL +=
          '''(${int.parse(ele['transactionId'])},'${numberToArabicWords(double.parse(ele['amount']))}'),''';
    }
    transactionsSPSQL = transactionsSPSQL.substring(0, transactionsSPSQL.length - 1);
    transactionsSPSQL += ' ON DUPLICATE KEY UPDATE amountOnLetter = VALUES(amountOnLetter);';

    for (var ele in dataTransactionTemp) {
      transactionsTempSQL +=
          '''(${int.parse(ele['transactionId'])},'${numberToArabicWords(double.parse(ele['amount']))}'),''';
    }
    transactionsTempSQL = transactionsTempSQL.substring(0, transactionsTempSQL.length - 1);
    transactionsTempSQL += ' ON DUPLICATE KEY UPDATE amountOnLetter = VALUES(amountOnLetter);';

    await sqlQuery(insertUrl, {
      'sql1': transactionsSQL,
      'sql2': transactionsOthersSQL,
      'sql3': transactionsSPSQL,
      'sql4': transactionsTempSQL,
    });
    // print('done');
  }

  void loadData() async {
    var res = await sqlQuery(selectUrl, {
      'sql1': '''SELECT DISTINCT(Year(date)) AS year  FROM transaction 
          UNION SELECT DISTINCT(Year(date)) AS year FROM transactionothers 
          UNION SELECT DISTINCT(Year(date)) AS year FROM transactionsp 
          UNION SELECT DISTINCT(Year(date)) AS year FROM transactiontemp
          UNION SELECT year FROM profithistory
          UNION SELECT year FROM userhistory
          UNION SELECT year FROM unithistory;''',
      'sql2': '''SELECT DISTINCT(userName) AS name FROM transaction
          UNION SELECT DISTINCT(userName) AS name FROM transactionothers
          UNION SELECT DISTINCT(userName) AS name FROM transactiontemp WHERE userName <> 'reserve' AND userName <> 'reserveProfit'
          UNION SELECT name FROM users 
          UNION SELECT name FROM otherusers
          UNION SELECT name FROM userhistory;'''
    });

    for (var ele in res[0]) {
      years.add(ele['year'].toString());
    }
    years = SplayTreeSet.from(years, (a, b) => b.compareTo(a));

    userNames.clear();
    for (var ele in res[1]) {
      userNames.add(realUserNames[ele['name']] ?? ele['name']);
    }

    userNames = SplayTreeSet.from(userNames, (a, b) => a.compareTo(b));
  }

  @override
  void initState() {
    super.initState();
    selectedTab = tabsIndex[widget.index] ?? 0;
    initFont();
    loadData();

    // updateamountOnLetter();
  }

  initFont() async {
    pdfFont = pw.Font.ttf(await rootBundle.load("fonts/pdf.ttf"));
    pdfFontBold = pw.Font.ttf(await rootBundle.load("fonts/pdf-Bold.ttf"));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.index == 'first' ? scaffoldColor : primaryColor,
      body: Column(
        children: [
          WindowTitleBarBox(
            child: Container(
              color: primaryColor,
              child: MoveWindow(
                child: Stack(
                  children: [
                    Positioned.fill(child: Center(child: myText("FairSplit", color: Colors.white, size: 22))),
                    const Positioned(right: 0, child: WindowButtons()),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: widget.index == 'first'
                ? Center(child: passwordDialog())
                : Row(
                    children: [
                      Container(
                        width: getWidth(context, .1),
                        color: primaryColor,
                        padding: const EdgeInsets.only(left: 5),
                        child: Column(children: [
                          const Spacer(),
                          Divider(color: scaffoldColor, thickness: .1),
                          ...tabs
                              .map(
                                (e) => InkWell(
                                  onTap: () {
                                    context.read<Filter>().reset();
                                    setState(() => selectedTab = tabs.indexOf(e));
                                  },
                                  child: tabItem(e, tabs.indexOf(e) == selectedTab),
                                ),
                              )
                              .toList(),
                          const Spacer(flex: 10),
                          InkWell(
                            onTap: () async {
                              FilePickerResult? result = await FilePicker.platform.pickFiles(
                                type: FileType.custom,
                                allowedExtensions: ['txt'],
                              );
                              if (result != null) {
                                File file = File(result.files.single.path!);
                                String data = await file.readAsString();
                                for (var line in const LineSplitter().convert(data)) {
                                  if (line.isNotEmpty) realUserNames[line.split(';')[0]] = line.split(';')[1];
                                }
                                Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => MyApp(index: tabsIndex.keys.elementAt(selectedTab)),
                                    ));
                              }
                            },
                            child: Text(
                              myDateFormate2.format(DateTime.now()),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          mySizedBox(context),
                        ]),
                      ),
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.only(top: 8.0, bottom: 8.0, right: 8.0),
                          decoration: BoxDecoration(
                            color: scaffoldColor,
                            borderRadius: const BorderRadius.all(Radius.circular(12)),
                          ),
                          child: tabScreens[selectedTab],
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget tabItem(String text, bool selected) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.only(top: 8.0, bottom: 8.0, left: 20.0),
          decoration: BoxDecoration(
            color: selected ? scaffoldColor : Colors.transparent,
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(15)),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 18,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              color: selected ? primaryColor : Colors.white,
            ),
          ),
        ),
        Divider(color: scaffoldColor, thickness: .1),
      ],
    );
  }

  Widget passwordDialog() {
    String _password = '';

    void onTap() async {
      setState(() => isLoading = true);

      if (_password.contains('"') || _password.contains('\'')) {
        snackBar(context, getMessage('wrongPassword'), duration: 1);
      } else {
        var res = await sqlQuery(selectUrl, {
          'sql1': '''SELECT IF(user = '$_password',1,IF(admin = '$_password',2,0)) AS password FROM settings;''',
        });

        if (['1', '2'].contains(res[0][0]['password'])) {
          if (res[0][0]['password'] == '2') isAdmin = true;

          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MyApp(index: 'da')));
        } else {
          snackBar(context, getMessage('wrongPassword'), duration: 1);
        }
      }
      setState(() => isLoading = false);
    }

    return Container(
      height: getHeight(context, .20),
      width: getWidth(context, .20),
      decoration: BoxDecoration(
        color: scaffoldColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryColor),
      ),
      child: Column(
        children: [
          Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20.0),
                  topRight: Radius.circular(20.0),
                )),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    getText('password'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 20.0),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                myTextField(
                  context,
                  width: getWidth(context, .18),
                  onChanged: (text) => _password = text,
                  onSubmited: (value) => onTap(),
                  autoFocus: true,
                  isPassword: true,
                  isCenter: true,
                ),
                myButton(
                  context,
                  noIcon: true,
                  text: getText('confirm'),
                  isLoading: isLoading,
                  onTap: onTap,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
