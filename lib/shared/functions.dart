import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart';
import 'package:universal_html/html.dart' show AnchorElement;
import 'package:flutter/foundation.dart' show kIsWeb;

void snackBar(BuildContext context, String message, {int duration = 3}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      elevation: 1.0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Theme.of(context).colorScheme.secondary, width: 2.0),
        borderRadius: BorderRadius.circular(6.0),
      ),
      content: Text(
        message,
        textAlign: TextAlign.center,
      ),
      duration: Duration(seconds: duration),
    ));
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

Future<void> createExcel(List<List<dynamic>> data, String name) async {
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
