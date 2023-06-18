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

Future<void> createExcel(List<List<String>> data, String name) async {
  final Workbook workbook = Workbook();
  final Worksheet sheet = workbook.worksheets[0];
  sheet.getRangeByName('A1').setText('Fairsplit');
  final List<int> bytes = workbook.saveAsStream();
  workbook.dispose();

  if (kIsWeb) {
    AnchorElement(href: 'data:application/octet-stream;charset=utf-16le;base64,${base64.encode(bytes)}')
      ..setAttribute('download', '$name.xlsx')
      ..click();
  } else {
    String? outputFile = await FilePicker.platform.saveFile(
      dialogTitle: 'Please select an output file:',
      fileName: 'output-file.pdf',
    );

    if (outputFile != null) {
      final String? path = (await getDownloadsDirectory())?.path;
      final String fileName = Platform.isWindows ? '$path\\$name.xlsx' : '$path/$name.xlsx';
      final File file = File(fileName);
      await file.writeAsBytes(bytes, flush: true);
    }
  }
}
