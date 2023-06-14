import 'package:flutter/material.dart';

import '../models/other_user.dart';
import '../main.dart';
import '../shared/lists.dart';
import '../shared/parameters.dart';
import '../widgets/widget.dart';

class AddOtherUser extends StatefulWidget {
  final OtherUser user;
  const AddOtherUser({Key? key, required this.user}) : super(key: key);

  @override
  State<AddOtherUser> createState() => _AddOtherUserState();
}

class _AddOtherUserState extends State<AddOtherUser> {
  late String name, phone;
  late DateTime joinDate;
  bool isLoading = false, isDeposit = false;
  // String password = '';

  void deleteUser(int userId) async {
    setState(() => isLoading = true);
    Navigator.pop(context);
    // var res = await sqlQuery(selectUrl, {
    //   'sql1': '''SELECT IF(admin = '$password',1,0) AS password FROM settings;''',
    // });

    // if (res[0][0]['password'] == '1') {
    await sqlQuery(insertUrl, {'sql1': 'DELETE FROM OtherUsers WHERE userId = $userId'});

    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MyApp(index: 'ou')));
    snackBar(context, getMessage('deleteUser'));
    // } else {
    //   snackBar(context, getMessage('wrongPassword'), duration: 1);
    // }

    setState(() => isLoading = false);
  }

  void save() async {
    if (name == '') {
      snackBar(context, getMessage('emptyName'), duration: 5);
    } else {
      setState(() => isLoading = true);

      // var res = await sqlQuery(selectUrl, {
      //   'sql1': '''SELECT IF(admin = '$password',1,0) AS password FROM settings;''',
      // });

      // if (res[0][0]['password'] == '1') {
      bool isNew = widget.user.userId == -1;
      String _type = isDeposit ? 'deposit' : 'loan';

      //chack if the nae exist befor
      bool nameExist = false;
      if (isNew || name != widget.user.name) {
        var res = await sqlQuery(selectUrl,
            {'sql1': '''SELECT COUNT(*) AS count FROM otherusers WHERE name = '$name' AND type = '$_type';'''});
        nameExist = res[0][0]['count'] != '0';
      }

      if (nameExist) {
        setState(() => isLoading = false);
        snackBar(context, getMessage('existName'));
      } else {
        await sqlQuery(insertUrl, {
          'sql1': isNew
              ? '''INSERT INTO OtherUsers (name,phone,joinDate,type,amount,rest) VALUES ('$name' ,'$phone','$joinDate', '$_type', 0 , 0);'''
              : '''UPDATE OtherUsers SET name = '$name' ,phone = '$phone' ,joinDate = '$joinDate' ,type = '$_type' WHERE userID = ${widget.user.userId};'''
        });

        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MyApp(index: 'ou')));
        snackBar(context, widget.user.userId == -1 ? getMessage('addUser') : getMessage('updateUser'));
      }
      // } else {
      //   snackBar(context, getMessage('wrongPassword'), duration: 1);
      // }

      setState(() => isLoading = false);
    }
  }

  @override
  void initState() {
    name = widget.user.name;
    isDeposit = widget.user.type == 'deposit';
    phone = widget.user.phone;
    joinDate = widget.user.joinDate;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: getHeight(context, .40),
      width: getWidth(context, .3),
      child: Column(
        children: [
          Container(
            alignment: Alignment.center,
            child: Row(
              children: [
                widget.user.userId != -1 && widget.user.rest == 0
                    ? IconButton(
                        onPressed: () => createDialog(
                              context,
                              delteConfirmation(
                                context,
                                getMessage('deleteOtherUserConfirmation'),
                                () => deleteUser(widget.user.userId),
                                // onChanged: (text) => password = text,
                              ),
                            ),
                        icon: const Icon(
                          Icons.delete_forever,
                          color: Colors.white,
                        ))
                    : const SizedBox(),
                Expanded(
                  child: Text(
                    widget.user.userId == -1 ? getText('otherUser') : name,
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
                color: primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20.0),
                  topRight: Radius.circular(20.0),
                )),
          ),
          Expanded(
            child: isLoading
                ? myProgress()
                : Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                        color: scaffoldColor,
                        borderRadius: const BorderRadius.only(
                          bottomRight: Radius.circular(20.0),
                          bottomLeft: Radius.circular(20.0),
                        )),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Text(
                              getText('loan'),
                              style: !isDeposit
                                  ? Theme.of(context).textTheme.headlineMedium?.copyWith(color: primaryColor)
                                  : Theme.of(context).textTheme.headlineSmall,
                            ),
                            Transform.scale(
                              scale: 1.8,
                              child: Switch(
                                value: isDeposit,
                                onChanged: (value) => widget.user.userId != -1
                                    ? null
                                    : setState(
                                        () {
                                          isDeposit = value;
                                        },
                                      ),
                                thumbColor: MaterialStateProperty.all(Colors.white),
                                trackColor: MaterialStateProperty.all(primaryColor),
                                hoverColor: Colors.transparent,
                              ),
                            ),
                            Text(
                              getText('deposit'),
                              style: isDeposit
                                  ? Theme.of(context).textTheme.headlineMedium?.copyWith(color: primaryColor)
                                  : Theme.of(context).textTheme.headlineSmall,
                            ),
                          ],
                        ),
                        const Divider(),
                        Row(
                          children: [
                            Expanded(child: myText(getText('name'))),
                            Expanded(
                              flex: 4,
                              child: myTextField(
                                context,
                                hint: name,
                                width: getWidth(context, .33),
                                onChanged: ((text) => name = text),
                              ),
                            ),
                          ],
                        ),
                        mySizedBox(context),
                        Row(
                          children: [
                            Expanded(child: myText(getText('joinDate'))),
                            Expanded(
                              flex: 4,
                              child: Row(
                                children: [
                                  myTextField(
                                    context,
                                    hint: myDateFormate.format(joinDate),
                                    width: getWidth(context, .1),
                                    enabled: false,
                                    onChanged: ((text) {}),
                                  ),
                                  mySizedBox(context),
                                  IconButton(
                                    icon: Icon(
                                      Icons.calendar_month,
                                      color: primaryColor,
                                    ),
                                    onPressed: () async {
                                      final DateTime? selected = await showDatePicker(
                                        context: context,
                                        initialDate: joinDate,
                                        firstDate: DateTime(1900, 01, 01, 00, 00, 00),
                                        lastDate: DateTime.now(),
                                      );
                                      if (selected != null && selected != joinDate) {
                                        setState(() {
                                          joinDate = selected;
                                        });
                                      }
                                    },
                                  )
                                ],
                              ),
                            ),
                          ],
                        ),
                        mySizedBox(context),
                        Row(
                          children: [
                            Expanded(child: myText(getText('phone'))),
                            Expanded(
                              flex: 4,
                              child: myTextField(
                                context,
                                hint: phone,
                                width: getWidth(context, .13),
                                onChanged: ((text) {
                                  phone = text;
                                }),
                                isNumberOnly: true,
                              ),
                            ),
                          ],
                        ),
                        // mySizedBox(context),
                        // Row(
                        //   children: [
                        //     Expanded(child: myText(getText('password'))),
                        //     Expanded(
                        //         flex: 4,
                        //         child: Row(
                        //           children: [
                        //             myTextField(
                        //               context,
                        //               width: getWidth(context, .13),
                        //               onChanged: (text) => password = text,
                        //               isPassword: true,
                        //             ),
                        //           ],
                        //         )),
                        //   ],
                        // ),
                        const Spacer(),
                        myButton(context, onTap: () => save()),
                        const Spacer(),
                      ],
                    ),
                  ),
          )
        ],
      ),
    );
  }
}
