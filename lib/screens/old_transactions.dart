// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:wintest/classes/transaction.dart';
// import 'package:wintest/screens/add_transaction.dart';
// import 'package:wintest/screens/pdf_generator.dart';
// import 'package:wintest/shared/parameters.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';

// import '../shared/widget.dart';

// class Transactions extends StatelessWidget {
//   Transactions({Key? key}) : super(key: key);

//   final List<Transaction> loadedTransactions = [];
//   // get the list of all transactions
//   Future<List<Transaction>> _getTransactions() async {
//     //sending a post request to the url
//     var params = {
//       'type': 'get_all_transactions',
//       'year': Parameters.year.toString(),
//     };
//     var res = await http.post(Parameters.insertUrl, body: params);
//     //converting the fetched data from json to key value pair that can be displayed on the screen
//     final data = json.decode(res.body);

//     loadedTransactions.clear();

//     for (var element in data) {
//       loadedTransactions.add(Transaction(
//         transactionId: int.parse(element['transactionId']),
//         userId: int.parse(element['userId']),
//         userName: element['userName'],
//         year: int.parse(element['year']),
//         type: element['type'],
//         date: DateTime.parse(element['date']),
//         amount: double.parse(element['amount']),
//         soldeUser: double.parse(element['soldeUser']),
//         soldeCapital: double.parse(element['soldeCapital']),
//         note: element['note'],
//       ));
//     }

//     return loadedTransactions;
//   }

//   void _newTransaction(BuildContext context) async {
//     await createDialog(
//       context,
//       const SizedBox(
//         height: 500,
//         width: 540,
//         child: AddTransaction(),
//       ),
//       true,
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Parameters().scaffoldColor,
//       floatingActionButton: FloatingActionButton(
//         onPressed: () => _newTransaction(context),
//         child: const Icon(Icons.add),
//       ),
//       body: Container(
//         alignment: Alignment.center,
//         child: Row(
//           children: [
//             const Spacer(),
//             FutureBuilder(
//                 future: _getTransactions(),
//                 builder: (context, snapshot) {
//                   if (snapshot.hasData) {
//                     return TransactionsHome(
//                         allTransactions: loadedTransactions);
//                   } else if (snapshot.hasError) {
//                     return errorMessage();
//                   } else {
//                     return CircularProgressIndicator(
//                       color: Parameters().winTileColor,
//                     );
//                   }
//                 }),
//             const Spacer(),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class TransactionsHome extends StatefulWidget {
//   final List<Transaction> allTransactions;
//   const TransactionsHome({Key? key, required this.allTransactions})
//       : super(key: key);

//   @override
//   State<TransactionsHome> createState() => _TransactionsHomeState();
// }

// class _TransactionsHomeState extends State<TransactionsHome> {
//   List<Transaction> transactions = [];
//   final List<String> types = ['<Tout>', 'Entrie', 'Sortie'];
//   String searchType = '<Tout>';

//   String _search = '';

//   DateTime startDate = Parameters.startDate;
//   DateTime endDate = Parameters.endDate;

//   int? sortColumnIndex = 0;
//   bool isAscending = true;

//   final TextEditingController _controller = TextEditingController();

//   void filterTransactions() async {
//     transactions.clear();
//     for (var element in widget.allTransactions) {
//       if ((element.userId.toString().contains(_search) ||
//               element.userName
//                   .toString()
//                   .toLowerCase()
//                   .contains(_search.toLowerCase())) &&
//           (searchType == '<Tout>' || element.type == searchType) &&
//           (element.date.isAfter(startDate) &&
//               element.date.isBefore(DateTime(
//                 endDate.year,
//                 endDate.month,
//                 endDate.day + 1,
//               )))) {
//         transactions.add(element);
//       }
//     }

//     onSort();
//   }

//   void onSort() {
//     switch (sortColumnIndex) {
//       case 0:
//         transactions.sort((tr1, tr2) {
//           return !isAscending
//               ? tr1.date.compareTo(tr2.date)
//               : tr2.date.compareTo(tr1.date);
//         });
//         break;
//       case 1:
//         transactions.sort((tr1, tr2) {
//           return !isAscending
//               ? tr1.userName.compareTo(tr2.userName)
//               : tr2.userName.compareTo(tr1.userName);
//         });
//         break;
//       case 3:
//         transactions.sort((tr1, tr2) {
//           return !isAscending
//               ? tr1.amount.compareTo(tr2.amount)
//               : tr2.amount.compareTo(tr1.amount);
//         });
//         break;
//     }
//   }

//   void clearSearch() {
//     setState(() {
//       _search = '';
//       _controller.clear();
//       searchType = '<Tout>';
//       startDate = Parameters.startDate;
//       endDate = Parameters.endDate;
//     });
//   }

//   void printPage() {
//     createDialog(
//       context,
//       SizedBox(
//         width: 800,
//         child: PdfGenerator(
//           import: {
//             'source': 'transaction',
//             'data': [for (var ele in transactions) ele.toMap()],
//           },
//         ),
//       ),
//       true,
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     filterTransactions();
//     return RawKeyboardListener(
//       focusNode: FocusNode(),
//       autofocus: true,
//       onKey: (event) {
//         final key = event.logicalKey;
//         if (key == LogicalKeyboardKey.escape) {
//           clearSearch();
//         }
//       },
//       child: Container(
//         padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 25),
//         color: Colors.white,
//         child: IntrinsicWidth(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               filteringRow(),
//               Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 8.0),
//                 child: const Divider(),
//               ),
//               Expanded(
//                 child: transactions.isEmpty
//                     ? emptyList()
//                     : SingleChildScrollView(
//                         child: dataTable(
//                           isAscending: isAscending,
//                           sortColumnIndex: sortColumnIndex,
//                           columns: [
//                             dataColumn('Date', true),
//                             dataColumn('User', true),
//                             dataColumn('Type', false),
//                             dataColumn('Somme', true),
//                             dataColumn('Note', false),
//                           ],
//                           rows: transactions
//                               .map(
//                                 (transaction) => DataRow(
//                                   cells: [
//                                     dataCell(
//                                       dateFormat(transaction.date),
//                                       Alignment.center,
//                                     ),
//                                     dataCell(
//                                       transaction.userName,
//                                       Alignment.centerLeft,
//                                     ),
//                                     dataCell(
//                                       transaction.type,
//                                       Alignment.center,
//                                     ),
//                                     dataCell(
//                                       currencyFormate(transaction.amount),
//                                       Alignment.centerRight,
//                                     ),
//                                     dataCell(
//                                       transaction.note,
//                                       Alignment.centerLeft,
//                                     ),
//                                   ],
//                                 ),
//                               )
//                               .toList(),
//                         ),
//                       ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget filteringRow() {
//     return Row(
//       crossAxisAlignment: CrossAxisAlignment.center,
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         SizedBox(
//           width: 250,
//           height: 35,
//           child: searchBox(),
//         ),
//         const SizedBox(width: 8.0),
//         const SizedBox(
//           height: 30,
//           child: VerticalDivider(
//             thickness: 1.5,
//           ),
//         ),
//         const SizedBox(width: 8.0),
//         SizedBox(
//           width: 80.0,
//           height: 35,
//           child: typeSearchBox(),
//         ),
//         const SizedBox(width: 8.0),
//         const SizedBox(
//           height: 30,
//           child: VerticalDivider(
//             thickness: 1.5,
//           ),
//         ),
//         const SizedBox(width: 8.0),
//         const Text('From:'),
//         const SizedBox(width: 8.0),
//         SizedBox(
//           width: 100,
//           height: 35,
//           child: dateSearchBox(startDate, 1),
//         ),
//         const SizedBox(width: 8.0),
//         const Text('To:'),
//         const SizedBox(width: 8.0),
//         SizedBox(
//           width: 100,
//           height: 35,
//           child: dateSearchBox(endDate, 0),
//         ),
//         const SizedBox(width: 8.0),
//         IconButton(
//             onPressed: () => clearSearch(),
//             icon: Icon(
//               Icons.update,
//               color: Parameters().winTileColor,
//             )),
//         IconButton(
//             onPressed: () => printPage(),
//             icon: Icon(
//               Icons.print,
//               color: Parameters().winTileColor,
//             )),
//       ],
//     );
//   }

//   DataColumn dataColumn(String title, bool sortable) {
//     return DataColumn(
//         label: Text(title),
//         onSort: (int columnIndex, bool ascending) {
//           if (sortable) {
//             setState(() {
//               sortColumnIndex = columnIndex;
//               isAscending = ascending;
//             });
//           }
//         });
//   }

//   DataCell dataCell(String text, Alignment alignment) {
//     return DataCell(
//       Container(
//         alignment: alignment,
//         child: text.length < 50
//             ? Text(text)
//             : ConstrainedBox(
//                 constraints: const BoxConstraints(
//                   maxWidth: 350,
//                 ),
//                 child: Tooltip(
//                   message: text,
//                   preferBelow: false,
//                   verticalOffset: 20,
//                   padding: const EdgeInsets.all(8.0),
//                   textStyle: const TextStyle(
//                     color: Colors.white,
//                     fontSize: 16.0,
//                   ),
//                   child: Text(
//                     text,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                 ),
//               ),
//       ),
//     );
//   }

//   Widget searchBox() {
//     return TextFormField(
//       controller: _controller,
//       showCursor: false,
//       onChanged: (value) {
//         setState(() {
//           _search = value;
//         });
//       },
//       style: const TextStyle(
//         fontSize: 14.0,
//         height: 2.7,
//         color: Colors.black,
//       ),
//       decoration: InputDecoration(
//         hintText: 'Search ...',
//         focusedBorder: OutlineInputBorder(
//             borderSide: BorderSide(color: Parameters().winTileColor)),
//         prefixIcon: Icon(
//           Icons.search,
//           size: 20.0,
//           color: Parameters().winTileColor,
//         ),
//       ),
//     );
//   }

//   Widget typeSearchBox() {
//     return DropdownButtonFormField(
//       value: searchType,
//       focusColor: Colors.transparent,
//       alignment: Alignment.topRight,
//       style: const TextStyle(
//         height: 0,
//         color: Colors.black,
//       ),
//       items: types.map((item) {
//         return DropdownMenuItem(
//           alignment: Alignment.center,
//           value: item,
//           child: Text(item),
//         );
//       }).toList(),
//       onChanged: (value) {
//         setState(() {
//           searchType = value.toString();
//         });
//       },
//     );
//   }

//   Widget dateSearchBox(DateTime date, int type) {
//     return InkWell(
//       onTap: () async {
//         final DateTime? selected = await showDatePicker(
//           context: context,
//           initialDate: date,
//           firstDate: DateTime(Parameters.year),
//           lastDate: DateTime.now().year == Parameters.year
//               ? DateTime.now()
//               : DateTime(Parameters.year, 12, 31, 23, 59, 59),
//         );
//         if (selected != null && selected != date) {
//           setState(() {
//             date = selected;
//             type == 1 ? startDate = date : endDate = date;
//           });
//         }
//       },
//       child: TextField(
//         readOnly: true,
//         enabled: false,
//         decoration: InputDecoration(
//           border: const OutlineInputBorder(),
//           label: Text(
//             dateFormat(date),
//             style: const TextStyle(fontSize: 14.0, color: Colors.black),
//           ),
//         ),
//       ),
//     );
//   }
// }
