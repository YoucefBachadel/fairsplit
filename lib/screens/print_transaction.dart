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
  final bool isFirst; //true only after insert new transaction to update the reciver/...
  final String reciver;
  final String amountOnLetter;
  final String intermediates;
  final String printingNotes;

  const PrintTransaction({
    super.key,
    required this.source,
    required this.type,
    required this.reference,
    required this.amount,
    required this.date,
    this.reciver = '',
    this.amountOnLetter = '',
    this.intermediates = '',
    this.printingNotes = '',
    this.isFirst = false,
  });

  @override
  State<PrintTransaction> createState() => _PrintTransactionState();
}

class _PrintTransactionState extends State<PrintTransaction> {
  late pw.Document pdf;
  String amountOnLetter = '';
  String intermediates = '';
  String printingNotes = '';
  String user = '';
  String reciver = '';
  late String amountType;
  List<String> recivers = [];
  bool isPrinting = false;

  void loadRecivers() async {
    for (var item in (await sqlQuery(reciversUrl, {}))['data']) {
      recivers.add(item.toString());
    }
  }

  @override
  void initState() {
    loadRecivers();
    if (widget.isFirst) {
      amountOnLetter = '${numberToArabicWords(widget.amount.toInt())} دينار';
    } else {
      reciver = widget.reciver;
      amountOnLetter = widget.amountOnLetter;
      intermediates = widget.intermediates;
      printingNotes = widget.printingNotes;
    }
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
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          mySizedBox(context),
                          myText('المبلغ بالحروف', isBold: true),
                          mySizedBox(context),
                          TextFormField(
                            initialValue: amountOnLetter,
                            style: const TextStyle(fontSize: 18),
                            textAlign: TextAlign.start,
                            minLines: 1,
                            maxLines: 2,
                            textDirection: TextDirection.rtl,
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
                            textDirection: TextDirection.rtl,
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
                            fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                              textEditingController.text = reciver;
                              return TextFormField(
                                controller: textEditingController,
                                focusNode: focusNode,
                                textDirection: TextDirection.rtl,
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
                                onChanged: (value) => setState(() => reciver = value),
                              );
                            },
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
                            initialValue: intermediates,
                            style: const TextStyle(fontSize: 18),
                            textAlign: TextAlign.start,
                            minLines: 2,
                            maxLines: 5,
                            textDirection: TextDirection.rtl,
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
                            initialValue: printingNotes,
                            style: const TextStyle(fontSize: 18),
                            textAlign: TextAlign.start,
                            minLines: 2,
                            maxLines: 5,
                            textDirection: TextDirection.rtl,
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.all(12),
                              border: OutlineInputBorder(
                                gapPadding: 0,
                                borderSide: BorderSide(width: 0.5),
                                borderRadius: BorderRadius.all(Radius.circular(12)),
                              ),
                            ),
                            onChanged: (value) => setState(() => printingNotes = value),
                          ),
                          mySizedBox(context),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  child: myButton(
                    context,
                    text: 'Imprimer',
                    icon: Icons.print,
                    isLoading: isPrinting,
                    color:
                        amountOnLetter.isNotEmpty && user.isNotEmpty && reciver.isNotEmpty ? primaryColor : Colors.grey,
                    enabled: amountOnLetter.isNotEmpty && user.isNotEmpty && reciver.isNotEmpty,
                    onTap: () async {
                      setState(() => isPrinting = true);
                      if (widget.isFirst) {
                        await sqlQuery(insertUrl, {
                          'sql1':
                              '''UPDATE ${widget.source == 'user' ? 'transaction' : 'transactionothers'} SET amountOnLetter = '$amountOnLetter', intermediates = '$intermediates', printingNotes = '$printingNotes', reciver = '$reciver' WHERE reference = '${widget.reference}\''''
                        });
                      }

                      printPdf(context, pdf.save());
                    },
                  ),
                ),
                mySizedBox(context),
              ],
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
    pdf.addPage(page());
    pdf.addPage(page(isLeft: false));
    return pdfPreview(pdf.save());
  }

  pw.MultiPage page({bool isLeft = true}) {
    return pdfPage(build: [
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
      if (printingNotes.isNotEmpty)
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
          pw.Text('ملاحظات أخرى :'),
          pw.Text(printingNotes),
          pw.SizedBox(height: 16),
        ]),
      pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Column(children: [
          pw.Text((widget.type == 'in') ? 'مستلم اﻷموال : ' : 'مقدم الأموال : ',
              style: const pw.TextStyle(fontSize: 10)),
          pw.Text(reciver),
          pw.SizedBox(height: 16),
          if (isLeft) pw.Text('إمضاء : ', style: const pw.TextStyle(fontSize: 10)),
        ]),
        pw.Spacer(),
        pw.Column(children: [
          pw.Text((widget.type == 'in') ? 'مودع اﻷموال : ' : 'ساحب الأموال : ',
              style: const pw.TextStyle(fontSize: 10)),
          pw.Text(user),
          pw.SizedBox(height: 16),
          if (!isLeft) pw.Text('إمضاء : ', style: const pw.TextStyle(fontSize: 10)),
        ]),
      ]),
    ]);
  }
}
