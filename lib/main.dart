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
  runApp(MyApp());
}

AudioCache player = AudioCache();

class MyApp extends StatelessWidget {

  static Map<String,Map<String,dynamic>> Theme = {
    "grey" : {
      "bg" : Color.fromRGBO(255, 255, 255, 1),
      "text" : Color.fromRGBO(105, 105, 105, 1),
      "hintText" : Color.fromRGBO(211, 211, 211, 1),
      "inputBorder" : Color.fromRGBO(211, 211, 211, 1),
      "dateButton" : Color.fromRGBO(128, 128, 128, 1),
      "brokeButton" : Color.fromRGBO(169, 169, 169, 1),
      "deleteYes" : Color.fromRGBO(46,139,87, 1),
      "deleteNo" : Color.fromRGBO(128, 0, 0, 1),
      "soundDef" : "greyDefault.mp3",
      "soundSucc" : "greySucc.mp3"
    },
    "retro" : {
      "bg" : Color.fromRGBO(0, 0, 0, 1),
      "text" : Color.fromRGBO(224,231,34, 1),
      "hintText" : Color.fromRGBO(224,231,34, 1),
      "inputBorder" : Color.fromRGBO(224,231,34, 1),
      "dateButton" : Color.fromRGBO(0, 255, 255, 1),
      "brokeButton" : Color.fromRGBO(254, 1, 254, 1),
      "deleteYes" : Color.fromRGBO(57, 255, 20, 1),
      "deleteNo" : Color.fromRGBO( 255, 7, 58, 1),
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
        selectedItemColor: Color.fromRGBO(105, 105, 105, 1),
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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child : Scaffold(
        body: Center(
          child : Column(
            children: <Widget> [
              Container(
                child : TextButton(
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
                ),
              ),
              Container(
                child: TextFormField(
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
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: MyApp.Theme[MyApp.selectedTheme]!["inputBorder"],
                    width: 4
                  ),
                  borderRadius: BorderRadius.circular(10)
                ),
                width: 300,
                margin: EdgeInsets.only(bottom : 50, top : 30),
              ),
              Container(
                child : AnimatedButton(
                  onPressed: () async {
                    if (amountController.text != '') {
                      player.play(MyApp.Theme[MyApp.selectedTheme]!["soundSucc"]);
                      await spentDatabase.instance.accumulateAmount(
                        Spent(
                          date: _date,
                          amount: double.parse(amountController.text))
                        );
                    } else {
                      player.play(MyApp.Theme[MyApp.selectedTheme]!["soundDef"]);
                    }
                    amountController.clear();
                  },
                  child: Text(
                    "BROKE!",
                    style: TextStyle(
                        fontSize: 30
                    ),
                  ),
                  color: MyApp.Theme[MyApp.selectedTheme]!["brokeButton"],
                  width: 350,
                  height:  100,
                ),
              )
            ],
            mainAxisAlignment: MainAxisAlignment.center
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
                      return LinearProgressIndicator();
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
                      return LinearProgressIndicator();
                    }
                  }
              ),

              FutureBuilder(
                future: spentDatabase.instance.getTotalSpendingYearly(DateTime.now().year),
                builder: (BuildContext context, AsyncSnapshot<double> snapshot) {
                  if (snapshot.hasData) {
                    return Text("annual spending: ${snapshot.data}",
                      style: TextStyle(
                        fontSize: 14
                      )
                    );
                  } else {
                    return LinearProgressIndicator();
                  }
                }
              ),

              FutureBuilder(
                future: spentDatabase.instance.getTotalSpendingMonthly(DateTime.now().month),
                builder: (BuildContext context, AsyncSnapshot<double> snapshot) {
                  String month;
                  switch(DateTime.now().month) {
                    case 1 :
                      month = 'january';
                      break;
                    case 2:
                      month = 'february';
                      break;
                    case 3:
                      month = 'march';
                      break;
                    case 4 :
                      month = 'april';
                      break;
                    case 5:
                      month = 'may';
                      break;
                    case 6:
                      month = 'june';
                      break;
                    case 7 :
                      month = 'july';
                      break;
                    case 8:
                      month = 'august';
                      break;
                    case 9:
                      month = 'september';
                      break;
                    case 10 :
                      month = 'october';
                      break;
                    case 11:
                      month = 'november';
                      break;
                    default :
                      month = 'december';
                      break;
                  }
                  if (snapshot.hasData) {
                    return Text("total spending this month ($month) : ${snapshot.data.toString()}",
                      style: TextStyle(
                            fontSize: 14
                      )
                    );
                  } else {
                    return LinearProgressIndicator();
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
                BoxShadow(color: Colors.black,offset: Offset(0,10),
                    blurRadius: 10
                ),
              ]
          ),
          width: MediaQuery.of(context).size.height / 1.5,
          height : MediaQuery.of(context).size.width / 2,
          child : Column(
            children: [
              Text("Reset Database"),
              SizedBox(height : 25),
              Text("All input data you've previously entered will be erased. Are you sure?"),
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
                      child : Text("YES"),
                      color: MyApp.Theme[MyApp.selectedTheme]!["deleteYes"]!,
                      width: 100,
                      height: 32
                  ),
                  AnimatedButton(
                      onPressed: () {
                        player.play(MyApp.Theme[MyApp.selectedTheme]!["soundDef"]);
                        Navigator.pop(context);
                      },
                      child: Text("NO"),
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

