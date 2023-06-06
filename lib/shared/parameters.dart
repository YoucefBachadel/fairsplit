import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pdf;
import 'package:http/http.dart' as http;

int currentYear = 0;
double profitability = 0;
bool namesHidden = false;

Color primaryColor = const Color(0XFF02333c); //0XFF303F9F
Color secondaryColor = const Color(0XFF08535d);
Color scaffoldColor = const Color(0xFFf0f2f5); //0XFF99bcc4

List<pdf.Font> fonts = [];
double textFeildHeight = .05;

// String host = 'http://localhost/fairsplit';
String host = 'http://fairsplit.assala.com/php_test';
// String host = 'http://fairsplit.assala.com/php';

Uri insertUrl = Uri.parse('$host/insert.php');
Uri insertSPUrl = Uri.parse('$host/insertSP.php');
Uri selectUrl = Uri.parse('$host/select.php');

dynamic sqlQuery(Uri uri, dynamic params) async {
  var res = await http.post(uri, body: jsonEncode(params));
  return jsonDecode(res.body);
}

NumberFormat myCurrency = NumberFormat.currency(
    symbol: '', customPattern: '#,##0.00', locale: 'fr_FR');

DateFormat myDateFormate = DateFormat('dd-MM-yyyy');
DateFormat myDateFormate2 = DateFormat('dd MMM yyyy');
DateFormat myDateFormate3 = DateFormat('dd MMMM yyyy');

double getWidth(BuildContext context, double size) =>
    MediaQuery.of(context).size.width * size;

double getHeight(BuildContext context, double size) =>
    MediaQuery.of(context).size.height * size;

Widget mySizedBox(BuildContext context) =>
    SizedBox(height: getHeight(context, .01), width: getWidth(context, .005));
