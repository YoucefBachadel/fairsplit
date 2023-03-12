import 'package:fairsplit/models/other_user.dart';
import 'package:flutter/material.dart';

import '../models/user.dart';
import '../shared/parameters.dart';
import '../widgets/widget.dart';
import '../main.dart';
import '../shared/lists.dart';

class AddTransaction extends StatefulWidget {
  final int userId;
  final String sourceTab, selectedName, category;
  final String type; // used for loan and deposit transaction
  final double userCapital; // used for users transaction
  final double amount, rest; // used for loan and deposit transaction
  final int selectedTransactionType; //0: specials  1:users 2:loans 3:deposits
  const AddTransaction({
    Key? key,
    this.sourceTab = 'tr',
    this.userId = 0,
    this.selectedName = '',
    this.category = 'caisse',
    this.type = '',
    this.userCapital = 0,
    this.amount = 0,
    this.rest = 0,
    this.selectedTransactionType = 0,
  }) : super(key: key);

  @override
  State<AddTransaction> createState() => _AddTransactionState();
}

class _AddTransactionState extends State<AddTransaction> {
  late String selectedName = '', category = 'caisse', type = 'in', amount = '0', note = '';
  late double caisse, reserve, donation, zakat, rest = 0;
  DateTime date = DateTime.now();
  bool isLoading = false;
  bool isTransactionTypeSelected = true;
  int selectedTransactionType = 0;

  List<User> users = [];
  List<OtherUser> loanUsers = [], depositUsers = [];
  User selectedUser = User();
  OtherUser selectedOtherUser = OtherUser();

  void loadData() async {
    var res = await sqlQuery(selectUrl, {'sql1': 'SELECT * FROM Settings;'});
    var dataSettings = res[0][0];

    caisse = double.parse(dataSettings['caisse']);
    reserve = double.parse(dataSettings['reserve']);
    donation = double.parse(dataSettings['donation']);
    zakat = double.parse(dataSettings['zakat']);

    if (widget.sourceTab == 'tr') {
      var res = await sqlQuery(selectUrl, {
        'sql1': '''SELECT userId,name,capital FROM Users;''',
        'sql2': '''SELECT userId,name,type,amount,rest FROM OtherUsers;''',
      });
      var dataUsers = res[0];
      var dataOtherUsers = res[1];

      for (var element in dataUsers) {
        users.add(User(
            userId: int.parse(element['userId']), name: element['name'], capital: double.parse(element['capital'])));
      }

      for (var element in dataOtherUsers) {
        OtherUser user = OtherUser(
          userId: int.parse(element['userId']),
          name: element['name'],
          type: element['type'],
          amount: double.parse(element['amount']),
          rest: double.parse(element['rest']),
        );
        user.type == 'loan' ? loanUsers.add(user) : depositUsers.add(user);
      }

      users.sort((a, b) => a.name.compareTo(b.name));
      loanUsers.sort((a, b) => a.name.compareTo(b.name));
      depositUsers.sort((a, b) => a.name.compareTo(b.name));
    } else {
      selectedName = widget.selectedName;
      selectedTransactionType = widget.selectedTransactionType;
      if (selectedTransactionType == 3) type = 'out'; //for deposit set default transaction type to sortie
      rest = widget.rest;
      if (widget.sourceTab == 'us') {
        selectedUser = User(userId: widget.userId, name: selectedName, capital: widget.userCapital);
      } else {
        selectedOtherUser = OtherUser(
          userId: widget.userId,
          name: selectedName,
          type: widget.type,
          amount: widget.amount,
          rest: widget.rest,
        );
      }
      category = widget.category;
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  void initState() {
    if (widget.sourceTab == 'tr') isTransactionTypeSelected = false;
    loadData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: getHeight(context, .62),
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
            width: double.infinity,
            decoration: BoxDecoration(
                color: scaffoldColor,
                borderRadius: const BorderRadius.only(
                  bottomRight: Radius.circular(20.0),
                  bottomLeft: Radius.circular(20.0),
                )),
            child: isLoading
                ? myPogress()
                : !isTransactionTypeSelected
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: selectTransactionType
                            .map((e) => Column(
                                  children: [
                                    Card(
                                      elevation: 5.0,
                                      child: myButton(
                                        context,
                                        text: e,
                                        width: getWidth(context, .15),
                                        noIcon: true,
                                        color: Colors.white,
                                        textColor: Colors.black,
                                        onTap: () => setState(() {
                                          isTransactionTypeSelected = true;
                                          selectedTransactionType = selectTransactionType.indexOf(e);
                                          if (selectedTransactionType == 3) type = 'out';
                                        }),
                                      ),
                                    ),
                                    mySizedBox(context),
                                  ],
                                ))
                            .toList(),
                      )
                    : Column(
                        children: [
                          if (selectedTransactionType == 0) // special transactio
                            Row(
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
                          else if (selectedTransactionType == 1) // users transaction
                            Row(
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
                                              maxHeight: getHeight(context, .2),
                                              maxWidth: getWidth(context, .29),
                                            ),
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
                            )
                          else // loan and deposit transaction
                            Row(
                              children: [
                                Expanded(child: myText(getText('name'))),
                                Expanded(
                                  flex: 4,
                                  child: Autocomplete<OtherUser>(
                                    displayStringForOption: (user) => user.name,
                                    onSelected: (user) => setState(() {
                                      selectedName = user.name;
                                      rest = user.rest;
                                    }),
                                    optionsBuilder: (textEditingValue) {
                                      if (selectedTransactionType == 2) {
                                        return loanUsers.where((user) =>
                                            user.name.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                                      } else {
                                        return depositUsers.where((user) =>
                                            user.name.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                                      }
                                    },
                                    fieldViewBuilder: (
                                      context,
                                      textEditingController,
                                      focusNode,
                                      onFieldSubmitted,
                                    ) {
                                      if (widget.selectedName.isNotEmpty) textEditingController.text = selectedName;

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
                                      AutocompleteOnSelected<OtherUser> onSelected,
                                      Iterable<OtherUser> options,
                                    ) {
                                      return Align(
                                        alignment: Alignment.topLeft,
                                        child: Material(
                                          elevation: 8.0,
                                          child: ConstrainedBox(
                                            constraints: BoxConstraints(
                                              maxHeight: getHeight(context, .2),
                                              maxWidth: getWidth(context, .29),
                                            ),
                                            child: ListView.builder(
                                              padding: EdgeInsets.zero,
                                              shrinkWrap: true,
                                              itemCount: options.length,
                                              itemBuilder: (BuildContext context, int index) {
                                                final OtherUser option = options.elementAt(index);
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
                          mySizedBox(context),
                          Row(
                            children: [
                              Expanded(child: myText(getText('amount'))),
                              Expanded(
                                  flex: 4,
                                  child: Row(
                                    children: [
                                      myTextField(
                                        context,
                                        width: getWidth(context, .13),
                                        isNumberOnly: true,
                                        autoFocus: widget.sourceTab != 'tr',
                                        onChanged: (value) => amount = value,
                                      ),
                                      mySizedBox(context),
                                      (selectedTransactionType == 2 || selectedTransactionType == 3)
                                          ? myText('${getText('rest')} :   ${myCurrency.format(rest)}')
                                          : const SizedBox()
                                    ],
                                  )),
                            ],
                          ),
                          mySizedBox(context),
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
                          mySizedBox(context),
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
                                    mySizedBox(context),
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
                          mySizedBox(context),
                          Row(children: [
                            Expanded(child: myText(getText('note'))),
                            const Expanded(flex: 4, child: SizedBox())
                          ]),
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
                          mySizedBox(context),
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
          bool _testsChecked = true; //used to test if rest is >= 0 and prevent navigation to main screen
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

          if (selectedTransactionType == 0) {
            //insert the special transaction
            //update the setting category
            sqlQuery(insertUrl, {
              'sql1':
                  '''INSERT INTO TransactionSP (year,category,date,type,amount,solde,note) VALUES ($currentYear , '$category' , '$date' , '$type' ,${_amount.abs()} , $_solde , '$note' );''',
              'sql2': '''UPDATE Settings SET $category = $_solde WHERE 1;'''
            });
          } else {
            bool nameWrite = false;
            //check if the name is write
            if (selectedTransactionType == 1) {
              for (var user in users) {
                if (user.name == selectedName) {
                  nameWrite = true;
                  selectedUser = user;
                  break;
                }
              }
            } else if (selectedTransactionType == 2) {
              for (var user in loanUsers) {
                if (user.name == selectedName) {
                  nameWrite = true;
                  selectedOtherUser = user;
                  break;
                }
              }
            } else {
              for (var user in depositUsers) {
                if (user.name == selectedName) {
                  nameWrite = true;
                  selectedOtherUser = user;
                  break;
                }
              }
            }

            if (selectedTransactionType == 1) {
              //test if name is not empty and name is write or users list is empty in case the user is selected from users tab
              if (selectedName.isNotEmpty && (users.isEmpty || nameWrite)) {
                double _soldeUser = selectedUser.capital + _amount;

                //insert the transaction
                //update the User capital
                //update the setting caisse
                sqlQuery(insertUrl, {
                  'sql1':
                      '''INSERT INTO Transaction (userName,year,date,type,amount,soldeUser,soldeCaisse,note) VALUES ('${selectedUser.name}',$currentYear , '$date' , '$type' ,${_amount.abs()} ,$_soldeUser, $_solde , '$note' );''',
                  'sql2': '''UPDATE Users SET capital = $_soldeUser WHERE userId = ${selectedUser.userId};''',
                  'sql3': '''UPDATE Settings SET caisse = $_solde WHERE 1;'''
                });
              } else {
                snackBar(context, 'Check The Name');
              }
            } else if (selectedTransactionType == 2) {
              if (selectedName.isNotEmpty && (loanUsers.isEmpty || nameWrite)) {
                double _userAmount = selectedOtherUser.amount;
                if (type == 'out') {
                  _userAmount -= _amount;
                }
                double _userRest = selectedOtherUser.rest - _amount;

                if (_userRest >= 0) {
                  //insert the transaction
                  //update the User capital
                  //update the setting caisse
                  sqlQuery(insertUrl, {
                    'sql1':
                        '''INSERT INTO TransactionOthers (userName,category,year,date,type,amount,soldeCaisse,note) VALUES ('${selectedOtherUser.name}', 'loan', $currentYear , '$date' , '$type' ,${_amount.abs()} , $_solde , '$note' );''',
                    'sql2':
                        '''UPDATE OtherUsers SET amount = $_userAmount, rest = $_userRest WHERE userId = ${selectedOtherUser.userId};''',
                    'sql3': '''UPDATE Settings SET caisse = $_solde WHERE 1;'''
                  });
                } else {
                  setState(() {
                    _testsChecked = false;
                    isLoading = false;
                  });
                  snackBar(context, 'Rest must be >= 0');
                }
              } else {
                snackBar(context, 'Check The Name');
              }
            } else {
              if (selectedName.isNotEmpty && (depositUsers.isEmpty || nameWrite)) {
                double _userAmount = selectedOtherUser.amount;
                if (type == 'in') {
                  _userAmount += _amount;
                }
                double _userRest = selectedOtherUser.rest + _amount;

                if (_userRest >= 0) {
                  //insert the transaction
                  //update the User capital
                  //update the setting caisse
                  sqlQuery(insertUrl, {
                    'sql1':
                        '''INSERT INTO TransactionOthers (userName,category,year,date,type,amount,soldeCaisse,note) VALUES ('${selectedOtherUser.name}','deposit',$currentYear , '$date' , '$type' ,${_amount.abs()} , $_solde , '$note' );''',
                    'sql2':
                        '''UPDATE OtherUsers SET amount = $_userAmount, rest = $_userRest WHERE userId = ${selectedOtherUser.userId};''',
                    'sql3': '''UPDATE Settings SET caisse = $_solde WHERE 1;''',
                  });
                } else {
                  setState(() {
                    _testsChecked = false;
                    isLoading = false;
                  });
                  snackBar(context, 'Rest must be >= 0');
                }
              } else {
                snackBar(context, 'Check The Name');
              }
            }
          }
          if (_testsChecked) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => MyApp(index: widget.sourceTab)),
            );
            snackBar(context, 'Transaction added successfully');
          }
        } else {
          snackBar(context, 'Amount can not be zero!!!', duration: 5);
        }
      },
    );
  }
}
