import 'package:fairsplit/models/other_user.dart';
import 'package:fairsplit/screens/print_transaction.dart';
import 'package:flutter/material.dart';
import 'package:toggle_switch/toggle_switch.dart';

import '../models/user.dart';
import '../shared/functions.dart';
import '../shared/constants.dart';
import '../shared/widgets.dart';
import '../main.dart';
import '../shared/lists.dart';

class SelectTransactionCategoty extends StatelessWidget {
  const SelectTransactionCategoty({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: getHeight(context, .58),
      width: getWidth(context, .39),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
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
        const Spacer(),
        ...selectTransactionType
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
                        onTap: () async {
                          Navigator.pop(context);
                          await createDialog(
                            context,
                            AddTransaction(
                              sourceTab: 'tr',
                              selectedTransactionType: selectTransactionType.indexOf(e),
                            ),
                            dismissable: false,
                          );
                        },
                      ),
                    ),
                    mySizedBox(context),
                  ],
                ))
            .toList(),
        const Spacer(),
      ]),
    );
  }
}

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
  late String selectedName = '', category = 'caisse', type = 'out', amount = '0', note = '', appBarTitle = '';
  late double caisse,
      reserve,
      reserveProfit,
      donation,
      zakat,
      rest = 0,
      selectedUserCapital = 0; //used to show user capital
  DateTime date = DateTime.now();
  bool isLoading = true;
  int selectedTransactionType = 0;
  String _password = ''; // used for all users Transaction;
  int reference = 0;
  bool isNewYear = false; //true after 1 jan befor passage so user and reserve transaction will be stored in tempTransac

  List<User> users = [];
  List<OtherUser> loanUsers = [], depositUsers = [];
  User selectedUser = User();
  OtherUser selectedOtherUser = OtherUser();
  TextEditingController controller = TextEditingController();

  String amountOnLetter = '';
  String intermediates = '';
  String printingNotes = '';
  String reciver = '';
  double soldeForPrint = 0;
  List<String> recivers = [];

  void loadRecivers() async {
    for (var item in (await sqlQuery(reciversUrl, {}))['data']) {
      recivers.add(item.toString());
    }
  }

  void loadData() async {
    var params = {};
    int counter = 1;
    params['sql$counter'] = 'SELECT * FROM Settings;';
    if ((['tr', 'da'].contains(widget.sourceTab)) && ([1, 4].contains(selectedTransactionType))) {
      counter++;
      params['sql$counter'] = '''SELECT userId,name,capital FROM Users;''';
    }
    if (['tr', 'da'].contains(widget.sourceTab) && ([2, 3].contains(selectedTransactionType))) {
      counter++;
      params['sql$counter'] = '''SELECT userId,name,type,amount,rest FROM OtherUsers;''';
    }
    var res = await sqlQuery(selectUrl, params);

    var dataSettings = res[0][0];
    caisse = double.parse(dataSettings['caisse']);
    reserve = double.parse(dataSettings['reserve']);
    reserveProfit = double.parse(dataSettings['reserveProfit']);
    donation = double.parse(dataSettings['donation']);
    zakat = double.parse(dataSettings['zakat']);

    if (widget.sourceTab == 'da' && selectedTransactionType == 0) {
      //if source tab is dashboard and type is special
      category = widget.category;
    } else if (!['da', 'tr'].contains(widget.sourceTab)) {
      //else if source tab is not dashboard or transaction
      selectedName = widget.selectedName;
      rest = widget.rest;
      if (widget.sourceTab == 'us') {
        selectedUser = User(userId: widget.userId, name: selectedName, capital: widget.userCapital);
        selectedUserCapital = widget.userCapital;
      } else {
        selectedOtherUser = OtherUser(
          userId: widget.userId,
          name: selectedName,
          type: widget.type,
          amount: widget.amount,
          rest: widget.rest,
        );
      }
    } else if (selectedTransactionType != 0) {
      // else if source tab is dashboard or transaction and type is not special
      var dataUsers = res[1];

      if ([1, 4].contains(selectedTransactionType)) {
        for (var element in dataUsers) {
          users.add(User(
              userId: int.parse(element['userId']), name: element['name'], capital: double.parse(element['capital'])));
        }
        users.sort((a, b) => a.realName.compareTo(b.realName));
      } else {
        for (var element in dataUsers) {
          OtherUser user = OtherUser(
            userId: int.parse(element['userId']),
            name: element['name'],
            type: element['type'],
            amount: double.parse(element['amount']),
            rest: double.parse(element['rest']),
          );
          user.type == 'loan' ? loanUsers.add(user) : depositUsers.add(user);
        }
        loanUsers.sort((a, b) => a.realName.compareTo(b.realName));
        depositUsers.sort((a, b) => a.realName.compareTo(b.realName));
      }
    }

    loadRecivers();

    setState(() => isLoading = false);
  }

  void save() async {
    bool _testsChecked = true; //used to test if rest is >= 0 and prevent navigation to main screen
    isNewYear = date.year != currentYear;
    double _amount = double.parse(amount);
    double _soldeCaisse = caisse;

    if (type == 'out') _amount = _amount * -1;
    if (selectedTransactionType != 4) _soldeCaisse += _amount;

    if (_soldeCaisse < 0) {
      _testsChecked = false;
      snackBar(context, getMessage('soldeCaisseZero'));
    } else {
      //get the current reference
      var res = await sqlQuery(selectUrl, {'sql1': 'SELECT reference FROM Settings'});
      reference = int.parse(res[0][0]['reference']);

      if (selectedTransactionType == 0) {
        //special trnasaction
        double _solde = 0;

        switch (category) {
          case 'caisse':
            _solde = caisse + _amount;
            break;
          case 'reserve':
            _solde = reserve + _amount;
            break;
          case 'reserveProfit':
            _solde = reserveProfit + _amount;
            break;
          case 'donation':
            _solde = donation + _amount;
            break;
          case 'zakat':
            _solde = zakat + _amount;
            break;
        }
        if (_solde < 0) {
          _testsChecked = false;
          snackBar(context, getMessage('soldeZero'));
        } else {
          soldeForPrint = ((category == 'reserve' || category == 'reserveProfit') && isNewYear) ? -0.01 : _solde;
          //insert the special transaction
          //update the setting category
          //update the setting caisse
          await sqlQuery(insertUrl, {
            'sql1': ((category == 'reserve' || category == 'reserveProfit') && isNewYear)
                ? '''INSERT INTO transactiontemp(reference,userId,userName,date,type,amount,soldeCaisse,note,amountOnLetter,intermediates,printingNotes,reciver) VALUES ('${date.year % 100}/${reference.toString().padLeft(4, '0')}' , -1 ,'$category' , '$date' , '$type' ,${_amount.abs()} ,$_soldeCaisse , '$note','$amountOnLetter','$intermediates','$printingNotes','$reciver');'''
                : '''INSERT INTO transactionsp (reference,category,date,type,amount,solde,soldeCaisse,note,amountOnLetter,intermediates,printingNotes,reciver) VALUES ('${date.year % 100}/${reference.toString().padLeft(4, '0')}' , '$category' , '$date' , '$type' ,${_amount.abs()} , $_solde ,$_soldeCaisse , '$note','$amountOnLetter','$intermediates','$printingNotes','$reciver');''',
            'sql2':
                '''UPDATE settings SET $category = $_solde , caisse = $_soldeCaisse , reference = ${reference + 1};''',
          });
        }
      } else if (selectedTransactionType == 4) {
        //all Users transaction

        List<User> moneyUsers = [];
        double _totalUsersCapital = 0, _userAmount = 0, _soldeUser = 0;
        String usersSQL = 'INSERT INTO users(userId, capital) VALUES ';
        String transactionsSQL =
            'INSERT INTO ${isNewYear ? 'transactiontemp' : 'transaction'} (reference,userId,userName,date,type,amount,${isNewYear ? '' : ' soldeUser,'}soldeCaisse,note,amountOnLetter,intermediates,printingNotes,reciver) VALUES ';

        //get money users
        for (var user in users) {
          if (['money', 'both'].contains(user.type) && user.capital != 0) {
            moneyUsers.add(user);
            _totalUsersCapital += user.capital;
          }
        }

        if (type == 'out' && _amount.abs() > _totalUsersCapital) {
          _testsChecked = false;
          snackBar(context, getMessage('amountTotalUserCapital'));
        } else {
          //calculate the amount for each user
          for (var user in moneyUsers) {
            _userAmount = (user.capital * 100 / _totalUsersCapital) * _amount / 100;

            _soldeUser = user.capital + _userAmount;

            usersSQL += '(${user.userId}, $_soldeUser),';
            transactionsSQL +=
                '''('${date.year % 100}/${reference.toString().padLeft(4, '0')}' , ${user.userId} , '${user.name}' , '$date' , '$type' ,${_userAmount.abs()} , ${isNewYear ? '' : '$_soldeUser,'} $_soldeCaisse , '$note' , '${numberToArabicWords(_userAmount.abs())}' , '$intermediates' , '$printingNotes' , '$reciver' ),''';
            reference++;
          }

          usersSQL = usersSQL.substring(0, usersSQL.length - 1);
          usersSQL += ' ON DUPLICATE KEY UPDATE capital = VALUES(capital);';
          transactionsSQL = transactionsSQL.substring(0, transactionsSQL.length - 1);
          transactionsSQL += ';';

          //insert the transactions
          //update the Users capitals
          //update the setting caisse
          await sqlQuery(insertUrl, {
            'sql1': transactionsSQL,
            'sql2': usersSQL,
            'sql3': '''UPDATE settings SET reference = $reference;''',
          });
        }
      } else {
        //other type of transaction that must check the name first
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
          //user transaction
          //test if name is not empty and name is write or users list is empty in case the user is selected from users tab
          if (selectedName.isNotEmpty && (users.isEmpty || nameWrite)) {
            double _soldeUser = selectedUser.capital + _amount;

            if (_soldeUser < 0 && !isNewYear) {
              _testsChecked = false;
              snackBar(context, getMessage('capitalZero'));
            } else {
              soldeForPrint = isNewYear ? -0.01 : _soldeUser;
              //insert the transaction
              //update the User capital
              //update the setting caisse
              await sqlQuery(insertUrl, {
                'sql1':
                    '''INSERT INTO ${isNewYear ? 'transactiontemp' : 'transaction'} (reference,userId,userName,date,type,amount,${isNewYear ? '' : 'soldeUser,'}soldeCaisse,note,amountOnLetter,intermediates,printingNotes,reciver) VALUES ('${date.year % 100}/${reference.toString().padLeft(4, '0')}' , ${selectedUser.userId},'${selectedUser.name}', '$date' , '$type' ,${_amount.abs()} ,${isNewYear ? '' : '$_soldeUser,'} $_soldeCaisse , '$note' , '$amountOnLetter','$intermediates','$printingNotes','$reciver');''',
                'sql2': '''UPDATE users SET capital = $_soldeUser WHERE userId = ${selectedUser.userId};''',
                'sql3': '''UPDATE settings SET caisse = $_soldeCaisse , reference = ${reference + 1};'''
              });
            }
          } else {
            _testsChecked = false;
            snackBar(context, getMessage('checkName'));
          }
        } else if (selectedTransactionType == 2) {
          //loan transaction
          if (selectedName.isNotEmpty && (loanUsers.isEmpty || nameWrite)) {
            double _userAmount = selectedOtherUser.amount;
            if (type == 'out') _userAmount -= _amount;

            double _userRest = selectedOtherUser.rest - _amount;

            if (_userRest < 0) {
              _testsChecked = false;
              snackBar(context, getMessage('restZero'));
            } else {
              soldeForPrint = _userRest;
              //insert the transaction
              //update the User capital
              //update the setting caisse
              await sqlQuery(insertUrl, {
                'sql1':
                    '''INSERT INTO transactionothers (reference,userName,category,date,type,amount,soldeUser,soldeCaisse,note,amountOnLetter,intermediates,printingNotes,reciver) VALUES ('${date.year % 100}/${reference.toString().padLeft(4, '0')}' , '${selectedOtherUser.name}', 'loan' , '$date' , '$type' ,${_amount.abs()} ,$_userRest, $_soldeCaisse , '$note' ,'$amountOnLetter','$intermediates','$printingNotes','$reciver');''',
                'sql2':
                    '''UPDATE otherusers SET amount = $_userAmount, rest = $_userRest WHERE userId = ${selectedOtherUser.userId};''',
                'sql3': '''UPDATE settings SET caisse = $_soldeCaisse , reference = ${reference + 1};'''
              });
            }
          } else {
            _testsChecked = false;
            snackBar(context, getMessage('checkName'));
          }
        } else if (selectedTransactionType == 3) {
          //deposit transaction
          if (selectedName.isNotEmpty && (depositUsers.isEmpty || nameWrite)) {
            double _userAmount = selectedOtherUser.amount;
            if (type == 'in') {
              _userAmount += _amount;
            }
            double _userRest = selectedOtherUser.rest + _amount;

            if (_userRest < 0) {
              _testsChecked = false;
              snackBar(context, getMessage('restZero'));
            } else {
              soldeForPrint = _userRest;
              //insert the transaction
              //update the User capital
              //update the setting caisse
              await sqlQuery(insertUrl, {
                'sql1':
                    '''INSERT INTO transactionothers (reference,userName,category,date,type,amount,soldeUser,soldeCaisse,note,amountOnLetter,intermediates,printingNotes,reciver) VALUES ('${date.year % 100}/${reference.toString().padLeft(4, '0')}' , '${selectedOtherUser.name}','deposit' , '$date' , '$type' ,${_amount.abs()} ,$_userRest, $_soldeCaisse , '$note' ,'$amountOnLetter','$intermediates','$printingNotes','$reciver');''',
                'sql2':
                    '''UPDATE otherusers SET amount = $_userAmount, rest = $_userRest WHERE userId = ${selectedOtherUser.userId};''',
                'sql3': '''UPDATE settings SET caisse = $_soldeCaisse , reference = ${reference + 1};''',
              });
            }
          } else {
            _testsChecked = false;
            snackBar(context, getMessage('checkName'));
          }
        }
      }
    }
    if (_testsChecked) {
      done(_amount.abs());
    } else {
      setState(() => isLoading = false);
    }
  }

  void done(double amount) async {
    if (selectedTransactionType != 4) {
      await createDialog(
        context,
        dismissable: isAdmin,
        PrintTransaction(
          source: (selectedTransactionType == 0)
              ? 'special'
              : (selectedTransactionType == 1)
                  ? 'user'
                  : (selectedTransactionType == 2)
                      ? 'loan'
                      : 'deposit',
          user: (selectedTransactionType == 0)
              ? getText(category)
              : (selectedTransactionType == 1)
                  ? selectedUser.realName
                  : selectedOtherUser.realName,
          solde: soldeForPrint,
          type: type,
          reference: '${date.year % 100}/${(reference).toString().padLeft(4, '0')}',
          amount: amount,
          date: myDateFormate.format(date),
          amountOnLetter: amountOnLetter,
          intermediates: intermediates,
          printingNotes: printingNotes,
          reciver: reciver,
        ),
      );
    }
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MyApp(index: widget.sourceTab)));
    snackBar(context, getMessage('addTransaction'));
  }

  @override
  void initState() {
    selectedTransactionType = widget.selectedTransactionType;
    appBarTitle = selectedTransactionType == 0
        ? getText('special')
        : selectedTransactionType == 1
            ? getText('user')
            : selectedTransactionType == 2
                ? getText('loan')
                : selectedTransactionType == 3
                    ? getText('deposit')
                    : getText('allUsers');
    loadData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: getHeight(context, .6),
      width: getWidth(context, .7),
      child: Column(
        children: [
          Container(
            alignment: Alignment.center,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    appBarTitle,
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
          mySizedBox(context),
          Expanded(
            child: isLoading
                ? myProgress()
                : Center(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          children: [
                            Flexible(child: transactionInfo()),
                            mySizedBox(context),
                            SizedBox(height: getHeight(context, .40), child: const VerticalDivider(thickness: 2)),
                            mySizedBox(context),
                            Flexible(child: printingInfo()),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
          mySizedBox(context),
          if (!isLoading)
            myButton(
              context,
              enabled: ((amount.isNotEmpty && amount != '0') &&
                  ([0, 4].contains(selectedTransactionType) || selectedName.isNotEmpty) &&
                  (selectedTransactionType == 4 || amountOnLetter.isNotEmpty) &&
                  reciver.isNotEmpty),
              onTap: () async {
                setState(() => isLoading = true);
                if (selectedTransactionType == 4) {
                  var res = await sqlQuery(selectUrl, {
                    'sql1': '''SELECT IF(admin = '$_password',1,0) AS password FROM settings;''',
                  });

                  if (res[0][0]['password'] == '1') {
                    save();
                  } else {
                    setState(() => isLoading = false);
                    snackBar(context, getMessage('wrongPassword'), duration: 1);
                  }
                } else {
                  save();
                }
              },
            ),
          mySizedBox(context),
        ],
      ),
    );
  }

  Widget transactionInfo() {
    Map<String, String> compts = {
      'caisse': getText('caisse'),
      'reserve': getText('reserve'),
      'reserveProfit': getText('reserveProfit'),
      'donation': getText('donation'),
      'zakat': getText('zakat'),
    };

    return Column(
      children: [
        if (selectedTransactionType == 0) // special transaction
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
                      onChanged:
                          widget.sourceTab == 'da' ? null : (value) => setState(() => category = value.toString()),
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
                  displayStringForOption: (user) => user.realName,
                  onSelected: (user) {
                    setState(() {
                      selectedName = user.name;
                      selectedUserCapital = user.capital;
                    });
                  },
                  optionsBuilder: (textEditingValue) => users.where(
                    (user) => user.realName.toLowerCase().contains(textEditingValue.text.toLowerCase()),
                  ),
                  fieldViewBuilder: (
                    context,
                    textEditingController,
                    focusNode,
                    onFieldSubmitted,
                  ) {
                    if (widget.selectedName.isNotEmpty) {
                      textEditingController.text = selectedUser.realName;
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
                          style: const TextStyle(fontSize: 16.0),
                          enabled: ['da', 'tr'].contains(widget.sourceTab),
                          autofocus: true,
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
                                    icon: const Icon(Icons.clear, size: 20.0)),
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
                            maxWidth: getWidth(context, .26),
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
                                  child: myText(option.realName),
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
        else if (selectedTransactionType == 4) // allUsers Transaction
          const SizedBox()
        else // loan and deposit transaction
          Row(
            children: [
              Expanded(child: myText(getText('name'))),
              Expanded(
                flex: 4,
                child: Autocomplete<OtherUser>(
                  displayStringForOption: (user) => user.realName,
                  onSelected: (user) => setState(() {
                    selectedName = user.name;
                    rest = user.rest;
                  }),
                  optionsBuilder: (textEditingValue) {
                    if (selectedTransactionType == 2) {
                      return loanUsers
                          .where((user) => user.realName.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                    } else {
                      return depositUsers
                          .where((user) => user.realName.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                    }
                  },
                  fieldViewBuilder: (
                    context,
                    textEditingController,
                    focusNode,
                    onFieldSubmitted,
                  ) {
                    if (widget.selectedName.isNotEmpty) {
                      textEditingController.text = selectedOtherUser.realName;
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
                          style: const TextStyle(fontSize: 16.0),
                          enabled: ['da', 'tr'].contains(widget.sourceTab),
                          autofocus: true,
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
                                    icon: const Icon(Icons.clear, size: 20.0)),
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
                            maxWidth: getWidth(context, .26),
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
                                  child: myText(option.realName),
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
            Expanded(child: myText(getText('type'))),
            Expanded(
              flex: 4,
              child: Row(
                children: [
                  ToggleSwitch(
                    minWidth: getWidth(context, .064),
                    minHeight: getHeight(context, textFeildHeight),
                    borderWidth: 1,
                    icons: const [Icons.remove, Icons.add],
                    inactiveBgColor: Colors.white,
                    borderColor: const [Colors.black],
                    activeBgColors: [
                      [Colors.red[800]!],
                      [Colors.green[800]!]
                    ],
                    initialLabelIndex: type == 'out' ? 0 : 1,
                    labels: [getText('out'), getText('in')],
                    onToggle: (index) => setState(() => type = index == 0 ? 'out' : 'in'),
                  ),
                  mySizedBox(context),
                  if (selectedTransactionType != 4 && !(selectedTransactionType == 0 && category == 'caisse'))
                    myText('${getText('caisse')} :   ${myCurrency(caisse)}'),
                ],
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
                      autoFocus: widget.sourceTab != 'tr' || selectedTransactionType == 4,
                      onChanged: (value) => amount = value,
                      hint: myCurrency(double.parse(amount)),
                    ),
                    mySizedBox(context),
                    InkWell(
                      onTap: () => setState(() {
                        switch (selectedTransactionType) {
                          case 0:
                            setState(() {
                              amount = category == 'caisse'
                                  ? caisse.toString()
                                  : category == 'reserve'
                                      ? reserve.toString()
                                      : category == 'reserveProfit'
                                          ? reserveProfit.toString()
                                          : category == 'donation'
                                              ? donation.toString()
                                              : zakat.toString();
                            });
                            break;
                          case 1:
                            setState(() => amount = selectedUserCapital.toString());
                            break;
                          case 2:
                            setState(() => amount = rest.toString());
                            break;
                          case 3:
                            setState(() => amount = rest.toString());
                            break;
                        }
                      }),
                      child: (selectedTransactionType == 0)
                          ? myText(
                              '${getText('solde')} :   ${myCurrency(category == 'caisse' ? caisse : category == 'reserve' ? reserve : category == 'reserveProfit' ? reserveProfit : category == 'donation' ? donation : zakat)}')
                          : (selectedTransactionType == 1)
                              ? myText('${getText('capital')} :   ${myCurrency(selectedUserCapital)}')
                              : (selectedTransactionType == 4)
                                  ? const SizedBox()
                                  : myText('${getText('rest')} :   ${myCurrency(rest)}'),
                    )
                  ],
                )),
          ],
        ),
        if (isAdmin) mySizedBox(context),
        if (isAdmin)
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
                        color: primaryColor,
                      ),
                      onPressed: () async {
                        final DateTime? selected = await showDatePicker(
                          context: context,
                          initialDate: date,
                          firstDate: DateTime(currentYear),
                          lastDate: DateTime.now(),
                          initialEntryMode: DatePickerEntryMode.input,
                          locale: const Locale("fr", "FR"),
                        );
                        if (selected != null && selected != date) {
                          setState(
                            () => date = DateTime(
                              selected.year,
                              selected.month,
                              selected.day,
                              DateTime.now().hour,
                              DateTime.now().minute,
                              DateTime.now().second,
                            ),
                          );
                        }
                      },
                    )
                  ],
                ),
              ),
            ],
          ),
        if (selectedTransactionType == 4) mySizedBox(context),
        if (selectedTransactionType == 4)
          Row(
            children: [
              Expanded(child: myText(getText('password'))),
              Expanded(
                  flex: 4,
                  child: Row(
                    children: [
                      myTextField(
                        context,
                        width: getWidth(context, .13),
                        onChanged: (text) => _password = text,
                        isPassword: true,
                      ),
                    ],
                  )),
            ],
          ),
        mySizedBox(context),
        Container(
          alignment: Alignment.centerLeft,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            child: TextFormField(
              onChanged: ((value) => note = value),
              style: const TextStyle(fontSize: 16),
              maxLength: 350,
              minLines: 5,
              maxLines: 5,
              textDirection: TextDirection.rtl,
              decoration: InputDecoration(
                hintText: getText('note'),
                contentPadding: const EdgeInsets.all(8),
                border: const OutlineInputBorder(
                  gapPadding: 0,
                  borderSide: BorderSide(width: 0.5),
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget printingInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (selectedTransactionType != 4)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              myText('المبلغ بالحروف'),
              mySizedBox(context),
              TextFormField(
                style: const TextStyle(fontSize: 16),
                controller: controller,
                minLines: 1,
                maxLines: 2,
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.all(12),
                  border: const OutlineInputBorder(
                    gapPadding: 0,
                    borderSide: BorderSide(width: 0.5),
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  prefixIcon: IconButton(
                      onPressed: () => setState(() {
                            amountOnLetter = numberToArabicWords(double.parse(amount).abs());
                            controller.text = amountOnLetter;
                          }),
                      icon: Icon(Icons.calculate, color: primaryColor)),
                ),
                onChanged: (value) => setState(() => amountOnLetter = value),
              ),
            ],
          ),
        mySizedBox(context),
        myText(type == 'in' ? 'مستلم اﻷموال' : 'مقدم الأموال'),
        mySizedBox(context),
        Autocomplete<String>(
          onSelected: (value) => setState(() => reciver = value),
          optionsBuilder: (textEditingValue) => recivers.where((element) => element.contains(textEditingValue.text)),
          fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
            textEditingController.text = reciver;
            return TextFormField(
              controller: textEditingController,
              focusNode: focusNode,
              textDirection: TextDirection.rtl,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.all(12),
                border: OutlineInputBorder(
                  gapPadding: 0,
                  borderSide: BorderSide(width: 0.5),
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
              onChanged: (value) => setState(() => reciver = value),
            );
          },
          optionsViewBuilder: (context, onSelected, options) => Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 8.0,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: getWidth(context, .33)),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (BuildContext context, int index) {
                    final String option = options.elementAt(index);
                    return InkWell(
                      onTap: () => onSelected(option),
                      child: Container(
                        padding: const EdgeInsets.all(16.0),
                        alignment: Alignment.center,
                        child: myText(option),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        mySizedBox(context),
        TextFormField(
          initialValue: intermediates,
          style: const TextStyle(fontSize: 16),
          textAlign: TextAlign.start,
          maxLength: 350,
          minLines: 3,
          maxLines: 5,
          textDirection: TextDirection.rtl,
          decoration: const InputDecoration(
            hintText: 'الوسطاء',
            hintTextDirection: TextDirection.rtl,
            contentPadding: EdgeInsets.all(12),
            border: OutlineInputBorder(
              gapPadding: 0,
              borderSide: BorderSide(width: 0.5),
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
          onChanged: (value) => setState(() => intermediates = value),
        ),
        mySizedBox(context),
        TextFormField(
          initialValue: printingNotes,
          style: const TextStyle(fontSize: 16),
          textAlign: TextAlign.start,
          maxLength: 350,
          minLines: 3,
          maxLines: 5,
          textDirection: TextDirection.rtl,
          decoration: const InputDecoration(
            hintText: 'ملاحظات للطباعة',
            contentPadding: EdgeInsets.all(12),
            hintTextDirection: TextDirection.rtl,
            border: OutlineInputBorder(
              gapPadding: 0,
              borderSide: BorderSide(width: 0.5),
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
          onChanged: (value) => setState(() => printingNotes = value),
        ),
      ],
    );
  }
}
