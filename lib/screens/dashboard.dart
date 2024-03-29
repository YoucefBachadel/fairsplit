import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '/main.dart';
import '/models/unit.dart';
import '/providers/filter.dart';
import '/shared/functions.dart';
import '/shared/constants.dart';
import '/shared/widgets.dart';
import 'add_transaction.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({Key? key}) : super(key: key);

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  bool isLoadingData = true;
  List<Unit> units = [];
  double caisse = 0, reserve = 0, reserveProfit = 0, donation = 0, zakat = 0, totalProfit = 0, totalLoan = 0, totalDeposit = 0;

  void loadData() async {
    var res = await sqlQuery(selectUrl, {
      'sql1': '''SELECT 
                (SELECT SUM(money) FROM unithistory WHERE year =s.currentYear) as totalProfit,
                (SELECT SUM(rest) FROM OtherUsers WHERE type = 'loan') as totalLoan,
                (SELECT SUM(rest) FROM OtherUsers WHERE type = 'deposit') as totalDeposit,
                s.caisse, s.reserve, s.reserveProfit, s.donation, s.zakat, s.profitability, s.currentYear FROM Settings s;''',
      'sql2': 'SELECT name,profitability FROM units;',
    });
    var data = res[0][0];
    currentYear = int.parse(data['currentYear']);
    years.add(currentYear.toString());
    transactionFilterYear = currentYear.toString();
    caisse = double.parse(data['caisse']);
    reserve = double.parse(data['reserve']);
    reserveProfit = double.parse(data['reserveProfit']);
    donation = double.parse(data['donation']);
    zakat = double.parse(data['zakat']);
    profitability = double.parse(data['profitability']);
    totalProfit = double.parse(data['totalProfit'] ?? '0');
    totalLoan = double.parse(data['totalLoan'] ?? '0');
    totalDeposit = double.parse(data['totalDeposit'] ?? '0');

    for (var unit in res[1]) {
      units.add(Unit(
        name: unit['name'],
        profitability: double.parse(unit['profitability']) * 100,
      ));
    }
    units.sort((a, b) => b.profitability.compareTo(a.profitability));

    setState(() => isLoadingData = false);
  }

  @override
  void initState() {
    loadData();
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
                    ['Caisse', myCurrency(caisse), 'caisse'],
                    ['Reserve', myCurrency(reserve), 'reserve'],
                    ['Reserve Profit', myCurrency(reserveProfit), 'reserveProfit'],
                    ['Donation', myCurrency(donation), 'donation'],
                    ['Zakat', myCurrency(zakat), 'zakat'],
                  ]
                      .map((e) => boxCard(
                            e[0],
                            e[1],
                            true,
                            onTap: () async => await createDialog(
                              context,
                              AddTransaction(
                                sourceTab: 'da',
                                category: e[2],
                                selectedTransactionType: 0,
                              ),
                            ),
                            onLongPress: () {
                              context.read<Filter>().change(
                                    transactionCategory: e[2] == 'caisse' ? 'caisse' : 'specials',
                                    compt: e[2] == 'caisse' ? 'tout' : e[2],
                                  );
                              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MyApp(index: 'tr')));
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
                        child: Column(
                          children: [
                            ['Profitability', profitability == 0 ? zero : myPercentage(profitability * 100)],
                            ['Total Profit', myCurrency(totalProfit)],
                            ['Weighted Capital', profitability == 0 ? zero : myCurrency(totalProfit / profitability)],
                            ['Total Laon', myCurrency(totalLoan)],
                            ['Total Deposit', myCurrency(totalDeposit)],
                          ].map((e) => boxCard(e[0], e[1], false)).toList(),
                        ),
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
      children: [
        Expanded(child: Center(child: myText(title, size: 24))),
        const Divider(),
        Expanded(flex: 2, child: Center(child: myText(amount, size: 28, fontFamily: 'IBM'))),
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
        text: 'Units Profitability',
        textStyle: const TextStyle(fontSize: 24, color: Colors.black),
      ),
      tooltipBehavior: TooltipBehavior(
        enable: true,
        duration: 1500,
        builder: (data, point, series, pointIndex, seriesIndex) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: myText(
              '${(data as Unit).name} : ${myPercentage((data).profitability)}%',
              color: Colors.white,
            ),
          );
        },
      ),
      series: [
        PieSeries<Unit, String>(
            dataSource: units,
            strokeColor: Colors.white,
            strokeWidth: 1,
            radius: '60%',
            xValueMapper: (Unit data, _) => data.name,
            yValueMapper: (Unit data, _) => data.profitability,
            enableTooltip: true,
            dataLabelSettings: DataLabelSettings(
              isVisible: true,
              showZeroValue: false,
              labelPosition: ChartDataLabelPosition.outside,
              builder: (data, point, series, pointIndex, seriesIndex) {
                return myText('${(data as Unit).name} : ${myPercentage(data.profitability / profitability)}%', size: 16);
              },
            )),
      ],
    );
  }
}
