import 'package:flutter/material.dart';

import '../models/unit.dart';
import '../main.dart';
import '../shared/functions.dart';
import '../shared/lists.dart';
import '../shared/constants.dart';
import '../shared/widgets.dart';

class AddUnit extends StatefulWidget {
  final Unit unit;
  const AddUnit({Key? key, required this.unit}) : super(key: key);

  @override
  State<AddUnit> createState() => _AddUnitState();
}

class _AddUnitState extends State<AddUnit> {
  late String name, capital, reserve, donation, money, effort, threshold, founding;
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
    snackBar(context, getMessage('deleteUnit'));

    setState(() => isLoading = false);
  }

  void save() async {
    if (name == '') {
      snackBar(context, getMessage('emptyName'), duration: 5);
    } else if (double.parse(capital) == 0) {
      snackBar(context, getMessage('capitalZero'));
    } else {
      setState(() => isLoading = true);

      try {
        int _unitId = widget.unit.unitId;
        String _type = isExtern ? 'extern' : 'intern';
        double _capital = double.parse(capital);
        double _reserve = double.parse(reserve);
        double _donation = double.parse(donation);
        double _money = double.parse(money);
        double _effort = double.parse(effort);
        double _threshold = double.parse(threshold);
        double _founding = double.parse(founding);

        // sending a post request to the url
        await sqlQuery(insertUrl, {
          'sql1': _unitId == -1
              ? '''INSERT INTO Units (name,type,capital,profit,reservePerc,donationPerc,thresholdPerc,foundingPerc,effortPerc,moneyPerc,currentMonthOrYear) VALUES ('$name' ,'$_type',$_capital,0, $_reserve , $_donation  ,$_threshold , $_founding , $_effort , $_money , ${_type == 'intern' ? 1 : currentYear});'''
              : '''UPDATE Units SET name = '$name' ,capital = $_capital ,type = '$_type',reservePerc = $_reserve ,donationPerc = $_donation ,thresholdPerc = $_threshold ,foundingPerc = $_founding ,effortPerc = $_effort ,moneyPerc = $_money Where unitId = $_unitId;''',
        });

        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MyApp(index: 'un')));
        snackBar(context, widget.unit.unitId == -1 ? getMessage('addUnit') : getMessage('updateUnit'));
      } catch (e) {
        snackBar(context, getMessage('checkData'), duration: 5);
      }

      setState(() => isLoading = false);
    }
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
    threshold = widget.unit.thresholdPerc.toString();
    founding = widget.unit.foundingPerc.toString();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: getHeight(context, .55),
      width: getWidth(context, .3),
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
                              delteConfirmation(
                                context,
                                getMessage('deleteUnitConfitmation'),
                                () => deleteUnit(widget.unit.unitId),
                                isLoading: isLoading,
                              ),
                            ),
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
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              decoration: BoxDecoration(
                  color: scaffoldColor,
                  borderRadius: const BorderRadius.only(
                    bottomRight: Radius.circular(20.0),
                    bottomLeft: Radius.circular(20.0),
                  )),
              child: isLoading
                  ? myProgress()
                  : SingleChildScrollView(
                      child: Column(
                        children: [
                          mySizedBox(context),
                          information(),
                          mySizedBox(context),
                          myButton(context, onTap: () => save()),
                          mySizedBox(context),
                        ],
                      ),
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
                onChanged: ((text) => name = text),
              ),
            ),
          ],
        ),
        mySizedBox(context),
        Row(
          children: [
            Expanded(child: myText(getText('capital'))),
            Expanded(
                flex: 4,
                child: myTextField(
                  context,
                  hint: myCurrency(double.parse(capital)),
                  width: getWidth(context, .22),
                  isNumberOnly: true,
                  onChanged: (value) => capital = value,
                )),
          ],
        ),
        mySizedBox(context),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text(
              getText('intern'),
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
                            threshold = '0';
                            founding = '0';
                          }
                        },
                      ),
                thumbColor: MaterialStateProperty.all(Colors.white),
                trackColor: MaterialStateProperty.all(primaryColor),
                hoverColor: Colors.transparent,
              ),
            ),
            Text(
              getText('extern'),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ],
        ),
        mySizedBox(context),
        const Divider(),
        mySizedBox(context),
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
        mySizedBox(context),
        const Divider(),
        mySizedBox(context),
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
        mySizedBox(context),
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
                enabled: !isExtern,
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
                enabled: !isExtern,
              ),
            ),
          ],
        ),
        mySizedBox(context),
        const Divider(),
      ],
    );
  }
}
