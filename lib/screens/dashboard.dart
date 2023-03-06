import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../shared/lists.dart';
import '../shared/parameters.dart';
import '../shared/widget.dart';
import 'add_transaction.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({Key? key}) : super(key: key);

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  bool isLoadingData = true;
  var data = {};

  void locadData() async {
    var params = {
      'sql':
          '''SELECT (SELECT SUM(capital) FROM Users) as capitalUsers,(SELECT SUM(capital) FROM Units) as capitalUnits,(SELECT SUM(amount) FROM Transaction WHERE type = 'in' AND year = s.currentYear) as totalIn, (SELECT SUM(amount) FROM Transaction WHERE type = 'out' AND year = s.currentYear) as totalOut,(SELECT SUM(rest) FROM OtherUsers WHERE type = 'loan') as totalLoan,(SELECT SUM(rest) FROM OtherUsers WHERE type = 'deposit') as totalDeposit, s.* FROM Settings s;'''
    };
    var res = await http.post(selectUrl, body: params);
    data = (json.decode(res.body))['data'][0];
    currentYear = int.parse(data['currentYear']);
    setState(() {
      isLoadingData = false;
    });
  }

  @override
  void initState() {
    locadData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // Color(Random().nextInt(0xffffffff)).withAlpha(0xbb); // random color generator
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: isLoadingData
          ? Container(
              margin: const EdgeInsets.all(16.0),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(8)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey,
                    blurRadius: 3.0,
                  ),
                ],
              ),
              child: myPogress())
          : Column(
              children: [
                Row(
                  children: [
                    [getText('caisse'), data['caisse'], const Color(0xbbb19c97), true],
                    [getText('reserve'), data['reserve'], const Color(0xbbffbf62), true],
                    [getText('donation'), data['donation'], const Color(0xbbD3A4F8), true],
                    [getText('zakat'), data['zakat'], const Color(0xbba1fcf5), true],
                  ].map((e) => boxCard(e[0], double.parse(e[1]), e[2], clicable: e[3])).toList(),
                ),
                Row(
                  children: [
                    [getText('capitalUsers'), data['capitalUsers'], const Color(0xbbcdf6f2), false],
                    [getText('capitalUnits'), data['capitalUnits'], const Color(0xbb5a80fb), false],
                    [getText('totalIn'), data['totalIn'], const Color(0xbbc4a471), false],
                    [getText('totalOut'), data['totalOut'], const Color(0xbb0e737e), false],
                  ].map((e) => boxCard(e[0], double.parse(e[1]), e[2], clicable: e[3])).toList(),
                ),
                Row(
                  children: [
                    [getText(''), '0', const Color(0xbbcdf6f2), false],
                    [getText(''), '0', const Color(0xbb5a80fb), false],
                    [getText('totalLoan'), data['totalLoan'], const Color(0xbbc4a471), false],
                    [getText('totalDeposit'), data['totalDeposit'], const Color(0xbb0e737e), false],
                  ].map((e) => boxCard(e[0], double.parse(e[1]), e[2], clicable: e[3])).toList(),
                ),
              ],
            ),
    );
  }

  Widget boxCard(String title, double amount, Color color, {bool clicable = false}) {
    var column = Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            title,
            style: Theme.of(context).textTheme.headline4?.copyWith(color: Colors.grey[900]),
          ),
        ),
        Divider(thickness: 0.3, color: Colors.grey[900]),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 35),
            child: Text(
              myCurrency.format(amount),
              style: Theme.of(context).textTheme.headline4?.copyWith(fontSize: 30, color: Colors.grey[900]),
            ),
          ),
        ),
      ],
    );
    return Expanded(
      child: Container(
        height: getHeight(context, .25),
        margin: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
        decoration: const BoxDecoration(
          // color: Colors.white,
          color: Color(0xbbcdf6f2),
          borderRadius: BorderRadius.all(Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.grey,
              blurRadius: 2.0,
            ),
          ],
        ),
        child: !clicable
            ? column
            : InkWell(
                onTap: () async => await createDialog(
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
