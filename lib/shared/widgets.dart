import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
}) {
  color = color ?? secondaryColor;
  return InkWell(
    onTap: isLoading ? null : onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(15),
      ),
      alignment: Alignment.center,
      width: width ?? getWidth(context, .09),
      child: isLoading
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
}) {
  controller = controller ?? TextEditingController();
  return Container(
    alignment: isCenter ? Alignment.center : Alignment.centerLeft,
    child: SizedBox(
      height: getHeight(context, textFeildHeight),
      width: width ?? getWidth(context, .06),
      child: TextFormField(
        controller: controller,
        onChanged: onChanged,
        autofocus: autoFocus,
        textAlign: TextAlign.center,
        obscureText: isPassword,
        enabled: enabled,
        style: const TextStyle(fontSize: 22),
        decoration: textInputDecoration(hint),
        inputFormatters: [isNumberOnly ? DecimalTextInputFormatter() : FilteringTextInputFormatter.deny(r'')],
      ),
    ),
  );
}

Widget myText(String text, {Color color = Colors.black, double size = 18.0}) {
  return Text(
    text,
    style: TextStyle(fontSize: size, color: color),
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
        // if (authontication) mySizedBox(context),
        // if (authontication)
        //   SizedBox(
        //     width: getWidth(context, .2),
        //     child: myTextField(
        //       context,
        //       width: getWidth(context, .18),
        //       onChanged: onChanged,
        //       isPassword: true,
        //       isCenter: true,
        //       hint: getText('password'),
        //     ),
        //   ),
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

DataCell dataCell(BuildContext context, String text, {TextAlign textAlign = TextAlign.center}) {
  return DataCell(
    SizedBox(
      width: double.infinity,
      child: Text(
        text,
        textAlign: textAlign,
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

DataTable dataTable({
  required List<DataColumn> columns,
  required List<DataRow> rows,
  bool isAscending = false,
  int? sortColumnIndex = 0,
  double columnSpacing = 10,
}) {
  return DataTable(
    sortAscending: isAscending,
    sortColumnIndex: sortColumnIndex,
    dataRowHeight: 35,
    headingRowHeight: 30,
    columnSpacing: columnSpacing,
    horizontalMargin: 8,
    headingRowColor: MaterialStateProperty.all(Colors.grey[300]),
    headingTextStyle: const TextStyle(
      color: Colors.black,
      fontWeight: FontWeight.w600,
    ),
    border: TableBorder.all(width: 0.1),
    showCheckboxColumn: false,
    columns: columns,
    rows: rows,
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
