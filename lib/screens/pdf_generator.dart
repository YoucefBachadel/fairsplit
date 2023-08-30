import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../shared/constants.dart';

class PdfGenerator extends StatefulWidget {
  final Future<Uint8List> pdf;
  const PdfGenerator({Key? key, required this.pdf}) : super(key: key);

  @override
  State<PdfGenerator> createState() => _PdfGeneratorState();
}

class _PdfGeneratorState extends State<PdfGenerator> {
  late Future<Uint8List> pdf;
  late List<Map<String, dynamic>> data;

  @override
  void initState() {
    super.initState();
    pdf = widget.pdf;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        mini: true,
        onPressed: () => printPdf(),
        child: const Icon(Icons.print),
      ),
      body: RawKeyboardListener(
        focusNode: FocusNode(),
        autofocus: true,
        onKey: (event) {
          if (event.logicalKey == LogicalKeyboardKey.keyP) printPdf();
        },
        child: PdfPreview(
          build: (format) => pdf,
          allowPrinting: false,
          allowSharing: false,
          canChangeOrientation: false,
          canChangePageFormat: false,
          loadingWidget: Center(
            child: CircularProgressIndicator(color: primaryColor),
          ),
        ),
      ),
    );
  }

  void printPdf() async {
    await Printing.layoutPdf(
      usePrinterSettings: true,
      onLayout: (PdfPageFormat format) async => pdf,
    ).then((value) => value ? Navigator.pop(context) : null);
  }
}
  // Future<void> userPage() async {
  //   doc.addPage(pdfPage([
  //     pw.Center(
  //       child: pw.Column(children: [
  //         pdfTable([
  //           pw.TableRow(children: [
  //             pdfTableHeaderRow('ID'),
  //             pdfTableHeaderRow('Name'),
  //           ]),
  //           ...data
  //               .map((ele) => pw.TableRow(children: [
  //                     pdfTableRow(
  //                       text: ele['asId'].toString(),
  //                       alignment: pw.Alignment.centerRight,
  //                     ),
  //                     pdfTableRow(
  //                       text: ele['asName'],
  //                       alignment: pw.Alignment.centerLeft,
  //                       textDirection: pw.TextDirection.rtl,
  //                     ),
  //                   ]))
  //               .toList(),
  //         ]),
  //       ]),
  //     )
  //   ]));
  // }

  // Future<void> transactionPage() async {
  //   doc.addPage(pdfPage([
  //     pdfTable([
  //       pw.TableRow(children: [
  //         pdfTableHeaderRow('Date'),
  //         pdfTableHeaderRow('Name'),
  //         pdfTableHeaderRow('Type'),
  //         pdfTableHeaderRow('Somme'),
  //       ]),
  //       ...data
  //           .map(
  //             (ele) => pw.TableRow(children: [
  //               pdfTableRow(text: dateFormat(ele['trDate'])),
  //               pdfTableRow(
  //                 text: ele['asName'],
  //                 alignment: pw.Alignment.centerLeft,
  //                 textDirection: pw.TextDirection.rtl,
  //               ),
  //               pdfTableRow(text: ele['trType']),
  //               pdfTableRow(
  //                 text: myCurrency.format(ele['trSomme']),
  //                 alignment: pw.Alignment.centerRight,
  //               ),
  //             ]),
  //           )
  //           .toList(),
  //     ]),
  //   ]));
  // }


