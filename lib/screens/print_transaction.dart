import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;

import '../shared/functions.dart';
import '../shared/constants.dart';
import '../shared/widgets.dart';

class PrintTransaction extends StatefulWidget {
  final String source; //user/loan/deposit
  final String type; //in/out
  final String reference;
  final double amount;
  final String date;
  const PrintTransaction({
    super.key,
    required this.source,
    required this.type,
    required this.reference,
    required this.amount,
    required this.date,
  });

  @override
  State<PrintTransaction> createState() => _PrintTransactionState();
}

class _PrintTransactionState extends State<PrintTransaction> {
  late pw.Document pdf;
  String amountOnLetter = '';
  String intermediates = '';
  String notes = '';
  String user = '';
  String reciver = '';
  late String amountType;
  List<String> recivers = [];

  void loadRecivers() async {
    for (var item in (await sqlQuery(reciversUrl, {}))['data']) {
      recivers.add(item.toString());
    }
  }

  @override
  void initState() {
    loadRecivers();
    amountOnLetter = '${numberToArabicWords(widget.amount.toInt())} دينار';
    amountType = (widget.source == 'loan' && widget.type == 'in')
        ? 'رد للسلف'
        : (widget.source == 'loan' && widget.type == 'out')
            ? 'سلف'
            : (widget.source == 'deposit' && widget.type == 'in')
                ? 'وديعة'
                : 'سحب من وديعة';
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    pdf = pw.Document();
    return SizedBox(
      height: getHeight(context, .85),
      width: getWidth(context, .7),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  mySizedBox(context),
                  myText('المبلغ بالحروف', isBold: true),
                  mySizedBox(context),
                  TextFormField(
                    initialValue: amountOnLetter,
                    style: const TextStyle(fontSize: 18),
                    textAlign: TextAlign.end,
                    minLines: 1,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.all(12),
                      border: OutlineInputBorder(
                        gapPadding: 0,
                        borderSide: BorderSide(width: 0.5),
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                    onChanged: (value) => setState(() => amountOnLetter = value),
                  ),
                  mySizedBox(context),
                  mySizedBox(context),
                  myText((widget.type == 'in') ? 'مودع اﻷموال' : 'ساحب الأموال', isBold: true),
                  mySizedBox(context),
                  TextFormField(
                    style: const TextStyle(fontSize: 18),
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.all(12),
                      border: OutlineInputBorder(
                        gapPadding: 0,
                        borderSide: BorderSide(width: 0.5),
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                    onChanged: (value) => setState(() => user = value),
                  ),
                  mySizedBox(context),
                  mySizedBox(context),
                  myText((widget.type == 'in') ? 'مستلم اﻷموال' : 'مقدم الأموال', isBold: true),
                  mySizedBox(context),
                  Autocomplete<String>(
                    onSelected: (value) => setState(() => reciver = value),
                    optionsBuilder: (textEditingValue) =>
                        recivers.where((element) => element.contains(textEditingValue.text)),
                    fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) => TextFormField(
                        controller: textEditingController,
                        focusNode: focusNode,
                        style: const TextStyle(fontSize: 18),
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.all(12),
                          border: OutlineInputBorder(
                            gapPadding: 0,
                            borderSide: BorderSide(width: 0.5),
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                        ),
                        onChanged: (value) => setState(() => reciver = value)),
                    optionsViewBuilder: (context, onSelected, options) => Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 8.0,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: getWidth(context, .283),
                          ),
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: options.length,
                            itemBuilder: (BuildContext context, int index) {
                              final String option = options.elementAt(index);
                              return InkWell(
                                onTap: () => onSelected(option),
                                child: Container(
                                  padding: const EdgeInsets.all(16.0),
                                  alignment: Alignment.center,
                                  child: myText(option),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                  mySizedBox(context),
                  mySizedBox(context),
                  myText('الوسطاء', isBold: true),
                  mySizedBox(context),
                  TextFormField(
                    style: const TextStyle(fontSize: 18),
                    textAlign: TextAlign.end,
                    minLines: 7,
                    maxLines: 7,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.all(12),
                      border: OutlineInputBorder(
                        gapPadding: 0,
                        borderSide: BorderSide(width: 0.5),
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                    onChanged: (value) => setState(() => intermediates = value),
                  ),
                  mySizedBox(context),
                  mySizedBox(context),
                  myText('ملاحظات', isBold: true),
                  mySizedBox(context),
                  TextFormField(
                    style: const TextStyle(fontSize: 18),
                    textAlign: TextAlign.end,
                    minLines: 7,
                    maxLines: 7,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.all(12),
                      border: OutlineInputBorder(
                        gapPadding: 0,
                        borderSide: BorderSide(width: 0.5),
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                    onChanged: (value) => setState(() => notes = value),
                  ),
                  const Spacer(),
                  Center(
                    child: myButton(
                      context,
                      text: 'Imprimer',
                      icon: Icons.print,
                      color: amountOnLetter.isNotEmpty && user.isNotEmpty && reciver.isNotEmpty
                          ? primaryColor
                          : Colors.grey,
                      enabled: amountOnLetter.isNotEmpty && user.isNotEmpty && reciver.isNotEmpty,
                      onTap: () => printPdf(context, pdf.save()),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            width: getWidth(context, .39),
            child: printPage(),
          )
        ],
      ),
    );
  }

  Widget printPage() {
    final page = pdfPage(build: [
      pw.Row(children: [
        pw.Text((widget.type == 'in') ? 'وصل إيداع' : 'وصل سحب', style: const pw.TextStyle(fontSize: 25)),
        pw.Spacer(),
        pw.SizedBox(
          width: 200,
          child: pw.Column(
            children: [
              pw.Row(children: [
                pw.Expanded(flex: 4, child: pw.Text(widget.reference)),
                pw.Expanded(child: pw.Text('وصل رقم : ', style: const pw.TextStyle(fontSize: 10))),
              ]),
              pw.Row(children: [
                pw.Expanded(flex: 4, child: pw.Text(widget.date)),
                pw.Expanded(child: pw.Text('التاريخ : ', style: const pw.TextStyle(fontSize: 10))),
              ]),
            ],
          ),
        ),
      ]),
      pw.Divider(thickness: .1),
      pw.Row(children: [
        pw.Expanded(flex: 4, child: pw.Text(myCurrency.format(widget.amount))),
        pw.Expanded(child: pw.Text('المبلغ باﻷرقام : ', style: const pw.TextStyle(fontSize: 10))),
      ]),
      pw.Row(children: [
        pw.Expanded(flex: 4, child: pw.Text(amountOnLetter)),
        pw.Expanded(child: pw.Text('المبلغ بالحروف : ', style: const pw.TextStyle(fontSize: 10))),
      ]),
      pw.SizedBox(height: 16),
      if (widget.source == 'loan' || widget.source == 'deposit')
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
      if (notes.isNotEmpty)
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
          pw.Text('ملاحظات أخرى :'),
          pw.Text(notes),
          pw.SizedBox(height: 16),
        ]),
      pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Column(children: [
          pw.Text((widget.type == 'in') ? 'مستلم اﻷموال : ' : 'مقدم الأموال : ',
              style: const pw.TextStyle(fontSize: 10)),
          pw.Text(reciver),
          pw.SizedBox(height: 16),
          pw.Text('إمضاء : ', style: const pw.TextStyle(fontSize: 10)),
        ]),
        pw.Spacer(),
        pw.Column(children: [
          pw.Text((widget.type == 'in') ? 'مودع اﻷموال : ' : 'ساحب الأموال : ',
              style: const pw.TextStyle(fontSize: 10)),
          pw.Text(user),
        ]),
      ]),
    ]);
    pdf.addPage(page);
    pdf.addPage(page);
    return pdfPreview(pdf.save());
  }
}
