// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:http/http.dart' as http;
// import 'package:wintest/main.dart';
// import 'dart:convert';

// import 'package:wintest/shared/parameters.dart';
// import 'package:wintest/shared/widget.dart';

// class Years extends StatelessWidget {
//   Years({Key? key}) : super(key: key);

//   final List<int> loadedYears = [];

//   Future<List<int>> _getYears() async {
//     //sending a post request to the url
//     var params = {
//       'type': 'get_years',
//     };
//     var res = await http.post(Parameters.selectUrl, body: params);
//     //converting the fetched data from json to key value pair that can be displayed on the screen
//     final data = json.decode(res.body);

//     loadedYears.clear();
//     for (var element in data) {
//       loadedYears.add(int.parse(element['year']));
//     }

//     return loadedYears;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return FutureBuilder(
//       future: _getYears(),
//       builder: (context, snapshot) {
//         if (snapshot.hasData) {
//           return YearsHome(years: loadedYears);
//         } else if (snapshot.hasError) {
//           return errorMessage();
//         } else {
//           return Center(
//             child: CircularProgressIndicator(color: Parameters().winTileColor),
//           );
//         }
//       },
//     );
//   }
// }

// class YearsHome extends StatefulWidget {
//   final List<int> years;
//   const YearsHome({Key? key, required this.years}) : super(key: key);

//   @override
//   State<YearsHome> createState() => _YearsHomeState();
// }

// class _YearsHomeState extends State<YearsHome> {
//   var index = 0;
//   bool saving = false;

//   late FixedExtentScrollController scrollController;

//   @override
//   void initState() {
//     super.initState();

//     scrollController = FixedExtentScrollController(
//         initialItem: widget.years.indexOf(Parameters.year));
//     index = widget.years.indexOf(Parameters.year);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return RawKeyboardListener(
//       autofocus: true,
//       focusNode: FocusNode(),
//       onKey: (event) {
//         final key = event.logicalKey;
//         if (key == LogicalKeyboardKey.enter) {
//           Parameters.year = widget.years[index];
//           Navigator.of(context).pushReplacement(MaterialPageRoute(
//               builder: (context) => const MyApp(
//                     index: 0,
//                   )));
//         } else if (key == LogicalKeyboardKey.arrowUp) {
//           scrollController.jumpToItem(index--);
//         } else if (key == LogicalKeyboardKey.arrowDown) {
//           scrollController.jumpToItem(index++);
//         }
//       },
//       child: Padding(
//         padding: const EdgeInsets.all(8.0),
//         child: Column(
//           children: [
//             Expanded(
//               child: CupertinoPicker(
//                   scrollController: scrollController,
//                   itemExtent: 64,
//                   looping: true,
//                   onSelectedItemChanged: (index) {
//                     setState(() {
//                       this.index = index;
//                     });
//                   },
//                   selectionOverlay: CupertinoPickerDefaultSelectionOverlay(
//                     background: CupertinoColors.activeBlue.withOpacity(0.2),
//                   ),
//                   children: List.generate(widget.years.length, (index) {
//                     final isSelected = this.index == index;
//                     final item = widget.years[index];
//                     return Center(
//                       child: Text(
//                         item.toString(),
//                         style: TextStyle(
//                             fontSize: isSelected ? 48 : 32,
//                             color: isSelected
//                                 ? CupertinoColors.activeBlue
//                                 : CupertinoColors.black),
//                       ),
//                     );
//                   })),
//             ),
//             const SizedBox(height: 8.0),
//             InkWell(
//               onTap: () {},
//               child: Container(
//                 padding: const EdgeInsets.all(16.0),
//                 alignment: Alignment.center,
//                 width: 268,
//                 child: saving
//                     ? const CircularProgressIndicator(
//                         color: Colors.white,
//                       )
//                     : const Text(
//                         'New Year',
//                         style: TextStyle(color: Colors.white, fontSize: 20),
//                       ),
//                 decoration: BoxDecoration(
//                   color: Parameters().winTileColor,
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 16.0),
//           ],
//         ),
//       ),
//     );
//   }
// }
