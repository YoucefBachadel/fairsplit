import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;

import '../shared/functions.dart';
import '../shared/constants.dart';
import '../shared/widgets.dart';

class PrintTransaction extends StatelessWidget {
  final String source; //user/loan/deposit
  final String type; //in/out
  final String reference;
  final String user;
  final double amount;
  final double solde;
  final String date;
  final String reciver;
  final String amountOnLetter;
  final String intermediates;
  final String printingNotes;
  const PrintTransaction({
    super.key,
    required this.source,
    required this.type,
    required this.reference,
    required this.user,
    required this.amount,
    required this.solde,
    required this.date,
    required this.reciver,
    required this.amountOnLetter,
    required this.intermediates,
    required this.printingNotes,
  });

  pw.MultiPage page({bool isLeft = true}) {
    String amountType = (source == 'loan' && type == 'in')
        ? 'رد للسلف'
        : (source == 'loan' && type == 'out')
            ? 'سلف'
            : (source == 'deposit' && type == 'in')
                ? 'وديعة'
                : 'سحب من وديعة';
    return pdfPage(build: [
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            (type == 'in') ? 'وصل إيداع' : 'وصل سحب',
            style: pw.TextStyle(fontSize: 26, fontWeight: pw.FontWeight.bold),
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.SizedBox(height: 5),
              pw.Row(children: [
                data(date),
                title('التاريخ         '),
              ]),
              pw.SizedBox(height: 5),
              pw.Row(children: [
                data(reference),
                title('وصل رقم     '),
              ]),
            ],
          ),
        ],
      ),
      pw.SizedBox(height: 12),
      pw.Container(
        decoration: pw.BoxDecoration(
          border: pw.Border.all(width: .1),
          borderRadius: pw.BorderRadius.circular(12),
        ),
        padding: const pw.EdgeInsets.all(8),
        child: pw.Column(
          children: [
            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [
              data(myCurrency(amount)),
              title('المبلغ باﻷرقام      '),
            ]),
            pw.SizedBox(height: 5),
            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [
              pw.SizedBox(
                width: 270,
                child: data(amountOnLetter),
              ),
              title('المبلغ بالحروف     '),
            ]),
            pw.SizedBox(height: 5),
            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [
              data(solde == 0 ? '0' : myCurrency(solde)),
              title('الرصيد الحالي       '),
            ]),
          ],
        ),
      ),
      pw.SizedBox(height: 12),
      if (source == 'loan' || source == 'deposit')
        pw.Column(children: [
          title('هذا المبلغ عبارة عن $amountType'),
          pw.SizedBox(height: 12),
        ]),
      if (intermediates.isNotEmpty)
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
          title('للعملية وسطاء هم'),
          data(intermediates),
          pw.SizedBox(height: 12),
        ]),
      if (printingNotes.isNotEmpty)
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
          title('ملاحظات أخرى'),
          data(printingNotes),
          pw.SizedBox(height: 12),
        ]),
      pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Column(children: [
          title((type == 'in') ? 'مستلم اﻷموال' : 'مقدم الأموال'),
          pw.SizedBox(height: 3),
          data(reciver),
          pw.SizedBox(height: 12),
          if (isLeft) title('إمضاء'),
        ]),
        pw.Spacer(),
        pw.Column(children: [
          title((type == 'in') ? 'مودع اﻷموال' : 'ساحب الأموال'),
          pw.SizedBox(height: 3),
          data(user),
          pw.SizedBox(height: 12),
          if (!isLeft) title('إمضاء'),
        ]),
      ]),
    ]);
  }

  pw.Text data(String text) => pw.Text(text, style: const pw.TextStyle(fontSize: 10));

  pw.Text title(String text) => pw.Text(text, style: pw.TextStyle(fontWeight: pw.FontWeight.bold));

  @override
  Widget build(BuildContext context) {
    pw.Document pdf = pw.Document();

    pdf.addPage(page());
    pdf.addPage(page(isLeft: false));

    return SizedBox(
      width: getWidth(context, .392),
      child: Stack(
        children: [
          pdfPreview(pdf.save()),
          Positioned(
            bottom: 16,
            right: 20,
            child: FloatingActionButton(
              mini: true,
              onPressed: () => printPdf(context, pdf.save()),
              child: const Icon(Icons.print),
            ),
          ),
        ],
      ),
    );
  }
}
