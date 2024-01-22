import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'lists.dart';
import 'constants.dart';

Widget myProgress({Color? color}) {
  color = color ?? primaryColor;
  return Center(child: CircularProgressIndicator(color: color));
}

Widget myButton(
  BuildContext context, {
  String? text,
  required Function() onTap,
  bool noIcon = false,
  IconData icon = Icons.save,
  double? width,
  Color? color,
  Color textColor = Colors.white,
  bool isLoading = false,
  bool enabled = true,
}) {
  color = color ?? secondaryColor;
  return InkWell(
    onTap: isLoading || !enabled ? null : onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      decoration: BoxDecoration(
        color: enabled ? color : Colors.grey,
        borderRadius: BorderRadius.circular(15),
      ),
      alignment: Alignment.center,
      width: width ?? getWidth(context, .09),
      child: isLoading && enabled
          ? myProgress(color: Colors.white)
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                noIcon
                    ? const SizedBox()
                    : Icon(
                        icon,
                        color: Colors.white,
                      ),
                const SizedBox(width: 6.0),
                myText(text ?? getText('save'), color: textColor)
              ],
            ),
    ),
  );
}

Widget myTextField(
  BuildContext context, {
  TextEditingController? controller,
  String hint = '',
  double? width,
  bool enabled = true,
  bool isNumberOnly = false,
  bool autoFocus = false,
  bool isPassword = false,
  bool isCenter = false,
  required Function(String text) onChanged,
  Function(String text)? onSubmited,
}) {
  controller = controller ?? TextEditingController();
  return Container(
    alignment: isCenter ? Alignment.center : Alignment.centerLeft,
    child: SizedBox(
      height: getHeight(context, textFeildHeight),
      width: width ?? getWidth(context, .06),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        onSubmitted: onSubmited ?? (value) {},
        autofocus: autoFocus,
        obscureText: isPassword,
        enabled: enabled,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 18),
        decoration: textInputDecoration(hint: hint),
        inputFormatters: [isNumberOnly ? DecimalTextInputFormatter() : FilteringTextInputFormatter.deny(r'')],
      ),
    ),
  );
}

Widget myText(String text, {Color color = Colors.black, double size = 18.0, bool isBold = false}) {
  return Text(
    text,
    style: TextStyle(fontSize: size, color: color, fontWeight: isBold ? FontWeight.bold : FontWeight.normal),
  );
}

Widget myDropDown(
  BuildContext context, {
  required Object value,
  required List<DropdownMenuItem> items,
  required Function(dynamic value)? onChanged,
  double? width,
  Color color = Colors.grey,
}) {
  return Container(
    height: getHeight(context, textFeildHeight),
    width: width ?? getWidth(context, .08),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: color),
      borderRadius: const BorderRadius.all(Radius.circular(12)),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton(
        style: const TextStyle(fontSize: 18, color: Colors.black, overflow: TextOverflow.ellipsis),
        value: value,
        isExpanded: true,
        items: items,
        onChanged: onChanged,
        itemHeight: null,
      ),
    ),
  );
}

Widget delteConfirmation(
  BuildContext context,
  String message,
  Function() onTap, {
  Function(String)? onChanged,
  bool authontication = true,
  bool isLoading = false,
}) {
  onChanged = onChanged ?? (text) {};
  return Container(
    padding: const EdgeInsets.all(12.0),
    decoration: BoxDecoration(
      color: scaffoldColor,
      border: Border.all(width: 2.0),
      borderRadius: BorderRadius.circular(12.0),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          getText('deleteConfirmation'),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        SizedBox(width: getWidth(context, .16), child: const Divider()),
        mySizedBox(context),
        Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        mySizedBox(context),
        myButton(
          context,
          onTap: onTap,
          noIcon: true,
          isLoading: isLoading,
          color: Colors.red,
          text: getText('confirm'),
        )
      ],
    ),
  );
}

Widget verticalDivider() => const VerticalDivider(color: Colors.black, thickness: 0.2);

Widget emptyList() {
  return Container(
    alignment: Alignment.center,
    child: Text(
      getText('emptyList'),
      style: const TextStyle(fontSize: 30, color: Colors.grey),
    ),
  );
}

InputDecoration textInputDecoration({
  String hint = '',
  Widget? prefixIcon,
  Widget? suffixIcon,
  Color borderColor = Colors.black,
}) {
  return InputDecoration(
    hintText: hint,
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: borderColor),
      borderRadius: const BorderRadius.all(Radius.circular(12)),
    ),
    border: const OutlineInputBorder(
      borderSide: BorderSide(),
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,
  );
}

DataCell dataCell(
  BuildContext context,
  String text, {
  TextAlign textAlign = TextAlign.center,
  TextDirection textDirection = TextDirection.ltr,
}) {
  return DataCell(
    SizedBox(
      width: double.infinity,
      child: Text(
        text,
        textAlign: textAlign,
        textDirection: textDirection,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    ),
  );
}

DataColumn dataColumn(BuildContext context, String text) {
  return DataColumn(
    label: Expanded(
      child: Text(
        text,
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
      ),
    ),
  );
}

DataColumn sortableDataColumn(BuildContext context, String text, Function(int columnIndex, bool ascending) onSort) {
  return DataColumn(
    onSort: onSort,
    label: Expanded(
      child: Text(
        text,
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
      ),
    ),
  );
}

DataTable dataTable(
  BuildContext context, {
  required List<DataColumn> columns,
  required List<DataRow> rows,
  bool isAscending = false,
  int? sortColumnIndex = 0,
}) {
  return DataTable(
    sortAscending: isAscending,
    sortColumnIndex: sortColumnIndex,
    columnSpacing: getWidth(context, .008),
    horizontalMargin: getWidth(context, .008),
    columns: columns,
    rows: rows,
    dataRowMinHeight: getHeight(context, .035),
    dataRowMaxHeight: getHeight(context, .035),
    headingRowHeight: getHeight(context, .03),
    showCheckboxColumn: false,
    border: TableBorder.all(width: 0.2, color: Colors.black),
    headingRowColor: MaterialStateProperty.all(Colors.grey[300]),
    headingTextStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
  );
}

Widget myScorallable(Widget widget, ScrollController _controllerH, ScrollController _controllerV) {
  return Scrollbar(
    thumbVisibility: true,
    controller: _controllerH,
    child: SingleChildScrollView(
      controller: _controllerH,
      scrollDirection: Axis.horizontal,
      child: Scrollbar(
        thumbVisibility: true,
        controller: _controllerV,
        child: SingleChildScrollView(
          controller: _controllerV,
          child: widget,
        ),
      ),
    ),
  );
}

Widget totalItem(BuildContext context, String title, String value) {
  return Container(
    width: getWidth(context, .23),
    padding: const EdgeInsets.only(top: 8.0),
    child: Row(
      children: [
        Expanded(flex: 2, child: myText(title)),
        Expanded(flex: 2, child: myText(':    $value')),
      ],
    ),
  );
}

PdfPreview pdfPreview(Future<Uint8List> pdf) {
  return PdfPreview(
    build: (format) => pdf,
    allowPrinting: false,
    allowSharing: false,
    canChangeOrientation: false,
    canChangePageFormat: false,
    loadingWidget: Center(child: CircularProgressIndicator(color: primaryColor)),
  );
}

pw.MultiPage pdfPage({
  required List<pw.Widget> build,
  PdfPageFormat pdfPageFormat = PdfPageFormat.a5,
}) {
  return pw.MultiPage(
    pageFormat: pdfPageFormat,
    crossAxisAlignment: pw.CrossAxisAlignment.end,
    textDirection: pw.TextDirection.rtl,
    theme: pw.ThemeData.withFont(base: pdfFont),
    margin: const pw.EdgeInsets.all(25),
    build: (pw.Context context) => build,
  );
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

Future<pw.Widget> pdfTableRow({
  required String text,
  pw.Alignment? alignment,
  pw.TextDirection? textDirection,
}) async {
  List<pw.Font> fonts = [];
  fonts.add(pw.Font.ttf(await rootBundle.load('fonts/GothicA1-Regular.ttf')));
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

class DecimalTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final regEx = RegExp(r'^\d*\.?\d*');
    final String newString = regEx.stringMatch(newValue.text) ?? '';
    return newString == newValue.text ? newValue : oldValue;
  }
}
