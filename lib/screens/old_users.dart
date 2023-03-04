// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:wintest/screens/add_user.dart';
// import 'package:wintest/screens/pdf_generator.dart';

// import '../classes/user.dart';
// import '../shared/parameters.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';

// import '../shared/widget.dart';

// class Users extends StatefulWidget {
//   const Users({Key? key}) : super(key: key);

//   @override
//   State<Users> createState() => _UsersState();
// }

// class _UsersState extends State<Users> {
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

//   void _newUser(BuildContext context, User user) async {
//     await createDialog(
//       context,
//       AddUser(
//         user: user,
//       ),
//       false,
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Parameters().scaffoldColor,
//       floatingActionButton: FloatingActionButton(
//         onPressed: () => _newUser(context, User()),
//         child: const Icon(Icons.add),
//       ),
//       body: Row(
//         children: [
//           const Spacer(),
//           FutureBuilder(
//             future: _getUsers(),
//             builder: (context, snapshot) {
//               if (snapshot.hasData) {
//                 return Container(
//                   child: UsersHome(allUsers: users),
//                   padding: const EdgeInsets.all(16.0),
//                   decoration: const BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.only(
//                         bottomLeft: Radius.circular(20.0),
//                         bottomRight: Radius.circular(20.0),
//                       )),
//                 );
//               } else if (snapshot.hasError) {
//                 return errorMessage();
//               } else {
//                 return Center(
//                   child: CircularProgressIndicator(
//                       color: Parameters().winTileColor),
//                 );
//               }
//             },
//           ),
//           const Spacer(),
//         ],
//       ),
//     );
//   }
// }

// class UsersHome extends StatefulWidget {
//   final List<User> allUsers;
//   const UsersHome({Key? key, required this.allUsers}) : super(key: key);

//   @override
//   State<UsersHome> createState() => _UsersHomeState();
// }

// class _UsersHomeState extends State<UsersHome> {
//   List<User> users = [];
//   String _search = '';
//   int? sortColumnIndex = 0;
//   bool isAscending = true;

//   final TextEditingController _controller = TextEditingController();

//   void filterUsers() async {
//     users.clear();
//     for (var element in widget.allUsers) {
//       if ((element.userId.toString().contains(_search) ||
//           element.name
//               .toString()
//               .toLowerCase()
//               .contains(_search.toLowerCase()))) {
//         users.add(element);
//       }
//     }

//     onSort();
//   }

//   void onSort() {
//     switch (sortColumnIndex) {
//       case 0:
//         users.sort((tr1, tr2) {
//           return !isAscending
//               ? tr2.userId.compareTo(tr1.userId)
//               : tr1.userId.compareTo(tr2.userId);
//         });
//         break;
//     }
//   }

//   void clearSearch() {
//     setState(() {
//       _search = '';
//       _controller.clear();
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     filterUsers();
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
//         padding: const EdgeInsets.fromLTRB(25, 8, 25, 8),
//         color: Colors.white,
//         child: IntrinsicWidth(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               filteringRow(),
//               Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 8.0),
//                 child: const Divider(),
//               ),
//               Expanded(
//                 child: users.isEmpty
//                     ? emptyList()
//                     : SingleChildScrollView(
//                         child: dataTable(
//                           isAscending: isAscending,
//                           sortColumnIndex: sortColumnIndex,
//                           columns: [
//                             sortableDataColumn('Code'),
//                             dataColumn('Name'),
//                           ],
//                           rows: users
//                               .map(
//                                 (user) => DataRow(
//                                   onSelectChanged: (value) {
//                                     createDialog(
//                                         context,
//                                         SizedBox(
//                                             width: 350,
//                                             height: 400,
//                                             child: AddUser(
//                                               user: User(),
//                                             )),
//                                         true);
//                                   },
//                                   cells: [
//                                     dataCell(user.userId.toString(),
//                                         Alignment.centerRight),
//                                     dataCell(
//                                       user.name,
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
//         IconButton(
//             onPressed: () => clearSearch(),
//             icon: Icon(
//               Icons.update,
//               color: Parameters().winTileColor,
//             )),
//         const SizedBox(width: 8.0),
//         IconButton(
//             onPressed: () => createDialog(
//                   context,
//                   SizedBox(
//                       width: 800,
//                       child: PdfGenerator(
//                         import: {
//                           'source': 'user',
//                           'data': [for (var ele in users) ele.toMap()],
//                         },
//                       )),
//                   true,
//                 ),
//             icon: Icon(
//               Icons.print,
//               color: Parameters().winTileColor,
//             )),
//       ],
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

//   DataColumn dataColumn(String title) {
//     return DataColumn(
//       label: Text(
//         title,
//         style: const TextStyle(
//           color: Colors.black,
//           fontWeight: FontWeight.w700,
//         ),
//       ),
//     );
//   }

//   DataColumn sortableDataColumn(String title) {
//     return DataColumn(
//       label: Text(
//         title,
//         style: const TextStyle(
//           color: Colors.black,
//           fontWeight: FontWeight.w700,
//         ),
//       ),
//       onSort: (int columnIndex, bool ascending) {
//         setState(() {
//           sortColumnIndex = columnIndex;
//           isAscending = ascending;
//         });
//       },
//     );
//   }

//   DataCell dataCell(String text, Alignment alignment) {
//     return DataCell(
//       Container(
//         alignment: alignment,
//         child: Text(text),
//       ),
//     );
//   }
// }
