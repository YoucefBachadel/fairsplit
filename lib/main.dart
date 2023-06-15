import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:fairsplit/providers/filter.dart';
import 'package:fairsplit/screens/profit_history.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'screens/other_users.dart';
import 'screens/units.dart';
import 'shared/lists.dart';
import 'screens/transactions.dart';
import 'screens/user_history.dart';
import 'screens/users.dart';
import 'screens/dashboard.dart';
import 'screens/unit_history.dart';
import 'shared/parameters.dart';
import 'widgets/widget.dart';

// textTheme: GoogleFonts.gothicA1TextTheme(),
// textTheme: GoogleFonts.gothicA1TextTheme(),
// textTheme: GoogleFonts.itimTextTheme(),
// textTheme: GoogleFonts.comicNeueTextTheme(),

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => Filter()),
      ],
      child: MaterialApp(
        localizationsDelegates: const [GlobalMaterialLocalizations.delegate],
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
            fontFamily: 'Gothic'),
        home: const MyApp(index: 'first'),
      ),
    ),
  );

  // Add this code below

  doWhenWindowReady(() {
    const initialSize = Size(1800, 950);
    appWindow.minSize = initialSize;
    appWindow.size = initialSize;
    appWindow.alignment = Alignment.center;
    appWindow.title = "FairSplit";
    appWindow.maximize();
    appWindow.show();
  });
}

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

class WindowButtons extends StatelessWidget {
  const WindowButtons({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
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

  @override
  void initState() {
    super.initState();
    selectedTab = tabsIndex[widget.index] ?? 0;
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
              child: Row(
                children: [
                  Expanded(child: MoveWindow(child: Center(child: myText("FairSplit", color: Colors.white, size: 22)))),
                  const WindowButtons()
                ],
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
                              if (!namesHidden) {
                                namesHidden = true;
                                isAdmin = false;
                                Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => MyApp(
                                            index: tabsIndex.keys.firstWhere((key) => tabsIndex[key] == selectedTab))));
                              } else {
                                await createDialog(context, passwordDialog());
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

    void onTap() async {
      setState(() => isLoading = true);

      var res = await sqlQuery(selectUrl, {
        'sql1': '''SELECT IF(user = '$_password',1,IF(admin = '$_password',2,0)) AS password FROM settings;''',
      });

      if (['1', '2'].contains(res[0][0]['password'])) {
        if (res[0][0]['password'] == '2') isAdmin = true;
        namesHidden = false;

        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => MyApp(
                    index: widget.index == 'first'
                        ? 'da'
                        : tabsIndex.keys.firstWhere((key) => tabsIndex[key] == selectedTab))));
      } else {
        snackBar(context, getMessage('wrongPassword'), duration: 1);
      }
      setState(() => isLoading = false);
    }

    return RawKeyboardListener(
      focusNode: FocusNode(),
      onKey: (event) {
        if (event.isKeyPressed(LogicalKeyboardKey.enter)) onTap();
      },
      child: Container(
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
      ),
    );
  }
}
