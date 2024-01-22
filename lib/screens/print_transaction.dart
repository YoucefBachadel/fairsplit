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
      pw.Row(children: [
        pw.Text((type == 'in') ? 'وصل إيداع' : 'وصل سحب', style: const pw.TextStyle(fontSize: 25)),
        pw.Spacer(),
        pw.SizedBox(
          width: 200,
          child: pw.Column(
            children: [
              pw.Row(children: [
                pw.Expanded(flex: 4, child: pw.Text(reference)),
                pw.Expanded(child: pw.Text('وصل رقم : ', style: const pw.TextStyle(fontSize: 10))),
              ]),
              pw.Row(children: [
                pw.Expanded(flex: 4, child: pw.Text(date)),
                pw.Expanded(child: pw.Text('التاريخ : ', style: const pw.TextStyle(fontSize: 10))),
              ]),
            ],
          ),
        ),
      ]),
      pw.Divider(thickness: .1),
      pw.Row(children: [
        pw.Expanded(flex: 4, child: pw.Text(myCurrency(amount))),
        pw.Expanded(child: pw.Text('المبلغ باﻷرقام : ', style: const pw.TextStyle(fontSize: 10))),
      ]),
      pw.Row(children: [
        pw.Expanded(flex: 4, child: pw.Text(amountOnLetter)),
        pw.Expanded(child: pw.Text('المبلغ بالحروف : ', style: const pw.TextStyle(fontSize: 10))),
      ]),
      pw.SizedBox(height: 16),
      if (source == 'loan' || source == 'deposit')
        pw.Column(children: [
          pw.Text('هذا المبلغ عبارة عن $amountType'),
          pw.SizedBox(height: 16),
        ]),
      if (intermediates.isNotEmpty)
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
          pw.Text('للعملية وسطاء هم :'),
          pw.Text(intermediates),
          pw.SizedBox(height: 16),
        ]),
      if (printingNotes.isNotEmpty)
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
          pw.Text('ملاحظات أخرى :'),
          pw.Text(printingNotes),
          pw.SizedBox(height: 16),
        ]),
      pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Column(children: [
          pw.Text((type == 'in') ? 'مستلم اﻷموال : ' : 'مقدم الأموال : ', style: const pw.TextStyle(fontSize: 10)),
          pw.Text(reciver),
          pw.SizedBox(height: 16),
          if (isLeft) pw.Text('إمضاء : ', style: const pw.TextStyle(fontSize: 10)),
        ]),
        pw.Spacer(),
        pw.Column(children: [
          pw.Text((type == 'in') ? 'مودع اﻷموال : ' : 'ساحب الأموال : ', style: const pw.TextStyle(fontSize: 10)),
          pw.Text(user),
          pw.SizedBox(height: 16),
          if (!isLeft) pw.Text('إمضاء : ', style: const pw.TextStyle(fontSize: 10)),
        ]),
      ]),
    ]);
  }

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
            right: 16,
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
