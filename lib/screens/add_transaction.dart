import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../classes/user.dart';
import '../shared/parameters.dart';
import '../shared/widget.dart';
import '../main.dart';
import '../shared/lists.dart';

class AddTransaction extends StatefulWidget {
  final int userId;
  final String sourceTab, selectedName, category;
  final double userCapital;

  const AddTransaction({
    Key? key,
    this.sourceTab = 'tr',
    this.userId = 0,
    this.selectedName = '',
    this.userCapital = 0,
    this.category = 'caisse',
  }) : super(key: key);

  @override
  State<AddTransaction> createState() => _AddTransactionState();
}

class _AddTransactionState extends State<AddTransaction> {
  late String selectedName = '', category = 'caisse', type = 'in', amount = '0', note = '';
  late double caisse, reserve, donation, zakat;
  DateTime date = DateTime.now();
  bool isLoading = false;
  bool isSpeacial = false; //flase for user transaction and true for speacial transaction

  List<User> users = [];
  User selectedUser = User();

  void loadData() async {
    var params = {'sql': 'SELECT * FROM Settings;'};
    var res = await http.post(selectUrl, body: params);
    var dataSettings = (json.decode(res.body))['data'][0];

    caisse = double.parse(dataSettings['caisse']);
    reserve = double.parse(dataSettings['reserve']);
    donation = double.parse(dataSettings['donation']);
    zakat = double.parse(dataSettings['zakat']);

    if (widget.sourceTab == 'tr') {
      params = {'sql': '''SELECT userId,name,capital FROM Users;'''};
      res = await http.post(selectUrl, body: params);
      var dataUsers = (json.decode(res.body))['data'];

      for (var element in dataUsers) {
        users.add(
            User(userId: int.parse(element['userId']), name: element['name'], capital: double.parse(element['capital'])));
      }
      users.sort(
        (a, b) => a.name.compareTo(b.name),
      );
    } else {
      isSpeacial = widget.sourceTab == 'da';
      selectedName = widget.selectedName;
      selectedUser = User(userId: widget.userId, name: selectedName, capital: widget.userCapital);
      category = widget.category;
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  void initState() {
    loadData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.sourceTab == 'tr' ? getHeight(context, .71) : getHeight(context, .62),
      width: getWidth(context, .39),
      child: Column(children: [
        Container(
          alignment: Alignment.center,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  getText('transaction'),
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
                      widget.sourceTab == 'tr'
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Text(
                                  getText('user'),
                                  style: !isSpeacial
                                      ? Theme.of(context).textTheme.headline4?.copyWith(color: winTileColor)
                                      : Theme.of(context).textTheme.headline6,
                                ),
                                Transform.scale(
                                  scale: 1.8,
                                  child: Switch(
                                    value: isSpeacial,
                                    onChanged: (value) => setState(
                                      () {
                                        isSpeacial = value;
                                      },
                                    ),
                                    thumbColor: MaterialStateProperty.all(Colors.white),
                                    trackColor: MaterialStateProperty.all(winTileColor),
                                    hoverColor: Colors.transparent,
                                  ),
                                ),
                                Text(
                                  getText('special'),
                                  style: isSpeacial
                                      ? Theme.of(context).textTheme.headline4?.copyWith(color: winTileColor)
                                      : Theme.of(context).textTheme.headline6,
                                ),
                              ],
                            )
                          : const SizedBox(),
                      widget.sourceTab == 'tr' ? const Divider() : const SizedBox(),
                      const SizedBox(height: 8.0),
                      isSpeacial
                          ? Row(
                              children: [
                                Expanded(child: myText(getText('category'))),
                                Expanded(
                                  flex: 4,
                                  child: Container(
                                      alignment: Alignment.centerLeft,
                                      child: myDropDown(
                                        context,
                                        value: category,
                                        width: getWidth(context, .13),
                                        items: compts.entries.map((item) {
                                          return DropdownMenuItem(
                                            value: getKeyFromValue(item.value),
                                            alignment: AlignmentDirectional.center,
                                            child: Text(item.value),
                                          );
                                        }).toList(),
                                        onChanged: widget.sourceTab == 'da'
                                            ? null
                                            : (value) => setState(() => category = value.toString()),
                                      )),
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                Expanded(child: myText(getText('name'))),
                                Expanded(
                                  flex: 4,
                                  child: Autocomplete<User>(
                                    displayStringForOption: (user) => user.name,
                                    onSelected: (user) => selectedName = user.name,
                                    optionsBuilder: (textEditingValue) => users.where(
                                      (user) => user.name.toLowerCase().contains(textEditingValue.text.toLowerCase()),
                                    ),
                                    fieldViewBuilder: (
                                      context,
                                      textEditingController,
                                      focusNode,
                                      onFieldSubmitted,
                                    ) {
                                      if (widget.selectedName.isNotEmpty) {
                                        textEditingController.text = selectedName;
                                      }
                                      return Container(
                                          alignment: Alignment.center,
                                          height: getHeight(context, textFeildHeight),
                                          decoration: const BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.all(Radius.circular(12)),
                                          ),
                                          child: TextFormField(
                                            controller: textEditingController,
                                            focusNode: focusNode,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(fontSize: 18.0),
                                            enabled: widget.sourceTab == 'tr',
                                            decoration: InputDecoration(
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 8.0),
                                              border: const OutlineInputBorder(
                                                borderSide: BorderSide(width: 0.5),
                                                borderRadius: BorderRadius.all(Radius.circular(12)),
                                              ),
                                              suffixIcon: widget.sourceTab != 'tr' || textEditingController.text.isEmpty
                                                  ? const SizedBox()
                                                  : IconButton(
                                                      onPressed: () => setState(() {
                                                            textEditingController.clear();
                                                            selectedName = '';
                                                          }),
                                                      icon: const Icon(
                                                        Icons.clear,
                                                        size: 20.0,
                                                      )),
                                            ),
                                          ));
                                    },
                                    optionsViewBuilder: (
                                      BuildContext context,
                                      AutocompleteOnSelected<User> onSelected,
                                      Iterable<User> options,
                                    ) {
                                      return Align(
                                        alignment: Alignment.topLeft,
                                        child: Material(
                                          elevation: 8.0,
                                          child: ConstrainedBox(
                                            constraints: BoxConstraints(
                                                maxHeight: getHeight(context, .2), maxWidth: getWidth(context, .29)),
                                            child: ListView.builder(
                                              padding: EdgeInsets.zero,
                                              shrinkWrap: true,
                                              itemCount: options.length,
                                              itemBuilder: (BuildContext context, int index) {
                                                final User option = options.elementAt(index);
                                                return InkWell(
                                                  onTap: () => onSelected(option),
                                                  child: Container(
                                                    padding: const EdgeInsets.all(16.0),
                                                    child: myText(option.name),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                      const SizedBox(height: 8.0),
                      Row(
                        children: [
                          Expanded(child: myText(getText('amount'))),
                          Expanded(
                              flex: 4,
                              child: myTextField(
                                context,
                                width: getWidth(context, .13),
                                isNumberOnly: true,
                                autoFocus: widget.sourceTab != 'tr',
                                onChanged: (value) => amount = value,
                              )),
                        ],
                      ),
                      const SizedBox(height: 8.0),
                      Row(
                        children: [
                          Expanded(child: myText(getText('type'))),
                          Expanded(
                            flex: 4,
                            child: Container(
                              alignment: Alignment.centerLeft,
                              child: myDropDown(
                                context,
                                value: type,
                                width: getWidth(context, .13),
                                items: transactionsTypes.entries.map((item) {
                                  return DropdownMenuItem(
                                    value: getKeyFromValue(item.value),
                                    alignment: AlignmentDirectional.center,
                                    child: Text(item.value),
                                  );
                                }).toList(),
                                onChanged: (value) => setState(() => type = value.toString()),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8.0),
                      Row(
                        children: [
                          Expanded(child: myText(getText('date'))),
                          Expanded(
                            flex: 4,
                            child: Row(
                              children: [
                                myTextField(
                                  context,
                                  hint: myDateFormate.format(date),
                                  width: getWidth(context, .10),
                                  enabled: false,
                                  onChanged: ((text) {}),
                                ),
                                const SizedBox(width: 5.0),
                                IconButton(
                                  icon: Icon(
                                    Icons.calendar_month,
                                    color: winTileColor,
                                  ),
                                  onPressed: () async {
                                    final DateTime? selected = await showDatePicker(
                                      context: context,
                                      initialDate: date,
                                      firstDate: DateTime(1900, 01, 01, 00, 00, 00),
                                      lastDate: DateTime.now(),
                                    );
                                    if (selected != null && selected != date) {
                                      setState(() => date = selected);
                                    }
                                  },
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8.0),
                      Row(children: [Expanded(child: myText(getText('note'))), const Expanded(flex: 4, child: SizedBox())]),
                      const Spacer(),
                      Container(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                          child: TextFormField(
                            onChanged: ((value) => note = value),
                            style: const TextStyle(fontSize: 22),
                            maxLength: 350,
                            minLines: 4,
                            maxLines: 4,
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.all(8),
                              border: OutlineInputBorder(
                                gapPadding: 0,
                                borderSide: BorderSide(width: 0.5),
                                borderRadius: BorderRadius.all(Radius.circular(12)),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      saveButton(),
                    ],
                  ),
          ),
        ),
      ]),
    );
  }

  Widget saveButton() {
    return myButton(
      context,
      onTap: () async {
        if (amount.isNotEmpty && amount != '0') {
          setState(() {
            isLoading = true;
          });
          double _amount = double.parse(amount);
          double _solde = 0;

          if (type == 'out') {
            _amount = _amount * -1;
          }

          switch (category) {
            case 'caisse':
              _solde = caisse + _amount;
              break;
            case 'reserve':
              _solde = reserve + _amount;
              break;
            case 'donation':
              _solde = donation + _amount;
              break;
            case 'zakat':
              _solde = zakat + _amount;
              break;
          }

          if (isSpeacial) {
            //insert the special transaction
            await http.post(
              insertUrl,
              body: {
                'sql':
                    '''INSERT INTO TransactionSP (year,category,date,type,amount,solde,note) VALUES ($currentYear , '$category' , '$date' , '$type' ,${_amount.abs()} , $_solde , '$note' );''',
              },
            );
            //update the setting category
            await http.post(
              insertUrl,
              body: {'sql': '''UPDATE Settings SET $category = $_solde WHERE 1;'''},
            );
          } else {
            bool nameWrite = false;
            //check if the name is write
            for (var user in users) {
              if (user.name == selectedName) {
                nameWrite = true;
                selectedUser = user;
                break;
              }
            }

            //test if name is not empty and name is write or users list is empty in case the user is selected from users tab
            if (selectedName.isNotEmpty && (users.isEmpty || nameWrite)) {
              double _soldeUser = selectedUser.capital + _amount;
              var params = {
                'sql':
                    '''INSERT INTO Transaction (userName,year,date,type,amount,soldeUser,soldeCaisse,note) VALUES ('${selectedUser.name}',$currentYear , '$date' , '$type' ,${_amount.abs()} ,$_soldeUser, $_solde , '$note' );''',
              };
              await http.post(
                insertUrl,
                body: params,
              );
              //update the User capital
              await http.post(
                insertUrl,
                body: {'sql': '''UPDATE Users SET capital = $_soldeUser WHERE userId = ${selectedUser.userId};'''},
              );
              //update the setting caisse
              await http.post(
                insertUrl,
                body: {'sql': '''UPDATE Settings SET caisse = $_solde WHERE 1;'''},
              );
            } else {
              snackBar(context, 'Check The Name');
            }
          }

          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => MyApp(index: widget.sourceTab),
            ),
          );
          snackBar(context, 'Transaction added successfully');
        } else {
          snackBar(context, 'Amount can not be zero!!!', duration: 5);
        }
      },
    );
  }
}
