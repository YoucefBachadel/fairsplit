import 'package:flutter/material.dart';

import '../classes/other_user.dart';
import '../screens/add_other_user.dart';
import '../shared/lists.dart';
import '../shared/widget.dart';

class OtherUsers extends StatefulWidget {
  const OtherUsers({Key? key}) : super(key: key);

  @override
  State<OtherUsers> createState() => _OtherUsersState();
}

void _newUser(BuildContext context, OtherUser user) async =>
    await createDialog(context, AddOtherUser(user: user), false);

class _OtherUsersState extends State<OtherUsers> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        mini: true,
        onPressed: () => _newUser(context, OtherUser()),
        tooltip: getText('newUser'),
        child: const Icon(Icons.add),
      ),
      body: Container(),
    );
  }
}
