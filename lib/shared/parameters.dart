import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pdf;
import 'package:http/http.dart' as http;

String password = '';
int currentYear = 2023;
bool namesHidden = true;
DateTime startDate = DateTime.now();
DateTime endDate = DateTime.now();

int destinationPageIndex = 1;

Color winTileColor = const Color(0XFF303F9F);

// Color scaffoldColor = const Color(0xFF4f5b62);
Color scaffoldColor = const Color(0xFFf0f2f5);

List<pdf.Font> fonts = [];
double textFeildHeight = .05;

Uri insertUrl = Uri.parse('http://localhost/wintest/insert.php');
Uri insertSPUrl = Uri.parse('http://localhost/wintest/insertSP.php');
Uri selectUrl = Uri.parse('http://localhost/wintest/select.php');

dynamic sqlQuery(Uri uri, dynamic params) async {
  Map<String, dynamic> globalParams = {
    'host': 'localhost',
    'user': 'root',
    'pass': '',
    'db': 'wintest',
  };

  globalParams.addAll(params);
  var res = await http.post(uri, body: jsonEncode(globalParams));
  return jsonDecode(res.body);
}

NumberFormat myCurrency = NumberFormat.currency(symbol: '', customPattern: '#,##0.00', locale: 'fr_FR');

DateFormat myDateFormate = DateFormat('dd-MM-yyyy');
DateFormat myDateFormate2 = DateFormat('dd MMM yyyy');
DateFormat myDateFormate3 = DateFormat('dd MMMM yyyy');

double getWidth(BuildContext context, double size) => MediaQuery.of(context).size.width * size;

double getHeight(BuildContext context, double size) => MediaQuery.of(context).size.height * size;

Widget mySizedBox(BuildContext context) => SizedBox(height: getHeight(context, .01), width: getWidth(context, .005));
