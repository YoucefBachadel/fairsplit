import 'package:fairsplit/shared/constants.dart';
import 'package:fairsplit/shared/lists.dart';
import 'package:flutter/material.dart';

class Passage extends StatefulWidget {
  const Passage({super.key});

  @override
  State<Passage> createState() => _PassageState();
}

class _PassageState extends State<Passage> {
  void loadData() async {}

  @override
  void initState() {
    loadData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: getHeight(context, .6),
      width: getWidth(context, .5),
      child: Column(children: [
        Container(
          alignment: Alignment.center,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  getText('passage'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20.0,
                  ),
                ),
              ),
              IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white,
                  ))
            ],
          ),
          decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20.0),
                topRight: Radius.circular(20.0),
              )),
        ),
        Expanded(child: Container()),
      ]),
    );
  }
}
