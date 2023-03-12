import 'package:flutter/material.dart';

import '../models/unit.dart';
import '../main.dart';
import '../shared/lists.dart';
import '../shared/parameters.dart';
import '../widgets/widget.dart';

class AddUnit extends StatefulWidget {
  final Unit unit;
  const AddUnit({Key? key, required this.unit}) : super(key: key);

  @override
  State<AddUnit> createState() => _AddUnitState();
}

class _AddUnitState extends State<AddUnit> {
  late String name, capital, reserve, donation, money, effort, thresholdFounding, threshold, founding;
  late bool isExtern;
  bool isLoading = false;

  void deleteUnit(int unitId) async {
    sqlQuery(insertUrl, {
      'sql1': 'DELETE FROM Threshold WHERE unitId = $unitId',
      'sql2': 'DELETE FROM Founding WHERE unitId = $unitId',
      'sql3': 'DELETE FROM Effort WHERE unitId = $unitId',
      'sql4': 'DELETE FROM Units WHERE unitId = $unitId',
    });

    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const MyApp(index: 'un')));
    snackBar(context, 'Unit deleted successfully');
  }

  @override
  void initState() {
    name = widget.unit.name;
    isExtern = widget.unit.type == 'extern';
    capital = widget.unit.capital.toString();
    reserve = widget.unit.reservePerc.toString();
    donation = widget.unit.donationPerc.toString();
    money = widget.unit.moneyPerc.toString();
    effort = widget.unit.effortPerc.toString();
    thresholdFounding = widget.unit.thresholdFoundingPerc.toString();
    threshold = widget.unit.thresholdPerc.toString();
    founding = widget.unit.foundingPerc.toString();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: getHeight(context, .69),
      width: getWidth(context, .29),
      child: Column(
        children: [
          Container(
            alignment: Alignment.center,
            child: Row(
              children: [
                widget.unit.unitId != -1
                    ? IconButton(
                        onPressed: () => createDialog(
                            context,
                            delteConfirmation(context,
                                'Are you sure you want to delete this unit, once deleted all related information will be deleted as well',
                                () {
                              deleteUnit(widget.unit.unitId);
                            }),
                            true),
                        icon: const Icon(
                          Icons.delete_forever,
                          color: Colors.white,
                        ))
                    : const SizedBox(),
                Expanded(
                  child: Text(
                    widget.unit.unitId == -1 ? getText('unit') : name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20.0,
                    ),
                  ),
                ),
                IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                    ))
              ],
            ),
            decoration: BoxDecoration(
                color: winTileColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20.0),
                  topRight: Radius.circular(20.0),
                )),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                  color: scaffoldColor,
                  borderRadius: const BorderRadius.only(
                    bottomRight: Radius.circular(20.0),
                    bottomLeft: Radius.circular(20.0),
                  )),
              child: isLoading
                  ? myPogress()
                  : Column(
                      children: [
                        information(),
                        const SizedBox(height: 16.0),
                        saveButton(),
                      ],
                    ),
            ),
          )
        ],
      ),
    );
  }

  Widget information() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: myText(getText('name'))),
            Expanded(
              flex: 4,
              child: myTextField(
                context,
                hint: name,
                width: getWidth(context, .22),
                onChanged: ((text) {
                  name = text;
                }),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8.0),
        Row(
          children: [
            Expanded(child: myText(getText('capital'))),
            Expanded(
                flex: 4,
                child: myTextField(
                  context,
                  hint: myCurrency.format(double.parse(capital)),
                  width: getWidth(context, .22),
                  isNumberOnly: true,
                  onChanged: (value) => capital = value,
                )),
          ],
        ),
        const SizedBox(height: 8.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text(
              getText('intern'),
              style: Theme.of(context).textTheme.headline5,
            ),
            Transform.scale(
              scale: 1.8,
              child: Switch(
                value: isExtern,
                onChanged: (value) => setState(
                  () {
                    isExtern = value;
                  },
                ),
                thumbColor: MaterialStateProperty.all(Colors.white),
                trackColor: MaterialStateProperty.all(winTileColor),
                hoverColor: Colors.transparent,
              ),
            ),
            Text(
              getText('extern'),
              style: Theme.of(context).textTheme.headline5,
            ),
          ],
        ),
        const SizedBox(height: 8.0),
        const Divider(),
        const SizedBox(height: 8.0),
        Row(
          children: [
            Expanded(child: myText('${getText('reserve')} %')),
            Expanded(
              child: myTextField(
                context,
                hint: reserve,
                onChanged: ((text) {
                  reserve = text;
                }),
                isNumberOnly: true,
              ),
            ),
            Expanded(child: myText('${getText('donation')} %')),
            Expanded(
              child: myTextField(
                context,
                hint: donation,
                onChanged: ((text) {
                  donation = text;
                }),
                isNumberOnly: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8.0),
        const Divider(),
        const SizedBox(height: 8.0),
        Row(
          children: [
            Expanded(child: myText('${getText('money')} %')),
            Expanded(
              child: myTextField(
                context,
                hint: money,
                onChanged: ((text) {
                  money = text;
                }),
                isNumberOnly: true,
              ),
            ),
            Expanded(child: myText('${getText('effort')} %')),
            Expanded(
              child: myTextField(
                context,
                hint: effort,
                onChanged: ((text) {
                  effort = text;
                }),
                isNumberOnly: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16.0),
        Row(
          children: [
            Expanded(child: myText('${getText('thresholdFounding')} %')),
            Expanded(
              child: myTextField(
                context,
                hint: thresholdFounding,
                onChanged: ((text) {
                  thresholdFounding = text;
                }),
                isNumberOnly: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8.0),
        const Divider(),
        const SizedBox(height: 8.0),
        Row(
          children: [
            Expanded(child: myText('${getText('threshold')} %')),
            Expanded(
              child: myTextField(
                context,
                hint: threshold,
                onChanged: ((text) {
                  threshold = text;
                }),
                isNumberOnly: true,
              ),
            ),
            Expanded(child: myText('${getText('founding')} %')),
            Expanded(
              child: myTextField(
                context,
                hint: founding,
                onChanged: ((text) {
                  founding = text;
                }),
                isNumberOnly: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget saveButton() {
    return myButton(context, onTap: () async {
      if (name != '') {
        try {
          int _unitId = widget.unit.unitId;
          String _type = isExtern ? 'extern' : 'intern';
          double _capital = double.parse(capital);
          double _reserve = double.parse(reserve);
          double _donation = double.parse(donation);
          double _money = double.parse(money);
          double _effort = double.parse(effort);
          double _thresholdFounding = double.parse(thresholdFounding);
          double _threshold = double.parse(threshold);
          double _founding = double.parse(founding);

          // sending a post request to the url
          sqlQuery(insertUrl, {
            'sql1': _unitId == -1
                ? '''INSERT INTO Units (name,type,capital,reservePerc,donationPerc,thresholdFoundingPerc,thresholdPerc,foundingPerc,effortPerc,moneyPerc,calculated) VALUES ('$name' ,'$_type',$_capital, $_reserve , $_donation , $_thresholdFounding ,$_threshold , $_founding , $_effort , $_money , 0);'''
                : '''UPDATE Units SET name = '$name' ,capital = $_capital ,type = '$_type',reservePerc = $_reserve ,donationPerc = $_donation ,thresholdFoundingPerc = $_thresholdFounding ,thresholdPerc = $_threshold ,foundingPerc = $_founding ,effortPerc = $_effort ,moneyPerc = $_money Where unitId = $_unitId;''',
          });

          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const MyApp(index: 'un')));
          snackBar(context, widget.unit.unitId == -1 ? 'Unit added successfully' : 'Unit updated successfully');
        } catch (e) {
          snackBar(context, 'Check Your Data!!!', duration: 5);
        }
      } else {
        snackBar(context, 'Name can not be empty!!!', duration: 5);
      }
    });
  }
}
