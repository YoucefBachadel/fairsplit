import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../shared/parameters.dart';
import '../widgets/widget.dart';

class PdfGenerator extends StatefulWidget {
  final Map<String, dynamic> import;
  const PdfGenerator({Key? key, required this.import}) : super(key: key);

  @override
  State<PdfGenerator> createState() => _PdfGeneratorState();
}

class _PdfGeneratorState extends State<PdfGenerator> {
  final doc = pw.Document();
  late Uint8List pdf;
  late List<Map<String, dynamic>> data;

  @override
  void initState() {
    super.initState();
    _generatePdf();
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
          final key = event.logicalKey;
          if (key == LogicalKeyboardKey.keyP) {
            printPdf();
          }
        },
        child: PdfPreview(
          build: (format) => doc.save(),
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
      onLayout: (PdfPageFormat format) async => doc.save(),
    ).then((value) => value ? Navigator.pop(context) : null);
  }

  void _generatePdf() async {
    fonts.add(pw.Font.ttf(await rootBundle.load('assets/arial.ttf')));

    data = widget.import['data'] ?? [];
    switch (widget.import['source']) {
      case 'user':
        userPage().then((value) {
          doc.save().then((value) {
            setState(() {
              pdf = value;
            });
          });
        });
        break;
      case 'transaction':
        transactionPage().then((value) {
          doc.save().then((value) {
            setState(() {
              pdf = value;
            });
          });
        });
        break;
    }
  }

  pw.MultiPage pdfPage(List<pw.Widget> build) {
    return pw.MultiPage(
      pageFormat: PdfPageFormat.a5,
      margin: const pw.EdgeInsets.all(40),
      maxPages: 1000,
      header: (pw.Context context) => pw.Center(child: pw.Text('Header')),
      footer: (pw.Context context) => pw.Center(child: pw.Text('Footer')),
      build: (pw.Context context) => build,
    );
  }

  Future<void> userPage() async {
    doc.addPage(pdfPage([
      pw.Center(
        child: pw.Column(children: [
          pdfTable([
            pw.TableRow(children: [
              pdfTableHeaderRow('ID'),
              pdfTableHeaderRow('Name'),
            ]),
            ...data
                .map((ele) => pw.TableRow(children: [
                      pdfTableRow(
                        text: ele['asId'].toString(),
                        alignment: pw.Alignment.centerRight,
                      ),
                      pdfTableRow(
                        text: ele['asName'],
                        alignment: pw.Alignment.centerLeft,
                        textDirection: pw.TextDirection.rtl,
                      ),
                    ]))
                .toList(),
          ]),
        ]),
      )
    ]));
  }

  Future<void> transactionPage() async {
    doc.addPage(pdfPage([
      pdfTable([
        pw.TableRow(children: [
          pdfTableHeaderRow('Date'),
          pdfTableHeaderRow('Name'),
          pdfTableHeaderRow('Type'),
          pdfTableHeaderRow('Somme'),
        ]),
        ...data
            .map(
              (ele) => pw.TableRow(children: [
                pdfTableRow(text: dateFormat(ele['trDate'])),
                pdfTableRow(
                  text: ele['asName'],
                  alignment: pw.Alignment.centerLeft,
                  textDirection: pw.TextDirection.rtl,
                ),
                pdfTableRow(text: ele['trType']),
                pdfTableRow(
                  text: currencyFormate(ele['trSomme']),
                  alignment: pw.Alignment.centerRight,
                ),
              ]),
            )
            .toList(),
      ]),
    ]));
  }

  pw.Table pdfTable(List<pw.TableRow> children) {
    return pw.Table(
      border: pw.TableBorder.all(width: 0.2),
      children: children,
    );
  }

  pw.Widget pdfTableHeaderRow(String text) {
    return pw.Container(
      alignment: pw.Alignment.center,
      child: pw.Text(text),
    );
  }

  pw.Widget pdfTableRow({
    required String text,
    pw.Alignment? alignment,
    pw.TextDirection? textDirection,
  }) {
    return pw.Container(
      alignment: alignment ?? pw.Alignment.center,
      padding: const pw.EdgeInsets.symmetric(vertical: 5.0, horizontal: 8.0),
      child: pw.Text(
        text,
        textDirection: textDirection,
        style: pw.TextStyle(
          fontFallback: fonts,
          fontSize: 8,
        ),
      ),
    );
  }
}
