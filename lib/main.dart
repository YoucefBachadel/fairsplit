import 'package:flutter/material.dart';

import 'screens/other_users.dart';
import 'screens/units.dart';
import 'shared/lists.dart';
import 'screens/transactions.dart';
import 'screens/user_history.dart';
import 'screens/users.dart';
import 'screens/consultaion.dart';
import 'screens/dashboard.dart';
import 'screens/unit_history.dart';
import 'shared/parameters.dart';
import 'widgets/widget.dart';

//used to conver color to material color in material theme
final Map<int, Color> color = {
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
};
// textTheme: GoogleFonts.gothicA1TextTheme(),
// textTheme: GoogleFonts.gothicA1TextTheme(),
// textTheme: GoogleFonts.itimTextTheme(),
// textTheme: GoogleFonts.comicNeueTextTheme(),

void main() => runApp(MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FairSplit',
      theme: ThemeData(primarySwatch: MaterialColor(0XFF02333c, color), fontFamily: 'Itim'),
      home: const MyApp(index: 'da'),
    ));

class MyApp extends StatefulWidget {
  final String index;
  const MyApp({Key? key, required this.index}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late int selectedTab;
  Map<String, int> tabsIndex = {
    'da': 0,
    'un': 1,
    'us': 2,
    'ou': 3,
    'tr': 4,
    'ush': 5,
    'unh': 6,
    'co': 7,
  };
  List<String> tabs = [
    getText('dashboard'),
    getText('units'),
    getText('users'),
    getText('otherUsers'),
    getText('transaction'),
    getText('userHistory'),
    getText('unitHistory'),
    getText('consultation'),
  ];

  List<Widget> tabScreens = [
    const Dashboard(),
    const Units(),
    const Users(),
    const OtherUsers(),
    const Transactions(),
    const UserHistoryScreen(),
    const UnitHistoryScreen(),
    const Consultaion(),
  ];

  @override
  void initState() {
    selectedTab = tabsIndex[widget.index] ?? 0;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      body: Row(
        children: [
          Container(
            width: MediaQuery.of(context).size.width * 0.1,
            color: primaryColor,
            padding: const EdgeInsets.only(left: 5),
            child: Column(children: [
              const Spacer(),
              ...tabs
                  .map(
                    (e) => InkWell(
                      onTap: (() => setState(() => selectedTab = tabs.indexOf(e))),
                      child: tabItem(e, tabs.indexOf(e) == selectedTab),
                    ),
                  )
                  .toList(),
              const Spacer(flex: 10),
              InkWell(
                onTap: () async {
                  if (!namesHidden) {
                    namesHidden = true;
                    Navigator.of(context).pushReplacement(MaterialPageRoute(
                        builder: (context) =>
                            MyApp(index: tabsIndex.keys.firstWhere((key) => tabsIndex[key] == selectedTab))));
                  } else {
                    await createDialog(context, passwordDialog(), true);
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
              const SizedBox(height: 16.0),
            ]),
          ),
          Expanded(
            flex: 6,
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
    );
  }

  Widget tabItem(String text, bool selected) {
    return Container(
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
    );
  }

  Widget passwordDialog() {
    String _password = '';
    return Container(
      height: getHeight(context, .20),
      width: getWidth(context, .20),
      decoration: BoxDecoration(color: scaffoldColor, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.all(8.0),
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
            decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20.0),
                  topRight: Radius.circular(20.0),
                )),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                myTextField(
                  context,
                  width: getWidth(context, .18),
                  onChanged: (text) => _password = text,
                  autoFocus: true,
                  isPassword: true,
                  isCenter: true,
                ),
                myButton(
                  context,
                  noIcon: true,
                  text: getText('confirm'),
                  onTap: () {
                    if (_password == password) {
                      namesHidden = false;
                    } else {
                      snackBar(context, 'Wrong Password!!', duration: 1);
                    }
                    Navigator.of(context).pushReplacement(MaterialPageRoute(
                        builder: (context) =>
                            MyApp(index: tabsIndex.keys.firstWhere((key) => tabsIndex[key] == selectedTab))));
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
