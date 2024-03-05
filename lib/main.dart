import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:pdf/widgets.dart' as pw;

import 'providers/filter.dart';
import 'screens/passage.dart';
import 'screens/unit_history.dart';
import 'screens/other_users.dart';
import 'screens/units.dart';
import 'screens/transactions.dart';
import 'screens/users_history.dart';
import 'screens/users.dart';
import 'screens/dashboard.dart';
import 'shared/functions.dart';
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
  bool isPassageAllowed = false;

  Map<String, int> tabsIndex = {'da': 0, 'un': 1, 'us': 2, 'ou': 3, 'tr': 4, 'ush': 6, 'unh': 7};

  List<String> tabs = ['Dashboard', 'Units', 'Users', 'Other Users', 'Transaction', 'User History', 'Unit History'];

  List<Widget> tabScreens = const [Dashboard(), Units(), Users(), OtherUsers(), Transactions(), UsersHistory(), UnitsHistory()];

  void loadData() async {
    var res = await sqlQuery(selectUrl, {
      'sql1': '''SELECT DISTINCT(Year(date)) AS year  FROM transaction 
          UNION SELECT DISTINCT(Year(date)) AS year FROM transactionothers 
          UNION SELECT DISTINCT(Year(date)) AS year FROM transactionsp 
          UNION SELECT DISTINCT(Year(date)) AS year FROM transactiontemp
          UNION SELECT year FROM userhistory
          UNION SELECT year FROM unithistory;''',
      'sql2': '''SELECT DISTINCT(userName) AS name FROM transaction
          UNION SELECT DISTINCT(userName) AS name FROM transactionothers
          UNION SELECT DISTINCT(userName) AS name FROM transactiontemp WHERE userName <> 'reserve' AND userName <> 'reserveProfit'
          UNION SELECT name FROM users 
          UNION SELECT name FROM otherusers
          UNION SELECT name FROM userhistory;''',
      'sql3': '''SELECT COUNT(unitId) AS count FROM units WHERE type = 'intern' AND currentMonthOrYear != 13''',
    });

    for (var ele in res[0]) {
      years.add(ele['year'].toString());
    }
    years = SplayTreeSet.from(years, (a, b) => b.compareTo(a));

    userNames.clear();
    for (var ele in res[1]) {
      userNames.add(realUserNames[ele['name']] ?? ele['name']);
    }

    if (res[2][0]['count'] == '0') setState(() => isPassageAllowed = true);

    userNames = SplayTreeSet.from(userNames, (a, b) => a.compareTo(b));
  }

  initFont() async {
    pdfFont = pw.Font.ttf(await rootBundle.load("fonts/pdf.ttf"));
    pdfFontBold = pw.Font.ttf(await rootBundle.load("fonts/pdf-Bold.ttf"));
  }

  @override
  void initState() {
    if (widget.index != 'first') {
      selectedTab = tabsIndex[widget.index] ?? 0;
      initFont();
      loadData();
    }
    super.initState();
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
                          if (isAdmin && isPassageAllowed)
                            InkWell(
                              onTap: () => createDialog(context, const Passage(), dismissable: false),
                              child: Container(
                                  height: getHeight(context, textFeildHeight),
                                  margin: const EdgeInsets.only(right: 5),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(color: primaryColor),
                                    borderRadius: const BorderRadius.all(Radius.circular(12)),
                                  ),
                                  child: myText('Passage', color: primaryColor)),
                            ),
                          mySizedBox(context),
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
        snackBar(context, 'Wrong Password!!', duration: 1);
      } else {
        var res = await sqlQuery(selectUrl, {
          'sql1': '''SELECT IF(user = '$_password',1,IF(admin = '$_password',2,0)) AS password FROM settings;''',
        });

        if (['1', '2'].contains(res[0][0]['password'])) {
          if (res[0][0]['password'] == '2') isAdmin = true;

          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MyApp(index: 'da')));
        } else {
          snackBar(context, 'Wrong Password!!', duration: 1);
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
            child: const Text(
              'Password',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 20.0),
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
                  text: 'Confirm',
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
