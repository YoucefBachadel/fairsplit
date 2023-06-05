import 'package:fairsplit/providers/transactions_filter.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../shared/lists.dart';
import '../shared/parameters.dart';
import '../widgets/widget.dart';
import 'add_transaction.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({Key? key}) : super(key: key);

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  bool isLoadingData = true;
  double caisse = 0,
      reserve = 0,
      donation = 0,
      zakat = 0,
      totalIn = 0,
      totalOut = 0,
      totalLoan = 0,
      totalDeposit = 0,
      totalProfit = 0,
      reserveProfit = 0;

  void locadData() async {
    var res = await sqlQuery(selectUrl, {
      'sql1':
          '''SELECT (SELECT SUM(capital) FROM Users) as capitalUsers,(SELECT SUM(capital) FROM Units) as capitalUnits,
          (SELECT SUM(profit) FROM ProfitHistory WHERE year =s.currentYear) as totalProfit,
          (SELECT SUM(amount) FROM Transaction WHERE type = 'in' AND year = s.currentYear) as totalIn,
          (SELECT SUM(amount) FROM Transaction WHERE type = 'out' AND year = s.currentYear) as totalOut,
          (SELECT SUM(rest) FROM OtherUsers WHERE type = 'loan') as totalLoan,
          (SELECT SUM(rest) FROM OtherUsers WHERE type = 'deposit') as totalDeposit,
          s.caisse, s.reserve, s.donation, s.zakat,s.reserveProfit, s.currentYear FROM Settings s;'''
    });
    var data = res[0][0];
    currentYear = int.parse(data['currentYear']);
    caisse = double.parse(data['caisse'] ?? '0');
    reserve = double.parse(data['reserve'] ?? '0');
    donation = double.parse(data['donation'] ?? '0');
    zakat = double.parse(data['zakat'] ?? '0');
    totalIn = double.parse(data['totalIn'] ?? '0');
    totalOut = double.parse(data['totalOut'] ?? '0');
    totalLoan = double.parse(data['totalLoan'] ?? '0');
    totalDeposit = double.parse(data['totalDeposit'] ?? '0');
    totalProfit = double.parse(data['totalProfit'] ?? '0');
    reserveProfit = double.parse(data['reserveProfit'] ?? '0');

    setState(() => isLoadingData = false);
  }

  @override
  void initState() {
    locadData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: isLoadingData
          ? myProgress()
          : Column(
              children: [
                Row(
                  children: [
                    [getText('caisse'), caisse, 'caisse'],
                    [getText('reserve'), reserve, 'reserve'],
                    [getText('donation'), donation, 'donation'],
                    [getText('zakat'), zakat, 'zakat'],
                  ].map((e) => boxCard(e[0] as String, e[1] as double, true, compt: e[2] as String)).toList(),
                ),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Container(
                          margin: const EdgeInsets.all(8.0),
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: const BorderRadius.all(Radius.circular(20)),
                              boxShadow: const [BoxShadow(color: Colors.grey, blurRadius: 5.0)],
                              border: Border.all(color: primaryColor, width: .5)),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            [getText('totalProfit'), totalProfit],
                            [getText('totalIn'), totalIn],
                            [getText('totalOut'), totalOut],
                            [getText('totalLoan'), totalLoan],
                            [getText('totalDeposit'), totalDeposit],
                            [getText('reserveProfit'), reserveProfit],
                          ].map((e) => boxCard(e[0] as String, e[1] as double, false)).toList(),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
    );
  }

  Widget boxCard(String title, double amount, bool clicable, {String compt = ''}) {
    var column = Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        myText(title, size: 24),
        Container(
          padding: const EdgeInsets.all(8.0),
          alignment: Alignment.center,
          child: myText(myCurrency.format(amount), size: 28),
        ),
      ],
    );
    return Expanded(
      child: Container(
        height: getHeight(context, .17),
        width: getWidth(context, .22),
        margin: const EdgeInsets.all(8.0),
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.all(Radius.circular(20)),
            boxShadow: const [BoxShadow(color: Colors.grey, blurRadius: 5.0)],
            border: Border.all(color: primaryColor, width: .5)),
        child: !clicable
            ? column
            : InkWell(
                onTap: () {
                  context.read<TransactionsFilter>().change(
                        transactionCategory: compt == 'caisse' ? 'caisse' : 'specials',
                        compt: compt == 'caisse' ? 'tout' : compt,
                      );
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MyApp(index: 'tr')));
                },
                onLongPress: () async => await createDialog(
                  context,
                  AddTransaction(
                    sourceTab: 'da',
                    category: getKeyFromValue(title),
                    selectedTransactionType: 0,
                  ),
                  false,
                ),
                child: column,
              ),
      ),
    );
  }
}


// : Column(
      //     children: [
      //       Row(
      //         children: [
      //           [getText('caisse'), data['caisse'], const Color(0xbbb19c97), true],
      //           [getText('reserve'), data['reserve'], const Color(0xbbffbf62), true],
      //           [getText('donation'), data['donation'], const Color(0xbbD3A4F8), true],
      //           [getText('zakat'), data['zakat'], const Color(0xbba1fcf5), true],
      //         ].map((e) => boxCard(e[0], double.parse(e[1]), e[2], clicable: e[3])).toList(),
      //       ),
      //       Row(
      //         children: [
      //           [getText('capitalUsers'), data['capitalUsers'], const Color(0xbbcdf6f2), false],
      //           [getText('capitalUnits'), data['capitalUnits'], const Color(0xbb5a80fb), false],
      //           [getText('totalIn'), data['totalIn'], const Color(0xbbc4a471), false],
      //           [getText('totalOut'), data['totalOut'], const Color(0xbb0e737e), false],
      //         ].map((e) => boxCard(e[0], double.parse(e[1]), e[2], clicable: e[3])).toList(),
      //       ),
      //       Row(
      //         children: [
      //           [getText(''), '0', const Color(0xbbcdf6f2), false],
      //           [getText(''), '0', const Color(0xbb5a80fb), false],
      //           [getText('totalLoan'), data['totalLoan'], const Color(0xbbc4a471), false],
      //           [getText('totalDeposit'), data['totalDeposit'], const Color(0xbb0e737e), false],
      //         ].map((e) => boxCard(e[0], double.parse(e[1]), e[2], clicable: e[3])).toList(),
      //       ),
      //     ],
      //   ),






// Expanded(
//                         child: Column(
//                       children: [
//                         Row(
//                           children: [
//                             [getText('totalIn'), data['totalIn'], const Color(0xbbc4a471), false],
//                             [getText('totalOut'), data['totalOut'], const Color(0xbb0e737e), false],
//                           ].map((e) => boxCard(e[0], double.parse(e[1]), e[2], clicable: e[3])).toList(),
//                         ),
//                         Row(
//                           children: [
//                             [getText('totalLoan'), data['totalLoan'], const Color(0xbbc4a471), false],
//                             [getText('totalDeposit'), data['totalDeposit'], const Color(0xbb0e737e), false],
//                           ].map((e) => boxCard(e[0], double.parse(e[1]), e[2], clicable: e[3])).toList(),
//                         ),
//                         Row(
//                           children: [
//                             [getText('capitalUsers'), data['capitalUsers'], const Color(0xbbcdf6f2), false],
//                             [getText('capitalUnits'), data['capitalUnits'], const Color(0xbb5a80fb), false],
//                           ].map((e) => boxCard(e[0], double.parse(e[1]), e[2], clicable: e[3])).toList(),
//                         ),
//                       ],
//                     )),




// Column(
//               children: [
//                 Row(
//                   children: [
//                     [getText('caisse'), data['caisse'], const Color(0xbbb19c97), true],
//                     [getText('reserve'), data['reserve'], const Color(0xbbffbf62), true],
//                     [getText('donation'), data['donation'], const Color(0xbbD3A4F8), true],
//                     [getText('zakat'), data['zakat'], const Color(0xbba1fcf5), true],
//                   ].map((e) => boxCard(e[0], double.parse(e[1]), e[2], clicable: e[3])).toList(),
//                 ),
//                 Row(
//                   children: [
//                     [getText('totalIn'), data['totalIn'], const Color(0xbbc4a471), false],
//                     [getText('totalOut'), data['totalOut'], const Color(0xbb0e737e), false],
//                     [getText('totalLoan'), data['totalLoan'], const Color(0xbbc4a471), false],
//                     [getText('totalDeposit'), data['totalDeposit'], const Color(0xbb0e737e), false],
//                   ].map((e) => boxCard(e[0], double.parse(e[1]), e[2], clicable: e[3])).toList(),
//                 ),
//                 Expanded(
//                     child: Row(
//                   children: [
//                     Expanded(
//                       child: Container(
//                         margin: const EdgeInsets.all(8.0),
//                         padding: const EdgeInsets.all(8.0),
//                         decoration: BoxDecoration(
//                             color: Colors.white,
//                             borderRadius: const BorderRadius.all(Radius.circular(20)),
//                             boxShadow: const [BoxShadow(color: Colors.grey, blurRadius: 5.0)],
//                             border: Border.all(color: primaryColor, width: .5)),
//                       ),
//                     ),
//                     Expanded(
//                       child: Container(
//                         margin: const EdgeInsets.all(8.0),
//                         padding: const EdgeInsets.all(8.0),
//                         decoration: BoxDecoration(
//                             color: Colors.white,
//                             borderRadius: const BorderRadius.all(Radius.circular(20)),
//                             boxShadow: const [BoxShadow(color: Colors.grey, blurRadius: 5.0)],
//                             border: Border.all(color: primaryColor, width: .5)),
//                       ),
//                     ),
//                   ],
//                 ))
//               ],
//             ),






