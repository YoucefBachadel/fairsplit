import 'package:flutter/material.dart';

import '../models/other_user.dart';
import '../shared/functions.dart';
import '../shared/constants.dart';
import '../shared/widgets.dart';

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

  void deleteUser(int userId) async {
    setState(() => isLoading = true);
    Navigator.pop(context);
    await sqlQuery(insertUrl, {'sql1': 'DELETE FROM OtherUsers WHERE userId = $userId'});

    Navigator.pop(context, true);
    snackBar(context, 'User deleted successfully');

    setState(() => isLoading = false);
  }

  void save() async {
    if (name == '') {
      snackBar(context, 'Name can not be empty!!!', duration: 5);
    } else {
      setState(() => isLoading = true);

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
        snackBar(context, 'Name already exist!!!');
      } else {
        await sqlQuery(insertUrl, {
          'sql1': isNew
              ? '''INSERT INTO OtherUsers (name,phone,joinDate,type,rest) VALUES ('$name' ,'$phone','$joinDate', '$_type', 0);'''
              : '''UPDATE OtherUsers SET name = '$name' ,phone = '$phone' ,joinDate = '$joinDate' ,type = '$_type' WHERE userID = ${widget.user.userId};'''
        });

        userNames.add(name);

        Navigator.pop(context, true);
        snackBar(context, widget.user.userId == -1 ? 'User added successfully' : 'User updated successfully');
      }

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
      width: getWidth(context, .3),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            alignment: Alignment.center,
            child: Row(
              children: [
                widget.user.userId != -1 && widget.user.rest == 0
                    ? myIconButton(
                        onPressed: () => createDialog(
                          context,
                          deleteConfirmation(
                            context,
                            'Are you sure you want to delete this user!!',
                            () => deleteUser(widget.user.userId),
                          ),
                        ),
                        icon: Icons.delete_forever,
                      )
                    : const SizedBox(),
                Expanded(
                  child: Text(
                    widget.user.userId == -1 ? 'Other User' : name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20.0,
                    ),
                  ),
                ),
                myIconButton(onPressed: () => Navigator.pop(context, false), icon: Icons.close)
              ],
            ),
            decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20.0),
                  topRight: Radius.circular(20.0),
                )),
          ),
          isLoading
              ? SizedBox(height: getHeight(context, .3), child: myProgress())
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
                      mySizedBox(context),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Text(
                            'Loan',
                            style: Theme.of(context).textTheme.headlineSmall,
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
                            'Deposit',
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
                              width: getWidth(context, .33),
                              onChanged: (text) => name = text,
                            ),
                          ),
                        ],
                      ),
                      mySizedBox(context),
                      Row(
                        children: [
                          Expanded(child: myText('Join Date')),
                          Expanded(
                            flex: 4,
                            child: Row(
                              children: [
                                Container(
                                    height: getHeight(context, textFeildHeight),
                                    width: getWidth(context, .10),
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border.all(color: Colors.black),
                                      borderRadius: const BorderRadius.all(Radius.circular(12)),
                                    ),
                                    child: myText(myDateFormate.format(joinDate))),
                                mySizedBox(context),
                                myIconButton(
                                  icon: Icons.calendar_month,
                                  color: primaryColor,
                                  onPressed: () async {
                                    final DateTime? selected = await showDatePicker(
                                      context: context,
                                      initialDate: joinDate,
                                      initialEntryMode: DatePickerEntryMode.input,
                                      firstDate: DateTime(1900, 01, 01, 00, 00, 00),
                                      lastDate: DateTime.now(),
                                    );
                                    if (selected != null && selected != joinDate) {
                                      setState(() => joinDate = selected);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      mySizedBox(context),
                      Row(
                        children: [
                          Expanded(child: myText('Phone')),
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
                      mySizedBox(context),
                      const Divider(),
                    ],
                  ),
                ),
          if (!isLoading) myButton(context, onTap: () => save()),
          mySizedBox(context),
        ],
      ),
    );
  }
}
