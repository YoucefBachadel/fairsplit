import 'package:fairsplit/models/unit.dart';
import 'package:fairsplit/providers/filter.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../main.dart';
import '../shared/functions.dart';
import '../shared/lists.dart';
import '../shared/constants.dart';
import '../shared/widgets.dart';
import 'add_transaction.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({Key? key}) : super(key: key);

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  bool isLoadingData = true;
  List<Unit> units = [];
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
          // '''SELECT (SELECT SUM(capital) FROM Users) as capitalUsers,(SELECT SUM(capital) FROM Units) as capitalUnits,
          // (SELECT SUM(profit) FROM ProfitHistory WHERE year =s.currentYear) as totalProfit,
          // (SELECT SUM(amount) FROM Transaction WHERE type = 'in' AND year = s.currentYear) as totalIn,
          // (SELECT SUM(amount) FROM Transaction WHERE type = 'out' AND year = s.currentYear) as totalOut,
          // (SELECT SUM(rest) FROM OtherUsers WHERE type = 'loan') as totalLoan,
          // (SELECT SUM(rest) FROM OtherUsers WHERE type = 'deposit') as totalDeposit,
          // s.caisse, s.reserve, s.donation, s.zakat,s.profitability,s.reserveProfit, s.currentYear FROM Settings s;'''
          '''SELECT (SELECT SUM(capital) FROM Users) as capitalUsers,(SELECT SUM(capital) FROM Units) as capitalUnits,
          (SELECT SUM(profit) FROM ProfitHistory WHERE year =s.currentYear) as totalProfit,
          (SELECT SUM(rest) FROM OtherUsers WHERE type = 'loan') as totalLoan,
          (SELECT SUM(rest) FROM OtherUsers WHERE type = 'deposit') as totalDeposit,
          s.caisse, s.reserve, s.donation, s.zakat,s.profitability,s.reserveProfit, s.currentYear FROM Settings s;''',
      'sql2': 'SELECT name,profitability FROM units;',
    });
    var data = res[0][0];
    currentYear = int.parse(data['currentYear']);
    profitability = double.parse(data['profitability']);
    caisse = double.parse(data['caisse']);
    reserve = double.parse(data['reserve']);
    donation = double.parse(data['donation']);
    zakat = double.parse(data['zakat']);
    // totalIn = double.parse(data['totalIn'] ?? '0');
    // totalOut = double.parse(data['totalOut'] ?? '0');
    totalLoan = double.parse(data['totalLoan'] ?? '0');
    totalDeposit = double.parse(data['totalDeposit'] ?? '0');
    totalProfit = double.parse(data['totalProfit'] ?? '0');
    reserveProfit = double.parse(data['reserveProfit'] ?? '0');

    for (var unit in res[1]) {
      units.add(Unit(
        name: unit['name'],
        profitability: double.parse((double.parse(unit['profitability']) * 100).toStringAsFixed(2)),
      ));
    }

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
                    [getText('caisse'), myCurrency.format(caisse), 'caisse'],
                    [getText('reserve'), myCurrency.format(reserve), 'reserve'],
                    [getText('reserveProfit'), myCurrency.format(reserveProfit), 'reserveProfit'],
                    [getText('donation'), myCurrency.format(donation), 'donation'],
                    [getText('zakat'), myCurrency.format(zakat), 'zakat'],
                  ]
                      .map((e) => boxCard(
                            e[0],
                            e[1],
                            true,
                            onTap: () async => await createDialog(
                              context,
                              AddTransaction(
                                sourceTab: 'da',
                                category: getKeyFromValue(e[0]),
                                selectedTransactionType: 0,
                              ),
                            ),
                            onLongPress: () {
                              context.read<Filter>().change(
                                    transactionCategory: e[2] == 'caisse' ? 'caisse' : 'specials',
                                    compt: e[2] == 'caisse' ? 'tout' : e[2],
                                  );
                              Navigator.pushReplacement(
                                  context, MaterialPageRoute(builder: (context) => const MyApp(index: 'tr')));
                            },
                          ))
                      .toList(),
                ),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Container(
                          margin: const EdgeInsets.all(8.0),
                          padding: const EdgeInsets.all(8.0),
                          child: profitability == 0 ? emptyList() : chart(),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: const BorderRadius.all(Radius.circular(20)),
                              boxShadow: const [BoxShadow(color: Colors.grey, blurRadius: 5.0)],
                              border: Border.all(color: primaryColor, width: .5)),
                        ),
                      ),
                      Expanded(
                        child: Column(children: [
                          ...[
                            [getText('profitability'), (profitability * 100).toStringAsFixed(2)],
                            [getText('totalProfit'), myCurrency.format(totalProfit)],
                            // [getText('totalIn'), myCurrency.format(totalIn)],
                            // [getText('totalOut'), myCurrency.format(totalOut)],
                            // [getText('totalLoan'), myCurrency.format(totalLoan)],
                            // [getText('totalDeposit'), myCurrency.format(totalDeposit)],
                            // [getText('reserveProfit'), myCurrency.format(reserveProfit)],
                          ].map((e) => boxCard(e[0], e[1], false)).toList(),
                          ...[
                            [getText('totalLoan'), myCurrency.format(totalLoan), '2', 'loan'],
                            [getText('totalDeposit'), myCurrency.format(totalDeposit), '3', 'deposit'],
                          ]
                              .map((e) => boxCard(
                                    e[0],
                                    e[1],
                                    true,
                                    onTap: () async => await createDialog(
                                      context,
                                      AddTransaction(
                                        sourceTab: 'da',
                                        selectedTransactionType: int.parse(e[2]),
                                      ),
                                    ),
                                    onLongPress: () {
                                      context.read<Filter>().change(loanDeposit: e[3]);
                                      Navigator.pushReplacement(
                                          context, MaterialPageRoute(builder: (context) => const MyApp(index: 'ou')));
                                    },
                                  ))
                              .toList(),
                        ]),
                      ),
                    ],
                  ),
                )
              ],
            ),
    );
  }

  Widget boxCard(
    String title,
    String amount,
    bool clicable, {
    Function()? onTap,
    Function()? onLongPress,
  }) {
    var column = Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        myText(title, size: 24),
        Container(
          padding: const EdgeInsets.all(8.0),
          alignment: Alignment.center,
          child: myText(amount, size: 28),
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
                onLongPress: onLongPress,
                onTap: onTap,
                child: column,
              ),
      ),
    );
  }

  Widget chart() {
    return SfCircularChart(
      title: ChartTitle(
        text: getText('unitsProfitability'),
        textStyle: const TextStyle(fontSize: 24, color: Colors.black),
      ),
      tooltipBehavior: TooltipBehavior(
        enable: true,
        builder: (data, point, series, pointIndex, seriesIndex) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: myText(
              '${(data as Unit).profitability}%',
              color: Colors.white,
            ),
          );
        },
      ),
      series: [
        DoughnutSeries<Unit, String>(
            dataSource: units,
            xValueMapper: (Unit data, _) => data.name,
            yValueMapper: (Unit data, _) => data.profitability,
            enableTooltip: true,
            dataLabelSettings: DataLabelSettings(
              isVisible: true,
              showZeroValue: false,
              labelPosition: ChartDataLabelPosition.outside,
              builder: (data, point, series, pointIndex, seriesIndex) {
                return myText('${(data as Unit).name} : ${(data.profitability / profitability).toStringAsFixed(2)}%');
              },
            )),
      ],
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






