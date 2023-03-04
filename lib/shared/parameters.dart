import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart';

int currentYear = 2023;
DateTime startDate = DateTime.now();
DateTime endDate = DateTime.now();

int destinationPageIndex = 1;

Color winTileColor = const Color(0XFF303F9F);

// Color scaffoldColor = const Color(0xFF4f5b62);
Color scaffoldColor = const Color(0xFFf0f2f5);

List<Font> fonts = [];
double textFeildHeight = .05;

Uri insertUrl = Uri.parse('http://localhost/wintest/insert.php');
Uri insertSPUrl = Uri.parse('http://localhost/wintest/insertSP.php');
Uri selectUrl = Uri.parse('http://localhost/wintest/select.php');
NumberFormat myCurrency = NumberFormat.currency(symbol: '', customPattern: '#,##0.00', locale: 'fr_FR');

DateFormat myDateFormate = DateFormat('dd-MM-yyyy');
DateFormat myDateFormate2 = DateFormat('dd MMM yyyy');
DateFormat myDateFormate3 = DateFormat('dd MMMM yyyy');

double getWidth(BuildContext context, double size) => MediaQuery.of(context).size.width * size;

double getHeight(BuildContext context, double size) => MediaQuery.of(context).size.height * size;
