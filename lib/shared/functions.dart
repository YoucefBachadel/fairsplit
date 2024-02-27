import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart';
import 'package:universal_html/html.dart' show AnchorElement;
import 'package:flutter/foundation.dart' show kIsWeb;

void snackBar(BuildContext context, String message, {int duration = 3}) async {
  showGeneralDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(.1),
    pageBuilder: (context, animation, secondaryAnimation) {
      Future.delayed(Duration(seconds: duration), () {
        Navigator.of(context).pop(); // Close the dialog
      });
      return Align(
        alignment: Alignment.bottomCenter,
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.all(16.0),
            padding: const EdgeInsets.all(16.0),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
            decoration: const BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
        ),
      );
    },
  );
}

Future createDialog(BuildContext context, Widget content, {bool dismissable = true}) {
  return showDialog(
      barrierDismissible: dismissable,
      context: context,
      builder: (context) => StatefulBuilder(
          builder: (context, setState) => Dialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
                child: content,
              )));
}

Future<void> createExcel(String name, List<List<dynamic>> data) async {
  final Workbook workbook = Workbook();
  final Worksheet sheet = workbook.worksheets[0];

  int i = 1, j = 1;
  for (var row in data) {
    for (var element in row) {
      sheet.getRangeByIndex(i, j).setText(element.toString());
      j++;
    }
    j = 1;
    i++;
  }
  final List<int> bytes = workbook.saveAsStream();
  workbook.dispose();

  if (kIsWeb) {
    AnchorElement(href: 'data:application/octet-stream;charset=utf-16le;base64,${base64.encode(bytes)}')
      ..setAttribute('download', '$name.xlsx')
      ..click();
  } else {
    final String? initialDirectory = (await getDownloadsDirectory())?.path;
    String? fileName = await FilePicker.platform.saveFile(
      dialogTitle: 'Please select an output file:',
      initialDirectory: initialDirectory,
      fileName: name,
      allowedExtensions: ['xlsx'],
    );

    if (fileName != null) {
      final File file = File('$fileName.xlsx');
      await file.writeAsBytes(bytes, flush: true);
    }
  }

  // final String? path = (await getDownloadsDirectory())?.path;
  // final String fileName = Platform.isWindows ? '$path\\$name.xlsx' : '$path/$name.xlsx';
  // final File file = File(fileName);
  // await file.writeAsBytes(bytes, flush: true);
}

String numberToArabicWords(double number) {
  String result = '${getIntToWord(number.toInt())} دينار';

  String decimalPart = (number.toStringAsFixed(2)).split('.')[1];

  if (decimalPart != '00') {
    result += ' و ${getIntToWord(int.parse(decimalPart))} سنتيم';
  }

  return result;
}

String getIntToWord(int number) {
  final List<String> units = ['صفر', 'واحد', 'اثنان', 'ثلاثة', 'أربعة', 'خمسة', 'ستة', 'سبعة', 'ثمانية', 'تسعة'];

  final List<String> tens = ['', 'عشرة', 'عشرون', 'ثلاثون', 'أربعون', 'خمسون', 'ستون', 'سبعون', 'ثمانون', 'تسعون'];

  final List<String> hundreds = [
    '',
    'مائة',
    'مائتان',
    'ثلاثمائة',
    'أربعمائة',
    'خمسمائة',
    'ستمائة',
    'سبعمائة',
    'ثمانمائة',
    'تسعمائة',
  ];

  if (number >= 0 && number <= 9) {
    return units[number];
  } else if (number >= 10 && number <= 99) {
    if (number % 10 == 0) {
      return tens[number ~/ 10];
    } else {
      return (number == 11)
          ? 'أحد عشر'
          : (number == 12)
              ? 'إثنا عشر'
              : (number ~/ 10 == 1)
                  ? '${units[number % 10]} عشر'
                  : '${units[number % 10]} و ${tens[number ~/ 10]}';
    }
  } else if (number >= 100 && number <= 999) {
    String unit = hundreds[number ~/ 100];
    return (number % 100 == 0) ? unit : '$unit و ${getIntToWord(number % 100)}';
  } else if (number >= 1000 && number <= 999999) {
    String unit = (number ~/ 1000 == 1)
        ? 'ألف'
        : (number ~/ 1000 == 2)
            ? 'ألفين'
            : (number ~/ 1000 % 100 >= 3 && number ~/ 1000 % 100 <= 10)
                ? '${getIntToWord(number ~/ 1000)} آلاف'
                : '${getIntToWord(number ~/ 1000)} ألف';
    return (number % 1000 == 0) ? unit : '$unit و ${getIntToWord(number % 1000)}';
  } else if (number >= 1000000 && number <= 999999999) {
    String unit = (number ~/ 1000000 == 1)
        ? 'مليون'
        : (number ~/ 1000000 == 2)
            ? 'مليونين'
            : (number ~/ 1000000 % 100 >= 3 && number ~/ 1000000 % 100 <= 10)
                ? '${getIntToWord(number ~/ 1000000)} ملايين'
                : '${getIntToWord(number ~/ 1000000)} مليون';
    return (number % 1000000 == 0) ? unit : '$unit و ${getIntToWord(number % 1000000)}';
  }

  return 'Number out of range';
}

void printPdf(BuildContext context, Future<Uint8List> pdf) async {
  await Printing.layoutPdf(
    usePrinterSettings: true,
    onLayout: (PdfPageFormat format) async => pdf,
  );
}
