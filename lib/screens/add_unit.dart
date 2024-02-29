import 'package:flutter/material.dart';

import '../models/unit.dart';
import '../main.dart';
import '../shared/functions.dart';
import '../shared/constants.dart';
import '../shared/widgets.dart';

class AddUnit extends StatefulWidget {
  final Unit unit;
  const AddUnit({Key? key, required this.unit}) : super(key: key);

  @override
  State<AddUnit> createState() => _AddUnitState();
}

class _AddUnitState extends State<AddUnit> {
  late String name;
  late double capital, reserve, donation, money, effort, threshold, founding;
  late bool isExtern;
  bool isLoading = false;

  void deleteUnit(int unitId) async {
    setState(() => isLoading = true);
    Navigator.pop(context);
    await sqlQuery(insertUrl, {
      'sql1': 'DELETE FROM Threshold WHERE unitId = $unitId',
      'sql2': 'DELETE FROM Founding WHERE unitId = $unitId',
      'sql3': 'DELETE FROM Effort WHERE unitId = $unitId',
      'sql4': 'DELETE FROM Units WHERE unitId = $unitId',
    });

    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MyApp(index: 'un')));
    snackBar(context, 'Unit deleted successfully');

    setState(() => isLoading = false);
  }

  void save() async {
    if (name == '') {
      snackBar(context, 'Name can not be empty!!!', duration: 5);
    } else if (capital == 0) {
      snackBar(context, 'Capital must be >= 0');
    } else {
      setState(() => isLoading = true);

      try {
        int _unitId = widget.unit.unitId;
        String _type = isExtern ? 'extern' : 'intern';

        // sending a post request to the url
        await sqlQuery(insertUrl, {
          'sql1': _unitId == -1
              ? '''INSERT INTO Units (name,type,capital,profit,reservePerc,donationPerc,thresholdPerc,foundingPerc,effortPerc,moneyPerc,currentMonthOrYear) VALUES ('$name' ,'$_type',$capital,0, $reserve , $donation  ,$threshold , $founding , $effort , $money , ${_type == 'intern' ? 1 : currentYear});'''
              : '''UPDATE Units SET name = '$name' ,capital = $capital ,type = '$_type',reservePerc = $reserve ,donationPerc = $donation ,thresholdPerc = $threshold ,foundingPerc = $founding ,effortPerc = $effort ,moneyPerc = $money Where unitId = $_unitId;''',
        });

        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MyApp(index: 'un')));
        snackBar(context, widget.unit.unitId == -1 ? 'Unit added successfully' : 'Unit updated successfully');
      } catch (e) {
        snackBar(context, 'Check your data!!!', duration: 5);
      }

      setState(() => isLoading = false);
    }
  }

  @override
  void initState() {
    name = widget.unit.name;
    isExtern = widget.unit.type == 'extern';
    capital = widget.unit.capital;
    reserve = widget.unit.reservePerc;
    donation = widget.unit.donationPerc;
    money = widget.unit.moneyPerc;
    effort = widget.unit.effortPerc;
    threshold = widget.unit.thresholdPerc;
    founding = widget.unit.foundingPerc;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: getWidth(context, .3),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            alignment: Alignment.center,
            child: Row(
              children: [
                widget.unit.unitId != -1
                    ? myIconButton(
                        onPressed: () => createDialog(
                              context,
                              deleteConfirmation(
                                context,
                                'Are you sure you want to delete this unit, once deleted all related information will be deleted too',
                                () => deleteUnit(widget.unit.unitId),
                                isLoading: isLoading,
                              ),
                            ),
                        icon: Icons.delete_forever)
                    : const SizedBox(),
                Expanded(
                  child: Text(
                    widget.unit.unitId == -1 ? 'Unit' : name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20.0,
                    ),
                  ),
                ),
                myIconButton(onPressed: () => Navigator.pop(context), icon: Icons.close)
              ],
            ),
            decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20.0),
                  topRight: Radius.circular(20.0),
                )),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            decoration: BoxDecoration(
                color: scaffoldColor,
                borderRadius: const BorderRadius.only(
                  bottomRight: Radius.circular(20.0),
                  bottomLeft: Radius.circular(20.0),
                )),
            child: isLoading
                ? SizedBox(height: getHeight(context, .4), child: myProgress())
                : Center(
                    child: Column(
                      children: [
                        mySizedBox(context),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Text(
                              'Intern',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            Transform.scale(
                              scale: 1.8,
                              child: Switch(
                                value: isExtern,
                                onChanged: (value) => widget.unit.unitId != -1
                                    ? null
                                    : setState(
                                        () {
                                          isExtern = value;
                                          if (isExtern) {
                                            threshold = 0;
                                            founding = 0;
                                          }
                                        },
                                      ),
                                thumbColor: MaterialStateProperty.all(Colors.white),
                                trackColor: MaterialStateProperty.all(primaryColor),
                                hoverColor: Colors.transparent,
                              ),
                            ),
                            Text(
                              'Extern',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                          ],
                        ),
                        mySizedBox(context),
                        const Divider(),
                        mySizedBox(context),
                        Row(
                          children: [
                            Expanded(child: myText('Name')),
                            Expanded(
                              flex: 4,
                              child: myTextField(
                                context,
                                hint: name,
                                width: getWidth(context, .22),
                                onChanged: ((text) => name = text),
                              ),
                            ),
                          ],
                        ),
                        mySizedBox(context),
                        Row(
                          children: [
                            Expanded(child: myText('Capital')),
                            Expanded(
                                flex: 4,
                                child: myTextField(
                                  context,
                                  hint: myCurrency(capital),
                                  width: getWidth(context, .22),
                                  isNumberOnly: true,
                                  onChanged: (value) => capital = double.parse(value),
                                )),
                          ],
                        ),
                        mySizedBox(context),
                        const Divider(),
                        mySizedBox(context),
                        Row(
                          children: [
                            Expanded(child: myText('Reserve %')),
                            Expanded(
                              child: myTextField(
                                context,
                                hint: myPercentage(reserve),
                                onChanged: ((text) => reserve = double.parse(text)),
                                isNumberOnly: true,
                              ),
                            ),
                            Expanded(child: myText('Donation %')),
                            Expanded(
                              child: myTextField(
                                context,
                                hint: myPercentage(donation),
                                onChanged: ((text) => donation = double.parse(text)),
                                isNumberOnly: true,
                              ),
                            ),
                          ],
                        ),
                        mySizedBox(context),
                        Row(
                          children: [
                            Expanded(child: myText('Money %')),
                            Expanded(
                              child: myTextField(
                                context,
                                hint: myPercentage(money),
                                onChanged: ((text) => money = double.parse(text)),
                                isNumberOnly: true,
                              ),
                            ),
                            Expanded(child: myText('Effort %')),
                            Expanded(
                              child: myTextField(
                                context,
                                hint: myPercentage(effort),
                                onChanged: ((text) => effort = double.parse(text)),
                                isNumberOnly: true,
                              ),
                            ),
                          ],
                        ),
                        mySizedBox(context),
                        Row(
                          children: [
                            Expanded(child: myText('Threshold %')),
                            Expanded(
                              child: myTextField(
                                context,
                                hint: myPercentage(threshold),
                                onChanged: ((text) => threshold = double.parse(text)),
                                isNumberOnly: true,
                                enabled: !isExtern,
                              ),
                            ),
                            Expanded(child: myText('Founding %')),
                            Expanded(
                              child: myTextField(
                                context,
                                hint: myPercentage(founding),
                                onChanged: ((text) => founding = double.parse(text)),
                                isNumberOnly: true,
                                enabled: !isExtern,
                              ),
                            ),
                          ],
                        ),
                        mySizedBox(context),
                        const Divider(),
                      ],
                    ),
                  ),
          ),
          mySizedBox(context),
          if (!isLoading) myButton(context, onTap: () => save()),
          mySizedBox(context),
        ],
      ),
    );
  }
}
