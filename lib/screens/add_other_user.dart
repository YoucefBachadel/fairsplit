import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../classes/other_user.dart';
import '../main.dart';
import '../shared/lists.dart';
import '../shared/parameters.dart';
import '../shared/widget.dart';

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
    var sql = 'DELETE FROM OtherUsers WHERE userId = $userId';
    var res = await http.post(insertUrl, body: {'sql': sql});

    final data = json.decode(res.body);
    if (data['data'] == true) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const MyApp(index: 'ou')));
      snackBar(context, 'User deleted successfully');
    } else {
      snackBar(context, 'something went wrong!!');
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
      width: getWidth(context, .29),
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
                              delteConfirmation(context, 'Are you sure you want to delete this user!!',
                                  () => deleteUser(widget.user.userId)),
                              true,
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
                color: winTileColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20.0),
                  topRight: Radius.circular(20.0),
                )),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(8.0),
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Text(
                              getText('loan'),
                              style: !isDeposit
                                  ? Theme.of(context).textTheme.headline4?.copyWith(color: winTileColor)
                                  : Theme.of(context).textTheme.headline6,
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
                                trackColor: MaterialStateProperty.all(winTileColor),
                                hoverColor: Colors.transparent,
                              ),
                            ),
                            Text(
                              getText('deposit'),
                              style: isDeposit
                                  ? Theme.of(context).textTheme.headline4?.copyWith(color: winTileColor)
                                  : Theme.of(context).textTheme.headline6,
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
                                      color: winTileColor,
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
                        mySizedBox(context),
                        saveButton(),
                      ],
                    ),
            ),
          )
        ],
      ),
    );
  }

  Widget saveButton() {
    return myButton(context, onTap: () async {
      if (name != '') {
        String _type = isDeposit ? 'deposit' : 'loan';
        var params = {};
        if (widget.user.userId == -1) {
          params = {
            'sql':
                '''INSERT INTO OtherUsers (name,phone,joinDate,type,amount,rest) VALUES ('$name' ,'$phone','$joinDate', '$_type', 0 , 0);''',
          };
        } else {
          params = {
            'sql':
                '''UPDATE OtherUsers SET name = '$name' ,phone = '$phone' ,joinDate = '$joinDate' ,type = '$_type' WHERE userID = ${widget.user.userId};''',
          };
        }

        // sending a post request to the url
        var res = await http.post(
          insertUrl,
          body: params,
        );

        //converting the fetched data from json to key value pair that can be displayed on the screen
        final data = json.decode(res.body);

        if (data['data'] == true) {
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const MyApp(index: 'ou')));
          snackBar(context, widget.user.userId == -1 ? 'User added successfully' : 'User updated successfully');
        } else {
          snackBar(context, 'something went wrong!!');
        }
      } else {
        snackBar(context, 'Name can not be empty!!!', duration: 5);
      }
    });
  }
}
