import 'package:broked/Database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';
import 'package:animated_button/animated_button.dart';
import 'package:audioplayers/audioplayers.dart';
import "Database.dart";
import "Theme.dart";

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations(
    [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]
  );

  runApp(MyApp());
}

AudioCache player = AudioCache();

class MyApp extends StatelessWidget {

  static Map<String,Map<String,dynamic>> Theme = {
    "grey" : {
      "bg" : Colors.white,
      "text" : Color.fromRGBO(105, 105, 105, 1),
      "buttonText" : Colors.white,
      "hintText" : Color.fromRGBO(211, 211, 211, 1),
      "inputBorder" : Color.fromRGBO(211, 211, 211, 1),
      "dateButton" : Color.fromRGBO(128, 128, 128, 1),
      "brokeButton" : Color.fromRGBO(169, 169, 169, 1),
      "budgetButton" : Color.fromRGBO(169, 169, 169, 1),
      "sumButton" : Color.fromRGBO(169, 169, 169, 1),
      "deleteYes" : Color.fromRGBO(46,139,87, 1),
      "deleteNo" : Color.fromRGBO(128, 0, 0, 1),
      "dialogShadow" : Colors.black,
      "navBar" : Colors.white,
      "navSelected" : Color.fromRGBO(105, 105, 105, 1),
      "soundDef" : "greyDefault.mp3",
      "soundSucc" : "greySucc.mp3"
    },
    "retro" : {
      "bg" : Colors.black,
      "text" : Color.fromRGBO(224,231,34, 1),
      "buttonText" : Colors.black,
      "hintText" : Color.fromRGBO(224,231,34, 1),
      "inputBorder" : Color.fromRGBO(224,231,34, 1),
      "dateButton" : Color.fromRGBO(0, 255, 255, 1),
      "brokeButton" : Color.fromRGBO(254, 1, 254, 1),
      "budgetButton" : Color.fromRGBO(255, 7, 58, 1),
      "sumButton" : Color.fromRGBO(255, 7, 58, 1),
      "deleteYes" : Color.fromRGBO(57, 255, 20, 1),
      "deleteNo" : Color.fromRGBO( 255, 7, 58, 1),
      "dialogShadow" : Color.fromRGBO(57, 255, 20, 1),
      "navBar" : Colors.black,
      "navSelected" : Color.fromRGBO(224, 231, 34, 1),
      "soundDef" : "retroDefault.wav",
      "soundSucc" : "retroSucc.wav"
    }
  };

  static String selectedTheme = "grey";

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child : MaterialApp(
        title: 'Broked', 
        theme: customTheme.defaultTheme,
        home: MyHomePage(title: 'Broked'),
      )
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String title;

  MyHomePage({Key? key, required this.title}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}


class _MyHomePageState extends State<MyHomePage> {


  int _selectedDisplay = 0;
  static const List<Widget> _displayOptions = <Widget>[
    BrokeMain(),
    Analytics()
  ];

  void onTabTapped (int index) {
    setState(() {
      _selectedDisplay = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child : _displayOptions.elementAt(_selectedDisplay)
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.calculate),
            label : "input"
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart),
            label : "analytics"
          )
        ],
        currentIndex: _selectedDisplay,
        onTap: onTabTapped,
        backgroundColor: MyApp.Theme[MyApp.selectedTheme]!["navBar"],
        selectedItemColor: MyApp.Theme[MyApp.selectedTheme]!["navSelected"],
        unselectedItemColor: Color.fromRGBO(220, 220, 220, 1)
      ),
    );
  }
}

class BrokeMain extends StatefulWidget {
  const BrokeMain({ Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _BrokeMain();

}

class _BrokeMain extends State<BrokeMain> {

  DateTime _date = DateTime.now();
  final amountController = TextEditingController();
  final budgetController = TextEditingController();

  Widget brokeButton() {
    return AnimatedButton(
      onPressed: () async {
        if (amountController.text != '') {
          player.play(MyApp.Theme[MyApp.selectedTheme]!["soundSucc"]);
          await spentDatabase.instance.accumulateAmount(
              Spent(
                  date: _date,
                  amount: double.parse(amountController.text)
              )
          );
        } else {
          player.play(MyApp.Theme[MyApp.selectedTheme]!["soundDef"]);
        }
        amountController.clear();
      },
      child: Text(
        "BROKE!",
        style: TextStyle(
            fontSize: 30,
            color: MyApp.Theme[MyApp.selectedTheme]!["buttonText"]
        ),
      ),
      color: MyApp.Theme[MyApp.selectedTheme]!["brokeButton"],
      width: 350,
      height: 100,
    );
  }

  Widget inputAmount() {
    return TextFormField(
      controller: amountController,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          RegExp('[0-9.,]+')
        ),
        LengthLimitingTextInputFormatter(8),
      ],
      decoration: InputDecoration(
          hintText: 'Amount',
          hintStyle: TextStyle(
              color : MyApp.Theme[MyApp.selectedTheme]!["hintText"]
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 20.0, horizontal: 10.0)
      ),
      style: TextStyle(
          fontSize: 30,
          color: MyApp.Theme[MyApp.selectedTheme]!["text"]
      ),
    );
  }

  Widget datePicker() {
    return TextButton(
      onPressed : () {
        DatePicker.showDatePicker(
          context,
          showTitleActions: true,
          currentTime: _date,
          minTime: DateTime(2000),
          maxTime: DateTime.now(),
          onConfirm: (date) {
            setState(() =>
              _date = date
            );
          }
        );
      },
      child : Text("${DateFormat('dd MMM yyyy').format(_date)}")
    );
  }

  Widget budgetButton() {
    return ElevatedButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) {
              return Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)
                ),
                elevation: 0,
                backgroundColor: Colors.white,
                child: budgetDialog(context)
              );
            }
          );
        },
        child: Text(
            "Go LESS Broked",
            style: TextStyle(
              color: MyApp.Theme[MyApp.selectedTheme]!["buttonText"]
            )
        ),
        style: ElevatedButton.styleFrom(
          primary: MyApp.Theme[MyApp.selectedTheme]!["budgetButton"]
        )
    );
  }

  Widget budgetDialog(context) {
    return Stack(
      children: <Widget>[
        Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            shape: BoxShape.rectangle,
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: MyApp.Theme[MyApp.selectedTheme]!["dialogShadow"],
                offset: Offset(0,10),
                blurRadius: 10
              )
            ]
          ),
          width: MediaQuery.of(context).size.height / 1.5,
          height : MediaQuery.of(context).size.width / 2,
          child : Column(
            children: [
              Text(
                "Enter budget for this month",
                style: TextStyle(
                  color: Colors.black
                )
              ),
              SizedBox(height : 20),
              inputBudget(),
              SizedBox(height : 15),
              AnimatedButton(
                onPressed: () async {
                  if (budgetController.text != '') {
                    await spentDatabase.instance.addBudget(
                      double.parse(
                        budgetController.text
                      )
                    );
                  }

                  player.play(MyApp.Theme[MyApp.selectedTheme]!["soundDef"]);
                  Navigator.pop(context);
                },
                child: Text("DONE",
                    style: TextStyle(
                        color: MyApp.Theme[MyApp.selectedTheme]!["buttonText"]
                    )
                ),
                width: 100,
                height: 32
              )
            ],
          )
        )
      ]
    );
  }

  Widget inputBudget() {
    return TextFormField(
      controller: budgetController,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.allow(
            RegExp('[0-9.,]+')
        ),
        LengthLimitingTextInputFormatter(8),
      ],
      decoration: InputDecoration(
          hintText: 'Budget',
          hintStyle: TextStyle(
              color : Colors.black
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 20.0, horizontal: 10.0)
      ),
      style: TextStyle(
          fontSize: 30,
          color: Colors.black
      ),
    );
  }

  Widget summaryButton() {
    return ElevatedButton(
        onPressed: () {
          showDialog(
              context: context,
              builder: (context) {
                return Dialog(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)
                    ),
                    elevation: 0,
                    backgroundColor: Colors.white,
                    child: endOfMonthSummary(context)
                );
              }
          );
        },
      child: Text(
          "Summary",
          style: TextStyle(
              color: MyApp.Theme[MyApp.selectedTheme]!["buttonText"]
          )
      ),
      style: ElevatedButton.styleFrom(
          primary: MyApp.Theme[MyApp.selectedTheme]!["budgetButton"]
      )
    );
  }


  Widget endOfMonthSummary(context) {
    return Stack(
      children: [
        Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            shape :BoxShape.rectangle,
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: MyApp.Theme[MyApp.selectedTheme]!["dialogShadow"],
                offset:  Offset(0, 10),
                blurRadius: 10
              )
            ]
          ),
          width: MediaQuery.of(context).size.height / 1.5,
          height: MediaQuery.of(context).size.width,
          child : Column(
            children: [
              FutureBuilder(
                future: spentDatabase.instance.getBudgetThisMonth(),
                builder: (BuildContext context, AsyncSnapshot<double> snapshot) {
                  if (snapshot.hasData) {
                    return Text("Budget this month: ${snapshot.data}",
                        style: TextStyle(
                          fontSize: 14,
                          color : Colors.black
                        )
                    );
                  } else {
                    return Text("Budget this month: ",
                        style: TextStyle(
                            fontSize: 14,
                            color : Colors.black
                        )
                    );
                  }
                }
              ),
              SizedBox(height : 20),
              FutureBuilder(
                  future: spentDatabase.instance.getOverUnderSpent(),
                  builder: (BuildContext context, AsyncSnapshot<double> snapshot) {
                    if (snapshot.hasData) {
                      return RichText(
                          text: TextSpan(
                            text: "Leftover: ",
                            style : TextStyle(
                              fontSize: 14,
                              color: Colors.black
                            ),
                            children: [
                              TextSpan(
                                text: snapshot.data.toString(),
                                style: TextStyle(
                                  color: (snapshot.data! > 0)
                                      ? Color.fromRGBO(50, 205, 50, 1)
                                      : (snapshot.data! < 0)
                                      ? Color.fromRGBO(221, 0, 4, 1)
                                      : Colors.black
                                )
                              )
                            ]
                          )
                      );
                    } else {
                      return Text(
                        "Leftover: ",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 14
                        )
                      );
                    }
                  }
              ),
              AnimatedButton(
                  onPressed: () async {
                    player.play(MyApp.Theme[MyApp.selectedTheme]!["soundDef"]);
                    Navigator.pop(context);
                  },
                  child: Text(
                      "Understood",
                      style: TextStyle(
                          color: MyApp.Theme[MyApp.selectedTheme]!["buttonText"]
                      )
                  ),
                  width: 100,
                  height: 32
              )
            ],
          )
        )
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child : Scaffold(
        body: Center(
          child : Column(
            children: <Widget> [
              Container(
                margin: EdgeInsets.fromLTRB(20, 20, 20, 140),
                child : Row(
                  children: [
                    summaryButton(),
                    Spacer(),
                    budgetButton()
                  ],
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                )
              ),
              Container(
                child : datePicker()
              ),
              Container(
                width: 300,
                margin: EdgeInsets.only(bottom : 50, top : 30),
                child: inputAmount(),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: MyApp.Theme[MyApp.selectedTheme]!["inputBorder"],
                    width: 4
                  ),
                  borderRadius: BorderRadius.circular(10)
                )
              ),
              Container(
                child : brokeButton()
              )
            ],
            mainAxisAlignment: MainAxisAlignment.start
          ),
        ),
      ),
    );
  }

}



class Analytics extends StatefulWidget {
  const Analytics({ Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _Analytics();

}

class _Analytics extends State<Analytics> {

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Center(
          child : Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child : IconButton(
                  icon : Icon(Icons.delete),
                  color: Color.fromRGBO(220, 220, 220, 1),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return Dialog(
                          shape: RoundedRectangleBorder(
                            borderRadius:
                              BorderRadius.circular(10),
                          ),
                          elevation: 0,
                          backgroundColor: Colors.white,
                          child: PopUpBox(context),
                        );
                      }
                    );
                  }
                )
              ),
              Container(
                child : Text("analytics : ",
                  style: TextStyle(
                    fontSize: 16
                  )
                ),
                margin: EdgeInsets.only(bottom : 40)
              ),
              FutureBuilder(
                future: spentDatabase.instance.getSpendingToday(),
                  builder: (BuildContext context, AsyncSnapshot<double> snapshot) {
                    if (snapshot.hasData) {
                      return Text("spent today: ${snapshot.data.toString()}",
                        style: TextStyle(
                          fontSize: 14
                        )
                      );
                    } else {
                      return Text("spent today: ",
                          style: TextStyle(
                              fontSize: 14
                          )
                      );
                    }
                  }
              ),

              FutureBuilder(
                  future: spentDatabase.instance.getAvgSpending(DateTime.now().year),
                  builder: (BuildContext context, AsyncSnapshot<double> snapshot) {
                    if (snapshot.hasData) {
                      return Text("avg spending per month: ${snapshot.data}",
                        style: TextStyle(
                           fontSize: 14
                        )
                      );
                    } else {
                      return Text("avg spending per month: ",
                          style: TextStyle(
                              fontSize: 14
                          )
                      );
                    }
                  }
              ),

              FutureBuilder(
                future: spentDatabase.instance.getSpendingThisYear(),
                builder: (BuildContext context, AsyncSnapshot<double> snapshot) {
                  if (snapshot.hasData) {
                    return Text("annual spending: ${snapshot.data}",
                      style: TextStyle(
                        fontSize: 14
                      )
                    );
                  } else {
                    return Text("annual spending: ",
                        style: TextStyle(
                            fontSize: 14
                        )
                    );
                  }
                }
              ),

              FutureBuilder(
                future: spentDatabase.instance.getSpendingThisMonth(),
                builder: (BuildContext context, AsyncSnapshot<double> snapshot) {
                  String month = DateFormat("MMMM")
                      .format(DateTime.now())
                      .toLowerCase();
                  if (snapshot.hasData) {
                    return Text("total spending this month "
                      "($month) : ${snapshot.data.toString()}",
                      style: TextStyle(
                            fontSize: 14
                      )
                    );
                  } else {
                    return Text("total spending this month ($month) : ",
                      style: TextStyle(
                        fontSize: 14
                      )
                    );
                  }
                }
              ),
            ],
          )
        ),
      )
    );
  }

  Widget PopUpBox(context) {
    return Stack(
      children: <Widget>[
        Container (
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
              shape: BoxShape.rectangle,
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                    color: MyApp.Theme[MyApp.selectedTheme]!["dialogShadow"],
                    offset: Offset(0,10),
                    blurRadius: 10
                ),
              ]
          ),
          width: MediaQuery.of(context).size.height / 1.5,
          height : MediaQuery.of(context).size.width / 2,
          child : Column(
            children: [
              Text("Reset Database",
                style: TextStyle(
                  color: Colors.black
                )
              ),
              SizedBox(height : 25),
              Text("All input data you've previously entered will be erased. Are you sure?",
                style: TextStyle(
                  color: Colors.black
                )
              ),
              SizedBox(height : 40),
              Row(
                children: [
                  AnimatedButton(
                      onPressed: () async {
                        player.play(MyApp.Theme[MyApp.selectedTheme]!["soundDef"]);
                        await spentDatabase.instance.deleteAllRecords();
                        setState(() {
                        });
                        Navigator.pop(context);
                      },
                      child : Text("YES",
                        style: TextStyle(
                          color: MyApp.Theme[MyApp.selectedTheme]!["buttonText"]
                        )
                      ),
                      color: MyApp.Theme[MyApp.selectedTheme]!["deleteYes"]!,
                      width: 100,
                      height: 32
                  ),
                  AnimatedButton(
                      onPressed: () {
                        player.play(MyApp.Theme[MyApp.selectedTheme]!["soundDef"]);
                        Navigator.pop(context);
                      },
                      child: Text("NO",
                        style: TextStyle(
                          color: MyApp.Theme[MyApp.selectedTheme]!["buttonText"]
                        )
                      ),
                      color: MyApp.Theme[MyApp.selectedTheme]!["deleteNo"]!,
                      width: 100,
                      height: 32
                  )
                ],
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              )
            ],
          ),
        )
      ],
    );
  }


}

