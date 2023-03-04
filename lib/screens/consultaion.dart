import 'package:flutter/material.dart';

import '../screens/pdf_generator.dart';
import '../shared/parameters.dart';
import '../shared/widget.dart';

class Consultaion extends StatefulWidget {
  const Consultaion({Key? key}) : super(key: key);

  @override
  State<Consultaion> createState() => _ConsultaionState();
}

class _ConsultaionState extends State<Consultaion> {
  int seIndex = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        mini: true,
        onPressed: () {
          createDialog(
            context,
            SizedBox(
                width: getWidth(context, .52),
                child: const PdfGenerator(
                  import: {'source': 'test'},
                )),
            true,
          );
        },
        child: const Icon(Icons.add),
      ),
      body: Container(),
    );
  }
}
