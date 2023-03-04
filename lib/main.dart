import 'package:flutter/material.dart';

import '../screens/other_users.dart';
import '../screens/units.dart';
import '../shared/lists.dart';
import '../screens/transactions.dart';
import '../screens/user_history.dart';
import '../screens/users.dart';
import '../screens/consultaion.dart';
import '../screens/dashboard.dart';
import '../screens/unit_history.dart';
import 'shared/parameters.dart';

//used to conver color to material color in material theme
final Map<int, Color> color = {
  50: winTileColor,
  100: winTileColor,
  200: winTileColor,
  300: winTileColor,
  400: winTileColor,
  500: winTileColor,
  600: winTileColor,
  700: winTileColor,
  800: winTileColor,
  900: winTileColor,
};
// textTheme: GoogleFonts.gothicA1TextTheme(),
// textTheme: GoogleFonts.gothicA1TextTheme(),
// textTheme: GoogleFonts.itimTextTheme(),
// textTheme: GoogleFonts.comicNeueTextTheme(),

void main() => runApp(MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FairSplit',
      theme: ThemeData(
          primarySwatch: MaterialColor(0XFF303F9F, color), fontFamily: 'Itim'),
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
      backgroundColor: winTileColor,
      body: Row(
        children: [
          Container(
            width: MediaQuery.of(context).size.width * 0.1,
            color: winTileColor,
            padding: const EdgeInsets.only(left: 5),
            child: Column(children: [
              const Spacer(),
              ...tabs
                  .map(
                    (e) => InkWell(
                      onTap: (() {
                        setState(() {
                          selectedTab = tabs.indexOf(e);
                        });
                      }),
                      child: tabItem(e, tabs.indexOf(e) == selectedTab),
                    ),
                  )
                  .toList(),
              const Spacer(flex: 10),
              Text(
                myDateFormate2.format(DateTime.now()),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
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
          color: selected ? winTileColor : Colors.white,
        ),
      ),
    );
  }
}
