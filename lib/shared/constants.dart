import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:http/http.dart' as http;

int currentYear = 0;
double profitability = 0;
bool isAdmin = false;
String transactionFilterYear = 'tout';
var years = <String>{};
var userNames = <String>{};
Map<String, String> realUserNames = {};

Color primaryColor = const Color(0XFF02333c); //0XFF303F9F
Color secondaryColor = const Color(0XFF08535d);
Color scaffoldColor = Colors.white; // const Color(0xFFf0f2f5); //0XFF99bcc4

double textFeildHeight = .05;
double dropDownWidth = .065;

String zero = '-';

late pw.Font pdfFont;
late pw.Font pdfFontBold;

// String host = 'http://fairsplit.assala.com/php_test';
String host = 'http://fairsplit.assala.com/php';

Uri insertUrl = Uri.parse('$host/insert.php');
Uri insertSPUrl = Uri.parse('$host/insertSP.php');
Uri selectUrl = Uri.parse('$host/select.php');
Uri reciversUrl = Uri.parse('$host/recivers.php');

dynamic sqlQuery(Uri uri, dynamic params) async {
  var res = await http.post(uri, body: jsonEncode(params));
  return jsonDecode(res.body);
}

String myPercentage(double percentage) => percentage == 0
    ? zero
    : double.parse(percentage.toStringAsFixed(2)) == percentage.toInt()
        ? percentage.toInt().toString()
        : double.parse(percentage.toStringAsFixed(2)).toString();

String myCurrency(double amount) =>
    amount == 0 ? zero : (NumberFormat.currency(symbol: '', customPattern: '#,##0.00', locale: 'fr_FR')).format(amount);

String dateFormat(DateTime date) => DateFormat('dd-MM-yyyy').format(date);

DateFormat myDateFormate = DateFormat('dd-MM-yyyy');
DateFormat myDateFormate2 = DateFormat('dd MMM yyyy');
DateFormat myDateFormate3 = DateFormat('dd MMMM yyyy');

double getWidth(BuildContext context, double size) => MediaQuery.of(context).size.width * size;

double getHeight(BuildContext context, double size) => MediaQuery.of(context).size.height * size;

Widget mySizedBox(BuildContext context) => SizedBox(height: getHeight(context, .01), width: getWidth(context, .005));
