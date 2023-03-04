// import 'package:flutter/material.dart';
// import 'package:wintest/classes/user.dart';
// import 'package:wintest/main.dart';
// import 'package:wintest/shared/parameters.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';

// import 'package:wintest/shared/widget.dart';

// class AddTransaction extends StatefulWidget {
//   const AddTransaction({Key? key}) : super(key: key);

//   @override
//   State<AddTransaction> createState() => _AddTransactionState();
// }

// class _AddTransactionState extends State<AddTransaction> {
//   List<User> users = [];

//   Future<List<User>> _getUsers() async {
//     //sending a post request to the url
//     var params = {
//       'type': 'get_users',
//     };
//     var res = await http.post(Parameters.selectUrl, body: params);
//     //converting the fetched data from json to key value pair that can be displayed on the screen
//     final data = json.decode(res.body);

//     users.clear();
//     for (var element in data) {
//       users.add(User(
//         userId: int.parse(element['userId']),
//         name: element['name'],
//         phone: element['phone'],
//         joinDate: DateTime.parse(element['joinDate']),
//         type: element['type'],
//         capital: double.parse(element['capital']),
//         threshold: double.parse(element['threshold']),
//         founding: double.parse(element['founding']),
//         effort: double.parse(element['effort']),
//       ));
//     }

//     return users;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         Container(
//           alignment: Alignment.center,
//           padding: const EdgeInsets.all(5.0),
//           child: const Text(
//             'Ajouter Transaction',
//             style: TextStyle(
//               color: Colors.white,
//               fontSize: 20.0,
//             ),
//           ),
//           decoration: BoxDecoration(
//               color: Parameters().winTileColor,
//               borderRadius: const BorderRadius.only(
//                 topLeft: Radius.circular(20.0),
//                 topRight: Radius.circular(20.0),
//               )),
//         ),
//         Expanded(
//           child: Container(
//             decoration: BoxDecoration(
//                 color: Parameters().scaffoldColor,
//                 borderRadius: const BorderRadius.only(
//                   bottomLeft: Radius.circular(20.0),
//                   bottomRight: Radius.circular(20.0),
//                 )),
//             child: FutureBuilder(
//               future: _getUsers(),
//               builder: (context, snapshot) {
//                 if (snapshot.hasData) {
//                   return Container(
//                     child: TransactionForm(users: users),
//                     padding: const EdgeInsets.all(16.0),
//                   );
//                 } else if (snapshot.hasError) {
//                   return errorMessage();
//                 } else {
//                   return Center(
//                     child: CircularProgressIndicator(
//                         color: Parameters().winTileColor),
//                   );
//                 }
//               },
//             ),
//           ),
//         )
//       ],
//     );
//   }
// }

// class TransactionForm extends StatefulWidget {
//   final List<User> users;
//   const TransactionForm({Key? key, required this.users}) : super(key: key);

//   @override
//   State<TransactionForm> createState() => _TransactionFormState();
// }

// class _TransactionFormState extends State<TransactionForm> {
//   late User _user = widget.users[0];
//   String _trType = 'Entrie';
//   String _trSomme = '';
//   DateTime _trDate = DateTime.now();
//   String _trNote = '';
//   bool saving = false;
//   @override
//   Widget build(BuildContext context) {
//     final _formKey = GlobalKey<FormState>();

//     return Form(
//       key: _formKey,
//       child: Column(
//         children: [
//           const Spacer(),
//           Row(
//             children: [
//               const SizedBox(width: 100),
//               SizedBox(
//                 width: 150,
//                 child: ListTile(
//                   title: const Text('Entrie'),
//                   trailing: Radio<String>(
//                     value: 'Entrie',
//                     groupValue: _trType,
//                     onChanged: (value) {
//                       setState(() {
//                         _trType = value!;
//                       });
//                     },
//                   ),
//                 ),
//               ),
//               SizedBox(
//                 width: 150,
//                 child: ListTile(
//                   title: const Text('Sortie'),
//                   leading: Radio<String>(
//                     value: 'Sortie',
//                     groupValue: _trType,
//                     onChanged: (value) {
//                       setState(() {
//                         _trType = value!;
//                       });
//                     },
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 100),
//             ],
//           ),
//           const SizedBox(height: 8.0),
//           const Divider(),
//           const SizedBox(height: 8.0),
//           Row(
//             children: [
//               SizedBox(
//                 width: 142,
//                 child: TextFormField(
//                   initialValue: _user.userId.toString(),
//                   decoration: textInputDecoration('Code'),
//                   onFieldSubmitted: (value) {
//                     try {
//                       setState(() {
//                         _user = getUserById(widget.users, int.parse(value));
//                       });
//                     } catch (e) {
//                       setState(() {
//                         _user = widget.users[0];
//                       });
//                     }
//                   },
//                 ),
//               ),
//               const SizedBox(width: 8),
//               SizedBox(
//                 width: 350,
//                 child: DropdownButtonFormField(
//                   decoration: textInputDecoration('User Name'),
//                   value: _user,
//                   items: widget.users.map((item) {
//                     return DropdownMenuItem(
//                       value: item,
//                       child: Text(item.name),
//                     );
//                   }).toList(),
//                   onChanged: (value) {
//                     setState(() {
//                       _user = value as User;
//                     });
//                   },
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 12.0),
//           Row(
//             children: [
//               SizedBox(
//                 width: 300,
//                 child: TextFormField(
//                   initialValue: _trSomme,
//                   decoration: textInputDecoration('Somme'),
//                   onChanged: (value) => _trSomme = value,
//                   validator: (value) {
//                     try {
//                       if (value == null || value.isEmpty) {
//                         return 'required !!';
//                       }
//                       double.parse(value);
//                       return null;
//                     } catch (e) {
//                       return 'Numbers Only !!';
//                     }
//                   },
//                 ),
//               ),
//               const SizedBox(width: 8),
//               SizedBox(
//                 width: 140,
//                 child: TextFormField(
//                   readOnly: true,
//                   enabled: false,
//                   initialValue: dateFormat(_trDate),
//                   decoration: textInputDecoration('Date'),
//                 ),
//               ),
//               const SizedBox(width: 4),
//               IconButton(
//                 onPressed: () async {
//                   final DateTime? selected = await showDatePicker(
//                     context: context,
//                     initialDate: _trDate,
//                     firstDate: DateTime(Parameters.year),
//                     lastDate: DateTime.now().year == Parameters.year
//                         ? DateTime.now()
//                         : DateTime(Parameters.year, 12, 31, 23, 59, 59),
//                   );
//                   if (selected != null && selected != _trDate) {
//                     setState(() {
//                       _trDate = selected;
//                     });
//                   }
//                 },
//                 icon: Icon(
//                   Icons.calendar_month_outlined,
//                   color: Parameters().winTileColor,
//                 ),
//               )
//             ],
//           ),
//           const SizedBox(height: 12.0),
//           SizedBox(
//             width: 508,
//             child: TextFormField(
//               initialValue: _trNote,
//               decoration: textInputDecoration('Note'),
//               maxLines: 2,
//               keyboardType: TextInputType.multiline,
//               onChanged: (value) => _trNote = value,
//             ),
//           ),
//           const Spacer(flex: 2),
//           InkWell(
//             onTap: () async {
//               if (_formKey.currentState!.validate()) {
//                 setState(() {
//                   saving = true;
//                 });
//                 // sending a post request to the url
//                 var params = {
//                   'type': 'insert_trnsaction',
//                   'us_id': _user.userId.toString(),
//                   'tr_year': Parameters.year.toString(),
//                   'tr_type': _trType,
//                   'tr_somme': _trSomme,
//                   'tr_date': _trDate.toString(),
//                   'tr_note': _trNote == '' ? '/' : _trNote,
//                 };

//                 var res = await http.post(Parameters.insertUrl, body: params);
//                 //converting the fetched data from json to key value pair that can be displayed on the screen
//                 final data = json.decode(res.body);

//                 Navigator.of(context).pushReplacement(MaterialPageRoute(
//                     builder: (context) => const MyApp(index: 0)));
//                 snackBar(context, data);
//               }
//             },
//             child: Container(
//               padding: const EdgeInsets.all(8.0),
//               alignment: Alignment.center,
//               width: 200,
//               child: saving
//                   ? const CircularProgressIndicator(
//                       color: Colors.white,
//                     )
//                   : const Text(
//                       'Confermer',
//                       style: TextStyle(color: Colors.white, fontSize: 20),
//                     ),
//               decoration: BoxDecoration(
//                 color: Parameters().winTileColor,
//                 borderRadius: BorderRadius.circular(12),
//               ),
//             ),
//           ),
//           const Spacer(),
//         ],
//       ),
//     );
//   }
// }
