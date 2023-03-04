import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../shared/lists.dart';
import 'parameters.dart';

Widget myPogress() {
  return Center(
    child: CircularProgressIndicator(
      color: winTileColor,
    ),
  );
}

Widget myButton(
  BuildContext context, {
  String? text,
  required Function() onTap,
  bool noIcon = false,
  IconData icon = Icons.save,
  double? width,
  Color color = Colors.green,
}) {
  return InkWell(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(15),
      ),
      alignment: Alignment.center,
      width: width ?? getWidth(context, .09),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          noIcon
              ? const SizedBox()
              : Icon(
                  icon,
                  color: Colors.white,
                ),
          const SizedBox(width: 6.0),
          myText(text ?? getText('save'), color: Colors.white)
        ],
      ),
    ),
  );
}

Widget myTextField(
  BuildContext context, {
  String hint = '',
  double? width,
  bool enabled = true,
  bool isNumberOnly = false,
  bool autoFocus = false,
  required Function(String text) onChanged,
}) {
  return Container(
    alignment: Alignment.centerLeft,
    child: SizedBox(
      height: getHeight(context, textFeildHeight),
      width: width ?? getWidth(context, .06),
      child: TextFormField(
        onChanged: onChanged,
        autofocus: autoFocus,
        textAlign: TextAlign.center,
        enabled: enabled,
        style: const TextStyle(fontSize: 22),
        decoration: textInputDecoration(hint),
        inputFormatters: [
          isNumberOnly
              ? DecimalTextInputFormatter()
              : FilteringTextInputFormatter.deny(r'')
        ],
      ),
    ),
  );
}

Widget myText(String text, {Color color = Colors.black}) {
  return Text(
    text,
    style: TextStyle(fontSize: 18.0, color: color),
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
    alignment: Alignment.center,
    height: getHeight(context, textFeildHeight),
    width: width ?? getWidth(context, .09),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: color),
      borderRadius: const BorderRadius.all(Radius.circular(12)),
    ),
    child: DropdownButtonFormField(
      style: const TextStyle(fontSize: 18, color: Colors.black),
      decoration: const InputDecoration(
        border: OutlineInputBorder(
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 8.0),
      ),
      value: value,
      isExpanded: true,
      items: items,
      onChanged: onChanged,
    ),
  );
}

String dateFormat(DateTime date) {
  return DateFormat('dd-MM-yyyy').format(date);
}

Future createDialog(BuildContext context, Widget content, bool dismissable) {
  return showDialog(
    barrierDismissible: dismissable,
    context: context,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      child: content,
    ),
  );
}

Widget delteConfirmation(
  BuildContext context,
  String message,
  Function() onTap,
) {
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
          style: Theme.of(context)
              .textTheme
              .headline5
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        SizedBox(width: getWidth(context, .16), child: const Divider()),
        const SizedBox(height: 12.0),
        Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headline6,
        ),
        const SizedBox(height: 16.0),
        myButton(context,
            onTap: onTap,
            noIcon: true,
            color: Colors.red,
            text: getText('confirm'))
      ],
    ),
  );
}

Widget verticalDivider() {
  return const VerticalDivider(
    color: Colors.black,
    thickness: 0.2,
  );
}

Widget emptyList() {
  return Container(
    alignment: Alignment.center,
    child: Text(
      getText('emptyList'),
      style: const TextStyle(fontSize: 30, color: Colors.grey),
    ),
  );
}

void snackBar(BuildContext context, String message, {int duration = 3}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      elevation: 1.0,
      shape: RoundedRectangleBorder(
        side: BorderSide(
            color: Theme.of(context).colorScheme.secondary, width: 2.0),
        borderRadius: BorderRadius.circular(6.0),
      ),
      content: Text(
        message,
        textAlign: TextAlign.center,
      ),
      duration: Duration(seconds: duration),
    ));
}

InputDecoration textInputDecoration(String hint) {
  return InputDecoration(
    hintText: hint,
    contentPadding: const EdgeInsets.all(0),
    filled: true,
    fillColor: Colors.white,
    border: const OutlineInputBorder(
      borderSide: BorderSide(),
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
  );
}

DataCell dataCell(BuildContext context, String text,
    {TextAlign textAlign = TextAlign.center}) {
  return DataCell(
    SizedBox(
      width: double.infinity,
      child: Text(
        text,
        textAlign: textAlign,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.subtitle1,
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
        style: Theme.of(context)
            .textTheme
            .subtitle1
            ?.copyWith(fontWeight: FontWeight.w500),
      ),
    ),
  );
}

DataColumn sortableDataColumn(BuildContext context, String text,
    Function(int columnIndex, bool ascending) onSort) {
  return DataColumn(
    onSort: onSort,
    label: Expanded(
      child: Text(
        text,
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context)
            .textTheme
            .subtitle1
            ?.copyWith(fontWeight: FontWeight.w500),
      ),
    ),
  );
}

DataTable dataTable({
  required List<DataColumn> columns,
  required List<DataRow> rows,
  bool isAscending = false,
  int? sortColumnIndex = 0,
}) {
  return DataTable(
    sortAscending: isAscending,
    sortColumnIndex: sortColumnIndex,
    dataRowHeight: 35,
    headingRowHeight: 30,
    headingRowColor: MaterialStateProperty.all(Colors.grey[300]),
    headingTextStyle: const TextStyle(
      color: Colors.black,
      fontWeight: FontWeight.w600,
    ),
    border: TableBorder.all(width: 0.1),
    showCheckboxColumn: false,
    columnSpacing: 10.0,
    horizontalMargin: 8.0,
    columns: columns,
    rows: rows,
  );
}

String currencyFormate(double currency) {
  return NumberFormat('#,##0.00', 'fr_FR').format(currency);
}

class DecimalTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final regEx = RegExp(r'^\d*\.?\d*');
    final String newString = regEx.stringMatch(newValue.text) ?? '';
    return newString == newValue.text ? newValue : oldValue;
  }
}
