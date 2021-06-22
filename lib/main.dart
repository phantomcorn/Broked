import 'package:broked/Database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';
import 'package:animated_button/animated_button.dart';
import "Database.dart";
import "CustomTheme.dart";

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {


  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Broked',
      theme: customTheme.greyTheme,
      home: MyHomePage(title: 'Broked'),
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
            icon: Icon(Icons.favorite),
            label : "input"
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.beach_access),
            label : "analytics"
          )
        ],
        currentIndex: _selectedDisplay,
        onTap: onTabTapped,
        selectedItemColor: Colors.grey,
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
                      color : Colors.grey
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 20.0, horizontal: 10.0)
                  ),
                  style: TextStyle(
                    fontSize: 30
                  ),
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color.fromRGBO(211, 211, 211,
                      1)),
                  borderRadius: BorderRadius.circular(10)
                ),
                width: 300,
                margin: EdgeInsets.only(bottom : 50, top : 30),
              ),
              Container(
                child : AnimatedButton(
                  onPressed: () async {
                    if (amountController.text != '') {
                      spentDatabase.instance.insertAmount(
                        Spent(
                          date: _date,
                          amount: double.parse(amountController.text))
                        );
                      }
                      amountController.clear();
                    },
                  child: Text(
                    "BROKE!",
                    style: TextStyle(
                        fontSize: 30
                    ),
                  ),
                  color: const Color.fromRGBO(169, 169, 169, 1),
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
    return Scaffold(
      body: Center(
        child : Column(
          children: [
            Text("analytics : "),

            FutureBuilder(
              future: spentDatabase.instance.getSpendingToday(),
                builder: (BuildContext context, AsyncSnapshot<double> snapshot) {
                  if (snapshot.hasData) {
                    return Text("spent today: ${snapshot.data.toString()}");
                  } else {
                    return CircularProgressIndicator();
                  }
                }
            ),

            FutureBuilder(
                future: spentDatabase.instance.getAvgSpending(DateTime.now().year),
                builder: (BuildContext context, AsyncSnapshot<double> snapshot) {
                  if (snapshot.hasData) {
                    return Text("avg spending per month: ${snapshot.data}");
                  } else {
                    return CircularProgressIndicator();
                  }
                }
            ),

            FutureBuilder(
              future: spentDatabase.instance.getTotalSpendingYearly(DateTime.now().year),
              builder: (BuildContext context, AsyncSnapshot<double> snapshot) {
                if (snapshot.hasData) {
                  return Text("annual spending: ${snapshot.data}");
                } else {
                  return CircularProgressIndicator();
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
                  return Text("total spending this month ($month) : ${snapshot.data.toString()}");
                } else {
                  return CircularProgressIndicator();
                }
              }
            ),
          ],
          mainAxisAlignment: MainAxisAlignment.center
        )
      ),
    );
  }


}

