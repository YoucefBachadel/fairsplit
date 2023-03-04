// import 'package:flutter/material.dart';

// class NavBarItem extends StatefulWidget {
//   final String element;
//   final Function onTap;
//   final bool selected;

//   const NavBarItem({
//     Key? key,
//     required this.element,
//     required this.onTap,
//     required this.selected,
//   }) : super(key: key);
//   @override
//   _NavBarItemState createState() => _NavBarItemState();
// }

// class _NavBarItemState extends State<NavBarItem> with TickerProviderStateMixin {
//   bool hovered = false;

//   @override
//   Widget build(BuildContext context) {
//     return InkWell(
//       onTap: () {
//         widget.onTap();
//       },
//       child: MouseRegion(
//         onEnter: (value) {
//           setState(() {
//             hovered = true;
//           });
//         },
//         onExit: (value) {
//           setState(() {
//             hovered = false;
//           });
//         },
//         child: Container(
//             decoration: BoxDecoration(
//               color: hovered && !widget.selected
//                   ? Colors.white12
//                   : Colors.transparent,
//               borderRadius: const BorderRadius.only(
//                 topLeft: Radius.circular(8),
//                 topRight: Radius.circular(8),
//               ),
//             ),
//             child: Container(
//               alignment: Alignment.center,
//               height: 36,
//               padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
//               decoration: widget.selected
//                   ? const BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.only(
//                         topLeft: Radius.circular(8),
//                         topRight: Radius.circular(8),
//                       ),
//                     )
//                   : const BoxDecoration(
//                       color: Colors.transparent,
//                     ),
//               child: Text(
//                 widget.element,
//                 style: TextStyle(
//                   color:
//                       widget.selected ? const Color(0XFF1976d2) : Colors.white,
//                   fontWeight:
//                       widget.selected ? FontWeight.bold : FontWeight.normal,
//                   fontSize: widget.selected ? 16.0 : 12.0,
//                 ),
//               ),
//             )),
//       ),
//     );
//   }
// }
